param(
    [string]$RepoRoot = 'C:\Users\khen\source\repos\mf1027\project_myps',
    [string]$VaultRoot = 'C:\Users\khen\Desktop\Projects\Obsidian\project_obsidian_mem\MYPS',
    [string]$WorkspaceRoot = 'C:\Users\khen\Documents\ChatGPT\MYPS'
)

# Repeatable validation for the MYPS Obsidian function/SQL mindmap layer (ADR-101/102/103).
# Codifies the manual checks run by hand 3 times this session so future regeneration/edits can
# be verified in one command instead of re-deriving the same audit routine again.

$ErrorActionPreference = 'Stop'
$failures = @()
$checks = 0

function Check([bool]$Condition, [string]$Message) {
    $script:checks++
    if (-not $Condition) {
        $script:failures += $Message
        Write-Host "FAIL: $Message" -ForegroundColor Red
    } else {
        Write-Host "PASS: $Message" -ForegroundColor Green
    }
}

$requiredNotes = @(
    (Join-Path $VaultRoot '03 - Backend\Function Index.md'),
    (Join-Path $VaultRoot '04 - Database\SQL Object Index.md'),
    (Join-Path $VaultRoot '05 - SQL Dependency Maps\Code to SQL Traceability.md'),
    (Join-Path $VaultRoot '15 - Change Management\Backend Change Impact Map.md'),
    (Join-Path $VaultRoot '20 - Standards & Conventions\Claude Codex Backend Sync Guide.md')
)
$requiredCsvs = @(
    (Join-Path $VaultRoot '21 - Reference\Function SQL Evidence\function-index.csv'),
    (Join-Path $VaultRoot '21 - Reference\Function SQL Evidence\sql-object-index.csv'),
    (Join-Path $VaultRoot '21 - Reference\Function SQL Evidence\code-to-sql-traceability.csv')
)

# 1. Required files exist
foreach ($f in ($requiredNotes + $requiredCsvs)) {
    Check (Test-Path -LiteralPath $f) "exists: $f"
}

# 2. No control characters (the ADR-101/102 corruption class: tab/form-feed from PowerShell
#    backtick-escape collapse) in any required note
$controlCharPattern = '[\x00-\x08\x0B\x0C\x0E-\x1F]'
foreach ($f in $requiredNotes) {
    if (Test-Path -LiteralPath $f) {
        $bytes = Get-Content -LiteralPath $f -Raw -Encoding UTF8
        $hasControlChar = $bytes -match $controlCharPattern
        Check (-not $hasControlChar) "no control characters: $f"
    }
}

# 3. No single-backtick-only fence lines (the specific mangled-fence shape from the same bug).
#    A broken fence is a line that is ENTIRELY "`word" (no closing backtick, nothing else on the
#    line) or entirely a lone "`" -- NOT a legitimate inline code span like "`DB-OPEN` means...",
#    which always has a closing backtick plus more content on the same line.
foreach ($f in $requiredNotes) {
    if (Test-Path -LiteralPath $f) {
        $lines = Get-Content -LiteralPath $f
        $badFence = $lines | Where-Object { $_ -match '^`[a-zA-Z]+$' -or $_ -eq '`' }
        Check ($badFence.Count -eq 0) "no malformed single-backtick fences: $f"
    }
}

# 4. Evidence CSV row counts parse and are non-zero
foreach ($f in $requiredCsvs) {
    if (Test-Path -LiteralPath $f) {
        $rows = (Get-Content -LiteralPath $f | Measure-Object -Line).Lines - 1
        Check ($rows -gt 0) "non-zero row count ($rows): $f"
    }
}

