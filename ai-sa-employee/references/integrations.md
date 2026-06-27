# Integrations Reference

Memory lane protocol, MCP tool usage, and plugin integration details.
Load this file when you need specifics on how to write memory, invoke database-admin,
ingest PDFs, or use brightdata, Postman, context-mode, or claude-mem.

---

## Memory Lane Protocol

### Write rules
- Write to the correct lane file after confirmation — never before
- Each entry: what was decided/found, why, how to apply, source (stakeholder or session date)
- Update existing entries — don't duplicate. Mark superseded entries with `[SUPERSEDED by ADR-XXX]`
- Convert relative dates to absolute (`next Friday` → `2026-06-19`)
- No secrets, credentials, or PII in memory files

### File structure (per client + project)

All client data lives under `memory/clients/` which is **gitignored — never pushed**.

```
memory/clients/                        ← gitignored
└── [client-name]/
    ├── [client-name].md               ← client record (profile, stack, constraints)
    ├── reference/                     ← client documents (PDF→MD, specs, contracts)
    └── [project-name]/
        ├── README.md                  ← project identity
        ├── requirements.md            ← REQ-F, REQ-NF, stakeholders, assumptions
        ├── stakeholders.md            ← register, RACI, comms plan
        ├── risks.md                   ← RAID log (RISK/ASS/ISS/DEP)
        ├── plan.md                    ← WBS, milestones, PERT, critical path
        ├── tasks.md                   ← active sprint tasks with owner + status
        ├── decisions.md               ← ADRs, scope decisions, deferred items
        ├── communication.md           ← RAG history, escalation log
        ├── database.md                ← schema, migrations, DBA findings
        ├── calibration.md             ← estimates vs actuals, risk hit rate, churn
        └── deliverables/              ← client output (reports/, diagrams/, documents/, pdf/)
```

### When to write
| Event | Write to |
|---|---|
| New REQ- confirmed | `memory/clients/[name]/[project]/requirements.md` |
| RISK- identified | `memory/clients/[name]/[project]/risks.md` |
| ADR made | `memory/clients/[name]/[project]/decisions.md` |
| Scope item cut or deferred | `memory/clients/[name]/[project]/decisions.md` |
| Plan approved | `memory/clients/[name]/[project]/plan.md` |
| DB schema change flagged | `memory/clients/[name]/[project]/database.md` |
| Estimate produced | `memory/clients/[name]/[project]/calibration.md` (actual filled by end-of-task) |
| New client onboarded | `memory/clients/[name]/[name].md` + update Client Index in `memory/memory.md` |
| Lesson learned | `memory/memory.md` (long-term) |
| New preference learned | `memory/memory.md` (Preferences section) |

---

## Database-Admin Skill Hook

### Invoke `database-admin` when:
- A component owns or mutates persistent data (from DESIGN mode)
- Schema changes are required (migration safety review)
- Query performance is a concern (slow query analysis, index recommendations)
- HA/DR requirements surface (replication, backup, failover)
- Cost optimisation is needed (right-sizing, archiving, partitioning)
- Compliance data handling is involved (encryption at rest, audit logs, retention)

### What to pass when invoking
- The relevant section of `requirements.md` (data entities, volume NFRs)
- The current `database.md` (if it exists)
- The specific concern: schema design / migration safety / performance / HA/DR / cost / compliance

### DB lens (always apply proactively)
Even when not explicitly invoked — apply DB lens whenever any component:
- Creates, reads, updates, or deletes records
- Could cause table locks under concurrent load
- Has a reporting/analytics requirement alongside OLTP writes
- Requires audit trail or soft-delete behaviour

---

## PDF Ingestion — @opendataloader/pdf

### Purpose
Convert client-provided PDFs to Markdown before reading them. Raw PDF bytes are not read directly — converting once and ingesting to claude-mem avoids re-reading every session.

### Converters (priority order)
1. `@opendataloader/pdf` — installed in `node_modules` (`npm install`). High-fidelity, but **requires Java** on PATH.
2. `pypdf` — automatic fallback when Java/opendataloader is unavailable. Text-only (no tables/layout). `pdf2md` warns when it falls back.

