<#
.SYNOPSIS
    Verifies that every identifier or path enclosed in backticks in INDICE.md exists physically in the repository.
.DESCRIPTION
    Usage: .\scripts\verify_index.ps1 [-IndexFile "INDICE.md"] [-RootPath "."]
    Exit code: 0 if no discrepancies, 1 if any token is missing.
#>
param(
    [string]$IndexFile = "INDICE.md",
    [string]$RootPath = "."
)

if (-not (Test-Path -LiteralPath $IndexFile)) {
    Write-Error "Index file not found: $IndexFile"
    exit 2
}

$excludeDirs = @(
    "node_modules", ".git", "dist", "build", "venv", ".venv", 
    "__pycache__", ".next", "coverage", "indices"
)
$indexName = Split-Path $IndexFile -Leaf

# 1. Extract unique tokens enclosed in backticks
$content = Get-Content -Raw -Path $IndexFile
$regex = '`([^`]+)`'
$tokenMatches = [regex]::Matches($content, $regex)
$tokens = $tokenMatches | ForEach-Object { $_.Groups[1].Value.Trim() } | Where-Object { $_ } | Select-Object -Unique | Sort-Object

$total = 0
$miss = 0

# 2. Collect codebase files ONCE outside the loop for high performance
$candidateFiles = Get-ChildItem -Path $RootPath -Recurse -File | Where-Object {
    $filePath = $_.FullName
    $fileName = $_.Name
    if ($fileName -eq $indexName -or $fileName -like "*.md") { return $false }
    foreach ($d in $excludeDirs) {
        if ($filePath -match "[\\/]$d[\\/]") { return $false }
    }
    return $true
}

# 3. Check each token
foreach ($tok in $tokens) {
    $total++

    # A. Physical path that exists (-LiteralPath supports brackets like app/[id]/)
    $candidatePath = Join-Path $RootPath $tok
    if (Test-Path -LiteralPath $candidatePath) {
        continue
    }

    # B. Directory path that does not exist
    if ($tok.EndsWith('/') -or $tok.EndsWith('\')) {
        Write-Host "MISSING path: $tok" -ForegroundColor Red
        $miss++
        continue
    }

    # C. Code symbol: search in candidate files
    $pattern = if ($tok -match '^[A-Za-z0-9_]+$') { "\b$tok\b" } else { [regex]::Escape($tok) }
    
    $found = $false
    foreach ($file in $candidateFiles) {
        if (Select-String -LiteralPath $file.FullName -Pattern $pattern -Quiet) {
            $found = $true
            break
        }
    }

    if (-not $found) {
        Write-Host "MISSING symbol: $tok" -ForegroundColor Red
        $miss++
    }
}

$color = if ($miss -eq 0) { "Green" } else { "Yellow" }
Write-Host "Verified: $total | Discrepancies: $miss" -ForegroundColor $color
if ($miss -gt 0) { exit 1 } else { exit 0 }
