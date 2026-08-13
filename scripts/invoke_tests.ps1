[CmdletBinding()]
param(
  [ValidateSet("all", "syntax", "dependency", "unit", "integration",
    "contracts", "visual", "matrix")]
  [string] $Suite = "all",
  [string] $Filter,
  [int] $Seed = 1337,
  [string] $LovePath,
  [string] $SourceRoot,
  [switch] $DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "lib\CleanUiTools.ps1")

$SourceRoot = if ([string]::IsNullOrWhiteSpace($SourceRoot)) {
  Split-Path -Parent $PSScriptRoot
} else { $SourceRoot }
$root = Resolve-CleanUiPath -Path $SourceRoot
$testsRoot = Join-Path $root "tests"
$suites = if ($Suite -eq "all") {
  @("syntax", "dependency", "unit", "integration", "contracts", "visual", "matrix")
} else { @($Suite) }

function Resolve-LoveExecutable([string] $Requested) {
  if (-not [string]::IsNullOrWhiteSpace($Requested)) {
    $full = Resolve-CleanUiPath -Path $Requested
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
      throw "LÖVE executable does not exist: $full"
    }
    return $full
  }

  foreach ($candidate in @(
      "C:\Program Files\LOVE\lovec.exe",
      "C:\Program Files\LOVE\love.exe")) {
    if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
  }
  foreach ($name in @("lovec.exe", "love.exe", "lovec", "love")) {
    $command = Get-Command $name -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }
  }
  throw "Unable to locate LÖVE; pass -LovePath"
}

if ($DryRun) {
  $displayLove = if ([string]::IsNullOrWhiteSpace($LovePath)) {
    "<auto-detected lovec>"
  } else { $LovePath }
  foreach ($suiteName in $suites) {
    Write-Output ("DRY RUN: CLEAN_UI_TEST_SUITE={0} FILTER={1} SEED={2} {3} {4}" -f
      $suiteName, $Filter, $Seed, $displayLove, $testsRoot)
  }
  return
}

if (-not (Test-Path -LiteralPath $testsRoot -PathType Container)) {
  throw "Tests directory does not exist: $testsRoot"
}
$love = Resolve-LoveExecutable $LovePath

$bundleParent = Join-Path $root ".test-bundles"
$bundle = Join-Path $bundleParent ([Guid]::NewGuid().ToString("N"))
$bundleTests = Join-Path $bundle "tests"
New-Item -ItemType Directory -Path $bundleTests -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $testsRoot "main.lua") `
  -Destination (Join-Path $bundle "main.lua")
Copy-Item -LiteralPath (Join-Path $testsRoot "conf.lua") `
  -Destination (Join-Path $bundle "conf.lua")
Copy-Item -LiteralPath (Join-Path $testsRoot "support") `
  -Destination (Join-Path $bundle "support") -Recurse
$bundleCore = Join-Path $bundle "src\clean_ui"
New-Item -ItemType Directory -Path $bundleCore -Force | Out-Null
Get-ChildItem -LiteralPath (Join-Path $root "src\clean_ui") -Force |
  ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination $bundleCore -Recurse -Force
  }

$environmentNames = @(
  "CLEAN_UI_TEST_SUITE", "CLEAN_UI_TEST_FILTER", "CLEAN_UI_TEST_SEED")
$previous = @{}
foreach ($name in $environmentNames) {
  $item = Get-Item -LiteralPath ("Env:" + $name) -ErrorAction SilentlyContinue
  $previous[$name] = if ($item) {
    [pscustomobject]@{ Exists = $true; Value = $item.Value }
  } else {
    [pscustomobject]@{ Exists = $false; Value = $null }
  }
}

$oldLocation = Get-Location
try {
  Set-Location $root
  $env:CLEAN_UI_TEST_SEED = [string] $Seed
  if ([string]::IsNullOrWhiteSpace($Filter)) {
    Remove-Item Env:CLEAN_UI_TEST_FILTER -ErrorAction SilentlyContinue
  } else {
    $env:CLEAN_UI_TEST_FILTER = $Filter
  }

  foreach ($suiteName in $suites) {
    $env:CLEAN_UI_TEST_SUITE = $suiteName
    Write-Output "Running Clean UI suite '$suiteName' with seed $Seed"
    & $love $bundle
    if ($LASTEXITCODE -ne 0) {
      throw "Clean UI suite '$suiteName' failed with exit code $LASTEXITCODE"
    }
  }
} finally {
  Set-Location $oldLocation
  foreach ($name in $environmentNames) {
    $record = $previous[$name]
    if ($record.Exists) {
      Set-Item -LiteralPath ("Env:" + $name) -Value $record.Value
    } else {
      Remove-Item -LiteralPath ("Env:" + $name) -ErrorAction SilentlyContinue
    }
  }
  if (Test-Path -LiteralPath $bundle) {
    Remove-Item -LiteralPath $bundle -Recurse -Force
  }
  if ((Test-Path -LiteralPath $bundleParent) -and
      @(Get-ChildItem -LiteralPath $bundleParent -Force).Count -eq 0) {
    Remove-Item -LiteralPath $bundleParent -Force
  }
}

Write-Output "All requested Clean UI suites passed"
