param(
    [string]$RepoRoot = 'C:\Users\khen\source\repos\mf1027\project_myps',
    [string]$VaultRoot = 'C:\Users\khen\Desktop\Projects\Obsidian\project_obsidian_mem\MYPS',
    [string]$WorkspaceRoot = 'C:\Users\khen\Documents\ChatGPT\MYPS'
)

$ErrorActionPreference = 'Stop'
$today = (Get-Date).ToString('yyyy-MM-dd')

# Single-quoted here-strings/strings do NOT process backtick escape sequences, so building these
# once and interpolating the variable (never a literal backtick) into the double-quoted @"..."@
# blocks below avoids PowerShell collapsing `f/`t/etc. into form-feed/tab control characters.
# (Root cause of the 2026-08-21 corrupted-Markdown incident — see ADR-101/ADR-102.)
$bt = '`'
$fence = '```'

function Ensure-Dir([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path | Out-Null
    }
}

function Rel([string]$Path, [string]$Root) {
    return $Path.Replace($Root, '').TrimStart('\')
}

function Escape-Md([string]$Text) {
    if ($null -eq $Text) { return '' }
    return $Text.Replace('|', '\|').Replace("`r", '').Replace("`n", ' ')
}

function Domain-ForFile([string]$File, [string]$Class, [string]$Function) {
    $s = "$File $Class $Function"
    if ($s -match 'Revision') { return 'Formal Revision' }
    if ($s -match 'Programs|ProgramController|ProgramHelper') { return 'Program' }
    if ($s -match 'Projects|ProjectController|ProjectHelper|ProjectGroup') { return 'Project' }
    if ($s -match 'PCMA|Publish') { return 'PCMA / Publishing' }
    if ($s -match 'PIS') { return 'PIS Integration' }
    if ($s -match 'Lumpsum|Wallet') { return 'LS / Wallet' }
    if ($s -match 'Import') { return 'Import / Jobs' }
    if ($s -match 'Report|Crystal') { return 'Reporting' }
    if ($s -match 'Auth|UserManagement|Permission|Authorize') { return 'Security / Access' }
    if ($s -match 'GlobalSearch') { return 'Global Search' }
    if ($s -match 'FutureInfra') { return 'Future Infra' }
    if ($s -match 'CodeTable') { return 'Code Tables' }
    return 'Core / Shared'
}

$controllerRoot = Join-Path $RepoRoot 'WebAPI\Controllers'
$controllerFiles = Get-ChildItem -LiteralPath $controllerRoot -Recurse -Filter '*.cs' |
    Where-Object { $_.FullName -notmatch '\\bin\\|\\obj\\|\\FE\\' }

$actions = New-Object System.Collections.Generic.List[object]
foreach ($file in $controllerFiles) {
    $lines = Get-Content -LiteralPath $file.FullName
    $class = ''
    $controllerRoute = ''
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '\[Route\("([^"]+)"\)\]') { $controllerRoute = $Matches[1] }
        if ($lines[$i] -match 'class\s+(\w+)') { $class = $Matches[1] }
        if ($lines[$i] -match '\[(HttpGet|HttpPost|HttpPut|HttpDelete|HttpPatch)(?:\("([^"]*)"\))?\]') {
            $verb = $Matches[1].Replace('Http', '').ToUpperInvariant()
            $route = $Matches[2]
            $function = ''
            $params = ''
            $signatureLine = 0
            for ($j = $i + 1; $j -lt [Math]::Min($i + 10, $lines.Count); $j++) {
                if ($lines[$j] -match '\b(?:public\s+)?(?:async\s+)?(?:Task<[^>]+>|Task|IActionResult|ActionResult<[^>]+>|ActionResult|FileContentResult)\s+(\w+)\s*\((.*)') {
                    $function = $Matches[1]
                    $params = $Matches[2]
                    $signatureLine = $j + 1
                    break
                }
            }
            if ($function) {
                $domain = Domain-ForFile $file.FullName $class $function
                $actions.Add([pscustomobject]@{
                    Domain = $domain
                    File = Rel $file.FullName $RepoRoot
                    Class = $class
                    Function = $function
                    Line = $signatureLine
                    Route = ($(if ($controllerRoute) { "$controllerRoute/$route" } else { $route })).TrimEnd('/')
                    'HTTP Method' = $verb
                    'Read/Write' = $(if ($verb -eq 'GET') { 'Read' } else { 'Write/Command' })
                    'DTO/Input' = $params
                    Output = 'Controller response'
                    'EF Entity/DbSet' = ''
                    'SQL Object' = ''
                    'Tables Touched' = ''
                    'External System' = $(if ($domain -match 'PCMA') { 'PCMA' } elseif ($domain -match 'PIS') { 'PIS' } else { '' })
                    'Transaction Boundary' = ''
                    'Related Risk' = ''
                    'Related Test' = ''
                    'Evidence Status' = 'CODE-CONFIRMED'
                    'Last Verified' = $today
                    Notes = 'Public controller action extracted from source.'
                })
            }
        }
    }
}

