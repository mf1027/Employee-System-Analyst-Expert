# deliverables/

**Fallback** output folder for ad-hoc / workspace-level documents that aren't tied to a specific
client or project (e.g. a one-off template, an internal memo).

> **Client/project deliverables do NOT go here.** They are saved with their project at
> `memory/clients/[client]/[project]/deliverables/` (gitignored, backed up by `backup.ps1`, and
> co-located with that project's requirements/plan/risks). This keeps a client's entire footprint
> in one portable folder for `resume-client` and handoff.

**Structure (fallback, non-client docs only):** `deliverables/documents/[name].[ext]`,
`deliverables/diagrams/`, `deliverables/pdf/`

**Note:** Everything here except this README is gitignored. Markdown fallbacks (when LibreOffice is
not installed) are saved as `.md`; binary formats (`.docx`, `.pptx`, `.xlsx`) require LibreOffice
(auto-installed by `scripts/setup.ps1`).
