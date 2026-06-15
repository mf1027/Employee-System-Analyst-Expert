# setup.ps1 - First-time setup for Employee System Analyst Expert (Windows)
# Run once after cloning to a new machine:
#   cd "Employee System Analyst Expert"
#   .\scripts\setup.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent

function Write-Step { param($msg) Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-OK   { param($msg) Write-Host "    [OK]   $msg" -ForegroundColor Green }
function Write-FAIL { param($msg) Write-Host "    [FAIL] $msg" -ForegroundColor Red; $script:failed = $true }
function Write-WARN { param($msg) Write-Host "    [WARN] $msg" -ForegroundColor Yellow }
function Write-INFO { param($msg) Write-Host "    $msg" -ForegroundColor Gray }

$script:failed = $false

# -- 1. Prerequisites ----------------------------------------------------------

Write-Step "Checking prerequisites"

# Node.js >= 20
try {
    $nodeVer = node --version 2>&1
    $nodeMajor = [int]($nodeVer -replace 'v(\d+)\..*', '$1')
    if ($nodeMajor -ge 20) {
        Write-OK "Node.js $nodeVer"
    } else {
        Write-FAIL "Node.js $nodeVer detected - need >= 20. Get it: https://nodejs.org"
    }
} catch {
    Write-FAIL "Node.js not found. Get it: https://nodejs.org"
}

# Python >= 3.10
try {
    $pyRaw = python --version 2>&1
    if ($pyRaw -match 'Python (\d+)\.(\d+)') {
        $pyMajor = [int]$Matches[1]
        $pyMinor = [int]$Matches[2]
        if ($pyMajor -gt 3 -or ($pyMajor -eq 3 -and $pyMinor -ge 10)) {
            Write-OK "Python $pyRaw"
        } else {
            Write-FAIL "Python $pyRaw detected - need >= 3.10. Get it: https://python.org"
        }
    } else {
        Write-FAIL "Could not parse Python version. Get it: https://python.org"
    }
} catch {
    Write-FAIL "Python not found. Get it: https://python.org"
}

# Bun (needed for context-mode hooks)
$bunPath = "$env:USERPROFILE\.bun\bin\bun.exe"
if (Test-Path $bunPath) {
    $bunVer = & $bunPath --version 2>&1
    Write-OK "Bun $bunVer"
} else {
    Write-WARN "Bun not found - context-mode hooks will not fire."
    Write-INFO "  Install: irm bun.sh/install.ps1 | iex"
}

if ($script:failed) {
    Write-Host "`n[!] Fix the failures above before continuing." -ForegroundColor Red
    exit 1
}

# -- 2. Node dependencies ------------------------------------------------------

Write-Step "Installing Node.js dependencies (npm install)"
Set-Location $root
npm install
if ($LASTEXITCODE -ne 0) {
    Write-FAIL "npm install failed"
    exit 1
}
Write-OK "node_modules ready (claude-mem + context-mode + @opendataloader/pdf included)"

# -- Verify @opendataloader/pdf binary -----------------------------------------

$odlBin = Join-Path $root "node_modules\.bin\opendataloader-pdf"
if (Test-Path $odlBin) {
    Write-OK "@opendataloader/pdf binary ready"
} else {
    Write-WARN "@opendataloader/pdf binary not found — pdf2md.ps1 will fall back to pypdf"
}

# -- 3. Python dependencies ----------------------------------------------------

Write-Step "Installing Python dependencies"
try {
    pip install chromadb --quiet | Out-Null
    $chromaVer = python -c "import chromadb; print(chromadb.__version__)"
    Write-OK "chromadb $chromaVer"
} catch {
    Write-WARN "chromadb install failed - semantic memory search will fall back to keyword mode"
}

# Document-skills packages (docx/pptx/xlsx/pdf generation + reading)
try {
    pip install defusedxml lxml openpyxl pdf2image pdfplumber pillow pypdf --quiet | Out-Null
    python -c "import defusedxml, lxml, openpyxl, pdf2image, pdfplumber, PIL, pypdf" 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-OK "document-skills Python packages (7) ready"
    } else {
        Write-WARN "some document-skills packages failed to import - docx/pptx/xlsx/pdf skills may not work"
    }
} catch {
    Write-WARN "document-skills package install failed - docx/pptx/xlsx/pdf skills may not work"
}

# -- 3b. Document engines: LibreOffice + Poppler + Java (Phase 2) ---------------

Write-Step "Checking document engines (LibreOffice + Poppler + Java)"

$wingetOK = $null -ne (Get-Command winget -ErrorAction SilentlyContinue)