$csFiles = Get-ChildItem -LiteralPath $RepoRoot -Recurse -Filter '*.cs' |
    Where-Object { $_.FullName -notmatch '\\FE\\|\\bin\\|\\obj\\|\\.git\\|\\documents\\|\\memory\\|\\e2e\\' }
$sqlCalls = New-Object System.Collections.Generic.List[object]
foreach ($file in $csFiles) {
    $lines = Get-Content -LiteralPath $file.FullName
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        $hit = $false
        $kind = ''
        if ($line -match 'FromSql(?:Raw|Interpolated)?') { $hit = $true; $kind = 'EF FromSql' }
        elseif ($line -match 'ExecuteSql(?:Raw|Interpolated)?') { $hit = $true; $kind = 'EF ExecuteSql' }
        elseif ($line -match 'Sql\.QueryAsync|Sql\.Execute|QueryAsync<|ExecuteAsync\(') { $hit = $true; $kind = 'Dapper/Sql helper' }
        elseif ($line -match 'EXEC\s+(?:dbo\.)?([A-Za-z][A-Za-z0-9_]+)') { $hit = $true; $kind = 'EXEC' }
        if ($hit) {
            $lo = [Math]::Max(0, $i - 1)
            $hi = [Math]::Min($lines.Count - 1, $i + 3)
            $window = ($lines[$lo..$hi] -join ' ')
            $objects = [regex]::Matches($window, '\b(?:dbo\.)?([pfv][A-Z][A-Za-z0-9_]+)\b') |
                ForEach-Object { $_.Groups[1].Value } |
                Where-Object { $_ -notin @('FileInfo','FileStream','FileNotFoundException','FileUpload','False','First','FirstOrDefault','FirstOrDefaultAsync','Find','Format','ForCorrectionRevision') } |
                Select-Object -Unique
            $objectText = ($objects -join ';')
            $domain = Domain-ForFile $file.FullName '' $objectText
            $sqlCalls.Add([pscustomobject]@{
                Domain = $domain
                File = Rel $file.FullName $RepoRoot
                Class = ''
                Function = ''
                Route = ''
                'HTTP Method' = ''
                'Read/Write' = $(if ($kind -match 'Execute|EXEC') { 'May write / command' } else { 'Read/query' })
                'DTO/Input' = ''
                Output = ''
                'EF Entity/DbSet' = ''
                'SQL Object' = $objectText
                'Tables Touched' = ''
                'External System' = ''
                'Transaction Boundary' = ''
                'Related Risk' = ''
                'Related Test' = ''
                'Evidence Status' = 'CODE-CONFIRMED'
                'Last Verified' = $today
                Notes = "$kind at $($file.Name):$($i + 1) - $($line.Trim())"
            })
        }
    }
}

$sqlObjectRows = $sqlCalls |
    Where-Object { $_.'SQL Object' } |
    ForEach-Object {
        foreach ($obj in ($_.'SQL Object' -split ';' | Where-Object { $_ })) {
            [pscustomobject]@{
                Object = $obj
                Kind = $(if ($obj -match '^p') { 'Stored procedure' } elseif ($obj -match '^v') { 'View' } elseif ($obj -match '^f') { 'Function/TVF' } else { 'SQL object' })
                Domain = $_.Domain
                Caller = $_.File
                Evidence = 'CODE-CONFIRMED; DB-OPEN'
                Notes = 'Referenced by backend code. DB metadata verification blocked by local sqlcmd encryption/client error during this run.'
            }
        }
    } |
    Group-Object Object |
    ForEach-Object {
        $first = $_.Group | Select-Object -First 1
        [pscustomobject]@{
            Object = $_.Name
            Kind = $first.Kind
            Domain = (($_.Group.Domain | Sort-Object -Unique) -join '; ')
            'Caller Count' = $_.Count
            'Example Caller' = $first.Caller
            Evidence = $first.Evidence
            Notes = $first.Notes
        }
    } |
    Sort-Object Kind, Object

