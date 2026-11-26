#!/usr/bin/env bash
# Verified backup wrapper for Linux/macOS.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"
PYTHON="$(command -v python3 || command -v python || true)"
[ -n "$PYTHON" ] || { echo '[FAIL] Python 3 is required for verified backups.' >&2; exit 1; }
DESTINATION="${1:-$HOME/Documents/EmployeeBackups}"
ARGS=(--root "$ROOT" --destination "$DESTINATION" --keep "${KEEP:-10}")
[ "${INCLUDE_ENGINES:-0}" = 1 ] && ARGS+=(--include-engines)
if command -v cygpath >/dev/null 2>&1; then
  SCRIPT_DIR="$(cygpath -w "$SCRIPT_DIR")"
  ROOT="$(cygpath -w "$ROOT")"
  DESTINATION="$(cygpath -w "$DESTINATION")"
  ARGS=(--root "$ROOT" --destination "$DESTINATION" --keep "${KEEP:-10}")
  [ "${INCLUDE_ENGINES:-0}" = 1 ] && ARGS+=(--include-engines)
  MSYS2_ARG_CONV_EXCL='*' exec "$PYTHON" "$SCRIPT_DIR/backup.py" "${ARGS[@]}"
fi
exec "$PYTHON" "$SCRIPT_DIR/backup.py" "${ARGS[@]}"
