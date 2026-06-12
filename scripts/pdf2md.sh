#!/usr/bin/env bash
# pdf2md.sh - Convert PDF to Markdown for ingestion into reference/
# Usage:
#   bash scripts/pdf2md.sh "reference/document.pdf"
#   bash scripts/pdf2md.sh "reference/document.pdf" "reference/out.md"
#
# Converter priority:
#   1. @opendataloader/pdf  (installed in node_modules — primary, best quality)
#   2. pypdf                (pip install pypdf — fallback, plain text extraction only)
#
# After conversion: ensure the .md is in reference/ then run ingest-reference in Claude Code.

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[OK]   $1${NC}"; }
fail() { echo -e "${RED}[FAIL] $1${NC}"; }
warn() { echo -e "${YELLOW}[WARN] $1${NC}"; }
info() { echo -e "${GRAY}       $1${NC}"; }

# -- Args and paths ------------------------------------------------------------

if [ $# -lt 1 ]; then
    echo "Usage: bash scripts/pdf2md.sh <input.pdf> [output.md]"
    exit 1
fi

INPUT="$1"
if [ ! -f "$INPUT" ]; then
    fail "File not found: $INPUT"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"

INPUT_ABS="$(cd "$(dirname "$INPUT")" && pwd)/$(basename "$INPUT")"
INPUT_BASE="$(basename "$INPUT_ABS" .pdf)"
INPUT_DIR="$(dirname "$INPUT_ABS")"

if [ $# -ge 2 ]; then
    OUTPUT="$2"
    if [[ "$OUTPUT" != /* ]]; then
        OUTPUT="$(pwd)/$OUTPUT"
    fi
else
    OUTPUT="$INPUT_DIR/$INPUT_BASE.md"
fi

OUTPUT_DIR="$(dirname "$OUTPUT")"
OUTPUT_BASE="$(basename "$OUTPUT" .md)"

echo -e "${CYAN}Input:  $INPUT_ABS${NC}"
echo -e "${CYAN}Output: $OUTPUT${NC}"
echo ""

CONVERTED=0
TEMP_PY="$(mktemp /tmp/pdf2md_XXXXXX.py)"
trap 'rm -f "$TEMP_PY"' EXIT

# Detect Python
PY_CMD=""
for cmd in python3 python; do
    if command -v "$cmd" &>/dev/null; then
        PY_CMD="$cmd"
        break
    fi
done

# -- Attempt 1: @opendataloader/pdf (node_modules) ----------------------------

ODL_BIN="$ROOT/node_modules/.bin/opendataloader-pdf"

if [ -x "$ODL_BIN" ]; then
    info "Using: @opendataloader/pdf"
    if "$ODL_BIN" "$INPUT_ABS" -f markdown -o "$OUTPUT_DIR" -q --image-output off; then
        # Rename if the converter produced input-base.md but desired name differs
        PRODUCED="$OUTPUT_DIR/$INPUT_BASE.md"
        if [ -f "$PRODUCED" ] && [ "$PRODUCED" != "$OUTPUT" ]; then
            mv "$PRODUCED" "$OUTPUT"
        fi
        CONVERTED=1
    else
        warn "@opendataloader/pdf failed — trying fallback"
    fi
else
    warn "@opendataloader/pdf binary not found at $ODL_BIN"
    info "Run: npm install  (from project root) to install it"
fi

# -- Attempt 2: pypdf fallback -------------------------------------------------

if [ "$CONVERTED" -eq 0 ] && [ -n "$PY_CMD" ] && "$PY_CMD" -c "import pypdf" 2>/dev/null; then
    warn "Using: pypdf (text extraction only — tables and layout not preserved)"
    cat > "$TEMP_PY" <<'PYEOF'
import pypdf, sys
reader = pypdf.PdfReader(sys.argv[1])
lines = []
for i, page in enumerate(reader.pages, 1):
    lines.append(f"## Page {i}")
    text = page.extract_text() or ""
    lines.append(text)
    lines.append("")
with open(sys.argv[2], 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines))
PYEOF
    "$PY_CMD" "$TEMP_PY" "$INPUT_ABS" "$OUTPUT"
    CONVERTED=1
fi

# -- Result --------------------------------------------------------------------

if [ "$CONVERTED" -eq 0 ]; then
    echo ""
    fail "No converter available."
    echo ""
    echo -e "    ${YELLOW}Primary:  npm install   (installs @opendataloader/pdf in node_modules)${NC}"
    echo -e "    ${YELLOW}Fallback: pip install pypdf${NC}"
    echo ""
    exit 1
fi

echo ""
ok "Converted: $OUTPUT"
echo ""
echo -e "${CYAN}Next steps:${NC}"
info "1. Ensure the .md file is in reference/"
info "2. Open Claude Code and run: ingest-reference"
echo ""
