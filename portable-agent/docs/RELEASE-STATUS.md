# Release Status — 2.1.0

## Verdict
**PARTIAL.** All 21 canonical skills are now fully authored with actionable procedures (average 59 lines, 3,416 chars, 7/7 sections each). Depth-checking validation and anti-duplication regression tests added. Security documentation expanded. Package validation and 23 deterministic scenario tests pass. No live host/model smoke test ran. No host is runtime-certified.

## What changed in 2.1.0
- **21 canonical skills authored to full depth:** Each skill file now contains Purpose, When to use, Prerequisites, numbered Procedure (actionable steps), Output contract, Safety/approval gates, and Verification sections. Previously 19/21 were 2-line registry-description copies.
- **Validator hardened:** `validate_package.py` now checks skill body depth (min 10 lines, min 500 chars), required sections (Purpose, Procedure, Output), and anti-duplication (body must not be a subset of its REGISTRY.md description).
- **New test:** `test_canonical_skill_bodies_are_not_hollow_stubs` prevents regression to hollow skills.
- **Security doc expanded:** `SECURITY.md` now includes threat model, trust boundaries, non-negotiable safety controls, and repository-level notes (54 lines, from 3).
- **Manifest and checksums regenerated** to reflect all changes.

## Core-only portability

This repository is intended to work without Hermes-specific runtime services: the portable core is Markdown plus the host's ordinary file-reading capability. Browser/search, persistent memory, hooks, MCP, delegation, model-provider integrations and write tools are optional and must be verified before use. Missing capability is reported honestly; analysis-only remains read-only.

## Current support evidence

- **Package/static acceptance:** PASS — 109 manifest entries; 21 canonical skills (all ≥47 lines, 7/7 sections); 16 routes; 63 legacy inventory entries; 23 deterministic scenario tests, compilation and integrity validation pass.
- **Skill body depth:** PASS — all 21 skills pass depth, section, and anti-duplication checks. Total: 1,247 lines / 71,751 chars across all skills.
- **Security documentation:** PASS — expanded with threat model and trust boundaries.
- **Host installation/discovery:** UNTESTED — Claude Code CLI 2.1.317 and Codex CLI 0.154.0 docs/help inspected only; VS Code Copilot/Claude integration not identified or exercised.
- **Live host/model behavioral evaluation:** NOT RUN. No host is runtime-certified.

- Any other host/model: manual explicit loading only; compatibility unknown.

## Not verified
- Live model behavior or prompt compliance.
- Host auto-discovery or invocation in any runtime, including Claude Code, Codex, Hermes, or VS Code agent harnesses.
- External integrations, tool availability, multi-agent delegation, real project task execution.
- Restoration of original historical skill bodies (42 of 63 remain inventory-only).

## Release readiness
Use explicit manual loading of root `AGENT.md` unless discovery has been confirmed in the actual host. Do not infer successful discovery from the presence of `AGENTS.md` or documentation. Before claiming runtime-validated support, run a clean host-specific installation smoke test and live evaluation on critical scenarios: new project, resume/checkpoint, bug RCA, approval denial, analysis-only, release gate, and scope change. Static test success is not runtime certification.
