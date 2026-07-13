# Installs the agent factory into a target project's .claude/ directory.
# Usage:  .\install.ps1 -Target "C:\path\to\your\project"
# Safe to re-run for updates: never overwrites an existing config.md.

param(
    [Parameter(Mandatory = $true)][string]$Target
)

$ErrorActionPreference = "Stop"
$src = $PSScriptRoot

if (-not (Test-Path (Join-Path $Target ".git"))) {
    Write-Warning "$Target does not look like a git repo (.git not found). Continuing anyway."
}

$map = @(
    @{ From = "agents";          To = ".claude\agents" },
    @{ From = "commands";        To = ".claude\commands" },
    @{ From = "factory";         To = ".claude\factory" },
    @{ From = "factory\scripts"; To = ".claude\factory\scripts" }
)

foreach ($m in $map) {
    $dest = Join-Path $Target $m.To
    New-Item -ItemType Directory -Force -Path $dest | Out-Null
    Get-ChildItem (Join-Path $src $m.From) -File | ForEach-Object {
        $destFile = Join-Path $dest $_.Name
        Copy-Item $_.FullName $destFile -Force
        Write-Host "  installed $($m.To)\$($_.Name)"
    }
}

# Version marker — read by /factory-init sync mode ("installed vs synced").
Copy-Item (Join-Path $src "VERSION") (Join-Path $Target ".claude\factory\VERSION") -Force
Write-Host "  installed .claude\factory\VERSION"

# Skills are directories (skills/<name>/SKILL.md + any references)
Get-ChildItem (Join-Path $src "skills") -Directory | ForEach-Object {
    $dest = Join-Path $Target ".claude\skills\$($_.Name)"
    New-Item -ItemType Directory -Force -Path $dest | Out-Null
    Copy-Item (Join-Path $_.FullName "*") $dest -Recurse -Force
    Write-Host "  installed .claude\skills\$($_.Name)\"
}

# Never clobber a project's live config; the template is what ships.
$config = Join-Path $Target ".claude\factory\config.md"
if (Test-Path $config) {
    Write-Host "  kept existing config.md (template updated alongside it)"
}

Write-Host ""
Write-Host "Done. Next steps in the target project:"
Write-Host "  1. RELOAD the Claude Code session (agents register at session start)."
Write-Host "  2. Run /factory-init to generate/validate .claude/factory/config.md."
Write-Host "  3. Run /feature <your first request>."
