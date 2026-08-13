Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-CleanUiPath {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][string] $Path,
    [string] $BasePath = (Get-Location).Path
  )

  if ([IO.Path]::IsPathRooted($Path)) {
    return [IO.Path]::GetFullPath($Path)
  }
  return [IO.Path]::GetFullPath((Join-Path $BasePath $Path))
}

function Test-CleanUiContainedPath {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][string] $Path,
    [Parameter(Mandatory = $true)][string] $Root
  )

  $fullPath = [IO.Path]::GetFullPath($Path).TrimEnd('\', '/')
  $fullRoot = [IO.Path]::GetFullPath($Root).TrimEnd('\', '/')
  if ($fullPath.Equals($fullRoot, [StringComparison]::OrdinalIgnoreCase)) {
    return $true
  }
  $prefix = $fullRoot + [IO.Path]::DirectorySeparatorChar
  return $fullPath.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)
}

function Get-CleanUiRelativePath {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][string] $Path,
    [Parameter(Mandatory = $true)][string] $Root
  )

  $fullPath = [IO.Path]::GetFullPath($Path)
  $fullRoot = [IO.Path]::GetFullPath($Root).TrimEnd('\', '/')
  if (-not (Test-CleanUiContainedPath -Path $fullPath -Root $fullRoot)) {
    throw "Path is outside root: $fullPath (root $fullRoot)"
  }
  if ($fullPath.Equals($fullRoot, [StringComparison]::OrdinalIgnoreCase)) {
    return ""
  }
  return $fullPath.Substring($fullRoot.Length).TrimStart('\', '/').Replace('\', '/')
}

function Write-CleanUiUtf8 {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][string] $Path,
    [Parameter(Mandatory = $true)][AllowEmptyString()][string] $Text
  )

  $parent = Split-Path -Parent $Path
  if ($parent -and -not (Test-Path -LiteralPath $parent)) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
  }
  $normalized = $Text.Replace("`r`n", "`n").Replace("`r", "`n")
  $encoding = New-Object Text.UTF8Encoding($false)
  [IO.File]::WriteAllText($Path, $normalized, $encoding)
}

function Get-CleanUiSha256 {
  [CmdletBinding()]
  param([Parameter(Mandatory = $true)][string] $Path)

  $stream = [IO.File]::OpenRead($Path)
  try {
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
      $hash = $sha.ComputeHash($stream)
    } finally {
      $sha.Dispose()
    }
  } finally {
    $stream.Dispose()
  }
  return ([BitConverter]::ToString($hash)).Replace("-", "").ToLowerInvariant()
}

function Get-CleanUiFiles {
  [CmdletBinding()]
  param([Parameter(Mandatory = $true)][string] $Root)

  $fullRoot = Resolve-CleanUiPath -Path $Root
  if (-not (Test-Path -LiteralPath $fullRoot -PathType Container)) {
    throw "Directory does not exist: $fullRoot"
  }
  return @(
    Get-ChildItem -LiteralPath $fullRoot -File -Recurse |
      ForEach-Object {
        [pscustomobject]@{
          FullPath = $_.FullName
          RelativePath = Get-CleanUiRelativePath -Path $_.FullName -Root $fullRoot
        }
      } |
      Sort-Object -Property RelativePath
  )
}

