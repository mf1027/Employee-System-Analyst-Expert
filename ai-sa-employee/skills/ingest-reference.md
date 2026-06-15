# Skill: ingest-reference

## Purpose
Process a file the operator has placed in `reference/` — read it once, distil
the key information into **claude-mem** as tagged knowledge entries, and update
`reference/README.md`. Keeps memory.md lean; knowledge is retrieved on demand
via semantic search rather than auto-loaded every session.

## Trigger
Invoke when the operator says "ingest this file", "process the reference material",
"add [file] to the knowledge base", or drops a file into `reference/` and asks
you to read it.

## Minimum context required
- The filename (or a description of what was added to `reference/`)
If missing: list the files currently in `reference/` and ask which to ingest.

---

## Steps

1. Search claude-mem: `mem search [filename or topic]` — check whether entries
   from this file already exist to avoid duplicates.
2. Read the README in the file's folder (repo-root `reference/`, client `reference/`, or
   `migration/legacy|target/`) — confirm what's already indexed there.
3. **Read the source file** in `reference/` once, in full.
4. Extract and categorise the key information:
   - Business domain / context
   - Requirements or constraints stated or implied
   - Risks or assumptions mentioned
   - Technical / database details
   - Decisions already made
5. For each distinct knowledge item, store in claude-mem via `memory_add`:
   - **Title:** `[Category] — [Short title]`
   - **Content:** 2–4 sentence distillation of what this says and why it matters
   - **Tags:** `category:[type]`, `source:reference/[filename]`,
     `client:[name]` (if client-specific), `project:[name]` (if project-specific)
   - **Categories:** Business, Requirements, Risk, Technical, Database,
     Process, Compliance, Stakeholder, Glossary
   - **Conversion projects — mandatory `system:` tag.** If the file came from
     `[project]/migration/legacy/` tag it `system:legacy`; from `migration/target/` tag it
     `system:target`. NEVER omit this on a conversion project and NEVER mix the two — a legacy
     fact is not a target requirement. Route legacy material to `migration/legacy/` and target
     material to `migration/target/` (not the shared `reference/`). See `conversion-analysis`.
6. Update the **README co-located with the ingested file** — append a row to its `## Ingestion Log`
   table with: filename, type, summary (one line), entry titles stored, date ingested. The target
   README depends on where the file lives:
   - repo-root `reference/` → `reference/README.md`
   - client folder `memory/clients/[client]/reference/` → that folder's `reference/README.md`
   - conversion project `…/migration/legacy/` or `…/migration/target/` → that folder's `README.md` (its Inventory table)
   If the README or its `## Ingestion Log` table doesn't exist yet, create the table first
   (columns: `File | Type | Summary | claude-mem entries | Date ingested`). Do **not** log a
   client/project file's ingestion into the repo-root `reference/README.md`.
7. Search claude-mem for any entry that conflicts with what was just stored —
   surface conflicts for the operator to resolve.
8. Flag any requirements, risks, or decisions implied by the file that haven't
   yet been logged in the project's deliverable files.

---

## How to store in claude-mem

Use the `mcp__claude-mem__memory_add` tool (or `mem add` in claude-mem skill):

```
Title:   "Database — PostgreSQL version and schema summary"
Content: "Client uses PostgreSQL 14 on AWS RDS. Main schema has 3 core tables:
          orders, customers, products. orders has ~2M rows. No foreign keys enforced
          at DB level. Source: reference/db-schema-export.sql"
Tags:    category:Database, source:reference/db-schema-export.sql, client:acme
```

To retrieve later: `mem search "PostgreSQL schema"` or `mem search "orders table"`

---

## Output format

```
REFERENCE INGESTED: [filename]
Date: [YYYY-MM-DD]
---
Entries stored in claude-mem:
- [Category] — [Title]: [one-line summary]
- [Category] — [Title]: [one-line summary]

Ingestion Log updated in: [reference/README.md | clients/[client]/reference/README.md | …/migration/[legacy|target]/README.md] ✓

Conflicts with existing knowledge:
- "[existing entry]" conflicts with this file on [topic] — needs resolution
  (or "None detected")

Flags:
- Implied requirement: REQ-F0X candidate — [description] — not yet in requirements.md
- Implied risk: RISK-NNN candidate — [description] — not yet in risks.md
- Implied decision: ADR candidate — [description] — not yet in decisions.md

Source file: reference/[filename] — DO NOT re-read; search claude-mem for "[topic]"
```

---

## Quality checklist

- [ ] Has the source file been read exactly once?
- [ ] Does every entry have a source tag `source:reference/[filename]`?
- [ ] Is the **co-located** README's Ingestion Log updated (client `reference/` or `migration/` README — not the repo-root one for client/project files)?
- [ ] For conversion-project files: is the `system:legacy` / `system:target` tag set?
- [ ] Were conflicts with existing claude-mem entries checked?
- [ ] Are implied requirements, risks, and decisions flagged?

## Failure exit
"No file specified. List the contents of reference/ and ask which file to ingest."
