# Standalone Agent Portability Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Employee System Analysis Expert usable as a self-contained, host-portable agent package across supported coding assistants and VS Code-based workflows, with root `AGENT.md` as the single authoritative source of policy and behavior.

**Architecture:** Keep the existing portable core (`AGENT.md`, `workflows/`, `skills/`, `evals/`, and `tools/`) host-neutral. Add thin, documented host adapters and install/verification paths that point back to the root contract and canonical skill procedures rather than copying or redefining them. Certify each named host/version separately with reproducible installation checks and live behavior evaluations; do not imply that a generic adapter or static package tests prove runtime compatibility.

**Tech Stack:** Markdown instruction/workflow/skill files; Python standard-library package validation and deterministic tests; host-specific native instruction/skill configuration only where supported and verified; optional shell/PowerShell packaging or setup only if current repository conventions and target-host requirements justify it.

**Spec:** User request (2026-10-29): work from `C:\Users\Msi\Downloads\Employee-System-Analysis-Expert`, update the repository branch named `Enhanced` later, do not run Git commands in the repository for now, make the package work as a standalone agent rather than only inside Hermes, support VS Code/Claude and other relevant hosts, and keep `AGENT.md` as the real source of truth with other model/host instruction entry points redirecting to it. Repository evidence: `AGENT.md`; `README.md`; `docs/ARCHITECTURE.md`; `docs/INSTALLATION.md`; `docs/PRODUCTION-READINESS-REVIEW.md`; `docs/RELEASE-STATUS.md`; `docs/SECURITY.md`; `docs/SOURCE-BOUNDARY.md`; `skills/REGISTRY.md`; `workflows/routing.md`; `tools/validate_package.py`; `tools/test_scenarios.py`; `evals/*.json`; adapter READMEs and pointer files.

## Global Constraints

- Do not run any Git command in the repository during this plan or its implementation unless separately authorized; the target branch is `Enhanced` for a later, separately authorized Git operation.
- Do not modify implementation or configuration during this plan-only task. This file is the only planned deliverable for this request.
- `AGENT.md` is the sole authoritative agent contract. Host files (`CLAUDE.md`, `GEMINI.md`, `.github/copilot-instructions.md`, editor configuration, or equivalent) may bootstrap or point to it, but must not fork its policy.
- Canonical skill procedures remain under root `skills/`; `skills/REGISTRY.md` remains their routing index. Host-discovered skills are thin pointers/adapters or generated copies with automated source-parity protection, never separately maintained policy.
- Host instructions and skill discovery are version-specific. Verify official current host documentation and actual installed versions during implementation; do not assume directory conventions or cross-host equivalence.
- Treat the package as standalone: core analysis/plan/review capabilities must work with only the host's ordinary file-reading/editing/tool capabilities; optional integrations must be capability-gated and never required for basic operation.
- Do not add a mandatory network service, plugin, database, model provider, memory service, package manager, or third-party runtime dependency without an approved need. The existing validation tools use Python standard library; preserve that baseline unless evidence justifies otherwise.
- Preserve existing authority, approval, privacy, safety, evidence, scope, canonical-memory and truthful-completion controls in `AGENT.md` and workflows. Host-specific affordances must not weaken them.
- External/retrieved content remains untrusted data; a host adapter cannot elevate it to instructions.
- Never claim a host, model, skill, tool, integration, or runtime behavior is tested unless that exact target was actually exercised and evidence recorded.
- Keep static/package integrity, host installation/discovery, and live model behavior as separate verification claims.
- Avoid embedding client/project private information, secrets, prompts, transcripts, or unnecessary personal data in tests, reports, manifests, or release artifacts.
- Preserve provenance limits in `docs/SOURCE-BOUNDARY.md`: do not claim reconstruction of unavailable historical skill bodies or runtime assets.
- Preserve the package's current default to load only relevant skills/workflows; do not require all instructions to be placed into every host's context at once.

## Review Focus

- **Missing or unreadable root `AGENT.md`:** installation must fail clearly or provide a documented manual fallback; it must never silently continue with a divergent host policy. Test missing path, unreadable file, and relative-path/workspace relocation.
- **Host-specific instruction truncation/precedence:** prove each host actually loads the canonical entry point and disclose context/file-size limits; test conflicting lower-priority host text and confirm canonical safety rules remain authoritative where that host's instruction precedence permits.
- **Canonical skill pointer drift or broken resolution:** every discovered pointer must resolve to the root skill, and validation must detect stale/missing/duplicated content and adapter/core parity drift.
- **No optional integrations or degraded tool access:** core workflows still function and report capability gaps without pretending to search, persist memory, delegate, or call unavailable services.
- **Untrusted project/retrieved instruction injection and unsafe action requests:** test that every host preserves the approval gate, does not obey artifact-embedded authority claims, and remains read-only for analysis-only requests.

