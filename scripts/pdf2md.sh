#!/usr/bin/env bash
# pdf2md.sh - Convert PDF(s) to Markdown for ingestion into reference/
# Usage:
#   bash scripts/pdf2md.sh                       # convert every *.pdf in pdf-source/
#   bash scripts/pdf2md.sh sample.pdf            # bare name: pdf-source/ first, then current dir
#   bash scripts/pdf2md.sh reference/doc.pdf     # explicit path
#   bash scripts/pdf2md.sh reference/            # a folder: convert all *.pdf inside it
#   bash scripts/pdf2md.sh doc.pdf out.md        # single file, custom output
#   RECURSE=1 bash scripts/pdf2md.sh             # include subfolders when batching
#
# Converter priority:
#   1. @opendataloader/pdf  (node_modules - primary, best quality)
#   2. pypdf                (project .venv fallback, text only)
#
# Output: <name>.md next to each source PDF (unless a 2nd arg gives a custom output for one file).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"
PDF_SOURCE="$ROOT/pdf-source"
INPUT="${1:-}"
OUTPUT="${2:-}"
RECURSE="${RECURSE:-0}"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[0;33m'; CYAN='\033[0;36m'; GRAY='\033[0;90m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[OK]   $1${NC}"; }
fail() { echo -e "${RED}[FAIL] $1${NC}"; }
warn() { echo -e "${YELLOW}[WARN] $1${NC}"; }
info() { echo -e "${GRAY}       $1${NC}"; }

ODL_BIN="$ROOT/node_modules/.bin/opendataloader-pdf"
PY_CMD="$ROOT/.venv/bin/python"
[ -x "$PY_CMD" ] || PY_CMD=""
TMP_PY="$(mktemp).py"
trap 'rm -f "$TMP_PY"' EXIT
PYPDF_CHECKED=0; PYPDF_READY=0
USED_FALLBACK=0

# Collect *.pdf from a directory into the PDFS array
collect_dir() {
    local dir="$1"
    if [ "$RECURSE" = "1" ]; then
        while IFS= read -r -d '' f; do PDFS+=("$f"); done \
            < <(find "$dir" -type f -iname '*.pdf' -print0 2>/dev/null)
    else
        while IFS= read -r -d '' f; do PDFS+=("$f"); done \
            < <(find "$dir" -maxdepth 1 -type f -iname '*.pdf' -print0 2>/dev/null)
    fi
}

PDFS=()
if [ -z "$INPUT" ]; then
    # No argument -> batch pdf-source/
    if [ ! -d "$PDF_SOURCE" ]; then
        warn "No file given and pdf-source/ does not exist yet."
        info "Drop PDFs into pdf-source/ and re-run, or pass a path."
        exit 0
    fi
    collect_dir "$PDF_SOURCE"
    [ ${#PDFS[@]} -eq 0 ] && { warn "No PDFs found in pdf-source/."; exit 0; }
    info "Batch: ${#PDFS[@]} PDF(s) from pdf-source/"
elif [ -d "$INPUT" ]; then
    collect_dir "$INPUT"
    [ ${#PDFS[@]} -eq 0 ] && { warn "No PDFs found in $INPUT"; exit 0; }
    info "Batch: ${#PDFS[@]} PDF(s) from $INPUT"
else
    # A file: explicit path vs bare name
    RESOLVED=""
    case "$INPUT" in
        */*|/*) [ -f "$INPUT" ] && RESOLVED="$INPUT" ;;          # has a dir component
        *)                                                       # bare name
            if [ -f "$PDF_SOURCE/$INPUT" ]; then RESOLVED="$PDF_SOURCE/$INPUT"; info "Found in pdf-source/: $INPUT"
            elif [ -f "./$INPUT" ];        then RESOLVED="./$INPUT";          info "Found in current directory: $INPUT"
            fi ;;
    esac
    if [ -z "$RESOLVED" ]; then
        fail "Not found: '$INPUT'"
        case "$INPUT" in */*|/*) : ;; *) info "Looked in pdf-source/ then the current directory." ;; esac
        exit 1
    fi
    case "$RESOLVED" in *.pdf|*.PDF) : ;; *) warn "Not a .pdf extension: $RESOLVED (trying anyway)" ;; esac
    PDFS=("$RESOLVED")
fi

if [ -n "$OUTPUT" ] && [ ${#PDFS[@]} -gt 1 ]; then
    warn "custom output ignored for a batch of ${#PDFS[@]}; writing <name>.md next to each PDF."
    OUTPUT=""
fi

ensure_pypdf() {
    if [ "$PYPDF_CHECKED" -eq 0 ]; then
        PYPDF_CHECKED=1
        if [ -n "$PY_CMD" ] && "$PY_CMD" -c "import pypdf" 2>/dev/null; then
            PYPDF_READY=1
            cat > "$TMP_PY" <<'PYEOF'
import pypdf, sys
reader = pypdf.PdfReader(sys.argv[1])
out = []
for i, page in enumerate(reader.pages, 1):
    out.append(f"## Page {i}")
    out.append(page.extract_text() or "")
    out.append("")
open(sys.argv[2], "w", encoding="utf-8").write("\n".join(out))
PYEOF
        fi
    fi
    return $((1 - PYPDF_READY))
}

# Success is judged by the output FILE existing, not by exit codes - robust to
# the opendataloader binary failing (e.g. Java absent). Echoes the converter used.
convert_one() {
    local in="$1" out="$2"
    local base outdir produced
    base="$(basename "${in%.*}")"
    outdir="$(dirname "$out")"
    [ -f "$out" ] && rm -f "$out"
    if [ -x "$ODL_BIN" ]; then
        "$ODL_BIN" "$in" -f markdown -o "$outdir" -q --image-output off >/dev/null 2>&1 || true
        produced="$outdir/$base.md"
        [ -f "$produced" ] && [ "$produced" != "$out" ] && mv -f "$produced" "$out"
        if [ -s "$out" ]; then echo "opendataloader"; return 0; fi
    fi
    if ensure_pypdf; then
        "$PY_CMD" "$TMP_PY" "$in" "$out" >/dev/null 2>&1 || true
        if [ -f "$out" ]; then USED_FALLBACK=1; echo "pypdf"; return 0; fi
    fi
    return 1
}

CONVERTED=0; FAILED=0; FAILLIST=()
for pdf in "${PDFS[@]}"; do
    name="$(basename "$pdf")"
    if [ -n "$OUTPUT" ]; then outpath="$OUTPUT"
    else outpath="$(dirname "$pdf")/$(basename "${pdf%.*}").md"; fi
    echo -e "${CYAN}-> $name${NC}"
    if via="$(convert_one "$pdf" "$outpath")"; then ok "  $outpath  [$via]"; CONVERTED=$((CONVERTED+1))
    else fail "  failed: $name"; FAILED=$((FAILED+1)); FAILLIST+=("$name"); fi
done

if [ "$CONVERTED" -eq 0 ] && [ ! -x "$ODL_BIN" ] && [ "$PYPDF_READY" -eq 0 ]; then
    echo ""
    fail "No converter available."
    echo -e "${YELLOW}    Primary:  npm ci   (installs locked @opendataloader/pdf)${NC}"
    echo -e "${YELLOW}    Fallback: run scripts/setup.sh to create the project .venv${NC}"
    exit 1
fi

echo ""
if [ "$FAILED" -eq 0 ]; then echo -e "${GREEN}Summary: $CONVERTED converted, 0 failed${NC}"
else echo -e "${YELLOW}Summary: $CONVERTED converted, $FAILED failed${NC}"; for f in "${FAILLIST[@]}"; do info "failed: $f"; done; fi
if [ "$USED_FALLBACK" -eq 1 ]; then
    warn "Used pypdf (text-only) - tables/layout not preserved."
    info "For best quality install Java so @opendataloader/pdf can run, then re-convert."
fi
echo ""
echo -e "${CYAN}Next: put the .md in reference/ (or ingest from pdf-source/), then run ingest-reference.${NC}"
[ "$FAILED" -eq 0 ] && exit 0 || exit 1
