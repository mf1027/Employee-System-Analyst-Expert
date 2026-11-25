# Production Readiness Remediation — RCA / GAP / Risk Review

**Target:** Employee-System-Analysis-Expert reconstructed portable core, prior version 1.0.0
**Remediation version:** 2.0.0
**Basis:** package files and the supplied Portable Skills v6 process-flow clipboard
**Assessment type:** sandbox artifact audit and remediation; no live agent host was installed or invoked


## Executive verdict

Version 2.0.0 materially improves the portable operating contract, scenario workflows, test-fixture linkage, static integrity validation, and honest release claims. It is **PASS as a production-oriented portable instruction package / release candidate** based on the executed sandbox checks. It is **not runtime-certified**: live model routing, agent behavior, host discovery, actual skill invocation, and integration with Hermes/Claude/Codex have not been exercised.

The original package's most important failure was a mismatch between claims and evidence: its tests mostly tested hard-coded toy conditions, while the real scenario matrix was not wired to test execution. This release fixes the static/fixture side of that mismatch and explicitly does not claim that structural checks prove an agent behaves correctly.

## RCA

### Primary root cause — the package was authored as guidance, then treated as executable validation

- Workflow instructions existed, but they did not encode all v6 scenarios as explicit route-specific procedures.
- Routing fixtures were only checked for basic fields; they were not connected to route-to-workflow/skill consistency assertions.
- Scenario JSON and tests were independent, so the test suite could pass while scenario coverage drifted.
- Runtime limitations (host discovery, LLM behavior, tool availability) were not clearly separated from static package validity in the release story.

### Contributing causes
1. **Coverage model was incomplete:** broad skill guidance was mistaken for an operational workflow for specialized cases.
2. **Test architecture was disconnected:** hard-coded tests did not consume scenario/routing fixtures.
3. **Integrity tooling had a blind spot:** manifest completeness was not enforced; one packaged file was omitted.
4. **Adapter validation was shallow:** pointer files resolved on disk, but compatibility was not proven in a host.
5. **Release wording was too broad:** local tests were interpreted as evidence of agent-level readiness.

## Remediation completed

| Finding | Remediation | Verification |
|---|---|---|
| Agent contract lacked complete route map | Rewrote canonical `AGENT.md` with task router, universal lifecycle, modes, evidence labels, safety, canonical memory, and truthful completion controls | Static contract test |
| Missing dedicated scenario workflows | Added feature/change, research, analysis-only, scope-change, blocked-task, skill lifecycle, context optimization, release, multi-agent, routing, state machine, and continuation contract | Route fixtures check workflow files and skill references |
| New/existing-project SOP depth | Expanded discovery, baseline, current-state inspection, reconciliation, ready gate, and output expectations | Workflow phrase/structure tests |
| Routing/scenario fixtures disconnected | Unified 16-case coverage IDs and required workflow/skill mappings; tests load the fixture files directly | Fixture-connected regression tests |
| Adversarial cases missing | Added 10 prompts covering approval bypass, fake tests, stale checkpoint, schema invention, scope creep, repeated failure, analysis-only mutation, fake delegation, unavailable tools, and duplicate memory | Suite identity/coverage test; prompt behavior still needs live evaluation |
| Manifest omission/integrity gaps | Rebuilt manifest and checksum list; validator enforces completeness, sizes, hashes, format hygiene, links, adapter parity, fixture consistency | Static validator |
| Runtime claims overstated | README/release status explicitly states static/fixture validation only and host-specific/live-model tests remain unverified | Documentation assertion test |
| Checkpoint semantics weak | Explicit state machine and next-agent contract include resume reconciliation, state evidence, and next-action requirements | State/contract regression checks |


## v6 coverage / gap map