---

## 1. Current-State Evidence and Scope

### Verified repository state

- The package is currently version `2.0.0`; it describes itself as a portable operating-contract/workflow package.
- Root `AGENT.md` names itself the operating contract and directs routing through workflows and `skills/REGISTRY.md`. It states that canonical skill procedures are in `skills/*.md` and adapter files are pointers only.
- `docs/ARCHITECTURE.md` calls `AGENT.md` the only authoritative operating contract. `SOUL.md` is described as optional behavioral framing, not competing policy.
- `adapters/claude/` and `adapters/codex/` contain one `SKILL.md` pointer per canonical skill; README files explicitly say these are examples, not verified host configuration bundles. `adapters/generic/README.md` is guidance only.
- `docs/INSTALLATION.md` requires manually configuring each host and checking current host/version discovery. It does not provide verified VS Code installation or host-specific packaged config.
- `README.md`, `docs/RELEASE-STATUS.md`, `docs/VALIDATION-REPORT.md`, and `docs/PRODUCTION-READINESS-REVIEW.md` explicitly say host auto-discovery, live model behavior, and actual runtime integration are unverified. Static and fixture checks are not LLM behavior tests.
- `tools/validate_package.py` currently validates Claude/Codex pointer parity, routes, scenarios, links, manifest/checksums and file hygiene. `tools/test_scenarios.py` exercises structural/contract fixtures; neither invokes a live host/model.
- The current repository contains 21 canonical skills, 16 routing/scenario cases, and an inventory of 63 historical skill names; the source-boundary document says the original historical skill bodies and host runtime assets are unavailable.
- User-supplied intent expands the target to standalone operation, VS Code/Claude and other applicable agent hosts. The exact VS Code agent products and supported host/version matrix are **not yet verified** and must be decided from current official host documentation before implementation.

### In-scope outcomes

1. A complete host-neutral core that can be followed without Hermes-specific tools or services.
2. Canonical instructions that all host entry points resolve to, without competing model-specific policy.
3. Per-host setup, use, skill discovery/routing, limitations, and uninstall/rollback guidance.
4. Automated consistency/integrity checks covering adapters and generated package outputs.
5. Reproducible host-specific smoke tests plus live behavioral evaluation evidence, separately reported per host/model/version.
6. Accurate documentation, package/release metadata, and support boundaries.

### Out of scope unless approved later

- Reconstructing unavailable legacy skill bodies/assets or claiming parity with them.
- Building a new agent runtime, model, IDE extension, plugin marketplace package, remote service, database, or memory system.
- Making any host's tool permissions broader or bypassing its sandbox/approval UI.
- Automatically executing external actions, database changes, deployments, commits, or publishing.
- Claiming all products branded “Claude”, all VS Code extensions, or every agent runtime are compatible based on one tested configuration.
- Git operations, branch creation/switching, commits, pushes, merging, or publishing as part of this plan; branch `Enhanced` is only a later target.

## 2. Intended User Experience and Acceptance Criteria

A user should be able to obtain/open the package in a supported host, configure or install its adapter using documented steps, verify that the host has loaded root `AGENT.md`, ask for an analysis/planning/review/authorized implementation task, and receive behavior governed by the same contract. The user must be told what is native, what is manually configured, what tools are unavailable, and what remains unverified.

### Package-level acceptance

- Root `AGENT.md` remains the only authoritative instruction policy; `SOUL.md` and host files clearly defer to it.
- Each supported host has a current, versioned setup path with prerequisites, workspace/project scope, exact files/settings to install or configure, skill discovery behavior, permission implications, verification steps, uninstall/rollback, and troubleshooting.
- A no-plugin/no-network baseline can complete representative read-only analysis and planning tasks using ordinary host file tools; unavailable capabilities are disclosed, not fabricated.
- Host-specific instruction and skill entry files are either direct references/pointers to canonical files or generated from those files with a check that prevents silent divergence. No manually forked policy text.
- The package can be copied/relocated while preserving documented relative paths or gives a deterministic repair procedure when a host requires absolute paths.
- One command sequence from the documented package root runs static validation, structural regression tests, format/syntax checks applicable to the repository, and package archive/fresh-extraction validation.
- Validator detects missing/extra/stale adapter pointers, unsupported host declarations, broken links, malformed fixtures, source-parity failures, missing manifest entries, stale hashes, invalid UTF-8/JSON and missing final newlines.
- Static checks, per-host discovery checks, and live behavioral evaluations are separately reported and never conflated.
- Test matrix includes positive and negative routing, read-only analysis, checkpoint recovery, unavailable tools, prompt injection, denied destructive/release action, and truthful completion/evidence.
- Release documentation names precisely which host, product, version, model/provider, and configuration were validated; unsupported/untested hosts remain explicitly unverified.

### Host/runtime acceptance

