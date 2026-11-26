# Release Status — 2.3.1

## Verdict
**2.3.1 remediation package: sandbox checks passed for the remediated operational defects; not live production-certified. See [remediation report](PRODUCTION-READINESS-REMEDIATION-2.3.1.md).

**PARTIAL — static package and skill-routing certification only.** The 22 canonical portable skills, source-backed historical parity map, deterministic skill resolver and regression tests are present. Live model classification, host discovery, host permissions, persistent memory and delegation remain unverified.

## 2.3.0 baseline

## What changed in 2.3.0
- Added the deterministic Skill Intelligence & Orchestration Layer.
- Added explicit intent, specialist and support roles with one-primary ownership.
- Retained 18 low-level resolver fixtures and expanded natural-language routing coverage to all 30 primary intents.
- Audited all 63 historical skill names against source files in the uploaded archive.
- Corrected the prior inaccurate claim that 42 of 63 historical bodies were unavailable.
- Consolidated DBA specialist procedures into the canonical `database-analysis` skill.
- Added explicit task intents for all natural-language route fixtures and made each fixture execute through the same deterministic resolver.
- Corrected research routing so `web-research` owns external research; `agent-reach` is not loaded by default.
- Removed default DBA loading from generic release routing; DBA is selected only when database changes are evidenced.
- Enforced bounded loading: one primary, at most three specialists, at most two support skills, six unique skills maximum.
- Added explicit reporting of redundant selections suppressed by primary/specialist precedence.
- Added catalog schema, path-containment and adapter-pointer validation.
- Expanded adversarial prompt-injection/approval fixtures to 16 cases and added a live security evaluation protocol with hard-failure conditions.
- 2.3.0 removed the duplicate nested Godmode payload; 2.3.1 moved the remaining canonical payload outside active host discovery and excluded it from production release archives.
- Added a high-risk/non-default Godmode quarantine in root Claude/Codex entry points in 2.3.0; 2.3.1 adds technical path isolation and tests.
- Adapted `SOUL.md` to the user's shared engineering soul while keeping `AGENT.md` as operating authority.
- Cleaned release packaging and regenerated manifest/checksums.

## Evidence
- Portable package validator: see `release/TEST-RESULTS.txt`.
- Portable regression suites: see `release/TEST-RESULTS.txt`; includes resolver limit, catalog-integrity and route-to-resolver parity tests.
- Portable regression suite: 61 tests.
- Natural-language classification/resolver parity: 30 cases; explicit low-level resolver fixtures: 18 cases.
- Classification evaluator was tested with synthetic outputs only; no model classification score exists yet.
- ZIP CRC and clean extraction: recorded in release test results.

## Not certified
- Live semantic classification by an LLM.
- Claude/Codex/Hermes or other host instruction/skill discovery.
- Runtime tool permission enforcement or sandbox behavior.
- Real project-memory persistence, multi-agent delegation or independent QA.
- Two absent historical source bodies.

A passing deterministic resolver test proves that explicit selections are validated and ordered. It does not prove the model selected the correct intent.


## 2.3.1 operational remediation
- Bash scripts normalized to LF and syntax-checked.
- First-write reminder hook no longer emits a permission decision.
- Runtime evidence statuses explicitly describe caller-supplied claims, not independent attestation; mind-map authorization is separate.
- Node dependencies are lockfile-pinned; Python document libraries install into `.venv` from `requirements-docs.txt`.
- Backup archives are hash-manifested and verified before retention pruning.
- Godmode is stored outside active skill roots and omitted from production release archives.
- Local operator/client memory is excluded from release artifacts; stale memory is marked as such.
- The release packager verifies archive CRC, manifest hashes, and SHA-256.
