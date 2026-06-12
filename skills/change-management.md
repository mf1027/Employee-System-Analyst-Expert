# Skill: change-management

## Purpose
Assess a change request against the confirmed scope baseline — impact on
requirements, schedule, risks, and cost — and produce a recommendation for
the decision-maker before any change is accepted into scope.

## Trigger
Invoke when the operator says "change request", "the client wants to add X",
"scope change", "assess this change", or "the requirements changed".

## Minimum context required
- The proposed change (description of what is being added, removed, or modified)
- The client / project
If missing: ask for the change description and which project it relates to.

---

## Steps

1. Read `memory/memory.md` and `memory/clients/[client-name].md`.
2. Read the project's `requirements.md` (baseline), `plan.md` (current schedule),
   `risks.md`, and `database.md` (if the change affects data).
3. Assign the next Change Request ID: `CR-NNN`.
4. Classify the change:
   - **Type:** Addition / Modification / Removal / Correction
   - **Driver:** Client request / Regulatory / Error in requirements / Discovery
5. Assess impact across four dimensions:
   a. **Scope:** Which REQ- entries are affected? What is added/removed?
   b. **Schedule:** Additional effort (three-point estimate). Which milestones slip?
   c. **Risk:** Does this introduce new RISK- entries or worsen existing ones?
   d. **Cost:** Effort delta in days (for the operator to convert to cost).
6. State a recommendation: Accept / Reject / Defer with rationale.
7. If recommending Accept: list the conditions (what must be updated, who must sign off).
8. **Notification list** — who must be informed of this change request regardless of outcome:
   - All stakeholders whose deliverable, milestone, or requirement is affected
   - Any stakeholder in "Manage closely" or "Keep satisfied" quadrant (from stakeholders.md)
   - Flag for inclusion in the next status report.
9. Output. Wait for confirmation before updating any project files.

---

## Output format

```
CHANGE REQUEST: CR-[NNN]
Project: [name] | Client: [name] | Date: [YYYY-MM-DD]
Requested by: [Stakeholder / role]
---
Change: [Plain-English description of what is being requested]
Type: [Addition / Modification / Removal / Correction]
Driver: [Why this is being requested]

Impact assessment:
  Scope:
  - Adds: [new requirements, if any]
  - Modifies: REQ-F0X — [what changes]
  - Removes: [any requirements being dropped]
  - Out-of-scope impact: [does this set a precedent that opens the door to other changes?]

  Schedule:
  - Additional effort: [O / ML / P / PERT estimate]
  - Milestones affected: [which ones slip, by how much]
  - Critical path: [affected / not affected]

  Risk:
  - New risks: [RISK-NNN: description] — or "none"
  - Existing risks worsened: [RISK-NNN: how it worsens] — or "none"

  Database impact:
  - [Schema changes? Migration required? — or "none"]

Cost delta: ~[X] days effort

Recommendation: [ACCEPT / REJECT / DEFER]
Rationale: [Why — tied to specific requirements, constraints, or risks]
Conditions (if Accept): [What must happen before this is in scope]

Notify: [list stakeholders to inform — regardless of decision]
Status report flag: [Yes — include in next status report / No — minor change, internal only]

Next: confirm recommendation → update requirements.md, plan.md, risks.md if accepted → notify stakeholders
```

---

## Quality checklist

- [ ] Is the change described in plain language (not just a ticket ID)?
- [ ] Are ALL four impact dimensions assessed — scope, schedule, risk, cost?
- [ ] Does the recommendation have a rationale tied to project facts?
- [ ] If accepted: are conditions stated explicitly?
- [ ] Does the database lens check for schema/migration impact?
- [ ] Is the precedent risk assessed (does this open the door to more changes)?
- [ ] Is the notification list complete — all affected stakeholders identified?
- [ ] Is the status report flag set appropriately?

## Failure exit
"Cannot assess a change without knowing what the change is and which project it
affects. Provide the change description and project name."
