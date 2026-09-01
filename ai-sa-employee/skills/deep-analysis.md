# Skill: deep-analysis

## Purpose
Deep analysis before implementation — root cause, gap analysis, adversarial self-review, and an
explicit GO / GO WITH CONDITIONS / NO-GO verdict. This is **the depth implementation of ADR-105
Phase 1**, not a parallel protocol: ADR-105 already mandates "RCA + Gap Analysis before any plan"
and owns the surrounding sequence (Plan → Approval → Execute → Sync → Changelog). This skill only
answers *how deep, with what rigor, and how do I know when I'm done*.

## Trigger
Invoke when the operator says "analyze this deeply", "RCA this", "is this the right approach",
"challenge this plan", "should we build this", "what's the real cause" — or automatically whenever
ADR-105 Phase 1 fires on a **FULL-tier** task (see Step 0).

## Minimum context required
- The thing being analyzed: a bug, a feature, a change, or a decision.
- Read access to the relevant source, schema, and the project's own lane files.
If missing: ask one crisp question naming exactly what you need, then stop.

---

## Steps

### 0. Tier the work first — depth scales, presence doesn't
`CLAUDE.md` requires proportionate deliverables; ADR-109 requires RCA presence to be unconditional.
Both hold: **always do Steps 1–3; the adversarial loop (Step 4) is what scales.**

| Tier | When | Depth |
|---|---|---|
| **FULL** | Schema/DDL, multi-file, money/IDs/auth/data-integrity, architecture decisions, client-facing | Steps 1–6, up to 5 adversarial cycles |
| **ABBREVIATED** | Single-file, scoped, reversible | Steps 1–3 + 6. One adversarial pass, not a loop |
| **SKIP** | Lookups, read-only questions (Tier 2 per `CLAUDE.md` #1) | Answer directly. Say so — don't perform ceremony |

State the tier in one line before proceeding. Guessing high wastes the operator's time; guessing low
is how SKL-035 and SKL-046 happened.

### 1. Understand — and check our own records BEFORE treating anything as new
This repo's most expensive recurring failure is re-deriving what already exists (SKL-011, SKL-029,
SKL-035, SKL-044, SKL-046). Before any claim of "undocumented" / "no record of" / "new":

- Grep `decisions.md`, `risks.md`, `requirements.md`, `database.md`, `deliverables/documents/`.
- Open the artifacts. A status label ("interview pending", "✅ Current") is a claim, not evidence (SKL-041).

Then trace **upstream → target → downstream**: callers, the target itself, and every consumer.
For code: controllers, services, repositories, DTOs, entities, config, auth, frontend consumers, tests.
For data: lane files, live schema, views/procs/TVFs, drills, ERDs, mock/seed scripts.

### 2. Root cause — one chain, the repo's existing fields mapped onto it
Use a single causal chain. **Symptom → Immediate Cause → Contributing Cause → Architectural Cause →
Root Cause.** SKL-050's drill fields are not a second format — they are levels of this same chain:
*Mechanism* = Immediate Cause · *Since when* = when the Contributing Cause entered · *New or
recurring* = whether an Architectural Cause exists (a 3rd+ recurrence means the fix's **shape** is
wrong, not that another one-off entry is needed).

Label every conclusion:

| Label | Bar |
|---|---|
| **Confirmed** | A citation exists — `file:line`, or DB object + the query run. No citation, no Confirmed. |
| **Highly Likely** | Strong indirect evidence, consistent with everything checked |
| **Possible** | Plausible, untested |
| **Unverified** | Stated as hypothesis only — never assert as fact |

Evidence outranks assumption, in this order: **live code / DB catalog → operator → API contracts →
tests → config → call sites → docs & labels → inference.** DDL gives structure only; semantics come
from the source or the operator (SKL-006/008).

### 3. Gap analysis — current vs. required
For each material gap: **Gap → Impact → Required Change.** Cover logic, data, schema, contracts,
validation, business rules, error handling, security, authorization, transactions, concurrency,
performance, null handling, state transitions, testing, observability, migration, backward
compatibility.

**Delegate, don't duplicate:** for anything schema-touching, `dba-cross-domain-impact` is the
blast-radius engine (Breaking/Incomplete/Cosmetic/None + `IC-` checklist + execution order). Run it
and cite its output — do not produce a competing, coarser impact list.

### 4. Adversarial review — attack your own analysis (FULL tier)
Distinct from CHALLENGE mode, which attacks the **client's scope before planning**
(`references/modes.md`). This attacks **your own draft analysis after it exists**. For scope
feasibility and cut/defer decisions, chain to CHALLENGE rather than re-deriving it here.

Assume the plan is wrong. What assumption could be false? What breaks on implementation? Hidden
callers? Contract changes? Null/empty? Concurrency? Retries duplicating work? Does another feature
depend on the current behavior? Is this fixing the symptom? **Is there a simpler solution?**

If a material issue surfaces → return to Step 2. **Cap: 5 cycles.** After 5, stop and name the
unresolved uncertainty explicitly. Do not loop to feign confidence.

### 5. Separate scope — do not silently expand
**Required** (needed for the requested behavior) · **Recommended** (reliability/security/
maintainability) · **Out of scope** (real, unrelated — log as `RISK-`/`REC-`, don't fix inline).

### 6. Verdict — and what it does *not* authorize
**GO** · **GO WITH CONDITIONS** (list them) · **NO-GO** (name the blocking uncertainty).

> **A GO is not permission to build.** It means *the analysis is sound enough to present a plan*.
> `CLAUDE.md` Standing Instruction #1 and SKL-017's plan-gate still apply in full afterward.
> For a **change request specifically**, `change-management`'s ACCEPT/REJECT/DEFER remains the
> authoritative verdict — don't run two scales against the same CR.

---

## Output format

Internal reasoning may be long. **The delivered output is short.**

```
Tier: FULL / ABBREVIATED

## Verdict
GO / GO WITH CONDITIONS / NO-GO — one sentence.

## RCA
- Root cause [Confirmed/Highly Likely/Possible] — evidence: file:line
- Contributing cause, if material

## Gaps
- Gap → impact
- Gap → impact

## Plan
1. `file/component` — change
2. `file/component` — change
3. Validation / tests

## Risks
- Risk → mitigation

## Recommendation
One short paragraph.

## Confidence
High / Medium / Low. Not checked: [the main thing you did not verify].
```

---

## Quality checklist
- [ ] Tier stated up front; depth matches stakes (Step 0)
- [ ] Project's own lane files + deliverables grepped before any "new/undocumented" claim (SKL-011/029/046)
- [ ] Causal chain reaches an architectural cause, or says explicitly why it stops earlier
- [ ] Every "Confirmed" carries a real citation — no citation means Highly Likely at best (SKL-041)
- [ ] `dba-cross-domain-impact` run and cited for schema-touching gaps, not re-derived
- [ ] Adversarial pass actually changed something, or states plainly that it didn't (a rubber-stamp is not a review)
- [ ] Cycle count ≤ 5; residual uncertainty named, not hidden
- [ ] Required / Recommended / Out-of-scope separated — no silent scope growth
- [ ] Verdict stated; GO explicitly does not bypass the Tier 1 / SKL-017 plan gate
- [ ] Confidence names what was NOT checked
- [ ] Triple-lens applied (SA / PM / DBA) per `CLAUDE.md` #11

## Failure exit
"Nothing concrete to analyze. Name the bug, feature, change, or decision — and point me at the file, table, or ticket."
