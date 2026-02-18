#!/usr/bin/env bash
set -euo pipefail

RUN_ID="${RUN_ID:-$(date -u +"%Y-%m-%dT%H%M%SZ")}"
MAP_MODE="${MAP_MODE:-stub}"
OVERPASS_ENDPOINT="${OVERPASS_ENDPOINT:-https://overpass-api.de/api/interpreter}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${ROOT_DIR}/artifacts/${RUN_ID}"
KIT_DIR="${OUT_DIR}/city_demo_kit"
ZIP_PATH="${OUT_DIR}/city_demo_kit.zip"

mkdir -p "${KIT_DIR}"/{multiview,pcd_groundtruth,pcd_pseudo,labels}

ZONE_FILE="${ROOT_DIR}/inputs/zone.geojson"

MAP_PROVENANCE="Zone polygon stub (default offline mode)."
MAP_MODE_EFFECTIVE="stub"

# ----------------------------- 
# Map step
# - stub: copy polygon as map.geojson
# - osm: fetch highway ways in bbox; fallback to stub on failure
# ----------------------------- 

if [[ "${MAP_MODE}" == "osm" ]]; then
  echo "🌍 MAP_MODE=osm: attempting Overpass fetch → map.geojson"
  if python3 - <<PY
import json, sys
from urllib import request, parse
from pathlib import Path

zone_path = Path("${ZONE_FILE}")
endpoint = "${OVERPASS_ENDPOINT}"
out_path = Path("${KIT_DIR}") / "map.geojson"

zone = json.loads(zone_path.read_text(encoding="utf-8"))

try:
  coords = zone["features"][0]["geometry"]["coordinates"][0]
except Exception:
  print("No polygon coords found in inputs/zone.geojson", file=sys.stderr)
  sys.exit(2)

lons = [c[0] for c in coords]
lats = [c[1] for c in coords]
west, east = min(lons), max(lons)
south, north = min(lats), max(lats)

q = f"""
[out:json][timeout:25];
(
  way["highway"]({south},{west},{north},{east});
);
(._;>;);
out body;
"""

data = parse.urlencode({"data": q}).encode("utf-8")
req = request.Request(endpoint, data=data, headers={
  "User-Agent": "urbanability-citykit/0.2 (demo generator)"
})

with request.urlopen(req, timeout=35) as resp:
  raw = resp.read().decode("utf-8")
  js = json.loads(raw)

elements = js.get("elements", [])
nodes = {}
ways = []

for el in elements:
  if el.get("type") == "node":
    nodes[el["id"]] = (el["lon"], el["lat"])
  elif el.get("type") == "way":
    ways.append(el)

features = []
for w in ways:
  nds = w.get("nodes", [])
  coords = [nodes[n] for n in nds if n in nodes]
  if len(coords) < 2:
    continue
  tags = w.get("tags", {})
  features.append({
    "type": "Feature",
    "properties": {
      "osm_id": w.get("id"),
      "highway": tags.get("highway"),
      "name": tags.get("name"),
      "surface": tags.get("surface"),
      "oneway": tags.get("oneway")
    },
    "geometry": {"type": "LineString", "coordinates": coords}
  })

out_path.write_text(json.dumps({"type":"FeatureCollection","features":features}, indent=2), encoding="utf-8")

# Consider success only if we have at least 1 LineString feature
if len(features) < 1:
  sys.exit(3)

print(f"Wrote OSM map features: {len(features)}")
PY
  then
    MAP_PROVENANCE="OSM highways via Overpass (bbox from inputs/zone.geojson)."
    MAP_MODE_EFFECTIVE="osm"
  else
    echo "⚠️ Overpass fetch failed or returned no features; falling back to stub polygon." >&2
    cp "${ZONE_FILE}" "${KIT_DIR}/map.geojson"
    MAP_PROVENANCE="Zone polygon stub (OSM requested but fetch failed; fallback applied)."
    MAP_MODE_EFFECTIVE="stub"
  fi
