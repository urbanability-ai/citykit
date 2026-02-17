# TASKS

Task index for the City Demo Kit project.

---

## Service Operations (Automated + Assisted)

These tasks are framed around **city services for people**: safer streets, clearer curbside rules, and reliable delivery and mobility — including the shift toward aging-in-place and higher demand for at-home services.

### Task: Autonomous Delivery Route (Urban Grid)

**Inputs:**
- OSM street graph (bounding box)
- Delivery waypoints (lat/lon)
- Obstacle dataset (parked cars, pedestrians, construction)

**Outputs:**
- `route_plan.json` — approved path + decision points
- `incident_cards.md` — edge cases (e.g., unexpected pedestrian)
- `renders/robot_pov.mp4` — first-person sim video

**Artifact paths:**
- `artifacts/<run_id>/delivery/route_plan.json`
- `artifacts/<run_id>/delivery/incident_cards.md`
- `artifacts/<run_id>/delivery/renders/robot_pov.mp4`

---

### Task: Multi-sensor Fusion (Lidar + Camera + Radar)

**Inputs:**
- Simulated point clouds (ground truth)
- Rendered RGB (Veo appearance)
- Simulated radar returns

**Outputs:**
- `fusion_report.md` — sensor performance metrics
- `pcd_aligned/` — registered point clouds
- `depth_comparison.json` — truth vs. ML-estimated

**Artifact paths:**
- `artifacts/<run_id>/fusion/fusion_report.md`
- `artifacts/<run_id>/fusion/pcd_aligned/`
- `artifacts/<run_id>/fusion/depth_comparison.json`

---

## Vehicle Operations

### Task: Intersection Clearance (A/B/C Routing)

**Inputs:**
- Intersection geometry (OSM + curb data)
- Vehicle fleet config (size, speed, sensor footprint)
- Incident scenario (double-parked car, pedestrian encroachment)

**Outputs:**
- `routing_options.json` — A/B/C decision trees
- `kpi_report.md` — safety score, time-to-clear, collision risk
- `renders/bird_eye.mp4` — 2D overhead video

**Artifact paths:**
- `artifacts/<run_id>/intersection_ops/routing_options.json`
- `artifacts/<run_id>/intersection_ops/kpi_report.md`
- `artifacts/<run_id>/intersection_ops/renders/bird_eye.mp4`

---

### Task: Curb Rule Validation

**Inputs:**
- Curb rules (loading zones, transit lanes, bike lanes)
- OSM + local overrides
- Vehicle type + time-of-day

**Outputs:**
- `curb_rules.json` — machine-readable rules
- `compliance_report.md` — validation against fleet policies
- `geojson/` — visual boundary exports

**Artifact paths:**
- `artifacts/<run_id>/curb_ops/curb_rules.json`
- `artifacts/<run_id>/curb_ops/compliance_report.md`
- `artifacts/<run_id>/curb_ops/geojson/`

---

## Infrastructure & Planning

### Task: City-Scale Deployment Plan

**Inputs:**
- City boundary (OSM polygon)
- Demand heatmap (delivery, transit, micro-mobility)
- Infrastructure constraints (sidewalk width, power, comms)

**Outputs:**
- `deployment_plan.json` — A/B/C rollout options
- `phasing.md` — timeline + KPIs per phase
- `cost_model.md` — CAPEX, OPEX per option

**Artifact paths:**
- `artifacts/<run_id>/deployment/deployment_plan.json`
- `artifacts/<run_id>/deployment/phasing.md`
- `artifacts/<run_id>/deployment/cost_model.md`

---

## Dataset Export

### Task: Trainable Dataset Pack

**Inputs:**
- Scenario run (all sim data)
- Ground-truth labels (objects, lanes, terrain)
- Split config (train/val/test %)

**Outputs:**
- `dataset_manifest.json` — schema + provenance
- `train/`, `val/`, `test/` — image + depth + segmentation
- `dataset_stats.md` — class distribution, coverage analysis

**Artifact paths:**
- `artifacts/<run_id>/dataset/dataset_manifest.json`
- `artifacts/<run_id>/dataset/train/`
- `artifacts/<run_id>/dataset/val/`
- `artifacts/<run_id>/dataset/test/`
- `artifacts/<run_id>/dataset/dataset_stats.md`

---

## Template: Add Your Task

**Task: [Your Task Name]**

**Inputs:**
- (list required inputs)

**Outputs:**
- (list concrete files)

**Artifact paths:**
- `artifacts/<run_id>/[your_category]/[files]`

---

**All tasks must produce artifacts. No task is done until artifacts exist.**
