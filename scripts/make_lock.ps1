[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string] $VendorRoot,
  [Parameter(Mandatory = $true)][string] $OutputPath,
  [Parameter(Mandatory = $true)][string] $CoreTag,
  [Parameter(Mandatory = $true)][string] $CoreCommit
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "lib\CleanUiTools.ps1")

$vendor = Resolve-CleanUiPath -Path $VendorRoot
$output = Resolve-CleanUiPath -Path $OutputPath
if ((Split-Path -Leaf $vendor) -ne "clean_ui_core") {
  throw "Vendor root leaf must be named clean_ui_core: $vendor"
}
if (-not (Test-Path -LiteralPath $vendor -PathType Container)) {
  throw "Vendor root does not exist: $vendor"
}
if (Test-CleanUiContainedPath -Path $output -Root $vendor) {
  throw "Lock file cannot be written inside the tree it hashes"
}
if ([string]::IsNullOrWhiteSpace($CoreTag)) {
  throw "CoreTag cannot be empty"
}
if ($CoreCommit -notmatch '^[0-9a-fA-F]{40}$') {
  throw "CoreCommit must be a full 40-character hexadecimal commit"
}

$fileRecords = @()
foreach ($file in Get-CleanUiFiles -Root $vendor) {
  Assert-CleanUiArchivePath -RelativePath $file.RelativePath
  $fileRecords += [ordered]@{
    path = $file.RelativePath
    sha256 = Get-CleanUiSha256 -Path $file.FullPath
  }
}
if ($fileRecords.Count -eq 0) { throw "Vendor tree contains no files" }

$lock = [ordered]@{
  schema = 1
  coreTag = $CoreTag
  coreCommit = $CoreCommit.ToLowerInvariant()
  files = @($fileRecords)
}
$json = $lock | ConvertTo-Json -Depth 8
Write-CleanUiUtf8 -Path $output -Text ($json + "`n")
Write-Output ("Wrote {0} with {1} file hashes" -f
  $output, $fileRecords.Count)

