# Employee System Analyst Expert

A Claude Code workspace that acts as a **senior AI employee** — System Analyst, Solutions Architect,
and Project Manager — working directly for you across multiple client projects.

---

## What is this?

This is not a generic AI assistant. It is a configured Claude Code environment that behaves as a
full-time senior employee with defined roles, memory, skills, and governance rules.

**What the employee does:**
- Gathers and structures requirements (REQ- IDs, MoSCoW, acceptance criteria)
- Analyses processes (AS-IS / TO-BE maps, BPMN, gap analysis)
- Designs solutions and architectures (C4 model, ADRs, tech stack decisions)
- Manages risks (RAID log, probability/impact scoring, owners)
- Plans projects (WBS, critical path, milestones, scope estimates)
- Advises on databases (schema design, migration safety, HA/DR, cost)
- Produces formal documents (SRS, PRD, SDD, status reports)

**Primary lane:** thinking and specifying — it analyses, plans, governs, and advises by default.
**Implementation and verification are available, not default:** when you direct a specific code
change, DB fix, or test/drill, it executes directly (Claude Code has real file/build/DB
capability) rather than manufacturing a handoff — gated by a plan and your explicit go-signal
first, same as any DB-mutating or multi-file work. It does not invent scope or start building
unprompted; that stays a proposal for you to approve. *(Retired 2026-08-25, ADR-121 — this used
to be an absolute "does not write code" rule, contradicted by continuous practice.)*

---

## Quick Start

### New machine — first time

1. Clone the repository
2. Open the folder in Claude Code
3. Run the setup script:

```powershell
# Windows
scripts\setup.ps1
```
```
# Linux / Mac
bash scripts/setup.sh
```

The script checks and installs:
- Node.js dependencies (`claude-mem`, `context-mode`, `@opendataloader/pdf`)
- Python `chromadb` for semantic memory search
- Checks for the upstream Ponytail plugin in Claude Code and Codex
- Checks optional Ollama CLI/service state and the explicitly configured local model
- Prints Claude Code and Codex Ponytail install commands if needed
- Reminds you to review/trust hooks and restart the agent runtime

4. Install any missing plugins printed by the setup script in Claude Code or Codex
5. Review/trust Ponytail hooks, then reload Claude Code or open a fresh Codex task

**You're ready.** Open this folder in Claude Code and start a session.

### Optional local Ollama model

Ollama supplies inference; Claude Code and Codex remain the agent hosts that load the repository
skills, execute tools, enforce permissions, and run hooks. Configure an explicit locally installed
model before using the local path:

```powershell
$env:OLLAMA_HOST = "http://localhost:11434"
$env:OLLAMA_MODEL = "<local-model-name>"
$env:RUNTIME_SYNC_PROVIDER = "ollama"
ollama launch claude --model $env:OLLAMA_MODEL
ollama launch codex --model $env:OLLAMA_MODEL
```

The setup scripts check Ollama, service reachability, and the exact model but never pull, select, or
switch models automatically. For reliable agent work, verify adequate context and read-only tool
calling with the selected model. Ollama does not make Claude and Codex hooks identical; verify each
host independently.

Native Claude, Ollama-backed Claude, native Codex, and Ollama-backed Codex are four separate
verification targets. Claude project hooks can record the active host/provider pair; Codex
project-hook support must be verified against the installed CLI. If Codex hooks are unavailable,
run the runtime skill's explicit evidence flow. First run a `runtime-sync.mjs --dry-run` with safe,
matching host evidence; only a postflight that also supplies `--authorize-mindmap` can update the
Agent Tooling Mindmap. `RUNTIME_SYNC_PROVIDER=ollama` prevents a native session from being
misreported as Ollama-backed. `runtime-sync.mjs --verify` can report `VAULT_READY` only; it checks
the vault artifacts and does not verify a host tool, Ponytail hook, or Ollama model. The project
does not retain broad automatic Claude command approvals; review each requested command.

---

## How Sessions Work

Every session starts with a hard gate:

1. **Environment check** — the employee verifies claude-mem and context-mode are responding
   and announces the active memory tier; if memory is degraded it says so explicitly
