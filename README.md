# CityKit

**Unofficial**, **open-source** kit for generating reproducible city corridor scenarios.

Run `make demo` to produce a zipped scenario bundle with:

- map geometry (`map.geojson`)
- scenario config (`scenario.json`)
- dataset manifest (`dataset_manifest.json`)
- multi-view placeholders (front POV, cyclist POV, bird's-eye)
- reserved folders for labels and point clouds (`labels/`, `pcd_pseudo/`, `pcd_groundtruth/`)

**This project ships artifacts first. No hype.** See [docs/READ_THIS_FIRST.md](docs/READ_THIS_FIRST.md) for what's real vs placeholder.

---

## Quickstart

**Prerequisites**

- Python 3
- `make`

**Optional**

- `zip` (CLI; faster packaging — Python zipfile fallback is used if missing)
- `ffmpeg` for `.mp4` placeholders (otherwise writes `.txt` stubs)
- Internet access when `MAP_MODE=osm` (Overpass API)

**Run It**

```bash
make demo    # Generate a kit
make inspect # Validate + inspect output
```

**Output**

```bash
artifacts/<run_id>/city_demo_kit.zip
```

Full command list:
```bash
make smoke   # Sanity checks
make demo    # Generate a new kit zip under artifacts/<run_id>/
make inspect # Validate + print key fields from the latest kit
make clean   # Remove artifacts/
```

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