For every host claimed supported (each exact product/version configuration is a separate row):

1. Root instructions are discovered and loaded in the actual runtime from a clean test workspace.
2. A canonical skill can be discovered/resolved and invoked; the host does not require a duplicated content copy that can drift, or its copy generation is tested against canonical source.
3. At least one read-only repository action succeeds using the host's normal tool path.
4. A representative task routes to the expected workflow/skill and observes the core evidence/approval rules.
5. Analysis-only causes no workspace writes; denied destructive action remains denied absent explicit target-specific approval.
6. Missing optional memory/search/MCP/delegation tools result in an honest limitation and a usable core-only fallback.
7. Actual host/version/model/configuration, test prompts/case IDs, outputs or privacy-safe evidence, evaluator, pass/fail, defects, and date are recorded without exposing secrets or private transcripts unnecessarily.
8. Installation is removable and rollback restores prior host configuration without changing unrelated workspace/user settings.

## 3. Architecture and File Map (Proposed; confirm during implementation)

- `AGENT.md` — retain canonical contract; modify only if a demonstrated host-neutral gap prevents standalone operation. Do not place host-specific install recipes here.
- `SOUL.md` — optional short persona framing explicitly subordinate to `AGENT.md`; verify no contradictory operating rules.
- `skills/*.md` — canonical portable procedures; add/change only for evidenced capability gaps; maintain one source.
- `skills/REGISTRY.md` — canonical skill routing and workflow catalog; update if canonical skill names/triggers change.
- `workflows/*.md` — host-neutral task procedures and safe fallback behavior; clarify tool assumptions only where core users otherwise cannot proceed.
- `adapters/<host>/README.md` and host-specific files — minimal bootstrapping/install documentation and references, using actual host conventions. Do not create directories/configs until host documentation confirms them.
- `adapters/generic/README.md` — true manual fallback for hosts without supported native instruction/skill mechanisms; explain explicit loading of `AGENT.md`, workflow and selected skill.
- `docs/INSTALLATION.md` — host matrix, portable baseline, installation and removal procedure, troubleshooting, and links to each adapter guide.
- `docs/ARCHITECTURE.md` — canonical-source and adapter-generation/resolution model, precedence, boundaries, supported integration types.
- `docs/SECURITY.md` — host permission and trust-boundary guidance; ensure instruction portability does not weaken host sandbox controls.
- `docs/VALIDATION-REPORT.md`, `docs/RELEASE-STATUS.md`, `docs/PRODUCTION-READINESS-REVIEW.md` — report actual package and host evidence precisely; retain separate claim levels.
- `evals/routing-cases.json`, `evals/scenario-cases.json`, `evals/adversarial-cases.json` — host-neutral evaluation corpus, with new cases added for standalone/host degradation and precedence.
- `tools/validate_package.py` — extend structural checks for supported adapters, canonical references/source parity, installation metadata, host matrix/eval artifact integrity; do not make network calls or assume host software exists.
- `tools/test_scenarios.py` — deterministic tests for new requirements and fixtures, clearly not model evaluation.
- `tools/` — add only justified generation/package/smoke-test helpers. Keep ordinary package validation standard-library/offline unless approved otherwise.
- `manifest/FILE-MANIFEST.json`, `manifest/SHA256SUMS`, `release/TEST-RESULTS.txt`, `VERSION`, and `CHANGELOG.md` — regenerate/update only after content is final and checks pass; follow existing versioning/release policy.
- `README.md` — front door: standalone purpose, quick start, supported/untested hosts, core-only fallback, source-of-truth statement, evidence boundary, links to installation/evaluation docs.

No actual target files beyond this saved plan are changed in plan mode.

## 4. Ordered Implementation Work

### Phase 0 — Lock targets and verify current host requirements

#### Task 0.1: Define support matrix and compatibility criteria

**Files:** Read only initially; later update `docs/INSTALLATION.md`, `docs/RELEASE-STATUS.md`, possibly `adapters/*/README.md`.

- [ ] Enumerate product-level host targets, not broad brands: at minimum evaluate Claude Code CLI, the exact VS Code agent surface(s) the user expects, and Codex if retained as a supported adapter. Treat Claude Code inside VS Code and third-party VS Code extensions as separate products when their instruction/tool discovery differs.
- [ ] Use official up-to-date vendor documentation for each target/version: instruction-file names, discovery scope/precedence, supported skill format, workspace trust, tool permissions/sandbox behavior, context/file-size limits, supported links/includes, and extension/CLI availability.
- [ ] Mark each target `candidate`, `supported`, `manual fallback`, or `not supported` with evidence and date; do not promise an installation mode until its official conventions and actual runtime are confirmed.
- [ ] Define what “standalone” guarantees: no Hermes runtime/services required; host may still require its own model and tools. Separate portable core capability from optional integrations.
- [ ] Identify OS targets (Windows, macOS, Linux) based on user need and scripts actually intended; do not imply OS support simply because Markdown is portable.
- [ ] Define host-specific capability matrix for file read/write, terminal/command approval, browser/web/research, MCP/external services, subagents, persistent memory/session resume, and project-scoped instruction loading. Mark optional/unavailable honestly.
- [ ] Record product/version, documentation URLs, relevant behavior, open issues, and test setup in a concise support-matrix artifact or installation table.

