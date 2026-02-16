# REPRODUCE

Goal: produce `city_demo_kit.zip` from a clean machine.

## Quickstart (v0.1)

### 1) Install prerequisites (minimal)

```bash
# Core requirements
python3
zip

# Optional (for hero mode)
ffmpeg
```

### 2) Run

```bash
make demo
```

### 3) Output

```
artifacts/<run_id>/city_demo_kit.zip
```

The zip contains:
- `scenario.json` — full scenario spec
- `dataset_manifest.json` — dataset provenance + schema
- `kpi_report.md` — metrics and outcomes
- `renders/*.mp4` — multi-view video
- `depth/` + `seg/` — raw geometry layers
- `pcd_groundtruth/` — point cloud truth data
- `REPRODUCE.md` — how to rebuild this exact pack

---

## What's Inside

Each `city_demo_kit.zip` is self-documenting and reproducible from its manifest.

No external API calls. No credentials required.

**Every artifact is independently verifiable.**
