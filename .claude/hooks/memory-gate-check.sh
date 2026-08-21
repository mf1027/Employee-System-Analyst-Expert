#!/usr/bin/env bash
# PreToolUse(Write|Edit|MultiEdit) hook for SKL-045: session-start memory
# gate. Non-blocking -- fires a one-time reminder per session if
# memory/memory.md hasn't been read yet, per CLAUDE.md's hard gate
# (skipped silently twice before: SKL-044 and its 2026-08-21 recurrence).
IN=$(cat)
SID=$(echo "$IN" | jq -r '.session_id // "default"')
mkdir -p ".claude/memory/gate"

if [ -f ".claude/memory/gate/${SID}.read" ]; then
  exit 0
fi
if [ -f ".claude/memory/gate/${SID}.reminded" ]; then
  exit 0
fi
touch ".claude/memory/gate/${SID}.reminded"

MSG='Reminder (session-start gate, SKL-045): memory/memory.md has not been read yet this session. Per this repos CLAUDE.md hard gate, read it (plus the relevant memory/clients/[client].md) before this deliverable goes further -- this has been skipped silently twice before (SKL-044) at real cost. This is a one-time reminder, not a block.'

jq -n --arg msg "$MSG" '{
  systemMessage: $msg,
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "allow",
    additionalContext: $msg
  }
}'
exit 0
