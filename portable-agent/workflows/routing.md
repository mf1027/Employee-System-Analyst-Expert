# Routing Matrix

| Intent | Primary workflow | Skill(s) commonly relevant | Exit condition |
|---|---|---|---|
| New project | `new-project.md` | requirements, system, domain, architecture, planning, NFR, risk | approved baseline and ready plan |
| Existing project | `existing-project.md` | system-analysis, context-economy | verified current state and bounded task |
| Resume | `continuation.md` + `continuation-contract.md` | checkpoint reconciled and resumed/blocked |
| Bug | `diagnosis.md` | evidence-backed RCA and approved fix verified or handed off |
| Feature/change | `feature-change.md` | impact/acceptance/baseline delta approved |
| Research/video | `research.md` | `web-research` for external research; `video-intelligence` for audiovisual evidence |
| Analysis only | `analysis-only.md` | findings/options/recommendation, no mutation |
| Comprehensive analysis | `comprehensive-analysis.md` | coordinated requirements/system/process/RCA/GAP/risk/specialist coverage; no mutation unless separately authorized |
| Review | `review-acceptance.md` | findings/verdict and evidence |
| Scope change | `scope-change.md` | impact and decision recorded |
| Blocked | `blocked-task.md` | blocker resolved or safely handed off |
| Skill lifecycle | `skill-lifecycle.md` | skill validated, routed, documented |
| Reference ingestion | `reference-ingestion.md` | relevant source facts distilled with provenance into existing canonical memory |
| Context optimization | `context-optimization.md` | quality-preserving improvement verified |
| Release/deploy | `release.md` | authorized release with post-checks or explicit stop |
| Multi-agent | `multi-agent.md` | coordinated outputs integrated and verified |
| Status | `project-status.md` | truthful status, risks and next action |

Load the `skills/REGISTRY.md` for skill triggers and canonical filenames. Route cases in `evals/routing-cases.json` are expected routing fixtures; they do not demonstrate live model selection.

## Deterministic skill resolution

After choosing the dominant workflow, classify exactly one primary intent and only evidenced specialist domains. Record the primary deliverable, trigger evidence, evidence for each specialist, the distinct output needed from each support skill, excluded candidates and uncertainty. Pass this record as required `--decision-json` to `python tools/resolve_skills.py`. The resolver enforces one primary, at most three specialists, at most two support skills and six unique skills total. Overflow, missing evidence and unknown IDs fail closed. Redundant role selections are deduplicated and reported. The resolver does not infer intent from raw text, load files, or grant tools/permissions.

When the resolver is unavailable, apply the same rules manually and disclose the fallback. Never load all skills to avoid making a routing decision.
