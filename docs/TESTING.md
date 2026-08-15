# Clean UI Testing

Clean UI treats layout, registration, surfaces, and native fallback as
contracts rather than screenshot-only behavior.

## Launchers

From the core repository:

```powershell
.\scripts\invoke_tests.ps1
.\scripts\invoke_tests.ps1 -Suite unit -Filter dropdown
.\scripts\invoke_tests.ps1 -Suite matrix -Seed 8675309
.\scripts\invoke_tests.ps1 -DryRun
```

The `.cmd` wrapper forwards all arguments:

```bat
scripts\invoke_tests.cmd -Suite contracts
```

The PowerShell launcher resolves `lovec.exe`, sets
`CLEAN_UI_TEST_FILTER`, `CLEAN_UI_TEST_SEED`, and `CLEAN_UI_TEST_SUITE`, and
propagates the first nonzero exit code. It never edits source or test files.

## Sandbox release gate

The sandbox scan is mandatory for every core export and example archive:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File .\scripts\verify_sandbox.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File .\scripts\verify_source_tree.ps1
```

The first command scans only shipped core/example Lua. It rejects raw `io`,
unsafe `os`, blocked `love` namespaces, debug/package/environment loaders,
blocked `require` targets, invalid UTF-8, `.luac`, and Lua/LuaJIT bytecode even
when renamed with a `.lua` extension. Built-in positive and negative probes
also ensure the scanner continues to allow `mod:read`, sandboxed `load`,
`mod.storage`, `os.time`/`os.date`/`os.clock`, and `love.graphics`.

The source-tree verifier invokes the sandbox scan and additionally rejects
unsafe example manifest paths. CI must still validate and load the final product
on the official sandboxed host; static matching cannot prove runtime behavior.
See [SANDBOX_COMPATIBILITY.md](SANDBOX_COMPATIBILITY.md).

## Suite order

Default execution is deliberately separated:

```text
syntax -> dependency -> unit -> integration -> contracts -> visual -> matrix
```

This keeps a dependency-layer failure from being buried in a viewport matrix.
The seed is printed for every run.

## Required viewport matrix

```lua
{
  { 320, 180 }, { 640, 360 }, { 360, 640 }, { 390, 844 },
  { 1024, 768 }, { 1280, 720 }, { 1280, 1024 }, { 1600, 1000 },
  { 1920, 1080 }, { 2560, 1440 }, { 3440, 1440 },
  { 3840, 2160 }, { 5120, 2784 },
}
```

Representative touch-safe insets cover portrait, short landscape, desktop,
ultrawide, 4K, and 5K.

For every production fixture, matrix coverage combines:

- UI Size Auto, Small, Medium, and Large;
- Plain Pixel Auto and 1× through 4×;
- System font;
- Density Auto, Comfortable, and Compact;
- Clean, Dark, and High Contrast themes;
- NORMAL and OVERFLOW content;
- maximum combined settings.

The full Cartesian matrix may be sharded by stable fixture hash. A deterministic
smoke subset runs locally.

## Core invariants

Every layout result asserts:

- finite geometry;
- outer bounds contained by the safe area;
- frame/fill separation;
- no unresolved required overlap;
- clipping only in explicit scroll viewports;
- reachable scroll extent;
- hit regions inside visible owning regions;
- Plain Pixel allocations only at 15, 30, 45, or 60 pixels;
- stable outer bounds across content/page/selection changes.

Rendering tests verify that drawing consumes the measured result without a
second layout pass.

## Dropdown matrix

Tests cover:

- closed/open reducer transitions;
- below and above placement;
- safe-area clamping;
- short, grouped, disabled, and overflowing options;
- controlled-value reconciliation;
- controller and keyboard navigation;
- wheel and touch-drag scrolling;
- pointer activation and outside dismissal;
- cancel without mutation;
- focus trap and trigger restoration;
- parent envelope stability.

## V3 registry tests

Contract tests include:

- valid registration and idempotent replacement;
- invalid replacement leaving the previous registration untouched;
- stable contribution ordering;
- game filtering;
- unknown action and target references;
- malformed IDs and semantic versions;
- functions/cycles/metatables/userdata in data snapshots;
- idempotent unregister;
- owner reload/removal cleanup;
- callback error isolation.

No loader-level compatibility aliases are loaded by the contract suite.
Product-scoped Modern UI v1/v2 facades are covered by the owning product's
compatibility suite.

## Surface tests

The graphics spy mutates and verifies restoration of:

- canvas and active slice;
- transform stack;
- shader;
- color;
- blend and alpha mode;
- scissor;
- font;
- line width/style/join;
- point size;
- color mask and stencil state.

Success and exception paths run both against the spy and a real private LÖVE
canvas. Faulting one owner disables only that surface.

## Gallery safety tests

Fixture browsing installs spies that fail on:

- live-screen construction;
- source callbacks;
- audio;
- save or option writes;
- source navigation;
- native suppression.

Gameplay and Gallery models must enter the same production presenter entry
point. There is no Gallery-only presenter exception.

## Pin and Mod Menus tests

- per-save persistence through `mod.save`;
- no legacy import;
- dormant pins survive missing/disabled owners;
- deterministic catalog order;
- unlimited pins with scrolling;
- stable-ID legacy discovery;
- duplicate label-only entries remain accessible but unpinnable;
- pin icon pointer/touch operation;
- Select toggling;
- callback failure leaves Start and Mod Menus alive.

## Provider contract tests

Every host-declared screen ID has one `supported`, `native`, or `deferred`
inventory record. A new development ID fails coverage while runtime behavior
remains native.

Supported records are tested with:

- valid state;
- incomplete and malformed fields;
- unknown mode/phase;
- custom draw override;
- capture mode;
- exception-producing validator/extractor/presenter;
- complete parent/modal stack;
- unsupported parent with otherwise supported child;
- drift between preparation and suppression.

The decisive assertion is that no failed candidate leaves native UI hidden.

## Stable-envelope tests

Canonical geometry snapshots compare outer bounds while cycling:

- Summary pages and Pokémon;
- Pokédex views and records;
- Pack pockets;
- Trainer Card pages;
- Pokegear cards;
- PC modes and embedded prompts;
- selected rows and content levels;
- dropdown open/closed state.

Inner nodes may reflow or scroll. The outer rectangle and resolved font step
remain stable for the live session.

## Product smoke tests

Gen2 real routes cover Main, dialogue/ChoiceBox, Start, Options, Pack, Party,
three Summary purposes, held-item and move-order flows, Pokédex, Trainer Card,
Save, Naming, PC family, Pokegear, shops, mail, and specialty services as their
milestones land. Gen2 additionally runs `gen2check --strict --notes`.

Gen1 real routes cover Main, dialogue/ChoiceBox/PicBox/Naming, Start, Options,
Party, Summary, moves, Pokédex/Dex Entry, Map, Bag, shops, Trainer Card,
Save/Load Report, PC/Boxes/Item PC, Manager, and all supported 2D battle phases.
3D/voxel battle stacks remain native.

## Archive and vendoring tests

- deterministic core export path order and LF text;
- lock JSON schema, sorted paths, 40-hex commit, and exact SHA-256 values;
- no missing, extra, stale, or modified vendored files;
- deterministic example and product ZIP bytes;
- exactly one mod directory at ZIP root;
- manifest ID equals the root directory;
- manifest entry exists;
- no `dist`, `.git`, transient, or hidden editor files in archives;
- official-host load test.

## Requirement traceability

Tests declare stable requirement IDs, including:

- `LAYOUT-STABLE-001`
- `FONT-WHOLE-001`
- `DROPDOWN-FOCUS-001`
- `V3-ATOMIC-001`
- `SURFACE-RESTORE-001`
- `NATIVE-FAILOPEN-001`
- `GALLERY-NOMUTATE-001`
- `PINS-DORMANT-001`
- `V3-EDITOR-FIXTURE-001`

CI rejects a required ID with no covering test.

## Slice validation before source exists

The documentation/examples/tooling slice can be checked independently:

```powershell
.\scripts\verify_source_tree.ps1 -DocumentationOnly
```

This validates required documents, all seven example manifests/entry modules,
wrapper presence, forbidden archive contents, JSON parsing, duplicate IDs, and
tooling syntax without requiring `src/` or `tests/` to exist yet.
