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
| SRS, PRD, BRD, SDD, formal spec | Word (.docx) | `ai-sa-employee/document-skills/docx/SKILL.md` | ✅ Ready |
| Status report, meeting minutes, memo | Word (.docx) | `ai-sa-employee/document-skills/docx/SKILL.md` | ✅ Ready |
| Presentation, deck, slides | PowerPoint (.pptx) | `ai-sa-employee/document-skills/pptx/SKILL.md` | ✅ Ready |
| Project tracker, RAID log, budget | Excel (.xlsx) | `ai-sa-employee/document-skills/xlsx/SKILL.md` | ✅ Ready |
| PDF creation / form filling | PDF | `ai-sa-employee/document-skills/pdf/SKILL.md` | ✅ Ready |
| Read an uploaded/shared file | Any format | `ai-sa-employee/document-skills/file-reading/SKILL.md` | ✅ Ready |
| Read / inspect a PDF | PDF | `ai-sa-employee/document-skills/pdf-reading/SKILL.md` | ✅ Ready |

---

## Steps

### For document generation (docx / pptx / xlsx / pdf)

1. **Check dependency.** Is LibreOffice available? Check PATH *and* the default
   install dir (the patched `get_soffice_cmd()` checks both):
   ```
   PowerShell: (Get-Command soffice -ErrorAction SilentlyContinue) -or (Test-Path "C:\Program Files\LibreOffice\program\soffice.exe")
   Bash: which soffice
   ```
   If not found → inform the operator (see "Fallback" below), offer a Markdown
   alternative, and point to `scripts/setup.ps1` which auto-installs it.

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
   - Any file type → follow `ai-sa-employee/document-skills/file-reading/SKILL.md` dispatch table
   - PDF specifically → follow `ai-sa-employee/document-skills/pdf-reading/SKILL.md`

3. **Note: file paths in Claude Code** — unlike claude.ai uploads (which land at
   `/mnt/user-data/uploads/`), files in this project are on the local Windows
   filesystem. Use `Read` tool or `ctx_execute_file` for local file analysis.
   Adapt the skill's Bash/Python commands to Windows paths.

4. **After reading:** apply triple-lens review — extract any REQ-, RISK-, or REC-
   items from the document content and auto-log them with IDs.

---

## Fallback (LibreOffice not installed on this machine)

Engines are installed automatically by `scripts/setup.ps1` / `setup.sh`. If
LibreOffice is still missing (setup not run yet), offer:

```
LibreOffice is not installed — Word/PowerPoint/Excel generation is
unavailable on this machine. I can:

Option A: Run `scripts/setup.ps1` — installs LibreOffice + Poppler automatically
Option B: Generate the full document in Markdown → you copy-paste into Word
Option C: Generate a structured template you can fill in Word directly

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
- [ ] Engine dependency handled gracefully if LibreOffice missing (setup.ps1 fixes it)
