#!/usr/bin/env bash
set -euo pipefail

# Find and inspect the latest city_demo_kit.zip

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARTIFACTS_DIR="${ROOT_DIR}/artifacts"

# Find the latest zip
LATEST_ZIP=$(find "${ARTIFACTS_DIR}" -name "city_demo_kit.zip" -type f 2>/dev/null | sort -r | head -n 1)

if [[ -z "${LATEST_ZIP}" ]]; then
  echo "❌ No city_demo_kit.zip found in artifacts/"
  exit 1
fi

echo "📦 Inspecting: ${LATEST_ZIP}"

# Create temp dir for unzip
TMPDIR=$(mktemp -d)
trap "rm -rf ${TMPDIR}" EXIT

unzip -q "${LATEST_ZIP}" -d "${TMPDIR}"
KIT_DIR="${TMPDIR}/city_demo_kit"

# Validate structure and report
python3 - <<INSPECT
import json
import os
import sys
from pathlib import Path

kit_dir = "${KIT_DIR}"

# Check required files
required_files = [
    "scenario.json",
    "dataset_manifest.json",
    "map.geojson",
    "kpi_report.md"
]

print("\n=== STRUCTURE ===")
missing = []
for f in required_files:
    fpath = os.path.join(kit_dir, f)
    exists = "✓" if os.path.exists(fpath) else "✗"
    print(f"  {exists} {f}")
    if not os.path.exists(fpath):
        missing.append(f)

# Parse scenario.json
print("\n=== SCENARIO ===")
try:
    with open(os.path.join(kit_dir, "scenario.json")) as f:
        scenario = json.load(f)
    
    print(f"  Schema version: {scenario.get('schema_version', 'N/A')}")
    print(f"  Run ID: {scenario.get('run_id', 'N/A')}")
    
    cameras = scenario.get('cameras', [])
    print(f"  Cameras: {len(cameras)}")
    for cam in cameras:
        cam_id = cam.get('id', '?')
        cam_type = cam.get('type', '?')
        print(f"    - {cam_id} ({cam_type})")
except Exception as e:
    print(f"  ❌ Error parsing scenario.json: {e}")
    missing.append("scenario.json")

# Parse dataset_manifest.json
print("\n=== MANIFEST ===")
try:
    with open(os.path.join(kit_dir, "dataset_manifest.json")) as f:
        manifest = json.load(f)
    
    dataset_id = manifest.get('dataset_id', 'N/A')
    created_at = manifest.get('created_at_utc', 'N/A')
    print(f"  Dataset ID: {dataset_id}")
    print(f"  Created: {created_at}")
    
    outputs = manifest.get('outputs', {})
    multiview = outputs.get('multiview', [])
    print(f"  Multiview videos: {len(multiview)}")
    for vid in multiview:
        vid_path = os.path.join(kit_dir, vid)
        exists_check = "✓" if os.path.exists(vid_path) else "✗"
        print(f"    {exists_check} {vid}")
        if not os.path.exists(vid_path):
            missing.append(vid)
except Exception as e:
    print(f"  ❌ Error parsing dataset_manifest.json: {e}")
    missing.append("dataset_manifest.json")

# Parse map.geojson
print("\n=== MAP ===")
try:
    with open(os.path.join(kit_dir, "map.geojson")) as f:
        geojson = json.load(f)
    
    features = geojson.get('features', [])
    print(f"  Features: {len(features)}")
    
    if features:
        print(f"  Sample feature: {features[0].get('properties', {}).get('name', 'unnamed')}")
except Exception as e:
    print(f"  ❌ Error parsing map.geojson: {e}")
    missing.append("map.geojson")

# Summary
print("\n=== RESULT ===")
if missing:
    print(f"❌ {len(missing)} issue(s) found:")
    for m in missing:
        print(f"  - {m}")
    sys.exit(1)
else:
    print("✅ Kit structure is valid")
    sys.exit(0)
INSPECT
