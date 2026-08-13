[CmdletBinding()]
param(
  [string] $SourceRoot,
  [switch] $DocumentationOnly,
  [string] $VendorRoot,
  [string] $LockPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "lib\CleanUiTools.ps1")

$SourceRoot = if ([string]::IsNullOrWhiteSpace($SourceRoot)) {
  Split-Path -Parent $PSScriptRoot
} else { $SourceRoot }
$root = Resolve-CleanUiPath -Path $SourceRoot
$issues = New-Object 'Collections.Generic.List[string]'

function Add-Issue([string] $Message) {
  $script:issues.Add($Message)
}

function Require-File([string] $RelativePath) {
  $path = Join-Path $root $RelativePath
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    Add-Issue "Missing required file: $RelativePath"
    return $null
  }
  return $path
}

function Read-StrictUtf8([string] $Path) {
  try {
    $encoding = New-Object Text.UTF8Encoding($false, $true)
    return $encoding.GetString([IO.File]::ReadAllBytes($Path))
  } catch {
    Add-Issue "Invalid UTF-8: $(Get-CleanUiRelativePath -Path $Path -Root $root)"
    return $null
  }
}

function Test-ModRelativePath([string] $Value) {
  if ([string]::IsNullOrWhiteSpace($Value)) { return $false }
  $candidate = $Value.Replace('\', '/')
  if ($candidate.StartsWith('/') -or $candidate -match '^[A-Za-z]:') {
    return $false
  }
  if ($candidate -match '^[A-Za-z][A-Za-z0-9+.-]*:') {
    return $false
  }
  foreach ($segment in $candidate.Split('/')) {
    if ([string]::IsNullOrWhiteSpace($segment) -or
        $segment -eq '.' -or $segment -eq '..') {
      return $false
    }
  }
  return $true
}

foreach ($path in @("main.lua", "config/options.json", "nested/module.lua")) {
  if (-not (Test-ModRelativePath $path)) {
    Add-Issue "Internal path-validator self-test rejected safe path: $path"
  }
}
foreach ($path in @(
    "", "../main.lua", "dir/../main.lua", "/main.lua", "C:\main.lua",
    "file://main.lua", "dir//main.lua", ".\main.lua")) {
  if (Test-ModRelativePath $path) {
    Add-Issue "Internal path-validator self-test accepted unsafe path: $path"
  }
}

$requiredDocs = @(
  "docs\CLEAN_UI_REWORK_PLAN.md",
  "docs\ARCHITECTURE.md",
  "docs\API_V3.md",
  "docs\COMPONENTS.md",
  "docs\GALLERY.md",
  "docs\LAYOUT_CONTRACT.md",
  "docs\PRODUCT_PROVIDER_CONTRACT.md",
  "docs\SANDBOX_COMPATIBILITY.md",
  "docs\TESTING.md"
)
foreach ($relative in $requiredDocs) {
  $path = Require-File $relative
  if ($path) {
    $text = Read-StrictUtf8 $path
    if ($null -ne $text) {
      $badCharacters = @([char] 0x00E2, [char] 0x00C3, [char] 0xFFFD)
      foreach ($character in $badCharacters) {
        if ($text.IndexOf($character) -ge 0) {
          Add-Issue "Possible mojibake in $relative (character U+$('{0:X4}' -f [int] $character))"
        }
      }
    }
  }
}

$requiredScripts = @(
  "scripts\lib\CleanUiTools.ps1",
  "scripts\build_example.ps1", "scripts\build_example.cmd",
  "scripts\export_core.ps1", "scripts\export_core.cmd",
  "scripts\make_lock.ps1", "scripts\make_lock.cmd",
  "scripts\verify_source_tree.ps1", "scripts\verify_source_tree.cmd",
  "scripts\verify_sandbox.ps1", "scripts\verify_sandbox.cmd",
  "scripts\invoke_tests.ps1", "scripts\invoke_tests.cmd"
)
foreach ($relative in $requiredScripts) { [void] (Require-File $relative) }

try {
  & (Join-Path $PSScriptRoot "verify_sandbox.ps1") -SourceRoot $root
} catch {
  Add-Issue $_.Exception.Message
}

$expectedExamples = @(
  "party-row-colors",
  "extra-summary-page",
  "dropdown-screen",
  "start-action-pinning",
  "details-fields-footer-lists",
  "modal-overlay",
  "animated-shader-grid"
)
$examplesRoot = Join-Path $root "examples"
[void] (Require-File "examples\README.md")
$seenModIds = @{}
foreach ($slug in $expectedExamples) {
  $exampleRoot = Join-Path $examplesRoot $slug
  if (-not (Test-Path -LiteralPath $exampleRoot -PathType Container)) {
    Add-Issue "Missing example directory: examples/$slug"
    continue
  }
  foreach ($wrapper in @("README.md", "build_release.ps1", "build_release.cmd")) {
    if (-not (Test-Path -LiteralPath (Join-Path $exampleRoot $wrapper) -PathType Leaf)) {
      Add-Issue "Example $slug is missing $wrapper"
    }
  }

  $modsRoot = Join-Path $exampleRoot "mods"
  $modDirectories = @(if (Test-Path -LiteralPath $modsRoot -PathType Container) {
    Get-ChildItem -LiteralPath $modsRoot -Directory
  })
  if ($modDirectories.Count -ne 1) {
    Add-Issue "Example $slug must contain exactly one mod directory"
    continue
  }

  $modRoot = $modDirectories[0].FullName
  $manifestPath = Join-Path $modRoot "manifest.json"
  if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    Add-Issue "Example $slug has no manifest.json"
    continue
  }
  try {
    $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 |
      ConvertFrom-Json
  } catch {
    Add-Issue "Example $slug has invalid manifest JSON: $($_.Exception.Message)"
    continue
  }

  if ($manifest.id -ne $modDirectories[0].Name) {
    Add-Issue "Example $slug manifest id does not match its mod directory"
  }
  if ($seenModIds.ContainsKey([string] $manifest.id)) {
    Add-Issue "Duplicate example mod id: $($manifest.id)"
  } else {
    $seenModIds[[string] $manifest.id] = $true
  }
  if ([int] $manifest.api -ne 2) {
    Add-Issue "Example $slug must use mod API 2"
  }
  $games = @($manifest.games)
  if ($games -notcontains "gen1" -or $games -notcontains "gen2") {
    Add-Issue "Example $slug must explicitly support gen1 and gen2"
  }
  $optional = @($manifest.optional_dependencies)
  if (-not ($optional | Where-Object { $_ -like "gen1_clean_ui@*" })) {
    Add-Issue "Example $slug lacks the Gen1 Clean UI optional dependency"
  }
  if (-not ($optional | Where-Object { $_ -like "gen2_clean_ui@*" })) {
    Add-Issue "Example $slug lacks the Gen2 Clean UI optional dependency"
  }

  $entryValue = [string] $manifest.entry
  $entryPath = $null
  if (-not (Test-ModRelativePath $entryValue)) {
    Add-Issue "Example $slug manifest entry must be a safe mod-relative path"
  } elseif ([IO.Path]::GetExtension($entryValue) -ne ".lua") {
    Add-Issue "Example $slug manifest entry must be source Lua"
  } else {
    $entryPath = Join-Path $modRoot $entryValue
  }

  if ($manifest.PSObject.Properties.Name -contains "options_schema") {
    $schemaValue = [string] $manifest.options_schema
    if (-not (Test-ModRelativePath $schemaValue)) {
      Add-Issue "Example $slug options_schema must be a safe mod-relative path"
    }
  }

  $contractPath = Join-Path $modRoot "contract.lua"
  foreach ($required in @($entryPath, $contractPath)) {
    if ($null -ne $required -and
        -not (Test-Path -LiteralPath $required -PathType Leaf)) {
      Add-Issue "Example $slug is missing $(Split-Path -Leaf $required)"
    }
  }

  foreach ($luaPath in @($entryPath, $contractPath)) {
    if ($null -ne $luaPath -and
        (Test-Path -LiteralPath $luaPath -PathType Leaf)) {
      $lua = Read-StrictUtf8 $luaPath
      if ($null -ne $lua) {
        foreach ($legacy in @(
            "gen1ModernUi", "registerAdapter", "compatibilityApiVersion",
            "surfaceApiVersion")) {
          if ($lua.Contains($legacy)) {
            Add-Issue "Example $slug contains forbidden legacy API token '$legacy'"
          }
        }
      }
    }
  }
  if ($null -ne $entryPath -and
      (Test-Path -LiteralPath $entryPath -PathType Leaf)) {
    $entryLines = @(Get-Content -LiteralPath $entryPath -Encoding UTF8)
    if ($entryLines.Count -gt 120) {
      Add-Issue "Example $slug main.lua is not a thin bootstrap ($($entryLines.Count) lines)"
    }
  }
}