`pdf2md` judges success by the **output file existing**, not exit codes — so a silent opendataloader failure (e.g. missing Java) cleanly falls through to pypdf.

### Default drop folder: `pdf-source/`
Raw client PDFs go in `pdf-source/` (gitignored). `pdf2md` reads from there by default.

### Input resolution
| Passed | Behaviour |
|---|---|
| nothing | batch every `*.pdf` in `pdf-source/` |
| bare name (`brief.pdf`) | check `pdf-source/` first → then current dir → else error |
| a path (`reference/x.pdf`) | use as given |
| a folder | batch every `*.pdf` in it |
| `-Recurse` / `RECURSE=1` | descend into subfolders when batching |

### Script
```powershell
# Windows
scripts/pdf2md.ps1                            # batch pdf-source\
scripts/pdf2md.ps1 -InputFile "brief.pdf"     # by name (pdf-source\ first)
scripts/pdf2md.ps1 -InputFile "reference\x.pdf"
```
```bash
# Linux/Mac
bash scripts/pdf2md.sh                         # batch pdf-source/
bash scripts/pdf2md.sh brief.pdf
```
Each PDF produces `<name>.md` next to it.

### Workflow
1. Client drops PDF(s) into `pdf-source/`
2. Run `pdf2md` → produces `.md` next to each PDF (note converter used; pypdf = degraded)
3. Move/keep the `.md` in `reference/`, then invoke `ingest-reference` → distill to claude-mem as `KB-NNN`
4. Search claude-mem for KB entries before any future task that may benefit
5. Do NOT re-read the source `.md` unless the file changes or an entry is suspect

---

## brightdata MCP — Web Research

### Available tools
| Tool | Use for |
|---|---|
| `mcp__brightdata__search_engine` | General web search — technology docs, news, regulations |
| `mcp__brightdata__scrape_as_markdown` | Extract structured content from a specific URL |
| `mcp__brightdata__search_engine_batch` | Multiple parallel searches in one call |
| `mcp__brightdata__scraping_browser_navigate` | Interactive browsing for paginated content |

### Invoke via
`web-research` skill — handles the research types (Technology Evaluation, Competitive Analysis, Regulatory Lookup, Market Context) and formats findings into the correct output.

### When to use
- Technology evaluation for a design decision → Type A
- Client wants to understand competitive landscape → Type B
- Project handles regulated data or specific jurisdiction → Type C
- Background on an industry or problem space → Type D
- DISCOVER mode surfaces an unknown needing external validation → any type

### Rules
- Always frame search queries with client/project context
- Multiple sources — no single-source findings treated as fact
- Feed regulatory findings to `security-review` skill
- Feed technology findings to `solution-design` as ADR input
- Log all generated REQ-/RISK-/REC- entries with IDs

---

## Postman MCP — API Contract Review

### Available tools
| Tool | Use for |
|---|---|
| `mcp__claude_ai_Postman__getCollections` | List available API collections in the workspace |
| `mcp__claude_ai_Postman__getCollection` | Retrieve full collection with requests |
| `mcp__claude_ai_Postman__getSpec` | Retrieve OpenAPI/Swagger spec |
| `mcp__claude_ai_Postman__getSpecDefinition` | Get full spec definition |
| `mcp__claude_ai_Postman__searchPostmanElements` | Search for specific endpoints |

### When to use
- DESIGN mode Step 10: client has existing API collections or the design includes external APIs
- Validate interface contracts against the solution design
- Flag spec gaps or mismatches as open design questions

### Workflow
1. `getCollections` → identify relevant collections
2. `getSpec` or `getCollection` → retrieve contract details
3. Compare against the integration map in the architecture
4. Flag any mismatch or missing spec as an open design question

---

## context-mode Plugin — Token Reduction

### Purpose
Run heavy tool outputs (file reads, shell commands, web fetches) in a sandbox, index the results, and return only matching summaries. Keeps raw bytes out of the conversation context (~98% token reduction on large outputs).

