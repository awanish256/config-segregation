<#
  Packages each config folder into its own versioned .tar.gz, e.g. out\INI-1.0.42.tar.gz
  Usage: .\build\package.ps1 [-Version 1.0.42] [-ConfigRoot config] [-OutDir out]
  In TeamCity the version defaults to the build number.
#>
param(
    [string]$Version    = $(if ($env:BUILD_NUMBER) { $env:BUILD_NUMBER } else { '0.0.0-local' }),
    [string]$ConfigRoot = (Join-Path $PSScriptRoot '..\config'),
    [string]$OutDir     = (Join-Path $PSScriptRoot '..\out'),
    [string[]]$Folders  = @('INI', 'XSL', 'XSD', 'PROPS')
)

$ErrorActionPreference = 'Stop'

$ConfigRoot = (Resolve-Path $ConfigRoot).Path
# Start clean so old versions never get uploaded or copied again
if (Test-Path $OutDir) { Remove-Item -Recurse -Force $OutDir }
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$OutDir = (Resolve-Path $OutDir).Path

foreach ($folder in $Folders) {
    $source = Join-Path $ConfigRoot $folder
    if (-not (Test-Path $source -PathType Container)) {
        throw "Config folder not found: $source"
    }

    $archive = Join-Path $OutDir "$folder-$Version.tar.gz"

    Write-Host "Packaging $folder -> $archive"
    # tar.exe ships with Windows 10 1803+ / Server 2019+
    & tar.exe -czf $archive -C $ConfigRoot $folder
    if ($LASTEXITCODE -ne 0) { throw "tar failed for $folder (exit $LASTEXITCODE)" }
}

Write-Host "Packaged $($Folders.Count) folders (version $Version) into $OutDir"
