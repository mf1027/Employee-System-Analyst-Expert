---
name: ollama-agent-runtime
description: Use when a Claude or Codex task involves Ollama, Soup, Ponytail, repository skill discovery, MYPS readiness, or synchronized mind-map evidence.
---

# Ollama Agent Runtime

This is the cross-agent preflight and completion contract for native and Ollama-backed Employee
sessions. Ollama provides model inference only. Claude Code and Codex independently provide skill
loading, repository tools, permissions, hooks, and agent loops.

## Required sequence

1. Identify the active host: Claude Code or Codex, and the inference provider: native or Ollama.
   Treat Claude/native, Claude/Ollama, Codex/native, and Codex/Ollama as separate runtime targets.
   Never infer one target from another.
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
5. For Ollama-backed sessions, verify Ollama with the dependency-free repository helper:

   ```text
   node scripts/verify-ollama-runtime.mjs --host "$OLLAMA_HOST" --model "$OLLAMA_MODEL"
   ```

   `OLLAMA_MODEL` is mandatory. Do not auto-pull, auto-select, silently switch, or use cloud-only
   models. Treat unknown context capacity, insufficient context, failed tool calling, a missing
   service, or a missing exact model as `LIMITED` or `UNVERIFIED`.
6. For native or Ollama-backed sessions, verify the active host's own tool loop with one harmless
   read-only repository operation. An Ollama API tool-call response alone does not prove that Claude
   or Codex executed a host tool.
7. For implementation or test-design work, independently observe that the active host has upstream
   Ponytail installed, its hook trust accepted, and full mode applied. Installation or a project-trust
   record alone is not that evidence. If any part is missing, report `Ponytail runtime: UNVERIFIED`;
   do not claim the full runtime contract passed. Apply Ponytail full mode only to simplification
   choices.
8. Load exactly the one task-specific skill required after this preflight. For backend behavior,
   chain `code-behavior-audit` before `rollback-readiness-test`.
9. Before any ledger write, create a safe evidence file outside tracked source. It must identify the
   same host/provider/model and contain the raw Ollama verifier result (for Ollama), one completed
   read-only host tool, and Ponytail installed/hook-trusted/full-mode evidence. Do not include prompts,
   tool input/output, credentials, or transcripts. Validate it first without side effects:

   ```text
   node scripts/runtime-sync.mjs --postflight --dry-run --host <claude|codex> \
     --provider <native|ollama> --model <model-if-ollama> --evidence <safe-evidence.json>
   ```

   The status is derived from caller-supplied claims; `--status VERIFIED` is rejected. Even a
   complete matching evidence JSON produces `CLAIMS-CONSISTENT`, not independent `VERIFIED`.
   A dry-run validates the safe evidence shape and matching gates, but it is not a live host smoke result. Likewise,
   `runtime-sync.mjs --verify` may report `VAULT_READY` only; it checks vault artifacts, not runtime
   behavior. After normal documentation write authorization, record and project the same validated
   evidence explicitly:

   ```text
   node scripts/runtime-sync.mjs --postflight --authorize-mindmap --host <claude|codex> \
     --provider <native|ollama> --model <model-if-ollama> --evidence <safe-evidence.json>
   ```

   Hook mode appends unverified lifecycle observations only; Claude's `session_end` phase is passive
   telemetry, not this explicit postflight. An explicit postflight updates the mind-map only with
   `--authorize-mindmap`; without it the map is byte-for-byte unchanged.
10. Mind-map projection authorization is independent of runtime status. A complete claim set may
    be recorded without projection authorization; an authorized projection may also record an
    UNVERIFIED/LIMITED result. Neither state grants tool permissions or certifies the host.

## After model selection

When the operator chooses an installed Ollama model, use that exact model for the entire smoke run:

```text
set OLLAMA_HOST=http://localhost:11434
set OLLAMA_MODEL=<explicit-installed-model>
set RUNTIME_SYNC_PROVIDER=ollama
node scripts/verify-ollama-runtime.mjs --host "$OLLAMA_HOST" --model "$OLLAMA_MODEL"
ollama launch <claude|codex> --model "$OLLAMA_MODEL"
```

The fresh host session must read this skill, read the skill index, confirm Ponytail full mode, and
complete one harmless read-only repository tool action. Only then create the safe evidence file and
run the dry-run/postflight commands above. Do not invoke Soup in this flow unless the task is
explicitly about Soup model preparation.

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

## Four-mode event identity

Every ledger event records `host`, `provider`, `launch_mode`, `model`, skill paths, Ponytail status,
Soup status, and overall status. For Ollama launches, set `RUNTIME_SYNC_PROVIDER=ollama` before
starting the host; native sessions default to `native`. If the provider cannot be identified, report
`UNVERIFIED` instead of guessing.

Claude project lifecycle hooks are declared in `.claude/settings.json`. Codex project-hook support
is build-dependent and must be verified against the installed CLI; no global hook file is assumed.
If Codex does not expose project hooks, use the explicit preflight/postflight commands above.
Hook presence is not hook trust, and hook trust is not host-tool verification; each must be checked
independently.

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
- Runtime claim status: CLAIMS-CONSISTENT / LIMITED / UNVERIFIED
- Mind-map projection: AUTHORIZED / NOT_AUTHORIZED
```

For readiness work, also include the rollback skill's `Ponytail discipline` block and its complete
evidence-based readiness output. Missing API, rollback, integration, negative-case, scope, or mind-map
evidence cannot support “100% working,” “fully ready,” or unconditional `GO`.
