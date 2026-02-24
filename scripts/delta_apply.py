#!/usr/bin/env python3
"""
delta_apply.py — Minimal OSM delta applier (stdlib-only)

Inputs:
  --baseline derived/osm_baseline.geojson
  --delta inputs/scenario_delta.example.json
  --corridor inputs/corridor.example.json (bbox AOI)

Output:
  --out derived/osm_modified.geojson

Behavior:
  - Applies set_speed_limit by tag selector (e.g., "highway=residential") to baseline features
  - Adds overlay polygons for add_geofence (AOI bbox) and add_curb_zone (bbox center square)
  - Deterministic ordering: baseline order preserved; overlays appended in ops order
"""

from __future__ import annotations

import argparse
import json
import math
import os
import sys
from datetime import datetime, timezone
from typing import Any, Dict, List, Tuple, Optional


def read_json(path: str) -> Any:
    """Read JSON file."""
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def write_json(path: str, obj: Any) -> None:
    """Write JSON file with directory creation."""
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(obj, f, indent=2, ensure_ascii=False)


def parse_selector(selector: str) -> Tuple[str, str]:
    """Parse simple 'key=value' selector."""
    if "=" not in selector:
        raise ValueError(f"Unsupported selector (expected key=value): {selector}")
    k, v = selector.split("=", 1)
    k, v = k.strip(), v.strip()
    if not k or not v:
        raise ValueError(f"Invalid selector: {selector}")
    return k, v


def corridor_bbox(corridor: Dict[str, Any]) -> Tuple[float, float, float, float]:
    """Extract bbox from corridor AOI."""
    aoi = corridor.get("aoi", {})
    if aoi.get("type") != "bbox":
        raise ValueError("corridor aoi.type must be 'bbox' for week2 day2 minimal engine")
    
    min_lon = float(aoi["min_lon"])
    min_lat = float(aoi["min_lat"])
    max_lon = float(aoi["max_lon"])
    max_lat = float(aoi["max_lat"])
    
    if min_lon >= max_lon or min_lat >= max_lat:
        raise ValueError("Invalid bbox ordering in corridor.example.json")
    
    return min_lon, min_lat, max_lon, max_lat


def bbox_center(
    min_lon: float, min_lat: float, max_lon: float, max_lat: float
) -> Tuple[float, float]:
    """Compute center of bbox."""
    return (min_lon + max_lon) / 2.0, (min_lat + max_lat) / 2.0


def meters_to_degrees(lat_deg: float, meters: float) -> Tuple[float, float]:
    """
    Very rough conversion. Good enough for an overlay polygon in v0.2.
    
    1 deg latitude ~ 111,320 m
    longitude degrees shrink by cos(latitude)
    """
    dlat = meters / 111_320.0
    cos_lat = max(0.1, math.cos(math.radians(lat_deg)))
    dlon = meters / (111_320.0 * cos_lat)
    return dlon, dlat


def polygon_from_bbox(
    min_lon: float, min_lat: float, max_lon: float, max_lat: float
) -> Dict[str, Any]:
    """Create Polygon geometry from bbox corners."""
    return {
        "type": "Polygon",
        "coordinates": [
            [
                [min_lon, min_lat],
                [max_lon, min_lat],
                [max_lon, max_lat],
                [min_lon, max_lat],
                [min_lon, min_lat],
            ]
        ],
    }


def square_polygon_around_point(
    lon: float, lat: float, radius_m: float
) -> Dict[str, Any]:
    """Create a square polygon with side length 2*radius_m centered at (lon, lat)."""
    dlon, dlat = meters_to_degrees(lat, radius_m)
    min_lon, max_lon = lon - dlon, lon + dlon
    min_lat, max_lat = lat - dlat, lat + dlat
    return polygon_from_bbox(min_lon, min_lat, max_lon, max_lat)


def feature_collection(
    features: List[Dict[str, Any]], extra: Optional[Dict[str, Any]] = None
) -> Dict[str, Any]:
    """Build a GeoJSON FeatureCollection with optional extra metadata."""
    fc: Dict[str, Any] = {"type": "FeatureCollection", "features": features}
    if extra:
        fc.update(extra)
    return fc


def apply_set_speed_limit(
    features: List[Dict[str, Any]], selector: str, value_kph: int
) -> int:
    """Apply set_speed_limit op to matching features. Returns count of changed features."""
    key, val = parse_selector(selector)
    changed = 0
    
    for feat in features:
        props = feat.get("properties") or {}
        if props.get(key) == val:
            props["maxspeed_kph"] = int(value_kph)
            
            # Track delta application
            da = props.get("delta_applied")
            if not isinstance(da, list):
                da = []
            if "set_speed_limit" not in da:
                da.append("set_speed_limit")
            props["delta_applied"] = da
            
            feat["properties"] = props
            changed += 1
    
    return changed


def build_geofence_feature(
    min_lon: float, min_lat: float, max_lon: float, max_lat: float, allowed_hours: str
) -> Dict[str, Any]:
    """Build geofence overlay feature."""
    return {
        "type": "Feature",
        "geometry": polygon_from_bbox(min_lon, min_lat, max_lon, max_lat),
        "properties": {"feature_type": "geofence", "allowed_hours": allowed_hours, "source": "scenario_delta"},
    }


