# reference/

Workspace **ingestion inbox** — a drop zone for source material (documents, images, data,
diagrams) shared by the operator or client.

**How to use:** Drop a file here, then say "ingest this" or invoke the `ingest-reference` skill.
The employee reads each file once, distils it into claude-mem as tagged KB entries, and never
re-reads the raw file unless asked.

**Supported formats:** `.md`, `.txt`, `.pdf`, `.png`, `.jpg`, `.csv`, `.mermaid`, SQL DDL, API specs,
schema dumps, ERD exports — see `ai-sa-employee/skills/skills.md §2` for the full list.

---

## Where does a file actually belong? (read this before dropping)

There are three homes for source material. Pick by *what the file is*, not by habit:

| If the file is… | Put it in… | Why |
|---|---|---|
| A quick drop to be ingested / not yet sorted, or workspace-level material | **`reference/`** (here) | General inbox; ingest then file or leave |
| **Client-wide** — a contract, RFP, brief, business case, domain glossary spanning the client's projects | **`memory/clients/[client]/reference/`** | Canonical per-client store (gitignored, stays local) |
| Material that **describes the OLD system** you're converting away from (legacy schema, old API spec, runbook) | **`memory/clients/[client]/[project]/migration/legacy/`** | Conversion projects only — tag `system:legacy` |
| Material that **describes the NEW target system** (target architecture, new schema, new API contract) | **`memory/clients/[client]/[project]/migration/target/`** | Conversion projects only — tag `system:target` |

**Rule of thumb:** `migration/legacy` and `migration/target` are *not* a replacement for `reference/` —
they are specialised shelves that exist **only on conversion projects**, where keeping old and new
physically separate prevents conflating them. A contract or glossary on a conversion project still
goes in the client `reference/` (it describes neither system). See the `conversion-analysis` skill.

---

## Ingestion Log

