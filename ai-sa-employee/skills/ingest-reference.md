# Skill: ingest-reference

## Purpose
Process a file the operator has placed in `reference/` — read it once, distil
the key information into **canonical project memory** as tagged knowledge entries, and update
`reference/README.md`. Keeps canonical project records concise; knowledge is retrieved on demand
via semantic search rather than auto-loaded every session.

## Trigger
Invoke when the operator says "ingest this file", "process the reference material",
"add [file] to the knowledge base", or drops a file into `reference/` and asks
you to read it.

## Minimum context required
- The filename (or a description of what was added to `reference/`)
If missing: list the files currently in `reference/` and ask which to ingest.

---

## Document-type routing (read the file as what it *is*)

A contract, a meeting transcript, and a schema dump carry different value — extracting all of
them with the same generic pass loses the point of each. Detect the type first (from extension,
filename, and the first page), then bias extraction toward what that type is *for*:

| Detected type | Signals | Extraction emphasis |
|---|---|---|
| Contract / SOW / MSA | "agreement", "party", clauses, signatures | Obligations, deadlines, penalties, scope boundaries → `REQ-`/`RISK-` candidates |
| Spec / SRS / PRD | numbered requirements, "shall", acceptance criteria | Requirements → `REQ-` candidates with their criteria |
| Meeting notes / transcript | dates, attendees, "we decided", action items | Hand off to `ingest-meeting-notes` (decisions/actions/risks) — don't duplicate here |
| Schema / DDL / ERD | `CREATE TABLE`, columns, FKs | Hand off to `dba-schema-ingest`; store a `category:Database` summary |
| API spec / contract | endpoints, OpenAPI, request/response | Integration points, contracts → `category:Technical` |
| Brief / RFP / proposal | goals, evaluation criteria, budget | Business context, constraints, success criteria |
| Data sample / export | CSV/rows, headers | Volume, field meanings, quality issues (nulls, encoding) |

If the type is ambiguous, say which two it could be and extract for both. If it routes to another
skill (meeting notes, schema), invoke that skill instead of re-implementing its extraction here.

---

## Steps

1. Review the relevant project memory lane for existing entries from this source to avoid duplicates.
2. Read the README in the file's folder (repo-root `reference/`, client `reference/`, or
   `migration/legacy|target/`) — confirm what's already indexed there.
3. **Detect the document type** (routing table above) and **read the source file** once, in full,
   reading it as what it is.
4. Extract and categorise the key information, **biased by the detected type**:
   - Business domain / context
   - Requirements or constraints stated or implied
   - Risks or assumptions mentioned
   - Technical / database details
   - Decisions already made
5. For each distinct knowledge item, store in canonical project memory via approved project-memory update:
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
   (columns: `File | Type | Summary | canonical memory entries | Date ingested`). Do **not** log a
   client/project file's ingestion into the repo-root `reference/README.md`.
7. Search canonical project memory for any entry that conflicts with what was just stored —
   surface conflicts for the operator to resolve.
8. **Cross-reference against the project's existing IDs.** Read `requirements.md`/`risks.md`/
   `decisions.md` and compare what this file implies against what's already logged:
   - **New** → flag as a `REQ-`/`RISK-`/`ADR-` candidate.
   - **Already covered** → cite the existing ID (don't create a duplicate).
   - **Conflicts** with a logged item → surface it explicitly for the operator to resolve.
   This makes ingestion additive and conflict-aware instead of a blind dump.

---

## How to store in canonical project memory

Write the approved entries directly to the existing canonical project memory lane using the normal file-editing workflow; no separate memory service is used.

```
Title:   "Database — PostgreSQL version and schema summary"
Content: "Client uses PostgreSQL 14 on AWS RDS. Main schema has 3 core tables:
          orders, customers, products. orders has ~2M rows. No foreign keys enforced
          at DB level. Source: reference/db-schema-export.sql"
Tags:    category:Database, source:reference/db-schema-export.sql, client:acme
```

To retrieve later: search/read the relevant canonical project memory file for the topic.

---

## Output format

```
REFERENCE INGESTED: [filename]
Date: [YYYY-MM-DD]
---
Entries stored in canonical project memory:
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

Source file: reference/[filename] — DO NOT re-read; search canonical project memory for "[topic]"
```

---

## Quality checklist

- [ ] Has the source file been read exactly once?
- [ ] Does every entry have a source tag `source:reference/[filename]`?
- [ ] Is the **co-located** README's Ingestion Log updated (client `reference/` or `migration/` README — not the repo-root one for client/project files)?
- [ ] For conversion-project files: is the `system:legacy` / `system:target` tag set?
- [ ] Were conflicts with existing canonical project memory entries checked?
- [ ] Are implied requirements, risks, and decisions flagged?

## Failure exit
"No file specified. List the contents of reference/ and ask which file to ingest."
