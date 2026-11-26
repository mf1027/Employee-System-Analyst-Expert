# Plan: Production-Readiness Next Steps — Employee System Analysis Expert 2.3.1

Status: IN_PROGRESS

## Goal

Define a detailed, executable sequence to close portable-agent 2.3.1 production-readiness gaps, with measurable evidence gates and a bounded GO/NO-GO decision. This plan does not itself certify or authorize deployment, publication, permission expansion, or production data use.

- Tier: FULL
- Mode: DOCUMENT
- Approval gate: Live runtime qualification requires an exact host/model/OS profile and safe synthetic workspace; publication/deployment/permission expansion remain separate approvals.

## Context

**Prepared:** 2026-11-26
**Scope:** Portable agent under `portable-agent/`, its enclosing release packager, and qualification of one explicitly named host/model profile.
**Current source baseline:** parent repository branch `Enhanced`, HEAD `f46eeaad90106c5f34b321e0be0f65ca807ce7dd`, with local uncommitted remediation changes present at time of authoring. Reconfirm revision and file status before using this plan.

Scope in: local package and release-packager regression work; qualification of one exact runtime profile using synthetic data and least privilege; routing/adversarial/task-quality/continuation tests; isolated clean install and claimed platform flows; exact archive, source revision, provenance and privacy review.
Scope out unless separately authorized: installation/configuration in a daily host profile; broader permissions; production/client data, secrets, real external services or production databases; Git history rewrite, secret revocation/rotation, remote deletion; universal support/safety claims. This document is not standing release authorization.

| # | Required | Actual | Gap | Class | Sev | Owner |
|---|---|---|---|---|---|---|
| 1 | Source package metadata valid | Regenerated and validator passed on audited snapshot | Must re-run after final plan edit | partial | major | Package maintainer |
| 2 | Offline tests candidate-bound | 61 portable tests and parent suite passed; one platform-dependent skip | Repeat after final package changes | partial | major | QA/release |
| 3 | Host instructions loaded | No exact profile named or live check run | Runtime unknown | untested | blocker | Host owner |
| 4 | Permission boundaries effective | No live prompt/tool/state tests | Enforcement unknown | untested | blocker | Security/host |
| 5 | Artifact privacy | Filter fixed and regression test added | Final artifact/history must be rechecked | partial | major | Release/security |

Checked 5/5 high-level gates; unchecked runtime and provenance claims are UNVERIFIED, not passes.

## Evidence


The recommended next step is **not** broad distribution or write-capable use. First choose one host/model/provider/version/OS profile and qualify it in a fresh disposable synthetic workspace under least privilege. Static validation and offline tests establish package-contract properties, not live host/model behavior or enforcement.

- [VERIFIED] Source validator passed after regenerating manifest metadata; the stale mismatch was caused by unregenerated metadata after content changed (exact historical triggering edit unknown).
- [VERIFIED] Offline portable suite passed: 61 tests; `compileall` passed.
- [VERIFIED] Parent `npm test` passed; backup suite reported 3 passes and 1 platform-dependent symlink skip.
- [VERIFIED] Packager now excludes all content under `reference/`, `deliverables/`, `pdf-source/`, and `engines/`; regression test asserts absence of members under these roots.
- [VERIFIED] Current offline candidate r5: `C:\Users\Msi\deliverables\Employee-System-Analysis-Expert-2.3.1-readiness-candidate-r5.zip`; 521 payload files; SHA-256 `02090405e5ef0e22a05ccca7c1c6f994f031abc06d281293128c1e20b6a7e8c1`. Passed ZIP CRC/member checks, fresh extraction validator, 61 portable tests and compileall. Candidate predates the latest checkpoint text and is superseded; do not distribute.
- [VERIFIED] No live host/model, permission, adversarial, clean-install, Windows PowerShell, remote-history/provenance, external publication or deployment qualification was performed.

| Decision | Current result | Rationale |
|---|---|---|
| Portable package integrity | PASS on audited local snapshot | Manifest regenerated and package validator passed |
| Offline portable tests | PASS | 61 tests; compileall passed |
| Parent regression suite | PASS | Node tests passed; backup suite 3 passes, 1 platform skip |
| Exact host instruction discovery | NOT RUN | No selected profile or live runtime evidence |
| Model routing/task quality | NOT RUN | Fixtures are not live model behavior |
| Permission denial/approval boundary | NOT RUN | Actual host permission and state effects not exercised |
| Clean dependency install/platform support | PARTIAL / NOT RUN | Clean install and Windows PowerShell flows unverified |
| Git history/provenance/publication | NOT RUN | No history audit or signing evidence |
| Production-ready designation | **NO-GO** | Critical runtime and release gaps remain |

## Approach

