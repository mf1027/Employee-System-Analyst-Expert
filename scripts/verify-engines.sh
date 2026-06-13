#!/usr/bin/env bash
# verify-engines.sh - End-to-end test of the document engines (Linux/Mac)
# Proves docx/pptx/xlsx/pdf generation actually works on THIS machine.
#
#   bash scripts/verify-engines.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"
OFFICE_DIR="$ROOT/ai-sa-employee/document-skills/docx/scripts/office"
PY_CMD="$(command -v python3 || command -v python)"
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[0;33m'; CYAN='\033[0;36m'; GRAY='\033[0;90m'; NC='\033[0m'
PASS=0; FAIL=0

check() { # name, ok(0/1), detail
    if [ "$2" = "1" ]; then echo -e "  ${GREEN}[PASS] $1${NC}"; PASS=$((PASS+1))
    else echo -e "  ${RED}[FAIL] $1 ${3:-}${NC}"; FAIL=$((FAIL+1)); fi
}

echo -e "\n${CYAN}=== Document Engine Verification ===${NC}"

# 1. soffice resolver
SOFFICE=$("$PY_CMD" -c "import sys; sys.path.insert(0, r'$OFFICE_DIR'); from soffice import get_soffice_cmd; print(get_soffice_cmd())" 2>/dev/null)
if [ "$SOFFICE" = "soffice" ]; then command -v soffice &>/dev/null && SOK=1 || SOK=0
elif [ -x "$SOFFICE" ]; then SOK=1; else SOK=0; fi
check "LibreOffice resolver" "$SOK" "$SOFFICE"
case "$SOFFICE" in
  */engines/*) echo -e "         ${GRAY}(using in-project engines/ copy)${NC}" ;;
  *) [ "$SOK" = "1" ] && echo -e "         ${GRAY}(using system install: $SOFFICE)${NC}" ;;
esac

# 2. Poppler
command -v pdftoppm &>/dev/null && POK=1 || POK=0
check "Poppler (pdftoppm)" "$POK"

# 3. Python packages
"$PY_CMD" -c "import defusedxml, lxml, openpyxl, pdf2image, pdfplumber, PIL, pypdf" 2>/dev/null && PKGOK=1 || PKGOK=0
check "Python packages (7)" "$PKGOK"

if [ "$SOK" != "1" ]; then
    echo -e "\n  ${YELLOW}LibreOffice missing - skipping conversion tests.${NC}"
    echo -e "  ${YELLOW}Fix: bash scripts/setup.sh${NC}\n"
    exit 1
fi

# 4. End-to-end chain
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
printf 'Engine verification document.' > "$T/in.txt"
printf 'item,qty\nwidget,5\n' > "$T/in.csv"

"$SOFFICE" --headless --convert-to docx --outdir "$T" "$T/in.txt" >/dev/null 2>&1
[ -f "$T/in.docx" ] && check "txt -> docx" 1 || check "txt -> docx" 0

"$SOFFICE" --headless --convert-to pdf --outdir "$T" "$T/in.docx" >/dev/null 2>&1
[ -f "$T/in.pdf" ] && check "docx -> pdf" 1 || check "docx -> pdf" 0

"$SOFFICE" --headless --convert-to xlsx --outdir "$T" "$T/in.csv" >/dev/null 2>&1
[ -f "$T/in.xlsx" ] && check "csv -> xlsx" 1 || check "csv -> xlsx" 0

if [ "$POK" = "1" ] && [ -f "$T/in.pdf" ]; then
    "$PY_CMD" -c "from pdf2image import convert_from_path; convert_from_path('$T/in.pdf')[0].save('$T/p1.png')" 2>/dev/null
    [ -f "$T/p1.png" ] && check "pdf -> png (Poppler)" 1 || check "pdf -> png (Poppler)" 0
fi

"$PY_CMD" -c "import openpyxl; wb=openpyxl.Workbook(); wb.active['A1']='x'; wb.save('$T/native.xlsx')" 2>/dev/null
[ -f "$T/native.xlsx" ] && check "openpyxl create xlsx" 1 || check "openpyxl create xlsx" 0

if [ -f "$T/in.pdf" ]; then
    PAGES=$("$PY_CMD" -c "from pypdf import PdfReader; print(len(PdfReader('$T/in.pdf').pages))" 2>/dev/null)
    [ "${PAGES:-0}" -ge 1 ] 2>/dev/null && check "pypdf read pdf" 1 || check "pypdf read pdf" 0 "pages=$PAGES"
fi

echo ""
if [ "$FAIL" -eq 0 ]; then echo -e "${GREEN}=== Result: $PASS passed, 0 failed - all engines working ===${NC}\n"; exit 0
else echo -e "${RED}=== Result: $PASS passed, $FAIL failed ===${NC}\n"; exit 1; fi
