# Documentation Handover

## Purpose
Produce technical and project documentation that enables another person or team to understand, maintain, and continue the work without the original author being present. Prioritize utility over completeness — document what someone NEEDS to know, not everything that exists.

## When to use
Invoke when asked to write documentation, create a handover, prepare a knowledge transfer, document a system, or at the end of a project phase when work must be handed to another team member or the client.

## Prerequisites
- The system, project, or work being documented.
- Knowledge of the audience: technical level, role, what they need to do with the documentation.
- Access to the source code, architecture, requirements, and decisions.

## Procedure

1. **Identify the audience and their needs:**
   a. **Operator/maintainer:** how to run, configure, monitor, and troubleshoot.
   b. **Developer:** how to understand the code, make changes, run tests.
   c. **Stakeholder/client:** what was delivered, what decisions were made, what remains.
   d. Write for the audience — an operator does not need class diagrams; a developer does not need business summaries.

2. **Structure by purpose, not by file:**
   a. **Getting started:** how to set up, configure, and verify the system runs.
   b. **Architecture overview:** what the system does, how components relate, key decisions and their rationale.
   c. **Operational runbook:** how to deploy, monitor, troubleshoot, back up, and recover.
   d. **Decision log:** key decisions made, alternatives considered, rationale, and trade-offs.
   e. **Known issues and limitations:** what does not work, what is incomplete, what has workarounds.
   f. **Remaining work:** prioritized list of incomplete items with context.

3. **Write with these rules:**
   - Lead with what someone needs to DO (commands, steps, locations).
   - Explain WHY only when the reason is non-obvious or affects decision-making.
   - Use exact file paths, command lines, and configuration values — no "see the config file."
   - Include working examples, not just descriptions.
   - Keep each section self-contained — a reader should not need to read everything to find what they need.

4. **Verify documentation accuracy:**
   - Run the "getting started" steps yourself. If they fail, fix them.
   - Check that file paths, commands, and configuration values are current.
   - Check that architecture diagrams match the actual code structure.

5. **Handover briefing:**
   - Summary of what was delivered.
   - Key decisions and their constraints.
   - Known risks and their mitigations.
   - Remaining work prioritized by urgency and impact.
   - Contact information for questions (if applicable).

## Output contract
- Documentation structured by purpose (getting started, architecture, operations, decisions, known issues).
- Working commands and examples verified by execution.
- Remaining work list with context and priority.
- Handover summary for stakeholder/client.

## Safety and approval gates
- Documentation is analysis/writing — no system changes.
- Do not document secrets, credentials, or PII in plain text.
- Do not claim capabilities exist that have not been verified.
- Flag any documentation gaps that block safe operation or maintenance.

## Verification
- Getting-started steps are executable and produce the documented result.
- File paths, commands, and config values are current.
- Each section answers its audience's primary question without requiring full document read.
- Known issues and remaining work are prioritized, not just listed.