**Recommended:** finish the offline candidate release gate, then perform a single-profile read-only live qualification in a disposable synthetic workspace. This separates evidence types and prevents package tests from being mistaken for runtime containment.

**Rejected:**

| Option | Why not |
|---|---|
| Broad distribution now | Runtime and provenance gates are open; prior archive exposed local-only README content |
| Enable write-capable use as the first test | Adds risk before read-only instruction loading and permission behavior are qualified |
| Treat static fixtures as runtime certification | Offline tests cannot prove actual host/model behavior |

**Impact surfaces**

| Surface | Impact |
|---|---|
| Code / config / jobs / tests | Packager, package tests and integrity metadata; no runtime implementation planned |
| API / contracts / permissions | No API changes; live profile permissions remain explicit gate |
| Schema / procs / migrations / indexes | NOT_APPLICABLE: no database scope |
| Deploy / observability / backup / docs | Readiness documentation and release evidence; no deployment authorized |
| Security / PII / performance / cost | Archive privacy, secrets, sandbox boundaries; live cost to be bounded by profile owner |
| Stakeholders: approves / affected / informed | Operator chooses profile; security/release owner signs gates; no client data used |

**Lens selection**

| Family | Verdict (`APPLIED` / `NOT_APPLICABLE`) | Finding or reason | Evidence / level |
|---|---|---|---|
| Diagnostic | APPLIED | RCA confirms README exception bypassed root exclusion | E2 source and regression tests |
| Comparative / variance | APPLIED | Offline package checks pass; live profile evidence absent | E3 tests; live untested |
| Temporal / trend / funnel / cohort | NOT_APPLICABLE | No time-series operational data; add if longitudinal pilot begins | No trend data in scope |
| Economic / CBA | NOT_APPLICABLE | No costs/benefits quantified; no rollout decision yet | Revisit with deployment proposal |
| Strategic / SWOT / PESTLE | APPLIED | Benefit is safer distribution; weakness is profile-specific evidence gap | Risk register and plan |
| Risk / threat / scenario | APPLIED | Threat boundaries and hard-stop cases defined below | Plan-level; live tests open |
| Data / exploratory | NOT_APPLICABLE | No production dataset authorized; synthetic data only | No production data used |
| Decision / prioritisation | APPLIED | P0 archive/runtime gates precede P1 reproducibility/provenance | Gap register |

**Premortem**

| Headline | Mechanism | Earliest signal | Guard added to plan |
|---|---|---|---|
| "Local ingestion notes ship again" | New package root bypasses filter | Protected-root member in archive listing | Exact final archive inspection and regression assertion — Stage 1/6 |
| "Model claims obeyed policy but wrote anyway" | Prompt text mistaken for tool enforcement | Workspace diff or unapproved tool call | Capture native tool calls and before/after state — Stage 3/4 |
| "Candidate cannot be reproduced" | Archive unbound to source/tests | Digest or manifest mismatch | Candidate hash and extracted-artifact gate — Stage 1 |

## Assumptions

1. Initial qualification uses a read-only synthetic workspace — default if unanswered: keep live gate BLOCKED.
2. No external publication or deployment is authorized by this plan — default: do not publish/deploy.
3. Candidate r4 was produced from a dirty local checkout — default: treat as diagnostic offline snapshot, not signed release.
4. Owner must specify exact host/model/provider/version/OS — default: do not choose for them; production status remains NO-GO.
5. Tests and local source evidence remain available — default: rerun checks if files or environment changed.

## Stages
- Finish the local package and release-packager regression work already in progress.
- Qualify one exact runtime profile using synthetic data and explicit least-privilege settings.
- Run the package's 30 routing cases and 16 adversarial cases against that profile, plus task-quality and continuation checks.
- Verify clean dependency installation and claimed platform flows in isolated environments.
- Review the exact release archive, source revision, provenance and privacy scope before any external distribution decision.

**Out of scope unless separately authorized:** installation/configuration in the operator's daily host profile; broader permissions; production/client data, secrets, real external services or production databases; Git history rewrite, secret revocation/rotation, remote deletion; universal support/safety claims. This document is not standing release authorization.

**RCA — stale integrity metadata:** source package validator reported size/hash/SHA256SUMS disagreement for `docs/PRODUCTION-READINESS-REMEDIATION-2.3.1.md` (9,928 current bytes versus stale 9,936-byte binding). Current SHA-256 was `590726f77f99ca750b1b2f71dac1d8190959946c3768e23371c9a51a23e1771f`; prior manifest entry was `a35fa391ed34ac52e2ca410dfe8fdaba40fe0b5da9a2b81e62387f565ff994c1`. Mechanism: generated integrity metadata was not regenerated after content changed; exact historical triggering edit is unknown. Regeneration and validator passed; regenerate after any further included package edit.

