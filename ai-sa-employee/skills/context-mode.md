# Skill: context-mode

## Purpose
Switch the employee's operating focus to a specific mode, loading only the relevant
memory files and behavioural rules for that context. Keeps responses sharp and
on-task for the current work type.

## Trigger
Invoke when the operator says "switch to [mode]", "enter [mode] mode",
"focus on [task] today", or starts a session with a clear intent
(e.g. "let's do requirements today", "let's review the risks", "challenge this plan").

---

## Core Project Modes

These five modes represent phases of a project engagement.
**New project order (strict):** DISCOVER → ANALYZE → DESIGN → CHALLENGE → PLAN
**Existing project:** enter any mode directly. Skipping prerequisites → warning + explicit assumption list.

---

### 📋 DISCOVER
**Focus:** Interviewing stakeholders, ingesting documents, extracting requirements, probing gaps.
**Entry trigger:** "gather requirements", "what do they need", "tell me about the project", "let's do requirements"
**Reads:** `memory/memory.md`, client record, project `requirements.md` (if exists)
**Writes:** `memory/clients/[client]/[project]/requirements.md` (REQ- entries)
**Chains to:** `gather-requirements`, `stakeholder-analysis`, `use-case-analysis`, `ingest-reference`, `ingest-meeting-notes`, `web-research` (brightdata — competitive analysis, regulatory lookup, technology research)
**Behaviour:** Confirm need vs. solution — capture the problem and outcome before any feature.
Probe edge cases, permissions, concurrency, and failure paths. No requirement without
testable acceptance criteria. Understanding Check before every new requirement set.

---

### 🔍 ANALYZE
**Focus:** Mental process flow, risk identification, constraint mapping, unknowns surfacing.
**Entry trigger:** "analyse the system", "map the process", "let's go deeper", "what are the risks?"
**Reads:** `memory/memory.md`, client record, project `requirements.md`, `risks.md`
**Writes:** `memory/clients/[client]/[project]/risks.md` (RISK- entries, flow diagrams, gap analysis)
**Chains to:** `process-analysis`, `use-case-analysis`, `risk-management`, `nfr-review`
**Behaviour:** Map as-is before to-be. Quantify pain: time, cost, error rate, handoffs.
Root-cause the real bottleneck (5 Whys), not the symptom. Surface hidden constraints.
Apply DBA lens — flag data/schema implications even if not asked.

---

### 🏗️ DESIGN
**Focus:** Architecture, tech stack decisions, solution components, ADRs, integration specs, DB design.
**Entry trigger:** "design the solution", "architecture", "tech stack", "what would it look like"
**Reads:** `memory/memory.md`, project `requirements.md`, `decisions.md`
**Writes:** `memory/clients/[client]/[project]/decisions.md` (ADRs, component specs, interface contracts)
**Chains to:** `solution-design`, `database-admin`, `create-diagram`, `nfr-review`
**Behaviour:** State architecture style and WHY in one paragraph. Define interfaces and contracts.
Record every decision as an ADR (context, options, decision, consequences). Proactively apply
database lens — flag schema risks, HA/DR gaps, performance implications.

---

### ⚡ CHALLENGE
**Focus:** Scope audit, feasibility check, cut/defer list, "what breaks this plan?"
**Entry trigger:** "is this realistic?", "challenge this", "puwede ba to?", "ano ba talaga ang scope"
**Reads:** `memory/memory.md`, project `requirements.md`, `decisions.md`, `risks.md`, `plan.md`
**Writes:** `memory/clients/[client]/[project]/decisions.md` (scope decisions, deferred items)
**Chains to:** `risk-management`, `scope-estimate`, `change-management`
**Behaviour:** Question every assumption. Force trade-off decisions (scope/time/cost/quality).
Produce a cut list and a defer list — be explicit about what is out of scope and why.
Never soften findings. A senior PM's job is to surface the uncomfortable truth early.

---

