[CmdletBinding()]
param(
  [string] $SourceRoot,
  [Parameter(Mandatory = $true)][string] $Destination
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "lib\CleanUiTools.ps1")

$SourceRoot = if ([string]::IsNullOrWhiteSpace($SourceRoot)) {
  Split-Path -Parent $PSScriptRoot
} else { $SourceRoot }
$source = Resolve-CleanUiPath -Path $SourceRoot
$destination = Resolve-CleanUiPath -Path $Destination
if ((Split-Path -Leaf $destination) -ne "clean_ui_core") {
  throw "Destination leaf must be named clean_ui_core: $destination"
}
if (Test-CleanUiContainedPath -Path $destination -Root $source) {
  $allowedVendor = Join-Path $source "vendor\clean_ui_core"
  if (-not $destination.Equals(
      [IO.Path]::GetFullPath($allowedVendor),
      [StringComparison]::OrdinalIgnoreCase)) {
    throw "Destination inside the source repository is allowed only at vendor\clean_ui_core"
  }
}

$records = @(Get-CleanUiCoreExportPaths -SourceRoot $source)
$parent = Split-Path -Parent $destination
if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
  New-Item -ItemType Directory -Path $parent -Force | Out-Null
}
$nonce = [Guid]::NewGuid().ToString("N")
$staging = Join-Path $parent ("clean_ui_core.export." + $nonce)
$backup = Join-Path $parent ("clean_ui_core.backup." + $nonce)
New-Item -ItemType Directory -Path $staging | Out-Null

$strictUtf8 = New-Object Text.UTF8Encoding($false, $true)
$movedExisting = $false
try {
  foreach ($record in $records) {
    $target = Join-Path $staging $record.ExportPath.Replace('/', '\')
    $targetParent = Split-Path -Parent $target
    if (-not (Test-Path -LiteralPath $targetParent -PathType Container)) {
      New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
    }
    if ($record.Text) {
      $bytes = [IO.File]::ReadAllBytes($record.SourcePath)
      $text = $strictUtf8.GetString($bytes)
      Write-CleanUiUtf8 -Path $target -Text $text
    } else {
      [IO.File]::Copy($record.SourcePath, $target, $false)
    }
  }

  if (Test-Path -LiteralPath $destination) {
    Move-Item -LiteralPath $destination -Destination $backup
    $movedExisting = $true
  }
  Move-Item -LiteralPath $staging -Destination $destination
  if ($movedExisting -and (Test-Path -LiteralPath $backup)) {
    Remove-Item -LiteralPath $backup -Recurse -Force
  }
} catch {
  if (-not (Test-Path -LiteralPath $destination) -and
      (Test-Path -LiteralPath $backup)) {
    Move-Item -LiteralPath $backup -Destination $destination
  }
  throw
} finally {
  if (Test-Path -LiteralPath $staging) {
    Remove-Item -LiteralPath $staging -Recurse -Force
  }
}

$exported = @(Get-CleanUiFiles -Root $destination)
Write-Output ("Exported {0} deterministic core files to {1}" -f
  $exported.Count, $destination)
