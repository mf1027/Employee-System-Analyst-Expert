# Validation Report — 2.3.1

**Validation date:** 2026-11-26
**Scope:** v2.3.0 source baseline, independent production-readiness review, targeted 2.3.1 remediation, sandbox tests and fresh release extraction.

## Parent repository regression suite

- `npm test`: **PASS — 73 Node tests, 0 failed**.
- `python -m unittest discover -s scripts -p 'test_backup.py' -v`: **PASS — 4 tests**.
- Bash syntax: **PASS** for every packaged `.sh` script.
- Hook simulation: **PASS** — reminder output contains no permission decision; read marker sanitizes session IDs.
- Backup lifecycle: **PASS** — manifest/hash/CRC verification, disposable restore, successful retention and failed-verification preservation.
- Release packager: **PASS** — local/private data and quarantined red-team payload excluded; ZIP manifest and hashes verified.

## Portable-agent validation

- `python tools/validate_package.py`: **PASS** — 22 canonical skills, 30 natural-language routes, 63 historical parity entries, adapter pointers, fixtures, path containment, manifest and checksums.
- `python -m unittest discover -s tools -p 'test_*.py' -v`: **PASS — 61 tests**.
- `python -m compileall -q tools`: **PASS**.
- Route-to-resolver parity: **PASS — 30/30**.
- Adversarial fixture inventory: **16 cases structurally validated**; no live model execution.

## 2.3.1 remediation evidence

- Shell files normalized to LF; syntax gate added to default tests.
- PreToolUse memory reminder no longer returns `permissionDecision: allow`.
- Runtime status now reports `CLAIMS-CONSISTENT` at most; caller-supplied claims are not represented as independent `VERIFIED`. Mind-map projection authorization is a separate field.
- Node install is lockfile-driven (`npm ci`); exact Python package versions are installed only into `.venv`.
- Backup archives carry per-file SHA-256 manifests and are verified before retention pruning.
- Godmode moved outside active host skill-discovery roots and is omitted from production release archives.
- Local operator/client memory and other private workspace data are excluded from production release archives; the stale working-memory snapshot is marked and not distributed.

## Dependency-installation limitation

- `npm ci --offline` could not complete because `commander@14.0.3` was not in the sandbox npm cache (`ENOTCACHED`) and registry access was unavailable.
- Python dependency installation into a clean venv was not run because package registry access was unavailable. Versions are exact-pinned; wheel hashes are not yet locked.

- Fresh release ZIP: **523 packaged files + release manifest; 524 ZIP members**. CRC, manifest, SHA-256, credential-pattern scan, and fresh extraction: **PASS**. Post-extraction suites: 73 Node + 4 backup Python + 61 portable Python tests; portable validator: PASS.

## Not tested / not certified

- No live LLM was invoked to classify natural-language tasks or complete realistic analyst workflows.
- No Claude Code, Codex, Hermes or VS Code host was used to certify instruction/skill discovery or first-write permission prompts.
- Host permissions, sandboxing, prompt-injection resilience, actual Obsidian persistence, real delegation, Windows PowerShell behavior, Git remote history, database access and deployment boundaries remain unverified.
- Passing instruction/fixture tests do not prove model obedience or prevent host-level tool execution.

See [the 2.3.1 remediation report](PRODUCTION-READINESS-REMEDIATION-2.3.1.md) for the full RCA/GAP reconciliation and remaining owner gates.