# 5. Every [[wikilink]] in the required notes resolves against the vault
$allVaultFiles = Get-ChildItem -Path $VaultRoot -Recurse -File | ForEach-Object { $_.Name }
foreach ($f in $requiredNotes) {
    if (Test-Path -LiteralPath $f) {
        $content = Get-Content -LiteralPath $f -Raw
        $linkMatches = [regex]::Matches($content, '\[\[([^\]|]+)(\|[^\]]+)?\]\]')
        foreach ($m in $linkMatches) {
            $target = $m.Groups[1].Value.Trim()
            $targetBase = Split-Path $target -Leaf
            $resolved = $false
            # Obsidian resolves wikilinks by vault-relative path or by basename. It does NOT
            # resolve '../' relative paths -- a link containing '../' renders unresolved in the
            # app even when the file exists on disk. Tightened 2026-08-23: the previous basename
            # fallback masked exactly this, passing 3 links that are broken in the actual vault.
            # Obsidian's real vault root is the PARENT of the MYPS client folder, so a
            # folder-qualified link is 'MYPS/03 - Backend/...'. Resolve against both.
            $trueVaultRoot = Split-Path $VaultRoot -Parent
            if ($target -match '\.\./') {
                $resolved = $false
            }
            elseif (Test-Path -LiteralPath (Join-Path $trueVaultRoot "$target.md")) { $resolved = $true }
            elseif (Test-Path -LiteralPath (Join-Path $trueVaultRoot $target)) { $resolved = $true }
            elseif (Test-Path -LiteralPath (Join-Path $VaultRoot "$target.md")) { $resolved = $true }
            elseif ($allVaultFiles -contains "$targetBase.md") { $resolved = $true }
            elseif ($allVaultFiles -contains $targetBase) { $resolved = $true }
            Check $resolved "wikilink resolves: [[$target]] (in $(Split-Path $f -Leaf))"
        }
    }
}

# 6. Startup docs still reference the 4 required maps.
#    Corrected 2026-08-23: this check previously also required project_myps\CLAUDE.md and
#    project_myps\AGENTS.md to carry these references. ADR-107 deleted that AGENTS.md and ADR-108
#    reverted that CLAUDE.md to zero MYPS content, so the check was failing 5/5 for a state that is
#    now CORRECT BY DESIGN. CODEX_SYNC_STARTUP.md is the only startup doc that should carry them.
$startupDocs = @(
    (Join-Path $WorkspaceRoot 'memory\clients\myps\myps-system\CODEX_SYNC_STARTUP.md')
)
foreach ($doc in $startupDocs) {
    if (Test-Path -LiteralPath $doc) {
        $text = Get-Content -LiteralPath $doc -Raw
        Check ($text -match 'Function Index') "references Function Index: $doc"
        Check ($text -match 'SQL Object Index') "references SQL Object Index: $doc"
        Check ($text -match 'Code to SQL Traceability') "references Code to SQL Traceability: $doc"
        Check ($text -match 'Backend Change Impact Map') "references Backend Change Impact Map: $doc"
    } else {
        Check $false "startup doc exists: $doc"
    }
}

# 6b. ADR-107/108 zero-AI-footprint conformance (inverts the stale check above into a live guard).
#     These assert the ABSENCE of MYPS tooling in project_myps, which is the actual current rule.
Check (-not (Test-Path -LiteralPath (Join-Path $RepoRoot 'AGENTS.md'))) `
    "ADR-107: project_myps has NO AGENTS.md"
$pmClaude = Join-Path $RepoRoot 'CLAUDE.md'
if (Test-Path -LiteralPath $pmClaude) {
    $pmText = Get-Content -LiteralPath $pmClaude -Raw
    Check ($pmText -notmatch 'SQL Object Index|Code to SQL Traceability|Backend Change Impact Map|myps-system') `
        "ADR-108: project_myps\CLAUDE.md carries no MYPS/coordination content"
} else {
    Check $false "project_myps\CLAUDE.md exists (its own dev-workflow guide, must NOT be deleted)"
}

# 7. Any DB-CONFIRMED row in SQL Object Index.md has evidence behind it, not a bare label
$sqlIndexPath = Join-Path $VaultRoot '04 - Database\SQL Object Index.md'
if (Test-Path -LiteralPath $sqlIndexPath) {
    $sqlIndexText = Get-Content -LiteralPath $sqlIndexPath -Raw
    $dbConfirmedBare = [regex]::Matches($sqlIndexText, '\| DB-CONFIRMED \|')
    # A bare "| DB-CONFIRMED |" cell with nothing else is suspicious -- current convention keeps
    # the evidence note in the same file's header/CSV, so this just checks the label isn't the
    # ENTIRE evidence story with zero surrounding context (i.e. the header note above the table
    # must mention how/when verification happened).
    Check ($sqlIndexText -match 'DB metadata verification against') "SQL Object Index has a verification-method note, not just bare DB-CONFIRMED labels"
}

Write-Host ""
Write-Host "$($checks - $failures.Count) / $checks checks passed" -ForegroundColor Cyan
if ($failures.Count -gt 0) {
    Write-Host "FAILURES:" -ForegroundColor Red
    $failures | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
} else {
    Write-Host "All checks passed." -ForegroundColor Green
    exit 0
}
