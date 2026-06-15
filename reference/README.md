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
