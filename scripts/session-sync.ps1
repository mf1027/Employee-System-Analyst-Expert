<#
.SYNOPSIS
    SessionStart hook payload for MYPS: emits the canonical-memory sync check as
    hookSpecificOutput.additionalContext, for both Claude Code and Codex CLI (ADR-112/113).

.DESCRIPTION
    Read-only, always. Never connects to any database, never writes any file. Wraps the same
    facts codex-sync-startup.ps1 prints for a human, but as compact plain text meant to be
    injected directly into a fresh session's context -- so a session starts already knowing
    the current git state, the latest ADR/RISK, and whether memory/memory.md has gone stale,
    instead of that being something the agent has to remember to go check.

    This helper is a read-only summary only. Claude project lifecycle hooks and Codex project-hook
    support are separate runtime capabilities and must be verified independently; do not infer
    synchronization from this script's output.

    Emits ONE line of JSON on stdout, matching the hook wire protocol both tools share.
    Never throws -- any internal failure degrades to a short "sync check failed" note rather
    than blocking session start.

.PARAMETER ProjectMypsPath
    Path to the project_myps application repo.

.PARAMETER MypsWorkspacePath
    Path to this documentation/memory workspace.

.PARAMETER VaultPath
    Path to the Obsidian vault.
#>

param(
    [string]$ProjectMypsPath = $env:MYPS_PROJECT_PATH,
    [string]$MypsWorkspacePath = $env:MYPS_WORKSPACE_PATH,
    [string]$VaultPath = $env:MYPS_VAULT_ROOT,
    [string]$PythonExe = $env:MYPS_PYTHON_EXE
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path $PSScriptRoot -Parent
if ([string]::IsNullOrWhiteSpace($MypsWorkspacePath)) { $MypsWorkspacePath = $repoRoot }
if ([string]::IsNullOrWhiteSpace($VaultPath)) {
    $VaultPath = Join-Path (Split-Path $repoRoot -Parent) "Obsidian\MYPS_Obsidian_Vault"
}
if ([string]::IsNullOrWhiteSpace($PythonExe)) { $PythonExe = "python" }

# This helper is intentionally not a hook registration file. The Employee repository owns its
# Claude project hooks; Codex project-hook support is build-dependent. A session rooted in an
# unrelated project must get zero MYPS noise, and explicit runtime-sync commands are required when
# the active Codex build does not expose project hooks.
#
# Confirmed field name (2026-08-23): both tools' SessionStart stdin carries the session's
# working directory as `cwd` -- verified by reading context-mode's own installed Codex
# adapter (hooks/session-helpers.mjs:getInputProjectDir), which is explicitly documented as
# sharing Claude Code's wire protocol.
function Test-InMypsScope([string]$cwd) {
    if ([string]::IsNullOrWhiteSpace($cwd)) { return $false }
    try {
        $full = [System.IO.Path]::GetFullPath($cwd)
        $roots = @($ProjectMypsPath, $MypsWorkspacePath) | ForEach-Object { [System.IO.Path]::GetFullPath($_) }
        foreach ($r in $roots) {
            if ($full -eq $r -or $full.StartsWith($r + [System.IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
                return $true
            }
        }
    } catch { return $false }
    return $false
}

$stdinCwd = $null
try {
    if ([Console]::IsInputRedirected) {
        $raw = [Console]::In.ReadToEnd()
        if ($raw) {
            $parsed = $raw | ConvertFrom-Json -ErrorAction SilentlyContinue
            if ($parsed -and $parsed.cwd) { $stdinCwd = [string]$parsed.cwd }
        }
    }
} catch { $stdinCwd = $null }

if (-not (Test-InMypsScope $stdinCwd)) {
    # Out of scope -- stay silent. Empty additionalContext, not an error.
    Write-Output '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":""}}'
    return
}

function Get-SyncText {
    $myps = Join-Path $MypsWorkspacePath "memory\clients\myps\myps-system"
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("MYPS session sync (auto, read-only, ADR-113):")

    # 1. project_myps git state -- the check that matters most; uncommitted work has been
    #    found here before assuming a clean slate (2026-08-13, per codex-sync-startup.ps1).
    if (Test-Path $ProjectMypsPath) {
        Push-Location $ProjectMypsPath
        try {
            $branch = (git branch --show-current 2>$null)
            $dirty = (git status --short 2>$null)
            if ($dirty) {
                $n = ($dirty -split "`n" | Where-Object { $_ }).Count
                $lines.Add("- project_myps [$branch]: DIRTY -- $n uncommitted file(s). ADR-107/108's zero-footprint bar expects 0 unless the operator is mid-edit; diff before assuming a clean slate.")
            } else {
                $lines.Add("- project_myps [$branch]: clean (0 uncommitted).")
            }
        } finally { Pop-Location }
    } else {
        $lines.Add("- project_myps: NOT FOUND at $ProjectMypsPath.")
    }

    # 2. This workspace's own git state (memory/clients/ local repo, ADR-111).
    if (Test-Path (Join-Path $MypsWorkspacePath "memory\clients\.git")) {
        Push-Location (Join-Path $MypsWorkspacePath "memory\clients")
        try {
            $n = (git status --short 2>$null | Where-Object { $_ }).Count
            $lines.Add("- memory/clients/ (local-only history): $n uncommitted change(s).")
        } finally { Pop-Location }
    }

    # 3. Vault git state.
    if (Test-Path (Join-Path $VaultPath ".git")) {
        Push-Location $VaultPath
        try {
            $n = (git status --short 2>$null | Where-Object { $_ }).Count
            $head = (git log -1 --format=%h 2>$null)
            $lines.Add("- Obsidian vault [$head]: $n uncommitted change(s).")
        } finally { Pop-Location }
    }

    # 4. Vault node coverage (ADR-117) -- closes the one specific staleness class check #3
    #    (git status/HEAD-hash only) structurally cannot see: a clean, fully-committed vault repo
    #    whose generated ADR/RISK index CONTENT is stale. Found 2026-08-25 -- the vault's own
    #    index files were 5 ADRs / 2 RISKs behind despite 0 uncommitted changes in that repo.
    #    Read-only against canonical, never mutates anything. See RISK-095 for the other sync-
    #    mechanism gaps this does NOT close (by design -- no new lock/watcher infrastructure).
    $verifyScript = Join-Path $MypsWorkspacePath "tools\verify-vault-memory-nodes.py"
    if ((Test-Path $verifyScript) -and (Test-Path $PythonExe)) {
        try {
            $env:PYTHONIOENCODING = "utf-8"
            $null = & $PythonExe $verifyScript 2>$null
            if ($LASTEXITCODE -eq 0) {
                $lines.Add("- Vault node coverage: OK.")
            } else {
                $lines.Add("- WARNING: vault node coverage check FAILED (exit $LASTEXITCODE) -- run tools/verify-vault-memory-nodes.py for detail.")
            }
        } catch {
            $lines.Add("- Vault node coverage check did not run (non-fatal): $($_.Exception.Message)")
        }
    }

    # 5. Latest ADR / RISK.
    $decisionsFile = Join-Path $myps "decisions.md"
    $risksFile = Join-Path $myps "risks.md"
    $latestAdrNum = 0
    if (Test-Path $decisionsFile) {
        $m = Select-String -Path $decisionsFile -Pattern '^## (ADR-\d+)' | Select-Object -First 1
        if ($m) {
            $lines.Add("- Latest ADR: $($m.Matches[0].Groups[1].Value) -- $($m.Line.Substring(0, [Math]::Min($m.Line.Length, 140)))")
            $latestAdrNum = [int]($m.Matches[0].Groups[1].Value -replace 'ADR-', '')
        }
    }
    if (Test-Path $risksFile) {
        $m = Select-String -Path $risksFile -Pattern '^## (RISK-\d+)' | Select-Object -First 1
        if ($m) {
            $lines.Add("- Latest RISK: $($m.Matches[0].Groups[1].Value) -- $($m.Line.Substring(0, [Math]::Min($m.Line.Length, 140)))")
        }
    }

    # 6. memory/memory.md staleness check -- closes ADR-111's Gap 5. It was found 17 ADRs
    #    stale before anything checked; this makes that check automatic instead of incidental.
    $memoryMd = Join-Path $MypsWorkspacePath "memory\memory.md"
    if ((Test-Path $memoryMd) -and $latestAdrNum -gt 0) {
        $text = Get-Content $memoryMd -Raw
        $mentioned = [regex]::Matches($text, 'ADR-(\d+)') | ForEach-Object { [int]$_.Groups[1].Value }
        $maxMentioned = if ($mentioned) { ($mentioned | Measure-Object -Maximum).Maximum } else { 0 }
        $gap = $latestAdrNum - $maxMentioned
        if ($gap -gt 3) {
            $lines.Add("- WARNING: memory/memory.md's newest ADR reference is ADR-$maxMentioned, canonical is ADR-$latestAdrNum ($gap behind). It may be stale -- verify before trusting its Working Memory section.")
        } else {
            $lines.Add("- memory/memory.md: currency check OK (within $gap ADRs of canonical).")
        }
    }

    # 7. Static DB safety reminder -- always present, never conditional.
    $lines.Add("- DB SAFETY (revised 2026-08-25): myps_db_dev on 192.168.50.200 via appsettings.Development.json's MYPSDb connection string is now the standing approved target -- myps_db_revision is retired. Never myps_db (any host). The sa/<redacted> credential remains a tracked, OPEN exposure (RISK-090/091) -- accepted as a known condition of this target, not resolved. No DB mutation without explicit per-task operator override.")
    $lines.Add("- Read the MYPS Obsidian Claude + Codex Real-Time Sync Protocol and Agent Tooling Mindmap before starting relevant backend/database or runtime work. This sync check is a summary, not a substitute.")

    return ($lines -join "`n")
}

$context = try { Get-SyncText } catch { "MYPS session sync failed to run (non-fatal): $($_.Exception.Message)" }

$payload = @{
    hookSpecificOutput = @{
        hookEventName    = "SessionStart"
        additionalContext = $context
    }
} | ConvertTo-Json -Compress -Depth 5

Write-Output $payload
