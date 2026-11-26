# Skill: ingest-meeting-notes

## Purpose
Extract structured information from meeting notes, call summaries, client feedback,
or any informal update — and auto-capture decisions, requirements, risks, action items,
and open questions into the correct project files via the approved canonical project files. Do not write automatically without the required understanding/approval gate.

## Trigger
Invoke when the operator says "meeting notes", "notes from the call", "transcript",
"client said X", "got feedback from client", "here's what came out of the meeting",
or pastes a block of raw notes.

## Minimum context required
- The notes text (pasted or described by the operator)
- Which client and project they relate to
If missing: ask which client/project these notes belong to, then proceed.

---

## Steps

1. Read `memory/clients/[client-name].md` — context, comms style, domain glossary.
2. Read the project's `requirements.md`, `risks.md`, `decisions.md` — current state,
   to detect new vs already-logged items.
3. **Parse the notes** and extract ALL of the following that exist:
   a. **Decisions made** → ADR candidates or general decisions
   b. **Requirements surfaced** → REQ-F (functional) or REQ-NF (non-functional) candidates
   c. **Risks raised** → RISK- candidates
   d. **Assumptions stated** → ASS- candidates
   e. **Action items** → owner + due date (if stated)
   f. **Open questions** → unresolved items from the meeting
4. Store each extracted item in **canonical project memory** via approved project-memory update:
   - **Title:** `[Type] — [project] — [YYYY-MM-DD] — [short title]`
   - **Tags:** `type:[decision/requirement/risk/assumption/action/question]`,
     `client:[name]`, `project:[name]`, `source:meeting-[YYYY-MM-DD]`
5. Surface all extracted items in the output — show the operator exactly what was captured.
6. Flag what needs formal logging with the right skill to run next.

---

## Output format

```
MEETING NOTES INGESTED
Client: [name] | Project: [name] | Date: [YYYY-MM-DD]
Source: [meeting / call summary / client email / UAT feedback / other]
---

Decisions (ADR candidates):
- [Decision stated] → log in decisions.md as ADR-NNN

Requirements (REQ- candidates):
| Proposed ID | Description | Type | Priority | Source |
|---|---|---|---|---|
| REQ-F0X | [requirement] | Functional | P0/1/2 | [stakeholder] |
| REQ-NF0X | [NFR] | Non-functional | | |

Risks (RISK- candidates):
| Proposed ID | Risk | Category | Notes |
|---|---|---|---|
| RISK-0XX | [risk] | [Schedule/Technical/Compliance/DB/etc.] | |

Assumptions (ASS- candidates):
- ASS-0XX: [assumption] — risk if wrong: [consequence]

Action items:
| Action | Owner | Due | Notes |
|---|---|---|---|
| [what] | [who] | [YYYY-MM-DD or TBD] | |

Open questions:
1. [Question] — blocking: [REQ-/RISK-/ADR- if applicable]

Stored in canonical project memory: [N] entries

---
Flags — needs formal logging:
- requirements.md: [N] new candidates → run gather-requirements to formalise
- risks.md: [N] new candidates → run risk-management to formalise
- decisions.md: [N] ADR candidates → review and log
- plan.md / tasks.md: [N] action items to add
```

---

## Quality checklist

- [ ] Were all six item types checked? (decisions, requirements, risks, assumptions, actions, questions)
- [ ] Is every action item assigned an owner — even if "TBD"?
- [ ] Are REQ- / RISK- / ADR candidates flagged for formal logging?
- [ ] Were conflicts with existing entries in requirements.md / risks.md checked?
- [ ] Is the source tagged in canonical project memory for traceability?

## Failure exit
"No notes provided. Paste the meeting notes or summary and tell me which project they relate to."
