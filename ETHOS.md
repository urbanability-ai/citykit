# ETHOS — OpenClaw City Ops & Synthetic Scenario Factory

> **Vienna Rule:** If it can't be reproduced from a clean machine, it didn't happen.
>
> **Second Vienna Rule:** We ship the loop, not the slide deck.

This project exists to make **robot operations in real cities** feel inevitable:

- Cities get **clear, audit-friendly** infrastructure + curb rule plans.
- Operators get **run cards, incident playbooks, and deployment options**.
- Enthusiasts get **multi-perspective realism + datasets** they can train with.

No hype. Only artifacts.

---

## North Star

**A single command produces a city-grade demo kit:**

- multi-view video (robot, bike, van, pedestrian, bird's-eye)
- trainable geometry (depth → point clouds + labels)
- deployment plans (A/B/C) + KPIs
- ops playbooks (incidents + hybrid handoffs)
- a "hero cut" that makes people share it

**One scenario = one shareable proof.**

**One proof = one new collaborator.**

---

## Our Product Shape

We build two things that compound:

1) **Ops Control Room** - run ingest → QA → incident cards → playbooks → planning options
2) **Scenario Factory** - open data (OSM + public layers) → sim → render passes → dataset pack
   - **Veo is appearance. Sim is truth.**

---

## What We Optimize For

### ✅ Reproducibility
- Deterministic artifact folders with `run_id`
- Strict manifests + schemas
- Regression replays

### ✅ Operator-grade utility
- "What happened?" in 60 seconds
- "What to do next?" with a checklist

### ✅ Community magnetism
- Visual wow that stays honest
- Easy to try, easy to remix, easy to contribute

### ✅ Low-cost, low-friction
- Local-first on Hetzner/laptop
- Cloud only for "hero mode" or hard summarization

---

## Non-Negotiables

### 1) Artifacts > Opinions

Every task must output concrete files:

- `scenario.json`
- `dataset_manifest.json`
- `kpi_report.md`
- `renders/*.mp4`
- `depth/` + `seg/`
- `pcd_groundtruth/` OR clearly labeled `pcd_pseudo/`
- `REPRODUCE.md`

If you can't point to the artifact, it's not "done."

### 2) Truth Layer Separation

- **Truth layer:** sim depth, sim seg, simulated LiDAR (metric, trainable)
- **Appearance layer:** Veo / image models (photoreal, shareable)

We never pretend the appearance layer is geometry ground-truth.

### 3) CLI-first, UI later

The agent lives in tools. UIs exist to show outcomes, not to hide logic.

### 4) Strict Output Contracts

- JSON is valid JSON (no comments, no trailing commas)
- Units are explicit (m, s, m/s)
- Time is UTC or declared timezone—never "local maybe"

---

## Definition of Done (DoD)

A feature is done when:

1) `make demo` runs from a clean install OR a container
2) output artifacts match schema + pass checks
3) the README shows **3-step reproduction**
4) there is **one screenshot/clip** proving it
5) there is **one metric** (runtime, FPS, dataset size, KPI delta, cost)

---

## Shipping Cadence

### Daily
- Ship one improvement that touches the loop
- Produce one artifact pack
- Write one short changelog entry

### Weekly
- **Mon–Thu:** features
- **Fri:** refactor + docs + tests (refactor days are feature days)
- **Weekend:** "Intersection of the Week" release kit

---

## Tone & Communication

We're Austrian about it:

- direct, polite, minimal drama
- careful with claims
- always include the "receipt" (artifact link, command, metric)
- humor is allowed; excuses are not

---

## Open Data & Attribution

We use open datasets responsibly:

- OSM-derived layers are clearly attributed
- licensing notes live in `ATTRIBUTION.md`
- data provenance is tracked in `dataset_manifest.json`

---

## Safety & Ethics (Pragmatic)

We support safer streets and better operations, without moral theatre. We prioritize:

- auditability
- clarity of limits
- good defaults for privacy and redaction

---

## Anti-Goals (Things We Don't Do)

- We don't build a "platform" before we have a loop.
- We don't chase perfect realism before we have trainable truth.
- We don't add tools that increase maintenance burden without clear ROI.
- We don't ship features that can't be reproduced.

---

## Decision Rules (Fast, Sane)

If a decision blocks shipping:
- choose the simplest option that preserves the truth layer
- write it down in `DECISIONS.md`
- move on

If a decision affects trust:
- be explicit and conservative (label pseudo vs ground-truth)
- add a validation check

---

## The Motto (Pin this in your head)

**Ship the loop. Keep it honest. Make it reproducible.**
