#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

RID_STUB="${RID_STUB:-$(date -u +"%Y-%m-%dT%H%M%SZ")-stub}"
RID_OSM="${RID_OSM:-$(date -u +"%Y-%m-%dT%H%M%SZ")-osm}"

echo "==> Running stub demo (RUN_ID=${RID_STUB})"
make demo RUN_ID="${RID_STUB}" MAP_MODE=stub >/dev/null

echo "==> Running osm demo (RUN_ID=${RID_OSM})"
make demo RUN_ID="${RID_OSM}" MAP_MODE=osm >/dev/null || true

python3 <<PY
import json, zipfile
from pathlib import Path

root = Path("${ROOT_DIR}")
rid_stub = "${RID_STUB}"
rid_osm = "${RID_OSM}"

def inspect(run_id: str):
  zpath = root / "artifacts" / run_id / "city_demo_kit.zip"
  if not zpath.exists():
    return {"run_id": run_id, "ok": False, "error": "zip missing"}
  
  with zipfile.ZipFile(zpath, "r") as z:
    scenario = json.loads(z.read("city_demo_kit/scenario.json"))
    geo = json.loads(z.read("city_demo_kit/map.geojson"))
    actors = json.loads(z.read("city_demo_kit/actors.json"))
    
    zone = scenario.get("zone", {}) or {}
    map_mode = zone.get("map_mode", "(missing)")
    map_mode_requested = zone.get("map_mode_requested", "(missing)")
    features = geo.get("features", [])
    feat_count = len(features) if isinstance(features, list) else 0
    
    actor_list = actors.get("actors", []) if isinstance(actors, dict) else []
    actor_count = len(actor_list) if isinstance(actor_list, list) else 0
    actor_types = sorted({(a.get("type","?") if isinstance(a, dict) else "?") for a in actor_list})
    
    return {
      "ok": True,
      "run_id": scenario.get("run_id", run_id),
      "map_mode_requested": map_mode_requested,
      "map_mode": map_mode,
      "map_features": feat_count,
      "actor_count": actor_count,
      "actor_types": actor_types,
      "zip_bytes": zpath.stat().st_size,
      "zip_path": str(zpath),
    }

stub = inspect(rid_stub)
osm = inspect(rid_osm)

print("")
print("✅ CityKit Compare Summary")
print("-------------------------")

def show(label, r):
  print(f"{label} RUN_ID: {r.get('run_id')}")
  if not r.get("ok"):
    print(f" ERROR: {r.get('error')}")
    return
  print(f" map_mode: {r['map_mode']} (requested: {r['map_mode_requested']})") 
  print(f" features: {r['map_features']}")
  print(f" actors: {r['actor_count']} ({', '.join(r['actor_types'])})")
  print(f" zip_bytes: {r['zip_bytes']}")
  print(f" zip_path: {r['zip_path']}")

show("STUB", stub)
print("")
show("OSM ", osm)
print("")
print("Notes:")
print("- If Overpass is blocked, OSM requested may fall back to stub (map_mode becomes stub).")

PY
