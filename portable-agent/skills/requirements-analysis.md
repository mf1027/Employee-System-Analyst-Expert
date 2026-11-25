# Requirements Analysis

## Purpose
Elicit, structure, validate, and document requirements. Ensure each requirement captures a need (not a solution), is traceable from source to acceptance criteria, and is assigned a stable ID and priority.

## When to use
Invoke when asked to gather requirements, document needs, analyse what a system should do, interview stakeholders about requirements, or when beginning any project phase that requires a confirmed scope baseline.

## Prerequisites
- A project name or system description.
- A stakeholder, problem description, or existing documentation to work from.
- If neither exists: ask for the project name and what problem it solves before proceeding.

## Procedure

1. **Read existing context.** Review all available documentation — requirements documents, meeting notes, prior analysis, architecture, and constraints. Do not interrogate from scratch when context already exists.
2. **Evidence-first gate:** Quote what was found, identify what is missing, then ask only about the gaps. Never assume a blank slate.
3. **Apply 5W framing** before writing any requirement:
   a. **Who** — which role, persona, or system is affected?
   b. **What (current)** — what is the actual current behaviour or gap? (verified, not assumed)
   c. **What (target)** — what should it do instead?
   d. **Why now** — what is currently blocked, broken, or costing the business?
   e. **How verified** — what observable, measurable outcome confirms it is done?
   If any answer is unknown: flag as an open question. Do not write the requirement yet.
4. **For each requirement:**
   a. Confirm it expresses a **need**, not a solution. If it prescribes HOW, rephrase as what/why and note the proposed solution separately.
   b. Assign a stable ID: REQ-F (functional), REQ-NF (non-functional), REQ-C (constraint).
   c. Assign priority: P0 (must have for MVP) | P1 (should have) | P2 (nice to have) | P3 (future).
   d. Write acceptance criteria (testable, specific, measurable).
   e. Identify dependencies on other requirements or constraints.
5. **Identify and log assumptions** with rationale. State what breaks if the assumption is wrong.
6. **Identify open questions** — requirements that cannot be confirmed without stakeholder input. Number them and note who can answer.
7. **Cross-check:** review each requirement against related ones for contradictions, duplicates, or gaps.
8. **Structure the output.** Group by functional area or user journey. Present for review.

## Output contract
- Requirements table: ID | Priority | Description | Acceptance Criteria | Dependencies | Status
- Assumptions list with rationale and impact-if-wrong.
- Open questions with owner and due date.
- Summary: total requirements by priority, key gaps, and confidence level.

## Safety and approval gates
- Requirements analysis is analysis — do not implement features from gathered requirements without authorization.
- Distinguish confirmed requirements from assumptions. Never present an assumption as confirmed.
- Flag requirements with security, privacy, compliance, or data integrity implications.
- Wait for stakeholder sign-off before using requirements as a scope baseline.

## Verification
- Every requirement has an acceptance criterion that is testable and specific.
- No requirement prescribes a solution without a separate need statement.
- All 5W questions are answered or flagged as open.
- Assumptions are logged, not buried in requirement descriptions.
