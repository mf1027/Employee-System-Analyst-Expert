# Source and reconstruction boundary

This release is built from the uploaded repository archive. The archive contains 59 historical procedure files under `ai-sa-employee/skills/`, the umbrella employee skill at `ai-sa-employee/SKILL.md`, and the native Claude `plan-analysis` skill under `.claude/skills/plan-analysis/`. The 63-name historical inventory therefore has 61 available source bodies and two absent entries: `apk-standalone-conversion` and `multi-agent-skill-propagation`.

The 22 portable canonical skills are active only within `portable-agent/`. The enclosing Employee System Analyst runtime continues to use root `CLAUDE.md`, its 59 active employee procedure files and the umbrella employee skill; this package does not replace that runtime. Historical procedures were compared by capability and assigned explicit `REPLACE`, `MERGE`, `REFERENCE`, `RETIRE` or `HOST-DEPENDENT` dispositions. This is not a claim that all legacy text, scripts, templates or runtime integrations were copied verbatim. The parity decision and rationale are in `docs/SKILL-PARITY-CONFLICT-AUDIT.md`; the machine-readable map is in `skills/skill-intelligence.json`.

The root workspace's `AGENTS.md`, `CLAUDE.md`, legacy employee skills and host-specific commands remain separate from the portable agent's `AGENT.md` contract. Do not silently collapse those operating contexts or replace the user's project memory/role definitions.

No live model or host runtime was invoked for this static package audit. Host discovery, live classification accuracy, permission enforcement, memory persistence and delegation remain unverified.
