# Process Analysis

## Purpose
Map the current-state process (AS-IS), identify root causes of pain, and design the future-state process (TO-BE) so that solution design targets real bottlenecks instead of surface symptoms.

## When to use
Invoke when asked to map a process, identify bottlenecks, analyze a workflow, or compare current vs desired state. Natural chain: after requirements gathering, before solution design.

## Prerequisites
- A named process or problem area to analyse.
- Access to any existing process documentation, requirements, or stakeholder descriptions.

## Procedure

1. **Gather context.** Read existing project documentation, requirements, and any prior process artifacts. Identify known pain points before starting.
2. **Official vs real process check.** Ask whether the documented process matches day-to-day reality. If there is a gap, map BOTH and note discrepancies. The real process is the truth.
3. **Map the AS-IS process:**
   a. Steps in sequence, with the actor responsible for each.
   b. Inputs, outputs, systems, and handoff points at each step.
   c. Known pain points, delays, errors, rework, and workarounds.
   d. Wait states, duplicate entry, control gaps, bottlenecks, and ambiguity.
4. **Quantify the pain.** For the most significant pain point, ask for hard numbers:
   - Time cost: how long, how many people, how often?
   - Error rate: how frequently does this step fail or require rework?
   - Financial cost: what is the cost per incident, per month?
   - If numbers are unknown, record "unquantified" — never skip the step.
5. **Root cause analysis.** Apply 5 Whys to the most significant pain point: ask "why" five times to reach the root cause, not just a symptom. Record each level.
6. **Map the TO-BE process.** Design the desired future state that removes the root cause. Mark which steps change, are removed, or are added compared to AS-IS.
7. **Gap analysis.** Identify what needs to change to move from AS-IS to TO-BE. Flag gaps with significant technical, organisational, data, or system complexity.
8. **Validate.** Check proposed process changes against user roles, data constraints, system capabilities, acceptance criteria, and regulatory requirements.

## Output contract
- AS-IS process table: Step | Actor | Input | Action | Output | System | Pain Point
- Quantified pain summary
- 5 Whys root cause chain
- TO-BE process table: Step | Actor | Action | Change from AS-IS
- Gap list with complexity/risk flags
- Swimlane or sequence diagram in text or Mermaid when useful

## Safety and approval gates
- This is analysis — no implementation or system changes without explicit authorization.
- Validate proposed changes against existing requirements and constraints before recommending.
- Label assumptions explicitly; do not present inferred process details as confirmed.

## Verification
- Every AS-IS step has an identified actor, input, and output.
- At least one pain point is quantified or explicitly marked unquantified.
- TO-BE addresses the identified root cause, not symptoms.
- Gap list traces to specific AS-IS → TO-BE transitions.
