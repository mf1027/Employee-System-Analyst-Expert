# setup.ps1 - First-time setup for Employee System Analyst Expert (Windows)
# Run once after cloning to a new machine:
#   cd "Employee System Analyst Expert"
#   .\scripts\setup.ps1

[CmdletBinding()]
param(
    [switch]$InstallSoup,
    [switch]$InstallSoupTraining,
    [string]$SoupArchivePath
)

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
    Write-WARN "@opendataloader/pdf binary not found - pdf2md.ps1 will fall back to pypdf"
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
$ponytailKey    = "ponytail@ponytail"
$claudeMemOK    = $false
$contextModeOK  = $false
$ponytailClaudeOK = $false
$ponytailCodexOK  = $false
$duplicateClaudePonytail = @()
$claudeCLI = Get-Command claude -ErrorAction SilentlyContinue
$claudeCLIAvailable = $null -ne $claudeCLI
$codexCLI = Get-Command codex -ErrorAction SilentlyContinue
$codexCLIAvailable = $null -ne $codexCLI

if (Test-Path $ipPath) {
    $ip = Get-Content $ipPath -Raw | ConvertFrom-Json
    $pluginNames = $ip.plugins.PSObject.Properties.Name
    $claudeMemOK   = $pluginNames -contains $claudeMemKey
    $contextModeOK = $pluginNames -contains $contextModeKey
    $ponytailClaudeOK = $pluginNames -contains $ponytailKey
    $duplicateClaudePonytail = @($pluginNames | Where-Object { $_ -match '(?i)ponytail' -and $_ -ne $ponytailKey })
}

if ($duplicateClaudePonytail.Count -gt 0) {
    Write-WARN "Another Ponytail package is active in Claude Code; do not remove it automatically."
}

if ($codexCLIAvailable) {
    try {
        $codexPluginList = (& $codexCLI.Source plugin list 2>&1 | Out-String)
        if ($LASTEXITCODE -eq 0 -and $codexPluginList -match '(?i)ponytail') {
            $ponytailCodexOK = $true
        }
        if ($codexPluginList -match '(?i)engineering-suite-ponytail') {
            Write-WARN "Another Ponytail package is active in Codex; do not remove it automatically."
        }
    } catch {
        Write-WARN "Could not inspect Codex plugins - verify with: codex plugin list"
    }
} else {
    Write-WARN "Codex CLI not found - install it separately before using Codex with this repo."
}

if ($claudeMemOK)   { Write-OK "claude-mem plugin installed" }
else                { Write-WARN "claude-mem NOT installed" }

if ($contextModeOK) { Write-OK "context-mode plugin installed" }
else                { Write-WARN "context-mode NOT installed" }

if ($ponytailClaudeOK) { Write-OK "Ponytail plugin installed for Claude Code" }
else                   { Write-WARN "Ponytail plugin NOT installed for Claude Code" }

if ($ponytailCodexOK) { Write-OK "Ponytail plugin detected for Codex" }
elseif ($codexCLIAvailable) { Write-WARN "Ponytail plugin NOT detected for Codex" }

if ($claudeCLIAvailable) { Write-OK "Claude host available" }
else                    { Write-WARN "Claude host unavailable - install Claude Code separately before using this repo." }

if ($codexCLIAvailable) { Write-OK "Codex host available" }
else                   { Write-WARN "Codex host unavailable - install Codex CLI separately before using this repo." }

$ponytailRuntimeOK = $ponytailClaudeOK -and $ponytailCodexOK
if ($ponytailRuntimeOK) { Write-OK "Ponytail runtime verified" }
else                    { Write-WARN "Ponytail runtime not fully verified" }

if (-not $claudeMemOK -or -not $contextModeOK -or -not $ponytailClaudeOK -or -not $ponytailCodexOK) {
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
    if (-not $ponytailClaudeOK) {
        Write-Host "      /plugin marketplace add DietrichGebert/ponytail" -ForegroundColor Yellow
        Write-Host "      /plugin install ponytail@ponytail" -ForegroundColor Yellow
    }
    if (-not $ponytailCodexOK) {
        Write-Host "    In Codex, run:" -ForegroundColor White
        Write-Host "      codex plugin marketplace add DietrichGebert/ponytail" -ForegroundColor Yellow
        Write-Host "      codex plugin add ponytail@ponytail" -ForegroundColor Yellow
    }
    Write-Host "    Review/trust Ponytail hooks, then restart Claude Code or open a fresh Codex task." -ForegroundColor White
    Write-Host "    Ponytail lifecycle hooks require Node.js (already checked above)." -ForegroundColor Gray
}

# -- 5. Soup tool check/install -------------------------------------------------

Write-Step "Checking Soup model-preparation tool"
$soupArgs = @((Join-Path $PSScriptRoot "soup-setup.mjs"), "--repo", $root)
if ($SoupArchivePath) { $soupArgs += @("--archive", $SoupArchivePath) }
if ($InstallSoup -or $InstallSoupTraining) { $soupArgs += "--install" }
if ($InstallSoupTraining) { $soupArgs += "--training" }

& node @soupArgs
$soupExit = $LASTEXITCODE
if ($soupExit -eq 0) {
    Write-OK "Soup runtime verified"
} elseif ($InstallSoup -or $InstallSoupTraining) {
    Write-WARN "Soup installation/check did not complete; model preparation remains blocked"
    Write-INFO "  Re-run with a valid Soup archive and Python 3.10-3.12, or inspect the reported reason."
} else {
    Write-INFO "Soup is optional. To install it into the ignored repo-local environment:"
    Write-INFO "  .\scripts\setup.ps1 -InstallSoup -SoupArchivePath <path-to-Soup-0.75.0.zip>"
    Write-INFO "  Add -InstallSoupTraining only when training dependencies are explicitly needed."
}

