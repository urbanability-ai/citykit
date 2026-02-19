# Release Checklist — v0.1 Public Release

Use this checklist before tagging a public release on GitHub. Goal: calm, reproducible, no surprises.

---

## Pre-Release (1–2 days before)

- [ ] Pull latest from `origin/main`
- [ ] `git status` is clean (no uncommitted changes)
- [ ] Run `make smoke` (quick validation)
- [ ] Run `make demo` (full generation)
- [ ] Run `make inspect` (output validation)
- [ ] Verify all tests pass (if any)

---

## Documentation Review

- [ ] README.md is current and links resolve
- [ ] docs/SCENARIO_SPEC.md matches current schema version
- [ ] docs/DATA_SOURCES.md is accurate (no URLs broken)
- [ ] docs/CONTRIBUTING.md reflects current contribution process
- [ ] ROADMAP.md has next-steps section
- [ ] CODE_OF_CONDUCT.md is in place

---

## Git Hygiene

- [ ] `.gitignore` covers artifacts/, *.zip, *.mp4, inputs/reference/**
- [ ] No stray `.env` files or secrets
- [ ] No large binaries in git history (check with `git log --all --full-history -- *.mp4 2>/dev/null | wc -l`)
- [ ] Commit history is clean (rebase if needed)

---

## Version Bump

- [ ] Decide version: `v0.1.0` (semantic versioning)
- [ ] Update `__version__` or `version` field (if present in code)
- [ ] Update version in `docs/SCENARIO_SPEC.md` if schema changed
- [ ] Commit any version updates: `git commit -m "chore: bump version to v0.1.0"`

---

## Tag & Release

1. **Create annotated tag:**
   ```bash
   git tag -a v0.1.0 -m "CityKit v0.1.0 — Initial public release"
   ```

2. **Push tag:**
   ```bash
   git push origin v0.1.0
   ```

3. **On GitHub:**
   - Go to Releases → Create Release
   - Select tag `v0.1.0`
   - Use the Release Notes Template (see below)
   - Attach sample output (optional): one `city_demo_kit.zip` from `make demo`

---

## Release Notes Template

Copy and customize for GitHub Release body:

```markdown
## CityKit v0.1.0

**Initial public release.**

### What's Included

- Scenario manifest schema (v0.2)
- OpenStreetMap–compatible map generation
- Stub video generation (placeholder media)
- Example corridor & delta inputs
- Comprehensive docs (SCENARIO_SPEC, DATA_SOURCES, CONTRIBUTING)
- MIT license + Code of Conduct

### What's Placeholder

- Video outputs are textured stubs (real camera outputs in v0.2)
- Ground-truth geometry & metrics not generated (v0.2)
- Actor trajectories declared but not executed (v0.2)

### How to Use

```bash
make demo
make inspect
```

→ See README.md for quickstart.

### What's New

- Scenario spec finalized (v0.2 schema)
- Example corridors & deltas
- Data source policy (OSM only; no Google Maps)
- Contributing guide + Code of Conduct

### Known Limitations

- No real camera feeds yet
- No trajectory simulation
- No KPI computation
- Videos are stubs (install ffmpeg for mp4; otherwise text placeholders)

### Next Steps

→ See ROADMAP.md and SCENARIO_SPEC.md for v0.2 + v0.3 plans.

---

**Thanks for trying CityKit!** Questions? See CONTRIBUTING.md.
```

---

## Post-Release (announcement)

- [ ] Post on internal channels (if any)
- [ ] Optional: social post (use docs/LAUNCH_POST.md template)
- [ ] Update README badge (if desired): `v0.1.0 ✅`
- [ ] Create pinned Discussion on GitHub (copy docs/READ_THIS_FIRST.md)

---

## Rollback Plan

If something breaks post-release:

1. Delete the tag locally: `git tag -d v0.1.0`
2. Delete on GitHub: `git push origin --delete v0.1.0`
3. Fix the issue
4. Re-tag: `git tag -a v0.1.0 -m "CityKit v0.1.0 (corrected)"`
5. Push: `git push origin v0.1.0`

---

## Notes

- Don't rush. Run the full test suite even if it takes 30 minutes.
- Verify .gitignore one more time; once it's public, rewriting history is messy.
- Keep release notes **honest**: if it's a stub, say so.
- Link to SCENARIO_SPEC in release notes so people understand what's real.

---

_Done? Celebrate. You're shipping._
