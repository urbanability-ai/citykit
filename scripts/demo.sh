#!/usr/bin/env bash
set -euo pipefail

RUN_ID="${RUN_ID:-$(date -u +"%Y-%m-%dT%H%M%SZ")}"
MAKE_ONLINE="${MAKE_ONLINE:-0}"
OVERPASS_ENDPOINT="${OVERPASS_ENDPOINT:-https://overpass-api.de/api/interpreter}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${ROOT_DIR}/artifacts/${RUN_ID}"
KIT_DIR="${OUT_DIR}/city_demo_kit"
ZIP_PATH="${OUT_DIR}/city_demo_kit.zip"

mkdir -p "${KIT_DIR}"/{multiview,pcd_groundtruth,pcd_pseudo,labels,derived,provenance}

ZONE_FILE="${ROOT_DIR}/inputs/zone.geojson"

OSM_ONLINE="no"
MAP_PROVENANCE="Zone polygon stub (default offline mode)."

# ----------------------------- 
# OSM Fetch step (online optional)
# - MAKE_ONLINE=1: call osm_fetch.py
# - Success: copy derived/osm_baseline.geojson + provenance/osm_query.json → kit
# - Failure: continue with stub
# ----------------------------- 

if [[ "${MAKE_ONLINE}" == "1" ]]; then
  echo "🌍 MAKE_ONLINE=1: attempting OSM fetch via scripts/osm_fetch.py"
  if python3 "${ROOT_DIR}/scripts/osm_fetch.py"; then
    # osm_fetch.py succeeded; copy outputs into kit
    if [[ -f "${ROOT_DIR}/derived/osm_baseline.geojson" ]]; then
      mkdir -p "${KIT_DIR}/derived" "${KIT_DIR}/provenance"
      cp "${ROOT_DIR}/derived/osm_baseline.geojson" "${KIT_DIR}/derived/"
      cp "${ROOT_DIR}/provenance/osm_query.json" "${KIT_DIR}/provenance/"
      OSM_ONLINE="yes"
      MAP_PROVENANCE="OSM highways + footways + cycleways via Overpass API (bbox from inputs/corridor.example.json)."
    else
      echo "⚠️ osm_fetch.py succeeded but derived/osm_baseline.geojson not found." >&2
    fi
  else
    echo "⚠️ OSM fetch failed; continuing with stub polygon fallback." >&2
  fi
fi

# ----------------------------- 
# Delta apply step (if online mode + baseline exists)
# - Call delta_apply.py to transform baseline + delta → osm_modified.geojson
# - Copy osm_modified + scenario_delta.json into kit
# - Failure is non-fatal (continue with baseline only)
# ----------------------------- 

DELTA_APPLIED="no"

if [[ "${OSM_ONLINE}" == "yes" ]] && [[ -f "${ROOT_DIR}/derived/osm_baseline.geojson" ]]; then
  echo "📝 OSM_ONLINE: applying delta ops..."
  if python3 "${ROOT_DIR}/scripts/delta_apply.py" \
    --baseline "${ROOT_DIR}/derived/osm_baseline.geojson" \
    --delta "${ROOT_DIR}/inputs/scenario_delta.example.json" \
    --corridor "${ROOT_DIR}/inputs/corridor.example.json" \
    --out "${ROOT_DIR}/derived/osm_modified.geojson"; then
    
    if [[ -f "${ROOT_DIR}/derived/osm_modified.geojson" ]]; then
      mkdir -p "${KIT_DIR}/derived" "${KIT_DIR}/provenance"
      cp "${ROOT_DIR}/derived/osm_modified.geojson" "${KIT_DIR}/derived/"
      # Also copy scenario_delta.json for reference
      cp "${ROOT_DIR}/inputs/scenario_delta.example.json" "${KIT_DIR}/scenario_delta.json"
      DELTA_APPLIED="yes"
    else
      echo "⚠️ delta_apply.py succeeded but osm_modified.geojson not found." >&2
    fi
  else
    echo "⚠️ Delta apply failed; continuing with baseline only." >&2
  fi
fi

# ----------------------------- 
# Viewer step (only if OSM baseline/modified exist)
# - Writes viz/overview.html that loads local GeoJSON files
# - Works offline (no server required)
# ----------------------------- 