| v6 scenario | v2.0 workflow | Coverage | Evidence/remaining limitation |
|---|---|---|---|
| Master classify/context/route/execute/verify/report | `AGENT.md`, `routing.md`, state machine | Covered in package contract | Runtime routing behavior not proven |
| New project intake | `new-project.md` | Covered | No live elicitation evaluation |
| Requirement consolidation/baseline | `new-project.md`, requirements skill | Covered | Persistent project record depends on host/source-of-truth availability |
| Architecture/domain design | new-project + canonical skills | Covered | Skill content is prompt guidance, not deterministic enforcement |
| Plan/handoff | new-project, planning, handover | Covered | Real employee-agent integration untested |
| Implementation/TDD | implementation workflow + TDD skill | Covered | No live code-task execution evaluation in package tests |
| QA/acceptance | review-acceptance, test strategy | Covered | Independent QA is not guaranteed; simulated review disclosed |
| Existing project | `existing-project.md` | Covered | Runtime repository inspection depends on host tools |
| Interrupted/resumed task | continuation + contract | Covered | Cross-session persistence not verified |
| Bug/RCA | diagnosis | Covered | Model diagnostic accuracy not benchmarked |
| Feature in existing system | feature-change | Covered | Approval and implementation behavior needs live evaluation |
| Research/tutorial/video | research + video-intelligence | Covered | Retrieval/video tool capability is host-dependent |
| Analysis/planning-only | analysis-only | Covered | Prompt compliance requires live test |
| Code review | review-acceptance + code-review | Covered | Actual independent reviewer availability not assumed |
| Scope change | scope-change | Covered | Behavior under conflicting instructions untested live |
| Blocked/repeated failure | blocked-task | Covered | Retry budget is instruction, not runtime-enforced timer |
| Skill authoring | skill-lifecycle | Covered | Host discovery after installation untested |
| Context/token optimization | context-optimization | Covered | Savings are measured only when host exposes baseline metrics |
| Deployment/release | release | Covered | No deployment automation included; explicit authorization required |
| Multi-agent coordination | multi-agent | Covered | Shared workspace/delegation integration not tested |
| State machine | state-machine | Covered | Agent state transitions are not programmatically enforced |
| Next-agent contract | continuation-contract | Covered | Persistence must be supported by project mechanism |


## Risk register

| ID | Risk | Rating | Treatment / residual |
|---|---|---|---|
| R-01 | Agent ignores or misroutes a workflow | High | Live prompt evaluations and host routing smoke tests are required; static fixtures alone cannot close this |
| R-02 | Host fails to discover root instructions or skill pointers | High | Host-specific installation smoke test and version capture required |
| R-03 | User expects restored 63 original skill bodies | High | Explicit source boundary: only 21 authored core skills; 63 historical entries are inventory-only |
| R-04 | Checkpoint stale/incorrect | High | Resume must reconcile files/diff/tests and downgrade unsupported completion |
| R-05 | Unauthorized production/destructive action | Critical | Explicit action-target approval, preflight, rollback and abort gates; live adversarial tests still required |
| R-06 | Multiple agents conflict on shared files | High | Ownership, partitioned work, serialized writes, integration coordinator |
| R-07 | External research prompt injection or unreliable sources | High | Treat retrieved content as untrusted data; corroborate claims; no source text overrides agent/user/project policy |
| R-08 | Scope change causes unnoticed rework or unsafe migration | Medium/High | Pause, impact assessment, explicit decision, baseline/trace update |
| R-09 | Test fixture passing mistaken for LLM behavior proof | High | Release status labels static tests accurately; live eval must remain separate |


## Remaining release gates (must be run on the actual host)

1. Install the root instructions and selected skill pointers according to the actual host/version. Record the host version and configuration.
2. Verify auto-discovery of root instruction and at least one skill pointer; invoke the skill and capture host evidence.
3. Run live prompts for the four backbone cases: new project, resume/checkpoint, bug-to-fix, and approval-denied mutation.
4. Add live cases for analysis-only, scope change, release approval, blocked repeated failures, fake delegation, and untrusted retrieved content.
5. Verify canonical memory/checkpoint writes and cross-agent/session resume only if the runtime supports it.
6. Capture outputs and scoring criteria; distinguish expected/actual behavior, failures, and manual grading.
7. Do not call host runtime “production validated” until critical gate cases pass in the actual target runtime and failures are triaged.

---

## v2.1.0 Remediation — Skill Body Depth and Validation Hardening

**Date:** 2026-11-25
**Basis:** Full file-by-file inspection and root cause analysis

### RCA — Hollow skill bodies