### Tool hierarchy
1. `ctx_batch_execute` — primary research tool: run commands in parallel, auto-index output, return matching sections in the same round trip
2. `ctx_search` — follow-up: search anything already indexed (session memory + prior captures)
3. `ctx_execute` / `ctx_execute_file` — processing: filter, count, aggregate, parse — only what you `console.log()` enters conversation
4. `ctx_fetch_and_index` — web fetch: full network access, results indexed, raw bytes never enter conversation

### When NOT to use context-mode
- You need to Edit a file (Edit tool needs exact bytes — use Read directly)
- You intend to observe a short fixed output (git status, pwd)
- You are mutating state (git commands, mkdir, rm)

### Session search (on resume)
```
mcp__plugin_context-mode_context-mode__ctx_search(
  queries: ["prior decisions", "open items", "last task"],
  source: "session-events"
)
```

---

## claude-mem Plugin — Episodic Memory

### Purpose
Persist decisions, requirements, risks, and knowledge base entries across sessions. claude-mem speaks first at session start — search before answering from scratch.

### Commands (in conversation)
```
mem search "[query]"           # Search episodic memory
mem search "[project] requirements"
mem search "estimate"
mem search recent              # Recent entries
```

### Adding entries programmatically
Use `mcp__plugin_claude-mem_mcp-search__memory_add` with:
- `content`: the entry text
- `tags`: array of relevant tags (project name, entry type, date)

### Entry format (for manual logging)
```
[YYYY-MM-DD] [ID] [Type]: [What was decided/found]
Why: [Rationale]
Apply when: [Context or trigger for using this knowledge]
Source: [Stakeholder name or session reference]
```

### Categories
| Tag | Use for |
|---|---|
| `category:Requirements` | REQ- entries |
| `category:Risk` | RISK- entries |
| `category:Decision` | ADR entries |
| `category:Database` | DBA findings, schema decisions |
| `category:Preference` | Operator preferences |
| `category:KB` | Knowledge base entries (KB- IDs) |

### Memory tiers
| Tier | Stack | Effect |
|---|---|---|
| Tier 0 | Skill only | Full hot layer; writes to `memory/` files; save-session required |
| Tier 1 | + claude-mem | Episodic memory via hooks; claude-mem searches at session start |
| Tier 2 | + context-mode | ~98% token reduction on heavy tool outputs |

---

## External-system integration patterns (WFC-003/004)

Patterns for integrating an external/owned-elsewhere database (e.g. PCMA) into a DB design.

### WFC-003 — Synonym-based environment switch
When a view/function depends on an external object that differs by environment (dev mock vs
prod linked server), **abstract it with a `SYNONYM`** so consuming objects never hardcode the path.

```sql
-- DEV (local mock):
CREATE SYNONYM dbo.synPCMAStatusRev FOR [Mock_PCMA].dbo.PCMA_vw_..._Revision;
-- PROD (linked server) — swap this ONE line at deploy:
-- CREATE SYNONYM dbo.synPCMAStatusRev FOR [PCMA_DB].[pcma_db_myps].[dbo].[PCMA_vw_..._Revision];
```
Every view references `dbo.synPCMAStatusRev` — zero code change between environments; only the
synonym definition swaps. Keeps dev runnable without the production linked server.

### WFC-004 — Live-overlay view for externally-owned data (don't store it)
If a field's source of truth is **another system**, do **not** store it as a column (it goes stale
and needs sync). Expose it via a **view that joins the external source live**:

```sql
CREATE VIEW dbo.vProjectComponentCost AS
SELECT pcc.*, pcma.proj_comp_construction_status_code, pcma.is_packaged
FROM dbo.tProjectComponentCost pcc
LEFT JOIN dbo.synPCMAStatusRev pcma
    ON pcma.myps_project_id_FK = ... AND pcma.project_component_id = ...;
```
- Drop the stored column + its lookup table; the external system owns the value.
- LEFT JOIN so rows pre-integration (e.g. pre-publish) return NULL gracefully.
- Read-only across the linked server — never write to the external system from here.
- Pairs with WFC-003 (the join target is a synonym).

**When NOT to use:** if you need point-in-time history of the external value, snapshot it
deliberately (a revision-style copy) rather than a live overlay.
