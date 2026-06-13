# fetch-libreoffice-local.ps1 - Install LibreOffice INTO the project (Windows)
# Downloads the official LibreOffice MSI and extracts it into engines/ via an
# administrative install (msiexec /a) - pure file extraction, NO system install,
# NO admin rights, NO registry changes. The result is a self-contained LibreOffice
# the document-skills resolve automatically (engines/ is checked before the system).
#
#   scripts\fetch-libreoffice-local.ps1
#   scripts\fetch-libreoffice-local.ps1 -Version 26.2.4
#   scripts\fetch-libreoffice-local.ps1 -Force      # re-extract even if present

param(
    [string]$Version = "26.2.4",
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$enginesDir = Join-Path $root "engines"
$targetDir  = Join-Path $enginesDir "LibreOffice"

function Find-Soffice {
    if (Test-Path $enginesDir) {
        $hit = Get-ChildItem $enginesDir -Recurse -Filter "soffice.exe" -ErrorAction SilentlyContinue |
               Select-Object -First 1
        if ($hit) { return $hit.FullName }
    }
    return $null
}

# Already present?
$existing = Find-Soffice
if ($existing -and -not $Force) {
    Write-Host "[OK] LibreOffice already in project: $existing" -ForegroundColor Green
    Write-Host "     Use -Force to re-extract." -ForegroundColor Gray
    exit 0
}

New-Item -ItemType Directory -Force $enginesDir | Out-Null
if ($Force -and (Test-Path $targetDir)) { Remove-Item -Recurse -Force $targetDir -Confirm:$false }

$msiName = "LibreOffice_${Version}_Win_x86-64.msi"
$url = "https://download.documentfoundation.org/libreoffice/stable/$Version/win/x86_64/$msiName"
$msiPath = Join-Path $env:TEMP $msiName

Write-Host "==> Downloading LibreOffice $Version (~360 MB)..." -ForegroundColor Cyan
Write-Host "    $url" -ForegroundColor Gray
try {
    $ProgressPreference = 'SilentlyContinue'   # much faster Invoke-WebRequest
    Invoke-WebRequest -Uri $url -OutFile $msiPath -UseBasicParsing
} catch {
    Write-Host "[FAIL] Download failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "       Check the version exists at download.documentfoundation.org, or pass -Version." -ForegroundColor Yellow
    exit 1
}
$sizeMB = [math]::Round((Get-Item $msiPath).Length / 1MB, 1)
Write-Host "    [OK] downloaded ($sizeMB MB)" -ForegroundColor Green

Write-Host "==> Extracting into engines\ (msiexec /a - no system install)..." -ForegroundColor Cyan
$log = Join-Path $env:TEMP "lo-admin-install.log"
$proc = Start-Process msiexec.exe -Wait -PassThru -ArgumentList @(
    "/a", "`"$msiPath`"", "/qn", "TARGETDIR=`"$targetDir`"", "/L*v", "`"$log`""
)
if ($proc.ExitCode -ne 0) {
    Write-Host "[FAIL] msiexec /a returned exit $($proc.ExitCode). See log: $log" -ForegroundColor Red
    exit 1
}

Remove-Item $msiPath -Force -ErrorAction SilentlyContinue

$soffice = Find-Soffice
if ($soffice) {
    Write-Host ""
    Write-Host "[OK] LibreOffice extracted into the project:" -ForegroundColor Green
    Write-Host "     $soffice" -ForegroundColor Green
    Write-Host ""
    Write-Host "The document-skills will now resolve this copy first (before the system install)." -ForegroundColor Gray
    Write-Host "It rides in scripts\backup.ps1, so other Windows machines need zero install." -ForegroundColor Gray
    Write-Host "Verify with: scripts\verify-engines.ps1" -ForegroundColor Cyan
} else {
    Write-Host "[WARN] Extraction finished but soffice.exe not found under engines\." -ForegroundColor Yellow
    Write-Host "       Inspect $targetDir and the log: $log" -ForegroundColor Yellow
    exit 1
}
