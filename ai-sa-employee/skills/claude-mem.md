# Skill: claude-mem

## Purpose
Manage all files in the `memory/` folder — add entries, update existing ones,
summarise current state, and flag stale or conflicting data. The single interface
for keeping memory clean, current, and useful across all clients and projects.

## Trigger
Invoke when the operator says:
- "update memory", "remember this", "log this"
- "what do we know about [topic/client/project]?"
- "summarise clients / risks / tasks"
- "clean up memory", "is anything stale?" — **route to `memory-hygiene` instead.** claude-mem is
  confirmed non-operational (Tier 0, ADR-111); this phrase pointing here is a dead end regardless
  of intent (tie-break: `CLAUDE.md` Trigger Table, RISK-098 #3)
- "add this to [memory file]"

---

## Commands

### `mem add <file> <content>`
Add a new entry to a memory file.

**Steps:**
1. Read the target memory file in full.
2. Check for duplicates — if a near-identical entry exists, offer to merge instead.
3. Format the new entry to match the file's existing structure.
4. Append or insert in the correct section.
5. Confirm what was added and where.

---

### `mem update <file> <entry> <new content>`
Update an existing entry in a memory file.

**Steps:**
1. Read the target memory file.
2. Locate the entry by name, ID, or closest match.
3. Show the current content and proposed update side-by-side.
4. Confirm before writing (unless the operator said "just update it").
5. Write the update and confirm.

---

### `mem show <file>`
Summarise the current state of a memory file in plain language.

**Output format:**
```
## MEMORY SUMMARY: [filename]

[3–7 bullet points covering the most important current state]

Gaps / items needing update:
- [Anything missing, outdated, or flagged as unverified]
```

---

### `mem search <keyword>`
Find all mentions of a keyword across all memory files.

**Steps:**
1. Scan all files in `memory/` and `memory/clients/`.
2. Return matches with file name, section, and a one-line excerpt.
3. Note if the same topic appears in multiple files with conflicting info.

**Output format:**
```
## SEARCH: "[keyword]"

Found in:
- memory/[file].md → [Section] → "[excerpt]"
- memory/clients/[name].md → [Section] → "[excerpt]"

Conflicts: [None | Description of conflict]
```

---

### `mem clean`
Audit all memory files for staleness, conflicts, gaps, and the 150-line cap.

**Steps:**
1. Read all files in `memory/` and `memory/clients/`.
2. Flag entries older than 60 days that reference time-sensitive data.
3. Identify conflicts — same topic with different values across files.
4. Identify gaps — `[TBC]` items or empty sections.
5. Flag any file approaching 150 lines and offer to archive oldest entries
   to `memory/archive.md`.
6. Output a prioritised action list.

**Output format:**
```
## MEMORY AUDIT
Run date: YYYY-MM-DD

### Stale Entries
- [file] → [entry] → Action: [update / archive / verify]

### Conflicts
- [topic] differs in [file A] and [file B] → Recommended resolution: [X]

### Gaps
- [file] → [section] → Missing: [what should be here]

### Cap Warnings
- [file] → [N] lines → archive oldest [N] entries?

### Priority Actions
1. [Most urgent]
2. [Second]
```

---

### `mem snapshot`
Single-page summary of everything currently known. Useful for starting a new session.

**Output format:**
```
## MEMORY SNAPSHOT
Generated: YYYY-MM-DD

### OPERATOR (memory/memory.md)
[Profile, preferences — 2–3 bullets]

### CLIENTS (memory/clients/)
[Count + one line per active client]

### ACTIVE PROJECTS
[Count + one line per project with status]

### KNOWLEDGE BASE (claude-mem entries)
[Count + most recent entries by category — run `mem search [topic]` to retrieve]

### OPEN RISKS (across all projects)
[RED/AMBER risks only, with owner]

### DATABASE CONTEXT
[Any DB platforms, known risks — or "none recorded"]
```

---

## Quality checklist

- [ ] Before adding — have I checked for duplicates in the target file?
- [ ] Before updating — have I shown the before/after to the operator?
- [ ] On clean — have I checked all files in `memory/` and `memory/clients/`?
- [ ] On clean — have I checked the 150-line cap on each file?
- [ ] On snapshot — is every section populated, even if it says "none yet"?
- [ ] Have I preserved the existing formatting and structure of the memory file?
