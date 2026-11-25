# Context Economy

## Purpose
Manage the agent's context window efficiently — prioritize high-value information, summarize or defer low-value content, and maintain working state across turns without exceeding capacity.

## When to use
Invoke when context is becoming large or fragmented, when a task spans many turns, when switching between subtasks, or when information needs to be preserved across context compression or session boundaries.

## Prerequisites
- A task in progress that requires state management.
- Awareness of context window limits and current usage.

## Procedure

1. **Assess context state:**
   a. What information is currently loaded and active?
   b. What information is stale (already acted on, no longer needed)?
   c. What information will be needed in future turns?
   d. What is the current context pressure (low/medium/high)?

2. **Prioritize by recency and relevance:**
   - **Keep active:** current task state, recent decisions, active requirements, unresolved questions.
   - **Summarize:** completed work (replace detailed traces with one-line result summaries).
   - **Defer:** reference material that can be re-read when needed (file paths, not full contents).
   - **Drop:** superseded information, resolved questions, exploration dead-ends.

3. **State preservation for multi-turn work:**
   a. Maintain a running summary of: where we are, what is done, what is next, what decisions were made.
   b. Use structured state (bulleted lists, not prose) for easy scanning on resume.
   c. Key information to preserve: file paths, function names, error messages, test results, decisions, and remaining work.

4. **Handoff between turns or sessions:**
   a. Write a continuation summary that includes: current step, blockers, last action, next action.
   b. Include exact commands and file paths, not descriptions.
   c. Flag any state that is in memory only (not yet written to disk).

5. **Avoid context waste:**
   - Do not re-read files you already have in context unless they may have changed.
   - Read targeted sections (line ranges) instead of full files when possible.
   - Summarize tool output instead of keeping raw output when the detail is no longer needed.
   - Do not repeat the user's request back to them.

## Output contract
- Context state assessment when context pressure is high.
- State preservation artifacts written to project files when crossing session boundaries.
- Continuation summaries at turn boundaries in multi-step work.

## Safety and approval gates
- Context economy is operational — no system changes.
- Do not drop security-relevant information, unresolved risks, or active blockers to save space.
- Do not summarize away error details that may be needed for debugging.
- When in doubt about what to drop, keep it.

## Verification
- Multi-turn work resumes without re-asking the user for previously provided information.
- Key decisions and their rationale are preserved, not just outcomes.
- File paths and commands are exact, not approximated from memory.