if [[ -d "${KIT_DIR}/derived" ]] && ls "${KIT_DIR}/derived/"osm_*.geojson >/dev/null 2>&1; then
  echo "🎨 Building viewer..."
  mkdir -p "${KIT_DIR}/viz"
  python3 "${ROOT_DIR}/scripts/build_viz.py" --kit "${KIT_DIR}" --embed 2>&1 || echo "build_viz failed; continuing" >&2
fi

# ----------------------------- 
# Map step (always include stub for compatibility)
# ----------------------------- 

cp "${ZONE_FILE}" "${KIT_DIR}/map.geojson"

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
# IMPORTANT: record OSM_ONLINE status (truthful)
# ----------------------------- 

export RUN_ID
export OSM_ONLINE
export DELTA_APPLIED
export MAP_PROVENANCE

python3 - <<'PY'
import json, os, datetime
from pathlib import Path

run_id = os.environ.get("RUN_ID")
osm_online = os.environ.get("OSM_ONLINE", "no")
delta_applied = os.environ.get("DELTA_APPLIED", "no")
map_provenance = os.environ.get("MAP_PROVENANCE", "")
kit_dir = os.path.join(os.getcwd(), "artifacts", run_id, "city_demo_kit")
root_dir = Path(os.getcwd())

created_at = datetime.datetime.utcnow().replace(microsecond=0).isoformat() + "Z"

scenario = {
  "schema_version": "0.2",
  "run_id": run_id,
  "zone": {
    "source": "inputs/zone.geojson",
    "map_artifact": "map.geojson",
    "osm_baseline_enabled": osm_online == "yes"
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

# Optional: enrich with AOI and delta_present if example files exist
corridor_path = root_dir / "inputs" / "corridor.example.json"
delta_path = root_dir / "inputs" / "scenario_delta.example.json"

if corridor_path.exists():
  try:
    corridor_data = json.loads(corridor_path.read_text(encoding="utf-8"))
    if "aoi" in corridor_data:
      scenario["aoi"] = corridor_data["aoi"]
  except Exception as e:
    print(f"Warning: could not read corridor.example.json: {e}", file=__import__('sys').stderr)

scenario["delta_present"] = delta_path.exists()

# Build outputs list (including OSM files if present)
outputs = {
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
}

# Add OSM outputs if online mode succeeded
if osm_online == "yes":
  osm_baseline_path = Path(kit_dir) / "derived" / "osm_baseline.geojson"
  osm_query_path = Path(kit_dir) / "provenance" / "osm_query.json"
  if osm_baseline_path.exists() and osm_query_path.exists():
    outputs["derived"] = {
      "osm_baseline": "derived/osm_baseline.geojson"
    }
    outputs["provenance"] = {
      "osm_query": "provenance/osm_query.json"
    }
    
    # Add modified if delta was applied
    if delta_applied == "yes":
      osm_modified_path = Path(kit_dir) / "derived" / "osm_modified.geojson"
      if osm_modified_path.exists():
        outputs["derived"]["osm_modified"] = "derived/osm_modified.geojson"
    
    # Add scenario_delta.json if present
    scenario_delta_path = Path(kit_dir) / "scenario_delta.json"
    if scenario_delta_path.exists():
      outputs["scenario_delta"] = "scenario_delta.json"

# Add viewer if present
viz_path = Path(kit_dir) / "viz" / "overview.html"
viewer_embedded = False
if viz_path.exists():
  outputs["viz"] = "viz/overview.html"
  viewer_embedded = True

manifest = {
  "schema_version": "0.2",
  "dataset_id": f"urbanability-citykit::{run_id}",
  "created_at_utc": created_at,
  "provenance": {
    "map": map_provenance,
    "attribution": "See ATTRIBUTION.md in repo root."
  },
  "outputs": outputs,
  "notes": [
    "Default (MAKE_ONLINE=0) is offline and reproducible with stub polygon.",
    "MAKE_ONLINE=1 fetches real OSM baseline via Overpass API; fallback to stub is automatic on failure.",
    "Training-grade ground truth is not part of v0.2.",
    "Ground-truth geometry and metrics come from simulator depth/LiDAR later."
  ]
}

if viewer_embedded:
  manifest["viewer_embedded_geojson"] = True

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
echo " MAKE_ONLINE: ${MAKE_ONLINE}"
echo " OSM_ONLINE: ${OSM_ONLINE}"
