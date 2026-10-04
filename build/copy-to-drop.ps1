<#
  Copies the packaged .tar.gz files to a per-version drop folder, e.g. D:\ConfigDrops\1.0.42\
  Usage: .\build\copy-to-drop.ps1 [-Version 1.0.42] [-SourceDir out] [-TargetDir D:\ConfigDrops]
#>
param(
    [string]$Version   = $(if ($env:BUILD_NUMBER) { $env:BUILD_NUMBER } else { '0.0.0-local' }),
    [string]$SourceDir = (Join-Path $PSScriptRoot '..\out'),
    [string]$TargetDir = 'D:\ConfigDrops'
)

$ErrorActionPreference = 'Stop'

$files = @(Get-ChildItem -Path $SourceDir -Filter "*-$Version.tar.gz" -File)
if ($files.Count -eq 0) { throw "No *-$Version.tar.gz files found in $SourceDir" }

$dest = Join-Path $TargetDir $Version
New-Item -ItemType Directory -Force -Path $dest | Out-Null

foreach ($file in $files) {
    Write-Host "Copying $($file.Name) -> $dest"
    Copy-Item -Path $file.FullName -Destination $dest -Force
}

Write-Host "Copied $($files.Count) files to $dest"