function Assert-CleanUiArchivePath {
  [CmdletBinding()]
  param([Parameter(Mandatory = $true)][string] $RelativePath)

  $normalized = $RelativePath.Replace('\', '/')
  if ($normalized.StartsWith('/') -or $normalized -match '(^|/)\.\.(/|$)') {
    throw "Unsafe archive path: $RelativePath"
  }
  if ($normalized -match '(^|/)(\.git|\.codex|\.agents|dist)(/|$)' -or
      $normalized -match '(^|/)(Thumbs\.db|desktop\.ini|\.DS_Store)$' -or
      $normalized -match '(~|\.tmp|\.bak)$') {
    throw "Transient or forbidden archive path: $RelativePath"
  }
}

function New-CleanUiDeterministicZip {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][array] $Entries,
    [Parameter(Mandatory = $true)][string] $OutputPath
  )

  Add-Type -AssemblyName System.IO.Compression
  Add-Type -AssemblyName System.IO.Compression.FileSystem

  $fullOutput = Resolve-CleanUiPath -Path $OutputPath
  $parent = Split-Path -Parent $fullOutput
  if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
  }
  if (Test-Path -LiteralPath $fullOutput) {
    if (-not $fullOutput.EndsWith(".zip", [StringComparison]::OrdinalIgnoreCase)) {
      throw "Refusing to replace a non-ZIP output: $fullOutput"
    }
    Remove-Item -LiteralPath $fullOutput -Force
  }

  $ordered = @($Entries | Sort-Object -Property ArchivePath)
  $seen = @{}
  foreach ($record in $ordered) {
    Assert-CleanUiArchivePath -RelativePath $record.ArchivePath
    if ($seen.ContainsKey($record.ArchivePath)) {
      throw "Duplicate archive path: $($record.ArchivePath)"
    }
    $seen[$record.ArchivePath] = $true
    if (-not (Test-Path -LiteralPath $record.SourcePath -PathType Leaf)) {
      throw "Archive source file is missing: $($record.SourcePath)"
    }
  }

  $fileStream = [IO.File]::Open(
    $fullOutput, [IO.FileMode]::CreateNew, [IO.FileAccess]::ReadWrite,
    [IO.FileShare]::None)
  try {
    $archive = New-Object IO.Compression.ZipArchive(
      $fileStream, [IO.Compression.ZipArchiveMode]::Create, $false)
    try {
      $fixedTime = [DateTimeOffset]::new(
        2000, 1, 1, 0, 0, 0, [TimeSpan]::Zero)
      foreach ($record in $ordered) {
        $entry = $archive.CreateEntry(
          $record.ArchivePath.Replace('\', '/'),
          [IO.Compression.CompressionLevel]::NoCompression)
        $entry.LastWriteTime = $fixedTime
        $input = [IO.File]::OpenRead($record.SourcePath)
        $output = $entry.Open()
        try {
          $input.CopyTo($output)
        } finally {
          $output.Dispose()
          $input.Dispose()
        }
      }
    } finally {
      $archive.Dispose()
    }
  } finally {
    $fileStream.Dispose()
  }

  return [pscustomobject]@{
    Path = $fullOutput
    Sha256 = Get-CleanUiSha256 -Path $fullOutput
    Entries = $ordered.Count
  }
}

function Get-CleanUiCoreExportPaths {
  [CmdletBinding()]
  param([Parameter(Mandatory = $true)][string] $SourceRoot)

  $root = Resolve-CleanUiPath -Path $SourceRoot
  $coreRoot = Join-Path $root "src\clean_ui"
  $manifestPath = Join-Path $coreRoot "module_manifest.lua"
  if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw "Core module manifest is missing: $manifestPath"
  }

  $manifest = [IO.File]::ReadAllText($manifestPath, [Text.Encoding]::UTF8)
  $moduleMatches = [regex]::Matches(
    $manifest, '\["([a-z0-9_]+(?:\.[a-z0-9_]+)*)"\]\s*=',
    [Text.RegularExpressions.RegexOptions]::IgnoreCase)
  $declared = @($moduleMatches | ForEach-Object {
      $_.Groups[1].Value.Replace('.', '/') + ".lua"
    })
  $declared += @("bootstrap.lua", "module_manifest.lua")
  $declared = @($declared | Sort-Object -Unique)

  foreach ($required in @(
      "bootstrap.lua", "module_manifest.lua", "version.lua", "core.lua")) {
    if ($declared -notcontains $required) {
      throw "module_manifest.lua does not export required file: $required"
    }
  }

  $actual = @(Get-CleanUiFiles -Root $coreRoot |
    Where-Object { $_.RelativePath.EndsWith(".lua") } |
    ForEach-Object { $_.RelativePath })
  $missing = @($declared | Where-Object { $actual -notcontains $_ })
  $extra = @($actual | Where-Object { $declared -notcontains $_ })
  if ($missing.Count -gt 0) {
    throw "Declared core files are missing: $($missing -join ', ')"
  }
  if ($extra.Count -gt 0) {
    throw "Core Lua files are not declared for export: $($extra -join ', ')"
  }

  $records = @()
  foreach ($relative in $declared) {
    $records += [pscustomobject]@{
      SourcePath = Join-Path $coreRoot $relative.Replace('/', '\')
      ExportPath = $relative
      Text = $true
    }
  }
  foreach ($notice in @("LICENSE", "THIRD_PARTY_NOTICES.md")) {
    $source = Join-Path $root $notice
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
      throw "Required export notice is missing: $source"
    }
    $records += [pscustomobject]@{
      SourcePath = $source
      ExportPath = $notice
      Text = $true
    }
  }
  return @($records | Sort-Object -Property ExportPath)
}
