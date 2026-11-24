# Employee System Analysis Expert — Portable Agent Package

A host-neutral operating contract and workflow library for systems analysis, requirements, architecture, planning, database analysis, engineering delivery, QA, security, research, review, and coordination. It augments an existing employee organization and project process; it does not replace existing roles or create a competing memory system.

## Canonical source

Root [`AGENT.md`](AGENT.md) is the **single source of truth** for behavior, safety and task routing. Host instruction files are small bootstrap pointers to that file; canonical skill procedures live in [`skills/`](skills/) and are routed by [`skills/REGISTRY.md`](skills/REGISTRY.md). Do not maintain separate copies of policy in host adapters.

This package does not require Hermes, plugins, a particular model provider, MCP, browser access, hooks, persistent memory, or delegation. Those are optional host capabilities. Verify availability and permission before relying on them; use a safe manual fallback and report the limitation when unavailable. Host sandbox and approval controls remain in force.

## Quick start

1. Extract or clone this package and keep its relative structure intact.
2. Use a host setup in [`docs/INSTALLATION.md`](docs/INSTALLATION.md), or the generic manual setup below.
3. Ensure the active host reads root `AGENT.md` before every task. Root `AGENTS.md` is the bootstrap pointer; verify its discovery in the actual host rather than assuming it loaded automatically.
4. For each task, route through `AGENT.md`; read only the selected workflow and relevant canonical skill(s).
5. Start with a harmless read-only task and check the host's instruction references/tool activity.

### Generic manual setup

For a host without a verified adapter, open the package root in its agent workspace and explicitly instruct the host to read `AGENT.md` first. Then ask it to follow the task router and load only relevant files from `workflows/` and `skills/REGISTRY.md`. This is a portable manual fallback, not proof of automatic discovery or host certification.

## Host support status

Official host documentation was checked on 2026-11-24. Local CLI versions were observed, but no authenticated model/runtime smoke test was run.

| Host/runtime | Setup approach | Evidence |
|---|---|---|
| Claude Code CLI 2.1.317 | Run `claude --version` in the tested environment. Root `AGENTS.md` is a bootstrap pointer; check `CLAUDE.md` precedence and active project-instruction settings, then confirm loaded files or explicitly load `AGENT.md`. | Docs and `--help` inspected; runtime discovery and model behavior untested. |
| Claude Code in VS Code | Use only the Claude Code harness; don't infer it from selecting a Claude model in another harness. | Official docs reviewed; installed extension/version unverified. |
| VS Code GitHub Copilot | Root `AGENTS.md` where supported by selected harness; check its instruction references/settings. | Official docs reviewed; Copilot harness/version untested. |
| Codex CLI 0.154.0 | Root `AGENTS.md` bootstrap; use canonical skills directly if thin pointers aren't discovered as skills. | Docs and `--help` inspected; runtime discovery and model behavior untested. |
| Other hosts | Explicitly load `AGENT.md`, then route through registry and canonical files. | Manual fallback only. |

No target is runtime-certified; see `docs/INSTALLATION.md` for discovery caveats and official reference links.

## Contents

- `AGENT.md`: canonical operating contract.
- `SOUL.md`: optional persona framing subordinate to the contract.
- `skills/`: 21 portable core skill bodies and registry; inventory-only historical names are not restored procedures.
- `workflows/`: task routing, analysis, implementation gates, review, release and continuation procedures.
- `evals/`: routing, scenario and adversarial fixtures.
- `tools/`: standard-library package validation and deterministic tests.
- `adapters/`: host setup notes and skill pointers; discovery must be verified on the actual runtime.

## Validate the package

From the package root:

```text
python tools/validate_package.py
python tools/test_scenarios.py
python -m compileall -q tools
```

These offline checks validate package structure, links, manifests, routing fixtures and static contracts. They do not invoke a model, prove live host discovery, guarantee instruction compliance, or certify host integration. The archive check is a separate manual packaging step. See [`docs/VALIDATION-REPORT.md`](docs/VALIDATION-REPORT.md).

## Source boundary

This is a reconstructed portable core. It does not restore the unavailable original historical skill bodies, scripts, templates, assets or legacy runtime. See [`docs/SOURCE-BOUNDARY.md`](docs/SOURCE-BOUNDARY.md).
