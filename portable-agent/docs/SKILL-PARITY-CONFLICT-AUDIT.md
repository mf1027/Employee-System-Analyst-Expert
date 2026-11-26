# Skill Parity, Conflict & Orchestration Audit

**Scope:** Full uploaded repository archive, including portable-agent, historical `ai-sa-employee/skills`, native Claude skills, commands and adapters.
**Method:** Static source inspection, capability-level comparison, duplicate-content comparison, deterministic resolver design and regression tests. This is not a live model/host certification.

## Executive verdict

The archive contains two intentionally distinct skill runtimes: the enclosing Employee System Analyst workspace (root `CLAUDE.md` + 59 active employee procedures + native `plan-analysis`) and the portable-agent subpackage (its own host-neutral contract and canonical skills). The portable layer had no machine-readable capability ownership model. Treating both runtimes as one flat list would itself create a new conflict. The historical index, root skill procedures, native Claude skills, portable canonical skills and host pointers represent different layers. Treating them as one flat skill list creates duplicate routing, unclear precedence and false parity claims.

**Decision:** Keep the 22 portable canonical skills as the authority only inside `portable-agent/`. Add a deterministic Skill Intelligence & Orchestration Layer there. Keep all root employee procedures active under root `CLAUDE.md`; the 63-name map is a capability crosswalk for standalone portability, not a root-runtime redirect or deletion plan.

## Evidence and corrected inventory

| Layer | Observed count | Interpretation |
|---|---:|---|
| Portable canonical skills | 22 | Fully authored portable procedures |
| Historical skill index | 63 names | Historical capability inventory; not 63 separate current owners |
| Historical source bodies in `ai-sa-employee/skills/` | 59 | Available for capability comparison; `skills.md` is the index, not one of the 63 procedure bodies |
| Umbrella employee skill | 1 | Source exists at `ai-sa-employee/SKILL.md`; it is the employee-level host skill |
| Native Claude `plan-analysis` | 1 | Source exists in `.claude/skills/plan-analysis/SKILL.md`; host-specific native skill |
| Historical names without a matching source body | 2 | `apk-standalone-conversion`, `multi-agent-skill-propagation` |
| Claude/Codex adapter pointers | 44 | Two pointer sets for the 22 portable skills; not separate skill bodies |

The old portable `LEGACY-INVENTORY.md` and release documents claimed the historical bodies were unavailable and 42 of 63 remained inventory-only. That was inaccurate for this archive: 59 root employee procedure files, the umbrella `ai-sa-employee/SKILL.md`, and the native `plan-analysis` source are present. The two missing source bodies remain unverified and are not reconstructed by guesswork. These root files remain active in the parent employee runtime; the portable map does not deactivate them.

## RCA — Why conflicts existed

| ID | Root cause | Evidence / mechanism | Consequence | Remediation |
|---|---|---|---|---|
| RCA-SK-01 | Flat/name-driven discovery | Registry was descriptive Markdown; no capability schema or deterministic resolver | Similar task names could select different or overlapping skills | Add capability catalog + explicit primary intent resolver |
| RCA-SK-02 | No single ownership rule | Overlapping skills had no explicit primary/specialist/support roles | Multiple skills could attempt to own the same deliverable | One primary intent, scoped specialists, bounded support |
| RCA-SK-03 | Historical parity was not audited against actual source | Legacy index was treated as inventory-only despite 59 procedure files plus the umbrella employee skill and native plan-analysis being present | False claim of 42 missing procedures; unique capabilities may be missed | Build 63-entry source-backed parity matrix |
| RCA-SK-04 | Multiple catalogs were unsynchronized | Root skill index, portable registry, native Claude skills, adapters and workflows each describe capabilities | Drift and inconsistent discovery | Declare layer boundaries and validate catalog-to-file parity |
| RCA-SK-05 | Generalist/specialist overlap | DBA, security, migration, testing and process skills overlap broader analysis skills | Overloading or duplicate execution | Define specialist triggers and ownership clusters |
| RCA-SK-06 | Duplicate native skill content | `quarantine/red-team/godmode/` and the former nested `.claude/skills/security/godmode/` path are byte-identical | Ambiguous maintenance and duplicate discovery risk | Keep top-level canonical copy; make nested path an explicit pointer only |
| RCA-SK-07 | Memory authority mismatch | Legacy procedures describe service-backed capture; portable contract requires existing project memory as authority | False claims of persistence or parallel memory | Make host memory capability conditional; project source of truth wins |
| RCA-SK-08 | Static tests validate structure, not semantic routing | Existing tests assert fixtures/files but did not run a deterministic resolver | Routing regressions could pass | Add resolver fixtures, negative tests and fail-closed behavior |

