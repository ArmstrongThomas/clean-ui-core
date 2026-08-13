[CmdletBinding()]
param([string]$SourceRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$root = if ([string]::IsNullOrWhiteSpace($SourceRoot)) {
  Split-Path -Parent $PSScriptRoot
} else { [IO.Path]::GetFullPath($SourceRoot) }

$roots = @((Join-Path $root "src\clean_ui"))
$modRoots = @()
$examplesRoot = Join-Path $root "examples"
if (Test-Path -LiteralPath $examplesRoot -PathType Container) {
  foreach ($example in Get-ChildItem -LiteralPath $examplesRoot -Directory) {
    $modsRoot = Join-Path $example.FullName "mods"
    if (-not (Test-Path -LiteralPath $modsRoot -PathType Container)) { continue }
    foreach ($modRoot in Get-ChildItem -LiteralPath $modsRoot -Directory) {
      $modRoots += $modRoot.FullName
      $roots += $modRoot.FullName
    }
  }
}

# This scanner is intentionally conservative. Shipped mod source has no reason
# to name these blocked globals, even in aliases. Keeping the rules here (rather
# than mirroring the host implementation) makes a host sandbox failure a local
# source-verification failure first.
$rules = @(
  [pscustomobject]@{
    Code = "raw_io"
    Pattern = '(?<![A-Za-z0-9_])io(?![A-Za-z0-9_])'
    Message = "io is unavailable; use mod:read or mod.storage"
  },
  [pscustomobject]@{
    Code = "unsafe_os"
    Pattern = '(?<![A-Za-z0-9_])os(?![A-Za-z0-9_])(?!(?:\s*\.\s*(?:time|date|clock)(?![A-Za-z0-9_])))'
    Message = "only os.time, os.date, and os.clock are available"
  },
  [pscustomobject]@{
    Code = "blocked_love_namespace"
    Pattern = '(?<![A-Za-z0-9_])love\s*(?:\.\s*(?:filesystem|thread|system|event)(?![A-Za-z0-9_])|\[\s*["''](?:filesystem|thread|system|event)["'']\s*\])'
    Message = "blocked love namespace; use mod APIs"
  },
  [pscustomobject]@{
    Code = "blocked_global"
    Pattern = '(?<![A-Za-z0-9_])(?:debug|package|ffi)(?![A-Za-z0-9_])'
    Message = "debug, package, and ffi are unavailable"
  },
  [pscustomobject]@{
    Code = "blocked_loader"
    Pattern = '(?<![A-Za-z0-9_])(?:dofile|loadfile|getfenv|setfenv)(?![A-Za-z0-9_])'
    Message = "blocked loader/environment API; use mod:read plus sandboxed load"
  },
  [pscustomobject]@{
    Code = "blocked_require"
    Pattern = '(?<![A-Za-z0-9_])require\s*(?:\(\s*)?["''](?:io|os|debug|package|ffi|love(?:\.|["'']))'
    Message = "blocked module require; use the provided love table or supported engine modules"
  },
  [pscustomobject]@{
    Code = "private_global"
    Pattern = '(?<![A-Za-z0-9_])_G(?![A-Za-z0-9_])'
    Message = "Clean UI must not use private _G for integration; use mod.exports and mod.find"
  }
)

$literalPathPatterns = @(
  '(?x)(?<![A-Za-z0-9_])mod\s*:\s*read\s*\(\s*(?<quote>["''])(?<path>[^"'']*)\k<quote>',
  '(?x)(?<![A-Za-z0-9_])mod\s*\.\s*assets\s*:\s*(?:path|image)\s*\(\s*(?<quote>["''])(?<path>[^"'']*)\k<quote>'
)

$nativeExtensions = @(
  ".a", ".dll", ".dylib", ".exe", ".lib", ".luac", ".so", ".wasm"
)

function Get-LineNumber([string]$Text, [int]$Index) {
  if ($Index -le 0) { return 1 }
  return 1 + ([regex]::Matches($Text.Substring(0, $Index), "`n")).Count
}

function Get-SandboxViolations([string]$Source) {
  $violations = New-Object 'Collections.Generic.List[object]'
  foreach ($rule in $rules) {
    foreach ($match in [regex]::Matches($Source, $rule.Pattern)) {
      $violations.Add([pscustomobject]@{
        Code = $rule.Code
        Line = Get-LineNumber -Text $Source -Index $match.Index
        Message = $rule.Message
        Match = $match.Value
      })
    }
  }
  return $violations.ToArray()
}

function Get-ForbiddenBinaryKind([byte[]]$Bytes) {
  if ($Bytes.Length -ge 4 -and $Bytes[0] -eq 0x1B -and
      $Bytes[1] -eq 0x4C -and $Bytes[2] -eq 0x75 -and
      $Bytes[3] -eq 0x61) {
    return "Lua bytecode"
  }
  if ($Bytes.Length -ge 3 -and $Bytes[0] -eq 0x1B -and
      $Bytes[1] -eq 0x4C -and $Bytes[2] -eq 0x4A) {
    return "LuaJIT bytecode"
  }
  if ($Bytes.Length -ge 2 -and $Bytes[0] -eq 0x4D -and $Bytes[1] -eq 0x5A) {
    return "PE executable"
  }
  if ($Bytes.Length -ge 4 -and $Bytes[0] -eq 0x7F -and
      $Bytes[1] -eq 0x45 -and $Bytes[2] -eq 0x4C -and
      $Bytes[3] -eq 0x46) {
    return "ELF executable"
  }
  if ($Bytes.Length -ge 4) {
    $magic = '{0:X2}{1:X2}{2:X2}{3:X2}' -f $Bytes[0], $Bytes[1], $Bytes[2], $Bytes[3]
    if ($magic -in @("FEEDFACE", "FEEDFACF", "CEFAEDFE", "CFFAEDFE",
        "CAFEBABE", "BEBAFECA")) {
      return "Mach-O executable"
    }
    if ($magic -eq "0061736D") { return "WebAssembly bytecode" }
  }
  return $null
}

function Test-ModRelativePath([string]$Value) {
  if ([string]::IsNullOrWhiteSpace($Value) -or $Value.IndexOf([char]0) -ge 0) {
    return $false
  }
  if ($Value.Contains('\')) { return $false }
  if ($Value.StartsWith('/') -or $Value -match '^[A-Za-z]:' -or
      $Value -match '^[A-Za-z][A-Za-z0-9+.-]*:') { return $false }
  foreach ($segment in $Value.Split('/')) {
    if ([string]::IsNullOrWhiteSpace($segment) -or $segment -eq '.' -or
        $segment -eq '..') { return $false }
  }
  return $true
}

function Get-LiteralModPaths([string]$Source) {
  $paths = New-Object 'Collections.Generic.List[object]'
  foreach ($pattern in $literalPathPatterns) {
    foreach ($match in [regex]::Matches($Source, $pattern)) {
      $paths.Add([pscustomobject]@{
        Path = $match.Groups["path"].Value
        Line = Get-LineNumber -Text $Source -Index $match.Index
      })
    }
  }
  return $paths.ToArray()
}

function Assert-ScannerContract {
  $blocked = @{
    raw_io = 'return io.open("state.txt", "w")'
    os_execute = 'return os.execute("tool")'
    os_alias = 'local unsafe = os'
    love_filesystem = 'return love.filesystem.read("state")'
    love_bracket = 'return love["thread"]'
    debug_global = 'return debug.traceback()'
    package_global = 'return package.path'
    dofile_call = 'return dofile("module.lua")'
    loadfile_call = 'return loadfile("module.lua")'
    require_ffi = 'return require("ffi")'
    require_love = "return require 'love.graphics'"
    private_global = 'return _G.shared_api'
  }
  foreach ($name in $blocked.Keys) {
    if (@(Get-SandboxViolations $blocked[$name]).Count -eq 0) {
      throw "Sandbox scanner self-test failed to reject: $name"
    }
  }

  $allowed = @{
    mod_read = 'local source = mod:read("contract.lua")'
    sandbox_load = 'local chunk = assert(load(source, "@contract.lua"))'
    storage = 'mod.storage:write(game, "settings", { value = true })'
    os_time = 'return os.time()'
    os_date = 'return os.date("!*t")'
    os_clock = 'return os.clock()'
    love_graphics = 'love.graphics.rectangle("fill", 0, 0, 1, 1)'
    require_core = 'local Rect = requireCore("geometry.rect")'
    exports = 'mod.exports.cleanUiHost = host'
    find = 'local other = mod.find("other_mod")'
  }
  foreach ($name in $allowed.Keys) {
    $found = @(Get-SandboxViolations $allowed[$name])
    if ($found.Count -gt 0) {
      throw "Sandbox scanner self-test rejected allowed source: $name ($($found[0].Code))"
    }
  }

  if ((Get-ForbiddenBinaryKind ([byte[]](0x1B, 0x4C, 0x75, 0x61))) -ne "Lua bytecode") {
    throw "Sandbox scanner self-test failed to identify Lua bytecode"
  }
  if ((Get-ForbiddenBinaryKind ([byte[]](0x1B, 0x4C, 0x4A))) -ne "LuaJIT bytecode") {
    throw "Sandbox scanner self-test failed to identify LuaJIT bytecode"
  }
  if ((Get-ForbiddenBinaryKind ([byte[]](0x4D, 0x5A))) -ne "PE executable" -or
      (Get-ForbiddenBinaryKind ([byte[]](0x7F, 0x45, 0x4C, 0x46))) -ne "ELF executable" -or
      (Get-ForbiddenBinaryKind ([byte[]](0x00, 0x61, 0x73, 0x6D))) -ne "WebAssembly bytecode") {
    throw "Sandbox scanner self-test failed to identify native/portable bytecode"
  }
  if ($null -ne (Get-ForbiddenBinaryKind ([Text.Encoding]::UTF8.GetBytes("return {}")))) {
    throw "Sandbox scanner self-test identified source as bytecode"
  }

  foreach ($safe in @("main.lua", "src/bootstrap.lua", "assets/icon.png")) {
    if (-not (Test-ModRelativePath $safe)) {
      throw "Sandbox path self-test rejected safe path: $safe"
    }
  }
  foreach ($unsafe in @("", "../main.lua", "src/../main.lua", "/main.lua",
      "C:/main.lua", "file://main.lua", "src//main.lua", "./main.lua",
      "src\main.lua")) {
    if (Test-ModRelativePath $unsafe) {
      throw "Sandbox path self-test accepted unsafe path: $unsafe"
    }
  }
  $literalSafe = @(Get-LiteralModPaths 'return mod:read("src/module.lua")')
  $literalUnsafe = @(Get-LiteralModPaths 'return mod.assets:image("../escape.png")')
  if ($literalSafe.Count -ne 1 -or
      -not (Test-ModRelativePath $literalSafe[0].Path) -or
      $literalUnsafe.Count -ne 1 -or
      (Test-ModRelativePath $literalUnsafe[0].Path)) {
    throw "Sandbox literal-path self-test failed"
  }
}

Assert-ScannerContract

$hits = New-Object 'Collections.Generic.List[string]'
$luaCount = 0
foreach ($scanRoot in $roots) {
  foreach ($item in Get-ChildItem -LiteralPath $scanRoot -Recurse -Force `
      -ErrorAction SilentlyContinue) {
    if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
      $hits.Add("$($item.FullName): reparse points/symlinks may not ship")
    }
  }

  foreach ($file in Get-ChildItem -LiteralPath $scanRoot -File -Recurse) {
    $bytes = [IO.File]::ReadAllBytes($file.FullName)
    $binaryKind = Get-ForbiddenBinaryKind $bytes
    $extension = $file.Extension.ToLowerInvariant()
    if ($extension -in $nativeExtensions) {
      $hits.Add("$($file.FullName): native/compiled extension may not ship")
    } elseif ($null -ne $binaryKind) {
      $hits.Add("$($file.FullName): $binaryKind may not ship")
    }
    if ($extension -ne ".lua") { continue }
    $luaCount++
    if ($null -ne $binaryKind) {
      continue
    }

    try {
      $encoding = New-Object Text.UTF8Encoding($false, $true)
      $source = $encoding.GetString($bytes)
    } catch {
      $hits.Add("$($file.FullName): Lua source must be valid UTF-8")
      continue
    }

    foreach ($violation in Get-SandboxViolations $source) {
      $hits.Add(
        "$($file.FullName):$($violation.Line): $($violation.Code): " +
        "$($violation.Message) [$($violation.Match)]")
    }
    foreach ($literal in Get-LiteralModPaths $source) {
      if (-not (Test-ModRelativePath $literal.Path)) {
        $hits.Add("$($file.FullName):$($literal.Line): unsafe literal mod path [$($literal.Path)]")
      }
    }
  }
}

foreach ($modRoot in $modRoots) {
  $manifestPath = Join-Path $modRoot "manifest.json"
  try {
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    foreach ($field in @("entry", "options_schema")) {
      $property = $manifest.PSObject.Properties[$field]
      if ($field -eq "options_schema" -and $null -eq $property) { continue }
      $value = if ($null -eq $property) { "" } else { [string]$property.Value }
      if (-not (Test-ModRelativePath $value)) {
        $hits.Add("$manifestPath`: $field must be a safe forward-slash mod-relative path")
      } elseif (-not (Test-Path -LiteralPath (Join-Path $modRoot $value) -PathType Leaf)) {
        $hits.Add("$manifestPath`: $field target does not exist: $value")
      }
    }
  } catch {
    $hits.Add("$manifestPath`: unable to validate sandbox paths: $($_.Exception.Message)")
  }
}

if ($hits.Count -gt 0) {
  throw "Sandbox-incompatible shipped/example Lua:`n$($hits -join "`n")"
}
Write-Output "Sandbox verification passed ($luaCount UTF-8 source Lua files; blocked APIs, private-global coupling, unsafe literal/manifest paths, reparse points, native binaries, and bytecode absent)."