$evidenceDir = Join-Path $VaultRoot '21 - Reference\Function SQL Evidence'
Ensure-Dir $evidenceDir
$actions | Export-Csv -LiteralPath (Join-Path $evidenceDir 'function-index.csv') -NoTypeInformation -Encoding UTF8
$sqlObjectRows | Export-Csv -LiteralPath (Join-Path $evidenceDir 'sql-object-index.csv') -NoTypeInformation -Encoding UTF8
$sqlCalls | Export-Csv -LiteralPath (Join-Path $evidenceDir 'code-to-sql-traceability.csv') -NoTypeInformation -Encoding UTF8

$functionGroups = $actions | Group-Object Domain | Sort-Object Name
$controllerGroups = $actions | Group-Object Class | Sort-Object Name
$sqlGroups = $sqlObjectRows | Group-Object Kind | Sort-Object Name

$functionTable = ($functionGroups | ForEach-Object {
    "| $(Escape-Md $_.Name) | $($_.Count) | $(Escape-Md (($_.Group | Select-Object -First 8 -ExpandProperty Class | Sort-Object -Unique) -join ', ')) |"
}) -join "`n"

$controllerTable = ($controllerGroups | ForEach-Object {
    $sample = ($_.Group | Select-Object -First 6 | ForEach-Object { "$($_.Function) [$($_.'HTTP Method')]" }) -join ', '
    "| $(Escape-Md $_.Name) | $($_.Count) | $(Escape-Md $sample) |"
}) -join "`n"

$sqlTable = ($sqlObjectRows | Select-Object -First 80 | ForEach-Object {
    "| $(Escape-Md $_.Object) | $(Escape-Md $_.Kind) | $(Escape-Md $_.Domain) | $($_.'Caller Count') | $(Escape-Md $_.Evidence) |"
}) -join "`n"

$traceTop = ($sqlObjectRows | Sort-Object 'Caller Count' -Descending | Select-Object -First 30 | ForEach-Object {
    "| $(Escape-Md $_.Object) | $(Escape-Md $_.Kind) | $($_.'Caller Count') | $(Escape-Md $_.'Example Caller') |"
}) -join "`n"

$functionIndex = @"
---
client: MYPS
type: reference
status: current
confidence: medium
source-authority: code-confirmed
last-verified: $today
related-tests: [MYPS.UnitTests, MYPS.DatabaseTests, MYPS.ApiIntegrationTests]
tags: [client/myps, backend, functions, codex, claude]
---

# Backend Function Index

This note is the backend function entry point for ChatGPT, Claude, and MYPS backend developers.

Use this before changing controller logic. It links public controller actions to the SQL and process maps instead of relying on memory or old plans.

## Safety Rules