else
  cp "${ZONE_FILE}" "${KIT_DIR}/map.geojson"
  MAP_MODE_EFFECTIVE="stub"
fi

# ----------------------------- 
# Actors (stub)
# ----------------------------- 

cat > "${KIT_DIR}/actors.json" <<'JSON'
{
  "schema_version": "0.1",
  "actors": [
    {"id":"robot_001","type":"delivery_robot","modality":"sidewalk","notes":"stub actor; routing/simulation comes later"},
    {"id":"cyclist_001","type":"cyclist","modality":"bike_lane","notes":"stub actor; for POV + conflicts later"},
    {"id":"ped_001","type":"pedestrian","modality":"crosswalk","notes":"stub actor"},
    {"id":"car_001","type":"car","modality":"road","notes":"stub actor"}
  ]
}
JSON

# ----------------------------- 
# Scenario + Manifest (strict JSON)
# IMPORTANT: record MAP_MODE_EFFECTIVE (truthful)
# ----------------------------- 

export RUN_ID
export MAP_MODE_REQUESTED="${MAP_MODE}"
export MAP_MODE_EFFECTIVE
export MAP_PROVENANCE

python3 - <<'PY'
import json, os, datetime

run_id = os.environ.get("RUN_ID")
map_mode_requested = os.environ.get("MAP_MODE_REQUESTED", "stub")
map_mode_effective = os.environ.get("MAP_MODE_EFFECTIVE", "stub")
map_provenance = os.environ.get("MAP_PROVENANCE", "")
kit_dir = os.path.join(os.getcwd(), "artifacts", run_id, "city_demo_kit")

created_at = datetime.datetime.utcnow().replace(microsecond=0).isoformat() + "Z"

scenario = {
  "schema_version": "0.2",
  "run_id": run_id,
  "zone": {
    "source": "inputs/zone.geojson",
    "map_artifact": "map.geojson",
    "map_mode_requested": map_mode_requested,
    "map_mode": map_mode_effective
  },
  "actors_artifact": "actors.json",
  "cameras": [
    {"id":"robot_front","type":"pov"},
    {"id":"cyclist_pov","type":"pov"},
    {"id":"birds_eye","type":"birdseye"}
  ],
  "truth_vs_appearance": {
    "truth_layer": "simulator depth/LiDAR (planned)",
    "appearance_layer": "video outputs (placeholders allowed in v0.x)"
  }
}

manifest = {
  "schema_version": "0.2",
  "dataset_id": f"urbanability-citykit::{run_id}",
  "created_at_utc": created_at,
  "provenance": {
    "map": map_provenance,
    "attribution": "See ATTRIBUTION.md in repo root."
  },
  "outputs": {
    "scenario": "scenario.json",
    "manifest": "dataset_manifest.json",
    "map": "map.geojson",
    "actors": "actors.json",
    "multiview": [
      "multiview/robot_front.mp4",
      "multiview/cyclist_pov.mp4",
      "multiview/birds_eye.mp4"
    ],
    "labels": "labels/ (empty in v0.x)",
    "pcd_groundtruth": "pcd_groundtruth/ (empty in v0.x)",
    "pcd_pseudo": "pcd_pseudo/ (empty in v0.x)"
  },
  "notes": [
    "Default MAP_MODE=stub is offline and reproducible.",
    "MAP_MODE=osm performs an optional network fetch; fallback to stub is explicit in scenario + provenance.",
    "Training-grade ground truth is not part of v0.2.",
    "Ground-truth geometry and metrics come from simulator depth/LiDAR later."
  ]
}

with open(os.path.join(kit_dir, "scenario.json"), "w", encoding="utf-8") as f:
  json.dump(scenario, f, indent=2)

with open(os.path.join(kit_dir, "dataset_manifest.json"), "w", encoding="utf-8") as f:
  json.dump(manifest, f, indent=2)
PY

