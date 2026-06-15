# Skill: new-client-setup

## Purpose
Onboard a new client through a lean conversational wizard. Creates the client folder
and record immediately after the name is given, creates the project scaffold immediately
after the project name is given, then gathers the remaining context before writing
anything further. All client data is stored under `memory/clients/` which is gitignored
and never pushed.

## Trigger
Invoke when the operator says "new client", "we have a new client", "onboard [client]",
"add a client", or "set up a client".

## Minimum context required
None — the skill asks for everything it needs.

---

## Steps

### Step 1 — Understanding Check
Restate: "Onboarding a new client — I'll create the folder and project scaffold as we go,
then capture the context. Correct?"
Wait for confirmation before proceeding.

---

### Step 2 — Client Name → create folder immediately

Ask:
> What's the client's name?
> *(Short slug — becomes the folder name. e.g., "ACME", "RetailCo", "JuanDev")*

After answer — **immediately create** without asking for confirmation:

```
memory/clients/[client-name]/
├── [client-name].md     ← client record (scaffold, filled as we go)
└── reference/           ← client documents drop here (PDF→MD, specs, contracts)
```

Confirm to operator:
> Created: `memory/clients/[client-name]/`

---

### Step 3 — Project Name → create project scaffold immediately

Ask:
> Project name?
> *(Short slug — e.g., "inventory-system", "customer-portal", "hr-app")*

After answer — **immediately invoke `new-project`** to create:

```
memory/clients/[client-name]/[project-name]/
├── README.md
├── requirements.md
├── stakeholders.md
├── risks.md
├── plan.md
├── tasks.md
├── decisions.md
├── communication.md
├── database.md
├── calibration.md
└── deliverables/
    ├── reports/
    ├── diagrams/
    ├── documents/
    └── pdf/
```

Confirm to operator:
> Created: `memory/clients/[client-name]/[project-name]/` — 10 files + deliverables scaffold.

---

### Step 4 — Problem Statement

Ask:
> What problem are they trying to solve? One sentence — the pain, not the solution.
>
> Good: *"Their payroll is manual and takes 3 days every cutoff"*
> Not: *"They want a payroll app"*

---

### Step 5 — Engagement Type

Ask:
> Type of engagement?
> A) New build — greenfield
> B) Enhancement — adding to existing system
> C) Migration / Conversion — porting or rewriting an existing app into a new language/stack
> D) Audit / review only

**Conversion profile detection:** if the answer is **C**, or **B** where the work is actually a
language/stack rewrite (e.g. "rebuild the old PHP app in Node"), set the **conversion profile** on
this project. `new-project` then also scaffolds the `migration/legacy/` + `migration/target/`
dual resource + `conversion.md`, and you invoke `conversion-analysis` to map parity. Capture the
source→target stack here so it's ready for Step 8.

---

### Step 6 — Timeline + Dev Team (batched)

Ask:
> Two quick ones:
> 1. Target go-live? *(rough — "Q4 2026" or "ASAP" is fine)*
> 2. Dev team ready? *(Yes / No / TBC)*

---

### Step 7 — Summary Card

Show before writing anything further:

```
NEW CLIENT SUMMARY
─────────────────────────────────
Client:   [client-name]
Project:  [project-name]
Problem:  [one-liner]
Type:     [A/B/C/D]
Go-live:  [absolute date or ASAP]
Dev team: [Yes/No/TBC]
```

---

### Step 8 — Tech Stack

Ask:
> What's the required tech stack? Skip anything that's TBC.
>
> 1. Frontend? *(e.g., React, Vue, Next.js, mobile — or TBC)*
> 2. Backend? *(e.g., Node.js, Laravel, Python — or TBC)*
> 3. Database? *(e.g., PostgreSQL, MySQL, MongoDB — or TBC)*
> 4. Hosting / Cloud? *(e.g., AWS, Azure, GCP, local server — or TBC)*
> 5. Key integrations? *(e.g., payment gateway, third-party APIs — or none)*

After answer — write tech stack to `[client-name].md` and flag known stacks in
`[project-name]/decisions.md` as early ADR context.

---

### Step 9 — Update client record

Write all gathered context to `memory/clients/[client-name]/[client-name].md`
using the schema below. Write project entry to the Active Projects table.
Update the Client Index in `memory/memory.md`.

---

### Step 10 — Mode Suggestion

Ask:
> All set. What's next?
> A) Start DISCOVER — gather requirements now
> B) Ingest a document first — drop a file in `memory/clients/[client-name]/reference/`
> C) Just the record for now — continue later

---

## Client record schema

```markdown
# Client: [Client Name]

## Profile
- **Record created:** YYYY-MM-DD
- **Last updated:** YYYY-MM-DD

## Active Projects
| Project | Type | Go-live | Dev Team | Status |
|---|---|---|---|---|
| [project-name] | [New build / Enhancement / Migration / Audit] | [date] | [Yes/No/TBC] | Active |

## Tech Stack
- **Frontend:** [stack or TBC]
- **Backend:** [stack or TBC]
- **Database:** [stack or TBC]
- **Hosting / Cloud:** [stack or TBC]
- **Integrations:** [list or none]

## Key Constraints
[TBC — probe in DISCOVER]

## Compliance / Regulatory
[TBC — probe in DISCOVER]

## Domain Glossary
| Term | Meaning |
|---|---|
| | |

## Open Questions
- [ ] —
```

---

## Folder structure (reference)

```
memory/clients/                        ← gitignored — never pushed
└── [client-name]/
    ├── [client-name].md               ← client record
    ├── reference/                     ← client documents (PDF→MD, specs, contracts)
    └── [project-name]/
        ├── README.md
        ├── requirements.md
        ├── stakeholders.md
        ├── risks.md
        ├── plan.md
        ├── tasks.md
        ├── decisions.md
        ├── communication.md
        ├── database.md
        ├── calibration.md
        └── deliverables/
            ├── reports/
            ├── diagrams/
            ├── documents/
            └── pdf/
```

---

## Quality checklist

- [ ] Client folder and record created immediately after Step 2
- [ ] Project scaffold created immediately after Step 3 (via new-project)
- [ ] Tech stack written to both client record and decisions.md
- [ ] Client Index in memory/memory.md updated
- [ ] All relative dates converted to absolute

## Failure exit
"Setup incomplete — missing [field]. Provide it and I'll continue."