2. Reads `CLAUDE.md` and `memory/memory.md`
3. Searches claude-mem for recent decisions and open items
4. Surfaces any open items from the last session before you say anything

**Understanding Check (tiered)** — anything that creates/modifies files, produces a
deliverable, is client-facing, or commits to scope/estimates gets a hard gate: the employee
restates its understanding in 1–3 lines and waits for your confirmation. Quick informational
questions are answered directly with assumptions stated inline — no round trip.

**Triple-lens review** — every deliverable is reviewed through SA (requirements), PM (risk/plan),
and DBA (data/schema) lenses before delivery.

**Session-close audit** — when a task closes (`end-of-task`), the employee verifies every
decision/risk has an ID in the right file, Next-ID counters were incremented, and working
memory was updated. A task isn't closed until the audit passes.

---

## Starting a New Client

Say: **"we have a new client"** (or "new client", "onboard client")

The employee runs `new-client-setup` which walks you through a short wizard:

| Step | What happens |
|---|---|
| Client name | Folder `memory/clients/[name]/` created immediately |
| Project name | Full project scaffold created immediately (10 files + deliverables) |
| Problem statement | One sentence — pain, not solution |
| Engagement type | New build / Enhancement / Migration / Audit |
| Timeline + dev team | Batched — one question |
| Summary card | Preview before writing |
| Tech stack | Frontend, backend, database, hosting, integrations |
| Client record written | `memory/clients/[name]/[name].md` + Client Index in `memory.md` |
| Mode suggestion | DISCOVER / ingest document first / record only |

All client data is stored under `memory/clients/` which is **gitignored and never pushed**.
Your client information stays on your machine only.

---

## Resuming on a New Machine

If you copy your `memory/clients/` folder to a new machine (fresh clone), say:

**"I have an ongoing client that I manually inserted"**
(or "resume client", "I copied the client folder", "I moved machines")

The employee runs `resume-client`:

1. Scans `memory/clients/` for all client folders
2. Reads the client record and all project files
3. Rebuilds the Client Index in `memory/memory.md`
4. Syncs open risks, decisions, and current phase to claude-mem
5. Shows a status card per project (phase, next milestone, open risks, open tasks)
6. Asks what you want to work on next

**What to copy between machines:**
```
memory/clients/          ← copy this whole folder
```

Everything else (`CLAUDE.md`, `ai-sa-employee/`, `scripts/`, etc.) comes from the repo.

---

## Backing Up Client Data

Client data is gitignored by design — which means **git is not your backup**. The backup
script is the safety net. Run it weekly (or say **"backup client data"**):

```powershell
# Windows
scripts\backup.ps1
scripts\backup.ps1 -Destination "D:\Backups" -Keep 20
```

```
# Linux / Mac
bash scripts/backup.sh
bash scripts/backup.sh /path/to/backups
```
It zips `memory/clients/`, `.claude-mem/`, `reference/`, and `deliverables/` into a
timestamped archive (default: `Documents/EmployeeBackups/`, keeps the newest 10).
To restore: extract the zip into a fresh clone's root, then say
*"I have an ongoing client that I manually inserted"*.

The weekly review checks backup age and nags you if it's older than 7 days.

---

## Keeping the System Healthy

**Weekly review** — say **"weekly review"** (or "portfolio check"). The employee sweeps
every active project — aging risks, stale tasks, milestones due within 14 days, blocked
questions — plus audits itself (memory freshness, backup age, untracked decisions) and
delivers one cross-client RAG digest with a Top-3 action list.

**System drill** — say **"run a drill"** after changing skills or CLAUDE.md. The employee
onboards a synthetic client (`_drill`), runs the full pipeline (onboard → IDs → write lanes
→ calibration → resume), reports PASS/FAIL per step, and cleans up after itself.

**Calibration** — every project has a `calibration.md`. Estimates are logged when made
(`scope-estimate`), actuals are filled when work completes (`end-of-task`), and once 3+
items are complete the running ratio corrects future estimates automatically — the employee
learns its own bias.

---

## The 5 Project Modes

