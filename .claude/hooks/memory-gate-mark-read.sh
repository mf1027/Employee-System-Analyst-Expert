#!/usr/bin/env bash
# PostToolUse(Read) hook for SKL-045: marks this session as having read
# memory/memory.md, so the PreToolUse write-gate hook stays silent.
IN=$(cat)
FP=$(echo "$IN" | jq -r '.tool_input.file_path // empty')
SID=$(echo "$IN" | jq -r '.session_id // "default"')
if echo "$FP" | grep -qiE 'memory[\\/]memory\.md$'; then
  mkdir -p ".claude/memory/gate"
  touch ".claude/memory/gate/${SID}.read"
fi
exit 0
