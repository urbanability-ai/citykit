#!/usr/bin/env bash
set -euo pipefail

ZIP_PATH="$(ls -1 artifacts/*/city_demo_kit.zip 2>/dev/null | sort | tail -n 1 || true)"

if [[ -z "${ZIP_PATH}" ]]; then
  echo "❌ No demo kit found at artifacts/*/city_demo_kit.zip"
  echo "Run: make demo"
  exit 2
fi

python3 - <<PY
import json
import sys
import zipfile
from collections import Counter

zip_path = "${ZIP_PATH}"

required_files = [
  "city_demo_kit/scenario.json",
  "city_demo_kit/dataset_manifest.json",
  "city_demo_kit/map.geojson",
  "city_demo_kit/kpi_report.md",
  "city_demo_kit/actors.json",
]

required_dirs = [
  "city_demo_kit/pcd_groundtruth/",
  "city_demo_kit/pcd_pseudo/",
  "city_demo_kit/labels/",
  "city_demo_kit/multiview/",
]

def nameset_has_prefix(nameset, prefix):
  return any(n.startswith(prefix) for n in nameset)

def has_any(nameset, options):
  return any(o in nameset for o in options)

# Accept either mp4 or txt placeholders
mv_required = {
  "robot_front": ["city_demo_kit/multiview/robot_front.mp4", "city_demo_kit/multiview/robot_front.mp4.txt"],
  "cyclist_pov": ["city_demo_kit/multiview/cyclist_pov.mp4", "city_demo_kit/multiview/cyclist_pov.mp4.txt"],
  "birds_eye": ["city_demo_kit/multiview/birds_eye.mp4", "city_demo_kit/multiview/birds_eye.mp4.txt"],
}

print(f"📦 Inspecting: {zip_path}")

with zipfile.ZipFile(zip_path, "r") as z:
  names = set(z.namelist())

  missing = []
  for p in required_files:
    if p not in names:
      missing.append(p)

  for d in required_dirs:
    if d not in names and not nameset_has_prefix(names, d):
      missing.append(d)

  for k, opts in mv_required.items():
    if not has_any(names, opts):
      missing.append(f"multiview/{k} (mp4 or mp4.txt)")

  if missing:
    print("❌ Missing required files/dirs:")
    for m in missing:
      print(f" - {m}")
    sys.exit(3)

  scenario = json.loads(z.read("city_demo_kit/scenario.json"))
  manifest = json.loads(z.read("city_demo_kit/dataset_manifest.json"))
  geo = json.loads(z.read("city_demo_kit/map.geojson"))
  actors = json.loads(z.read("city_demo_kit/actors.json"))

  run_id = scenario.get("run_id", "(missing)")
  schema_version = scenario.get("schema_version", "(missing)")
  zone = scenario.get("zone", {}) or {}
  map_mode = zone.get("map_mode", "(missing)")
  cameras = scenario.get("cameras", []) or []
  features = geo.get("features", [])
  feat_count = len(features) if isinstance(features, list) else 0

  actor_list = actors.get("actors", []) if isinstance(actors, dict) else []
  actor_count = len(actor_list) if isinstance(actor_list, list) else 0
  actor_types = sorted({(a.get("type","?") if isinstance(a, dict) else "?") for a in actor_list})

  print(f"✅ scenario.schema_version: {schema_version}")
  print(f"✅ scenario.run_id: {run_id}")
  print(f"🗺️ scenario.map_mode: {map_mode}")

  # Print AOI info if present
  aoi = scenario.get("aoi")
  if aoi:
    aoi_type = aoi.get("type", "?")
    if aoi_type == "bbox":
      min_lon = aoi.get("min_lon", "?")
      min_lat = aoi.get("min_lat", "?")
      max_lon = aoi.get("max_lon", "?")
      max_lat = aoi.get("max_lat", "?")
      print(f"🧭 scenario.aoi: bbox ({min_lon}, {min_lat}) → ({max_lon}, {max_lat})")
    elif aoi_type == "polygon":
      coords_count = len(aoi.get("coordinates", [])) if aoi.get("coordinates") else 0
      print(f"🧭 scenario.aoi: polygon ({coords_count} rings)")
    else:
      print(f"🧭 scenario.aoi: {aoi_type}")

  # Print delta_present if set
  delta_present = scenario.get("delta_present")
  if delta_present is not None:
    status = "✅ present" if delta_present else "❌ absent"
    print(f"📋 scenario.delta_present: {status}")

  print("🎥 Cameras:")
  if cameras:
    for c in cameras:
      cid = c.get("id", "?")
      ctype = c.get("type", "?")
      print(f" - {cid} ({ctype})")
  else:
    print(" - (none)")

  print(f"🗺️ map.geojson features: {feat_count}")
  print(f"🧍 actors.json actors: {actor_count}")
  print(f"🧩 actor types: {', '.join(actor_types) if actor_types else '(none)'}")
  
  # OSM baseline + modified reporting (optional, best-effort)
  if "city_demo_kit/derived/osm_baseline.geojson" in names:
    baseline_geo = json.loads(z.read("city_demo_kit/derived/osm_baseline.geojson"))
    baseline_features = baseline_geo.get("features", [])
    baseline_count = len(baseline_features) if isinstance(baseline_features, list) else 0
    print(f"🌍 osm_baseline.geojson features: {baseline_count}")
  
  if "city_demo_kit/derived/osm_modified.geojson" in names:
    modified_geo = json.loads(z.read("city_demo_kit/derived/osm_modified.geojson"))
    modified_features = modified_geo.get("features", [])
    modified_count = len(modified_features) if isinstance(modified_features, list) else 0
    modified_meta = modified_geo
    ops_count = modified_meta.get("delta_ops_count", 0)
    applied_ops = modified_meta.get("applied_ops", [])
    print(f"✏️ osm_modified.geojson features: {modified_count} (delta ops: {ops_count})")
    if applied_ops:
      op_names = [op.get("op", "?") for op in applied_ops]
      print(f"   ops applied: {', '.join(op_names)}")
  
  # Scenario delta reporting (optional)
  if "city_demo_kit/scenario_delta.json" in names:
    delta_spec = json.loads(z.read("city_demo_kit/scenario_delta.json"))
    delta_ops = delta_spec.get("ops", [])
    delta_op_count = len(delta_ops) if isinstance(delta_ops, list) else 0
    if delta_op_count > 0:
      delta_op_names = [op.get("op", "?") for op in delta_ops if isinstance(op, dict)]
      print(f"📝 scenario_delta.json ops: {delta_op_count}")
      print(f"   ops defined: {', '.join(delta_op_names)}")

  print("📁 multiview contents:")
  mv = [n for n in names if n.startswith("city_demo_kit/multiview/") and not n.endswith("/")]
  for n in sorted(mv):
    print(f" - {n.replace('city_demo_kit/','')}")

  # Basic manifest sanity
  mid = manifest.get("dataset_id", "(missing)")
  created = manifest.get("created_at_utc", "(missing)")
  print(f"🧾 manifest.dataset_id: {mid}")
  print(f"🕒 manifest.created_at: {created}")
  
  print("✅ Inspect OK")

PY
