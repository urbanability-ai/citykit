# REPRODUCE

Goal: produce `city_demo_kit.zip` from a clean machine.

## Quickstart (v0.1)

### Prereqs

**Required:**
- `python3`
- `zip` (CLI)

**Optional:**
- `ffmpeg` (only used to generate placeholder `.mp4` files; otherwise the demo writes placeholder `.txt` files)

### Run

```bash
make demo
```

### Output

* `artifacts/<run_id>/city_demo_kit.zip`

### Notes

* v0.1 is intentionally minimal and may include placeholders.
* We explicitly separate **truth** (simulator depth/LiDAR, planned) from **appearance** (videos for demos).