## Target architecture

```text
User task
   │
   ▼
Agent reasoning / task intelligence
   ├─ classify dominant intent (exactly one)
   ├─ identify evidenced specialist domains
   └─ select only necessary support procedures
   │
   ▼
Deterministic Skill Intelligence Layer
   ├─ validate intent and skill IDs
   ├─ enforce one primary owner
   ├─ apply stable order: primary → specialists → support
   ├─ deduplicate selected skill IDs
   ├─ reject unknown selections (fail closed)
   └─ emit workflow + exact canonical file paths
   │
   ▼
Agent loads only emitted procedures
   │
   ▼
Execute workflow → verify → report evidence
```

**Boundary:** AI performs semantic understanding. The deterministic layer validates and resolves an explicit classification; it does not pretend that keyword matching can understand intent. It does not grant permissions, run tools, enforce model obedience or replace host sandbox controls.

## Ownership and conflict rules

1. Exactly one primary intent and one primary skill per task.
2. A specialist is additive and scoped to an evidenced domain; it does not silently replace the primary task owner.
3. Supporting skills are loaded only when they contribute a distinct required output.
4. Duplicate skill IDs are loaded once; primary role takes precedence.
5. Unknown intent, specialist or skill ID fails closed with valid choices. No silent best-guess fallback.
6. Workflows own lifecycle sequencing; skills own focused procedures. Do not create skill copies for workflows or role identities.
7. Adapter files are pointers, never new canonical procedure bodies.
8. Existing project memory and employee role definitions remain authoritative; no second memory or employee system is created.
9. Host-specific capabilities remain host-dependent and must be verified before use.

### Ownership clusters

| Capability cluster | Primary owner | Specialist / supporting roles | Conflict resolution |
|---|---|---|---|
| Requirements, stakeholder, use-case | `requirements-analysis` | `process-analysis`, `domain-modeling` | Requirements owns need/acceptance; process owns flow; domain owns concepts/invariants |
| System tracing and RCA | `system-analysis` for system-wide mapping; `diagnosing-bugs` for defects | `database-analysis`, `domain-modeling`, `risk-management` | Choose by dominant intent; do not run two competing RCA owners |
| Architecture and solution design | `architecture-design` | `domain-modeling`, `api-contract-design`, `nfr-review` | Architecture owns solution structure; specialist owns its contract/domain/NFR concern |
| Database / DBA | `database-analysis` | `system-analysis`, `security-review`, `test-strategy` | DBA owns schema/SQL/data correctness; broader skills support cross-domain impact |
| Planning and delivery | `project-planning` | `change-management`, `risk-management`, `documentation-handover` | Planning owns sequence; change management owns baseline deltas |
| Quality | `test-strategy` for test design; `tdd` for implementation; `code-review` for review | `security-review`, `database-analysis` | Distinct phases, not interchangeable reviewer roles |
| Research / video | `web-research` for external research; `agent-reach` for capability boundaries; `video-intelligence` for audiovisual evidence | `documentation-handover` | Select by source modality; never claim retrieval if unavailable |
| Memory / continuation | `context-economy` | `documentation-handover` | Existing project memory is canonical; checkpoint is fallback, not parallel memory |

## Historical skill parity decisions