| Mode | When to use | What you get |
|---|---|---|
| **DISCOVER** | New project or new requirements | REQ- IDs, stakeholder register, NFR probe, 5W framing |
| **ANALYZE** | Understand the current system or process | AS-IS/TO-BE maps, risk list, constraints, unknowns |
| **DESIGN** | Choose architecture and tech | Solution design, ADRs, C4 diagrams, DB schema review |
| **CHALLENGE** | Pressure-test the plan or scope | Feasibility audit, cut/defer list, what breaks this plan |
| **PLAN** | Build the project plan | WBS, milestones, critical path, task breakdown, estimates |

**New project:** DISCOVER → ANALYZE → DESIGN → CHALLENGE → PLAN (default order)
**Existing project:** enter any mode directly by telling the employee what you need

---

## PDF Ingestion

To use a client PDF (contract, brief, RFP, spec):

1. Drop the PDF(s) into **`pdf-source/`** (the default drop folder)
2. Convert to Markdown — `pdf2md` finds them for you:

```powershell
# Windows
scripts\pdf2md.ps1                          # convert EVERY *.pdf in pdf-source\
scripts\pdf2md.ps1 -InputFile "brief.pdf"   # by name — pdf-source\ is checked first, then current dir
scripts\pdf2md.ps1 -InputFile "reference\brief.pdf"   # or an explicit path
```
```
# Linux / Mac
bash scripts/pdf2md.sh                       # convert every *.pdf in pdf-source/
bash scripts/pdf2md.sh brief.pdf             # by name
```

Each PDF produces `<name>.md` next to it. Pass `-Recurse` (PowerShell) / `RECURSE=1` (bash)
to include subfolders.

3. Tell the employee: **"ingest this"** (or drop the path)
4. The employee runs `ingest-reference`: reads the `.md` once → distils to claude-mem as `KB-` entries
5. Future sessions search claude-mem — the file is not re-read unless it changes

> **Converter quality:** the high-fidelity converter (`@opendataloader/pdf`) needs **Java**,
> which the **setup script installs for you** (winget / brew / apt). If Java is ever absent,
> `pdf2md` automatically falls back to **pypdf** (text-only — tables and layout not preserved)
> and tells you so, so a conversion never silently fails.

---

## Skills Reference

The employee has **59 invokable skills** (full index in `ai-sa-employee/skills/skills.md`).
Trigger them by saying the phrases in the right column. The most-used are below.

| Skill | Trigger phrases |
|---|---|
| `gather-requirements` | "gather requirements", "what do they need" |
| `stakeholder-analysis` | "who are the stakeholders", "stakeholder map" |
| `process-analysis` | "map the process", "as-is to-be" |
| `use-case-analysis` | "use cases", "user stories" |
| `solution-design` | "design the solution", "architecture" |
| `risk-management` | "risks", "RAID log", "what could go wrong" |
| `change-management` | "change request", "scope change" |
| `status-report` | "status update", "RAG report" |
| `plan-project` | "build the plan", "timeline", "WBS" |
| `scope-estimate` | "estimate this", "how long will X take" |
| `advise-client` | "advise the client", "what should we tell them" |
| `project-status` | "how are we doing", "project health" |
| `new-client-setup` | "new client", "onboard client" |
| `new-project` | "new project", "bagong project" |
| `resume-client` | "resume client", "I have an ongoing client", "I copied the client folder" |
| `weekly-review` | "weekly review", "portfolio check", "sweep all projects" |
| `system-drill` | "run a drill", "test the system", "system check" |
| `ingest-reference` | "ingest this", file dropped in `reference/` |
| `ingest-meeting-notes` | "meeting notes", "notes from the call", "sinabi ng client" |
| `database-admin` | "database", "schema", "migration", "query", "performance", "HA/DR" |
| `security-review` | "security review", "threat model", "STRIDE", "PII", "GDPR", "HIPAA" |
| `nfr-review` | "NFR", "non-functional requirements", "performance targets", "SLA" |
| `create-diagram` | "create a diagram", "flowchart", "ERD", "Gantt" |
| `web-research` | "research [topic]", "compare [options]", "competitive analysis" |
| `document-specialist-skill` | "generate an SRS", "write a PRD", "read this file", "read this PDF" |
| `end-of-task` | "done", "task complete" |
| `learn-from-feedback` | "the client said X", "got feedback" |
| `new-skill` | "create a new skill", "add a skill for X" |
| `deep-analysis` | "analyze this deeply", "RCA this", "is this the right approach", "challenge this plan" |
| `code-behavior-audit` | "audit this code for bugs", "trace this for issues", "check this controller for defects" — behavior trace with code/config/memory/mind-map/DB authority reconciliation |
| `rollback-readiness-test` | "test this thoroughly like Code Tables", "rollback-only test", "deployment-readiness test", "prove this module works" — source audit + DB metadata + rollback-only drill + build/authenticated-API/negative-case evidence readiness verdict; uses constrained upstream Ponytail simplification for implementation/test choices without overriding readiness gates |
| `ollama-agent-runtime` | "verify Ollama", "sync the agent runtime", "use the mind-map" — verifies the active Claude/Codex host, local model, context/tool calling, Ponytail, canonical skills, and relevant mind-map gates |
| `soup-model-preparation` | "use Soup", "fine-tune", "post-train", "prepare model for Ollama" — explicit plan-and-verify Soup workflow; training/export/deploy/model replacement require approval |
| `codex-behavior-parity` | "make Claude work like Codex", "sync Claude and Codex behavior", "Codex personal behavior" — maps Codex operating discipline to Claude-safe MYPS workflow rules without claiming unsupported runtime features |

