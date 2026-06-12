# pdf2md.ps1 - Convert PDF to Markdown for ingestion into reference/
# Usage:
#   .\scripts\pdf2md.ps1 -InputFile "reference\document.pdf"
#   .\scripts\pdf2md.ps1 -InputFile "reference\document.pdf" -OutputFile "reference\out.md"
#
# Converter priority:
#   1. @opendataloader/pdf  (installed in node_modules — primary, best quality)
#   2. pypdf                (pip install pypdf — fallback, plain text extraction only)
#
# After conversion: ensure the .md is in reference/ then run ingest-reference in Claude Code.

param(
    [Parameter(Mandatory=$true)]
    [string]$InputFile,

    [Parameter(Mandatory=$false)]
    [string]$OutputFile
)

$ErrorActionPreference = "Stop"

function Write-OK   { param($msg) Write-Host "[OK]   $msg" -ForegroundColor Green }
function Write-FAIL { param($msg) Write-Host "[FAIL] $msg" -ForegroundColor Red }
function Write-WARN { param($msg) Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-INFO { param($msg) Write-Host "       $msg" -ForegroundColor Gray }

# -- Resolve root and paths ----------------------------------------------------

$root = Split-Path $PSScriptRoot -Parent

if (-not (Test-Path $InputFile)) {
    Write-FAIL "File not found: $InputFile"
    exit 1
}
$inputAbs = (Resolve-Path $InputFile).Path
$inputDir  = Split-Path $inputAbs -Parent
$inputBase = [System.IO.Path]::GetFileNameWithoutExtension($inputAbs)

# Derive expected output path
if (-not $OutputFile) {
    $OutputFile = Join-Path $inputDir "$inputBase.md"
}
if (-not [System.IO.Path]::IsPathRooted($OutputFile)) {
    $OutputFile = Join-Path (Get-Location) $OutputFile
}
$outputDir  = Split-Path $OutputFile -Parent
$outputBase = [System.IO.Path]::GetFileNameWithoutExtension($OutputFile)

Write-Host "Input:  $inputAbs" -ForegroundColor Cyan
Write-Host "Output: $OutputFile" -ForegroundColor Cyan
Write-Host ""

$converted = $false
$tempPy    = [System.IO.Path]::GetTempFileName() + ".py"

# -- Attempt 1: @opendataloader/pdf (node_modules) -----------------------------

$odlBin = Join-Path $root "node_modules\.bin\opendataloader-pdf"
if (Test-Path $odlBin) {
    Write-INFO "Using: @opendataloader/pdf"
    & $odlBin $inputAbs -f markdown -o $outputDir -q --image-output off
    if ($LASTEXITCODE -eq 0) {
        # Rename if the converter used the input base name and it differs from desired output name
        $producedFile = Join-Path $outputDir "$inputBase.md"
        if ((Test-Path $producedFile) -and ($producedFile -ne $OutputFile)) {
            Move-Item -Path $producedFile -Destination $OutputFile -Force
        }
        $converted = $true
    } else {
        Write-WARN "@opendataloader/pdf returned exit code $LASTEXITCODE — trying fallback"
    }
} else {
    Write-WARN "@opendataloader/pdf binary not found at $odlBin"
    Write-INFO "Run: npm install  (from project root) to install it"
}

# -- Attempt 2: pypdf fallback -------------------------------------------------

if (-not $converted) {
    $check = python -c "import pypdf" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-WARN "Using: pypdf (text extraction only — tables and layout not preserved)"
        @'
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
'@ | Out-File -FilePath $tempPy -Encoding utf8
        python $tempPy $inputAbs $OutputFile
        $converted = $true
    }
}

# -- Clean up ------------------------------------------------------------------

if (Test-Path $tempPy) { Remove-Item $tempPy -Force }

# -- Result --------------------------------------------------------------------

if (-not $converted) {
    Write-Host ""
    Write-FAIL "No converter available."
    Write-Host ""
    Write-Host "    Primary:  npm install   (installs @opendataloader/pdf in node_modules)" -ForegroundColor Yellow
    Write-Host "    Fallback: pip install pypdf" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

Write-Host ""
Write-OK "Converted: $OutputFile"
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-INFO "1. Ensure the .md file is in reference/"
Write-INFO "2. Open Claude Code and run: ingest-reference"
Write-Host ""
