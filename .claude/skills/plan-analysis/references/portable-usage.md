# Portable usage

The core `SKILL.md` is intentionally model-neutral. To use it with Claude, ChatGPT, or another LLM:

1. Copy the `plan-analysis` folder or paste `SKILL.md` into the model's project instructions.
2. Provide the target repository, documents, known symptoms, constraints, and authorization boundary.
3. Ask the model to follow the six phases and emit the artifact contract.
4. If the model can write files, create `docs/plans/<slug>/`; otherwise return the artifacts in fenced Markdown/JSON blocks and mark the run non-persistent.
5. If a named gstack capability is unavailable, use the portable fallback checklist and record the degradation.
6. Run the supplied validator wherever Python 3 is available.

Portable invocation example:

```text
Use plan-analysis. Thoroughly inspect the supplied project and requirements, perform RCA and gap analysis, run every applicable strategy/architecture/design/DX/rollback review, produce the required evidence bundle, then re-audit the plan for up to five cycles. Do not implement code. Report COMPLETE only when the completion gate is proven.
```

The portable workflow does not depend on Codex paths, MCP, Bash, PowerShell, web search, or a particular second model.

## Claude Code (global skill)

This copy is installed at `~/.claude/skills/plan-analysis/` — global to every project on this
machine, discoverable via the Skill tool in any working directory, no per-project setup needed.

1. **Invoke:** `/plan-analysis` (or ask for it by name/description) from any project, MYPS or
   otherwise. It is not registered in any project's `.claude/commands/` wrapper set — a skill
   placed directly under `~/.claude/skills/<name>/SKILL.md` is natively discoverable without one.
2. **Artifacts land relative to the invoking project**, not this skill's own folder: `docs/plans/
   <slug>/` under whatever repository/working directory the skill was invoked in.
3. **Validator:** run `python ~/.claude/skills/plan-analysis/scripts/validate-artifacts.py
   docs/plans/<slug>/` from the invoking project — same stdlib-only script as the portable
   version above, just referenced from its installed path.
4. **Tool mapping:** Operating Rules 1 and 4 in `SKILL.md` already point at Claude Code's native
   `AskUserQuestion` and `EnterPlanMode`/`ExitPlanMode` tools instead of a separate portable
   question/plan-gate protocol — use those directly rather than re-deriving the generic fallback
   above when running inside Claude Code.
5. **Review adapters:** `references/review-adapters.md` records which of the 9 named capabilities
   are confirmed installed as global Claude Code skills on this machine versus needing the
   portable fallback checklist in this file — check that table before assuming a named review is
   available.

## This copy (project-vendored, MYPS)

This exact directory is also vendored into `C:\Users\khen\Documents\ChatGPT\MYPS\.claude\skills\
plan-analysis\` (ADR-136, 2026-09-01) — git-tracked, so a fresh `git clone` of the MYPS repo gets
`plan-analysis` auto-discoverable with no separate global install step. It is a straight,
byte-identical copy of the global install above; the global copy stays because `plan-analysis` is
explicitly usable in *any* project on this machine, not just MYPS. If you edit this skill's
methodology, update both copies in the same pass — there is no symlink or single-source mechanism
tying them together (Windows/git-clone portability made that impractical), so drift is a real,
manual risk to watch for, not an automatically-prevented one.

**Artifact-bundle commit discipline, MYPS-specific:** if a `docs/plans/<slug>/` bundle (the
`## Artifacts` section above) is ever created against this repo, commit it to git as part of
completing the run. It's small, git-trackable text — the same pattern this repo already uses for
every other vendored/authored skill file — not something `scripts/backup.ps1` covers (that script
only backs up gitignored, irreplaceable local data; `docs/plans/` isn't gitignored) and not
something git protects on its own until it's actually committed. Left uncommitted, a bundle is
invisible to both.