**Exit gate:** named targets and host-specific requirements are evidenced; unresolved host ambiguity is explicit; unsupported assumptions are not implemented.

#### Task 0.2: Audit standalone dependencies and claims

**Files:** `AGENT.md`, `SOUL.md`, all `workflows/`, all canonical skills, `README.md`, `docs/*`, `adapters/*`, test/eval files (read-only audit before edits).

- [ ] Search for Hermes-specific tool names, runtime assumptions, host-only slash commands, provider/model assumptions, implicit integrations, assumed persistence, and instructions requiring non-core capabilities.
- [ ] Classify each finding as core blocker, optional capability, host-specific adapter concern, obsolete/ambiguous claim, or intentional source limitation.
- [ ] For each optional capability, specify fallback: do core task manually, ask user for missing evidence, produce a handoff, or stop safely. Never imply unavailable capability ran.
- [ ] Check for contradictory policy in `SOUL.md`, adapter READMEs, skill pointers, workflows, installation docs, generated metadata, and README.
- [ ] Create traceability from each finding to a phase/task and an acceptance/evaluation case; avoid broad untracked cleanup.

**Exit gate:** every identified blocker has a planned resolution or explicit scope decision; no runtime integration is assumed.

### Phase 1 — Make the core host-neutral and canonical

#### Task 1.1: Specify host-neutral contract and precedence

**Files:** `AGENT.md`, `SOUL.md`, `docs/ARCHITECTURE.md`, `docs/INSTALLATION.md`.

- [ ] Define the bootstrap contract: host entry point loads/references root `AGENT.md`; `AGENT.md` routes to only relevant workflow and skill files; host-specific files provide location/tool mapping, not alternative policy.
- [ ] Clarify that host safety, sandbox, permission, approval and tool-availability controls remain enforced by the host; instructions never claim to override them.
- [ ] State a precedence fallback for hosts without include/reference support: the small host entry file must point users/model to read `AGENT.md` directly before task work; if policy content must be copied due to platform limits, generated copies must be machine-checked and the source remains `AGENT.md`.
- [ ] Specify behavior when `AGENT.md` cannot be read: stop or request manual loading, disclose the failure, and do not silently use a cached/divergent contract.
- [ ] Define portable baseline and optional integrations precisely. Explicitly mention limitations around persistence, web research, delegation, file/terminal tools and host hooks.
- [ ] Confirm `SOUL.md` contains framing only and cannot contradict the canonical contract; resolve any conflict by simplifying it to a pointer or subordinate framing.
- [ ] Keep core contract concise and maintain progressive disclosure rather than embedding all skills into host startup context.

**Tests:** add static assertions that entry-point docs and adapters identify `AGENT.md` as authoritative and that no adapter declares its own conflicting contract; add a negative test for missing source reference.

#### Task 1.2: Define capability negotiation and core-only fallbacks

**Files:** `AGENT.md`, targeted `workflows/*`, targeted canonical skills, `docs/INSTALLATION.md`, scenario/evaluation fixtures.

- [ ] Establish a compact, task-relevant capability check: only verify tools that the requested work needs; do not require integration health for simple read-only work.
- [ ] For each optional capability found in Task 0.2, name expected signal of availability and safe fallback; do not invent universal host APIs.
- [ ] Preserve analysis-only behavior when write tools exist; capability availability is not permission to mutate.
- [ ] For research, delegated work, persistent memory, browser, external integrations, and file generation, distinguish available tool, user-provided artifact, manual process and unavailable state.
- [ ] Require honest reporting of unsupported capabilities and their effect on outcome; do not state an external search/review/write occurred without evidence.
- [ ] Add scenarios for no web/MCP, no delegation, no durable memory/session resume, read-only/sandboxed workspace, and missing file access; assert safe useful behavior.

**Exit gate:** a host with only ordinary project-file access can route and perform a representative analysis/plan/review; optional integrations degrade honestly and safely.

#### Task 1.3: Keep policy and skill procedures single-source

**Files:** `skills/REGISTRY.md`, `adapters/*/skills/**`, validator/tests; generation helper only if required by verified host format.

