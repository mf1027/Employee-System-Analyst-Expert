# Agent-local usage

`plan-analysis` is maintained only in this employee-agent repository at `.claude/skills/plan-analysis/`. Run it while the Employee System Analyst Expert workspace is active; do not install a global copy or add a wrapper or skill files to client application repositories.

## Invocation model

The employee agent dispatches the skill for the active client/project. A request may include a client/project identity and `live` or `bundle` mode.

- Without an explicit mode, use `live` mode.
- Without client context, continue live analysis only when the context is unnecessary. Before a bundle write, resolve the client/project from the active task or ask one question.
- Treat a path under `memory/clients/<client>/<project>/` as authoritative client context only after confirming that it contains the expected project record.

## Persistence

Bundle mode writes only after explicit authorization to:

```text
memory/clients/<client>/<project>/deliverables/documents/plan-analysis/<slug>/
```

Use a lowercase hyphenated `<slug>`. `run.json` records the relative artifact path rather than a machine-specific absolute path.

If writing is unavailable or declined, return the planned artifacts in chat and set `persistence` to `CHAT_ONLY`. Do not write to a client application repository, the agent-root `deliverables/` fallback, a global skill directory, or a temporary path as a substitute for the requested bundle.

## Validation

The agent supports Node 20 or later. Validate a persisted bundle with:

```text
node .claude/skills/plan-analysis/scripts/validate-artifacts.mjs <bundle-directory>
```

The validator is intentionally dependency-free and checks the v2 contract, required headings, completion gates, review coverage, secrets in both Markdown and JSON artifacts, and that a persistent bundle is actually located at its recorded client-deliverables path.