| Historical skill | Disposition | Canonical target(s) | Reason |
|---|---|---|---|
| `advise-client` | **MERGE** | requirements-analysis; process-analysis; project-planning | Client advice is a composition of requirements, process and planning; no separate durable procedure owner is needed. |
| `api-contract-design` | **REPLACE** | api-contract-design | The portable canonical skill is the focused owner and is already fully authored. |
| `apk-standalone-conversion` | **HOST-DEPENDENT** | — | No source body is present; Android packaging/signing/build behavior is platform- and toolchain-specific. |
| `calibration-review` | **MERGE** | test-strategy; risk-management | Calibration belongs in evaluation design and risk interpretation; no distinct portable procedure is evidenced. |
| `change-management` | **REPLACE** | change-management | Direct canonical equivalent exists. |
| `claude-mem` | **HOST-DEPENDENT** | context-economy | Legacy memory integration is tied to a host service; canonical project memory must remain authoritative. |
| `code-behavior-audit` | **MERGE** | system-analysis; diagnosing-bugs; code-review | Trace behavior, diagnose deviations, and review findings are distinct phases owned by existing canonical skills. |
| `codex-behavior-parity` | **HOST-DEPENDENT** | agent-reach; test-strategy | Requires actual Codex runtime/version and host-specific evidence. |
| `context-mode` | **REPLACE** | context-economy | The canonical context-economy skill owns progressive loading and continuation context. |
| `conversion-analysis` | **MERGE** | system-analysis; architecture-design; database-analysis | Conversion is a system/data migration analysis, not a separate general-purpose owner. |
| `create-diagram` | **MERGE** | architecture-design; domain-modeling; process-analysis | Diagrams are outputs of the owning analysis, not a separate skill boundary. |
| `create-pr-timesheet` | **HOST-DEPENDENT** | documentation-handover | PR/time-sheet automation depends on repository and tracker integrations. |
| `data-migration-playbook` | **MERGE** | database-analysis; change-management; test-strategy | Migration safety is consolidated into DBA analysis, change control and validation. |
| `database-admin` | **HOST-DEPENDENT** | database-analysis | Actual administration requires verified DB tools, environment, permissions and operator authorization. |
| `dba-cross-domain-impact` | **MERGE** | database-analysis; system-analysis | Cross-domain blast-radius analysis becomes a required DBA procedure with system-level tracing. |
| `dba-data-flow-trace` | **MERGE** | database-analysis; system-analysis | Data lineage is part of schema/object and end-to-end flow analysis. |
| `dba-execution-plan` | **MERGE** | database-analysis | Execution-plan interpretation is a database-analysis procedure. |
| `dba-index-strategy` | **MERGE** | database-analysis | Index selection is a database-analysis procedure grounded in workload and plan evidence. |
| `dba-performance-baseline` | **MERGE** | database-analysis; test-strategy | Baseline capture and regression measurement belong to DBA analysis and test strategy. |
| `dba-process-interview` | **MERGE** | process-analysis; database-analysis | Interview-derived data rules are process analysis inputs, validated by DBA analysis. |
| `dba-schema-changelog` | **MERGE** | database-analysis; change-management | Schema change evidence belongs to database analysis and controlled change management. |
| `dba-schema-drill` | **MERGE** | database-analysis; diagnosing-bugs | Schema/object drills are diagnostic procedures within DBA analysis. |
| `dba-schema-ingest` | **MERGE** | database-analysis; context-economy | Schema ingestion is a bounded evidence-capture procedure, not a separate owner. |
| `dba-schema-review` | **MERGE** | database-analysis; code-review | Schema review belongs to DBA analysis; general review criteria remain in code-review. |
| `dba-security-audit` | **MERGE** | security-review; database-analysis | Database security is a scoped specialist pass combining security and schema evidence. |
| `dba-sql-object-chain` | **MERGE** | database-analysis; system-analysis | SQL dependency tracing is part of DBA and system-flow analysis. |
| `deep-analysis` | **MERGE** | system-analysis; diagnosing-bugs; risk-management; test-strategy | Deep analysis is a rigor profile combining existing skills and workflows, not another skill owner. |
| `developer-handoff` | **MERGE** | documentation-handover; project-planning; test-strategy | Implementation handoff is a deliverable flow using planning, acceptance and handover. |
| `document-specialist-skill` | **HOST-DEPENDENT** | documentation-handover | Document generation depends on the installed document skills and runtime tools. |
| `employee-system-analyst` | **RETIRE** | AGENT.md; SOUL.md | Umbrella identity is defined by the canonical agent contract and soul; it should not be a competing skill. |
| `end-of-task` | **MERGE** | documentation-handover; context-economy | Completion reporting and continuation checkpoint are covered by handover/context procedures. |
| `gather-requirements` | **REPLACE** | requirements-analysis | Direct canonical equivalent exists. |
| `ingest-meeting-notes` | **MERGE** | requirements-analysis; change-management; risk-management; documentation-handover | Meeting ingestion extracts candidates; formal owners validate and record each item. |
| `ingest-reference` | **MERGE** | agent-reach; context-economy; documentation-handover | Local reference ingestion is context distillation and handover; external discovery is `web-research`, video is `video-intelligence`. |
| `learn-from-feedback` | **MERGE** | skill-authoring; change-management; test-strategy | Feedback becomes a proposed change, regression fixture and governed skill update. |
| `memory-hygiene` | **MERGE** | context-economy; documentation-handover | Canonical memory hygiene is a context and handover concern; no parallel memory authority. |
| `multi-agent-skill-propagation` | **HOST-DEPENDENT** | skill-authoring | No source body; propagation requires actual host/agent installation and synchronization capability. |
| `new-client-setup` | **MERGE** | new-project workflow; project-planning; requirements-analysis | Client onboarding is a project lifecycle workflow, not a skill owner. |
| `new-project` | **MERGE** | new-project workflow; requirements-analysis; architecture-design; project-planning | New-project lifecycle is owned by workflow orchestration and canonical specialists. |
| `new-skill` | **REPLACE** | skill-authoring | Direct canonical equivalent exists. |
| `nfr-review` | **REPLACE** | nfr-review | Direct canonical equivalent exists. |
| `ollama-agent-runtime` | **HOST-DEPENDENT** | agent-reach; test-strategy | Runtime setup is host/model/provider-specific and requires live environment checks. |
| `plan-analysis` | **REFERENCE** | analysis-only workflow; system-analysis; requirements-analysis; risk-management | Native Claude skill is available in .claude; portable behavior is composed from the workflow and canonical skills. |
| `plan-project` | **REPLACE** | project-planning | Direct canonical equivalent exists. |
| `process-analysis` | **REPLACE** | process-analysis | Direct canonical equivalent exists. |
| `project-status` | **MERGE** | project-status workflow; documentation-handover; risk-management | Status reporting is a workflow and evidence-backed handover. |
| `resume-client` | **MERGE** | continuation; continuation-contract workflows; context-economy | Continuation is a workflow with checkpoint reconciliation, not a duplicate skill. |
| `risk-management` | **REPLACE** | risk-management | Direct canonical equivalent exists. |
| `rollback-readiness-test` | **MERGE** | release workflow; database-analysis; test-strategy | Rollback readiness combines release gates, data safety and validation. |
| `scope-estimate` | **MERGE** | project-planning; change-management; risk-management | Estimation is a planning procedure with uncertainty and scope-change controls. |
| `scrum-master` | **MERGE** | project-planning; change-management; project-status workflow | Coordination practices belong to planning/change/status; no new project-management layer. |
| `security-review` | **REPLACE** | security-review | Direct canonical equivalent exists. |
| `self-improvement` | **MERGE** | skill-authoring; test-strategy; evals | Improvements require evidence, a bounded change and regression coverage. |
| `solution-design` | **MERGE** | architecture-design; domain-modeling; api-contract-design | Solution design is composed from existing design owners. |
| `soup-model-preparation` | **HOST-DEPENDENT** | agent-reach; test-strategy | Depends on a particular local-model runtime, hardware and setup tools. |
| `stakeholder-analysis` | **MERGE** | requirements-analysis; process-analysis; risk-management | Stakeholder mapping is part of elicitation and process/risk context. |
| `status-report` | **MERGE** | project-status workflow; documentation-handover | Status output is a workflow deliverable. |
| `system-drill` | **MERGE** | system-analysis; diagnosing-bugs; database-analysis | Drill-down is a diagnostic technique inside existing system/DB analysis. |
| `task-board` | **HOST-DEPENDENT** | project-planning; project-status workflow | A live board requires a supported tracker integration; the agent must not invent one. |
| `test-strategy` | **REPLACE** | test-strategy | Direct canonical equivalent exists. |
| `use-case-analysis` | **MERGE** | requirements-analysis; domain-modeling; process-analysis | Use cases are requirements/process/domain artifacts, not a separate owner. |
| `web-research` | **REPLACE** | web-research | Portable research owner is now distinct from agent-reach capability assessment. |
| `weekly-review` | **MERGE** | project-status workflow; risk-management; context-economy | Periodic review is a cadence/workflow using existing project records. |

