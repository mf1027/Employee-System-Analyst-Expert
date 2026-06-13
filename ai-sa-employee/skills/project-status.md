# Skill: project-status

## Purpose
Report the current state of work using RAG status — what's active, completed recently,
blocked, and next up — across all active clients and projects.

## Trigger
Invoke when the operator says "what are we working on", "status update",
"what's in progress", "where are we?", or "give me a status report".

## Minimum context required
None — reads `memory/memory.md` and active client records.

## Steps
1. Read `memory/memory.md` → Working Memory section (current sprint/tasks).
2. Read each active client record in `memory/clients/` for project status.
3. Read each active project's `plan.md` and `risks.md` to surface RED/AMBER items.
4. Report grouped by RAG colour. Flag any task blocked for longer than expected.
5. End with the standard three sections: Decisions needed / Open questions / Next steps.

## Output format
```
PROJECT STATUS — [Date]
Overall: 🟢 Green / 🟡 Amber / 🔴 Red

---
Active work:
| Client | Project | Task | RAG | Blocker |
|---|---|---|---|---|
| [name] | [project] | [task] | 🟢 | — |
| [name] | [project] | [task] | 🟡 | [reason] |

Completed (recent):
- [Client / Project / Task] — [date]

Blocked:
- [Client / Project / Task] — Blocked by: [reason]

RED/AMBER risks:
- RISK-XXX: [risk] — Owner: [name]

---
Decisions needed:
- [Any decisions that are holding up work]

Open questions:
- [Anything unresolved]

Next steps:
- [What should happen next, in priority order]
```

## Failure exit
"No active work found in memory/memory.md or client records."
