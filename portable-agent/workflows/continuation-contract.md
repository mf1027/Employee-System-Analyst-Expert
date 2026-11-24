# Continuation / Next-Agent Contract

A checkpoint is a compact operational record, not a competing memory store. Put it in the project's existing canonical mechanism.

## Required fields
- Project/task identifier and goal
- Current state/status
- Scope and explicit non-goals
- Verified completed work (paths and evidence)
- Incomplete/remaining work
- Current files/worktree state and changes
- Tests/checks run with exact outcomes; tests not run
- Decisions/approval and constraints
- Risks/blockers
- One concrete next action
- Resume instructions (what to inspect/execute first)

## Resume protocol
1. Read checkpoint and canonical instructions.
2. Inspect named files and actual worktree/diff; verify completed claims.
3. Check whether environment/dependencies changed.
4. Run a minimal relevant baseline check.
5. Reconcile checkpoint: correct stale/unsupported claims and preserve decisions unless evidence invalidates them.
6. Resume at earliest unverified step, not from scratch.
7. Update checkpoint after material progress or before interruption.

Do not assume cross-agent memory, shared files, or context transfer works unless verified.
