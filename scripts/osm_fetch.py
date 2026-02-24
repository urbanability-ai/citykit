#!/usr/bin/env python3
"""
osm_fetch.py — Fetch OSM baseline from Overpass API for AOI bbox.

Reads: inputs/corridor.example.json (bbox)
Writes:
  - derived/osm_baseline.geojson (FeatureCollection)
  - provenance/osm_query.json (metadata + query)

Environment:
  OVERPASS_ENDPOINT (default: https://overpass-api.de/api/interpreter)
  OVERPASS_TIMEOUT (default: 30 seconds)

Exit codes:
  0 = success
  1 = input parsing error
  2 = network error
  3 = insufficient features returned
"""

import json
import sys
import os
from pathlib import Path
from urllib import request, parse
from datetime import datetime

OVERPASS_ENDPOINT = os.environ.get("OVERPASS_ENDPOINT", "https://overpass-api.de/api/interpreter")
OVERPASS_TIMEOUT = int(os.environ.get("OVERPASS_TIMEOUT", "30"))

def load_corridor_bbox():
    """Load bbox from inputs/corridor.example.json."""
    corridor_path = Path(__file__).parent.parent / "inputs" / "corridor.example.json"
    
    if not corridor_path.exists():
        print(f"ERROR: {corridor_path} not found", file=sys.stderr)
        sys.exit(1)
    
    try:
        data = json.loads(corridor_path.read_text(encoding="utf-8"))
        aoi = data.get("aoi")
        if not aoi or aoi.get("type") != "bbox":
            print("ERROR: aoi must be type='bbox'", file=sys.stderr)
            sys.exit(1)
        
        bbox = {
            "min_lat": aoi["min_lat"],
            "min_lon": aoi["min_lon"],
            "max_lat": aoi["max_lat"],
            "max_lon": aoi["max_lon"],
        }
        return bbox
    except Exception as e:
        print(f"ERROR parsing {corridor_path}: {e}", file=sys.stderr)
        sys.exit(1)

def fetch_osm(bbox):
    """Fetch highways + footways + cycleways from Overpass."""
    min_lat, min_lon = bbox["min_lat"], bbox["min_lon"]
    max_lat, max_lon = bbox["max_lat"], bbox["max_lon"]
    
    # Overpass query: highways, footways, cycleways
    query = f"""[out:json][timeout:{OVERPASS_TIMEOUT}];
(
  way["highway"]({min_lat},{min_lon},{max_lat},{max_lon});
  way["footway"]({min_lat},{min_lon},{max_lat},{max_lon});
  way["cycleway"]({min_lat},{min_lon},{max_lat},{max_lon});
);
(._;>;);
out body;
"""
    
    data = parse.urlencode({"data": query}).encode("utf-8")
    req = request.Request(
        OVERPASS_ENDPOINT,
        data=data,
        headers={"User-Agent": "urbanability-citykit/0.2 (osm_fetch)"}
    )
    
    try:
        with request.urlopen(req, timeout=OVERPASS_TIMEOUT) as resp:
            raw = resp.read().decode("utf-8")
            return json.loads(raw), query
    except Exception as e:
        print(f"ERROR fetching Overpass: {e}", file=sys.stderr)
        sys.exit(2)

def build_features(osm_data):
    """Convert OSM elements to GeoJSON LineString features."""
    elements = osm_data.get("elements", [])
    
    # Build node lookup
    nodes = {}
    for el in elements:
        if el.get("type") == "node":
            nodes[el["id"]] = (el["lon"], el["lat"])
    
    # Build features from ways
    features = []
    for el in elements:
        if el.get("type") != "way":
            continue
        
        nds = el.get("nodes", [])
        coords = [nodes[n] for n in nds if n in nodes]
        
        if len(coords) < 2:
            continue
        
        tags = el.get("tags", {})
        feature = {
            "type": "Feature",
            "properties": {
                "osm_id": el["id"],
                "highway": tags.get("highway"),
                "footway": tags.get("footway"),
                "cycleway": tags.get("cycleway"),
                "name": tags.get("name"),
                "surface": tags.get("surface"),
                "oneway": tags.get("oneway"),
            },
            "geometry": {
                "type": "LineString",
                "coordinates": coords
            }
        }
        features.append(feature)
    
    # Sort by osm_id for determinism
    features.sort(key=lambda f: f["properties"]["osm_id"])
    return features

def main():
    # Load bbox
    bbox = load_corridor_bbox()
    
    # Fetch from Overpass
    osm_data, query_used = fetch_osm(bbox)
    
    # Build features
    features = build_features(osm_data)
    
    if len(features) < 1:
        print("ERROR: Overpass returned 0 features", file=sys.stderr)
        sys.exit(3)
    
    # Prepare output directories
    derived_dir = Path(__file__).parent.parent / "derived"
    provenance_dir = Path(__file__).parent.parent / "provenance"
    
    derived_dir.mkdir(parents=True, exist_ok=True)
    provenance_dir.mkdir(parents=True, exist_ok=True)
    
    # Write GeoJSON
    geojson = {
        "type": "FeatureCollection",
        "features": features
    }
    
    geojson_path = derived_dir / "osm_baseline.geojson"
    geojson_path.write_text(json.dumps(geojson, indent=2), encoding="utf-8")
    
    # Write provenance
    provenance = {
        "source": "Overpass API",
        "endpoint": OVERPASS_ENDPOINT,
        "query": query_used,
        "timestamp_utc": datetime.utcnow().replace(microsecond=0).isoformat() + "Z",
        "bbox": bbox,
        "features_count": len(features)
    }
    
    provenance_path = provenance_dir / "osm_query.json"
    provenance_path.write_text(json.dumps(provenance, indent=2), encoding="utf-8")
    
    print(f"✅ osm_fetch: wrote {len(features)} features to {geojson_path}")
    return 0

if __name__ == "__main__":
    sys.exit(main())
