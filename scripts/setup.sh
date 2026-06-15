#!/usr/bin/env bash
# setup.sh - First-time setup for Employee System Analyst Expert (Linux/Mac)
# Run once after cloning to a new machine:
#   cd "Employee System Analyst Expert"
#   bash scripts/setup.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

FAILED=0

step() { echo -e "\n${CYAN}==> $1${NC}"; }
ok()   { echo -e "    ${GREEN}[OK]   $1${NC}"; }
fail() { echo -e "    ${RED}[FAIL] $1${NC}"; FAILED=1; }
warn() { echo -e "    ${YELLOW}[WARN] $1${NC}"; }
info() { echo -e "    ${GRAY}$1${NC}"; }

# -- 1. Prerequisites ----------------------------------------------------------

step "Checking prerequisites"

# Node.js >= 20
if command -v node &>/dev/null; then
    NODE_VER=$(node --version)
    NODE_MAJOR=$(echo "$NODE_VER" | sed 's/v\([0-9]*\)\..*/\1/')
    if [ "$NODE_MAJOR" -ge 20 ]; then
        ok "Node.js $NODE_VER"
    else
        fail "Node.js $NODE_VER detected — need >= 20. Get it: https://nodejs.org"
    fi
else
    fail "Node.js not found. Get it: https://nodejs.org"
fi

# Python >= 3.10
PY_CMD=""
for cmd in python3 python; do
    if command -v "$cmd" &>/dev/null; then
        PY_VER=$("$cmd" --version 2>&1 | awk '{print $2}')
        PY_MAJOR=$(echo "$PY_VER" | cut -d. -f1)
        PY_MINOR=$(echo "$PY_VER" | cut -d. -f2)
        if [ "$PY_MAJOR" -gt 3 ] || ([ "$PY_MAJOR" -eq 3 ] && [ "$PY_MINOR" -ge 10 ]); then
            PY_CMD="$cmd"
            ok "Python $PY_VER (via $cmd)"
            break
        fi
    fi
done
if [ -z "$PY_CMD" ]; then
    fail "Python >= 3.10 not found. Get it: https://python.org"
fi

# Bun (needed for context-mode hooks)
if command -v bun &>/dev/null; then
    BUN_VER=$(bun --version)
    ok "Bun $BUN_VER"
else
    warn "Bun not found — context-mode hooks will not fire."
    info "  Install: curl -fsSL https://bun.sh/install | bash"
fi

if [ "$FAILED" -eq 1 ]; then
    echo -e "\n${RED}[!] Fix the failures above before continuing.${NC}"
    exit 1
fi

# -- 2. Node dependencies ------------------------------------------------------

step "Installing Node.js dependencies (npm install)"
cd "$ROOT"
npm install
ok "node_modules ready (claude-mem + context-mode + @opendataloader/pdf included)"

# Verify @opendataloader/pdf binary
ODL_BIN="$ROOT/node_modules/.bin/opendataloader-pdf"
if [ -x "$ODL_BIN" ]; then
    ok "@opendataloader/pdf binary ready"
else
    warn "@opendataloader/pdf binary not found — pdf2md.sh will fall back to pypdf"
fi

# -- 3. Python dependencies ----------------------------------------------------

step "Installing Python dependencies"
if "$PY_CMD" -m pip install chromadb --quiet 2>/dev/null; then
    CHROMA_VER=$("$PY_CMD" -c "import chromadb; print(chromadb.__version__)" 2>/dev/null || echo "installed")
    ok "chromadb $CHROMA_VER"
else
    warn "chromadb install failed — semantic memory search will fall back to keyword mode"
fi

# Document-skills packages (docx/pptx/xlsx/pdf generation + reading)
if "$PY_CMD" -m pip install defusedxml lxml openpyxl pdf2image pdfplumber pillow pypdf --quiet 2>/dev/null \
   && "$PY_CMD" -c "import defusedxml, lxml, openpyxl, pdf2image, pdfplumber, PIL, pypdf" 2>/dev/null; then
    ok "document-skills Python packages (7) ready"
else
    warn "document-skills packages failed — docx/pptx/xlsx/pdf skills may not work"
fi

# -- 3b. Document engines: LibreOffice + Poppler (Phase 2) ----------------------

step "Checking document engines (LibreOffice + Poppler + Java)"

# LibreOffice — needed for docx/pptx/xlsx conversion and recalc
if command -v soffice &>/dev/null; then
    ok "LibreOffice present"
elif command -v brew &>/dev/null; then
    info "Installing LibreOffice via Homebrew..."
    brew install --cask libreoffice && ok "LibreOffice installed" || warn "LibreOffice install failed"
