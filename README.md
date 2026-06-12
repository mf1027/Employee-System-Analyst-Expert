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

**What the employee does not do:** write application code. It analyses, plans, governs, and advises.
It hands off to the developer (you or your team) with complete specifications.

---

## Quick Start

### New machine — first time

1. Clone the repository
2. Open the folder in Claude Code
3. Run the setup script:

```powershell
# Windows
scripts\setup.ps1

# Linux / Mac
bash scripts/setup.sh
```

The script checks and installs:
- Node.js dependencies (`claude-mem`, `context-mode`, `@opendataloader/pdf`)
- Python `chromadb` for semantic memory search
- Prints Claude Code plugin install commands if needed

4. Install any missing plugins printed by the setup script (copy/paste into Claude Code terminal)
5. Reload Claude Code

**You're ready.** Open this folder in Claude Code and start a session.

---

## How Sessions Work

Every session starts with a hard gate:

1. The employee reads `CLAUDE.md` and `memory/memory.md`
2. Searches claude-mem for recent decisions and open items
3. Surfaces any open items from the last session before you say anything

**Understanding Check** — before producing any analysis, recommendation, or deliverable, the
employee restates its understanding of your request in 1–3 lines and waits for explicit
confirmation. Nothing is produced until you confirm. This is non-negotiable.

**Triple-lens review** — every deliverable is reviewed through SA (requirements), PM (risk/plan),
and DBA (data/schema) lenses before delivery.

---

## Starting a New Client

Say: **"we have a new client"** (or "new client", "onboard client")

The employee runs `new-client-setup` which walks you through a short wizard:

| Step | What happens |
|---|---|
| Client name | Folder `memory/clients/[name]/` created immediately |
| Project name | Full project scaffold created immediately (9 files + deliverables) |
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

Everything else (`CLAUDE.md`, `skills/`, `scripts/`, etc.) comes from the repo.

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

1. Drop the PDF into `reference/` (root drop zone) or `memory/clients/[name]/reference/`
2. Convert to Markdown:

```powershell
# Windows — primary converter: @opendataloader/pdf (bundled in node_modules)
scripts\pdf2md.ps1 -InputFile "reference\brief.pdf"
scripts\pdf2md.ps1 -InputFile "reference\brief.pdf" -OutputFile "reference\brief.md"

# Linux / Mac
bash scripts/pdf2md.sh "reference/brief.pdf"
bash scripts/pdf2md.sh "reference/brief.pdf" "reference/brief.md"
```

3. Tell the employee: **"ingest this"** (or drop the path)
4. The employee runs `ingest-reference`: reads the `.md` once → distils to claude-mem as `KB-` entries
5. Future sessions search claude-mem — the file is not re-read unless it changes

---

## Skills Reference

The employee has 26 invokable skills. Trigger them by saying the phrases in the right column.

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

---

## Memory System

| What | Where | Pushed to git? |
|---|---|---|
| Operator profile + client index | `memory/memory.md` | Yes |
| Communication standards | `memory/communication.md` | Yes |
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

---

## File Structure

```
Employee System Analyst Expert/
├── CLAUDE.md                          ← Operating manual (read at every session start)
├── README.md                          ← This file
├── .claude/settings.json              ← MCP servers + env vars + permissions
├── .gitignore
├── package.json
│
├── ai-sa-employee/                    ← Distributable skill package
│   ├── SKILL.md                       ← Main skill file (5 modes, gates, trigger table)
│   ├── CLAUDE.md                      ← Compact quick-reference
│   └── references/
│       ├── modes.md                   ← Per-mode playbooks
│       ├── deliverables.md            ← SRS/architecture/plan templates + Mermaid patterns
│       ├── integrations.md            ← Memory lanes, DB hook, PDF ingestion, MCP usage
│       └── skill-creator.md           ← How to build new skills
│
├── skills/                            ← 26 SA/PM/DBA skills (flat)
│   ├── skills.md                      ← Master index + interaction protocol + quality checklist
│   └── [25 individual skill files]
│
├── document-skills/                   ← Document generation (Anthropic official, Windows-patched)
│   ├── file-reading/  ✅ Ready
│   ├── pdf-reading/   ✅ Ready
│   ├── pdf/           ⚠️ Phase 2
│   ├── docx/          ⚠️ Phase 2
│   ├── pptx/          ⚠️ Phase 2
│   └── xlsx/          ⚠️ Phase 2
│
├── memory/                            ← Runtime memory
│   ├── memory.md                      ← Operator profile + working memory + client index
│   ├── communication.md               ← RAG criteria + report format + ID reference
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
│               └── deliverables/
│
├── reference/                         ← 🚫 GITIGNORED — PDF drop zone (convert then ingest)
├── deliverables/                      ← 🚫 GITIGNORED — generated client output
├── scripts/
│   ├── setup.ps1                      ← Windows first-time setup
│   ├── setup.sh                       ← Linux/Mac first-time setup
│   ├── pdf2md.ps1                     ← PDF → Markdown (Windows)
│   └── pdf2md.sh                      ← PDF → Markdown (Linux/Mac)
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
| LibreOffice | DOCX/PPTX/XLSX creation | Phase 2 only |
| Poppler | PDF image conversion | Phase 2 only |
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
```
