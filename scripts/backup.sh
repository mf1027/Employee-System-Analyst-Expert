#!/usr/bin/env bash
# backup.sh - Back up all local-only client data (Linux/Mac)
# Client data is gitignored by design - this script is the safety net.
# Run weekly, or say "backup client data" to the employee.
#
#   bash scripts/backup.sh
#   bash scripts/backup.sh /path/to/backups
#   KEEP=20 bash scripts/backup.sh
#   INCLUDE_ENGINES=1 bash scripts/backup.sh   # also bundle the ~1 GB engines/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"
DESTINATION="${1:-$HOME/Documents/EmployeeBackups}"
KEEP="${KEEP:-10}"
INCLUDE_ENGINES="${INCLUDE_ENGINES:-0}"
STAMP="$(date +%Y-%m-%d_%H%M%S)"

GREEN='\033[0;32m'; YELLOW='\033[0;33m'; CYAN='\033[0;36m'; GRAY='\033[0;90m'; NC='\033[0m'

# Folders that hold data which exists nowhere else (all gitignored)
TARGETS=()
for dir in "memory/clients" ".claude-mem" "reference" "deliverables"; do
    [ -d "$ROOT/$dir" ] && TARGETS+=("$dir")
done

# engines/ is reproducible (re-fetch anytime) so it is OFF by default - it would
# add ~1 GB to every backup. Include it only for a portable bundle.
if [ "$INCLUDE_ENGINES" = "1" ] && [ -d "$ROOT/engines" ]; then
    TARGETS+=("engines")
fi

if [ ${#TARGETS[@]} -eq 0 ]; then
    echo -e "${YELLOW}[WARN] Nothing to back up - no client data folders found.${NC}"
    exit 0
fi

mkdir -p "$DESTINATION"
ZIP_PATH="$DESTINATION/employee-client-data_$STAMP.zip"

echo -e "${CYAN}==> Backing up client data${NC}"
for t in "${TARGETS[@]}"; do
    echo -e "    ${GRAY}+ $t${NC}"
done

(cd "$ROOT" && zip -rq "$ZIP_PATH" "${TARGETS[@]}")

SIZE=$(du -h "$ZIP_PATH" | cut -f1)
echo -e "    ${GREEN}[OK] $ZIP_PATH ($SIZE)${NC}"

# Retention - keep newest $KEEP, delete the rest
ls -t "$DESTINATION"/employee-client-data_*.zip 2>/dev/null | tail -n +$((KEEP + 1)) | while read -r old; do
    rm -f "$old"
    echo -e "    ${GREEN}[OK] Retention: removed $(basename "$old")${NC}"
done

echo ""
echo -e "${CYAN}Backup complete. To restore on another machine:${NC}"
echo "  1. Clone the repo and run: bash scripts/setup.sh"
echo "  2. Extract the zip into the repo root (restores memory/clients, .claude-mem, reference, deliverables)"
echo "  3. Tell the employee: 'I have an ongoing client that I manually inserted' (resume-client)"
