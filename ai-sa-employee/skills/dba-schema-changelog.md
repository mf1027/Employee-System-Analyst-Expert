---
name: dba-schema-changelog
description: >-
  Maintains a structured changelog for database schema files — tracks which tables
  were added, modified, or dropped, with version tags, dates, and ADR references.
  Provides a machine-readable history that complements the prose ADRs in decisions.md.
  Use this skill when a schema file is modified, when the operator asks for schema
  history, or when preparing migration scripts that need to know what changed between
  versions.
---

# dba-schema-changelog

ADRs in `decisions.md` explain WHY decisions were made. The schema changelog tracks
WHAT changed, WHEN, and in WHICH file — the structured delta that migration scripts
and code reviews need.

---

## Trigger

Invoke when:
- A schema SQL file is modified (table added, column added/removed/renamed/retyped,
  constraint added/dropped, index added/dropped)
- The operator asks "what changed in the schema", "schema history", "diff since version X"
- Preparing migration scripts (need to know the delta between two versions)
- Onboarding a new team member who needs to understand schema evolution

---

## Changelog format

Each schema SQL file carries a changelog header block. The format is:

```sql
/* =============================================================================
   MYPS Web — [Domain] Schema

   ...existing header...

   CHANGELOG:
   | Ver | Date       | ADR     | Changes                                    |
   |-----|------------|---------|--------------------------------------------|
   | 1.0 | 2026-06-18 | ADR-005 | Initial: 7 tables (programs + projects)    |
   | 1.1 | 2026-06-23 | ADR-017 | +ProjectGroupFK (nullable INT FK) on tProjects |
   ============================================================================= */
```

### Changelog entry rules

1. **Version numbering:** MAJOR.MINOR
   - MAJOR increments on: new table, table dropped, table renamed, table split/merged
   - MINOR increments on: column added/removed/renamed/retyped, constraint change, index change
2. **Date:** absolute date (YYYY-MM-DD), never relative
3. **ADR reference:** the ADR-NNN that authorized the change
4. **Changes:** terse but complete — use these prefixes:
   - `+` = added (table, column, index, constraint)
   - `-` = dropped
   - `~` = modified (renamed, retyped, constraint changed)
   - `!` = breaking change (column removed, type narrowed, NOT NULL added to existing column)
5. **One line per change.** If a version has multiple changes, use multiple lines with the
   same version number, or semicolons for closely related changes.

### Examples

```
| 1.0 | 2026-06-18 | ADR-005 | Initial: tPrograms, tProgramRevisions, tProgramStages, tProjects, tProjectRevisions, tProjectStages, tOptionProgramStage |
| 1.1 | 2026-06-20 | ADR-012 | ~Type+YearStart moved from tProgramRevisions to tPrograms; ~ExternalId+MYId moved from tProjectRevisions to tProjects; -UACS from tProjectRevisions |
| 1.2 | 2026-06-23 | ADR-017 | +ProjectGroupFK (INT NULL) on tProjects; +FK_tProjects_ProjectGroup |
| 2.0 | 2026-06-25 | ADR-019 | +tLSWallets (new table); +ParentWalletId on tProjects |
```

---

## Steps

### 1. Before modifying a schema file

Check the current version in the changelog header:
- What is the latest version number?
- Is the header present? (If not, create it with the initial version)

### 2. Make the schema change

Apply the change to the SQL file.

### 3. Update the changelog

Add a new entry with:
- Incremented version number (MAJOR or MINOR per the rules above)
- Today's date
- The ADR reference
- Terse description using +/-/~/! prefixes

### 4. Cross-reference

Ensure the ADR in `decisions.md` references the schema file and version:
```
**How to apply:** `deliverables/documents/myps-schema-programs-projects.sql` (v1.2)
```

---

## Standalone changelog file (for multi-file schemas)

When a database spans multiple schema files, maintain a single consolidated
changelog at `deliverables/documents/schema-changelog.md`:

```markdown
# Schema Changelog — [Project]

## [Domain: Programs & Projects] — myps-schema-programs-projects.sql
| Ver | Date | ADR | Changes |
|-----|------|-----|---------|
| ... |

## [Domain: Project Details] — myps-schema-project-detail.sql
| Ver | Date | ADR | Changes |
|-----|------|-----|---------|
| ... |

## [Domain: Revision] — myps-schema-revision.sql
| Ver | Date | ADR | Changes |
|-----|------|-----|---------|
| ... |
```

This gives a single-file view of the entire schema history across all domains.

---

## Output format

When invoked, produce:

```
SCHEMA CHANGELOG UPDATE: [file]
Version: [old] → [new]
Date: [YYYY-MM-DD]
ADR: [ADR-NNN]
Changes:
  [+ / - / ~ / ! entries]

Updated files:
  1. [schema file] — changelog header updated
  2. [decisions.md] — ADR cross-references version
  3. [schema-changelog.md] — consolidated entry added (if exists)
```

---

## Rules

1. **Every schema file change gets a changelog entry.** No exceptions.
2. **ADR is mandatory.** No changelog entry without an ADR reference. If the change is
   too small for a full ADR, reference the parent ADR that authorized the work.
3. **Breaking changes get `!` prefix.** Column removals, type narrowings, NOT NULL additions
   on existing columns — these must be visible at a glance.
4. **Version in the file, not just in decisions.md.** The schema file itself carries its
   version history so you don't need to cross-reference another file to understand it.
5. **Consolidated changelog is optional but recommended** for projects with 3+ schema files.

---

## Quality checklist

- [ ] Schema file has a changelog header
- [ ] Version number incremented correctly (MAJOR vs MINOR)
- [ ] Date is absolute (YYYY-MM-DD)
- [ ] ADR reference present and valid
- [ ] Change description uses +/-/~/! prefixes
- [ ] Breaking changes marked with !
- [ ] ADR in decisions.md cross-references the schema file version
- [ ] Consolidated changelog updated (if it exists)

## Failure exit

"Cannot update schema changelog without knowing which schema file changed and what
the change was. Describe the file and the modification."
