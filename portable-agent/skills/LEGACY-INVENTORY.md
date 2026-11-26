# Historical skill inventory and capability parity

This is a source-backed parity map for the 63 historical names reconstructed from the blueprint. The uploaded archive contains 59 historical procedure files under `ai-sa-employee/skills/`, the umbrella employee skill at `ai-sa-employee/SKILL.md`, and the native Claude `plan-analysis` skill under `.claude/skills/plan-analysis/`. Two entries have no matching source body. A disposition is a capability crosswalk for the portable-agent runtime, not a root-workspace routing change. All available root employee procedures remain active under root `CLAUDE.md`; this table does not authorize their deletion or redirection. It is not a claim that original text was copied verbatim into a portable skill.

| Historical skill | Source body | Disposition | Canonical target(s) |
|---|---|---|---|
| `advise-client` | Available | **MERGE** | requirements-analysis; process-analysis; project-planning |
| `api-contract-design` | Available | **REPLACE** | api-contract-design |
| `apk-standalone-conversion` | Missing | **HOST-DEPENDENT** | — |
| `calibration-review` | Available | **MERGE** | test-strategy; risk-management |
| `change-management` | Available | **REPLACE** | change-management |
| `claude-mem` | Available | **HOST-DEPENDENT** | context-economy |
| `code-behavior-audit` | Available | **MERGE** | system-analysis; diagnosing-bugs; code-review |
| `codex-behavior-parity` | Available | **HOST-DEPENDENT** | agent-reach; test-strategy |
| `context-mode` | Available | **REPLACE** | context-economy |
| `conversion-analysis` | Available | **MERGE** | system-analysis; architecture-design; database-analysis |
| `create-diagram` | Available | **MERGE** | architecture-design; domain-modeling; process-analysis |
| `create-pr-timesheet` | Available | **HOST-DEPENDENT** | documentation-handover |
| `data-migration-playbook` | Available | **MERGE** | database-analysis; change-management; test-strategy |
| `database-admin` | Available | **HOST-DEPENDENT** | database-analysis |
| `dba-cross-domain-impact` | Available | **MERGE** | database-analysis; system-analysis |
| `dba-data-flow-trace` | Available | **MERGE** | database-analysis; system-analysis |
| `dba-execution-plan` | Available | **MERGE** | database-analysis |
| `dba-index-strategy` | Available | **MERGE** | database-analysis |
| `dba-performance-baseline` | Available | **MERGE** | database-analysis; test-strategy |
| `dba-process-interview` | Available | **MERGE** | process-analysis; database-analysis |
| `dba-schema-changelog` | Available | **MERGE** | database-analysis; change-management |
| `dba-schema-drill` | Available | **MERGE** | database-analysis; diagnosing-bugs |
| `dba-schema-ingest` | Available | **MERGE** | database-analysis; context-economy |
| `dba-schema-review` | Available | **MERGE** | database-analysis; code-review |
| `dba-security-audit` | Available | **MERGE** | security-review; database-analysis |
| `dba-sql-object-chain` | Available | **MERGE** | database-analysis; system-analysis |
| `deep-analysis` | Available | **MERGE** | system-analysis; diagnosing-bugs; risk-management; test-strategy |
| `developer-handoff` | Available | **MERGE** | documentation-handover; project-planning; test-strategy |
| `document-specialist-skill` | Available | **HOST-DEPENDENT** | documentation-handover |
| `employee-system-analyst` | Available | **RETIRE** | AGENT.md; SOUL.md |
| `end-of-task` | Available | **MERGE** | documentation-handover; context-economy |
| `gather-requirements` | Available | **REPLACE** | requirements-analysis |
| `ingest-meeting-notes` | Available | **MERGE** | requirements-analysis; change-management; risk-management; documentation-handover |
| `ingest-reference` | Available | **MERGE** | agent-reach; context-economy; documentation-handover |
| `learn-from-feedback` | Available | **MERGE** | skill-authoring; change-management; test-strategy |
| `memory-hygiene` | Available | **MERGE** | context-economy; documentation-handover |
| `multi-agent-skill-propagation` | Missing | **HOST-DEPENDENT** | skill-authoring |
| `new-client-setup` | Available | **MERGE** | new-project workflow; project-planning; requirements-analysis |
| `new-project` | Available | **MERGE** | new-project workflow; requirements-analysis; architecture-design; project-planning |
| `new-skill` | Available | **REPLACE** | skill-authoring |
| `nfr-review` | Available | **REPLACE** | nfr-review |
| `ollama-agent-runtime` | Available | **HOST-DEPENDENT** | agent-reach; test-strategy |
| `plan-analysis` | Available | **REFERENCE** | comprehensive-analysis workflow; analysis-only workflow; system-analysis; requirements-analysis; risk-management |
| `plan-project` | Available | **REPLACE** | project-planning |
| `process-analysis` | Available | **REPLACE** | process-analysis |
| `project-status` | Available | **MERGE** | project-status workflow; documentation-handover; risk-management |
| `resume-client` | Available | **MERGE** | continuation; continuation-contract workflows; context-economy |
| `risk-management` | Available | **REPLACE** | risk-management |
| `rollback-readiness-test` | Available | **MERGE** | release workflow; database-analysis; test-strategy |
| `scope-estimate` | Available | **MERGE** | project-planning; change-management; risk-management |
| `scrum-master` | Available | **MERGE** | project-planning; change-management; project-status workflow |
| `security-review` | Available | **REPLACE** | security-review |
| `self-improvement` | Available | **MERGE** | skill-authoring; test-strategy; evals |
| `solution-design` | Available | **MERGE** | architecture-design; domain-modeling; api-contract-design |
| `soup-model-preparation` | Available | **HOST-DEPENDENT** | agent-reach; test-strategy |
| `stakeholder-analysis` | Available | **MERGE** | requirements-analysis; process-analysis; risk-management |
| `status-report` | Available | **MERGE** | project-status workflow; documentation-handover |
| `system-drill` | Available | **MERGE** | system-analysis; diagnosing-bugs; database-analysis |
| `task-board` | Available | **HOST-DEPENDENT** | project-planning; project-status workflow |
| `test-strategy` | Available | **REPLACE** | test-strategy |
| `use-case-analysis` | Available | **MERGE** | requirements-analysis; domain-modeling; process-analysis |
| `web-research` | Available | **REPLACE** | web-research |
| `weekly-review` | Available | **MERGE** | project-status workflow; risk-management; context-economy |

**Counts:** 63 historical names; 59 procedure files in `ai-sa-employee/skills/`; 1 umbrella employee skill at `ai-sa-employee/SKILL.md`; 1 host-native `plan-analysis` skill; 2 source bodies absent; 22 fully authored portable canonical skills. See [`SKILL-PARITY-CONFLICT-AUDIT.md`](../docs/SKILL-PARITY-CONFLICT-AUDIT.md) for rationale and ownership rules.