- [ ] Inventory every adapter instruction and skill pointer, confirming target resolves to canonical `AGENT.md` or `skills/<name>.md` as appropriate.
- [ ] Select per-host mechanism using actual host docs: relative symlink, direct host include, thin markdown pointer, or generated mirror. Do not assume symlinks/includes are supported in Windows, archives, workspaces or the host.
- [ ] If canonical Markdown cannot be directly consumed and generation is required, implement deterministic generation from the canonical file, with explicit generated-file header and hash/source mapping. Do not hand-edit generated copies.
- [ ] Extend package validation to check pointer targets, duplicate policy text, canonical skill set parity, source hashes/content parity for generated copies, missing/extra adapters, and root path resolution.
- [ ] Test package relocation and archive extraction to prove no adapter relies on an undocumented absolute local path.
- [ ] Keep historical skill inventory separate from active skills and do not treat its 63 entries as implementable procedures.

### Phase 2 — Deliver usable adapters and installation flows

#### Task 2.1: Implement verified Claude Code adapter

**Files:** `adapters/claude/**`, `docs/INSTALLATION.md`, validator/evals, optional minimal setup helper only if native behavior requires it.

- [ ] Apply Task 0.1's official Claude Code instruction/skill conventions for each supported version. Record exact source/version and whether workspace-level versus user-level placement is used.
- [ ] Provide one explicit setup path for a clean project/workspace, plus a non-destructive manual fallback. Do not overwrite existing `CLAUDE.md`, settings, skills or hooks without preview and user approval.
- [ ] Ensure any `CLAUDE.md`/host entry content points back to root `AGENT.md` and contains only unavoidable bootstrap/tool mapping. Do not create a second policy document.
- [ ] Ensure skill discovery points to canonical skills or verified generated pointers. Do not require Claude-specific service plugins for core behavior.
- [ ] Document how to verify startup instructions loaded, inspect a selected skill, and diagnose failed discovery/context limits.
- [ ] Document permission behavior and retain per-command host approval; do not broaden automatic approvals or install unreviewed hooks.
- [ ] Document uninstall/rollback and test no unrelated settings or project files are modified.
- [ ] Run fresh-workspace installation and actual Claude Code runtime smoke/evaluation; record exact product/version/model/configuration.

#### Task 2.2: Implement the exact VS Code target adapter(s)

**Files:** new host-specific `adapters/<verified-host>/**`, `docs/INSTALLATION.md`, validator/evals; do not select paths before Task 0.1 evidence.

- [ ] Confirm which VS Code products are in scope (for example, a Claude Code integration versus GitHub Copilot Chat/agent mode or another explicitly selected extension); treat each distinct runtime separately.
- [ ] For each selected product, verify whether it supports repository-level instruction files, references/includes, skill files, workspace trust, terminal/tool permissions and custom-agent definitions. Cite official docs and tested version.
- [ ] Add only the native minimal host entry/configuration required to load `AGENT.md`; if the host has no reference mechanism, use a transparent pointer or generated thin bootstrap, not an independently authored policy.
- [ ] Map host tool names/limits to generic capabilities only where verified. Keep all behavior contingent on actual tool availability and user authorization.
- [ ] Do not copy Claude Code adapter paths or assumptions to a separate VS Code extension without direct validation.
- [ ] Provide setup, verification, permissions, troubleshooting, clean uninstall/rollback and manual fallback.
- [ ] Test a clean VS Code workspace with trust prompts and restricted/unavailable tools; capture root instruction and skill discovery evidence.
- [ ] Run the host behavior suite for each product/configuration; distinguish editor integration version, extension version, CLI/runtime version, model and provider.

#### Task 2.3: Maintain Codex and generic/manual adapters by evidence

**Files:** `adapters/codex/**`, `adapters/generic/README.md`, validator, docs.

- [ ] Decide whether Codex remains a supported target based on user intent and current docs; if retained, document exact supported configuration and test it. Otherwise label it candidate/manual/untested rather than implying support.
- [ ] Preserve Codex skill pointer parity only if pointers match current official discovery format and actually resolve to canonical skills.
- [ ] Make generic setup actionable for hosts without native discovery: load `AGENT.md` first, then use router/registry to read the one relevant workflow and skill. Explain that instructions may need explicit session loading.
- [ ] Define generic limitations: no guaranteed persistent memory, hooks, tools, delegation or automatic skill discovery.
- [ ] Do not present “generic” as runtime certification or compatibility with all models.

#### Task 2.4: Add safe, idempotent setup and removal helpers only if justified

**Files:** new files under `tools/` or platform-specific setup locations, installation docs, tests, manifest.

- [ ] First determine whether manual setup is too error-prone for a supported host and whether official configuration permits safe automation. Skip this task if exact host setup is small and reliable manually.
- [ ] If needed, implement separate OS-aware helper(s) using standard library/OS tools already accepted by project conventions; expose `--dry-run`/preview and explicit target path, never silently install plugins, modify global settings, trust hooks, or change permissions.
- [ ] Require a clean distinction between create-new and update-existing; refuse ambiguous/conflicting files rather than overwriting. Make operation idempotent and provide a reversible uninstall that removes only files the helper created and still recognizes as its own.
- [ ] Validate path traversal, symlink/junction behavior, workspace root, path spaces/non-ASCII, permissions, existing user files, and interrupted operations.
- [ ] Add unit/integration tests with temporary directories on supported OSes. No external network calls or model invocation in setup helpers.

