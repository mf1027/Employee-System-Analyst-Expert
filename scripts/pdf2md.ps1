# pdf2md.ps1 - Convert PDF(s) to Markdown for ingestion into reference/
# Usage:
#   .\scripts\pdf2md.ps1                                # convert every *.pdf in pdf-source\
#   .\scripts\pdf2md.ps1 -InputFile "sample.pdf"        # bare name: pdf-source\ first, then current dir
#   .\scripts\pdf2md.ps1 -InputFile "reference\doc.pdf" # explicit path (relative or absolute)
#   .\scripts\pdf2md.ps1 -InputFile "reference\"        # a folder: convert all *.pdf inside it
#   .\scripts\pdf2md.ps1 -InputFile "doc.pdf" -OutputFile "out.md"   # single file, custom output
#   .\scripts\pdf2md.ps1 -Recurse                       # include subfolders when batching
#
# Converter priority:
#   1. @opendataloader/pdf  (installed in node_modules - primary, best quality)
#   2. pypdf                (pip install pypdf - fallback, plain text extraction only)
#
# Output: <name>.md next to each source PDF (unless -OutputFile is given for a single file).
# After conversion: put the .md in reference/ (or ingest from pdf-source/) then run ingest-reference.

param(
    [Parameter(Mandatory=$false, Position=0)]
    [string]$InputFile,

    [Parameter(Mandatory=$false)]
    [string]$OutputFile,

    [switch]$Recurse
)

$ErrorActionPreference = "Stop"

