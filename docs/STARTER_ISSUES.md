# STARTER ISSUES (Draft)

These will be created as GitHub issues later. Keeping them here first keeps scope disciplined.

---

## 1) Optional OSM extraction stub (bbox → map.geojson)

**Goal:** replace the zone stub with a minimal OSM extraction step

**Inputs:**
- zone polygon (GeoJSON)

**Output:**
- map.geojson with roads/paths in the zone + provenance notes

**Constraints:**
- optional dependency
- must have clean fallback when unavailable

**Impact:**
- Makes the demo map realistic without heavyweight tooling
- Encourages users to define their own zones

---

## 2) Actor format + one stub actor

**Goal:** define a minimal actor JSON format (pedestrian, cyclist, car, delivery bot)

**Inputs:**
- actor type + position

**Output:**
- actors.json included in the kit
- referenced by scenario.json

**Constraints:**
- no realism claims, just structure

**Impact:**
- Establishes how we represent traffic participants
- Unblocks scenario complexity

---

## 3) Pseudo-depth → pseudo-pointcloud proof-of-life

**Goal:** add an optional pipeline that turns appearance-layer video into a pseudo pointcloud

**Inputs:**
- multiview/*.mp4 (appearance layer)

**Output:**
- files stored under pcd_pseudo/ with clear labeling and README note

**Constraints:**
- must never be presented as ground truth
- clearly labeled "pseudo"

**Impact:**
- Demonstrates the "truth vs. appearance" separation in practice
- Teases future ground-truth pipeline

---

## 4) Minimal local viewer (inspect the kit)

**Goal:** CLI tool to show what's inside a demo kit (summary of map, actors, cameras, KPIs)

**Inputs:**
- path to city_demo_kit.zip or unzipped folder

**Output:**
- human-readable summary (print to terminal)

**Constraints:**
- pure Python, no heavy dependencies
- focus on "what was in this run?"

**Impact:**
- Reduces friction for understanding what a kit contains
- Encourages exploration

---

## 5) Smoke checks + regression tests

**Goal:** add deterministic tests to catch schema drift, missing files, or broken pipelines

**Inputs:**
- latest artifacts/*/city_demo_kit.zip

**Output:**
- pass/fail report + detailed error messages

**Constraints:**
- should run in <10s
- must be reproducible

**Impact:**
- CI/CD ready
- Catches regressions before commit

---

## Notes for Triaging Later

When converting these to GitHub issues:

- Label: `good-first-issue`, `help-wanted`, or `core-loop`
- Assign milestones to weeks (e.g., issue #3 → Week 3 plan)
- Add "acceptance criteria" as a checklist in the issue body
- Link to relevant task in TASKS.md

---

_This file is a working document. Update it as scope clarifies._
