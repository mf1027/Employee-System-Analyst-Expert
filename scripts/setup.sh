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
INSTALL_SOUP=0
INSTALL_SOUP_TRAINING=0
SOUP_ARCHIVE="${SOUP_ARCHIVE:-}"

step() { echo -e "\n${CYAN}==> $1${NC}"; }
ok()   { echo -e "    ${GREEN}[OK]   $1${NC}"; }
fail() { echo -e "    ${RED}[FAIL] $1${NC}"; FAILED=1; }
warn() { echo -e "    ${YELLOW}[WARN] $1${NC}"; }
info() { echo -e "    ${GRAY}$1${NC}"; }

while [ "$#" -gt 0 ]; do
    case "$1" in
        --install-soup) INSTALL_SOUP=1 ;;
        --install-soup-training) INSTALL_SOUP_TRAINING=1; INSTALL_SOUP=1 ;;
        --soup-archive)
            shift
            SOUP_ARCHIVE="${1:-}"
            ;;
        *) warn "Unknown setup option: $1" ;;
    esac
    shift
done

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
PONYTAIL_CLAUDE_OK=0
PONYTAIL_CODEX_OK=0
CLAUDE_CLI_OK=0
CODEX_CLI_OK=0

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
    if "$PY_CMD" -c "
import json
d = json.load(open('$IP_PATH'))
plugins = d.get('plugins', {})
exit(0 if 'ponytail@ponytail' in plugins else 1)
" 2>/dev/null; then
        PONYTAIL_CLAUDE_OK=1
    fi
    if "$PY_CMD" -c "
import json
d = json.load(open('$IP_PATH'))
plugins = d.get('plugins', {})
exit(0 if any('ponytail' in name.lower() and name != 'ponytail@ponytail' for name in plugins) else 1)
" 2>/dev/null; then
        warn "Another Ponytail package is active in Claude Code — do not remove it automatically."
    fi
fi

if command -v claude &>/dev/null; then
    CLAUDE_CLI_OK=1
else
    warn "Claude host unavailable — install Claude Code separately before using this repo."
fi

if command -v codex &>/dev/null; then
    CODEX_CLI_OK=1
    CODEX_PLUGIN_LIST=$(codex plugin list 2>&1 || true)
    if printf '%s\n' "$CODEX_PLUGIN_LIST" | grep -Eiq 'ponytail'; then
        PONYTAIL_CODEX_OK=1
    fi
    if printf '%s\n' "$CODEX_PLUGIN_LIST" | grep -Eiq 'engineering-suite-ponytail'; then
        warn "Another Ponytail package is active in Codex — do not remove it automatically."
    fi
else
    warn "Codex CLI not found — install it separately before using Codex with this repo."
fi

[ "$CLAUDE_MEM_OK" -eq 1 ]   && ok   "claude-mem plugin installed"   || warn "claude-mem NOT installed"
[ "$CONTEXT_MODE_OK" -eq 1 ] && ok   "context-mode plugin installed" || warn "context-mode NOT installed"
[ "$PONYTAIL_CLAUDE_OK" -eq 1 ] && ok "Ponytail plugin installed for Claude Code" || warn "Ponytail plugin NOT installed for Claude Code"
[ "$PONYTAIL_CODEX_OK" -eq 1 ] && ok "Ponytail plugin detected for Codex" || { [ "$CODEX_CLI_OK" -eq 1 ] && warn "Ponytail plugin NOT detected for Codex"; }
[ "$CLAUDE_CLI_OK" -eq 1 ] && ok "Claude host available" || true
[ "$CODEX_CLI_OK" -eq 1 ] && ok "Codex host available" || true

if [ "$PONYTAIL_CLAUDE_OK" -eq 1 ] && [ "$PONYTAIL_CODEX_OK" -eq 1 ]; then
    ok "Ponytail runtime verified"
else
    warn "Ponytail runtime not fully verified"
fi

