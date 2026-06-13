# verify-engines.ps1 - End-to-end test of the document engines (Windows)
# Proves docx/pptx/xlsx/pdf generation actually works on THIS machine.
# Run after setup, after fetch-libreoffice-local, or any time you doubt it.
#
#   scripts\verify-engines.ps1

$root = Split-Path $PSScriptRoot -Parent
$officeDir = Join-Path $root "ai-sa-employee\document-skills\docx\scripts\office"
$pass = 0; $fail = 0
function Check($name, $ok, $detail="") {
    if ($ok) { Write-Host ("  [PASS] {0}" -f $name) -ForegroundColor Green; $script:pass++ }
    else     { Write-Host ("  [FAIL] {0} {1}" -f $name, $detail) -ForegroundColor Red; $script:fail++ }
}

Write-Host "`n=== Document Engine Verification ===" -ForegroundColor Cyan

# 1. soffice resolves via the patched resolver (engines/ -> PATH -> system)
$soffice = python -c "import sys; sys.path.insert(0, r'$officeDir'); from soffice import get_soffice_cmd; print(get_soffice_cmd())" 2>$null
$sofficeOK = $soffice -and ((Test-Path $soffice) -or ($soffice -eq "soffice" -and (Get-Command soffice -ErrorAction SilentlyContinue)))
Check "LibreOffice resolver" $sofficeOK $soffice
if ($soffice -like "*\engines\*") { Write-Host "         (using in-project engines\ copy)" -ForegroundColor Gray }
elseif ($sofficeOK)              { Write-Host "         (using system install: $soffice)" -ForegroundColor Gray }

# 2. Poppler
$popplerOK = [bool](Get-Command pdftoppm -ErrorAction SilentlyContinue)
Check "Poppler (pdftoppm)" $popplerOK

# 3. Python packages
$pkgOK = $false
python -c "import defusedxml, lxml, openpyxl, pdf2image, pdfplumber, PIL, pypdf" 2>$null
if ($LASTEXITCODE -eq 0) { $pkgOK = $true }
Check "Python packages (7)" $pkgOK

if (-not $sofficeOK) {
    Write-Host "`n  LibreOffice missing - skipping conversion tests." -ForegroundColor Yellow
    Write-Host "  Fix: scripts\setup.ps1  OR  scripts\fetch-libreoffice-local.ps1`n" -ForegroundColor Yellow
    exit 1
}

# 4. End-to-end conversion chain
$t = Join-Path $env:TEMP ("engine-verify-" + [guid]::NewGuid().ToString("N").Substring(0,8))
New-Item -ItemType Directory -Force $t | Out-Null
try {
    Set-Content "$t\in.txt" -Value "Engine verification document." -Encoding ascii
    Set-Content "$t\in.csv" -Value "item,qty`nwidget,5" -Encoding ascii

    & $soffice --headless --convert-to docx --outdir $t "$t\in.txt" 2>$null | Out-Null
    Check "txt -> docx" (Test-Path "$t\in.docx")

    & $soffice --headless --convert-to pdf --outdir $t "$t\in.docx" 2>$null | Out-Null
    Check "docx -> pdf" (Test-Path "$t\in.pdf")

    & $soffice --headless --convert-to xlsx --outdir $t "$t\in.csv" 2>$null | Out-Null
    Check "csv -> xlsx" (Test-Path "$t\in.xlsx")

    if ($popplerOK -and (Test-Path "$t\in.pdf")) {
        python -c "from pdf2image import convert_from_path; convert_from_path(r'$t\in.pdf')[0].save(r'$t\p1.png')" 2>$null
        Check "pdf -> png (Poppler)" (Test-Path "$t\p1.png")
    }

    python -c "import openpyxl; wb=openpyxl.Workbook(); wb.active['A1']='x'; wb.save(r'$t\native.xlsx')" 2>$null
    Check "openpyxl create xlsx" (Test-Path "$t\native.xlsx")

    if (Test-Path "$t\in.pdf") {
        $pages = python -c "from pypdf import PdfReader; print(len(PdfReader(r'$t\in.pdf').pages))" 2>$null
        Check "pypdf read pdf" ($pages -ge 1) "pages=$pages"
    }
} finally {
    Remove-Item -Recurse -Force $t -ErrorAction SilentlyContinue
}

Write-Host "`n=== Result: $pass passed, $fail failed ===" -ForegroundColor $(if ($fail -eq 0) {"Green"} else {"Red"})
if ($fail -eq 0) { Write-Host "All document engines working.`n" -ForegroundColor Green; exit 0 }
else { Write-Host "Some engines failed - see above.`n" -ForegroundColor Red; exit 1 }
