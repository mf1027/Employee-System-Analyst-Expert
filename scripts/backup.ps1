# backup.ps1 - Back up all local-only client data (Windows)
# Client data is gitignored by design - this script is the safety net.
# Run weekly, or say "backup client data" to the employee.
#
#   scripts\backup.ps1
#   scripts\backup.ps1 -Destination "D:\Backups"
#   scripts\backup.ps1 -Keep 20
#   scripts\backup.ps1 -IncludeEngines   # also bundle the ~1 GB in-project LibreOffice

param(
    [string]$Destination = "$env:USERPROFILE\Documents\EmployeeBackups",
    [int]$Keep = 10,
    [switch]$IncludeEngines
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$stamp = Get-Date -Format "yyyy-MM-dd_HHmmss"

# Folders that hold data which exists nowhere else (all gitignored)
$targets = @(
    @{ Path = Join-Path $root "memory\clients"; Label = "memory/clients" },
    @{ Path = Join-Path $root ".claude-mem";    Label = ".claude-mem" },
    @{ Path = Join-Path $root "reference";      Label = "reference" },
    @{ Path = Join-Path $root "deliverables";   Label = "deliverables" }
)

# engines/ is reproducible (re-fetch anytime) so it is OFF by default - it would
# add ~1 GB to every backup. Include it only when you want a portable bundle.
if ($IncludeEngines) {
    $targets += @{ Path = Join-Path $root "engines"; Label = "engines (LibreOffice)" }
}

$existing = $targets | Where-Object { Test-Path $_.Path }
if (-not $existing) {
    Write-Host "[WARN] Nothing to back up - no client data folders found." -ForegroundColor Yellow
    exit 0
}

if (-not (Test-Path $Destination)) {
    New-Item -ItemType Directory -Force -Path $Destination | Out-Null
}

$zipPath = Join-Path $Destination "employee-client-data_$stamp.zip"

Write-Host "==> Backing up client data" -ForegroundColor Cyan
foreach ($t in $existing) {
    Write-Host "    + $($t.Label)" -ForegroundColor Gray
}

Compress-Archive -Path ($existing | ForEach-Object { $_.Path }) -DestinationPath $zipPath -CompressionLevel Optimal

$size = [math]::Round((Get-Item $zipPath).Length / 1MB, 2)
Write-Host "    [OK] $zipPath ($size MB)" -ForegroundColor Green

# Retention - keep newest $Keep, delete the rest
$old = Get-ChildItem $Destination -Filter "employee-client-data_*.zip" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -Skip $Keep
if ($old) {
    $old | Remove-Item -Force -Confirm:$false
    Write-Host "    [OK] Retention: removed $($old.Count) old backup(s), keeping newest $Keep" -ForegroundColor Green
}

Write-Host ""
Write-Host "Backup complete. To restore on another machine:" -ForegroundColor Cyan
Write-Host "  1. Clone the repo and run scripts\setup.ps1"
Write-Host "  2. Extract the zip into the repo root (restores memory\clients, .claude-mem, reference, deliverables)"
Write-Host "  3. Tell the employee: 'I have an ongoing client that I manually inserted' (resume-client)"