- Do not run git commit, push, reset, checkout, or staging commands from this workflow.
- Do not connect to production databases or $($bt)myps_db$($bt) (any host).
- Use $($bt)myps_db_dev$($bt) on $($bt)192.168.50.200$($bt) only for approved read-only metadata checks (standing target as of 2026-08-25 -- see CODEX_SYNC_STARTUP.md's "DB safety rules"; myps_db_revision is retired).
- Do not scan or modify FE implementation files for this backend map.

## Current Extraction Result

- Public controller actions found: **$($actions.Count)**
- Real SQL-call lines found: **$($sqlCalls.Count)**
- Code-referenced SQL objects found: **$($sqlObjectRows.Count)**
- DB verification status: **OPEN** because local $($bt)sqlcmd$($bt) failed before query execution with an encryption/client error.

## Function Groups By Domain

| Domain | Action Count | Example Controllers |
|---|---:|---|
$functionTable

## Controller Action Groups

| Controller | Action Count | Sample Actions |
|---|---:|---|
$controllerTable

## How To Use This Note

1. Find the controller or domain here.
2. Open [[Code to SQL Traceability]] before changing implementation.
3. Check [[SQL Object Index]] if a stored procedure, view, or TVF is involved.
4. Check [[Backend Change Impact Map]] for risk, test, and workflow effects.
5. Check [[Risk Register]] before claiming a behavior is fixed.

## Evidence Files

- [[../21 - Reference/Function SQL Evidence/function-index.csv|function-index.csv]]
- [[../21 - Reference/Function SQL Evidence/code-to-sql-traceability.csv|code-to-sql-traceability.csv]]
- [[../21 - Reference/Function SQL Evidence/sql-object-index.csv|sql-object-index.csv]]

## Critical Domain Reminders

- $($bt)tProjectRevisions$($bt) is lifecycle/base Project revision data, not the Formal Revision approval transaction.
- Formal Revision current target is the normalized model unless fresh schema evidence proves otherwise.
- $($bt)RISK-082$($bt) remains open; do not document manual restriction separation as fixed.
- LS/wallet behavior remains pending where exact rules are not confirmed.
"@

$sqlIndex = @"
---
client: MYPS
type: reference
status: current
confidence: medium
source-authority: code-confirmed
last-verified: $today
tags: [client/myps, database, sql, functions, procedures, views]
---

# SQL Object Index

This note maps backend-referenced SQL objects for MYPS. It is a navigation surface, not the source of truth.

DB metadata verification should use $($bt)myps_db_dev$($bt) on $($bt)192.168.50.200$($bt) only (standing target as of 2026-08-25; myps_db_revision is retired) and must be read-only. During this run, $($bt)sqlcmd$($bt) could not connect because the local client failed at encryption negotiation before query execution, so objects below are **CODE-CONFIRMED; DB-OPEN** unless later verified.

## SQL Objects Referenced By Backend Code

| SQL Object | Kind | Domain | Caller Count | Evidence |
|---|---|---|---:|---|
$sqlTable

## Main SQL Families

- Program and Project effective-data functions: $($bt)fProgramDetails$($bt), $($bt)fProgramStages$($bt), $($bt)fProjectDetails$($bt), $($bt)fProjectComponentCost$($bt), $($bt)fProjectFundingProfile$($bt), $($bt)fProjectMajorWorkItem$($bt), $($bt)fProjectMajorWorkLocations$($bt).
- Formal Revision normalized functions: $($bt)fRevisionQueue$($bt), $($bt)fRevisionDetail$($bt), $($bt)fRevisionApprovalStatus$($bt), $($bt)fRevisionProjectDetails$($bt), $($bt)fRevisionComponentCost$($bt), $($bt)fRevisionComponentCostPerYear$($bt), $($bt)fRevisionFundingProfile$($bt), $($bt)fRevisionMajorWorkItem$($bt), $($bt)fRevisionMajorWorkLocations$($bt).
- Publishability and publication procedures: $($bt)pRecomputeProjectPublishable$($bt), $($bt)pAllowProjectPublishing$($bt), $($bt)pPublishProgram$($bt).
- Reporting/export procedures: $($bt)pGenerateAIP01$($bt), $($bt)pGenerateAIPComponents$($bt), $($bt)pGenerateRBP$($bt), $($bt)pGenerateRBPComponents$($bt), $($bt)pGenerateRDIP$($bt), $($bt)pExportRawProjects$($bt), $($bt)pExportRawProjectsMajorItems$($bt).
- Identifier/counter procedures: $($bt)pGenerateUID$($bt), $($bt)pGenerateThirdSegment$($bt), $($bt)pReserveProjectIdBlock$($bt).

## Verification Status Rules

- $($bt)DB-CONFIRMED$($bt): verified from $($bt)myps_db_dev$($bt) metadata.
- $($bt)CODE-CONFIRMED$($bt): referenced by current backend code.
- $($bt)SCRIPT-CONFIRMED$($bt): present only in SQL script evidence.
- $($bt)CONFLICT$($bt): code, DB, and/or docs disagree.
- $($bt)OPEN$($bt): not verified yet.

## Evidence Files

- [[../21 - Reference/Function SQL Evidence/sql-object-index.csv|sql-object-index.csv]]
- [[../21 - Reference/Function SQL Evidence/code-to-sql-traceability.csv|code-to-sql-traceability.csv]]
"@

$traceability = @"
---
client: MYPS
type: dependency-map
status: current
confidence: medium
source-authority: code-confirmed
last-verified: $today
tags: [client/myps, traceability, backend, sql, codex, claude]
---

# Code to SQL Traceability

This is the bridge from VS Code functions to SQL objects. Use it before editing controllers, helpers, EF models, stored procedures, views, or TVFs.

$($fence)mermaid
flowchart LR
    A[Controller Action] --> B[Helper / Service]
    B --> C[EF DbSet or Keyless Model]
    C --> D[SQL Object]
    D --> E[Tables / Views / TVFs]
    E --> F[Risk / Test / Workflow]
$fence

## Highest-Impact SQL Dependencies

| SQL Object | Kind | Caller Count | Example Caller |
|---|---|---:|---|
$traceTop

## Required Workflow For Assistants

1. Identify the public controller action from [[Function Index]].
2. Find SQL calls in $($bt)code-to-sql-traceability.csv$($bt).
3. Check whether each SQL object is $($bt)DB-CONFIRMED$($bt), $($bt)CODE-CONFIRMED$($bt), $($bt)SCRIPT-CONFIRMED$($bt), $($bt)CONFLICT$($bt), or $($bt)OPEN$($bt).
4. Check related workflow notes before changing behavior.
5. Add or update tests before claiming deployment readiness.

## Conflict Handling

Use this review card when code and SQL disagree:

$($fence)text
Conflict ID:
Topic:
Code evidence:
DB evidence:
Script/doc evidence:
Observed difference:
Likely current truth:
Reasoning:
Risk if wrong:
Recommended action:
Needs user confirmation:
$fence

## Evidence Files

- [[../21 - Reference/Function SQL Evidence/function-index.csv|function-index.csv]]
- [[../21 - Reference/Function SQL Evidence/sql-object-index.csv|sql-object-index.csv]]
- [[../21 - Reference/Function SQL Evidence/code-to-sql-traceability.csv|code-to-sql-traceability.csv]]
"@

$impact = @"
---
client: MYPS
type: change-impact-map
status: current
confidence: medium
source-authority: code-confirmed
last-verified: $today
related-risk: [RISK-082]
tags: [client/myps, change-impact, backend, sql, testing]
---

# Backend Change Impact Map

Use this note before changing backend functions or SQL objects. It is designed for ChatGPT, Claude, and backend developers working together.

$($fence)mermaid
mindmap
  root((Backend Change Impact))
    ProgramController
      Stage advancement
      Publish restriction
      pRecomputeProjectPublishable
      pAllowProjectPublishing
    ProjectController
      AddProject
      Project aggregate copy
      pRecomputeProgramCost
      fProjectDetails family
    RevisionController
      RequestRevision
      RevisionRequests
      UpdateRevisionStatus
      ResubmitRevision
      fRevision function family
      tRevisionApprovals
    PCMAController
      pPublishProgram
      PCMA boundary
      Review saved on hold
    ReportingController
      AIP/RBP/RDIP generation procedures
      Export procedures
    Importing
      Hangfire jobs
      Project ID block allocation
      pReserveProjectIdBlock
    Security
      AuthController
      UserManagementController
      AuthorizeSessionAttribute
    Tests
      Unit tests
      Database tests
      API integration tests
$fence

## Change Rules

- If a controller action changes, update [[Function Index]] and [[Code to SQL Traceability]].
- If a SQL object changes, update [[SQL Object Index]] and add/adjust database tests.
- If Revision changes, verify normalized $($bt)RevisionDetailFK$($bt) / $($bt)tRevisionApprovals$($bt) behavior and never reintroduce flat $($bt)RegionStatus$($bt) / $($bt)COStatus$($bt) as current truth.
- If publishability changes, keep $($bt)RISK-082$($bt) open unless Phase 2 schema work explicitly resolves manual restriction separation.
- If Program stage logic changes, update Program/Project lifecycle workflow and test stage advancement.
- If documents or PCMA publishing change, update Revision and PCMA readiness tests.

## Fast Impact Questions

- Which public endpoint calls this function?
- Which EF model or DbSet materializes the result?
- Which SQL object or table shape can break runtime materialization?
- Is the operation read-only, state-changing, or external-system-calling?
- What rollback or retry behavior must be preserved?
- Which risk or deployment gate is affected?
"@

Set-Content -LiteralPath (Join-Path $VaultRoot '03 - Backend\Function Index.md') -Value $functionIndex -Encoding UTF8
Set-Content -LiteralPath (Join-Path $VaultRoot '04 - Database\SQL Object Index.md') -Value $sqlIndex -Encoding UTF8
Set-Content -LiteralPath (Join-Path $VaultRoot '05 - SQL Dependency Maps\Code to SQL Traceability.md') -Value $traceability -Encoding UTF8
Set-Content -LiteralPath (Join-Path $VaultRoot '15 - Change Management\Backend Change Impact Map.md') -Value $impact -Encoding UTF8

$backendMindmapPath = Join-Path $VaultRoot '01 - Application Architecture\MYPS Backend Mindmap.md'
$dbMindmapPath = Join-Path $VaultRoot '01 - Application Architecture\MYPS Database Mindmap.md'
$backend = Get-Content -LiteralPath $backendMindmapPath -Raw
if ($backend -notmatch 'Function / SQL Traceability') {
    $backend = $backend -replace '    Data Access\r?\n', "    Function / SQL Traceability`r`n      [[Function Index]]`r`n      [[Code to SQL Traceability]]`r`n      [[Backend Change Impact Map]]`r`n    Data Access`r`n"
}
Set-Content -LiteralPath $backendMindmapPath -Value $backend -Encoding UTF8

$db = Get-Content -LiteralPath $dbMindmapPath -Raw
if ($db -notmatch 'SQL Object Index') {
    $db = $db -replace '    Read Models\r?\n', "    SQL Object Index`r`n      [[SQL Object Index]]`r`n      [[Code to SQL Traceability]]`r`n    Read Models`r`n"
}
Set-Content -LiteralPath $dbMindmapPath -Value $db -Encoding UTF8

$startupPath = Join-Path $VaultRoot '00 - START HERE.md'
$startup = Get-Content -LiteralPath $startupPath -Raw
if ($startup -notmatch 'Function / SQL Entry Points') {
    $startup += @"

## Function / SQL Entry Points

- [[03 - Backend/Function Index|Backend Function Index]]
- [[04 - Database/SQL Object Index|SQL Object Index]]
- [[05 - SQL Dependency Maps/Code to SQL Traceability|Code to SQL Traceability]]
- [[15 - Change Management/Backend Change Impact Map|Backend Change Impact Map]]

Use these before asking ChatGPT or Claude to change backend code or SQL behavior.
"@
}
Set-Content -LiteralPath $startupPath -Value $startup -Encoding UTF8

$controlPath = Join-Path $WorkspaceRoot 'memory\clients\myps\myps-system\deliverables\documents\obsidian-mindmap-migration-control-2026-08-21.md'
$control = Get-Content -LiteralPath $controlPath -Raw
if ($control -notmatch 'VS Code \+ SQL Function Migration Addendum') {
    $control += @"

## VS Code + SQL Function Migration Addendum - $today

Status: Implemented with code-confirmed extraction and DB verification open.

Generated / updated:

- $($bt)MYPS/03 - Backend/Function Index.md$($bt)
- $($bt)MYPS/04 - Database/SQL Object Index.md$($bt)
- $($bt)MYPS/05 - SQL Dependency Maps/Code to SQL Traceability.md$($bt)
- $($bt)MYPS/15 - Change Management/Backend Change Impact Map.md$($bt)
- $($bt)MYPS/21 - Reference/Function SQL Evidence/function-index.csv$($bt)
- $($bt)MYPS/21 - Reference/Function SQL Evidence/sql-object-index.csv$($bt)
- $($bt)MYPS/21 - Reference/Function SQL Evidence/code-to-sql-traceability.csv$($bt)

Extraction result:

- Public controller actions: $($actions.Count)
- Real SQL-call lines: $($sqlCalls.Count)
- Code-referenced SQL objects: $($sqlObjectRows.Count)

DB verification note:

- $($bt)myps_db_dev$($bt) metadata query was attempted with read-only $($bt)sqlcmd$($bt).
- Connection failed before query execution because the local SQL client reported an encryption/client negotiation error.
- Therefore SQL object rows are $($bt)CODE-CONFIRMED; DB-OPEN$($bt) until a working read-only metadata connection is available.

Safety:

- No backend source files edited.
- No frontend files edited.
- No database statements executed successfully.
- No git commands executed by this generator.
"@
}
Set-Content -LiteralPath $controlPath -Value $control -Encoding UTF8

"Generated Obsidian function/SQL migration artifacts."
"Actions=$($actions.Count)"
"SqlCallLines=$($sqlCalls.Count)"
"SqlObjects=$($sqlObjectRows.Count)"