**Not in the table above:** `plan-analysis` is an agent-local, client-scoped planning skill at
`.claude/skills/plan-analysis/`. Run it from this employee-agent workspace for any managed
client/project. Codex exposes only a thin runtime bridge at
`C:\Users\Msi\.codex\skills\plan-analysis`; the canonical skill is not copied into client
application repositories. It defaults to live evidence-backed planning and supports an explicit,
client-deliverables evidence bundle. See `CLAUDE.md`'s Tie-breaks section for how it relates to
`deep-analysis`.

### Ponytail ownership

Generic Ponytail behavior remains sourced from the upstream `DietrichGebert/ponytail` plugin and is
installed separately for Claude Code and Codex by the post-clone setup instructions. The MYPS
specific readiness contract remains in `ai-sa-employee/skills/rollback-readiness-test.md`, and
`AGENTS.md` tells Codex where to read it. Ponytail simplifies implementation and test choices;
it never overrides rollback, authentication, evidence, safety, or mind-map completion gates.

Relevant Ollama/Ponytail/Soup/readiness work must first use
`ai-sa-employee/skills/ollama-agent-runtime.md`. It requires the Agent Tooling Mindmap preflight,
independent Claude/Codex verification, and an approval-gated sync entry before completion. Soup is
only invoked through `ai-sa-employee/skills/soup-model-preparation.md` when explicitly requested.

### Fresh-clone Soup and Ponytail setup

The default setup is check-only for both tools. It never changes user-level Claude/Codex plugin
stores, downloads an Ollama model, trains a model, or removes duplicate installations.

If Ponytail is missing, run the printed marketplace commands:

```text
Claude Code:
  /plugin marketplace add DietrichGebert/ponytail
  /plugin install ponytail@ponytail

Codex:
  codex plugin marketplace add DietrichGebert/ponytail
  codex plugin add ponytail@ponytail
```

If Soup is explicitly needed, install it in the ignored repository environment after the archive
hash check:

```powershell
.\scripts\setup.ps1 -InstallSoup -SoupArchivePath <path-to-Soup-0.75.0.zip>
.\scripts\setup.ps1 -InstallSoup -InstallSoupTraining -SoupArchivePath <path-to-Soup-0.75.0.zip>
```

```bash
bash scripts/setup.sh --install-soup --soup-archive <path-to-Soup-0.75.0.zip>
bash scripts/setup.sh --install-soup --install-soup-training --soup-archive <path-to-Soup-0.75.0.zip>
```

Soup is fully available for explicit model preparation, but it is not run during ordinary Employee
tasks. After a Soup-prepared model is imported into Ollama, Claude/Codex still load repository
skills and Ponytail remains the implementation/test simplification method.

