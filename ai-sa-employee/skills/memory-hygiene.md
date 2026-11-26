# Memory Hygiene — Canonical File Memory

## Purpose
Keep the canonical Obsidian/project memory concise, current, and internally consistent. The claude-mem integration is disabled and must not be invoked.

## Preconditions
- Identify the canonical Obsidian vault or project memory location.
- Confirm the target source exists and is the current source of truth.
- Never treat the repository's stale `memory/memory.md` snapshot as current without corroboration.

## Procedure
1. Inventory only the relevant canonical memory files and their last-updated metadata.
2. Identify duplicate, superseded, stale, unsupported, or contradictory entries.
3. Preserve source references, decision IDs, risk IDs, dates, and ownership.
4. Propose changes before editing. Do not delete or rewrite historical records without explicit authorization.
5. Consolidate repeated facts into the existing canonical file; do not create a parallel memory service or duplicate index.
6. Re-check inbound links, IDs, and cross-file references after approved edits.

## Output
- Current memory sources inspected
- Stale/duplicate/conflicting entries with evidence
- Proposed or approved changes
- Remaining unknowns and source gaps

## Safety
No secrets in memory. Do not infer current client state from stale snapshots. Do not call `mem search`, `memory_add`, or claude-mem MCP tools.
