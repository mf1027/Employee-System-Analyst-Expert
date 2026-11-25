# Change Management

## Purpose
Assess a change request against the confirmed scope baseline — impact on requirements, schedule, risks, architecture, data, and cost — and produce a recommendation before any change is accepted into scope.

## When to use
Invoke when a scope change is proposed, requirements shift, the client requests additions or modifications, or when any confirmed baseline item needs revision.

## Prerequisites
- The proposed change: description of what is being added, removed, or modified.
- Access to current requirements baseline, plan, risk register, and architecture.

## Procedure

1. **Read current baseline.** Review requirements, plan, risk register, architecture, and database documentation.
2. **Classify the change:**
   - **Type:** Addition / Modification / Removal / Correction.
   - **Driver:** Client request / Regulatory / Error in requirements / Discovery.
3. **Assess impact** across dimensions:
   a. **Scope:** Which requirements are affected? What is added/removed/modified?
   b. **Schedule:** Additional effort estimate. Which milestones slip?
   c. **Risk:** Does this introduce new risks or worsen existing ones?
   d. **Architecture:** Does this force a design change? New components/interfaces?
   e. **Data:** Schema changes? Migration required?
   f. **Cost:** Effort delta (for conversion to cost by operator).
4. **State recommendation:** Accept / Reject / Defer — with rationale tied to specific requirements, constraints, or risks.
5. **If recommending Accept:** list conditions (what must be updated, who must approve, which baselines change).
6. **Identify notification list:** all stakeholders whose deliverable, milestone, or requirement is affected.
7. **Present output.** Wait for explicit decision before updating any project files.

## Output contract
- Change request summary: ID, project, date, requester, description, type, driver.
- Impact assessment across scope, schedule, risk, architecture, data, and cost.
- Recommendation with rationale.
- Conditions for acceptance (if applicable).
- Notification list.

## Safety and approval gates
- Do not accept a change into scope without explicit decision-maker approval.
- Do not update baseline documents until the decision is confirmed.
- Flag changes that set precedents likely to open further scope expansion.
- Preserve traceability: every baseline change links to its change request.

## Verification
- Impact assessment covers all dimensions; none skipped without documented reason.
- Recommendation is justified by evidence, not just preference.
- Affected requirements/plan/risk items are identified by ID, not in general terms.
