# CityKit

A minimal, reproducible city scenario demo kit.

This project packages:

- a corridor definition (area of interest: bbox or polygon)
- a declarative "delta" (what changes: speed limits, curb zones, geofences)
- a structured artifact bundle (`city_demo_kit.zip`)
- multi-perspective placeholders (robot POV, cyclist POV, bird's-eye)

Designed for clarity, reproducibility, and open data.

See [docs/READ_THIS_FIRST.md](docs/READ_THIS_FIRST.md) for what's real vs placeholder.

---

## Run

**Offline mode (default):**
```bash
make smoke
make demo        # Generates kit with stub map
make inspect
```

**Online mode (fetch real OSM + generate viewer):**
```bash
make clean
MAKE_ONLINE=1 make demo    # Fetches OSM baseline, applies delta ops, builds interactive viewer
make inspect
```

Output: `artifacts/<run_id>/city_demo_kit.zip`

**v0.2.3 adds:**
- Optional OSM ingestion via Overpass API (`MAKE_ONLINE=1`)
- Minimal delta engine (speed limits, geofences, curb zones)
- Local Leaflet viewer (`viz/overview.html`) — layer toggles, no server needed

---

## Setup

**Prerequisites**

- Python 3
- `make`

**Optional**

- `zip` (CLI; faster packaging — Python zipfile fallback is used if missing)
- `ffmpeg` for `.mp4` placeholders (otherwise writes `.txt` stubs)
- Internet access when `MAP_MODE=osm` (Overpass API)

---

## What's Inside a Kit

```text
city_demo_kit/
├─ scenario.json # Scenario config (schema v0.2)
├─ dataset_manifest.json # Provenance + outputs index
├─ map.geojson # Zone geometry (GeoJSON)
├─ actors.json # Actor list (robot, cyclist, ped, car)
├─ kpi_report.md # KPI stub (metrics planned)
├─ multiview/
│ ├─ robot_front.mp4 # POV placeholder (stub video)
│ ├─ cyclist_pov.mp4 # POV placeholder (stub video)
│ └─ birds_eye.mp4 # Bird's-eye placeholder (stub video)
├─ pcd_groundtruth/ # Reserved for sim truth data
├─ pcd_pseudo/ # Reserved for derived 3D (clearly labeled)
└─ labels/ # Reserved for annotations
```

---

## Truth vs Appearance (v0.1)

**Real (production-ready):**
- Scenario schema (v0.2)
- Corridor AOI definitions (bbox, polygon)
- Actor modalities (sidewalk, bike_lane, road, crosswalk)
- Map structure (OpenStreetMap–compatible GeoJSON)
- Data source policy (OSM only; no proprietary maps)

**Placeholder (intentional, documented):**
- Videos are colored stubs (text overlay, not camera feeds)
- Ground truth (depth, LiDAR) not generated
- Simulation metrics declared but not computed
- Actor trajectories declared but not executed

→ See [docs/SCENARIO_SPEC.md](docs/SCENARIO_SPEC.md) for roadmap and detailed schema.

---

## Documentation

- **[docs/READ_THIS_FIRST.md](docs/READ_THIS_FIRST.md)** — Start here. What this is + what's placeholder.
- **[docs/SCENARIO_SPEC.md](docs/SCENARIO_SPEC.md)** — Schema, corridors, deltas, roadmap.
- **[docs/DATA_SOURCES.md](docs/DATA_SOURCES.md)** — Allowed data (OSM, open imagery); not allowed (Google Maps, proprietary).
- **[CONTRIBUTING.md](CONTRIBUTING.md)** — How to safely extend the kit.
- **[ETHOS.md](ETHOS.md)** — Why we built this.
- **[docs/RELEASE_CHECKLIST.md](docs/RELEASE_CHECKLIST.md)** — For maintainers: public release process.

---

## Contributing

Planned starter issues: [docs/STARTER_ISSUES.md](docs/STARTER_ISSUES.md)

**Vienna Rule:** If it can't be reproduced from a clean machine, it didn't happen.

See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) and [CONTRIBUTING.md](CONTRIBUTING.md).

---

## Attribution

- Map data: © OpenStreetMap contributors (ODbL). See [ATTRIBUTION.md](ATTRIBUTION.md)
- Project: UrbanAbility

---

## License

MIT. See [LICENSE](LICENSE).
