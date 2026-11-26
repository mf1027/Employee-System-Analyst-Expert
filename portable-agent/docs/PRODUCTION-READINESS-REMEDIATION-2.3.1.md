# Employee System Analysis Expert — Production-Readiness Remediation Report 2.3.1

**Date:** 2026-11-26
**Baseline:** `Employee-System-Analysis-Expert-2.3.0.zip`
**Independent findings source:** `Deep-Production-Readiness-RCA-GAP-2.3.0-Independent-Review.md`
**Remediation release:** 2.3.1
**Verdict:** **Operational defects remediated where safely verifiable in the sandbox; NOT LIVE-PRODUCTION-CERTIFIED.**

## 1. Executive result

The 2.3.0 architecture was retained. The 2.3.1 pass focused on the concrete packaging, permission, evidence-integrity, backup, dependency, privacy, skill-discovery, and memory-instruction defects identified by the independent review. It did not add speculative skills or rebuild the portable resolver.

### Verified in this sandbox

- Parent Node test suite: **73 passed, 0 failed**.
- Parent backup Python suite: **4 passed, 0 failed**.
- Portable package validator: **PASS** — 22 canonical skills, 30 natural-language routes, 63 historical parity entries.
- Portable Python suite: **61 passed, 0 failed**.
- Python compilation: **PASS**.
- Every packaged Bash script: **LF line endings and `bash -n` PASS**.
- Backup archive integrity, manifest/hash verification, restore-to-disposable-directory, retention success, and failed-verification preservation: **PASS**.
- Memory hook simulation: **PASS** — informational output contains no `permissionDecision`; session IDs are sanitized.
- Release packager: **PASS** — local/private data and the red-team quarantine are excluded; archive manifest, CRC and SHA-256 are verified.

### Not certified

No live Claude Code, Codex, Hermes, Ollama, or other model session was started. No live host permission prompt, real model routing, real adversarial behavior, real Obsidian persistence, Git remote history, database access, or deployment boundary was exercised. Windows PowerShell execution was unavailable in this sandbox. Clean npm/Python dependency installation could not be completed because package registries were unreachable and the local npm cache did not contain the locked package tarball.

## 2. Independent finding reconciliation

| Finding | 2.3.1 action | Sandbox evidence | Remaining limitation |
|---|---|---|---|
| RCA-NEW-01 / GAP-003 — Bash CRLF | Added `.gitattributes`; normalized all packaged `.sh` files to LF; added syntax gate | All shell files pass `bash -n`; packaging test enforces no CR characters | Windows Git Bash and macOS/Linux setup smoke still need target-host execution |
| RCA-NEW-02 / GAP-002 — reminder hook grants `allow` | Removed `permissionDecision: allow`; hook emits only `systemMessage` and `additionalContext`; session ID sanitized | Hook simulation confirms no permission decision; regression test added | Actual first-write prompt must be observed in a fresh Claude Code session |
| RCA-NEW-03 / GAP-004 — self-attested runtime evidence | Caller-supplied evidence now yields `CLAIMS-CONSISTENT` at most; reported provider/skill states use `CLAIMED-VERIFIED`; direct `VERIFIED` builder input is downgraded | Runtime tests cover fabricated evidence, downgraded labels and status output | This is truthful labelling, not cryptographic or independent attestation; do not use it as certification proof |
| RCA-NEW-04 / GAP-009 — runtime/projection conflation | Split `runtime_status` from `mindmap_projection_status`; authorization only controls the documentation write | Tests cover authorized/unauthorized projection with identical runtime claim status | Live vault projection remains untested |
| RCA-NEW-05 / GAP-005 — dependency drift/global pip | Pinned `@opendataloader/pdf` and transitive dependency in lockfile; setup uses `npm ci`; removed unused/disabled claude-mem and context-mode npm packages; added exact Python requirements and project `.venv` wrappers | Lockfile/config inspection and setup regression tests pass | `npm ci` and venv package installation not completed due unavailable registry/cache; Python hashes are not yet pinned |
| RCA-NEW-06 / GAP-006 — unsafe backup retention | Replaced backup logic with verified ZIP + per-file SHA-256 manifest; retention runs only after successful verification; failed run removes temp and preserves prior archives | Three Python tests plus actual Bash wrapper smoke; disposable restore test passes | PowerShell wrapper not executed on Windows |
| RCA-NEW-07 / GAP-007 — privacy mismatch | Local operator memory, client lanes, archive, improvement backlog, references, deliverables, PDF source, engines, temp files and red-team quarantine excluded from production release ZIP; `.gitignore` updated; README claims corrected | Release-packager test checks excluded paths; release archive scan pending final artifact | Existing Git remote/history was not available; previously committed files must be audited and untracked by the owner if needed |
| RCA-NEW-08 / GAP-008 — Godmode discoverability | Moved payload from `.claude/skills/` to `quarantine/red-team/godmode/`; omitted from production release | Regression tests prove both active skill paths absent and quarantined payload retained | Live host skill listing not run; separate red-team profile not certified |
| RCA-NEW-09 / GAP-010 — stale memory/instruction drift | Marked `memory/memory.md` stale; excluded local memory from release; updated README, root instructions, employee skill and secondary workflows to use canonical Obsidian/project memory; deprecated claude-mem skill | Static cross-file checks and release exclusion tests | Fresh host session must verify the actual canonical vault is available and correctly read |
| RCA-NEW-10 / GAP-011 — delegation unclear | Preserved the host-dependent boundary; no false claim of configured AI subagents added | Static package checks remain green | Owner must decide whether real AI delegation is a requirement; if yes, host roster and live delegation test remain required |