if [ "$CLAUDE_MEM_OK" -eq 0 ] || [ "$CONTEXT_MODE_OK" -eq 0 ] || [ "$PONYTAIL_CLAUDE_OK" -eq 0 ] || [ "$PONYTAIL_CODEX_OK" -eq 0 ]; then
    echo ""
    echo -e "    ${BOLD}Open Claude Code in this directory and run:${NC}"
    [ "$CLAUDE_MEM_OK" -eq 0 ]   && echo -e "      ${YELLOW}/plugin marketplace add thedotmack/claude-mem${NC}"
    [ "$CLAUDE_MEM_OK" -eq 0 ]   && echo -e "      ${YELLOW}/plugin install claude-mem@thedotmack${NC}"
    [ "$CONTEXT_MODE_OK" -eq 0 ] && echo -e "      ${YELLOW}/plugin marketplace add mksglu/context-mode${NC}"
    [ "$CONTEXT_MODE_OK" -eq 0 ] && echo -e "      ${YELLOW}/plugin install context-mode@context-mode${NC}"
    [ "$PONYTAIL_CLAUDE_OK" -eq 0 ] && echo -e "      ${YELLOW}/plugin marketplace add DietrichGebert/ponytail${NC}"
    [ "$PONYTAIL_CLAUDE_OK" -eq 0 ] && echo -e "      ${YELLOW}/plugin install ponytail@ponytail${NC}"
    [ "$PONYTAIL_CODEX_OK" -eq 0 ] && echo -e "    ${BOLD}In Codex, run:${NC}"
    [ "$PONYTAIL_CODEX_OK" -eq 0 ] && echo -e "      ${YELLOW}codex plugin marketplace add DietrichGebert/ponytail${NC}"
    [ "$PONYTAIL_CODEX_OK" -eq 0 ] && echo -e "      ${YELLOW}codex plugin add ponytail@ponytail${NC}"
    echo -e "    ${BOLD}Review/trust Ponytail hooks, then restart Claude Code or open a fresh Codex task.${NC}"
    echo -e "    Ponytail lifecycle hooks require Node.js (already checked above)."
fi

# -- 5. Soup tool check/install -------------------------------------------------

step "Checking Soup model-preparation tool"
SOUP_ARGS=("$ROOT/scripts/soup-setup.mjs" --repo "$ROOT")
[ -n "$SOUP_ARCHIVE" ] && SOUP_ARGS+=(--archive "$SOUP_ARCHIVE")
[ "$INSTALL_SOUP" -eq 1 ] && SOUP_ARGS+=(--install)
[ "$INSTALL_SOUP_TRAINING" -eq 1 ] && SOUP_ARGS+=(--training)

SOUP_OUTPUT=""
if SOUP_OUTPUT=$(node "${SOUP_ARGS[@]}" 2>&1); then
    SOUP_EXIT=0
else
    SOUP_EXIT=$?
fi
printf '%s\n' "$SOUP_OUTPUT"
if [ "$SOUP_EXIT" -eq 0 ]; then
    ok "Soup runtime verified"
elif [ "$INSTALL_SOUP" -eq 1 ]; then
    warn "Soup installation/check did not complete; model preparation remains blocked"
    info "  Re-run with a valid Soup archive and Python 3.10-3.12, or inspect the reported reason."
else
    info "Soup is optional. To install it into the ignored repo-local environment:"
    info "  bash scripts/setup.sh --install-soup --soup-archive <path-to-Soup-0.75.0.zip>"
    info "  Add --install-soup-training only when training dependencies are explicitly needed."
fi

# -- 6. Ollama local-model check -----------------------------------------------

step "Checking Ollama local-model runtime"

OLLAMA_INSTALLED=0
OLLAMA_SERVICE_OK=0
OLLAMA_MODEL_CONFIGURED=0
OLLAMA_MODEL_OK=0
OLLAMA_CAPABILITY_OK=0
OLLAMA_CLOUD_MODEL=0
OLLAMA_HOST="${OLLAMA_HOST:-http://localhost:11434}"
OLLAMA_HOST="${OLLAMA_HOST%/}"

if command -v ollama &>/dev/null; then
    OLLAMA_INSTALLED=1
    ok "Ollama installed"
    ok "Ollama CLI available"
    if command -v curl &>/dev/null && curl -fsS --max-time 3 "$OLLAMA_HOST/api/tags" >/dev/null; then
        OLLAMA_SERVICE_OK=1
        ok "Ollama service reachable at $OLLAMA_HOST"
    else
        warn "Ollama service not reachable at $OLLAMA_HOST — start Ollama before launching an agent"
    fi

    if [ -n "${OLLAMA_MODEL:-}" ]; then
        OLLAMA_MODEL_CONFIGURED=1
        ok "Explicit model configured: $OLLAMA_MODEL"
        case "$OLLAMA_MODEL" in
            *:cloud|*:cloud:*|*-cloud|*-cloud:*) OLLAMA_CLOUD_MODEL=1 ;;
        esac
        if [ "$OLLAMA_CLOUD_MODEL" -eq 1 ]; then
            warn "Cloud model names are not allowed for local-runtime verification: $OLLAMA_MODEL"
        elif ollama ls 2>/dev/null | awk -v model="$OLLAMA_MODEL" 'NR > 1 && $1 == model { found=1 } END { exit !found }'; then
            OLLAMA_MODEL_OK=1
            ok "Explicit Ollama model installed locally: $OLLAMA_MODEL"
        else
            warn "OLLAMA_MODEL '$OLLAMA_MODEL' is not present in ollama ls"
        fi
    else
        warn "Explicit model not configured"
        warn "OLLAMA_MODEL is not set — local-model verification is incomplete"
    fi
