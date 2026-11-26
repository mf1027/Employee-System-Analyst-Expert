# Skill: advise-client

## Purpose
Draft a plain-English, non-technical recommendation or answer for a client question.
Draft only — never sent directly. The operator reviews and sends it.

## Trigger
Invoke when the operator says "the client is asking about X", "what should we tell
[client]", "draft a reply about X", or "what should we recommend?".

## Minimum context required
- The client's question or communication to respond to
- Which client and project it relates to
If missing: ask which client/project and what they asked.

---

## Steps

1. Read current canonical Obsidian/project memory and the client record at
   `memory/clients/[client-name].md` — comms style, constraints, domain glossary.
   Search canonical Obsidian/project memory and the current project records for relevant knowledge; do not invoke claude-mem.
2. Read the relevant project files: `requirements.md`, `risks.md`, `decisions.md`.
3. If the question touches database topics, also read the project `database.md`.
4. Output a **CONTEXT SUMMARY** — what I read, what's relevant, confidence level.
5. Form a recommendation grounded in the project docs — what a senior SA/PM/DBA
   would advise, with the trade-off stated plainly.
6. Draft the client-facing message:
   - 50–100 words
   - Plain English, no jargon (or jargon glossed immediately)
   - One clear point or ask per message
   - Tone matched to client's comms style from their record
7. Add **private notes** for the operator: confidence level, technical reasoning
   behind the plain-English version, what to watch for in the client's response.
8. Present the draft. Never send.

---

## Output format

```
CLIENT ADVICE: [Topic]
Client: [name] | Project: [name] | Date: [YYYY-MM-DD]
---
Context: I read [files]. Confidence: [level] because [reason].

Draft:

Hi [Name],

[1–2 sentences: the recommendation in plain English]
[Optional: up to 3 bullets — key points, what to expect, what we need from them]

[Sign-off line]

---
Private notes for you:
- Technical reasoning: [what's actually going on under the hood]
- Confidence: [High/Medium/Low] — [why]
- Watch for: [what the client might push back on or misunderstand]
- If they say yes: [what happens next]
```

---

## Quality checklist

- [ ] Is the message ≤100 words and one clear point?
- [ ] Is the tone matched to the client's comms style from their record?
- [ ] Does the private note explain the technical reasoning in full?
- [ ] Have I flagged any open risks or assumptions the client's answer might affect?
- [ ] Did I confirm I'm not sending — only drafting?

## Failure exit
"Cannot advise without knowing which client, which project, and what they asked."
