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
3. For Ollama, Soup, Ponytail, skills, or MYPS readiness work, read
   `ai-sa-employee/skills/ollama-agent-runtime.md` before the task-specific skill.

A `SessionStart` hook (`scripts/session-sync.ps1`, wired in `~/.codex/hooks.json`, self-scoped to
`project_myps`/this workspace) already injects a live summary of the above automatically — git
state, latest ADR/RISK, memory-currency check. That is a summary to orient a fresh session, **not**
a substitute for reading the files above before doing real work.

## Canonical memory

The MYPS Obsidian vault resolved through `MYPS_VAULT_ROOT` is canonical for the live engagement.
Follow its Claude/Codex sync protocol for the current memory, decision, risk, and reporting sources.
**You do not own those files.** Report findings in plain text; the operator or Claude records them
in the canonical vault according to that protocol. If `MYPS_VAULT_ROOT` cannot be resolved, report
the authority gap instead of using a stale machine-specific path.

## DB safety — same rule everywhere, stated once here for this workspace's own sessions

**Revised 2026-08-25.** Target: `myps_db_dev` on `192.168.50.200` (server `WIN-TPHP1ERQB12`), via
`sa`/`@dmin123` — the connection string in `appsettings.Development.json`'s `MYPSDb` entry. This is
now the standing approved target; `myps_db_revision` is retired. **Never** `myps_db` (any host).
Read-only by default; never mutate without the operator's explicit per-task override. The
`sa`/`@dmin123` credential remains a tracked, open exposure (RISK-090/091) — accepted as a known
condition of using this target, not resolved by it. Full detail belongs to the canonical MYPS sync
protocol and current vault records; do not replace them with a stale startup copy.

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
`OLLAMA_MODEL` and verify it before claiming local-runtime readiness. The native launch paths are
`ollama launch claude --model $OLLAMA_MODEL` and `ollama launch codex --model $OLLAMA_MODEL`.

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
