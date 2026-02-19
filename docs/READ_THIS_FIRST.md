# READ THIS FIRST — What This Is + How to Run It

This is an **unofficial**, **open-source** kit for generating reproducible city corridor scenarios. It's not affiliated with any government or major robotics platform; it's a toolkit for researchers, municipalities, and builders exploring city operations simulation.

---

## What You Get in 60 Seconds

```bash
make demo
make inspect
```

This generates a synthetic dataset:
- **Scenario manifest** (corridor AOI, camera rig, actors)
- **Stub map** (OpenStreetMap–compatible GeoJSON)
- **Placeholder videos** (textured stubs; real camera outputs come later)
- **Actors list** (robot, cyclist, pedestrian, car)

All packaged in a single `.zip` file. Reproducible. No external secrets needed.

---

## Truth vs Appearance

**What's real:**
- Scenario schema (v0.2)
- Map structure (GeoJSON features)
- Corridor AOI definitions
- Actor definitions + modalities

**What's placeholder in v0.1:**
- Videos are stub renders (text + color, not real camera feeds)
- Ground truth (depth, LiDAR) is not generated yet
- Simulation metrics (KPIs) are documented but not computed
- Actor trajectories are declared but not executed

→ See [SCENARIO_SPEC.md](SCENARIO_SPEC.md) for the roadmap.

---

## Quickstart

1. **Install prereqs:**
   ```bash
   # Requires: make, python3, git, ffmpeg (optional; fallback to text placeholders)
   ```

2. **Clone + build:**
   ```bash
   git clone <repo-url>
   cd openclaw-city-demo-kit
   make demo
   ```

3. **Inspect the output:**
   ```bash
   make inspect
   ```

The kit outputs a zip file in `artifacts/` with everything inside.

---

## What's in the Zip

- `scenario.json` — Manifest (run_id, cameras, AOI, delta_present)
- `map.geojson` — Street network (from OpenStreetMap or zone.geojson stub)
- `actors.json` — Actor list (robot, cyclist, pedestrian, car)
- `dataset_manifest.json` — Provenance + outputs list
- `multiview/` — Placeholder videos (one POV per camera)
- `labels/`, `pcd_groundtruth/`, `pcd_pseudo/` — Reserved for future use

---

## How to Extend It

The kit is designed for **safe, reproducible contributions**:

- **Add example corridors:** Copy `inputs/corridor.example.json` → customize the AOI (bbox or polygon)
- **Add example deltas:** Copy `inputs/scenario_delta.example.json` → define new city ops
- **Modify schemas:** Edit `docs/SCENARIO_SPEC.md` or `scenario.json` structure
- **Run tests:** `make smoke`, `make demo`, `make inspect`

→ See [CONTRIBUTING.md](../CONTRIBUTING.md) and [STARTER_ISSUES.md](STARTER_ISSUES.md) for ideas.

---

## Data Sources & Licensing

This repo uses **open data only**:
- **Maps:** OpenStreetMap (ODbL; attribution required)
- **Imagery:** User-owned captures or open-licensed (Mapillary, KartaView, etc.)
- **Code:** MIT license

**Explicitly NOT allowed:**
- Google Maps / Google Street View
- Proprietary map services (Mapbox, Esri, HERE)
- Unattributed scraped data

→ See [DATA_SOURCES.md](DATA_SOURCES.md) for full policy.

---

## Questions or Issues?

- **How do I...?** → Check README or docs/
- **I found a bug** → Open an issue (include `make demo` output)
- **I want to contribute** → Read [CONTRIBUTING.md](../CONTRIBUTING.md) first
- **What's coming next?** → See [ROADMAP.md](../ROADMAP.md) and [SCENARIO_SPEC.md](SCENARIO_SPEC.md)

---

## Links

- [ETHOS.md](../ETHOS.md) — Why we built this
- [SCENARIO_SPEC.md](SCENARIO_SPEC.md) — Schema + corridor/delta definitions
- [DATA_SOURCES.md](DATA_SOURCES.md) — What data is allowed + why
- [CONTRIBUTING.md](../CONTRIBUTING.md) — How to safely extend the kit
- [STARTER_ISSUES.md](STARTER_ISSUES.md) — Good first contributions
- [REPRODUCE.md](../REPRODUCE.md) — Reproducibility pledge

---

_This is v0.1. Placeholders are intentional. We're building in public._
