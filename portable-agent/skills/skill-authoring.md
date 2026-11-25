# Skill Authoring

## Purpose
Create, review, and maintain skills — the agent's procedural knowledge files that guide specific task types. Ensure skills are actionable, well-structured, and testable.

## When to use
Invoke when asked to create a new skill, review an existing skill, update a skill procedure, or when a recurring task pattern would benefit from a documented procedure.

## Prerequisites
- A clear task pattern that occurs more than once.
- Understanding of the procedure, including safety gates and verification steps.
- Knowledge of the skill format and conventions used in the project.

## Procedure

1. **Assess whether a skill is needed:**
   - Does this task recur? (One-off procedures do not need a skill.)
   - Does the existing SOUL.md or AGENT.md workflow cover this? (Do not duplicate.)
   - Would an agent without this skill reliably produce the right output? (If yes, skip.)

2. **Define the skill structure:**
   a. **Name:** lowercase, hyphenated, descriptive of the action (e.g., `security-review`, `diagnosing-bugs`).
   b. **Purpose:** one paragraph — what the skill does and what value it provides.
   c. **When to use (trigger):** specific phrases, conditions, or contexts that invoke this skill.
   d. **Prerequisites:** what must exist before the skill can be executed.
   e. **Procedure:** numbered steps, each actionable and independently verifiable.
   f. **Output contract:** what the skill produces (format, structure, content).
   g. **Safety and approval gates:** what requires authorization, what must not happen.
   h. **Verification:** how to confirm the skill was executed correctly.

3. **Quality rules:**
   - Steps are imperative ("Check X," "Identify Y"), not descriptive ("The agent should...").
   - Each step is independently verifiable — you can tell whether it was done.
   - Procedures do not reference specific tools, file paths, or environments unless the skill is platform-specific.
   - Safety gates are explicit — never implicit. If authorization is needed, say so.
   - Output contract defines the shape, not just "produce a report."

4. **Review checklist:**
   a. Can an agent follow this procedure without additional context about how to do each step?
   b. Are safety gates sufficient to prevent damage?
   c. Is the trigger specific enough to avoid false activation?
   d. Would you trust an agent following this procedure on your production system?
   e. Is the skill the right size? Too broad = unfollowable; too narrow = micromanagement.

5. **Register the skill:** add to the skill registry with trigger, classification, and description.

## Output contract
- Skill file following the standard structure (Purpose, When to use, Prerequisites, Procedure, Output contract, Safety gates, Verification).
- Registry entry for the skill.

## Safety and approval gates
- New skills should be reviewed before use on critical systems.
- Skills must not bypass existing AGENT.md safety rules.
- Skills that authorize destructive actions must have explicit approval gates.

## Verification
- Skill follows the standard structure completely.
- Procedure steps are actionable and independently verifiable.
- Trigger conditions are specific enough to avoid false activation.
- Safety gates cover the skill's risk profile.
