#!/usr/bin/env bash
set -euo pipefail

mkdir -p scripts inputs
chmod 755 scripts || true

cat > .gitignore <<'GITIGNORE'
# secrets
.env

# generated outputs
artifacts/
data/

# archives
*.zip

# keep repo light by default (adjust later if needed)
*.mp4
*.mov
.DS_Store
GITIGNORE

cat > inputs/zone.geojson <<'ZONE'
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": {
        "name": "Demo Intersection Polygon"
      },
      "geometry": {
        "type": "Polygon",
        "coordinates": [
          [
            [13.404954, 52.520008],
            [13.406000, 52.520008],
            [13.406000, 52.521050],
            [13.404954, 52.521050],
            [13.404954, 52.520008]
          ]
        ]
      }
    }
  ]
}
ZONE

cat > Makefile <<'MAKEFILE'
SHELL := /usr/bin/env bash
RUN_ID ?= $(shell date -u +"%Y-%m-%dT%H%M%SZ")
ART_DIR := artifacts/$(RUN_ID)

.PHONY: help demo smoke clean

help:
	@echo "Targets:"
	@echo " make demo RUN_ID=... # build a city demo kit zip into artifacts/<run_id>/"
	@echo " make smoke # quick sanity checks"
	@echo " make clean # remove artifacts"

smoke:
	@command -v python3 >/dev/null || (echo "Missing python3" && exit 1)
	@command -v zip >/dev/null || (echo "Missing zip (apt-get install zip)" && exit 1)
	@echo "OK: python3 + zip present"
	@echo "Optional: ffmpeg for placeholder mp4"

demo:
	@mkdir -p "$(ART_DIR)"
	@RUN_ID="$(RUN_ID)" ./scripts/demo.sh

clean:
	rm -rf artifacts/*
MAKEFILE

cat > scripts/demo.sh <<'DEMOSH'
#!/usr/bin/env bash
set -euo pipefail

RUN_ID="${RUN_ID:-$(date -u +"%Y-%m-%dT%H%M%SZ")}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${ROOT_DIR}/artifacts/${RUN_ID}"
KIT_DIR="${OUT_DIR}/city_demo_kit"
ZIP_PATH="${OUT_DIR}/city_demo_kit.zip"

mkdir -p "${KIT_DIR}"/{multiview,pcd_groundtruth,pcd_pseudo,labels}

# 1) Map stub (zone polygon)
ZONE_FILE="${ROOT_DIR}/inputs/zone.geojson"
cp "${ZONE_FILE}" "${KIT_DIR}/map.geojson"

# 2) Scenario + Manifest (strict JSON)
python3 - <<PY
import json, os, datetime

run_id = os.environ.get("RUN_ID")
kit_dir = "${KIT_DIR}"
created_at = datetime.datetime.utcnow().replace(microsecond=0).isoformat() + "Z"

scenario = {
  "schema_version": "0.1",
  "run_id": run_id,
  "zone": {
    "source": "inputs/zone.geojson",
    "map_artifact": "map.geojson"
  },
  "cameras": [
    {"id":"robot_front","type":"pov"},
    {"id":"cyclist_pov","type":"pov"},
    {"id":"birds_eye","type":"birdseye"}
  ],
  "truth_vs_appearance": {
    "truth_layer": "simulator depth/LiDAR (planned)",
    "appearance_layer": "video outputs (placeholders allowed in v0.1)"
  }
}

manifest = {
  "schema_version": "0.1",
  "dataset_id": f"openclaw-city-demo-kit::{run_id}",
  "created_at_utc": created_at,
  "provenance": {
    "map": "Zone polygon stub in v0.1; optional OSM extraction planned.",
    "attribution": "See ATTRIBUTION.md in repo root."
  },
  "outputs": {
    "scenario": "scenario.json",
    "map": "map.geojson",
    "multiview": [
      "multiview/robot_front.mp4",
      "multiview/cyclist_pov.mp4",
      "multiview/birds_eye.mp4"
    ],
    "labels": "labels/ (empty in v0.1)",
    "pcd_groundtruth": "pcd_groundtruth/ (empty in v0.1)",
    "pcd_pseudo": "pcd_pseudo/ (empty in v0.1)"
  },
  "notes": [
    "v0.1 generates placeholder videos if ffmpeg is available; otherwise placeholder text files.",
    "Pseudo 3D and ground-truth geometry are not part of v0.1.",
    "Ground-truth geometry and metrics come from simulator depth/LiDAR later."
  ]
}

with open(os.path.join(kit_dir, "scenario.json"), "w") as f:
  json.dump(scenario, f, indent=2)

with open(os.path.join(kit_dir, "dataset_manifest.json"), "w") as f:
  json.dump(manifest, f, indent=2)
PY

# 3) KPI stub (plainspoken)
cat > "${KIT_DIR}/kpi_report.md" <<EOF2
# KPI Report (stub) — ${RUN_ID}

This is a v0.1 placeholder. Planned KPIs (later):

- conflict proxy rate
- curb dwell time
- pedestrian delay
- deliveries per hour

Notes:
- Training-grade ground truth comes from simulator depth/LiDAR.
- v0.1 does not claim metric accuracy.
EOF2

# 4) Placeholder multiview videos (optional)
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

# 5) Package zip
(
  cd "${OUT_DIR}"
  rm -f "${ZIP_PATH}"
  zip -qr "city_demo_kit.zip" "city_demo_kit"
)

echo "✅ Built: ${ZIP_PATH}"
DEMOSH

chmod +x scripts/demo.sh
echo "✅ Day-1 demo files created."
echo "Next:"
echo " make smoke"
echo " make demo"
