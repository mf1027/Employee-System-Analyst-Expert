#!/usr/bin/env bash
# Run Python with this repository's isolated dependency environment.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PY="$ROOT/.venv/bin/python"
[ -x "$PY" ] || { echo '[FAIL] Project .venv is missing. Run scripts/setup.sh first.' >&2; exit 2; }
exec "$PY" "$@"
