# Changelog

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
