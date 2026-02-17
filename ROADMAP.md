# ROADMAP (Next 8 Weeks) — Week-by-Week Plans

This roadmap is intentionally **week-by-week**. We publish a concrete plan at the start of each week and adjust based on what actually shipped.

**Non-goals**
- No long-range promises.
- No dependency on specific vendors, grants, or hardware.
- No guarantee that optional components will be available to everyone.

**Guiding rule**
If it can't be reproduced from a clean machine, it doesn't count as shipped.

---

## How weekly planning works

At the start of each week we publish a Week Plan file (e.g. `WEEK_2_PLAN.md`) with:
- goal for the week
- definition of done
- day-by-day task list
- risks / what might get cut

### How to suggest scope for next week

- GitHub Discussions: propose a goal + what it enables
- GitHub Issues: open an issue and label it `roadmap-candidate`

We prefer scope that tightens the "make demo → artifact pack" loop.

---

## Week 1 — Soft Launch v0.1 (Reproducible demo kit)
- repo front door + minimal kit generator
- clear pseudo vs ground-truth labeling

## Week 2 — "Better Map" v0.2 (OSM → usable intersection artifacts)
- optional OSM extraction step with clean fallback

## Week 3 — Actors v0.3 (Traffic participants, minimal realism)
- actor format + basic generator (can start as stub)

## Week 4 — Viewer v0.4 (Inspect what the kit contains)
- minimal local viewer for map/actors/camera paths

## Week 5 — Packaging + checks v0.5 (Make reproducibility boring)
- smoke checks + PR hygiene

## Week 6 — Pseudo 3D v0.6 (Optional video → pseudo point clouds)
- optional pipeline, clearly labeled pseudo, no metric claims

## Week 7 — KPI stubs v0.7 (Consistent reporting format)
- KPI schema + consistent report stubs

## Week 8 — Consolidation v0.8 (Tighten the loop)
- cleanup based on what shipped, reduce friction