**RCA — local-only README archive leakage:** release packager excluded most files in local-only roots but allowed `README.md`; `reference/README.md` contained a 53-line ingestion log with MYPS project/user-story names and detailed domain information. Earlier archive included this README; inclusion of raw client PDFs or other local files is not established. Root cause was filename exception overriding protected-root exclusion, and tests did not assert all README sentinels absent. Fix excludes all content under `reference/`, `deliverables/`, `pdf-source/`, `engines/`; packager test now asserts no archive entries there. Focused and full parent tests passed. Prior candidate archives are superseded.

**RCA — live qualification gap:** no live model defect is demonstrated; what is confirmed is the absence of evidence for a named runtime profile. Offline fixtures cannot prove live host instruction loading, model behavior, permission enforcement, or data isolation.

| ID | Gate / target | Evidence still required | Priority / effect | Owner |
|---|---|---|---|---|
| G-01 | Candidate package integrity | Regenerate manifest; validator on source and extracted archive | P0 block archive | Package maintainer |
| G-02 | Offline tests candidate-bound | Portable tests, compileall, parent tests, extraction; record skips | P0 block archive | QA/release |
| G-03 | Exact host loads intended contract and skill | Native host evidence of active instructions/skills/settings | P0 for pilot | Host qualification |
| G-04 | Permission boundaries enforced | Allowed/denied cases, observed prompts/tool calls and unchanged state when denied | P0 for write-capable use | Security/host |
| G-05 | Live model routes/responds adequately | 30 route cases and representative tasks on exact profile | P1 read-only; P0 high-impact | Evaluation |
| G-06 | Interruption/resume safe | Synthetic interrupted task, reconcile checkpoint, no duplicate/lost effect | P1 | QA/host |
| G-07 | Dependencies reproducible | Clean isolated `npm ci` and Python install with versions/hashes | P1 | Build |
| G-08 | Claimed OS flows work | Clean setup/backup/restore/PDF wrapper per claimed OS; PowerShell if Windows claimed | P1 | Platform |
| G-09 | Privacy/provenance acceptable | Final archive inspection; authorized history review; signing policy | P1 before external distribution | Release/security |
| G-10 | Status claims truthful | Reports identify candidate hash/profile and evidence level | P2 | Maintainer |

Any P0 gap blocks the corresponding production claim. The recommended sequence is offline candidate gate, named profile decision, read-only host discovery, routing/adversarial/permission tests, clean install/platform qualification, final privacy/provenance review, then a bounded go/no-go. No stage implies authorization for publication or deployment.

## Approach
### Stage 0 — Pin and protect the baseline (local, read-only)

1. Check `git status --short --branch`, `git rev-parse HEAD`, current remote/branch and intended file list.
2. Preserve unrelated changes; never stage the untracked `nul` or unrelated files.
3. Record artifact checksums; supersede stale candidates explicitly.

Check: `git status --short --branch` and `git diff --check`
Expected: intended changes enumerated; no unrelated files staged; diff check exit 0
Rollback: no repository mutation in this stage; if baseline is unclear, stop and restore no files

### Stage 1 — Finish package integrity and regression checks (local)

Regenerate manifest after final package changes, run source validator, portable tests, compileall and parent packaging/full tests. Build archive outside repository; inspect CRC and member list; assert protected roots absent; extract to an empty directory and repeat validator/tests/compileall.

Check: `python portable-agent/tools/build_manifest.py && python portable-agent/tools/validate_package.py && python -m unittest discover -s portable-agent/tools -p 'test_*.py' -v && python -m compileall -q portable-agent/tools && npm run test:packaging && npm test`
Expected: all required commands exit 0; report any platform skips; archive and extracted package validate; candidate SHA-256 recorded
Rollback: do not overwrite candidate; mark failed candidate superseded and build a new versioned archive after correction

### Stage 2 — Name and authorize one qualification profile (decision gate)

Record host/build, model/provider/version, OS, active instructions/skills/trust, permission settings, exposed tools, network access, disposable synthetic workspace, evaluator and evidence handling. Recommend read-only initial mode.

Check: profile record review against the required fields above
Expected: exact named profile, disposable workspace, no real secrets/client data or production connectivity, permissions known
Rollback: no runtime installation/action to roll back; if profile or permission identity is ambiguous, remain BLOCKED and do not run live tests

### Stage 3 — Verify host instruction discovery and harmless read-only behavior

Start fresh host context; confirm canonical `portable-agent/AGENT.md`, relevant skill and settings actually loaded; run benign synthetic analysis; inspect native tool activity and before/after workspace state. Do not weaken authentication or TLS to pass.

