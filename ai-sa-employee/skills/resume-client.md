# Skill: resume-client

## Purpose
Register an existing client folder that was manually copied into `memory/clients/`
(e.g., from another machine or backup). Reads all existing project files, rebuilds
the client index in `memory/memory.md`, syncs key context to claude-mem, and
surfaces the current project status so work can resume immediately.

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

### Step 4 — Rebuild memory

1. Update **Client Index** in `memory/memory.md` — add or update the client row
2. Write **Last Session** section in `memory/memory.md` with today's date and "Client resumed from copied folder"
3. Sync to **claude-mem**:
   - Open risks → `category:Risk`
   - Latest ADRs → `category:Decision`
   - Current phase + next milestone → `category:Requirements`
   - Tech stack → `category:Decision`

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
| Client already in `memory/memory.md` | Update the index row — do not duplicate |
| Multiple clients copied at once | Register all, show combined status card per client |
| Folder name doesn't match client record name inside | Use the folder name as the client identifier, note the mismatch |

---

## Quality checklist

- [ ] All client folders in `memory/clients/` detected?
- [ ] Client record read or reconstructed?
- [ ] All 7 project files read per project?
- [ ] Client Index in `memory/memory.md` updated?
- [ ] Key context synced to claude-mem?
- [ ] Status card shows open risks, tasks, and next milestone?
- [ ] Missing files scaffolded silently?

## Failure exit
"No client folders found in `memory/clients/`. Copy the folder from your other machine
into `memory/clients/[client-name]/` and tell me to resume."