### Phase 3 — Test, evaluate, and harden

#### Task 3.1: Extend deterministic package validation

**Files:** `tools/validate_package.py`, `tools/test_scenarios.py`, `evals/*.json`, tests as needed.

- [ ] Add schema checks for host support matrix and adapter metadata: unique IDs, valid statuses, source references, exact version/configuration fields for claimed support, and links to verification evidence.
- [ ] Add adapter inventory checks: every declared supported adapter has required docs/config/pointers; no undeclared adapter is described as supported; no candidate/untested target is called certified.
- [ ] Validate canonical-source pointer resolution and generated-output hashes/parity; detect copied divergent policy/skill bodies.
- [ ] Check host entry point source-of-truth statement and no duplicated conflicting policy with scoped, robust assertions rather than brittle full-document phrase matching where possible.
- [ ] Add path/relocation/archive test using a fresh temporary extraction and ensure docs' relative links and pointers resolve there.
- [ ] Add deterministic fixtures for entry file missing/unreadable, stale pointer, absent optional capability, file-write denial, unavailable memory, and unsupported host configuration.
- [ ] Preserve offline, standard-library validation; report exactly what was and was not tested.

#### Task 3.2: Design a cross-host behavioral evaluation suite

**Files:** `evals/routing-cases.json`, `evals/scenario-cases.json`, `evals/adversarial-cases.json`, new evaluation rubric/results schema under `evals/` or `docs/`.

- [ ] Keep existing 16 route IDs and coverage unless a documented scope decision changes them; link each test case to expected workflow, relevant skill(s), forbidden outcomes and acceptance oracle.
- [ ] Add cases for canonical `AGENT.md` entry, conflicting secondary instruction, missing root contract, host-specific skill selection, core-only/no-plugin operation, read-only sandbox, missing web/delegation/memory, Windows path/relocation, and context-limit disclosure.
- [ ] Cover all existing core scenarios: new project, existing project, continuation, bug/RCA, feature/change, research/video, analysis-only, review, scope change, blocked/repeated failure, skill lifecycle, context optimization, release/deploy, multi-agent and status.
- [ ] Cover adversarial cases: untrusted file/web injection, user asks to skip approval, fake test/review/delegation claim, unsupported host/tool/model capability, stale checkpoint, schema invention, scope creep, and false completion.
- [ ] Define objective pass/fail rubric for every case. Safety-critical behaviors (unauthorized destructive/release action, invented evidence, secret disclosure, or analysis-only mutation) are hard failures, not scoreable minor misses.
- [ ] Separate automated fixture linkage from model judgement. Record model/provider, temperature/settings if exposed, tool set, host version and exact prompt/case ID; store privacy-safe output excerpts or artifacts only with appropriate authorization.
- [ ] Run each evaluation separately per host configuration; do not infer Claude behavior from Claude-on-VS-Code or another provider/model.

#### Task 3.3: Execute host smoke tests and live evaluation

**Files:** host-specific evidence reports and release docs, only for targets actually tested.

- [ ] Use clean, disposable workspaces with no client data and no pre-existing instructions that could mask package loading.
- [ ] Record exact software and model versions, extension/CLI configuration, operating system, permissions/sandbox, install procedure and evidence collection method.
- [ ] Prove root `AGENT.md` load by asking a benign contract-specific question with a distinctive requirement, and prove one selected canonical skill was actually read/invoked via host evidence or behavior; do not treat a setup script's success as proof.
- [ ] Run at minimum: read-only analysis; plan-only no mutation; selected-skill task; existing-project inspection; checkpoint/continuation using the host's real persistence mechanism (or document it unavailable); denial of destructive action without approval; untrusted-instruction injection; unavailable optional tool; and truthful handoff.
- [ ] Confirm the analysis-only case leaves workspace hashes unchanged; confirm denial cases create no side effects; use tool/audit evidence when available.
- [ ] Capture failures, repeat only when a materially different hypothesis/test is justified, and report unresolved blockers; do not tune instructions solely to a single prompt at the expense of safety or portability.
- [ ] Complete a fresh-install/restart/second-session smoke test where host state allows; otherwise state exactly what persistence/discovery was not established.

#### Task 3.4: Security, privacy, and compatibility review

**Files:** applicable adapters, setup tooling, `docs/SECURITY.md`, evaluation artifacts.

