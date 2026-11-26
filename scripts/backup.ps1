# Verified backup wrapper for Windows. Retention runs only after manifest/hash verification.
param(
    [string]$Destination = "$env:USERPROFILE\Documents\EmployeeBackups",
    [int]$Keep = 10,
    [switch]$IncludeEngines
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$argsList = @((Join-Path $PSScriptRoot 'backup.py'), '--root', $root, '--destination', $Destination, '--keep', "$Keep")
if ($IncludeEngines) { $argsList += '--include-engines' }
python @argsList
if ($LASTEXITCODE -ne 0) { throw 'Verified backup failed; existing backups were preserved.' }
