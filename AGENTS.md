# Codex entry point — MYPS workspace

This is a thin pointer, not a duplicate of Claude Code's `CLAUDE.md` (which drives a
skill/slash-command architecture Codex doesn't share). Added 2026-08-23/24 (ADR-113) to close a
real gap: Codex had no project-level entry point in this workspace, only the global
`~/.codex/AGENTS.md` (zero-footprint rule for `project_myps` only — it says nothing about how to
work in this workspace itself).

## Read first, every session

1. `memory/clients/myps/myps-system/CODEX_SYNC_STARTUP.md` — the canonical startup checklist:
   role split, DB safety rules, current Revision-schema authority, "canonical files to read" list.
2. `memory/clients/myps/myps-system/decisions.md` — newest ADR first.
3. `memory/clients/myps/myps-system/risks.md` — newest RISK first.

A `SessionStart` hook (`scripts/session-sync.ps1`, wired in `~/.codex/hooks.json`, self-scoped to
`project_myps`/this workspace) already injects a live summary of the above automatically — git
state, latest ADR/RISK, memory-currency check. That is a summary to orient a fresh session, **not**
a substitute for reading the files above before doing real work.

## Canonical memory

`C:\Users\khen\Documents\ChatGPT\MYPS\memory\clients\myps\myps-system\` is canonical for the whole
MYPS engagement — `decisions.md` (ADR-), `risks.md` (RISK-/ASS-), `requirements.md` (REQ-),
`database.md`, `board.md`. **You do not own these files.** Report findings in plain text; the
operator (or Claude) logs them as `RISK-`/`ADR-` entries — see `CODEX_SYNC_STARTUP.md`'s "How
Codex reports findings" section.

## DB safety — same rule everywhere, stated once here for this workspace's own sessions

**Revised 2026-08-25.** Target: `myps_db_dev` on `192.168.50.200` (server `WIN-TPHP1ERQB12`), via
`sa`/`@dmin123` — the connection string in `appsettings.Development.json`'s `MYPSDb` entry. This is
now the standing approved target; `myps_db_revision` is retired. **Never** `myps_db` (any host).
Read-only by default; never mutate without the operator's explicit per-task override. The
`sa`/`@dmin123` credential remains a tracked, open exposure (RISK-090/091) — accepted as a known
condition of using this target, not resolved by it. Full detail: `CODEX_SYNC_STARTUP.md`'s
"DB safety rules" section.

## `project_myps` — separate, stricter rule

If you're working in `project_myps` specifically (the backend repo, not this workspace), the
zero-AI-footprint rule applies — see `~/.codex/AGENTS.md` (global) and ADR-107 in `decisions.md`.
It does not apply here; this workspace is where the AI-authored coordination files belong.

## Canonical shared skills for Claude and Codex

When working from this Employee-System-Analyst-Expert repository, use the canonical skill files
under `ai-sa-employee/skills/`:

- Read `ai-sa-employee/skills/rollback-readiness-test.md` for MYPS readiness testing and verdicts.
- Apply the upstream Ponytail plugin in full mode when choosing or simplifying implementation and
  test work, subject to the rollback skill's safety and evidence gates.
- Do not create a duplicate Ponytail copy under `.codex/skills/`.
- The Employee repository owns the MYPS readiness contract; the upstream Ponytail repository owns
  generic minimalism and its runtime plugin.
- Claude and Codex must verify their own runtime/plugin state; never claim identical runtime hooks
  merely because both agents follow the same workflow.
