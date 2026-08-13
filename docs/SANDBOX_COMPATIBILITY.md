# Mod Sandbox Compatibility

Clean UI treats the host mod sandbox as a hard release requirement. Everything
exported from `src/clean_ui` and every installable example must load without raw
filesystem, process, thread, package, or debug access.

## Audit status

The source tree and all seven installable examples were re-audited against the
announced sandbox contract on 2026-08-12. The static release gate passed 70
UTF-8 Lua source files with no blocked API, private-global coupling, unsafe
literal or manifest path, reparse point, native binary, or Lua/LuaJIT bytecode.

This is a source-level compatibility result, not a claim that a future host
build has already been released. Before release, run the same gate and load the
examples on the first tagged sandboxed host supported by the product manifests.

The sandbox boundary is distributed mod code: `src/clean_ui` after export and
the contents of each example's `mods/<id>` directory. Repository-only build and
test scripts run outside the game and may use host filesystem APIs to inspect
or package those files; they are not copied into an installed mod.

## Supported replacements

| Do not use in shipped mod Lua | Use instead |
|---|---|
| `io.*` | `mod:read(relative)` for packaged source/data; `mod.storage` for persistent data |
| `os.getenv`, `os.execute`, `os.remove`, `os.rename`, `os.exit`, `os.tmpname` | No direct replacement; request a scoped host API when a real capability is missing |
| `love.filesystem` | `mod:read`, `mod.assets`, or `mod.storage` |
| `love.thread`, `love.system`, `love.event` | `mod.events`, `mod.hooks`, `mod.input`, and the normal render APIs |
| `dofile`, `loadfile`, `package`, `debug`, `getfenv`, `setfenv` | `mod:read` followed by the sandbox-provided source-only `load`/`loadstring` |
| `require("ffi")` or `require("love.*")` | Use the provided `love` table and supported engine modules |
| Lua/LuaJIT bytecode | UTF-8 Lua source |

`os.time`, `os.date`, and `os.clock` remain available. Graphics, audio, timers,
and input under the provided `love` table remain available unless the host
documents a narrower API.

There is no permission that restores raw filesystem access. Clean UI and its
examples must not request or depend on one.

## Reading packaged modules

`mod:read` accepts a path relative to the calling mod. Absolute paths, drive
letters, and `..` segments are invalid. The host returns source text without
exposing a filesystem path.

```lua
local source, readError = mod:read("contract.lua")
assert(source, readError)

local compile = loadstring or load
local chunk, loadError = compile(source, "@contract.lua")
assert(chunk, loadError)

local contract = chunk()
```

The `load` and `loadstring` functions in this example are the sandbox-provided
versions. The loaded chunk inherits the calling mod's private environment; it
does not recover engine globals or filesystem access. Clean UI's bootstrap uses
the same pattern with a static module manifest and an injected `mod:read`
function.

Do not substitute `dofile`, `loadfile`, a modified `package.path`, or a host
filesystem path. All distributed `.lua` files must remain source. A compiled
chunk renamed to `main.lua` is still bytecode and is rejected.

## Persistent data

Use `mod.storage` for independently persisted data owned by the mod and current
playthrough:

```lua
local saved = mod.storage:read(game, "settings") or {}

mod.storage:write(game, "settings", {
  value = saved.value or "default",
})
```

Storage values are data, not executable Lua. Do not serialize functions, live
screen objects, canvases, shaders, or callbacks. Clean UI settings use the
public `mod.options:set` API; per-save Start-menu pins use `mod.save` according
to the product contract because they intentionally travel with a normal game
save. Neither mechanism is implemented with private files or raw filesystem
access.

## Private globals and cross-mod communication

`_G` belongs only to the current mod. Assigning a value there neither publishes
it to other mods nor mutates the engine's global table.

Cross-mod integration uses exports:

```lua
mod.exports.myApi = { version = 1 }

local dependency = mod.find("another_mod")
local api = dependency and dependency.exports and dependency.exports.someApi
```

Clean UI exposes API V3 through `mod.exports.cleanUiHost`. Integrations should
retry discovery on `mods.loaded` rather than relying on load order or shared
globals.

## Paths and manifests

The following values must be relative paths within the mod:

- `manifest.json` fields `entry` and `options_schema`;
- arguments to `mod:read`;
- arguments to `mod.assets:path` and `mod.assets:image`.

Do not use an absolute path, drive letter, URI, empty segment, or `..` segment.
Use forward slashes; do not use backslashes. The Clean UI source verifier
applies this rule to example manifests and statically visible `mod:read`,
`mod.assets:path`, and `mod.assets:image` calls. Dynamic paths must be produced
from a fixed manifest or a constrained identifier grammar; the host remains the
authoritative enforcement boundary.

## Local release gate

Run both checks before exporting or packaging core/examples:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File .\scripts\verify_sandbox.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File .\scripts\verify_source_tree.ps1
```

The sandbox verifier scans exported core source and complete example mod roots.
It rejects:

- `io`, unsafe `os`, blocked LÖVE namespaces, `debug`, `package`, `ffi`,
  blocked loader/environment APIs, and blocked module loads, including bare
  `require "..."` syntax and bracket access to LÖVE namespaces;
- `_G` integration, because each mod receives a private global table;
- unsafe literal own-file/asset paths and unsafe `entry` or `options_schema`
  manifest paths;
- reparse points/symlinks, native-library extensions, PE/ELF/Mach-O/WebAssembly
  signatures, `.luac` files, and Lua/LuaJIT bytecode hidden behind another
  extension; and
- invalid UTF-8 Lua source.

Positive and negative scanner self-tests run on every invocation. This static
gate deliberately complements the product private-environment smoke tests and
the official host validator; it does not attempt to emulate every host check.

The static gate complements, but does not replace, loading each product on the
official sandboxed host and running the host mod validator.
