# CityKit

UrbanAbility CityKit is a small, reproducible demo‑kit generator for **city operations**.

Run `make demo` to produce a zipped scenario bundle with:

- map geometry (`map.geojson`)
- scenario config (`scenario.json`)
- dataset manifest (`dataset_manifest.json`)
- multi-view placeholders (front POV, cyclist POV, bird's-eye)
- reserved folders for labels and point clouds (`labels/`, `pcd_pseudo/`, `pcd_groundtruth/`)

This project ships artifacts first. No hype.

---

## Quickstart

**Prerequisites**

- Python 3

**Optional**

- `zip` (CLI; faster packaging — Python zipfile fallback is used if missing)
- `ffmpeg` for `.mp4` placeholders (otherwise writes `.txt` stubs)
- Internet access when `MAP_MODE=osm` (Overpass API)

**Commands**

```bash
make smoke # sanity checks
make demo # generate a new kit zip under artifacts/<run_id>/
make inspect # validate + print key fields from the latest kit
make clean # remove artifacts/
```

**Output**

```bash
artifacts/<run_id>/city_demo_kit.zip
```

---

## What's Inside a Kit

```text
city_demo_kit/
├─ scenario.json # Scenario config (schema v0.1)
├─ dataset_manifest.json # Provenance + outputs index
├─ map.geojson # Zone geometry (GeoJSON)
├─ kpi_report.md # KPI stub (metrics planned)
├─ multiview/
│ ├─ robot_front.mp4 # POV placeholder
│ ├─ cyclist_pov.mp4 # POV placeholder
│ └─ birds_eye.mp4 # Bird's-eye placeholder
├─ pcd_groundtruth/ # Reserved for sim truth data
├─ pcd_pseudo/ # Reserved for derived 3D (clearly labeled)
└─ labels/ # Reserved for annotations
```

---

## Project Ethos

See [ETHOS.md](./ETHOS.md) for the full north star.

**Vienna Rule:** If it can't be reproduced from a clean machine, it didn't happen.

---

## Contributing

Planned starter issues are documented in [docs/STARTER_ISSUES.md](./docs/STARTER_ISSUES.md).

---

## Attribution

- Map data: © OpenStreetMap contributors (ODbL). See [ATTRIBUTION.md](./ATTRIBUTION.md)
- Project: UrbanAbility

---

## License

MIT