### 📅 PLAN
**Focus:** Task breakdown, WBS, scheduling, dependencies, milestones, developer assignments.
**Entry trigger:** "build the plan", "timeline", "WBS", "gawin na nating plan", "break this down"
**Reads:** `memory/memory.md`, project `requirements.md`, `risks.md`, `decisions.md`
**Writes:** `memory/clients/[client]/[project]/plan.md` (phases, milestones, WBS, critical path)
**Chains to:** `plan-project`, `scope-estimate`, `risk-management`
**Behaviour:** Build WBS before Gantt. Identify and name the critical path. Three-point estimates
(Optimistic/Most-likely/Pessimistic). Set milestones tied to deliverables, not dates alone.
Name what could blow the plan — feed findings to RISK- entries.

---

## Operational Support Modes

These modes are available at any time, independent of project phase.

---

### 🗄️ DATABASE
**Focus:** Database advisory — schema design, migration safety, performance, HA/DR, cost.
**Entry trigger:** "database", "schema", "migration", "query", "performance", "ERD", "HA/DR"
**Reads:** `memory/memory.md`, project `decisions.md`, any ingested schema/ERD KB entries
**Writes:** `decisions.md` (DB ADRs), RISK- entries, REC- entries, claude-mem (category:Database)
**Chains to:** `database-admin`
**Behaviour:** Apply full DBA expertise. Flag locking risks, data loss scenarios, compliance gaps.
Frame all findings in business impact terms — not just technical findings.

---

### 📊 STATUS
**Focus:** Status reporting, progress tracking, issue escalation.
**Entry trigger:** "status update", "progress report", "kamusta na?", "RAG report", "how are we doing"
**Reads:** `memory/memory.md`, project `plan.md`, `risks.md`, client record
**Writes:** RAG status report (see `memory/communication.md` template)
**Chains to:** `status-report`, `project-status`
**Behaviour:** Lead with RAG colour. Metrics before narrative. Surface RED/AMBER risks.
Always end with Decisions needed / Open questions / Next steps.

---

### 💬 ADVISORY
**Focus:** Drafting client-facing recommendations, answers, and communications.
**Entry trigger:** "advise the client", "what should we tell them", "draft a message"
**Reads:** `memory/memory.md`, client record, project `requirements.md`, `risks.md`, `decisions.md`
**Writes:** drafts only — never sends
**Chains to:** `advise-client`
**Behaviour:** Plain English, 50–100 words, one clear point per message.
Draft for the operator to review and send. Never send directly.

---

### 🧠 LEARN
**Focus:** Capturing outcomes, logging lessons, surfacing patterns.
**Entry trigger:** "done", "task complete", "got feedback", "lessons learned"
**Reads:** all `memory/` files
**Writes:** lessons to `memory/memory.md`, claude-mem KB entries, active task updates
**Chains to:** `end-of-task`, `learn-from-feedback`
**Behaviour:** Depth-checked lessons only — root cause + lesson, not just "fixed the bug".
Surface patterns after 3+ similar incidents.

---

### 🛠️ EXTEND
**Focus:** Creating or improving skills and memory files.
**Entry trigger:** "create a new skill", "add a skill for X", "update memory", "improve the system"
**Reads:** all `skills/` files, all `memory/` files
**Writes:** `skills/` folder, any memory file
**Chains to:** `new-skill`
**Behaviour:** Follow the canonical skill template exactly. Confirm before saving.

---

## Steps

1. **Identify the mode** from the operator's request.
2. **Confirm the mode** — output the name, focus, and active memory files.
3. **Load context** — read the relevant memory and project files for that mode.
4. **Acknowledge readiness** — one-line confirmation + what to provide next.
5. **Stay in mode** until the operator switches or the session ends.

---

## Output format

```
## MODE: [MODE NAME]

Focus: [What this mode does]
Memory loaded: [List of active files]
Next skill: [Which skill this chains to]

Ready. [One-line prompt for what to provide next.]
```

---

## Mode switching

- Switch any time with "switch to [mode]" or by invoking a new mode trigger.
- When switching, close the old mode and confirm the new one.
- For new projects, warn if switching out of order: "Skipping ANALYZE — noting assumption: [list]."
- Never carry over behavioural rules from the previous mode.

---

## Quality checklist

- [ ] Is the correct mode matched to the operator's intent?
- [ ] Are only the relevant memory files loaded for this mode?
- [ ] Is the output confirmation clear enough to know what to provide next?
- [ ] If chaining to another skill — has that skill's trigger condition been met?
- [ ] For new project out-of-order entry — were assumptions listed explicitly?
