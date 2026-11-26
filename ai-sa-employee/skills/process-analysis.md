# Skill: process-analysis

## Purpose
Map the current-state process (AS-IS), identify root causes of pain using 5 Whys,
and design the future-state process (TO-BE) — so that solution design targets real
bottlenecks instead of surface symptoms.

## Trigger
Invoke when the operator says "process analysis", "map the current process",
"as-is/to-be", "what's the bottleneck", or "analyse the workflow".

## Minimum context required
- A process name or the problem area to analyse
- The client / project
If missing: ask which process and which client/project.

---

## Steps

1. Read current canonical Obsidian/project memory and the relevant client lane — domain context,
   glossary, known pain points.
2. Read the project's `requirements.md` — any requirements that reference this process.
3. **Official vs real process check** — before mapping, ask: "Is the process I'm
   being told the official documented one, or how it actually runs day-to-day?"
   If there is a gap, map BOTH and note discrepancies. The real process is the truth.
4. Map the **AS-IS process**:
   a. Steps in sequence, with the actor responsible for each.
   b. Inputs, outputs, systems, and handoff points.
   c. Known pain points, delays, errors, and workarounds at each step.
5. **Quantify the pain** — for the most significant pain point, ask for hard numbers:
   - Time cost: how long does this take? How many people? How often?
   - Error rate: how frequently does this step fail or require rework?
   - Financial cost: what is the cost per incident, per month?
   - If numbers are unknown, state "unquantified" — never omit the step.
6. Apply **5 Whys** to the most significant pain point: ask "why" five times to
   reach the root cause, not just a symptom.
7. Map the **TO-BE process**: the desired future state that removes the root cause.
   Mark which steps change, are removed, or are added.
8. Identify the **gap**: what needs to change to go from AS-IS to TO-BE.
9. Flag any gap that has significant technical, organisational, or database complexity.
10. Output. Wait for confirmation before writing process artifacts.

---

## Output format

```
PROCESS ANALYSIS: [Process Name]
Client: [name] | Project: [name] | Date: [YYYY-MM-DD]
---

AS-IS Process:
| Step | Actor | Input | Action | Output | System | Pain point |
|---|---|---|---|---|---|---|
| 1 | [Role] | [what arrives] | [what they do] | [what leaves] | [tool/system] | [delay/error/workaround] |
| 2 | ... | | | | | |

Official vs real process: [Same / Different — if different, describe the gap]

Primary pain point: [The most significant problem]
Pain quantified: Time: [X min/hrs per occurrence, Y times/week] | Error rate: [Z%] | Cost: [$X/month or "unquantified"]

5 Whys (root cause analysis):
1. Why? → [answer]
2. Why? → [answer]
3. Why? → [answer]
4. Why? → [answer]
5. Why? → Root cause: [specific, actionable root cause]

TO-BE Process:
| Step | Actor | Action | Change from AS-IS | Notes |
|---|---|---|---|---|
| 1 | [Role] | [what they do] | [Same / Modified / New / Removed] | |

Gap analysis:
| Gap | Category | Complexity | Notes |
|---|---|---|---|
| [What must change] | [Process/Technical/Data/People/DB] | [High/Med/Low] | |

Flags:
- [Any gap that requires significant DB change, integration, or org change]

Next: confirm analysis → feed gaps into requirements.md and risks.md
```

---

## Quality checklist

- [ ] Was the official vs real process distinction checked — are both mapped if they differ?
- [ ] Does the AS-IS map show EVERY actor involved, including edge-case handoffs?
- [ ] Is the pain quantified with numbers (time/error rate/cost) — or marked "unquantified"?
- [ ] Do the 5 Whys reach a root cause — not just a symptom?
- [ ] Does the TO-BE address the root cause directly?
- [ ] Are high-complexity gaps flagged for risk assessment?
- [ ] Are database-intensive gaps flagged for the DBA lens?

## Failure exit
"Cannot analyse a process without knowing which process and which client/project.
Provide the process name and a brief description of what it does."
