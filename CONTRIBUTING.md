# Contributing

Thanks for your interest in improving the CityKit demo!

## Quickstart

1. **Clone & verify:**
   ```bash
   git clone <repo-url>
   cd openclaw-city-demo-kit
   ```

2. **Run a quick smoke test:**
   ```bash
   make smoke
   ```

3. **Generate a demo kit:**
   ```bash
   make demo
   ```

4. **Inspect the output:**
   ```bash
   make inspect
   ```

If all three pass, you're ready to contribute.

---

## What's Safe to Change

Feel free to modify:

- **Schemas & file formats:** `docs/SCENARIO_SPEC.md`, new fields in `scenario.json`
- **Scripts:** `scripts/demo.sh`, `scripts/inspect_latest.sh`
- **Documentation:** `docs/*.md`, inline code comments
- **Example inputs:** `inputs/*.example.json`, new example corridors/deltas
- **Tests & validation:** New checks in `Makefile`

---

## What NOT to Commit

Do NOT commit:

- **Generated artifacts:** `artifacts/`, `*.zip`, `*.mp4`, `*.mov`
- **Large binaries:** Raw video, images, point clouds
- **Private configs:** `.env`, secrets, API keys
- **PII or sensitive footage:** Faces, license plates, or personally identifying details
- **Third-party proprietary imagery:** Google Maps, Google Street View, scraped tiles

---

## Data Sources

Before adding imagery or maps, read `docs/DATA_SOURCES.md`. In short:

- **✅ Allowed:** OpenStreetMap, open-licensed street imagery (Mapillary, KartaView, Panoramax)
- **❌ Not allowed:** Google Maps, proprietary map services, unattributed scraped data

If you have reference images for testing, place them in `inputs/reference/` (gitignored). Don't commit raw footage.

---

## Pull Request Expectations

When submitting a PR:

1. **Keep claims honest:** Don't overstate simulation accuracy or data fidelity.
2. **Ensure reproducibility:** Your changes should work with `make demo && make inspect`.
3. **Update docs:** If you change file formats or workflows, update the relevant `docs/*.md`.
4. **Reference sources:** If you add new data or cite examples, include proper attribution.
5. **Check .gitignore:** Don't accidentally commit artifacts or large files.

---

## Questions?

Open an issue or check the README for pointers. We keep things simple and straightforward here.

Happy contributing!
