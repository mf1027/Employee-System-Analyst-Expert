# Skill: document-specialist-skill

## Purpose
Route requests for formal document output to the correct document-skill, wrapping
it with the right SA/PM content context. Bridges the employee's deliverable language
(SRS, PRD, SDD, status deck, tracker) to the document generation engine.

## Trigger
Invoke when the operator says:
- "generate an SRS" / "write a PRD" / "create an SDD" / "formal document"
- "make a presentation" / "create a deck" / "make slides"
- "build a tracker" / "make a spreadsheet" / "create a workbook"
- "export this to Word" / "put this in a document"
- "read this file" / a file path is shared / an uploaded file is mentioned
- "read this PDF" / "extract from this PDF" / "what does this PDF say"

## Minimum context required
- What type of document is needed (or the file to read)
- Which client and project it belongs to
- For generation: the source content (requirements.md, plan.md, decisions.md, or a brief)
If missing: ask which client/project and what the document should contain.

---

## Routing table

| Request | Output format | Skill to invoke | Dependency |
|---|---|---|---|
| SRS, PRD, BRD, SDD, formal spec | Word (.docx) | `document-skills/docx/SKILL.md` | ⚠️ LibreOffice |
| Status report, meeting minutes, memo | Word (.docx) | `document-skills/docx/SKILL.md` | ⚠️ LibreOffice |
| Presentation, deck, slides | PowerPoint (.pptx) | `document-skills/pptx/SKILL.md` | ⚠️ LibreOffice |
| Project tracker, RAID log, budget | Excel (.xlsx) | `document-skills/xlsx/SKILL.md` | ⚠️ LibreOffice |
| PDF creation / form filling | PDF | `document-skills/pdf/SKILL.md` | ⚠️ Poppler |
| Read an uploaded/shared file | Any format | `document-skills/file-reading/SKILL.md` | ✅ Ready |
| Read / inspect a PDF | PDF | `document-skills/pdf-reading/SKILL.md` | ✅ Ready |

---

## Steps

### For document generation (docx / pptx / xlsx / pdf)

1. **Check dependency.** Ask: is LibreOffice on PATH?
   ```
   PowerShell: (Get-Command soffice -ErrorAction SilentlyContinue)?.Source
   Bash: which soffice
   ```
   If not found → inform the operator (see "Phase 2 fallback" below) and offer
   a Markdown alternative.

2. **Identify document type** from the operator's request. Map to routing table above.

3. **Gather source content.** Read the relevant memory lane files:
   - SRS / PRD / BRD → `requirements.md` + `decisions.md` + stakeholder notes
   - SDD / Architecture → `decisions.md` + ADRs + `requirements.md`
   - Project plan / tracker → `plan.md` + `risks.md`
   - Status report → `plan.md` + `risks.md` + recent `memory/memory.md` entries

4. **Run Understanding Check.** Confirm document title, audience, sections, and
   output path before generating.

5. **Invoke the target SKILL.md** with the gathered content as input.
   Save output to `deliverables/documents/[client]/[project]/[document-name].[ext]`.

6. **Log the deliverable.** Add a `KB-` entry to claude-mem:
   `category:deliverable source:[path] client:[name] project:[name]`

---

### For file reading (file-reading / pdf-reading)

1. **Identify the file type** from extension or the operator's description.

2. **Route immediately** — no dependency check needed, both are ✅ Ready:
   - Any file type → follow `document-skills/file-reading/SKILL.md` dispatch table
   - PDF specifically → follow `document-skills/pdf-reading/SKILL.md`

3. **Note: file paths in Claude Code** — unlike claude.ai uploads (which land at
   `/mnt/user-data/uploads/`), files in this project are on the local Windows
   filesystem. Use `Read` tool or `ctx_execute_file` for local file analysis.
   Adapt the skill's Bash/Python commands to Windows paths.

4. **After reading:** apply triple-lens review — extract any REQ-, RISK-, or REC-
   items from the document content and auto-log them with IDs.

---

## Phase 2 fallback (LibreOffice not installed)

If LibreOffice is missing, offer:

```
LibreOffice is not installed — Word/PowerPoint/Excel generation (Phase 2) is
unavailable on this machine. I can:

Option A: Generate the full document in Markdown → you copy-paste into Word
Option B: Generate a structured template you can fill in Word directly
Option C: Walk you through installing LibreOffice (run `scripts/setup.ps1`)

Which do you prefer?
```

For Markdown output, follow the same content-gathering steps and produce
the document as a `.md` file in `deliverables/documents/[client]/[project]/`.

---

## Document templates reference

| Document | Key sections | Source files |
|---|---|---|
| SRS (Software Requirements Spec) | Introduction, Stakeholders, Functional Reqs (REQ-F), NFRs (REQ-NF), Use Cases, Constraints | requirements.md, decisions.md |
| PRD (Product Requirements Doc) | Vision, User Problems, Goals, Features (MoSCoW), Acceptance Criteria, Out of Scope | requirements.md |
| BRD (Business Requirements Doc) | Business Context, Stakeholders, Current State, Future State, Benefits, REQ-B IDs | requirements.md, risks.md |
| SDD (System Design Doc) | Architecture Overview, Components, Interfaces, ADRs, Data Model, NFR Responses | decisions.md, requirements.md |
| Project Plan | Phases, WBS, Milestones, Critical Path, RAID, Resource Plan | plan.md, risks.md |
| Status Report | RAG Summary, Progress, Risks, Decisions Needed, Next Steps | plan.md, risks.md |

---

## Quality checklist

- [ ] Understanding Check confirmed before generating
- [ ] Source content gathered from correct memory lane files
- [ ] Document type and audience confirmed
- [ ] Deliverable saved to `deliverables/documents/[client]/[project]/`
- [ ] KB- entry logged to claude-mem with path and client/project tags
- [ ] Triple-lens applied to extracted content (REQ-/RISK-/REC- auto-logged)
- [ ] Phase 2 dependency handled gracefully if LibreOffice missing
