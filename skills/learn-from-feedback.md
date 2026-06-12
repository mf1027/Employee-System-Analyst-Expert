# Skill: learn-from-feedback

## Purpose
Capture feedback — a client reply, a stakeholder note, a UAT finding, or a
post-incident review — into **claude-mem** with the same depth enforcement as
`end-of-task`, so the system learns from real outcomes without bloating memory.md.

## Trigger
Invoke when the operator says "the client said X", "got feedback on [task]",
"here's what came out of UAT", "post-incident notes", or pastes feedback to record.

## Minimum context required
- The feedback text (pasted or described by the operator)
- Which task, project, or client it relates to
The trigger is always manual — the operator provides the feedback.

## Steps
1. Search claude-mem for prior lessons on this topic: `mem search "[feedback topic]"` —
   check for patterns before writing.
2. Read the relevant client record at `memory/clients/[name].md` for context.
3. Interpret the feedback: what does it reveal? What was the underlying cause?
4. Compose a lesson entry with the **depth check** — must include root cause AND
   lesson-learned. Rewrite if shallow.
5. Store in claude-mem via `memory_add`:
   - **Title:** `Feedback — [topic] — [YYYY-MM-DD]`
   - **Content:** source + root cause + lesson (what to do differently)
   - **Tags:** `type:lesson`, `type:feedback`, `client:[name]`, `project:[name]`
6. Run the same pattern-surfacing check as `end-of-task`: search claude-mem for
   3+ similar root causes → ask whether to update the relevant skill.
7. If the feedback reveals a new risk, flag it for addition to the project's
   `risks.md` as a new `RISK-` entry.

## Output format
```
FEEDBACK CAPTURED
Client/Project: [name / name]
Related to: [task or deliverable]

Lesson stored in claude-mem:
  Title: Feedback — [topic] — [YYYY-MM-DD]
  Source: [client / stakeholder / UAT / other]
  Root cause: [specific cause]
  Lesson: [what to do differently or watch for]
  Tags: type:lesson, type:feedback, client:[name], project:[name]

[Pattern surfaced: "..." — if applicable]
[New risk flagged: "RISK-XXX — [description]" — if applicable]
```

## Failure exit
"No feedback text provided. Paste the feedback and tell me which project it relates to."
