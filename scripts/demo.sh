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

# ----------------------------- 
# Map step
# - stub: copy polygon as map.geojson
# - osm: fetch highway ways in bbox and emit LineString GeoJSON
# ----------------------------- 

MAP_PROVENANCE="Zone polygon stub (v0.1/v0.2 default)."
MAP_MODE_EFFECTIVE="stub"

if [[ "${MAP_MODE}" == "osm" ]]; then
  echo "🌍 MAP_MODE=osm: attempting Overpass fetch → map.geojson"
  python3 - <<PY || true
import json, sys, math, time
from urllib import request, parse
from pathlib import Path

zone_path = Path("${ZONE_FILE}")
endpoint = "${OVERPASS_ENDPOINT}"
out_path = Path("${KIT_DIR}") / "map.geojson"

zone = json.loads(zone_path.read_text(encoding="utf-8"))

# Extract bbox from polygon coordinates (assumes first feature polygon)
coords = None
try:
  coords = zone["features"][0]["geometry"]["coordinates"][0]
except Exception:
  # fallback: scan for any coordinates
  pass

if not coords:
  print("No polygon coords found in zone.geojson", file=sys.stderr)
  sys.exit(2)

lons = [c[0] for c in coords]
lats = [c[1] for c in coords]
west, east = min(lons), max(lons)
south, north = min(lats), max(lats)

# Overpass query: all highway ways within bbox (+ nodes)
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
  feat = {
    "type": "Feature",
    "properties": {
      "osm_id": w.get("id"),
      "highway": tags.get("highway"),
      "name": tags.get("name"),
      "surface": tags.get("surface"),
      "oneway": tags.get("oneway")
    },
    "geometry": {
      "type": "LineString",
      "coordinates": coords
    }
  }
  features.append(feat)

fc = {"type":"FeatureCollection","features":features}
out_path.write_text(json.dumps(fc, indent=2), encoding="utf-8")
print(f"Wrote OSM map features: {len(features)}")
PY

  # If the fetch wrote a file, accept it; otherwise fall back to stub
  if [[ -s "${KIT_DIR}/map.geojson" ]]; then
    MAP_PROVENANCE="OSM highways via Overpass (bbox from inputs/zone.geojson)."
    MAP_MODE_EFFECTIVE="osm"
  else
    echo "⚠️ Overpass fetch failed; falling back to stub map.geojson" >&2
    cp "${ZONE_FILE}" "${KIT_DIR}/map.geojson"
  fi
else
  cp "${ZONE_FILE}" "${KIT_DIR}/map.geojson"
fi

# ----------------------------- 
# Actors (stub)
# ----------------------------- 

cat > "${KIT_DIR}/actors.json" <<'JSON'
{
  "schema_version": "0.1",
  "actors": [
    {
      "id": "robot_001",
      "type": "delivery_robot",
      "modality": "sidewalk",
      "notes": "stub actor; routing/simulation comes later"
    },
    {
      "id": "cyclist_001",
      "type": "cyclist",
      "modality": "bike_lane",
      "notes": "stub actor; for POV + conflicts later"
    },
    {
      "id": "ped_001",
      "type": "pedestrian",
      "modality": "crosswalk",
      "notes": "stub actor"
    },
    {
      "id": "car_001",
      "type": "car",
      "modality": "road",
      "notes": "stub actor"
    }
  ]
}
JSON

# ----------------------------- 
# Scenario + Manifest (strict JSON)
# ----------------------------- 

python3 - <<PY
import json, os, datetime

run_id = os.environ.get("RUN_ID")
kit_dir = "${KIT_DIR}"
created_at = datetime.datetime.utcnow().replace(microsecond=0).isoformat() + "Z"

scenario = {
  "schema_version": "0.2",
  "run_id": run_id,
  "zone": {
    "source": "inputs/zone.geojson",
    "map_artifact": "map.geojson",
    "map_mode": os.environ.get("MAP_MODE", "stub")
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
    "map": "${MAP_PROVENANCE}",
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
    "MAP_MODE=osm performs an optional network fetch; generator falls back to stub on failure.",
    "Training-grade ground truth is not part of v0.2.",
    "Ground-truth geometry and metrics come from simulator depth/LiDAR later."
  ]
}

with open(os.path.join(kit_dir, "scenario.json"), "w") as f:
  json.dump(scenario, f, indent=2)

with open(os.path.join(kit_dir, "dataset_manifest.json"), "w") as f:
  json.dump(manifest, f, indent=2)

print("✓ scenario.json + dataset_manifest.json written")
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
# Package zip (CLI zip)
# ----------------------------- 

if command -v zip >/dev/null 2>&1; then
  ( cd "${OUT_DIR}" && rm -f "${ZIP_PATH}" && zip -qr "city_demo_kit.zip" "city_demo_kit" )
  echo "✅ Built: ${ZIP_PATH}"
else
  echo "⚠️ zip not available; kit directory built at: ${KIT_DIR}" >&2
fi

echo " MAP_MODE requested: ${MAP_MODE}"
echo " MAP_MODE effective: ${MAP_MODE_EFFECTIVE}"
