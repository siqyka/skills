<#
.SYNOPSIS
  Install every skill in this repo into a tool's skill root.

.EXAMPLE
  .\install.ps1                      # copy into %USERPROFILE%\.agents\skills
  .\install.ps1 -Link                # symlink instead (repo stays the single source)
  .\install.ps1 -Target "$HOME\.claude\skills"
  .\install.ps1 -DryRun
  .\install.ps1 -Force

.NOTES
  Discovery rule: a skill is any directory skills\<category>\<name>\ that
  contains SKILL.md. Nested SKILL.md files are ignored on purpose — tools
  only scan one level deep. Symlinks may need Developer Mode or an elevated
  shell; -Link falls back to a copy if the link cannot be created.
#>
param(
  [string]$Target = (Join-Path $env:USERPROFILE '.agents\skills'),
  [switch]$Link,
  [switch]$Force,
  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$skillsRoot = Join-Path $repoRoot 'skills'

if (-not (Test-Path $skillsRoot)) { throw "skills/ directory not found under $repoRoot" }
if (-not (Test-Path $Target)) { New-Item -ItemType Directory -Path $Target | Out-Null }

$installed = 0
$skipped = 0

Get-ChildItem -Path $skillsRoot -Directory | ForEach-Object {
  $categoryDir = $_
  Get-ChildItem -Path $categoryDir.FullName -Directory | ForEach-Object {
    $skillDir = $_
    $skillMd = Join-Path $skillDir.FullName 'SKILL.md'
    if (-not (Test-Path $skillMd)) { return }

    $name = $skillDir.Name
    $dest = Join-Path $Target $name

    if ((Test-Path $dest) -or (Test-Path -LiteralPath $dest)) {
      if (-not $Force) {
        Write-Host "skip   $name (already exists; use -Force to replace)"
        $script:skipped++
        return
      }
      Write-Host "remove $dest"
      if (-not $DryRun) { Remove-Item -Recurse -Force -LiteralPath $dest }
    }

    if ($Link) {
      Write-Host "link   $name -> $($skillDir.FullName)"
      if (-not $DryRun) {
        try {
          New-Item -ItemType SymbolicLink -Path $dest -Target $skillDir.FullName | Out-Null
        } catch {
          Write-Host "link failed ($($_.Exception.Message)); copying instead"
          Copy-Item -Recurse -Force -Path $skillDir.FullName -Destination $dest
        }
      }
    } else {
      Write-Host "copy   $name -> $dest"
      if (-not $DryRun) { Copy-Item -Recurse -Force -Path $skillDir.FullName -Destination $dest }
    }
    $script:installed++
  }
}

if ($DryRun) {
  Write-Host "dry run: would install $installed, skip $skipped into $Target"
  return
}

Write-Host ''
Get-ChildItem -Path $Target -Directory | ForEach-Object {
  $md = Join-Path $_.FullName 'SKILL.md'
  if (Test-Path $md) { Write-Host "ok     $md" }
}
Write-Host "installed $installed, skipped $skipped into $Target"