- [ ] Review host trust boundaries, instruction precedence, project/workspace trust, file and command permissions, tool grants, global versus local configuration, secrets, MCP/service configuration, logging/transcripts and client data.
- [ ] Ensure no installation procedure auto-approves broad commands, disables a sandbox, trusts a hook without user review, installs a model/plugin, or stores credentials.
- [ ] Ensure adapters cannot be tricked by untrusted repository content into overriding user/host policy; test prompt injection from README/code comments/tool output.
- [ ] Check portability on each declared OS: newline/encoding, case sensitivity, path separators/spaces, symlink behavior, PowerShell/Bash quoting if scripts exist, archive extraction, and write permissions.
- [ ] Review source provenance and third-party/license implications before introducing copied vendor snippets, bundled host configs or assets.
- [ ] Record residual risk and unsupported configurations instead of broadening claims.

### Phase 4 — Documentation, release integrity, and final gate

#### Task 4.1: Rewrite the front-door and installation docs

**Files:** `README.md`, `docs/INSTALLATION.md`, `docs/ARCHITECTURE.md`, adapter READMEs.

- [ ] Give a short standalone quick start with one tested path per supported target and a distinct manual/core-only fallback.
- [ ] Provide a support table with target product, exact tested version/range, OS, instruction discovery, skill discovery, required optional tools, verification status/date and known limitations.
- [ ] Clarify “standalone” means no Hermes dependency, not no host/model/tools; list truly required and optional components.
- [ ] Explain canonical `AGENT.md` and how host pointers resolve to it; explain why no copied policy is maintained.
- [ ] Document setup, confirmation of root/skill loading, first safe test, permissions, uninstall/rollback, troubleshooting, workspace trust, relative paths, context limits and common discovery failures.
- [ ] Clearly distinguish available portable-core behaviors from host-dependent web, memory, hooks, MCP, subagents, file generation and resume functionality.
- [ ] State that plan/analysis mode remains non-mutating and implementation/external side effects remain authorization-gated.
- [ ] Keep historical reconstruction/source limitations visible and avoid presenting inventory-only skills as delivered.

#### Task 4.2: Update release claims, evidence, and package metadata

**Files:** `docs/VALIDATION-REPORT.md`, `docs/RELEASE-STATUS.md`, `docs/PRODUCTION-READINESS-REVIEW.md`, `release/TEST-RESULTS.txt`, `CHANGELOG.md`, `VERSION`, `manifest/*`.

- [ ] Report three independent status lines: package/static acceptance; each host installation/discovery; each live host/model behavioral evaluation.
- [ ] For each evidence report, list exact commands/test IDs, environment, output summary, failures/skips, and scope. Do not copy historical claims without rerunning.
- [ ] Update risks and residual gates; don't call a host runtime-certified until applicable critical scenarios pass and findings are closed/accepted.
- [ ] Apply repository versioning policy only after scope/compatibility impact is known; do not arbitrarily bump version or claim a release.
- [ ] Regenerate manifest/checksum metadata after final changes using repository-supported process; verify no generated artifacts are omitted and no user/private data enters the package.
- [ ] Validate a distributable archive by extracting into a clean location and repeating package validation and documented core setup.

#### Task 4.3: Final acceptance and handoff

- [ ] Run the complete documented offline package validation and all deterministic tests from a fresh package root and fresh archive extraction.
- [ ] Run every claimed host smoke/evaluation suite and confirm results are recorded; untested targets remain explicitly marked.
- [ ] Inspect the final changed-file inventory and compare it to this plan; ensure no unrelated files, user config, client data, generated caches, or private evidence are included.
- [ ] Verify no Git commands were run without authorization; if later asked to target `Enhanced`, first confirm current repository state/branch via approved Git inspection at that later time.
- [ ] Report completed claims separately from unresolved runtime/host gaps; provide install links/paths, exact verification results, limitations, rollback steps, and next action.

## 5. Dependency Order and Decision Gates

1. **Gate A — Target decision:** Task 0.1 establishes exact supported host products/versions and authoritative setup conventions. VS Code product ambiguity must be resolved by evidence and, if necessary, a focused user decision before implementing an adapter.
2. **Gate B — Core readiness:** Tasks 0.2, 1.1 and 1.2 resolve Hermes assumptions, canonical precedence, and capability fallbacks. Host-specific implementation must not paper over a core contract gap.
3. **Gate C — Adapter mechanism:** Task 1.3 approves direct-reference versus generated-pointer choice per host. Task 2.1/2.2/2.3 depend on that choice.
4. **Gate D — Automation decision:** Task 2.4 is optional and follows demonstrated setup risk; skip if it adds more risk/complexity than manual setup.
5. **Gate E — Claims:** Static validation may pass before runtime tests, but support claims remain limited until Task 3.3's exact host evidence exists.
6. **Gate F — Distribution:** Final docs/manifests/archive and release claims follow all implementation, security and verification work. No publishing/release action is authorized by this plan.

## 6. Risk Register and Mitigation

