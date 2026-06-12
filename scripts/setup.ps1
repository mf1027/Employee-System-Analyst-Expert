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

# -- 5. Summary ----------------------------------------------------------------

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
