# Changelog

## 2.3.1 — Operational security and release hardening
- Fixed LF line endings for all packaged Bash scripts and added syntax checks to the default test run.
- Removed the memory reminder hook's `permissionDecision: allow`; it now emits context only and leaves approval to the host.
- Changed runtime evidence reporting to `CLAIMS-CONSISTENT`/`CLAIMED-VERIFIED`; caller-supplied JSON is no longer represented as independent verification.
- Separated runtime claim status from mind-map projection authorization.
- Switched Node installation to exact lockfile-driven `npm ci`; removed unused/disabled claude-mem and context-mode npm dependencies.
- Added pinned project-local Python document dependencies and removed global pip installs.
- Reworked backup creation to include a hash manifest, verify archive contents before commit, and apply retention only after successful verification.
- Moved Godmode payload outside active host skill-discovery roots and excluded it from production release archives.
- Marked the historical working-memory snapshot stale, reconciled session-start guidance with canonical Obsidian/project memory, and excluded local operator/client memory from production releases.
- Added a deterministic privacy-filtered release packager and backup/packaging regression tests.
- Live host/model/permission certification remains an owner-environment gate.

## 2.3.0 — Routing consistency, bounded selection and decision evidence
- Corrected natural-language route fixtures that disagreed with the skill ownership catalog (research and generic release were the notable cases).
- Added explicit primary intents for all 30 natural-language route classes and made fixture-to-resolver parity executable.
- Enforced one primary, max three specialists, max two support skills and six unique skills total; overflow fails closed.
- Required a structured decision record containing primary intent/deliverable/evidence, specialist evidence, support-output need, excluded candidates and uncertainty.
- Added full catalog validation, package-path containment checks, selected adapter pointer checks and redundant-selection reporting.
- Added an offline evaluator for actual model-produced classification JSON plus a documented live evaluation protocol.
- Expanded adversarial coverage to 16 cases and documented the live security/approval hard gates.
- Quarantined the legacy Godmode/jailbreak skill from default employee routing in both root Claude and Codex entry points; added four parent-repository regression checks.
- Added regression coverage for selection limits, malformed catalogs, path escape, missing/mismatched evidence, route parity and evaluator behavior.
- Updated release and validation documentation; live model/host certification remains pending.


## 2.2.0 — Skill intelligence, conflict resolution and parity audit
- Added machine-readable skill-intelligence catalog and deterministic resolver.
- Added explicit primary/specialist/support ownership and fail-closed selection.
- Added 18 skill-routing fixtures and resolver regression tests.
- Audited 63 historical names against the actual archive; identified 2 missing source bodies.
- Consolidated specialist DBA procedures into `database-analysis`.
- Converted duplicate nested Godmode content to a pointer to the canonical top-level path.
- Updated SOUL, source-boundary, inventory and release documentation.
- Cleaned ZIP metadata/cache artifacts and regenerated manifest/checksums.


## 2.1.0 — Skill body depth authoring and validation hardening
- Authored full procedure bodies for all 21 canonical skills: Purpose, When to use, Prerequisites, numbered Procedure, Output contract, Safety/approval gates, Verification. Average: 59 lines, 3,416 chars per skill.
- Added depth-checking validation to `validate_package.py`: minimum line/char thresholds, required section checks, anti-duplication guard (skill body must not be a copy of its registry description).
- Added `test_canonical_skill_bodies_are_not_hollow_stubs` regression test (23 tests total, up from 22).
- Expanded `docs/SECURITY.md` from 3 lines to 54 lines with threat model, trust boundaries, non-negotiable controls, and repository-level notes.
- Updated all release documentation: PRODUCTION-READINESS-REVIEW (v2.1.0 remediation section), RELEASE-STATUS, VALIDATION-REPORT.
- Regenerated FILE-MANIFEST.json and SHA256SUMS.

## 2.0.0 — Production-readiness remediation
- Strengthened canonical agent operating contract and route-by-intent.
- Added explicit workflows for feature/change, research, analysis-only, scope-change, blocked tasks, skill lifecycle, context optimization, release/deployment, multi-agent coordination, state machine, continuation contract and routing.
- Connected routing and scenario fixtures; expanded structural regression suite and adversarial fixture coverage.
- Added complete package manifest generation and integrity checks.
- Clarified runtime/LLM evaluation boundaries; no host compatibility claims.

## 1.0.0 — Reconstructed portable core
- 21 core skills and historical 63-skill inventory.
