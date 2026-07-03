# Skill: new-skill

## Purpose
Create a new skill for this AI employee. Take a plain-language description of a desired capability, write a fully structured skill file using the canonical template, show it, and save only after confirmation.

## Trigger
Invoke when the user says "I need a skill that...", "create a new skill", "add a skill for X", or describes a repeatable task that should be codified.

## Minimum context required
- A description of what the skill should do.
If missing: ask "What should this skill do, and when should I invoke it?"

## Steps
1. Clarify the skill's purpose, trigger, required inputs, and whether it changes code (needs the 3-step checkpoint) or is draft-only / read-only.
2. Draft the skill file using the canonical template (Purpose, Trigger, Minimum context required, Steps, Output format, Failure exit).
3. Show the complete proposed file content.
4. **Wait for "proceed" / "apply" / "yes" / "go ahead"** before writing.
5. Save to `ai-sa-employee/skills/[name].md` (kebab-case name).
6. **Update ALL consumers in the same pass (SKL-010 applied to skills):**
   - `.claude/commands/[name].md` — slash-menu wrapper (frontmatter `description:` = the skill's Purpose
     first sentence; body = "Read and follow ai-sa-employee/skills/[name].md exactly … Apply it to: $ARGUMENTS")
   - `CLAUDE.md` — trigger-table row + skills-list line + skill count (×2 in structure diagrams) + Build Status
   - `ai-sa-employee/skills/skills.md` — index entry
   - `README.md` — skill table row + counts
   A skill is NOT done until all five consumers are updated — the operator caught README drift 2026-07-03.

## Output format
```
PROPOSED SKILL — confirm before I save to ai-sa-employee/skills/[name].md:

# Skill: [name]
## Purpose
...
## Trigger
...
## Minimum context required
...
## Steps
...
## Output format
...
## Failure exit
...

Confirm to save? (proceed / modify [section])
```

## Failure exit
"Cannot create a skill without a description of what it should do."