### Disposition meaning

- **REPLACE:** direct portable canonical equivalent owns that capability inside `portable-agent/`; the historical root employee procedure remains active for the enclosing workspace and is not redirected.
- **MERGE:** capability is represented by one or more portable canonical skills/workflows; do not create a duplicate portable skill. Root employee procedures remain active in their separate runtime.
- **REFERENCE:** keep a host-native skill where useful and map portable equivalents; no duplicate portable copy is required.
- **RETIRE:** umbrella/duplicate responsibility should not remain an active portable skill; this does not deactivate root employee procedures unless the root workspace owner separately approves that change.
- **HOST-DEPENDENT:** depends on runtime, integration, platform or missing source evidence; do not claim portable parity.
- **RESTORE:** not selected in this audit because no missing unique capability was evidenced strongly enough to justify a new skill. Revisit only with a concrete recurring requirement and source/evaluation evidence.

## Recovered SC-01–SC-20 conflict register

The recovered prior conversation summary preserves the conflict themes and several precedence decisions, but not the full exact skill-pair membership for SC-09–SC-20. The table below records only recovered decisions; it does not fabricate missing pair details.

| ID | Conflict area | Recovered ownership / resolution | Implementation treatment |
|---|---|---|---|
| SC-01 | Requirements / gather-requirements / stakeholder / use-case | `requirements-analysis` owns; others are supporting methods | Mapped to one requirements owner; process/domain specialists remain scoped |
| SC-02 | System / thorough / deep / plan / RCA / GAP | Prior decision: comprehensive `plan-analysis` owns orchestration; RCA/GAP/system-analysis are methods | Portable `comprehensive-analysis` workflow owns sequencing; `system-analysis` is primary procedure; native plan-analysis remains a host reference |
| SC-03 | RCA / GAP | No competing diagnosis/report engine; activate only when relevant to dominant task | Defect RCA owned by `diagnosing-bugs`; broad gap analysis orchestrated by comprehensive-analysis workflow |
| SC-04 | Architecture / solution design | `architecture-design` owns architecture decisions | Solution-design legacy capability merged into architecture/domain/API skills |
| SC-05 | Domain modeling | Domain concepts are specialist supporting input, not competing architecture/requirements ownership | `domain-modeling` is a bounded specialist |
| SC-06 | Project planning / task board / status | `project-planning` owns plan; status reports state only | Planning skill and status workflow kept separate; tracker is host-dependent |
| SC-07 | Generic database / DBA | DBA specialist authority wins for SQL, schema, performance, migration, integrity and rollback | Consolidated DBA procedures into `database-analysis`; specialist selection is explicit |
| SC-08 | Web research / agent reach | Prior decision: `web-research` owns research; reach is access capability | Portable core has `web-research` owns research synthesis; `agent-reach` assesses capability/permission boundaries before retrieval |
| SC-09 | Reference ingestion / video | Route by source type; audiovisual analysis is not generic document ingestion | `video-intelligence` owns video/audio evidence; external research uses `web-research`; local reference ingestion uses the `reference-ingestion` workflow with `context-economy` + handover; `agent-reach` is only capability/permission assessment |
| SC-10 | Debugging | One debugging owner | `diagnosing-bugs` owns defect reproduction and RCA; TDD begins only after diagnosis/authorization |
| SC-11 | TDD / native TDD / Superpowers | One TDD owner; do not duplicate test-first procedure | `tdd` owns implementation test loop; native adapters remain host-dependent |
| SC-12 | Test strategy / testing | Strategy/design is distinct from executing tests | `test-strategy` owns test design; `tdd` owns implementation test execution |
| SC-13 | Code review / Superpowers review | One review owner | `code-review` owns review procedure; host review tools are adapters, not new owners |
| SC-14 | Adversarial QA / code review | Adversarial QA is a specialized second pass, not a duplicate general review | Add adversarial pass to review workflow when risk warrants; independent agent only when actually available |
| SC-15 | Plan-analysis / spec / tickets / Wayfinder | Sequential lifecycle; do not create a competing router | Comprehensive analysis → requirements/spec → project planning/tickets → implementation; workflows own sequence |
| SC-16 | Memory / auto-persist / Obsidian | Canonical memory hierarchy; no duplicate memory/glossary | Project's designated canonical records remain authoritative; context-economy/checkpoint are process only |
| SC-17 | Duplicate Godmode | One active canonical name/path | Top-level `quarantine/red-team/godmode/` retained; nested duplicate reduced to pointer |
| SC-18 | Global / project skills | Explicit precedence hierarchy | Host/system policy → current user instruction → applicable project-specific authority → global/general skill guidance; adapters do not override canonical source |
| SC-19 | Legacy / new canonical skills | Capability parity audit and scoped portable crosswalk; no blind restoration or root-runtime redirects | All 63 historical names dispositioned; 61 source bodies available, 2 absent; root employee runtime preserved |
| SC-20 | Native host / portable skills | Host compatibility resolver required | Resolver supports Claude/Codex pointer mapping and generic manual fallback; all discovery remains runtime-unverified |

