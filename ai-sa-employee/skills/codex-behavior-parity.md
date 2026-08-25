# Skill: codex-behavior-parity

## Purpose

Translate useful ChatGPT/Codex operating behaviors into Claude-side MYPS work rules without
pretending Claude has Codex's exact runtime capabilities.

Use this skill when the operator asks Claude to work "like Codex", sync with Codex, copy Codex's
testing/review discipline, or prepare Claude to plan work that Codex or a developer may implement.

This is a parity and coordination skill. It does not authorize code changes, database changes, git
operations, or frontend work.

## Trigger phrases

- "make Claude work like Codex"
- "sync Claude and Codex behavior"
- "Codex personal behavior"
- "what does Codex do that Claude should follow"
- "handoff this to Claude but keep it Codex-style"
- "make Claude use the same process as ChatGPT/Codex"

## Required workflow

### 1. Reconcile current MYPS authority

Before producing a plan or handoff, read or verify the current authority surfaces:

1. Current operator instruction.
2. Obsidian MYPS startup notes and current-state dashboard.
3. `CODEX_SYNC_STARTUP.md`.
4. Relevant MYPS ADR/RISK/memory lane files.
5. Live code/config/schema evidence when the task is implementation-related.

If sources conflict, stop and report a conflict card before deciding which behavior to copy.

### 2. Inventory Codex behavior in scope

List the Codex behaviors the task needs, using only behaviors actually relevant to the request:

- plan-first for risky, multi-file, DB, deployment, or unclear work;
- file/config/schema inspection before asking discoverable questions;
- safe local execution with approvals;
- no unrequested git mutation;
- no production DB mutation;
- DB target reconciliation before connecting;
- rollback-only drills for DB/data checks;
- authenticated API tests before readiness claims;
- fresh file/function/line evidence;
- skill-based workflows such as `code-behavior-audit` and `rollback-readiness-test`;
- Obsidian mind-map update before completion.

### 3. Classify portability

For each behavior, classify it:

- **Portable** — Claude can follow the same instruction directly.
- **Workflow-equivalent** — Claude can plan/specify the behavior, but Codex/developer may execute it.
- **Claude Code only** — possible only when Claude has local tool access and explicit permission.
- **Not portable** — runtime-specific Codex behavior; document the limitation.
- **Operator-only** — requires the operator to approve, provide credentials, or run something.

### 4. Translate into Claude rules

Create Claude-facing instructions using this pattern:

```text
Codex behavior:
Claude equivalent:
Evidence required:
Limits / what Claude must not claim:
Obsidian note to update:
```

Hard rule:

```text
When a MYPS task asks Claude to behave like Codex, Claude must not claim it can execute Codex runtime
features directly. Claude must apply Codex-equivalent behavior through planning, evidence
requirements, handoff instructions, Obsidian updates, and explicit implementation instructions for
Codex or the developer.
```

### 5. Run RCA + gap loop

Before finalizing, run at least two passes:

1. **RCA pass** — why could Claude and Codex still drift after this translation?
2. **Gap pass** — what behavior is still unmapped, ambiguous, or unsupported?
3. Tighten wording or mark the gap as open.

Stop only when every behavior is implemented, mapped to an existing skill, marked not portable, or
left as an explicit operator decision.

### 6. Completion and sync

For MYPS, update or instruct the update of relevant Obsidian notes before the task is complete:

- Claude/Codex sync guide;
- current-state dashboard;
- skill/process notes;
- backend/testing/change-impact notes when behavior affects implementation work.

Final response must include the MYPS mind-map sync block.

## Output format

```text
Codex-to-Claude parity result

RCA:
- ...

Gap analysis:
- ...

Behavior matrix:
- Codex behavior:
  Claude equivalent:
  Portability:
  Evidence:
  Limitation:

Updated/required docs:
- ...

Remaining open decisions:
- ...

Mind-map sync:
- Updated:
- Notes touched:
- If no:
```

## Guardrails

- Do not create or modify Markdown inside `project_myps`.
- Do not run git commit, push, reset, checkout, or staging commands.
- Do not mutate any database unless a separate approved task explicitly authorizes it.
- Do not convert Claude into a fake Codex runtime. Name capability limits plainly.
- Do not mark a workflow "100% synced" unless startup, completion, Obsidian, and evidence gates are all represented.
