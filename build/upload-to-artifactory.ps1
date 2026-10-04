<#
  Uploads out\<FOLDER>-<VERSION>.tar.gz to a JFrog Artifactory generic repo as
    <Repo>/<FOLDER>/<VERSION>/<FOLDER>-<VERSION>.tar.gz

  Usage:
    $env:ARTIFACTORY_URL   = 'https://<your-server>.jfrog.io/artifactory'
    $env:ARTIFACTORY_TOKEN = '<access token>'
    .\build\upload-to-artifactory.ps1 -Version 1.0.42
#>
param(
    [string]$Version        = $(if ($env:BUILD_NUMBER) { $env:BUILD_NUMBER } else { '0.0.0-local' }),
    [string]$ArtifactoryUrl = $env:ARTIFACTORY_URL,
    [string]$Repo           = $(if ($env:ARTIFACTORY_REPO) { $env:ARTIFACTORY_REPO } else { 'config-generic-local' }),
    [string]$Token          = $env:ARTIFACTORY_TOKEN,
    [string]$SourceDir      = (Join-Path $PSScriptRoot '..\out'),
    [string[]]$Folders      = @('INI', 'XSL', 'XSD', 'PROPS')
)

$ErrorActionPreference = 'Stop'

if (-not $ArtifactoryUrl) { throw 'Set ARTIFACTORY_URL, e.g. https://<your-server>.jfrog.io/artifactory' }
if (-not $Token)          { throw 'Set ARTIFACTORY_TOKEN to an Artifactory access token' }

# Windows PowerShell 5.1 defaults to old TLS versions that JFrog Cloud rejects
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$base = $ArtifactoryUrl.TrimEnd('/')

foreach ($folder in $Folders) {
    $name = "$folder-$Version.tar.gz"
    $file = Join-Path $SourceDir $name
    if (-not (Test-Path $file -PathType Leaf)) { throw "Package not found: $file (run package.ps1 first)" }

    $sha256 = (Get-FileHash -Path $file -Algorithm SHA256).Hash.ToLower()
    $sha1   = (Get-FileHash -Path $file -Algorithm SHA1).Hash.ToLower()
    $target = "$base/$Repo/$folder/$Version/$name"

    Write-Host "Uploading $name -> $target"
    $headers = @{
        'Authorization'     = "Bearer $Token"
        'X-Checksum-Sha256' = $sha256
        'X-Checksum-Sha1'   = $sha1
    }
    Invoke-RestMethod -Method Put -Uri $target -InFile $file -Headers $headers -ContentType 'application/gzip' | Out-Null
}

Write-Host "Uploaded $($Folders.Count) packages (version $Version) to $base/$Repo"