### Optional Soup model preparation

`Soup-0.75.0.zip` is the external `soup-cli` fine-tuning/post-training tool. It is not an Ollama
server, agent host, skill loader, or Ponytail implementation. Keep it outside this repository and,
if needed, install `soup-cli==0.75.0` in an isolated tool environment such as `pipx`. Do not add its
heavy training dependencies to normal setup. A Soup-produced model still needs a separate
compatibility/export/import check before Ollama can serve it; Soup is never required for Employee
skills or readiness verdicts.

When explicitly requested, setup can install Soup into the ignored repo-local environment after
checking the archive hash:

```powershell
.\scripts\setup.ps1 -InstallSoup -SoupArchivePath C:\Users\Msi\Downloads\Soup-0.75.0.zip
.\scripts\setup.ps1 -InstallSoup -InstallSoupTraining -SoupArchivePath C:\Users\Msi\Downloads\Soup-0.75.0.zip
```

```bash
bash scripts/setup.sh --install-soup --soup-archive /path/to/Soup-0.75.0.zip
bash scripts/setup.sh --install-soup --install-soup-training --soup-archive /path/to/Soup-0.75.0.zip
```

The training extra is a separate explicit choice. Setup never runs `soup train`, `soup export`,
`soup deploy`, or `ollama create`, and never replaces a global Soup installation.

**Delivery skills (design → build bridge):**

| Skill | Trigger phrases |
|---|---|
| `developer-handoff` | "hand this off to the developer", "make dev tickets", "ready for dev" |
| `api-contract-design` | "design the API", "what endpoints", "REST contract", "GraphQL schema" |
| `test-strategy` | "test plan", "QA plan", "UAT plan", "regression checklist" |
| `data-migration-playbook` | "migrate the data", "move data from [old] to [new] schema", "backfill" |
| `calibration-review` | "calibrate", "estimate accuracy", "were we right about the risks" |
| `task-board` | "task board", "show the board", "move [ID] to [status]", "sprint planning", "what's blocked", "generate the xlsx report" — Jira/monday-style board on the project's `board.md`; chat commands mutate (confirm-first), xlsx report on demand (Dashboard + BE + FE + QA sheets, weekend-aware dates, variance → calibration) |

**Meta skills (the agent improves itself):**

| Skill | Trigger phrases |
|---|---|
| `self-improvement` | "/check-improvements", "what should we improve", "audit yourself" · alias "/capture-workflow", "that worked, save the pattern" — dual-lens: friction → `SKL-`, successful workflows → `WFC-` |
| `memory-hygiene` | "/check-memory", "clean up memory", "memory is full", "claude-mem is slow" |

> The agent passively logs friction as one-line breadcrumbs in `memory/improvement-backlog.md`
> at near-zero cost; `/check-improvements` turns them into structured `SKL-` proposals on demand.

---

## Task Delegation & Board Workflow

Once a module's design is locked (schema confirmed, ADRs written, drills green), this is how you
turn it into work a developer, tester, and PM can actually pick up — the **module delivery pack**.
It chains four existing skills, then tracks the result on a live board.

### The chain (run per module)

```
1. developer-handoff   →  "hand this off to the developer"
   Produces:  DEV- tickets — acceptance criteria, tech notes, build order, out-of-scope

2. test-strategy        →  "test plan for [module]"
   Produces:  coverage matrix, scenarios, regression set, exit criteria (dev test automation)

3. FE/BE task breakdown →  "break DEV-0xx down into FE and BE tasks"
   Produces:  one sub-task list per discipline (BE-0xx.n / FE-0xx.n) with estimates + dependencies

4. User-level QA plan   →  "write a manual QA test plan for [module]"
   Produces:  plain test cases a human tester runs against the running app — steps, expected
              result, severity — separate from the dev test-strategy in step 2

5. task-board            →  "put [module]'s tickets on the board"
   Produces:  cards on the project's board.md — one per DEV ticket, sub-tasks as a checklist
```

