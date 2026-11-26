# Run Python with this repository's isolated dependency environment.
$root = Split-Path -Parent $PSScriptRoot
$python = Join-Path $root '.venv\Scripts\python.exe'
if (-not (Test-Path $python)) { throw 'Project .venv is missing. Run scripts\setup.ps1 first.' }
& $python @args
exit $LASTEXITCODE
