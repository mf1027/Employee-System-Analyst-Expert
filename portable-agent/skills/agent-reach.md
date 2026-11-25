# Agent Reach

## Purpose
Assess what is within the agent's capability and authority for a given request — what can be done safely and completely, what requires human assistance, and what is outside scope. Prevents scope overreach and capability hallucination.

## When to use
Invoke when a request is ambiguous about scope, when the task may require capabilities beyond code/text analysis, when physical-world actions are needed, or when the agent needs to determine whether to proceed, ask a question, or decline.

## Prerequisites
- The user's request.
- Knowledge of the agent's actual capabilities and constraints.

## Procedure

1. **Classify the request:**
   a. **Within reach:** code analysis, documentation, planning, review, text generation, structured analysis, file operations within the workspace.
   b. **Partial reach:** requires human input for specific decisions, credentials, or domain knowledge, but the agent can do the structural work.
   c. **Outside reach:** physical-world actions, real-time system access, live user testing, financial transactions, legal decisions, deployment to environments the agent cannot access.
   d. **Prohibited:** actions blocked by AGENT.md safety rules or organizational policy.

2. **For within-reach tasks:** proceed directly.

3. **For partial-reach tasks:**
   a. Identify exactly what the agent can do.
   b. Identify exactly what requires human input.
   c. Do the agent-capable portion and present the human-dependent items as specific questions.

4. **For outside-reach tasks:**
   a. State what the agent cannot do and why.
   b. Identify the closest action the agent CAN take (e.g., cannot deploy but can prepare deployment documentation; cannot test with users but can prepare test scripts).
   c. Provide the deliverable the human needs to complete the action (runbook, checklist, documentation).

5. **For prohibited tasks:**
   a. State the rule that prevents the action.
   b. Do not offer workarounds that circumvent the rule.

## Output contract
- Classification: within reach / partial reach / outside reach / prohibited.
- For partial reach: what the agent will do + what the human must do.
- For outside reach: closest helpful action + human action items.

## Safety and approval gates
- Do not claim capabilities the agent does not have.
- Do not attempt outside-reach actions with "best effort" — flag clearly.
- Prohibited actions are non-negotiable.

## Verification
- Classification is honest about actual capabilities.
- Human action items are specific and actionable.
- No capability hallucination ("I'll deploy that for you" when the agent cannot).