if (Test-Path -LiteralPath $examplesRoot -PathType Container) {
  $actualExamples = @(Get-ChildItem -LiteralPath $examplesRoot -Directory |
    Where-Object { $_.Name -ne "dist" } | ForEach-Object { $_.Name })
  foreach ($extra in $actualExamples) {
    if ($expectedExamples -notcontains $extra) {
      Add-Issue "Unexpected example directory: examples/$extra"
    }
  }
}

$parserType = [Management.Automation.Language.Parser]
foreach ($script in Get-ChildItem -LiteralPath (Join-Path $root "scripts") `
    -Filter "*.ps1" -File -Recurse -ErrorAction SilentlyContinue) {
  $tokens = $null
  $parseErrors = $null
  [void] $parserType::ParseFile($script.FullName, [ref] $tokens, [ref] $parseErrors)
  foreach ($parseError in @($parseErrors)) {
    Add-Issue "PowerShell syntax error in $($script.Name): $($parseError.Message)"
  }
}

if (-not $DocumentationOnly) {
  try {
    [void] (Get-CleanUiCoreExportPaths -SourceRoot $root)
  } catch {
    Add-Issue $_.Exception.Message
  }

  if ([string]::IsNullOrWhiteSpace($VendorRoot) -xor
      [string]::IsNullOrWhiteSpace($LockPath)) {
    Add-Issue "VendorRoot and LockPath must be supplied together"
  } elseif (-not [string]::IsNullOrWhiteSpace($VendorRoot)) {
    try {
      $vendor = Resolve-CleanUiPath -Path $VendorRoot
      $lockFile = Resolve-CleanUiPath -Path $LockPath
      $lock = Get-Content -LiteralPath $lockFile -Raw -Encoding UTF8 |
        ConvertFrom-Json
      if ([int] $lock.schema -ne 1) { Add-Issue "Unsupported lock schema" }
      if ([string] $lock.coreCommit -notmatch '^[0-9a-f]{40}$') {
        Add-Issue "Lock coreCommit is not full lower-case hexadecimal"
      }

      $lockRecords = @($lock.files)
      $lockPaths = @($lockRecords | ForEach-Object { [string] $_.path })
      $sortedLockPaths = @($lockPaths | Sort-Object)
      if (($lockPaths -join "`n") -ne ($sortedLockPaths -join "`n")) {
        Add-Issue "Lock file paths are not sorted"
      }
      if (@($lockPaths | Group-Object | Where-Object Count -gt 1).Count -gt 0) {
        Add-Issue "Lock file contains duplicate paths"
      }

      $actualFiles = @(Get-CleanUiFiles -Root $vendor)
      $actualPaths = @($actualFiles | ForEach-Object { $_.RelativePath })
      foreach ($missing in $lockPaths | Where-Object { $actualPaths -notcontains $_ }) {
        Add-Issue "Locked vendor file is missing: $missing"
      }
      foreach ($extra in $actualPaths | Where-Object { $lockPaths -notcontains $_ }) {
        Add-Issue "Untracked vendor file: $extra"
      }
      foreach ($record in $lockRecords) {
        $path = Join-Path $vendor ([string] $record.path).Replace('/', '\')
        if (Test-Path -LiteralPath $path -PathType Leaf) {
          $actualHash = Get-CleanUiSha256 -Path $path
          if ($actualHash -ne [string] $record.sha256) {
            Add-Issue "Vendor hash mismatch: $($record.path)"
          }
        }
      }

      $temporaryParent = Join-Path ([IO.Path]::GetTempPath()) `
        ("clean-ui-verify-" + [Guid]::NewGuid().ToString("N"))
      $temporaryVendor = Join-Path $temporaryParent "clean_ui_core"
      New-Item -ItemType Directory -Path $temporaryParent | Out-Null
      try {
        $null = & (Join-Path $PSScriptRoot "export_core.ps1") `
          -SourceRoot $root -Destination $temporaryVendor
        $expectedFiles = @(Get-CleanUiFiles -Root $temporaryVendor)
        $expectedPaths = @($expectedFiles | ForEach-Object { $_.RelativePath })
        foreach ($path in $expectedPaths | Where-Object { $actualPaths -notcontains $_ }) {
          Add-Issue "Vendor is missing exported source file: $path"
        }
        foreach ($file in $expectedFiles) {
          $vendorPath = Join-Path $vendor $file.RelativePath.Replace('/', '\')
          if ((Test-Path -LiteralPath $vendorPath -PathType Leaf) -and
              (Get-CleanUiSha256 -Path $vendorPath) -ne
                (Get-CleanUiSha256 -Path $file.FullPath)) {
            Add-Issue "Vendor differs from normalized source export: $($file.RelativePath)"
          }
        }
      } finally {
        if (Test-Path -LiteralPath $temporaryParent) {
          Remove-Item -LiteralPath $temporaryParent -Recurse -Force
        }
      }
    } catch {
      Add-Issue "Vendor/lock verification failed: $($_.Exception.Message)"
    }
  }
}

if ($issues.Count -gt 0) {
  foreach ($issue in $issues) { Write-Error $issue }
  throw "Clean UI source verification failed with $($issues.Count) issue(s)"
}

$mode = if ($DocumentationOnly) { "documentation/examples/tooling" } else { "full source" }
Write-Output "Clean UI $mode verification passed"