# -- 6. Ollama local-model check -----------------------------------------------

Write-Step "Checking Ollama local-model runtime"

$ollamaCLI = Get-Command ollama -ErrorAction SilentlyContinue
$ollamaInstalled = $null -ne $ollamaCLI
$ollamaServiceOK = $false
$ollamaModelConfigured = -not [string]::IsNullOrWhiteSpace($env:OLLAMA_MODEL)
$ollamaModelOK = $false
$ollamaCapabilityOK = $false
$ollamaCloudModel = $ollamaModelConfigured -and $env:OLLAMA_MODEL -match '(?i)(^|[-:])cloud($|[-:])'
$ollamaHost = if ([string]::IsNullOrWhiteSpace($env:OLLAMA_HOST)) { "http://localhost:11434" } else { $env:OLLAMA_HOST.TrimEnd('/') }

if ($ollamaInstalled) {
    Write-OK "Ollama installed"
    Write-OK "Ollama CLI available"
    try {
        Invoke-RestMethod -Uri "$ollamaHost/api/tags" -Method Get -TimeoutSec 3 | Out-Null
        $ollamaServiceOK = $true
        Write-OK "Ollama service reachable at $ollamaHost"
    } catch {
        Write-WARN "Ollama service not reachable at $ollamaHost - start Ollama before launching an agent"
    }

    if ($ollamaModelConfigured) {
        Write-OK "Explicit model configured: $env:OLLAMA_MODEL"
    } else {
        Write-WARN "Explicit model not configured"
    }

    if ($ollamaCloudModel) {
        Write-WARN "Cloud model names are not allowed for local-runtime verification: $env:OLLAMA_MODEL"
    } elseif ($ollamaModelConfigured) {
        $ollamaModels = (& $ollamaCLI.Source ls 2>&1 | Out-String)
        $ollamaModelOK = ($LASTEXITCODE -eq 0) -and @($ollamaModels -split "`r?`n" | Where-Object {
            $parts = $_.Trim() -split '\s+'
            $parts.Count -gt 0 -and $parts[0] -eq $env:OLLAMA_MODEL
        }).Count -gt 0
        if ($ollamaModelOK) {
            Write-OK "Explicit Ollama model installed locally: $env:OLLAMA_MODEL"
        } else {
            Write-WARN "OLLAMA_MODEL '$env:OLLAMA_MODEL' is not present in ollama ls"
        }
    } else {
        Write-WARN "OLLAMA_MODEL is not set - local-model verification is incomplete"
    }
} else {
    Write-WARN "Ollama not installed - local-model execution is unavailable"
}

if ($ollamaInstalled -and $ollamaServiceOK -and $ollamaModelOK) {
    Write-Host "    Read-only Ollama context/tool-calling probe:" -ForegroundColor White
    $ollamaVerify = Join-Path $PSScriptRoot "verify-ollama-runtime.mjs"
    & node $ollamaVerify --host $ollamaHost --model $env:OLLAMA_MODEL
    $ollamaCapabilityOK = $LASTEXITCODE -eq 0
    Write-INFO "Context capacity and Tool calling verified by verify-ollama-runtime.mjs; see the probe status above."
    if (-not $ollamaCapabilityOK) {
        Write-WARN "Ollama context/tool-calling verification did not pass"
    }
} else {
    Write-INFO "Context capacity and Tool calling verified: not run because Ollama, service, or exact model is unavailable."
    Write-INFO "Ollama context/tool-calling probe skipped until the local service and exact model are verified."
}

if (-not $ollamaInstalled -or -not $ollamaServiceOK -or -not $ollamaModelConfigured -or -not $ollamaModelOK -or -not $ollamaCapabilityOK) {
    Write-Host "    Configure an explicit local model before verification:" -ForegroundColor White
    Write-Host '      `$env:OLLAMA_MODEL = "<local-model-name>"' -ForegroundColor Yellow
    Write-Host '      ollama pull <OLLAMA_MODEL>  # manual operator action; setup never runs this' -ForegroundColor Yellow
    Write-Host '      ollama launch claude --model $env:OLLAMA_MODEL' -ForegroundColor Yellow
    Write-Host '      ollama launch codex --model $env:OLLAMA_MODEL' -ForegroundColor Yellow
    Write-Host "    Ollama only supplies inference; the host runtime supplies skills, tools, permissions, and hooks." -ForegroundColor Gray
}

# -- 7. Verify document engines ------------------------------------------------

Write-Step "Verifying document engines (end-to-end)"
$verify = Join-Path $PSScriptRoot "verify-engines.ps1"
if (Test-Path $verify) {
    & $verify
} else {
    Write-WARN "verify-engines.ps1 not found - skipping engine verification"
}

# -- 8. Summary ----------------------------------------------------------------

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  Setup complete" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

if (-not $claudeMemOK -or -not $contextModeOK -or -not $ponytailRuntimeOK -or -not $claudeCLIAvailable -or -not $codexCLIAvailable -or
    -not $ollamaInstalled -or -not $ollamaServiceOK -or -not $ollamaModelConfigured -or -not $ollamaModelOK -or
    -not $ollamaCapabilityOK -or
    (($InstallSoup -or $InstallSoupTraining) -and $soupExit -ne 0)) {
    Write-Host "  Action needed: install the missing plugin(s) listed above." -ForegroundColor Yellow
} else {
    Write-Host "  All dependencies ready. Open this folder in Claude Code." -ForegroundColor Green
}
Write-Host ""
