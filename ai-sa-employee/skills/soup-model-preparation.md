---
name: soup-model-preparation
description: Use when the operator explicitly requests Soup fine-tuning, post-training, model adaptation, evaluation, or preparation of a model for Ollama.
---

# Soup Model Preparation

This is an explicit, approval-gated model-preparation workflow. It is not an agent runtime, skill
loader, Ponytail implementation, or replacement for Claude Code/Codex.

## Default: plan and verify

Before any expensive or persistent operation:

1. Read and follow `ai-sa-employee/skills/ollama-agent-runtime.md`.
2. Read the Agent Tooling Mindmap and reconcile any prior Soup/Ollama entries.
3. Check global Soup first by looking for a `soup` command and record its version; report duplicate global and
   repo-local installations without removing either one.
4. If global Soup is absent or the version is not `0.75.0`, check the verified archive and the
   repo-local `.venv-soup` environment created by setup.
5. Verify the archive SHA-256 before using it:
   `61AD531DA5C4779E50390B6589202DD1EBA69D93A30156441542DD185C94F029`.
6. Check Python compatibility (Soup 0.75.0 supports Python 3.10–3.12), source-model format,
   dataset provenance, configuration, hardware, disk, and output path.
7. Run `soup advise` before recommending GPU-intensive training.
8. Produce a bounded command plan, compatibility risks, expected outputs, and rollback/removal steps.

Do not run `soup train`, `soup eval`, `soup diagnose`, `soup export`, `soup deploy`, `ollama create`,
model deletion, or model replacement until the operator approves that exact operation, input, output,
and target. Do not store credentials in configs, logs, or repository files.

## Approved preparation flow

When the operator explicitly approves the named operation, use the smallest Soup command that proves
the requested result:

```text
soup train --config <config>
soup eval ...
soup diagnose ...
soup export --model <output> --format gguf ...
ollama create <name> -f <Modelfile>
```

Keep checkpoints, adapters, GGUF files, logs, and manifests under the ignored Soup workspace. Record
only safe metadata: tool version, archive hash, source/output identifiers, command category, checks,
and final status. Do not commit model artifacts or the extracted Soup source.

After Ollama registration, run the Ollama verifier and then separate Claude and Codex host smoke
tests. Soup success does not prove skill discovery, tool execution, permissions, hooks, Ponytail, or
MYPS readiness.

## Output

```text
Soup model preparation:
- Global Soup:
- Repo-local Soup:
- Version/archive verified:
- Python compatibility:
- Training extras:
- Source model:
- Dataset/config:
- Ollama compatibility:
- Approval state:
- Artifacts:
- Status: PLAN_ONLY / VERIFIED / LIMITED / BLOCKED
```

The skill is `PLAN_ONLY` by default. A missing Soup installation blocks this workflow only; it does
not block ordinary Employee skill execution or readiness analysis when Soup is not required.
