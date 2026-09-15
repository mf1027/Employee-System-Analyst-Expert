---
name: ollama-agent-runtime
description: Use when a Claude or Codex task involves Ollama, Soup, Ponytail, repository skill discovery, MYPS readiness, or synchronized mind-map evidence.
---

# Ollama Agent Runtime

This is the cross-agent preflight and completion contract for Ollama-backed Employee sessions. Ollama
provides model inference only. Claude Code and Codex independently provide skill loading, repository
tools, permissions, hooks, and agent loops.

## Required sequence

1. Identify the active host: Claude Code or Codex. Never infer the other host's plugin or hook state.
2. Resolve `MYPS_VAULT_ROOT`. Prefer the operator's explicit value; otherwise use the documented
   sibling vault only when it exists. If the vault cannot be resolved, mark mind-map sync
   `UNVERIFIED` and do not claim synchronized completion.
3. Read the Agent Tooling Mindmap, the current-state dashboard, and the Claude/Codex sync protocol
   before analyzing relevant work. The sync protocol owns the full completion gate; this skill points
   to it and does not duplicate it.
4. Verify the canonical repository files before loading task-specific instructions:
   - `.claude/skills/plan-analysis/SKILL.md`
   - `ai-sa-employee/skills/code-behavior-audit.md`
   - `ai-sa-employee/skills/rollback-readiness-test.md`
   - `ai-sa-employee/skills/ollama-agent-runtime.md`
5. Verify Ollama with the dependency-free repository helper:

   ```text
   node scripts/verify-ollama-runtime.mjs --host "$OLLAMA_HOST" --model "$OLLAMA_MODEL"
   ```

   `OLLAMA_MODEL` is mandatory. Do not auto-pull, auto-select, silently switch, or use cloud-only
   models. Treat unknown context capacity, insufficient context, failed tool calling, a missing
   service, or a missing exact model as `LIMITED` or `UNVERIFIED`.
6. Verify the active host's own tool loop with one harmless read-only repository operation. An Ollama
   API tool-call response alone does not prove that Claude or Codex executed a host tool.
7. For implementation or test-design work, verify that the active host has upstream Ponytail
   installed and trusted. If it is missing, report `Ponytail runtime: UNVERIFIED`; do not claim the
   full runtime contract passed. Apply Ponytail full mode only to simplification choices.
8. Load exactly the one task-specific skill required after this preflight. For backend behavior,
   chain `code-behavior-audit` before `rollback-readiness-test`.
9. Before completion, reconcile prior tooling/runtime entries, run the related-note freshness checker,
   prepare the map update, and write it only when normal documentation authorization exists.

## Status contract

Use exactly one overall status:

- `VERIFIED`: all applicable local model, context, tool-calling, host, Ponytail, skill-path, and
  mind-map gates passed.
- `LIMITED`: the model is usable but context or another capability is below the verified threshold.
- `UNVERIFIED`: a capability is unknown, failed, or not independently verified.
- `BLOCKED`: required approval, artifact, vault, or external prerequisite is unavailable.

Never convert a failed gate into a successful status with prose. A runtime status does not establish a
MYPS readiness verdict. Only `rollback-readiness-test` owns `Internal-ready`, `API-ready`,
`Deployment-ready`, `GO`, `GO WITH CONDITIONS`, and `NO-GO`.

## Soup boundary

Soup is not part of ordinary runtime execution. Mark it `Not applicable` for normal analysis,
implementation, and readiness tasks. Invoke `soup-model-preparation` only when the operator explicitly
requests model preparation. That skill checks global Soup first, then the verified repo-local
environment; it never trains, exports, deploys, or replaces a model without approval.

## Required completion block

```text
Agent runtime sync:
- Ollama host:
- Ollama model:
- Local model verified:
- Tool calling verified:
- Context capacity:
- Active host: Claude / Codex
- Ponytail runtime:
- Soup runtime:
- Canonical skill paths:
- Mind-map sync:
- Overall status: VERIFIED / LIMITED / UNVERIFIED / BLOCKED
```

For readiness work, also include the rollback skill's `Ponytail discipline` block and its complete
evidence-based readiness output. Missing API, rollback, integration, negative-case, scope, or mind-map
evidence cannot support “100% working,” “fully ready,” or unconditional `GO`.