Run the **whole chain for one module** before moving to the next — that lets you checkpoint
decisions (schema questions, scope calls) before they compound into the next, more complex module.
Two habits that keep this clean across many modules:
- **Sync every consumer doc in the same pass** (the tickets register, `risks.md`, `decisions.md`)
  — don't batch it for later, it never happens later.
- **Give any service shared across modules one owner.** If two modules both need an ID generator
  or a validation rule, build it once in whichever module owns it first; the other just calls it.

### Working the board day-to-day

Once cards exist, drive everything through chat — the board file is never hand-edited:

```
"show the board"                        → progress per module, status counts, what's blocked
"move DEV-045 to in progress"           → updates status, logs the change
"tick BE-050.2"                         → checks off a sub-task
"assign DEV-050 to [name]"              → sets the assignee
"sprint planning — pull the next 2 weeks of foundation work" → proposes a sprint, waits for confirm
"what's blocked" / "what's next"        → dependency-aware queries
"generate the xlsx report"              → snapshot workbook: Dashboard + BE + FE + QA sheets
```

**Every board change is proposed in chat first — nothing writes to `board.md` until you confirm.**
That confirmed markdown file is the single source of truth; the xlsx (when you ask for it) is
always a timestamped snapshot generated *from* the confirmed board, never edited back into it.

The xlsx's BE/FE sheets auto-calculate working-day end dates from a Start Date you enter (skips
weekends), and an Actual End / Variance pair feeds `calibration-review` once real dates land.

**Full skill reference:** `task-board` and `developer-handoff` in the Skills Reference table above;
complete mechanics in `ai-sa-employee/skills/task-board.md`.

---

## Memory System

| What | Where | Pushed to git? |
|---|---|---|
| Operator profile + client index | `memory/memory.md` | Yes |
| Communication standards | `memory/communication.md` | Yes |
| Agent self-improvement backlog (`SKL-`/`WFC-` breadcrumbs) | `memory/improvement-backlog.md` | Yes |
| All client data (records + project files) | `memory/clients/` | **No — gitignored** |
| Episodic memory (decisions, risks, KB entries) | `.claude-mem/` (local) | **No — gitignored** |
| Client source documents (drop zone) | `reference/` | **No — gitignored** |
| Generated deliverables | `deliverables/` | **No — gitignored** |

**Rule:** only system files are pushed. No client information ever leaves your machine via git.

### Memory IDs

| Prefix | Used for |
|---|---|
| `REQ-FNN` | Functional requirements |
| `REQ-NFNN` | Non-functional requirements |
| `RISK-NNN` | Risks |
| `REC-NNN` | Recommendations |
| `ADR-NNN` | Architectural Decision Records |
| `KB-NNN` | Knowledge Base entries (from reference ingestion) |
| `ASS-NNN` | Assumptions |
| `SKL-NNN` | Agent self-improvement proposals (`memory/improvement-backlog.md`) |

---

## File Structure

