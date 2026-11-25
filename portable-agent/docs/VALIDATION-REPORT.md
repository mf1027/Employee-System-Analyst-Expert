# Validation report — reconstructed core

## v2.1.0 validation results (2026-11-25)

- `python tools/validate_package.py`: PASS (109 manifest entries, 21 canonical skills with depth/section/anti-duplication checks, 16 routes, 63 legacy entries).
- `python -m unittest tools.test_scenarios -v`: PASS (23 tests, including `test_canonical_skill_bodies_are_not_hollow_stubs`).
- `python -m compileall -q tools`: PASS.

### Skill body depth verification

All 21 canonical skills pass new depth checks:
- Minimum depth: 47 lines, 2,630 chars (agent-reach).
- Maximum depth: 73 lines, 4,043 chars (diagnosing-bugs/database-analysis).
- Average: 59 lines, 3,416 chars per skill.
- All 21 skills have 7/7 required sections (Purpose, When to use, Prerequisites, Procedure, Output contract, Safety/approval gates, Verification).
- No skill body is a duplicate of its REGISTRY.md description (anti-duplication check PASS).

### Security documentation

`docs/SECURITY.md` expanded from 3 lines to 54 lines:
- Threat model with 4 trust boundaries.
- 7 threat categories with specific AGENT.md section references.
- 8 non-negotiable safety controls.
- Repository-level security notes.

## v2.0.0 validation results (prior)

- `python tools/validate_package.py`: PASS (109 manifest entries, 21 canonical skills, 16 routes, 63 legacy entries).
- `python tools/test_scenarios.py`: PASS (22 tests).
- `python -m compileall -q tools`: PASS.
- Fresh ZIP archive extraction followed by `python tools/validate_package.py`: PASS.

## Validation boundaries

These are offline structural/contract checks. They do not invoke a model, prove live host discovery, guarantee instruction compliance, or certify host integration.

Static package validation checks canonical skill existence, registry links, adapter pointers, inventory count, package hashes, format hygiene, links and fixture structure. Scenario tests exercise deterministic contract/fixture structure, including optional capability fallback documentation, host support claim boundaries, and skill body depth/anti-duplication. They do not measure model behavior.

Official host documentation was reviewed for Claude Code, VS Code GitHub Copilot and Codex. Local CLI versions observed: Claude Code 2.1.317 and Codex 0.154.0; VS Code was present but Copilot/Claude extensions were not identified or tested. No host/runtime/model smoke test was run. Root `AGENTS.md` is a bootstrap pointer to root `AGENT.md`; live host discovery remains untested, so use explicit manual loading unless discovery is confirmed in the active host.

## Not tested

Live discovery/invocation in Claude Code CLI or extension, Codex, VS Code GitHub Copilot, Hermes, model routing outcomes, persistence/session resume, and external tool capabilities were not tested. Fresh archive extraction was tested; live host setup from the archive was not.
