# Scenario Specification (v0.1)

## Overview

A **scenario** describes a city corridor (area of interest) and optional operational changes (deltas) for simulation or planning.

The kit currently uses corridor definitions for documentation. Future versions will integrate deltas into scenario simulation.

---

## 1. What Is a Corridor?

A **corridor** is a geographic area of interest (AOI) where city operations occur. It's defined by bounding coordinates and optional metadata about intended operations.

Example use cases:
- Loading zone experiment
- Speed limit pilot
- Multimodal pathway planning
- Delivery robot geofence

---

## 2. AOI Types

### bbox (Bounding Box)

A simple rectangle defined by min/max longitude and latitude.

```json
{
  "type": "bbox",
  "min_lon": 13.404954,
  "min_lat": 52.520008,
  "max_lon": 13.406000,
  "max_lat": 52.521050
}
```

**Use when:** You have a rectangular study area or want quick setup.

### polygon (Future)

GeoJSON polygon for irregular shapes.

```json
{
  "type": "polygon",
  "coordinates": [ [ [lon, lat], [lon, lat], ... ] ]
}
```

---

## 3. What Is a Delta?

A **delta** is a list of declarative operations describing how a corridor's city infrastructure changes.

Deltas are **descriptive, not prescriptive**:
- They document intended changes in plain terms.
- They do not claim simulation results.
- They enable extension and human review before implementation.

### Delta Ops (Examples)

**set_speed_limit** — Reduce vehicle speed on residential streets

```json
{
  "op": "set_speed_limit",
  "target": { "selector": "highway=residential" },
  "value_kph": 20
}
```

**add_curb_zone** — Add loading, delivery, or parking zone

```json
{
  "op": "add_curb_zone",
  "where": { "near": "corridor_centerline", "radius_m": 40 },
  "type": "loading",
  "hours": "08:00-18:00"
}
```

**add_geofence** — Restrict vehicle access by time

```json
{
  "op": "add_geofence",
  "where": { "type": "corridor_aoi" },
  "allowed_hours": "06:00-22:00"
}
```

---

## 4. How It Maps to Kit Files

### Directory Structure

```
inputs/
  corridor.example.json              # AOI definition
  scenario_delta.example.json        # Declarative ops list
  zone.geojson                       # Map source (current)

scenario.json                        # Generated scenario manifest
  ├─ schema_version: "0.2"
  ├─ run_id: "2026-02-19T133804Z"
  ├─ map_mode: "stub"
  ├─ aoi: { ... }                    # Optional, from corridor.example.json
  └─ delta_present: true/false       # Set if scenario_delta.example.json exists

derived/                             # Planned: processed deltas, simulation outputs
provenance/                          # Planned: audit trail of data sources
viz/                                 # Planned: visualization assets
```

### Workflow (Current)

1. **Inputs exist** (corridor.example.json, scenario_delta.example.json)
2. **Demo runs** → generates scenario.json with aoi + delta_present metadata
3. **Inspect extracts** AOI type, bbox coords, and delta status for documentation
4. **Map generation unchanged** → still uses zone.geojson

### Workflow (Future)

1. Delta ops → validated against OSM schema
2. Curb zones, geofences → applied to map
3. Derived folder → contains processed outputs
4. Provenance folder → logs transformation steps

---

## 5. Contributing

To extend the kit:

1. **Add example corridors:**
   - Copy `inputs/corridor.example.json` → `inputs/corridor_<name>.json`
   - Update `aoi` with your bbox or polygon

2. **Add example deltas:**
   - Copy `inputs/scenario_delta.example.json` → `inputs/scenario_delta_<name>.json`
   - Define new ops or refine existing ones

3. **Test:**
   - `make demo` → generates scenario.json with your metadata
   - `make inspect` → shows AOI and delta presence
   - No changes needed for map generation (yet)

---

## 6. Schema Versions

### v0.1 (Current)

- AOI types: bbox, polygon (future)
- Delta ops: descriptive only, no simulation guarantees
- Output: scenario.json with optional aoi + delta_present

### v0.2+ (Future)

- Deltas → integrated into map generation
- Curb zones, geofences → applied before simulation
- Derived + provenance folders populated

---

## Example Files

- `inputs/corridor.example.json` — Minimal bbox AOI
- `inputs/scenario_delta.example.json` — Sample ops list
- Generated: `scenario.json` (after `make demo`)
