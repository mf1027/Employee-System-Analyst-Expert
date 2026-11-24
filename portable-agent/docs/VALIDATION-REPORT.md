# Validation report — reconstructed core


- `python tools/validate_package.py`: PASS (109 manifest entries, 21 canonical skills, 16 routes, 63 legacy entries).
- `python tools/test_scenarios.py`: PASS (21 tests).
- `python -m compileall -q tools`: PASS.
- Fresh ZIP archive extraction followed by `python tools/validate_package.py`: PASS.

These are offline structural/contract checks. They do not invoke a model, prove live host discovery, guarantee instruction compliance, or certify host integration.

Static package validation checks canonical skill existence, registry links, adapter pointers, inventory count, package hashes, format hygiene, links and fixture structure. Scenario tests exercise deterministic contract/fixture structure, including optional capability fallback documentation and host support claim boundaries. They do not measure model behavior.

Official host documentation was reviewed for Claude Code, VS Code GitHub Copilot and Codex. Local CLI versions observed: Claude Code 2.1.317 and Codex 0.154.0; VS Code was present but Copilot/Claude extensions were not identified or tested. No host/runtime/model smoke test was run. Root `AGENTS.md` is a bootstrap pointer to root `AGENT.md`; live host discovery remains untested, so use explicit manual loading unless discovery is confirmed in the active host.

## Validation boundaries

Deterministic tests and static validation do not invoke a language model, prove live host discovery, guarantee instruction compliance, or certify host integration. Host-specific discovery, canonical skill invocation and behavior remain untested. Do not claim runtime support based only on documentation, executable presence or static tests.

## Not tested

Live discovery/invocation in Claude Code CLI or extension, Codex, VS Code GitHub Copilot, Hermes, model routing outcomes, persistence/session resume, and external tool capabilities were not tested. Fresh archive extraction was tested; live host setup from the archive was not.
