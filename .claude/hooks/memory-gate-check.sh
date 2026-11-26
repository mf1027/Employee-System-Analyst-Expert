#!/usr/bin/env bash
# PreToolUse(Write|Edit|MultiEdit): one-time session reminder only.
# No permissionDecision is emitted; the host retains its normal approval flow.
set -euo pipefail
IN=$(cat)
SID=$(printf '%s' "$IN" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{let v={};try{v=JSON.parse(s)}catch{};process.stdout.write(String(v.session_id||"default").replace(/[^A-Za-z0-9_-]/g,""))})')
[ -n "$SID" ] || SID=default
GATE_DIR=".claude/memory/gate"
mkdir -p "$GATE_DIR"
[ -f "$GATE_DIR/${SID}.reminded" ] && exit 0
touch "$GATE_DIR/${SID}.reminded"
MSG='Reminder (session-start gate): read the current canonical memory source and relevant project decision records before making changes. This is a reminder only; the host permission system remains responsible for approving or denying the tool call.'
printf '%s' "$MSG" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>process.stdout.write(JSON.stringify({systemMessage:s,hookSpecificOutput:{hookEventName:"PreToolUse",additionalContext:s}})))'