elif command -v apt-get &>/dev/null; then
    info "Installing LibreOffice via apt (needs sudo)..."
    sudo apt-get install -y libreoffice && ok "LibreOffice installed" || warn "LibreOffice install failed"
else
    warn "LibreOffice not found — install manually: https://www.libreoffice.org"
fi

# Poppler — needed for PDF -> image conversion (pdf2image)
if command -v pdftoppm &>/dev/null; then
    ok "Poppler present"
elif command -v brew &>/dev/null; then
    info "Installing Poppler via Homebrew..."
    brew install poppler && ok "Poppler installed" || warn "Poppler install failed"
elif command -v apt-get &>/dev/null; then
    info "Installing Poppler via apt (needs sudo)..."
    sudo apt-get install -y poppler-utils && ok "Poppler installed" || warn "Poppler install failed"
else
    warn "Poppler not found — install manually (poppler / poppler-utils package)"
fi

# Java — needed by @opendataloader/pdf (high-fidelity PDF -> Markdown).
# Without it, pdf2md still works via the pypdf fallback, but text-only.
if command -v java &>/dev/null; then
    ok "Java present (high-fidelity PDF conversion available)"
elif command -v brew &>/dev/null; then
    info "Installing Java (Temurin JRE) via Homebrew..."
    brew install --cask temurin && ok "Java installed" || warn "Java install failed — pdf2md falls back to pypdf (text-only)"
elif command -v apt-get &>/dev/null; then
    info "Installing Java (default-jre) via apt (needs sudo)..."
    sudo apt-get install -y default-jre && ok "Java installed" || warn "Java install failed — pdf2md falls back to pypdf (text-only)"
else
    warn "Java not found — pdf2md will use pypdf (text-only). Install a JRE 11+: https://adoptium.net"
fi

# -- 4. Claude Code plugin check -----------------------------------------------

step "Checking Claude Code plugins"

IP_PATH="$HOME/.claude/plugins/installed_plugins.json"
CLAUDE_MEM_OK=0
CONTEXT_MODE_OK=0

if [ -f "$IP_PATH" ]; then
    if "$PY_CMD" -c "
import json
d = json.load(open('$IP_PATH'))
plugins = d.get('plugins', {})
exit(0 if 'claude-mem@thedotmack' in plugins else 1)
" 2>/dev/null; then
        CLAUDE_MEM_OK=1
    fi
    if "$PY_CMD" -c "
import json
d = json.load(open('$IP_PATH'))
plugins = d.get('plugins', {})
exit(0 if 'context-mode@context-mode' in plugins else 1)
" 2>/dev/null; then
        CONTEXT_MODE_OK=1
    fi
fi

[ "$CLAUDE_MEM_OK" -eq 1 ]   && ok   "claude-mem plugin installed"   || warn "claude-mem NOT installed"
[ "$CONTEXT_MODE_OK" -eq 1 ] && ok   "context-mode plugin installed" || warn "context-mode NOT installed"

if [ "$CLAUDE_MEM_OK" -eq 0 ] || [ "$CONTEXT_MODE_OK" -eq 0 ]; then
    echo ""
    echo -e "    ${BOLD}Open Claude Code in this directory and run:${NC}"
    [ "$CLAUDE_MEM_OK" -eq 0 ]   && echo -e "      ${YELLOW}/plugin marketplace add thedotmack/claude-mem${NC}"
    [ "$CLAUDE_MEM_OK" -eq 0 ]   && echo -e "      ${YELLOW}/plugin install claude-mem@thedotmack${NC}"
    [ "$CONTEXT_MODE_OK" -eq 0 ] && echo -e "      ${YELLOW}/plugin marketplace add mksglu/context-mode${NC}"
    [ "$CONTEXT_MODE_OK" -eq 0 ] && echo -e "      ${YELLOW}/plugin install context-mode@context-mode${NC}"
    echo -e "    ${BOLD}Then restart Claude Code.${NC}"
fi

# -- 5. Verify document engines ------------------------------------------------

step "Verifying document engines (end-to-end)"
if [ -f "$SCRIPT_DIR/verify-engines.sh" ]; then
    bash "$SCRIPT_DIR/verify-engines.sh" || true
else
    warn "verify-engines.sh not found - skipping engine verification"
fi

# -- 6. Summary ----------------------------------------------------------------

echo ""
echo -e "${CYAN}======================================${NC}"
echo -e "${CYAN}  Setup complete${NC}"
echo -e "${CYAN}======================================${NC}"

if [ "$CLAUDE_MEM_OK" -eq 0 ] || [ "$CONTEXT_MODE_OK" -eq 0 ]; then
    echo -e "  ${YELLOW}Action needed: install the missing plugin(s) listed above.${NC}"
else
    echo -e "  ${GREEN}All dependencies ready. Open this folder in Claude Code.${NC}"
fi
echo ""
