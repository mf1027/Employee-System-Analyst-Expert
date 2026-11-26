# Portable installation and host setup

## Supported meaning

“Standalone” means this package does not require Hermes or its plugins/services. It still requires an agent host, a model/provider, and whatever tools that host exposes. The host's sandbox, trust, and permission controls remain in force. Core analysis and planning should work with ordinary project-file reading; optional web, memory, MCP, hooks, delegation, and file generation are not assumed.

Root `AGENT.md` is the sole policy source. Root `AGENTS.md` is the cross-host bootstrap pointer: it directs the host to read `AGENT.md` before work. If host discovery is not confirmed, use the generic manual setup below and explicitly load `AGENT.md` each task. Do not claim automatic discovery without runtime evidence.

## Generic manual setup (available now)

1. Open the package root in the agent host/workspace and keep its relative layout intact.
2. In the host task, explicitly request reading root `AGENT.md` before work. If it cannot be accessed, stop instead of substituting a different policy.
3. Follow its task router; read only relevant workflow(s) and canonical skill(s) under `skills/`. For skill selection, use `skills/REGISTRY.md`.
4. Start with a harmless read-only request. Confirm the host can actually read those files and report unavailable tools honestly.
5. Do not treat this manual setup as evidence of automatic discovery or live host certification.

## Host compatibility matrix

This is a documentation-based compatibility matrix, not a certification. The local CLI binaries were observed as Claude Code `2.1.317` and Codex `0.154.0` on 2026-11-24. Their non-interactive help was inspected; no model request or authenticated runtime smoke test was run.

| Product/runtime | Official discovery guidance | Safe package setup | Evidence/status |
|---|---|---|---|
| Claude Code CLI | Anthropic says `AGENTS.md` can load as project instructions in place of `CLAUDE.md`, but only when no nearer `CLAUDE.md`/`CLAUDE.local.md` applies; direct `AGENTS.md` support requires v2.1.277+. The docs note some configurations needed v2.1.281+. | Keep root `AGENTS.md` as bootstrap. Check config/precedence and `/memory` or `/context`; if not loaded, explicitly provide root `AGENT.md`. | Docs reviewed 2026-11-24; local CLI 2.1.317; live loading not verified. |
| Claude Code in VS Code | Same Claude Code instructions apply only when the Claude Code harness is active; choosing a Claude model in another harness does not make it Claude Code. | Select the Claude Code harness and verify its own loaded-instruction view. | Official VS Code and Anthropic docs reviewed; extension/harness version not recorded or tested. |
| VS Code GitHub Copilot | The selected harness determines instruction support. Copilot supports project `AGENTS.md` in applicable agent harnesses; separate repository-wide `.github/copilot-instructions.md` is another mechanism and can add independent instructions. | Prefer the shared root `AGENTS.md`; check Copilot custom-instruction settings and references in the actual harness. Do not add a second policy file by default. | Official docs reviewed 2026-11-24; VS Code installed but Copilot extension/harness not identified or tested. |
| OpenAI Codex CLI | Codex reads `AGENTS.md` before work; root file is the project entry point. Codex skills use its own discovery conventions. | Root bootstrap points to `AGENT.md`; for procedures, directly open `skills/<name>.md` when adapter pointers do not resolve in the Codex skill loader. | Official docs reviewed 2026-11-24; local CLI 0.154.0; live loading/skill invocation not verified. |
| Other host/model | No universal file or skill discovery convention. | Explicitly load root `AGENT.md`, then follow `skills/REGISTRY.md` and open the canonical procedure directly. | Manual fallback only; compatibility unknown. |

No row is runtime-certified. Host version, settings, workspace trust, precedence, skill loading, model behavior and permissions can change the result. Documentation and binary presence do not prove the active session loaded these files.


## Adapter files

`adapters/claude/` and `adapters/codex/` contain skill-pointer examples, not installation bundles. Verify the exact discovery convention in the target host before relying on them; if pointer resolution is unsupported, open the canonical `skills/<name>.md` directly. They do not duplicate skill procedures.

## Optional capability behavior

Do not require or claim external web research, durable memory, MCP, hooks, delegation, session resume, or file-writing tools unless available and permitted in the active host. When a capability is missing, state the limitation and continue with safe core-only/manual work where possible. Analysis-only stays read-only even if write tools are available.

## Offline package checks

From the package root, run `python tools/validate_package.py`, `python tools/test_scenarios.py`, and `python -m compileall -q tools`. These checks validate static package consistency only; they do not prove instruction discovery, skill invocation, or model safety behavior in a live host.

## Official references reviewed

- Claude Code project instructions and `AGENTS.md` precedence: https://docs.anthropic.com/en/docs/claude-code/claude-md
- Claude Code directories and skills: https://docs.anthropic.com/en/docs/claude-code/claude-directory
- Codex project instructions: https://developers.openai.com/codex/agent-configuration/agents-md
- Codex skills: https://developers.openai.com/codex/skills
- VS Code instruction discovery: https://code.visualstudio.com/docs/agent-customization/custom-instructions
- VS Code format/locations: https://code.visualstudio.com/docs/agents/reference/custom-instructions-reference

This package offers no API or installer. A user can invoke each CLI's normal task surface on the package, but authentication, trust prompts, permissions, tools and model requests depend on that host. Do not run a live model smoke test without an approved, privacy-safe test scope and controlled workspace.

## Host-specific verification before claiming support

For each exact product/version/configuration, use a clean disposable workspace and record product, version, OS, extension/CLI, model/provider, workspace trust and permissions. Verify root instruction loading and a canonical skill read using actual host evidence. Test read-only analysis, task routing, no optional integrations, denied destructive action, untrusted prompt injection, and truthful handoff. Confirm no workspace writes in analysis-only. Keep results and limitations separate from static tests.

## Removal

Manual setup creates no package-owned host settings: close the workspace or remove the package directory. If you manually add an instruction pointer in host configuration, remove only the entry you added; do not remove or overwrite pre-existing host/user instructions. The package currently provides no installer or uninstaller.

## Skill Intelligence resolver

The agent classifies the task semantically, then validates its explicit primary intent and optional specialist/support selections with the deterministic resolver:

```bash
python tools/resolve_skills.py --intent system_analysis --specialist database --decision-json '{"dominant_intent":"system_analysis","primary_deliverable":"Evidence-backed current-state system analysis","trigger_evidence":"The task asks to inspect an existing system","specialist_evidence":{"database":"Actual schema/data flow is in scope"},"support_output_need":{},"excluded_candidates":["implementation"],"uncertainty":"Database scope must be confirmed from artifacts"}'
```

The resolver requires a structured decision record with evidence for the primary intent, each specialist and each support skill. It returns the workflow and exact skill paths. It does not infer intent from free text, load skills itself, grant tool permissions or certify host behavior. If Python is unavailable, apply the documented one-primary/specialist/support policy manually and disclose that fallback.
