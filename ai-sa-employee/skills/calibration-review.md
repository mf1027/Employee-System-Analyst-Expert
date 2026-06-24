# Skill: calibration-review

## Purpose
Close the estimation feedback loop. Every project scaffold has a `calibration.md`, but nothing
*drives* it — so estimates never learn from actuals and the same optimism bias repeats forever.
This skill makes calibration active: record each completed item's estimate-vs-actual, compute the
running bias, track risk hit-rate and scope churn, and **feed the correction back into the next
`scope-estimate`.** A senior estimator's edge isn't a better gut — it's a measured track record.

## Trigger
Invoke when the operator says "calibrate", "calibration review", "how accurate were our estimates",
"update calibration", "were we right about the risks", "estimate accuracy", "tama ba mga estimate
natin". Also auto-prompted by `weekly-review` (calibration check) and `end-of-task` (log the actual).

## Minimum context required
- The project's `calibration.md` (estimate-vs-actual log + risk hit-rate).
- For a new data point: the task, its original estimate, and its actual.
If `calibration.md` is empty: that's fine — start populating it; report "no trend yet" honestly
rather than inventing one from one data point (the n=1 trap).

---

## What it tracks

| Dimension | Question it answers | Source |
|---|---|---|
| **Estimate accuracy** | Are we optimistic, pessimistic, or calibrated? By how much? | Estimate vs Actual log |
| **Estimation bias (ratio)** | Running `actual / estimate` — >1 = under-estimating | Computed from the log |
| **Risk hit-rate** | Of risks we flagged, how many materialized? Are we crying wolf or missing real ones? | Risk Hit Rate table |
| **Scope churn** | How much did requirements change after baseline? | `requirements.md` / change log |

---

## Steps
1. Read `calibration.md`, plus `plan.md`/`tasks.md` (for estimates) and `risks.md` (for risk outcomes).
2. **Log new actuals** — for each completed item, append `Task | Estimated | Actual | Ratio | Notes`.
   The note captures *why* it diverged (the learnable part: "underestimated the data migration", not
   just "took longer").
3. **Compute the running bias** — mean and spread of the ratio. Call it out:
   - ratio ≈ 1.0 (±15%) → calibrated, keep estimating as-is
   - ratio > 1.15 → systematically optimistic → inflate future estimates by the factor
   - ratio < 0.85 → padding → tighten
4. **Update risk hit-rate** — mark resolved risks Hit/Miss. Too many misses = over-flagging (noise);
   missed materialized risks not on the register = blind spots → coaching note.
5. **Note scope churn** — significant requirement changes since baseline, as context for variance.
6. **Feed forward** — state the explicit correction the next `scope-estimate` should apply
   (e.g. "apply ×1.3 to data-heavy tasks"). This is the whole point — calibration that doesn't
   change the next estimate is just bookkeeping.
7. Apply the **triple lens** (SA: were missed requirements the cause of overruns? · PM: schedule/
   budget impact of the bias? · DBA: are DB tasks a recurring overrun category?).
8. Confirm before writing; update `calibration.md`. Surface at least one `REC-`.

---

## Output format
```
CALIBRATION REVIEW — [project] — [YYYY-MM-DD]
Data points: [N completed items]   (n<3 → trend is indicative only, not reliable)

ESTIMATE ACCURACY
  Running ratio (actual/estimate): [X.XX] ± [spread]   → [calibrated / optimistic / padded]
  Worst category: [e.g. data migration ×1.8]   Best: [e.g. UI ×1.0]

RISK HIT-RATE
  Flagged: [N]   Materialized: [M]   Hit-rate: [M/N]
  Blind spots (materialized, not flagged): [list or "none"]
  Over-flagging (flagged, never close to happening): [list or "none"]

SCOPE CHURN
  [significant changes since baseline — or "stable"]

FEED-FORWARD CORRECTION (apply in next scope-estimate)
  → [explicit multiplier/adjustment, e.g. "×1.3 on data-layer tasks; UI as-is"]

REC-NNN: [process improvement to reduce the bias at its source]
```

Close with **Decisions needed / Open questions / Next steps**.

## Quality checklist
- [ ] Every completed item has estimate, actual, ratio, and a *why* note (the learnable part)
- [ ] Running bias computed with spread, not a single ratio claimed as precise
- [ ] n<3 explicitly flagged as indicative-only (don't overfit on one data point)
- [ ] Risk hit-rate updated; blind spots and over-flagging both surfaced
- [ ] A concrete feed-forward correction stated for the next `scope-estimate`
- [ ] At least one `REC-`; triple-lens applied

## Failure exit
"`calibration.md` has no completed items with actuals yet — there's nothing to calibrate against.
I'll start the log as tasks finish (via `end-of-task`); after ~3 data points the trend becomes
meaningful. For now, estimates stand on three-point reasoning, not history."
