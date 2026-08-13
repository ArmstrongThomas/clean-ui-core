[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string] $ExamplePath,
  [string] $OutputDirectory
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "lib\CleanUiTools.ps1")

$exampleRoot = Resolve-CleanUiPath -Path $ExamplePath
$modsRoot = Join-Path $exampleRoot "mods"
if (-not (Test-Path -LiteralPath $modsRoot -PathType Container)) {
  throw "Example has no mods directory: $modsRoot"
}

$modDirectories = @(Get-ChildItem -LiteralPath $modsRoot -Directory)
if ($modDirectories.Count -ne 1) {
  throw "Example must contain exactly one mod directory; found $($modDirectories.Count)"
}

$modRoot = $modDirectories[0].FullName
$manifestPath = Join-Path $modRoot "manifest.json"
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
  throw "Example manifest is missing: $manifestPath"
}
$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 |
  ConvertFrom-Json
if ([string]::IsNullOrWhiteSpace([string] $manifest.id) -or
    [string]::IsNullOrWhiteSpace([string] $manifest.version) -or
    [string]::IsNullOrWhiteSpace([string] $manifest.entry)) {
  throw "Manifest requires id, version, and entry"
}
if ($manifest.id -ne $modDirectories[0].Name) {
  throw "Manifest id '$($manifest.id)' must match root '$($modDirectories[0].Name)'"
}
if ([int] $manifest.api -ne 2) {
  throw "Example manifests must use mod API 2"
}
if ($manifest.version -notmatch '^\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?$') {
  throw "Manifest version is not semantic: $($manifest.version)"
}

$entryPath = Join-Path $modRoot ([string] $manifest.entry)
if (-not (Test-Path -LiteralPath $entryPath -PathType Leaf)) {
  throw "Manifest entry does not exist: $entryPath"
}

if (-not $PSBoundParameters.ContainsKey("OutputDirectory")) {
  $OutputDirectory = Join-Path $exampleRoot "dist"
}
$outputRoot = Resolve-CleanUiPath -Path $OutputDirectory
if (-not (Test-Path -LiteralPath $outputRoot)) {
  New-Item -ItemType Directory -Path $outputRoot -Force | Out-Null
}

$entries = @()
foreach ($file in Get-CleanUiFiles -Root $modRoot) {
  Assert-CleanUiArchivePath -RelativePath $file.RelativePath
  $entries += [pscustomobject]@{
    SourcePath = $file.FullPath
    ArchivePath = "$($manifest.id)/$($file.RelativePath)"
  }
}
if ($entries.Count -eq 0) { throw "Example mod contains no files" }

$zipName = "$($manifest.id)-$($manifest.version).zip"
$result = New-CleanUiDeterministicZip -Entries $entries `
  -OutputPath (Join-Path $outputRoot $zipName)

Write-Output ("Built {0} ({1} entries, SHA-256 {2})" -f
  $result.Path, $result.Entries, $result.Sha256)