def build_curb_zone_feature(
    min_lon: float,
    min_lat: float,
    max_lon: float,
    max_lat: float,
    zone_type: str,
    hours: str,
    radius_m: float,
) -> Dict[str, Any]:
    """Build curb zone overlay feature."""
    lon_c, lat_c = bbox_center(min_lon, min_lat, max_lon, max_lat)
    geom = square_polygon_around_point(lon_c, lat_c, radius_m)
    
    return {
        "type": "Feature",
        "geometry": geom,
        "properties": {
            "feature_type": "curb_zone",
            "zone_type": zone_type,
            "hours": hours,
            "radius_m": radius_m,
            "source": "scenario_delta",
        },
    }


def main() -> int:
    """Main entry point."""
    ap = argparse.ArgumentParser(description="Apply delta ops to OSM baseline")
    ap.add_argument("--baseline", required=True, help="Path to baseline GeoJSON FeatureCollection")
    ap.add_argument("--delta", required=True, help="Path to scenario delta JSON")
    ap.add_argument("--corridor", required=True, help="Path to corridor JSON (bbox AOI)")
    ap.add_argument("--out", required=True, help="Path to output modified GeoJSON")
    args = ap.parse_args()
    
    # Load baseline
    if not os.path.exists(args.baseline):
        print(f"ERROR: baseline not found: {args.baseline}", file=sys.stderr)
        return 2
    
    baseline = read_json(args.baseline)
    if baseline.get("type") != "FeatureCollection":
        print("ERROR: baseline must be a GeoJSON FeatureCollection", file=sys.stderr)
        return 2
    
    features = baseline.get("features")
    if not isinstance(features, list):
        print("ERROR: baseline.features must be a list", file=sys.stderr)
        return 2
    
    # If delta missing, output baseline unchanged (but still valid)
    if not os.path.exists(args.delta):
        extra = {
            "generated_by": "delta_apply.py",
            "generated_at_utc": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
            "delta_ops_count": 0,
            "applied_ops": [],
            "baseline_feature_count": len(features),
            "modified_feature_count": len(features),
            "notes": ["delta file missing; output equals baseline"],
        }
        write_json(args.out, feature_collection(features, extra))
        return 0
    
    delta = read_json(args.delta)
    ops = delta.get("ops", [])
    if not isinstance(ops, list):
        print("ERROR: delta.ops must be a list", file=sys.stderr)
        return 2
    
    # Load corridor bbox
    corridor = read_json(args.corridor)
    min_lon, min_lat, max_lon, max_lat = corridor_bbox(corridor)
    
    # Apply ops
    overlays: List[Dict[str, Any]] = []
    ops_applied: List[Dict[str, Any]] = []
    
    for op in ops:
        if not isinstance(op, dict):
            continue
        
        op_name = op.get("op")
        
        if op_name == "set_speed_limit":
            target = op.get("target") or {}
            selector = target.get("selector")
            value_kph = op.get("value_kph")
            
            if isinstance(selector, str) and isinstance(value_kph, (int, float)):
                changed = apply_set_speed_limit(features, selector, int(value_kph))
                ops_applied.append(
                    {
                        "op": "set_speed_limit",
                        "selector": selector,
                        "value_kph": int(value_kph),
                        "features_changed": changed,
                    }
                )
            else:
                ops_applied.append(
                    {"op": "set_speed_limit", "status": "skipped", "reason": "missing selector or value_kph"}
                )
        
        elif op_name == "add_geofence":
            allowed_hours = op.get("allowed_hours", "")
            if not isinstance(allowed_hours, str) or not allowed_hours:
                allowed_hours = "unspecified"
            
            overlays.append(build_geofence_feature(min_lon, min_lat, max_lon, max_lat, allowed_hours))
            ops_applied.append({"op": "add_geofence", "allowed_hours": allowed_hours})
        
        elif op_name == "add_curb_zone":
            zone_type = op.get("type", "loading")
            hours = op.get("hours", "unspecified")
            where = op.get("where") or {}
            radius_m = where.get("radius_m", 40)
            
            try:
                radius_m_f = float(radius_m)
            except Exception:
                radius_m_f = 40.0
            
            overlays.append(
                build_curb_zone_feature(min_lon, min_lat, max_lon, max_lat, str(zone_type), str(hours), radius_m_f)
            )
            ops_applied.append(
                {"op": "add_curb_zone", "zone_type": str(zone_type), "hours": str(hours), "radius_m": radius_m_f}
            )
        
        else:
            # Ignore unknown ops (future-proof)
            if isinstance(op_name, str):
                ops_applied.append({"op": op_name, "status": "ignored"})
    
    # Build output: baseline features (possibly modified) + overlays
    out_features = list(features) + overlays
    
    extra = {
        "generated_by": "delta_apply.py",
        "generated_at_utc": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "delta_ops_count": len(ops),
        "applied_ops": ops_applied,
        "baseline_feature_count": len(features),
        "modified_feature_count": len(out_features),
        "notes": [
            "Overlays are annotations; they do not modify routing/topology.",
            "This output is intended for visualization and iteration (v0.2).",
        ],
    }
    
    write_json(args.out, feature_collection(out_features, extra))
    print(f"✅ delta_apply: wrote {len(out_features)} features ({len(overlays)} overlays) to {args.out}")
    
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
