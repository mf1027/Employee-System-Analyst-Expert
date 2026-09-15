# Codex entry point — MYPS workspace

This is a thin pointer, not a duplicate of Claude Code's `CLAUDE.md` (which drives a
skill/slash-command architecture Codex doesn't share). Added 2026-08-23/24 (ADR-113) to close a
real gap: Codex had no project-level entry point in this workspace, only the global
`~/.codex/AGENTS.md` (zero-footprint rule for `project_myps` only — it says nothing about how to
work in this workspace itself).

## Read first, every session

1. Resolve `MYPS_VAULT_ROOT` (or the documented sibling Obsidian vault) and read `MYPS/00 - START
   HERE.md`, the current-state dashboard, and `MYPS/20 - Standards & Conventions/Claude + Codex
   Real-Time Sync Protocol.md` — the canonical startup and completion sources.
2. Read applicable project memory and decision records only after confirming their paths exist;
   report missing or conflicting startup sources instead of trusting a stale path.
3. Read `MYPS/01 - Application Architecture/Agent Tooling Mindmap.md` for the shared runtime map.
4. For Ollama, Soup, Ponytail, skills, or MYPS readiness work, read
   `ai-sa-employee/skills/ollama-agent-runtime.md` before the task-specific skill.
5. Read `ai-sa-employee/skills/skills.md` for routing, then read only the one canonical skill
   required by the request. Read `rollback-readiness-test.md` for readiness, `code-behavior-audit.md`
   for behavior tracing, and `soup-model-preparation.md` only for an explicit Soup request.

Claude project lifecycle hooks are declared in `.claude/settings.json`. Codex project-hook support must be verified independently against the installed build; this repository does not assume a global
`~/.codex/hooks.json` or invent an unsupported Codex hook contract. When automatic Codex hooks are
not exposed, follow the runtime skill's evidence flow: run `runtime-sync.mjs --dry-run` first,
then use the matching evidence file for any authorised ledger write. `--authorize-mindmap` is
required in addition to `--postflight` before a mind-map projection. `scripts/session-sync.ps1`
is only a read-only summary and is not synchronization evidence. `runtime-sync.mjs --verify`
reports `VAULT_READY` only: it checks vault artifacts and never establishes a live host, tool,
Ponytail, or Ollama verification result.

## Canonical memory

The MYPS Obsidian vault resolved through `MYPS_VAULT_ROOT` is canonical for the live engagement.
Follow its Claude/Codex sync protocol for the current memory, decision, risk, and reporting sources.
**You do not own those files.** Report findings in plain text; the operator or Claude records them
in the canonical vault according to that protocol. If `MYPS_VAULT_ROOT` cannot be resolved, report
the authority gap instead of using a stale machine-specific path.

## DB safety — same rule everywhere, stated once here for this workspace's own sessions

**Revised 2026-09-16.** Resolve the approved development target from the canonical MYPS sync
protocol and active application configuration. Never copy connection strings or credentials into
agent instructions, reports, commands, or evidence. Read-only by default; never mutate without the
operator's explicit per-task override. Full target and risk detail belongs to the canonical MYPS
security records; do not replace them with a stale startup copy.

## `project_myps` — separate, stricter rule

If you're working in `project_myps` specifically (the backend repo, not this workspace), the
zero-AI-footprint rule applies — see `~/.codex/AGENTS.md` (global) and ADR-107 in `decisions.md`.
It does not apply here; this workspace is where the AI-authored coordination files belong.

## Canonical shared skills for Claude and Codex

When working from this Employee-System-Analyst-Expert repository, use the canonical skill files
under `ai-sa-employee/skills/`:

- Read `ai-sa-employee/skills/rollback-readiness-test.md` for MYPS readiness testing and verdicts.
- Read `ai-sa-employee/skills/ollama-agent-runtime.md` for cross-agent runtime and mind-map
  verification; read `ai-sa-employee/skills/soup-model-preparation.md` only for explicit Soup work.
- Apply the upstream Ponytail plugin in full mode when choosing or simplifying implementation and
  test work, subject to the rollback skill's safety and evidence gates.
- Do not create a duplicate Ponytail copy under `.codex/skills/`.
- The Employee repository owns the MYPS readiness contract; the upstream Ponytail repository owns
  generic minimalism and its runtime plugin.
- Claude and Codex must verify their own runtime/plugin state; never claim identical runtime hooks
  merely because both agents follow the same workflow.

## Ollama-backed execution

Ollama supplies local model inference; Claude Code and Codex remain the agent hosts responsible for
skill discovery, tools, permissions, hooks, and agent loops. Use an explicit installed model through
`OLLAMA_MODEL` and verify it before claiming local-runtime readiness. The native Ollama launch paths
are `RUNTIME_SYNC_PROVIDER=ollama ollama launch claude --model $OLLAMA_MODEL` and
`RUNTIME_SYNC_PROVIDER=ollama ollama launch codex --model $OLLAMA_MODEL`.
Claude/native, Claude/Ollama, Codex/native, and Codex/Ollama are four separate verification targets.

- Read `.claude/skills/plan-analysis/SKILL.md` for repository-local plan-analysis.
- Read `ai-sa-employee/skills/code-behavior-audit.md` for existing-code behavior tracing.
- Read `ai-sa-employee/skills/rollback-readiness-test.md` for the MYPS readiness contract and verdicts.
- Read `ai-sa-employee/skills/ollama-agent-runtime.md` first for relevant runtime, skill, Ponytail,
  Soup, or mind-map work; read `ai-sa-employee/skills/soup-model-preparation.md` only when Soup is
  explicitly requested.
- Apply upstream Ponytail when simplifying implementation or test choices; it never overrides
  readiness, evidence, authentication, rollback, or safety gates.
- Do not copy Ponytail into `.codex/skills/`, and do not copy the global plan-analysis bridge here.
- Verify Claude and Codex independently. Ollama-backed parity means equivalent behavior and evidence,
  not identical Claude/Codex internals or hooks.