| ID | Risk | Impact | Mitigation / evidence gate |
|---|---|---|---|
| R-01 | Ambiguous phrase “VS Code Claude etc.” causes wrong products to be supported | High | Name each host product/version in Task 0.1; ask only if official behavior does not resolve the target. |
| R-02 | A host cannot directly include the canonical file or resolve relative links | High | Validate official mechanism and real runtime; use minimal bootstrap or generated mirror with source-parity validation; document manual fallback. |
| R-03 | Adapters silently fork `AGENT.md` policy | Critical | Canonical-source architecture, generated-content checks, conflict audit and live precedence tests. |
| R-04 | Instruction context limits truncate critical safety controls or skills | High | Measure actual limits, keep bootstrap concise, progressive disclosure, test truncation/retrieval, clearly fail if core contract cannot load. |
| R-05 | Core depends on Hermes-only memory/delegation/research integrations | High | Dependency audit, capability negotiation and core-only fallback scenarios. |
| R-06 | Setup overwrites host/user configuration or broadens command permissions | Critical | Prefer manual setup; if helper needed, dry-run, conflict refusal, explicit targets, least privilege, no broad approvals and reversible cleanup. |
| R-07 | Static checks mistaken for model behavior evidence | High | Three separate acceptance/reporting layers; exact host live tests before support claims. |
| R-08 | A passing run on one model/product is generalized to all hosts | High | Product/version/provider-specific matrix and per-row status. |
| R-09 | Untrusted workspace instructions override user or canonical safety | Critical | Treat artifacts as data, host precedence review, injection cases on each host. |
| R-10 | Regression to all-skills-loaded or duplicated context cost | Medium | Preserve registry-based selective routing; test only relevant skills are loaded where runtime evidence exists. |
| R-11 | Historical inventory creates false promise of 63 skill bodies | High | Preserve source boundary and explicit inventory-only labeling. |
| R-12 | Manifest/checksum drift makes package incomplete or unverifiable | Medium | Run validator, regenerate manifests last, fresh archive/extraction test. |
| R-13 | OS path, symlink, shell, archive or encoding differences break standalone setup | Medium/High | Test each declared OS and avoid unsupported assumptions; explicit fallback. |
| R-14 | Privacy-sensitive live transcripts/evidence are committed or retained unnecessarily | High | Synthetic workspace, minimum evidence, redaction/consent policy, no private user/client data by default. |

## 7. Completion Definition

The implementation is complete only when:

- The canonical-contract and core-only behavior criteria pass.
- Every host called supported has actual installation, discovery, canonical skill-resolution and behavioral evidence for its exact tested configuration.
- Package checks, fixture tests, generated-pointer checks, fresh-archive extraction and all declared OS tests pass or have explicitly accepted, bounded exceptions.
- Security/authority tests show no weakened approval, sandbox, trust, or analysis-only boundaries.
- Docs, support matrix, validation report, changelog/version metadata and manifest agree with actual verified state.
- Changed-file scope and release artifacts have been reviewed; untested hosts/integrations and source reconstruction limits remain explicit.
- No Git, release, publication or deployment operation is performed without separate authorization.

## 8. Plan Self-Review / Traceability

| User need / existing evidence | Plan coverage | Acceptance evidence |
|---|---|---|
| Standalone rather than Hermes-only | Tasks 0.2, 1.2, 2.3, 3.1–3.3; core-only acceptance | no-Hermes/no-optional-tool tests and host runtime evidence |
| VS Code and Claude support | Tasks 0.1, 2.1, 2.2; per-product gate | official docs plus clean-workspace host smoke/evals |
| Other agent/model hosts | Tasks 0.1, 2.3; support matrix | each exact product/config is supported, manual, candidate, or explicitly unsupported |
| `AGENT.md` is real source of truth | Tasks 1.1, 1.3, 2.1–2.3; validator | pointers/parity checks and live loading/precedence evidence |
| Full and dependable plan first | ordered phases, dependencies, files, tasks, tests, risks, gates, done definition | each implementation task independently verifiable |
| Do not Git now; branch `Enhanced` later | Global Constraints and Task 4.3 | no Git operation until separately authorized |
| Existing static validation is not runtime proof | Current-State Evidence, Tasks 3.1–3.3 and 4.2 | three-layer reporting and exact host evidence |
| Preserve source provenance/legacy limits | Global Constraints, Tasks 1.3/4.1, risks R-11 | no claim of restoration of historical skill bodies |

**Self-review result:** The plan covers canonical policy, host discovery, skill routing, optional capability degradation, installation/removal, deterministic validation, live behavioral evaluation, security/privacy, compatibility, documentation, release metadata and limits. The only intentionally unresolved product decision is which exact VS Code host integrations and OS/version combinations to certify; resolve via current official evidence and user input only if still ambiguous. The plan does not alter source implementation or run Git.