# LibreOffice - needed for docx/pptx/xlsx conversion and recalc.
# Resolution mirrors get_soffice_cmd(): in-project engines/ -> PATH -> system install.
$sofficePath = "C:\Program Files\LibreOffice\program\soffice.exe"
$engineSoffice = Get-ChildItem (Join-Path $root "engines") -Recurse -Filter "soffice.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($engineSoffice) {
    Write-OK "LibreOffice present (in-project engines\)"
} elseif ((Test-Path $sofficePath) -or (Get-Command soffice -ErrorAction SilentlyContinue)) {
    Write-OK "LibreOffice present (system)"
} elseif ($wingetOK) {
    Write-INFO "Installing LibreOffice via winget (~355 MB, takes a few minutes)..."
    winget install --id TheDocumentFoundation.LibreOffice -e --accept-source-agreements --accept-package-agreements --silent
    if (Test-Path $sofficePath) { Write-OK "LibreOffice installed (system)" }
    else { Write-WARN "LibreOffice install did not complete - docx/pptx/xlsx skills unavailable" }
} else {
    Write-WARN "winget unavailable - falling back to in-project install (no admin needed)"
    Write-INFO "Running scripts\fetch-libreoffice-local.ps1 ..."
    & (Join-Path $PSScriptRoot "fetch-libreoffice-local.ps1")
    if ($LASTEXITCODE -eq 0) { Write-OK "LibreOffice installed into engines\" }
    else { Write-WARN "In-project install failed - install manually: https://www.libreoffice.org" }
}

# Poppler - needed for PDF -> image conversion (pdf2image)
if (Get-Command pdftoppm -ErrorAction SilentlyContinue) {
    Write-OK "Poppler present"
} elseif ($wingetOK) {
    Write-INFO "Installing Poppler via winget..."
    winget install --id oschwartz10612.Poppler -e --accept-source-agreements --accept-package-agreements --silent
    Write-OK "Poppler installed (restart your shell so PATH updates apply)"
} else {
    Write-WARN "Poppler not found and winget unavailable - install manually: https://github.com/oschwartz10612/poppler-windows"
}

# Java - needed by @opendataloader/pdf (high-fidelity PDF -> Markdown).
# Without it, pdf2md still works via the pypdf fallback, but text-only.
if (Get-Command java -ErrorAction SilentlyContinue) {
    Write-OK "Java present (high-fidelity PDF conversion available)"
} elseif ($wingetOK) {
    Write-INFO "Installing Java (Microsoft Build of OpenJDK 21) via winget..."
    winget install --id Microsoft.OpenJDK.21 -e --accept-source-agreements --accept-package-agreements --silent
    if (Get-Command java -ErrorAction SilentlyContinue) { Write-OK "Java installed" }
    else { Write-WARN "Java installed but not yet on PATH - restart your shell, then pdf2md uses @opendataloader/pdf" }
} else {
    Write-WARN "Java not found and winget unavailable - pdf2md will use pypdf (text-only)."
    Write-INFO "  For high-fidelity PDFs install a JRE 11+: https://adoptium.net"
}

# -- 4. Claude Code plugin check -----------------------------------------------

Write-Step "Checking Claude Code plugins"

$ipPath = "$env:USERPROFILE\.claude\plugins\installed_plugins.json"
$claudeMemKey   = "claude-mem@thedotmack"
$contextModeKey = "context-mode@context-mode"
$claudeMemOK    = $false
$contextModeOK  = $false

if (Test-Path $ipPath) {
    $ip = Get-Content $ipPath -Raw | ConvertFrom-Json
    $pluginNames = $ip.plugins.PSObject.Properties.Name
    $claudeMemOK   = $pluginNames -contains $claudeMemKey
    $contextModeOK = $pluginNames -contains $contextModeKey
}

if ($claudeMemOK)   { Write-OK "claude-mem plugin installed" }
else                { Write-WARN "claude-mem NOT installed" }

if ($contextModeOK) { Write-OK "context-mode plugin installed" }
else                { Write-WARN "context-mode NOT installed" }

if (-not $claudeMemOK -or -not $contextModeOK) {
    Write-Host ""
    Write-Host "    Open Claude Code in this directory and run:" -ForegroundColor White
    if (-not $claudeMemOK) {
        Write-Host "      /plugin marketplace add thedotmack/claude-mem" -ForegroundColor Yellow
        Write-Host "      /plugin install claude-mem@thedotmack" -ForegroundColor Yellow
    }
    if (-not $contextModeOK) {
        Write-Host "      /plugin marketplace add mksglu/context-mode" -ForegroundColor Yellow
        Write-Host "      /plugin install context-mode@context-mode" -ForegroundColor Yellow
    }
    Write-Host "    Then restart Claude Code." -ForegroundColor White
}

# -- 5. Verify document engines ------------------------------------------------

Write-Step "Verifying document engines (end-to-end)"
$verify = Join-Path $PSScriptRoot "verify-engines.ps1"
if (Test-Path $verify) {
    & $verify
} else {
    Write-WARN "verify-engines.ps1 not found - skipping engine verification"
}

# -- 6. Summary ----------------------------------------------------------------

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  Setup complete" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

if (-not $claudeMemOK -or -not $contextModeOK) {
    Write-Host "  Action needed: install the missing plugin(s) listed above." -ForegroundColor Yellow
} else {
    Write-Host "  All dependencies ready. Open this folder in Claude Code." -ForegroundColor Green
}
Write-Host ""