Check: host-native session evidence plus before/after synthetic workspace inventory
Expected: intended contract/skill loaded; no unauthorized write; result supports only named profile
Rollback: reset disposable workspace to captured baseline; stop if any real data/connectivity or unauthorized action appears

### Stage 4 — Execute routing, adversarial and permission suite

Run checked-in 30 routing cases and 16 adversarial cases against exact profile; re-count at runtime. Use fresh contexts and synthetic targets. Record actual tool calls, approval prompts and state effects. Exercise only tools exposed by profile. Run task-quality rubric and interrupted-run resume test. Any secret disclosure, unauthorized side effect, forged authorization, untrusted instruction override, or fabricated evidence is immediate FAIL; preserve sanitized evidence and stop.

Check: host-evaluation harness and per-case before/after state/evidence log
Expected: 100% critical safety/approval cases pass; no unexplained critical inconclusive; approved actions match permission matrix; quality meets thresholds set before testing
Rollback: restore only disposable synthetic workspace baseline; disable/close test session using host-supported controls; never clean up production/external resources

### Stage 5 — Clean install and platform qualification

In isolated environment, install Node from lockfile and Python project-local dependencies; record versions/hashes/source. Run setup, backup, restore, retention and PDF wrappers on every claimed OS; include PowerShell if Windows is claimed. Test backup preservation on simulated verification failure.

Check: clean-environment install plus platform-specific setup/backup/restore/PDF test commands from project docs
Expected: no global package mutations; reproducible dependency versions; claimed platform flows pass; prior good backup remains intact on failure
Rollback: remove only disposable environment and synthetic test data; retain known-good backup; do not modify global installs

### Stage 6 — Final privacy, history and provenance review

Inspect exact final archive for local-only roots, private memory, red-team quarantine, credentials and unexpected members. Perform authorized repository/history scans; do not rewrite history or rotate credentials here. Define provenance/signing, revision, digest, build environment, test evidence, limitations and rollback.

Check: final archive member scan, approved secret/privacy scanner and provenance checklist
Expected: no unresolved critical leak; release owner accepts exact artifact/hash and history disposition; reproducible source/test record; digest alone not represented as signed provenance
Rollback: quarantine the candidate and stop distribution; if actual exposure found, follow owner incident process, no unilateral history rewrite

### Stage 7 — Go/no-go and release boundary

GO only for exact tested artifact/profile/mode. NO-GO with any P0 gap, critical failure, incomplete evidence or ambiguity. Read-only pilot and write-capable production require separate decisions. External publication, deployment and expanded permissions remain separately authorized actions.

Check: signed gate record matching artifact SHA, source revision, profile, permissions and evidence
Expected: explicit bounded decision; no production-ready claim outside tested profile/use mode
Rollback: if any release artifact was staged but not published, quarantine it; do not publish/deploy without separate exact authorization

## Validation

Commands run after this plan is finalized:

| # | Command | Expected | Level |
|---|---|---|---|
| 1 | `python portable-agent/tools/build_manifest.py` | Regenerate consistent package metadata | E3_TESTED |
| 2 | `python portable-agent/tools/validate_package.py` | PASS integrity, links, adapters and catalogs | E3_TESTED |
| 3 | `python -m unittest discover -s portable-agent/tools -p 'test_*.py' -q` | 61 tests pass | E3_TESTED |
| 4 | `python -m compileall -q portable-agent/tools` | Exit 0 | E3_TESTED |
| 5 | `npm run test:packaging && npm test` | Pass; platform skip reported accurately | E3_TESTED |
| 6 | Extracted candidate validator/tests/compile | Same checks pass; no protected-root members | E3_TESTED |
| 7 | Live host qualification | NOT RUN; profile missing | NOT RUN |
| 8 | `python C:/Users/Msi/Desktop/LLM/Obsidian/Enhanced/03-SKILLS/thorough-plan/scripts/check_plan.py portable-agent/docs/PRODUCTION-READINESS-NEXT-STEPS-2.3.1.md` | Exit 0 after final edits | E3_TESTED |

Negative control: before the packager root-filter fix, an archive listing included `reference/README.md` — observed failing behavior: yes.

## Rollback

Keep source edits local and attributable; restore only intended files from the pre-change baseline if a change is rejected. Regenerated manifest and SHA256SUMS are a matching pair and must be restored/regenerated together. Never overwrite verified archives; quarantine and mark superseded. Live test rollback is limited to captured synthetic workspace baseline. Stop on unclear target, unexpected state, secret leak, test failure or unsafe rollback.

## Changelog

- 2026-11-26: Created detailed production-readiness RCA, gap register, profile-specific qualification sequence, verification and rollback gates; documented offline candidate evidence without claiming production readiness.
