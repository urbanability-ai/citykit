# WEEK 1 PLAN — Soft Launch (openclaw-city-demo-kit)

## What we're trying to achieve (7 days)

By Day 7, a stranger can:

1) open the repo
2) understand the promise in <60s
3) run `make demo`
4) get `artifacts/<run_id>/city_demo_kit.zip`
5) see three perspectives (robot POV + cyclist POV + bird's-eye), even if placeholder
6) know how to contribute (3 starter issues)

## Definition of Done (Soft Launch v0.1)

- Repo has: README.md + ETHOS.md + REPRODUCE.md + TASKS.md + ATTRIBUTION.md + .gitignore
- `make demo` produces: `artifacts/<run_id>/city_demo_kit.zip`
- Demo kit contains at minimum:
  - scenario.json
  - dataset_manifest.json
  - map.geojson (OSM stub for v0.1 is ok)
  - multiview/robot_front.mp4
  - multiview/cyclist_pov.mp4
  - multiview/birds_eye.mp4
  - kpi_report.md (stub allowed)
- Clear labeling conventions exist:
  - pcd_groundtruth/ (empty ok)
  - pcd_pseudo/ (empty ok)
- "Unofficial / not affiliated" disclaimer is visible at top of README

---

## Day-by-Day

### Day 1 — Repo front door + day-1 demo

- [ ] Add disclaimer block at top of README
- [ ] Add ETHOS.md
- [ ] Add ATTRIBUTION.md (OSM baseline)
- [ ] Add REPRODUCE.md (stub ok)
- [ ] Add TASKS.md (robot + intersection tasklists)
- [ ] Add a minimal demo generator (`make demo`)

Deliverable: repo looks legit and the demo can generate a kit artifact locally.