else
    warn "Ollama not installed — local-model execution is unavailable"
fi

if [ "$OLLAMA_INSTALLED" -eq 1 ] && [ "$OLLAMA_SERVICE_OK" -eq 1 ] && [ "$OLLAMA_MODEL_OK" -eq 1 ]; then
    echo "    Read-only Ollama context/tool-calling probe:"
    if node "$SCRIPT_DIR/verify-ollama-runtime.mjs" --host "$OLLAMA_HOST" --model "$OLLAMA_MODEL"; then
        OLLAMA_CAPABILITY_OK=1
    else
        warn "Ollama context/tool-calling verification did not pass"
    fi
    info "Context capacity and Tool calling verified by verify-ollama-runtime.mjs; see the probe status above."
else
    info "Context capacity and Tool calling verified: not run because Ollama, service, or exact model is unavailable."
    info "Ollama context/tool-calling probe skipped until the local service and exact model are verified."
fi

if [ "$OLLAMA_INSTALLED" -eq 0 ] || [ "$OLLAMA_SERVICE_OK" -eq 0 ] || [ "$OLLAMA_MODEL_CONFIGURED" -eq 0 ] || [ "$OLLAMA_MODEL_OK" -eq 0 ] || [ "$OLLAMA_CAPABILITY_OK" -eq 0 ]; then
    echo "    Configure an explicit local model before verification:"
    echo -e "      ${YELLOW}export OLLAMA_MODEL=\"<local-model-name>\"${NC}"
    echo -e "      ${YELLOW}ollama pull <OLLAMA_MODEL>  # manual operator action; setup never runs this${NC}"
    echo -e "      ${YELLOW}ollama launch claude --model \$OLLAMA_MODEL${NC}"
    echo -e "      ${YELLOW}ollama launch codex --model \$OLLAMA_MODEL${NC}"
    info "Ollama only supplies inference; the host runtime supplies skills, tools, permissions, and hooks."
fi

# -- 7. Verify document engines ------------------------------------------------

step "Verifying document engines (end-to-end)"
if [ -f "$SCRIPT_DIR/verify-engines.sh" ]; then
    bash "$SCRIPT_DIR/verify-engines.sh" || true
else
    warn "verify-engines.sh not found - skipping engine verification"
fi

# -- 8. Summary ----------------------------------------------------------------

echo ""
echo -e "${CYAN}======================================${NC}"
echo -e "${CYAN}  Setup complete${NC}"
echo -e "${CYAN}======================================${NC}"

if [ "$CLAUDE_MEM_OK" -eq 0 ] || [ "$CONTEXT_MODE_OK" -eq 0 ] || [ "$PONYTAIL_CLAUDE_OK" -eq 0 ] || [ "$PONYTAIL_CODEX_OK" -eq 0 ] || [ "$CLAUDE_CLI_OK" -eq 0 ] || [ "$CODEX_CLI_OK" -eq 0 ] ||
   [ "$OLLAMA_INSTALLED" -eq 0 ] || [ "$OLLAMA_SERVICE_OK" -eq 0 ] || [ "$OLLAMA_MODEL_CONFIGURED" -eq 0 ] || [ "$OLLAMA_MODEL_OK" -eq 0 ] || [ "$OLLAMA_CAPABILITY_OK" -eq 0 ] ||
   { [ "$INSTALL_SOUP" -eq 1 ] && [ "$SOUP_EXIT" -ne 0 ]; }; then
    echo -e "  ${YELLOW}Action needed: install the missing plugin(s) listed above.${NC}"
else
    echo -e "  ${GREEN}All dependencies ready. Open this folder in Claude Code.${NC}"
fi
echo ""