```
Employee System Analyst Expert/
├── CLAUDE.md                          ← Operating manual (read at every session start)
├── README.md                          ← This file
├── .claude/settings.json              ← MCP servers + env vars + permissions
├── .claude/commands/                  ← 63 command files (59 skill wrappers + 4 aliases) → point to ai-sa-employee/skills/
├── .claude/skills/plan-analysis/      ← Agent-local, client-scoped evidence planning skill
├── .gitignore
├── package.json
│
├── ai-sa-employee/                    ← THE employee — self-contained skill package
│   ├── SKILL.md                       ← Main skill file (5 modes, gates, trigger table)
│   ├── CLAUDE.md                      ← Compact quick-reference
│   ├── references/
│   │   ├── modes.md                   ← Per-mode playbooks
│   │   ├── deliverables.md            ← SRS/architecture/plan templates + Mermaid patterns
│   │   ├── integrations.md            ← Memory lanes, DB hook, PDF ingestion, MCP usage
│   │   └── skill-creator.md           ← How to build new skills
│   ├── skills/                        ← 59 SA/PM/DBA/delivery/meta skills (flat)
│   │   ├── skills.md                  ← Master index + interaction protocol + quality checklist
│   │   └── [59 individual skill files]
│   └── document-skills/               ← Document generation (Anthropic official, Windows-patched)
│       ├── file-reading/  ✅ Ready
│       ├── pdf-reading/   ✅ Ready
│       ├── pdf/           ✅ Ready
│       ├── docx/          ✅ Ready
│       ├── pptx/          ✅ Ready
│       └── xlsx/          ✅ Ready
│
├── engines/                           ← 🚫 GITIGNORED — portable LibreOffice/Poppler (in-project)
│   └── README.md                      ← how it's populated + resolution order
│
├── memory/                            ← Runtime memory
│   ├── memory.md                      ← Operator profile + working memory + client index
│   ├── communication.md               ← RAG criteria + report format + ID reference
│   ├── improvement-backlog.md         ← Agent self-improvement breadcrumbs + SKL-/WFC- proposals
│   └── clients/                       ← 🚫 GITIGNORED — all client data stays local
│       └── [client-name]/
│           ├── [client-name].md       ← client record
│           ├── reference/             ← client documents
│           └── [project-name]/
│               ├── requirements.md
│               ├── risks.md
│               ├── plan.md
│               ├── tasks.md
│               ├── decisions.md
│               ├── stakeholders.md
│               ├── communication.md
│               ├── database.md
│               ├── calibration.md
│               └── deliverables/
│
├── reference/                         ← 🚫 GITIGNORED — PDF drop zone (convert then ingest)
├── deliverables/                      ← 🚫 GITIGNORED — generated client output
├── scripts/                           ← GENERAL-PURPOSE only (client-specific scripts → memory/clients/[client]/[project]/scripts/)
│   ├── setup.ps1 / setup.sh           ← First-time setup (deps + document engines)
│   ├── pdf2md.ps1 / pdf2md.sh         ← PDF → Markdown
│   ├── fetch-libreoffice-local.ps1    ← Install LibreOffice into engines/ (in-project)
│   ├── verify-engines.ps1 / .sh       ← Test document engines end-to-end
│   ├── generate-board-xlsx.py         ← Task-board xlsx report (board.md → Dashboard+BE+FE+QA workbook)
│   └── backup.ps1 / backup.sh         ← Client data + engines backup
│
├── workspace/                         ← 🚫 GITIGNORED — local scratch: skill eval runs, temp tooling, throwaway analysis
│
└── node_modules/                      ← gitignored
```

---

## Tool Dependencies

| Tool | Required for | Install |
|---|---|---|
| Node.js ≥ 20 | claude-mem, context-mode, @opendataloader/pdf | https://nodejs.org |
| Python ≥ 3.10 | chromadb semantic search | https://python.org |
| Bun | context-mode hooks | `irm bun.sh/install.ps1 \| iex` (Windows) |
| LibreOffice | DOCX/PPTX/XLSX creation | Auto-installed by setup script (winget/brew/apt) |
| Poppler | PDF image conversion | Auto-installed by setup script (winget/brew/apt) |
| Claude Code | Required — this is a Claude Code workspace | https://claude.ai/code |

The `setup.ps1` / `setup.sh` scripts check and install everything automatically.

---

## Conversation Examples

```
"we have a new client"                       → onboard wizard
"gather requirements for [client]"           → DISCOVER mode
"design the solution"                        → DESIGN mode, solution design + ADRs
"what are the risks?"                        → RAID log, probability/impact scoring
"build the plan"                             → WBS, milestones, critical path
"status update"                              → RAG status report
"ingest this" [PDF dropped]                  → PDF → MD → claude-mem KB entries
"I have an ongoing client I manually inserted" → resume-client: scan, rebuild, status card
"security review"                            → STRIDE analysis, PII map, RISK-SEC entries
"research [technology]"                      → web research via brightdata MCP
"weekly review"                              → portfolio sweep + system audit, RAG digest
"run a drill"                                → synthetic client smoke test, PASS/FAIL report
"backup client data"                         → zip all local-only data with retention
"hand this off to the developer"             → DEV- tickets with acceptance criteria + build order
"break DEV-050 into FE and BE tasks"         → discipline sub-tasks with estimates + dependencies
"show the board"                             → per-module progress, status counts, blocked list
"generate the xlsx report"                   → Dashboard + BE + FE + QA workbook snapshot
```