`ingest-reference` appends a row here for each file ingested from this workspace inbox.
(Files ingested into a client's `reference/` or a project's `migration/` are logged in *that*
folder's README instead.)

| File | Type | Summary | claude-mem entries | Date ingested |
|---|---|---|---|---|
| `MYPS_MultiYear_Module_UserStories (2).md` | Spec/PRD (user stories, Given/When/Then) | MYPS Module 12 (Multi-Year Planning) — 24 user stories across Multi-Year Program List + Multi-Year Project List, modeled on Programs/Projects §5.2-5.3 + RDIP/UDIP/PIP from Ops Guide v7.0. Drafted functional-scope-only (roles deferred). 12 consolidated `[CONFIRM]` questions for client. See distillation below (claude-mem unreachable this session — SKL-022, PATH fix still pending — stored to file memory instead). | **N/A — claude-mem MCP unreachable (SKL-022).** Distillation: (1) Multi-Year = permanent planning container (RDIP/UDIP/PIP), always "Working" status, no stage lifecycle, no PCMA publish. (2) MY-series project ID persists for project's life (vs P/BP IDs that change per stage). (3) Annual cost distribution ~10 years + Original-vs-Revised cost tracking (Revised updates, Original locked). (4) Linking to AIP projects is MYCA/MYOA-gated: Case 1 (has authority) = one dedicated AIP record reused across programs; Case 2 (no authority) = separate AIP project per program, tied only by shared MYID. (5) Stage-gate: linking only allowed while the AIP project is newly-created and pre-GAA-R. (6) Role-based access explicitly deferred to a follow-up pass. | 2026-07-10 |
| `Dev-Programs and Projects ERD.mermaid` | Mermaid ERD | Cited as one of only 3 sources (with `Dev-Project Revisions.mermaid` and the User Manual) consolidated into the Programs/Projects domain ERD — see `decisions.md` ~L8170-8190. | N/A — Tier 0, file memory only | *(retroactive entry, logged 2026-08-25 — actual first use predates this log, ~2026-06-16)* |
| `Dev-Project Revisions.mermaid` | Mermaid ERD | Same consolidation as above — the Revision-domain counterpart ERD. | N/A — Tier 0, file memory only | *(retroactive entry, logged 2026-08-25 — actual first use predates this log, ~2026-06-08)* |
| `MYPS-Module-Function-Inventory.md` | Function/module inventory | Source for the module→function mapping that resolved RISK-025 — see `decisions.md` ~L8484. | N/A — Tier 0, file memory only | *(retroactive entry, logged 2026-08-25 — actual first use predates this log, ~2026-06-16)* |
| `LOCAL-MYPS(schema).sql` | Legacy DB schema export | The baseline legacy-schema source (112 tables) cited throughout `decisions.md`/`database.md` as the as-built ground truth; also the default input path for `memory/clients/myps/myps-system/scripts/parse-myps-schema.py` — a live script dependency, not just a reference. | N/A — Tier 0, file memory only | *(retroactive entry, logged 2026-08-25 — actual first use predates this log, ~2026-06-17)* |
| `LOCAL-MYPS(View-SCHEMA).sql` | Legacy DB view export | Same baseline set as above — 25 legacy views. | N/A — Tier 0, file memory only | *(retroactive entry, logged 2026-08-25 — actual first use predates this log, ~2026-06-17)* |
| `LOCAL-MYPS(Procedure-SCHEMA).sql` | Legacy DB procedure export | Same baseline set — cited as the point-in-time export behind the new orchestrator procs — see `decisions.md` ~L8502. | N/A — Tier 0, file memory only | *(retroactive entry, logged 2026-08-25 — actual first use predates this log, ~2026-06-17)* |
| `AdminAreaCityMunicipality.csv.xlsx` | Admin-area source data | Part of the AAMS/IOMS admin-area domain evidence trail (ADR-047/074 backfill) — see below, same finding as the other 2 admin-area files. | N/A — Tier 0, file memory only | *(retroactive entry, logged 2026-08-25 — actual first use predates this log, ~2026-08-04)* |
| `AdminAreaCongressionalDistrict.csv` | Admin-area source data | Matches a live staging table in `myps_db` (`AdminAreaCongressionalDistrict`, 257 rows, row count verified exact) kept as the ADR-047/074 AAMS/IOMS backfill evidence trail — see `decisions.md` ~L3341-3347. | N/A — Tier 0, file memory only | *(retroactive entry, logged 2026-08-25 — actual first use predates this log, ~2026-08-04)* |
| `InternalOrgUnits.csv` | Admin-area source data | Same finding as above — matches a live staging table (`InternalOrgUnits`, 329 rows, exact match). | N/A — Tier 0, file memory only | *(retroactive entry, logged 2026-08-25 — actual first use predates this log, ~2026-08-04)* |
| `exception-report-validation-fields-prompt.md` | Validation-field spec | Cited in `database.md` ADR-081 — aligning the app's `ExceptionReport` publish validation with the DB gate's field checks. | N/A — Tier 0, file memory only | *(retroactive entry, logged 2026-08-25 — actual first use predates this log, ~2026-08-06)* |
| `province.csv` | Admin-area source data | **Confirmed 2026-08-25** (was flagged as possibly-orphaned by a memory audit, then checked): matches a live staging table in `myps_db` (`province`, 83 rows, row count verified exact) — same ADR-047/074 AAMS/IOMS backfill evidence trail as the 3 rows above, explicitly kept as evidence behind still-open items (ASS-008 Pangasinan, Davao de Oro). Not orphaned. Per operator (2026-08-25): admin areas are now locked, no further changes needed. | N/A — Tier 0, file memory only | *(retroactive entry, logged 2026-08-25)* |
| `API_import_aams_ioms_1.xlsx` | Admin-area source workbook | **Checked 2026-08-25** (same flag/resolution as `province.csv`): a 4-sheet workbook (`AdminAreaRegionProvince`, `AdminAreaCityMunicipality`, `AdminAreaCongressionalDistrict`, `InternalOrgUnits`) whose sheet names match the domains of the other admin-area files above — almost certainly the original combined AAMS/IOMS export those were split from (inferred from structure, not a literal filename citation in `decisions.md`). Per operator: admin areas are locked, no further reconciliation needed this pass. | N/A — Tier 0, file memory only | *(retroactive entry, logged 2026-08-25)* |