## Specific remediation implemented in 2.2.0

| Change | Result |
|---|---|
| `skills/skill-intelligence.json` | Machine-readable intents, specialists, canonical skill contracts, host profiles, ownership clusters and 63-entry parity map |
| `tools/resolve_skills.py` | Deterministic resolver; exactly one primary; explicit specialist/support; host adapter pointer resolution; dedupe; fail-closed unknown IDs |
| `evals/skill-routing-cases.json` | 18 representative routing cases with expected workflow and ordered skills |
| `tools/test_skill_intelligence.py` | Positive routing, invalid intent/specialist/skill, dedupe, canonical parity and missing-source tests |
| `AGENT.md`, `REGISTRY.md`, `workflows/routing.md` | Integrated resolver into task routing and clarified skill/workflow boundaries |
| `LEGACY-INVENTORY.md` | Replaced inaccurate 42-missing statement with source-backed parity decisions; clarified that root employee procedures remain active |
| `.claude/skills/security/godmode/SKILL.md` | Converted duplicate nested skill body to pointer to `.claude/skills/godmode/SKILL.md`; duplicate payload removed |

## Remaining risks / unverified

1. The resolver is deterministic and tested, but the LLM-to-intent classification step still requires live host/model evaluation.
2. Host-native Claude skill discovery is not certified merely because the files exist.
3. Runtime permission enforcement, memory persistence, delegation, browser access and tool behavior remain host-specific.
4. Two missing historical skill source bodies are not reconstructed.
5. This audit does not certify offensive security tooling or grant permission to use it; the Godmode source body is preserved unchanged at the canonical path.