## 3. Other existing gaps that remain open

| ID | Status | Closure required |
|---|---|---|
| GAP-001 — live host/model/permission certification | **OPEN / P0** | Select one primary host and exact model/provider; capture versions, active instruction files, trust state and permission profile; run in a disposable workspace |
| GAP-012 — live routing and task-quality benchmark | **OPEN / P1** | Run all 30 natural-language cases and representative end-to-end tasks against the exact model; score routing, completeness, traceability and factuality |
| GAP-013 — live prompt-injection and approval suite | **OPEN / P1** | Execute all 16 fixtures plus host-specific attacks; prove tool state did not mutate; 100% critical safety/approval pass |
| GAP-014 — continuation/resume behavior | **OPEN / P1** | Interrupt, restart, resume stale/conflicting checkpoints; prove no duplicated or lost work |
| GAP-015 — host permission enforcement | **OPEN / P1** | Negative tests for file, shell, Git, network, database and deployment operations under least privilege |
| GAP-016 — root/portable workspace discovery | **OPEN / P2** | Confirm selected host loads only the intended entry point and skill registry |
| Privacy / Git history | **OPEN / OWNER + SECURITY** | Audit actual remote history and sharing; `.gitignore` and release filtering do not erase historical commits |
| Windows compatibility | **PARTIAL / UNVERIFIED** | Run `setup.ps1`, `backup.ps1`, `pdf2md.ps1`, hook and fresh-extraction tests on a clean Windows machine |
| Python dependency lock hashes | **PARTIAL** | Generate a hash-locked requirements file from trusted wheel artifacts when registry access is available |

## 4. Release and installation changes

- Release version: `2.3.1`.
- Node engine floor: `20.19.0` (matches `@opendataloader/pdf` requirement).
- Node dependency: exact `@opendataloader/pdf@2.4.7`; `package-lock.json` pins `commander@14.0.3` with integrity metadata.
- Python document dependencies: exact versions in `requirements-docs.txt`; installed only into `.venv` by setup scripts.
- Use `scripts/python.ps1` (Windows) or `scripts/python.sh` (Linux/macOS) to invoke the isolated Python environment.
- `scripts/package-release.py` builds a deterministic privacy-filtered ZIP and SHA-256 sidecar. Output must be outside the source tree.
- The old working-memory snapshot is preserved locally with a stale warning; it is not shipped in the production release.
- The Godmode payload and retired MYPS-specific helper scripts remain only in local quarantine; they are not shipped in the production release ZIP. Machine-specific path references in live entry-point docs were replaced with environment variables/placeholders.

## 5. Owner decisions still required

1. Primary host to certify first: Claude Code, Codex, or another supported host.
2. Exact production model/provider and version.
3. Test OS and disposable workspace location/data classification.
4. Allowed read/write paths and least-privilege tool profile.
5. Whether real AI subagent delegation is required or single-agent mode is accepted.
6. Whether the quarantined Godmode payload should remain in the owner's local offline archive.
7. Which remote repositories and historical commits require privacy/secrets review.
8. Whether database or deployment capability is in scope; recommended default remains disabled.

## 6. Final readiness decision

**2.3.1 closes the sandbox-verifiable packaging and operational defects, but it is not a production certification.** Read-only pilot use is a candidate only after the chosen host confirms instruction discovery, memory source access, and normal permission behavior. File-write, Git push, database write, and deployment capabilities remain **NO-GO** until their specific host permission, adversarial, backup, rollback, and approval gates pass.

Do not describe caller-supplied evidence as independently verified. Do not infer host behavior from static tests. Do not grant unrestricted permissions based on this release report.