**Primary root cause:** 19 of 21 canonical skill files were created by copying each skill's `REGISTRY.md` table-cell description into a standalone file with a heading. This satisfied the structural validator (file exists, name matches registry, adapter pointers resolve) but produced zero additional instructional content beyond what the registry already provides. The validator had no depth or anti-duplication check.

**Contributing causes:**
1. Validator checked file existence and hash; not body depth.
2. Tests checked structural contracts and routing; not skill content quality.
3. Adapter pointers masked hollowness — 42 pointer files created the appearance of a full library.
4. v2.0.0 PRODUCTION-READINESS-REVIEW mentions "21 authored core skills" without examining body depth.

### Remediation completed (v2.1.0)

| Finding | Remediation | Verification |
|---|---|---|
| 19/21 skill files were 2-line registry copies | Authored full procedure bodies for all 21 skills: Purpose, When to use, Prerequisites, numbered Procedure, Output contract, Safety/approval gates, Verification | All 21 files: min 47 lines, min 2,630 chars, 7/7 sections |
| 2/21 skills had marginal content | Expanded `process-analysis` and `requirements-analysis` to full procedure format | Same depth check passes |
| Validator had no depth check | Added min 10-line, min 500-char, required-section, and anti-duplication checks to `validate_package.py` | Validator PASS with new checks |
| Tests had no anti-duplication assertion | Added `test_canonical_skill_bodies_are_not_hollow_stubs` to `test_scenarios.py` | 23 tests PASS (was 22) |
| `SECURITY.md` was 3 lines | Expanded to 54 lines with threat model, trust boundaries, non-negotiable controls, and repository-level notes | File content verified |
| Manifest/checksums stale after edits | Regenerated `FILE-MANIFEST.json` and `SHA256SUMS` | Validator integrity PASS |

### v2.1.0 skill body depth evidence

| Skill | Lines | Chars | Sections |
|---|---|---|---|
| agent-reach | 50 | 2,630 | 7/7 |
| api-contract-design | 59 | 3,209 | 7/7 |
| architecture-design | 70 | 4,037 | 7/7 |
| change-management | 47 | 2,652 | 7/7 |
| code-review | 65 | 3,529 | 7/7 |
| context-economy | 57 | 3,028 | 7/7 |
| database-analysis | 67 | 4,043 | 7/7 |
| diagnosing-bugs | 73 | 4,037 | 7/7 |
| documentation-handover | 65 | 3,615 | 7/7 |
| domain-modeling | 60 | 3,657 | 7/7 |
| nfr-review | 53 | 3,450 | 7/7 |
| process-analysis | 49 | 3,109 | 7/7 |
| project-planning | 59 | 3,364 | 7/7 |
| requirements-analysis | 52 | 3,482 | 7/7 |
| risk-management | 55 | 3,451 | 7/7 |
| security-review | 59 | 3,645 | 7/7 |
| skill-authoring | 60 | 3,279 | 7/7 |
| system-analysis | 57 | 3,341 | 7/7 |
| tdd | 69 | 3,685 | 7/7 |
| test-strategy | 58 | 3,368 | 7/7 |
| video-intelligence | 63 | 3,140 | 7/7 |
| **Total** | **1,247** | **71,751** | — |
| **Average** | **59** | **3,416** | **7/7** |

### Updated risk register

| ID | Risk | v2.0 Rating | v2.1 Rating | Change rationale |
|---|---|---|---|---|
| R-03 | User expects restored 63 original skill bodies | High | Medium | 21 canonical skills are now fully authored with actionable procedures; remaining 42 remain inventory-only as disclosed |
| R-10 (new) | Skill bodies regress to hollow stubs | — | Low | Validator depth check + anti-duplication test prevent silent hollowing |

## Acceptance statement

**Package static and fixture acceptance: PASS.**
**Skill body depth and anti-duplication: PASS (21/21 skills, 23 tests).**
**Security documentation: PASS (expanded threat model).**
**Agent behavior acceptance: NOT RUN.**
**Host/runtime compatibility: NOT RUN.**
**Full original 63-skill restoration: OUT OF SCOPE / SOURCE NOT AVAILABLE.**