## Acceptance criteria

- [x] One explicit primary intent is required by resolver.
- [x] Specialist and support selections are explicit and validated.
- [x] Unknown selections fail closed.
- [x] Duplicate skills are emitted once.
- [x] All 22 canonical skill files are enumerated and checked.
- [x] All 63 historical names have a disposition and rationale.
- [x] Missing source bodies are identified exactly.
- [x] No live model or host certification is claimed.
- [ ] Run live model/host classification benchmark in the target production host.
- [ ] Verify host skill discovery and tool permission boundaries in that runtime.

## Recommended next actions

1. Run the resolver with a complete `--decision-json` record as shown in `skills/REGISTRY.md`; missing decision evidence is rejected.
2. Run the portable validation and tests listed in `README.md`.
3. In the target host, evaluate all route fixtures against the actual model and record expected vs actual intent, specialists and loaded files.
4. Do not promote to production-certified until live host, security and behavioral gates pass.


## Independent 2.3.0 follow-up findings

A second audit found that the original 18 natural-language routing fixtures were not all aligned with the newer skill-intelligence catalog. In particular, generic research expected `agent-reach`/`system-analysis` rather than `web-research`, and generic release expected DBA without evidence of a database change. The 2.3.0 release corrects these mappings, expands the suite to cover all 30 primary intents and makes every natural-language route resolve through the same catalog.

The original resolver also accepted an unbounded number of specialist and support skills and did not require a structured selection rationale. Version 2.3.0 adds hard limits (one primary, max three specialists, max two support skills, max six unique skills), requires a decision record with evidence for each selected role, validates catalog schema and package-contained paths, and reports redundant role selections. A separate evaluator can score model-produced classifications; it does not invoke a model and has not yet been used for live model certification.
