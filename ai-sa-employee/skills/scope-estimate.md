# Skill: scope-estimate

## Purpose
Break a piece of work into tasks with three-point estimates, a confidence level,
and risk flags — before any commitment is made. Uses PERT to produce a defensible
range rather than a single-point guess.

## Trigger
Invoke when the operator says "how long will X take", "estimate this",
"scope this work", or "what's the effort for X?".

## Minimum context required
- A work description (feature, change, migration, or project phase)
- Any known constraints (deadline, team size, environment)
If missing: ask for the description and constraints.

## Steps
1. Consult current canonical Obsidian/project memory for prior estimates, then read the
   project's `requirements.md`, `risks.md`, and `plan.md`.
2. If the work touches database topics, also read the project's `database.md`.
3. Output a CONTEXT SUMMARY — what I read, relevant risk factors, confidence.
4. Break the work into discrete, estimable tasks.
5. For each task: apply three-point estimation (Optimistic / Most Likely / Pessimistic)
   and calculate the PERT estimate: (O + 4×ML + P) ÷ 6.
6. Apply a confidence level. Lower it if `risks.md` has open HIGH risks touching
   this work, or if requirements have unresolved `[TBC]` items.
7. **Apply the calibration correction:** read the project's `calibration.md` —
   if a running ratio exists (3+ completed items), multiply the PERT totals by it
   and show both numbers ("raw PERT: 5d, calibrated: 6.5d — past estimates ran 30% under").
8. List risks, assumptions, and blockers.
9. **Log the estimate to `calibration.md`** (date, item, PERT) — the actual gets
   filled by `end-of-task` when the work completes. Every estimate is logged; an
   unlogged estimate can never improve future ones.

## Output format
```
SCOPE ESTIMATE: [Work Name]
Client: [name] | Project: [name] | Date: [YYYY-MM-DD]
---
Context: I read [files]. Confidence: [level] because [reason].

Tasks:
| # | Task | O | ML | P | PERT | Notes |
|---|---|---|---|---|---|---|
| 1 | [Description] | [Xd] | [Xd] | [Xd] | [Xd] | |
| 2 | ... | | | | | |

Total PERT: [X days] | Range: [O–P] | Confidence: [High/Medium/Low]

Risks to estimate:
- RISK-XXX: [risk that could blow this estimate]

Assumptions:
- [What I assumed to reach these numbers]

Blocked by:
- [Prerequisites, unknowns, or TBC requirements — or "none"]
```

## AI-assisted effort compression

When the work involves AI-generated code or content, apply these compression ratios
before presenting estimates to the owner or client:

| Work type | Human baseline | AI compression | Effective multiplier |
|---|---|---|---|
| Boilerplate / scaffolding | 100% | ~1% | ~100× faster |
| CRUD / standard patterns | 100% | ~10% | ~10× faster |
| Business logic / rules | 100% | ~30% | ~3× faster |
| Architecture / design decisions | 100% | ~20% | ~5× faster |
| Research / analysis | 100% | ~33% | ~3× faster |
| Integration / third-party wiring | 100% | ~40% | ~2.5× faster |
| Security review / testing | 100% | ~50% | ~2× faster |

Use these to set realistic expectations: a feature that takes a human developer
5 days may take 1–2 days with AI-assisted development. Flag the assumption explicitly.

## Failure exit
"Insufficient information to estimate. Need: [description of what's missing]."
