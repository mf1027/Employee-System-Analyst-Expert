# Release Status — 2.0.0

## Verdict
**PARTIAL.** Host install documentation and core-only fallback guidance are updated. Package validation and 21 deterministic scenario tests, compilation, and fresh archive validation pass. Claude Code CLI 2.1.317 and Codex CLI 0.154.0 docs/help were inspected; no live host/model smoke test ran. No host is runtime-certified. Independent review found no critical issues; its reported test count was stale (16 versus current 21).

## Core-only portability

This repository is intended to work without Hermes-specific runtime services: the portable core is Markdown plus the host's ordinary file-reading capability. Browser/search, persistent memory, hooks, MCP, delegation, model-provider integrations and write tools are optional and must be verified before use. Missing capability is reported honestly; analysis-only remains read-only.

## Current support evidence

- **Package/static acceptance:** PASS — 109 manifest entries; 21 canonical skills; 16 routes; 63 legacy inventory entries; 21 deterministic scenario tests, compilation and fresh archive extraction pass.
- **Host installation/discovery:** UNTESTED — Claude Code CLI 2.1.317 and Codex CLI 0.154.0 docs/help inspected only; VS Code Copilot/Claude integration not identified or exercised.
- **Live host/model behavioral evaluation:** NOT RUN. No host is runtime-certified.

- Any other host/model: manual explicit loading only; compatibility unknown.

## Not verified
- Live model behavior or prompt compliance.
- Host auto-discovery or invocation in any runtime, including Claude Code, Codex, Hermes, or VS Code agent harnesses.
- External integrations, tool availability, multi-agent delegation, real project task execution.
- Restoration of original historical skill bodies.

## Release readiness
Use explicit manual loading of root `AGENT.md` unless discovery has been confirmed in the actual host. Do not infer successful discovery from the presence of `AGENTS.md` or documentation. Before claiming runtime-validated support, run a clean host-specific installation smoke test and live evaluation on critical scenarios: new project, resume/checkpoint, bug RCA, approval denial, analysis-only, release gate, and scope change. Static test success is not runtime certification.
