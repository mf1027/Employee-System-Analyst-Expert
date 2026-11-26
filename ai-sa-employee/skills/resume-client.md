# Skill: resume-client

## Purpose
Register an existing client folder that was manually copied into `memory/clients/`
(e.g., from another machine or backup). Reads all existing project files, rebuilds
the local index only when its source is current, and surfaces current project status from the canonical project records. It does not sync to a secondary memory service.

## Trigger
Invoke when the operator says:
- "I have an ongoing client that I manually inserted"
- "I copied the client folder"
- "resume client" / "resume client [name]"
- "I have an existing client already"
- "I moved to a different PC"
- "may existing client ako" / "nag-copy ako ng client folder"
- "bagong machine, may client na ako"
- "I transferred my client files"

## Minimum context required
- `memory/clients/` must contain at least one folder.
If empty: "No client folders found in `memory/clients/`. Copy the folder there first,
then tell me."

---

## Steps

### Step 1 — Scan `memory/clients/`

List all subfolders in `memory/clients/`.

- **1 folder found** → proceed automatically with that client
- **Multiple folders found** → show list, ask:
  > Found [N] client folders: [list]. Which one do you want to resume?
  > (Or say "all" to register them all.)
- **No folders found** → stop:
  > No client folders found in `memory/clients/`. Copy the folder from your other
  > machine into this directory, then tell me and I'll resume.

---

### Step 2 — Read client record

Read `memory/clients/[name]/[name].md`.

- If file exists → extract: active projects, tech stack, constraints
- If file is missing → note it and reconstruct from project files:
  > Client record file not found — I'll rebuild it from the project files. Continue?

Confirm to operator:
> Found: **[client-name]** — [N] project(s): [list of subfolders]. Correct?

---

### Step 3 — Read all project files

For each project subfolder found under `memory/clients/[name]/`:

| File | Extract |
|---|---|
| `requirements.md` | Confirmed REQ- IDs, out-of-scope items, open `[TBC]` items |
| `risks.md` | Open RISK- entries (status = Open), top risk by score |
| `plan.md` | Current phase, next milestone, target date |
| `tasks.md` | In-progress and open tasks with owners |
| `decisions.md` | Latest ADRs (last 3) |
| `database.md` | Known platform, any open migration risks |
| `calibration.md` | Running estimate ratio, risk hit rate (apply to future estimates) |

If a file is missing → create an empty scaffold silently, flag as `[TBC]`.

---

### Step 4 — Rebuild memory (Tier 0, corrected 2026-08-24 — SKL-050)

1. Update the canonical Obsidian client index only when its location and write authorization are confirmed.
2. Record the resume event in the canonical project status/decision record when appropriate.
3. This system runs at **Tier 0 — file memory only** (`CLAUDE.md` Memory Tiers, ADR-111).
   claude-mem is disabled — do not attempt to sync to it. The canonical Obsidian/project lane files are the durable record; the repository `memory/memory.md` snapshot is stale and not authoritative. If context-mode
   (`ctx_search`) is available, it may pick up this session's activity automatically, but its
   absence is not a failure and it is never the system of record.

---

### Step 5 — Status card

Show a compact status for each project resumed:

```
CLIENT RESUMED: [client-name]
─────────────────────────────────────────
Project:          [project-name]
Phase:            [current phase from plan.md — or TBC]
Next milestone:   [from plan.md — or TBC]
Open risks:       [N] — top: [RISK-NNN description]
Open tasks:       [N] — next: [task description / owner]
Open REQ TBCs:    [N] items still unresolved
Open questions:   [N]
─────────────────────────────────────────
Files synced:     requirements ✓  risks ✓  plan ✓  tasks ✓  decisions ✓  database ✓  calibration ✓
Missing files:    [list or "none"]
```

---

### Step 6 — Mode suggestion

Ask:
> Ready. What do you want to work on?
> A) Continue DISCOVER — gather more requirements
> B) Review open risks
> C) Update the plan
> D) Something else — tell me

---

## Edge cases

| Situation | Handling |
|---|---|
| `[name]/[name].md` missing | Rebuild from project files — prompt to confirm reconstruction |
| Project files missing | Create empty scaffolds silently, flag all fields as `[TBC]` |
| Client already in the canonical Obsidian index | Update the index row — do not duplicate |
| Multiple clients copied at once | Register all, show combined status card per client |
| Folder name doesn't match client record name inside | Use the folder name as the client identifier, note the mismatch |

---

## Quality checklist

- [ ] All client folders in `memory/clients/` detected?
- [ ] Client record read or reconstructed?
- [ ] All 7 project files read per project?
- [ ] Canonical Obsidian client index checked/updated only with authorization?
- [ ] Canonical Obsidian/project memory freshness checked; local snapshot not treated as authority
- [ ] Status card shows open risks, tasks, and next milestone?
- [ ] Missing files scaffolded silently?

## Failure exit
"No client folders found in `memory/clients/`. Copy the folder from your other machine
into `memory/clients/[client-name]/` and tell me to resume."