# ----------------------------- 
# KPI stub
# ----------------------------- 

cat > "${KIT_DIR}/kpi_report.md" <<EOF2
# KPI Report (stub) — ${RUN_ID}

This is a v0.x placeholder. Planned KPIs (later):
- conflict proxy rate
- curb dwell time
- pedestrian delay
- deliveries per hour

Notes:
- Training-grade ground truth comes from simulator depth/LiDAR.
- v0.x does not claim metric accuracy.
EOF2

# ----------------------------- 
# Placeholder multiview videos (optional)
# ----------------------------- 

if command -v ffmpeg >/dev/null 2>&1; then
  ffmpeg -hide_banner -loglevel error -y \
    -f lavfi -i color=c=black:s=1280x720:d=3 \
    -vf "drawtext=text='robot_front (placeholder)\\nRUN_ID=${RUN_ID}':fontcolor=white:fontsize=48:x=(w-text_w)/2:y=(h-text_h)/2" \
    "${KIT_DIR}/multiview/robot_front.mp4"

  ffmpeg -hide_banner -loglevel error -y \
    -f lavfi -i color=c=black:s=1280x720:d=3 \
    -vf "drawtext=text='cyclist_pov (placeholder)\\nRUN_ID=${RUN_ID}':fontcolor=white:fontsize=48:x=(w-text_w)/2:y=(h-text_h)/2" \
    "${KIT_DIR}/multiview/cyclist_pov.mp4"

  ffmpeg -hide_banner -loglevel error -y \
    -f lavfi -i color=c=black:s=1280x720:d=3 \
    -vf "drawtext=text='birds_eye (placeholder)\\nRUN_ID=${RUN_ID}':fontcolor=white:fontsize=48:x=(w-text_w)/2:y=(h-text_h)/2" \
    "${KIT_DIR}/multiview/birds_eye.mp4"
else
  echo "ffmpeg missing; writing placeholder text files." >&2
  echo "robot_front placeholder (install ffmpeg for mp4)" > "${KIT_DIR}/multiview/robot_front.mp4.txt"
  echo "cyclist_pov placeholder (install ffmpeg for mp4)" > "${KIT_DIR}/multiview/cyclist_pov.mp4.txt"
  echo "birds_eye placeholder (install ffmpeg for mp4)" > "${KIT_DIR}/multiview/birds_eye.mp4.txt"
fi

# ----------------------------- 
# Package zip:
# - use zip CLI if present
# - else Python zipfile fallback (includes empty dirs)
# ----------------------------- 

rm -f "${ZIP_PATH}"

if command -v zip >/dev/null 2>&1; then
  ( cd "${OUT_DIR}" && zip -qr "city_demo_kit.zip" "city_demo_kit" )
else
  python3 - <<PY
import os, zipfile
from pathlib import Path

out_dir = Path("${OUT_DIR}")
kit_dir = out_dir / "city_demo_kit"
zip_path = out_dir / "city_demo_kit.zip"

with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED) as z:
  dirs_added = set()
  
  for p in kit_dir.rglob("*"):
    arc = "city_demo_kit/" + str(p.relative_to(kit_dir)).replace(chr(92), "/")
    if p.is_dir():
      dir_arc = arc.rstrip("/") + "/"
      if dir_arc not in dirs_added:
        z.writestr(dir_arc, "")
        dirs_added.add(dir_arc)
    else:
      z.write(p, arc)
  
  # Ensure reserved empty dirs exist
  for d in ["city_demo_kit/pcd_groundtruth/", "city_demo_kit/pcd_pseudo/", "city_demo_kit/labels/"]:
    if d not in dirs_added:
      z.writestr(d, "")

print(f"Wrote (python) zip: {zip_path}")
PY
fi

echo "✅ Built: ${ZIP_PATH}"
echo " MAP_MODE requested: ${MAP_MODE}"
echo " MAP_MODE effective: ${MAP_MODE_EFFECTIVE}"