function Write-OK   { param($msg) Write-Host "[OK]   $msg" -ForegroundColor Green }
function Write-FAIL { param($msg) Write-Host "[FAIL] $msg" -ForegroundColor Red }
function Write-WARN { param($msg) Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-INFO { param($msg) Write-Host "       $msg" -ForegroundColor Gray }

$root      = Split-Path $PSScriptRoot -Parent
$pdfSource = Join-Path $root "pdf-source"
$childArgs = @{ Filter = "*.pdf"; File = $true }
if ($Recurse) { $childArgs.Recurse = $true }

# -- Resolve which PDF(s) to convert -------------------------------------------

$pdfs = @()

if ([string]::IsNullOrWhiteSpace($InputFile)) {
    # No argument -> batch the pdf-source\ folder
    if (-not (Test-Path $pdfSource)) {
        Write-WARN "No file given and pdf-source\ does not exist yet."
        Write-INFO "Drop PDFs into pdf-source\ and re-run, or pass -InputFile <path>."
        exit 0
    }
    $pdfs = @(Get-ChildItem -Path $pdfSource @childArgs)
    if ($pdfs.Count -eq 0) { Write-WARN "No PDFs found in pdf-source\."; exit 0 }
    Write-INFO "Batch: $($pdfs.Count) PDF(s) from pdf-source\"
}
elseif (Test-Path $InputFile -PathType Container) {
    # A folder -> batch every *.pdf inside it
    $pdfs = @(Get-ChildItem -Path $InputFile @childArgs)
    if ($pdfs.Count -eq 0) { Write-WARN "No PDFs found in $InputFile"; exit 0 }
    Write-INFO "Batch: $($pdfs.Count) PDF(s) from $InputFile"
}
else {
    # A file: explicit path vs bare name (pdf-source\ first, then current dir)
    $hasDir = ($InputFile -match '[\\/]') -or [System.IO.Path]::IsPathRooted($InputFile)
    $resolved = $null
    if ($hasDir) {
        if (Test-Path $InputFile -PathType Leaf) { $resolved = (Resolve-Path $InputFile).Path }
    }
    else {
        $inSource = Join-Path $pdfSource $InputFile
        $inCwd    = Join-Path (Get-Location).Path $InputFile
        if (Test-Path $inSource -PathType Leaf) {
            $resolved = (Resolve-Path $inSource).Path
            Write-INFO "Found in pdf-source\: $InputFile"
        }
        elseif (Test-Path $inCwd -PathType Leaf) {
            $resolved = (Resolve-Path $inCwd).Path
            Write-INFO "Found in current directory: $InputFile"
        }
    }
    if (-not $resolved) {
        Write-FAIL "Not found: '$InputFile'"
        if (-not $hasDir) { Write-INFO "Looked in pdf-source\ then the current directory." }
        exit 1
    }
    if ([System.IO.Path]::GetExtension($resolved).ToLower() -ne ".pdf") {
        Write-WARN "Not a .pdf extension: $resolved (trying anyway)"
    }
    $pdfs = @(Get-Item $resolved)
}

if ($OutputFile -and $pdfs.Count -gt 1) {
    Write-WARN "-OutputFile ignored for a batch of $($pdfs.Count); writing <name>.md next to each PDF."
    $OutputFile = $null
}

# -- Converters ----------------------------------------------------------------

# Resolve the opendataloader shim - on Windows the runnable one is the .cmd,
# not the extensionless bash shim (calling the latter silently no-ops).
$odlBin = Join-Path $root "node_modules\.bin\opendataloader-pdf"
if ($env:OS -eq 'Windows_NT' -and (Test-Path "$odlBin.cmd")) { $odlBin = "$odlBin.cmd" }
$odlAvailable = Test-Path $odlBin
$tempPy = [System.IO.Path]::GetTempFileName() + ".py"
$script:pypdfChecked = $false
$script:pypdfReady   = $false
$script:usedFallback = $false

function Test-Pypdf {
    if (-not $script:pypdfChecked) {
        $script:pypdfChecked = $true
        # $ErrorActionPreference = "Stop" causes PowerShell 5.1 to turn native
        # stderr into a terminating NativeCommandError — temporarily suspend it.
        $prev = $ErrorActionPreference; $ErrorActionPreference = "SilentlyContinue"
        try { python -c "import pypdf" 2>&1 | Out-Null } catch {}
        $script:pypdfReady = ($LASTEXITCODE -eq 0)
        $ErrorActionPreference = $prev
        if ($script:pypdfReady) {
            @'
import pypdf, sys
reader = pypdf.PdfReader(sys.argv[1])
out = []
for i, page in enumerate(reader.pages, 1):
    out.append(f"## Page {i}")
    out.append(page.extract_text() or "")
    out.append("")
open(sys.argv[2], "w", encoding="utf-8").write("\n".join(out))
'@ | Out-File -FilePath $tempPy -Encoding utf8
        }
    }
    return $script:pypdfReady
}

function Convert-OnePdf {
    # Success is judged by the output FILE existing, not by exit codes - that is
    # robust to the opendataloader shim no-opping or Java being absent.
    param($inputAbs, $outPath)
    $base = [System.IO.Path]::GetFileNameWithoutExtension($inputAbs)
    $outDir = Split-Path $outPath -Parent
    if (Test-Path $outPath) { [System.IO.File]::Delete($outPath) }   # clear stale output

    if ($odlAvailable) {
        try { & $odlBin $inputAbs -f markdown -o $outDir -q --image-output off 2>$null | Out-Null } catch {}
        $produced = Join-Path $outDir "$base.md"
        if ((Test-Path $produced) -and ($produced -ne $outPath)) { Move-Item $produced $outPath -Force }
        if ((Test-Path $outPath) -and ((Get-Item $outPath).Length -gt 0)) { return "opendataloader" }
    }
    if (Test-Pypdf) {
        $prev = $ErrorActionPreference; $ErrorActionPreference = "SilentlyContinue"
        try { python $tempPy $inputAbs $outPath 2>&1 | Out-Null } catch {}
        $ErrorActionPreference = $prev
        if (Test-Path $outPath) { $script:usedFallback = $true; return "pypdf" }
    }
    return $null
}

# -- Run -----------------------------------------------------------------------

$converted = 0; $failed = 0; $failList = @()
foreach ($pdf in $pdfs) {
    $inputAbs = $pdf.FullName
    if ($OutputFile) {
        $outPath = $OutputFile
        if (-not [System.IO.Path]::IsPathRooted($outPath)) { $outPath = Join-Path (Get-Location).Path $outPath }
    } else {
        $base = [System.IO.Path]::GetFileNameWithoutExtension($inputAbs)
        $outPath = Join-Path (Split-Path $inputAbs -Parent) "$base.md"
    }
    Write-Host "-> $($pdf.Name)" -ForegroundColor Cyan
    $via = Convert-OnePdf $inputAbs $outPath
    if ($via) { Write-OK "  $outPath  [$via]"; $converted++ }
    else { Write-FAIL "  failed: $($pdf.Name)"; $failed++; $failList += $pdf.Name }
}

if (Test-Path $tempPy) { Remove-Item $tempPy -Force }

if ($converted -eq 0 -and -not $odlAvailable -and -not $script:pypdfReady) {
    Write-Host ""
    Write-FAIL "No converter available."
    Write-Host "    Primary:  npm install   (installs @opendataloader/pdf in node_modules)" -ForegroundColor Yellow
    Write-Host "    Fallback: pip install pypdf" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

Write-Host ""
Write-Host "Summary: $converted converted, $failed failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Yellow" })
foreach ($f in $failList) { Write-INFO "failed: $f" }
if ($script:usedFallback) {
    Write-WARN "Used pypdf (text-only) - tables/layout not preserved."
    Write-INFO "For best quality install Java so @opendataloader/pdf can run, then re-convert."
}
Write-Host ""
Write-Host "Next: put the .md in reference\ (or ingest from pdf-source\), then run ingest-reference." -ForegroundColor Cyan
if ($failed -gt 0) { exit 1 } else { exit 0 }
