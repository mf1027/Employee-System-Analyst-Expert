# reference/

Client source material — documents, images, data files, diagrams shared by the client or operator.

**How to use:** Drop any client file here, then say "ingest this" or invoke the `ingest-reference` skill.
The employee reads each file once, distills it into claude-mem as tagged KB entries, and never re-reads
the raw file unless asked.

**Supported formats:** `.md`, `.txt`, `.pdf`, `.png`, `.jpg`, `.csv`, `.mermaid`, SQL DDL, API specs,
schema dumps, ERD exports — see `skills/skills.md §2` for the full list.

**Subfolder suggestion:** `reference/[client-name]/[project-name]/` for multi-client work.
