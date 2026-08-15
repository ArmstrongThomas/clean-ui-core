# Clean UI Core — Implementation Architecture

Status: implementation-ready architecture for the approved Clean UI ground-up rebuild  
Target repository: `G:\dev\misc\clean-ui-core`  
Products: `gen1-clean-ui` and `gen2-clean-ui`  
License: MIT  
Runtime: the LÖVE/Lua runtime exposed by the official Gen 1 Recomp host

## 1. Architectural goals

`clean-ui-core` is a source dependency, test suite, and example collection. It is not an installable mod. Each product vendors a pinned, verified copy of the core and supplies a generation-specific provider.

The architecture must make these properties mechanically testable:

1. Layout is deterministic for the same model, viewport, safe area, settings, and theme.
2. A screen keeps one outer envelope for its entire open lifetime.
3. Plain Pixel is created only at 15, 30, 45, or 60 physical pixels.
4. Rendering consumes one measured layout result; drawing never performs a second independent layout pass.
5. Dropdowns are controlled, modal overlays that cannot resize their parent.
6. V3 registration is atomic, idempotent, deterministic, and product-scoped
   Modern UI compatibility never creates a loader-level product alias.
7. External surface callbacks cannot leak graphics state or break unrelated UI.
8. Unsupported, invalid, or failed presentation always fails open to native UI.
9. Gallery fixtures use production presenters but never construct live game screens or mutate game state.
10. Product-specific code owns screen detection, model extraction, source action mapping, sprite/palette resolution, pointer mapping, and suppression.

## 2. Hard boundaries

### Core owns

- Geometry primitives, safe-area calculations, preset envelopes, layout solving, and layout-result validation.
- Themes, tokens, the standard frame, density, font selection, text measurement, wrapping, and clipping.
- Generic components, including dropdown, list, button, card, modal overlay, tab strip, scroll viewport, and status card.
- Focus, pointer/touch routing, controller intents, overlay stacking, and scroll behavior.
- Clean UI API V3 validation and registries.
- Protected custom-surface execution and composition.
- Shared settings models, Mod Menus, pin records, Gallery, diagnostics, and test utilities.
- The fail-open replacement lifecycle as a state machine.

### Generation product owns

- The running-game identity (`gen1` or `gen2`).
- Exact source screen IDs and contract inventory.
- Validation of source screen shapes.
- Read-only model extraction from live source state.
- Source-owned action dispatch and pointer-to-source mapping.
- Pokémon sprite and palette lookup.
- Proof that a complete visible stack can be replaced.
- Acquisition and release of narrowly scoped `screen.render_visible` suppression leases.
- Production presenters and generation-specific Gallery fixtures.

### Source game always owns

- Update order, input semantics, callbacks, navigation, audio, save mutation, and transitions.

The core must never clear a shared world/UI/scene canvas and must never infer a source screen from a suffix or similar class name.

## 3. Repository layout

```text
clean-ui-core/
├── .github/
│   └── workflows/
│       └── ci.yml
├── docs/
│   ├── CLEAN_UI_REWORK_PLAN.md
│   ├── ARCHITECTURE.md
│   ├── API_V3.md
│   ├── COMPONENTS.md
│   ├── GALLERY.md
│   ├── LAYOUT_CONTRACT.md
│   ├── PRODUCT_PROVIDER_CONTRACT.md
│   └── TESTING.md
├── examples/
│   ├── party-row-colors/
│   ├── extra-summary-page/
│   ├── dropdown-screen/
│   ├── start-action-pinning/
│   ├── details-fields-footer-lists/
│   ├── modal-overlay/
│   ├── animated-shader-grid/
│   └── ui-editor-fixture/
├── scripts/
│   ├── build_example.ps1
│   ├── build_example.cmd
│   ├── export_core.ps1
│   ├── invoke_tests.ps1
│   ├── invoke_tests.cmd
│   ├── make_lock.ps1
│   └── verify_source_tree.ps1
├── src/
│   └── clean_ui/
│       ├── bootstrap.lua
│       ├── module_manifest.lua
│       ├── version.lua
│       ├── core.lua
│       ├── foundation/
│       ├── geometry/
│       ├── design/
│       ├── text/
│       ├── layout/
│       ├── input/
│       ├── components/
│       ├── render/
│       ├── presentation/
│       ├── v3/
│       ├── surfaces/
│       ├── integration/
│       ├── gallery/
│       └── diagnostics/
├── tests/
│   ├── conf.lua
│   ├── main.lua
│   ├── support/
│   ├── unit/
│   ├── integration/
│   ├── contracts/
│   ├── visual/
│   └── fixtures/
├── .editorconfig
├── .gitattributes
├── .gitignore
├── LICENSE
├── README.md
└── THIRD_PARTY_NOTICES.md
```

`docs/CLEAN_UI_REWORK_PLAN.md` must be present in the first repository commit. This architecture should become `docs/ARCHITECTURE.md` in the subsequent implementation commit.

## 4. Module format and deterministic loading

The host supports `mod:read(relative)` but a product ZIP must not depend on
process-global `package.path`. Core modules therefore use an injected loader.
This is also a sandbox boundary: packaged modules are read as text and compiled
with the sandbox-provided `load`/`loadstring`; raw filesystem loaders are never
used. See [SANDBOX_COMPATIBILITY.md](SANDBOX_COMPATIBILITY.md) for the complete
release contract.

Every ordinary module follows this form:

```lua
local requireCore = ...
local Rect = requireCore("geometry.rect")

local M = {}
-- implementation
return M
```

`bootstrap.lua` is the only special module. It returns a bootstrap function and implements `requireCore` with these rules:

- Module names must match `^[a-z0-9_]+(%.[a-z0-9_]+)*$`.
- Names map to `<root>/<name with dots replaced by slashes>.lua`.
- The allowed module list comes from `module_manifest.lua`; arbitrary file reads are rejected.
- Source is read with an injected `read(relative)` function. Products pass `mod:read`; tests pass a filesystem fixture.
- A module is inserted into the cache with a private `LOADING` sentinel before execution. A cycle produces `core_dependency_cycle`, not partial state.
- Sandboxed `loadstring`/`load` errors and module execution errors return
  structured bootstrap errors containing the module name. Loaded chunks inherit
  the product mod's private `_G`; they do not acquire engine globals.
- A module must return a non-`nil` value. The cache is immutable after successful load.
- The manifest lists dependencies for each module. CI compares declared dependencies with `requireCore(...)` calls and rejects undeclared edges or layer violations.

Product entry-point shape:

```lua
return function(mod)
  local source, readError = mod:read("vendor/clean_ui_core/bootstrap.lua")
  assert(source, readError)
  local compile = loadstring or load
  local chunk, loadError = compile(source, "@clean_ui/bootstrap.lua")
  assert(chunk, loadError)
  local bootstrap = chunk()
  local runtime = assert(bootstrap({
    root = "vendor/clean_ui_core",
    read = function(path) return mod:read(path) end,
    mod = mod,
    provider = PRODUCT_PROVIDER,
  }))
  runtime:install()
end
```

Tests use the exact same bootstrap path. There is no second test-only module system.

Runtime state is persisted only through scoped host APIs. Product settings use
`mod.options:set`; per-playthrough data uses `mod.storage` or the product's
documented `mod.save` contract. Cross-mod state is published through
`mod.exports` and discovered with `mod.find`, never through `_G`.

## 5. Dependency layers

Dependencies may point only left-to-right in this sequence:

```text
foundation
  → geometry + design
  → text
  → layout
  → input + components
  → render
  → v3 + surfaces + integration
  → gallery + diagnostics
  → presentation
  → core
```

`presentation` may coordinate lower layers but lower layers never import product providers or presentation sessions. `v3`, `surfaces`, and `integration` may share foundation modules but must not import one another through cycles; orchestration belongs in `core.lua`.

## 6. File-level module map

### 6.1 Root runtime

| File | Responsibility | Principal API |
|---|---|---|
| `bootstrap.lua` | Vendored module loader and startup error normalization. | `bootstrap(config) -> runtime | nil,error` |
| `module_manifest.lua` | Canonical sorted module list, dependency edges, and public/private markers. | data table only |
| `version.lua` | Core semantic version and V3 revision. | `{ coreVersion, apiVersion = 3 }` |
| `core.lua` | Composition root. Builds services, exports V3, installs hooks, and tears down safely. | `Core.new(config)`, `install`, `uninstall`, `update`, `draw` |

`core.lua` receives all mutable host dependencies explicitly. Modules must not reach into global game singletons.

### 6.2 Foundation

| File | Responsibility |
|---|---|
| `foundation/result.lua` | Structured `ok(value)` / `err(code,message,details)` results. Expected failures do not throw. |
| `foundation/assert.lua` | Internal invariant assertions with stable error codes. |
| `foundation/guard.lua` | `xpcall` wrapper, traceback normalization, error-rate limiting. |
| `foundation/copy.lua` | Cycle-aware deep copy for data-only values. |
| `foundation/data.lua` | Recursively rejects functions, userdata, threads, cycles, and metatables in snapshots. |
| `foundation/equal.lua` | Deterministic deep equality used by controlled components and tests. |
| `foundation/order.lua` | Stable key and record ordering; never relies on `pairs` order. |
| `foundation/id.lua` | Validates owner, contract, component, fixture, and action IDs. |
| `foundation/semver.lua` | Minimal comparison for capability minimum versions. |
| `foundation/cache.lua` | Bounded revision-keyed caches with explicit invalidation. |
| `foundation/log.lua` | Core logger facade over `mod.log`; deduplicates repeated failures. |
| `foundation/clock.lua` | Injected monotonic clock; no direct timer access in deterministic tests. |

Stable ordering keys are always explicit. Contract contributions sort by `(priority, ownerId, contractId, contributionId)`.

### 6.3 Geometry

| File | Responsibility |
|---|---|
| `geometry/rect.lua` | Normalize, inset, intersect, union, contains, clamp, snap, and finite-number checks. |
| `geometry/insets.lua` | Safe-area and frame inset types. |
| `geometry/anchor.lua` | Edge, center, and corner anchoring. |
| `geometry/placement.lua` | Above/below and left/right overlay placement with viewport clamping. |
| `geometry/hit_region.lua` | Visible and expanded touch hit geometry. |
| `geometry/transform.lua` | Logical-to-physical mapping for custom surfaces; core widgets render in physical coordinates. |

All final core-widget coordinates are integer physical pixels. Half-pixel line placement, where needed by LÖVE, is isolated in the painter.

### 6.4 Design system

| File | Responsibility |
|---|---|
| `design/tokens.lua` | Spacing, radii/cut sizes, line widths, opacity, minimum targets, and semantic colors. |
| `design/themes.lua` | Built-in Clean, Dark, and High Contrast themes plus validated registered themes. |
| `design/contrast.lua` | WCAG relative luminance and 4.5:1 validation for essential text/control pairs. |
| `design/frames.lua` | Default two-logical-pixel cut-corner frame and validated custom-frame registry. |
| `design/density.lua` | Auto, Comfortable, and Compact token resolution. |
| `design/presets.lua` | Immutable preset dimensions and bounded adaptive NAV/M widths. |

`design/presets.lua` contains exactly:

```lua
return {
  XS = { w = 320, h = 200 },
  S = { w = 400, h = 300 },
  NAV = { w = 440, minW = 320, h = 560, widthMode = "content" },
  M = { w = 600, minW = 320, h = 420, widthMode = "content" },
  L = { w = 760, h = 540 },
  XL = { w = 960, h = 640 },
  BATTLE_WIDE = { w = 640, h = 360 },
}
```

Preset tables are copied/frozen at the service boundary. Registered themes may reference only an existing registered frame ID.

### 6.5 Text and font policy

| File | Responsibility |
|---|---|
| `text/font_catalog.lua` | Lazily creates Plain Pixel and System fonts and caches by family/physical size. |
| `text/font_policy.lua` | Resolves AUTO/manual whole raster steps and System equivalents. |
| `text/glyphs.lua` | Detects missing glyphs and splits fallback runs. |
| `text/measure.lua` | Single source of width, height, baseline, and line-height measurements. |
| `text/wrap.lua` | Deterministic word/grapheme-aware wrapping and explicit newline policy. |
| `text/truncate.lua` | Ellipsis only where a contract marks text optional/truncatable. |
| `text/runs.lua` | Produces measured font runs, including System fallback glyphs. |

Plain Pixel font creation is centralized and guarded:

```lua
local PLAIN_PIXEL_BASE = 15
local VALID_STEPS = { 1, 2, 3, 4 }
font = love.graphics.newFont(path, PLAIN_PIXEL_BASE * step)
```

No other module may create a Plain Pixel font. `font_policy.lua` returns `{ family, step, physicalPx }`; a test spies on every `newFont` call and rejects any Plain Pixel size outside `{15,30,45,60}`.

AUTO selection tests candidate steps from 4 down to 1 and accepts the first that satisfies both:

- the configured physical-size target for the viewport; and
- a complete layout with no unresolved required overflow.

A manual request is a maximum, not a command to clip: candidates run from the requested step downward. The chosen step is stored in the screen session and remains stable until reopen, viewport/safe-area/orientation change, or a relevant settings/theme revision.

### 6.6 Layout engine

| File | Responsibility |
|---|---|
| `layout/request.lua` | Normalizes preset, viewport, safe area, theme, density, font, and content constraints. |
| `layout/envelope.lua` | Selects and centers a fixed preset envelope inside the safe viewport. |
| `layout/scale.lua` | Resolves UI size and fit cap, including 4K/5K growth. |
| `layout/session.lua` | Locks envelope, physical outer bounds, density, and font step for one open screen lifetime. |
| `layout/regions.lua` | Measures frame, header, body, footer, sidebar, overlay host, and content insets. |
| `layout/flow.lua` | Vertical/horizontal flow, gap, alignment, wrapping. |
| `layout/grid.lua` | Fixed and responsive columns with deterministic reflow. |
| `layout/list.lua` | Row metrics, visible range, scroll bounds, selection reveal. |
| `layout/details.lua` | Sprite reserve, `custom_fields`, column fit, and bottom-anchored `footer_lists`. |
| `layout/overflow.lua` | Applies the required overflow policy in a fixed order. |
| `layout/result.lua` | Constructs and validates the immutable measured output. |
| `layout/solver.lua` | Runs candidate scale/font/density arrangements and selects a complete result. |

#### Scale model

Core widgets are laid out directly in physical pixels; no final fractional transform is applied to text. The solver computes:

```text
fitCap       = min(safeWidth / presetWidth, safeHeight / presetHeight)
targetScale  = resolveUiSize(setting, safeWidth, safeHeight)
panelScale   = min(fitCap, targetScale)
outerWidth   = floor(presetWidth  * panelScale)
outerHeight  = floor(presetHeight * panelScale)
```

AUTO `targetScale` is a monotonic function of the safe viewport’s short edge, calibrated so 4K and 5K grow beyond 1080p while small screens remain bounded. Its constants live in `design/tokens.lua`, not presenter code. Small/Medium/Large apply documented multipliers to the same baseline. All results clamp to the safe viewport.

The panel scale may be continuous. Plain Pixel itself remains an unscaled font object at a whole authored step, and all glyph origins are snapped to integer physical pixels.

#### Overflow order

For every solver candidate:

1. Reflow declared responsive columns.
2. Wrap wrappable text.
3. Assign scroll viewports to declared scrollable regions.
4. Tighten optional spacing and optional chrome.
5. Try the next lower whole Plain Pixel step, or the next lower measured System size.
6. Reject the candidate if required content still overlaps or clips.

Clipping is valid only inside an explicit scroll viewport or for content explicitly marked decorative/optional. A complete result has `overflow.unresolvedRequired == 0`.

#### Stable session contract

`layout/session.lua` keys sessions by a product-provided screen instance token, not by screen ID alone. These changes do not rebuild outer bounds:

- current Pokémon/record;
- page/tab/pocket/mode;
- selection and scroll;
- embedded submenu or prompt;
- item count or text content.

Only reopen, viewport/safe-area/orientation change, or settings/theme revision creates a new session. Dynamic content uses the locked body regions and scroll policy. A product may declare a worst-case capacity contract so the initial solver reserves enough space across known pages.

#### Layout result

```lua
{
  revision = 17,
  preset = "L",
  viewport = { x=0, y=0, w=1920, h=1080 },
  safeArea = { ... },
  outer = { ... },
  frameInset = { left=..., top=..., right=..., bottom=... },
  regions = { header=..., body=..., footer=..., overlayHost=... },
  scale = 1.5,
  font = { family="plain_pixel", step=2, physicalPx=30 },
  density = "comfortable",
  nodes = { [componentId] = measuredNode },
  clipRects = { ... },
  scrollRanges = { ... },
  hitRegions = { ... },
  overflow = { resolved={...}, unresolvedRequired={} },
  diagnostics = { decisions={...}, warnings={} },
}
```

The result is treated as immutable. Render and pointer routing consume it without remeasurement.

### 6.7 Input and focus

| File | Responsibility |
|---|---|
| `input/intents.lua` | Maps host buttons, keyboard, pointer, wheel, and touch into semantic intents. |
| `input/focus.lua` | Focus scopes, restoration, directional movement, and disabled-node skipping. |
| `input/overlay_stack.lua` | Topmost modal/dropdown ownership and focus trapping. |
| `input/pointer.lua` | Hit testing against measured regions; pointer capture for drag. |
| `input/scroll.lua` | Wheel, buttons, repeat, touch drag, clamping, and reveal-selection. |
| `input/repeat.lua` | Deterministic key-repeat timing with injected clock. |

Semantic intents include `activate`, `cancel`, `select`, `start`, `move_up`, `move_down`, `move_left`, `move_right`, `scroll`, `pointer_down`, `pointer_move`, and `pointer_up`.

### 6.8 Components

| File | Responsibility |
|---|---|
| `components/host.lua` | Reconciles controlled descriptors with ephemeral component state. |
| `components/schema.lua` | Shared descriptor validation and named-action references. |
| `components/label.lua` | Static measured text. |
| `components/button.lua` | Activatable row/control. |
| `components/list.lua` | Selection, scroll, row decorators, icons, and empty state. |
| `components/card.lua` | Framed/raised content region. |
| `components/tabs.lua` | Stable page strip without changing parent envelope. |
| `components/modal.lua` | Modal overlay, dim layer, options, focus scope. |
| `components/dropdown.lua` | Public controlled single-select component. |
| `components/dropdown_state.lua` | Pure dropdown reducer/state machine. |
| `components/dropdown_layout.lua` | Placement, row viewport, scrolling, and hit regions. |
| `components/details.lua` | Sprite, fields, custom columns, and footer lists. |
| `components/status_card.lua` | Native/deferred Gallery and diagnostics status display. |

#### Dropdown state model

```lua
{
  phase = "closed", -- closed | open | dragging
  componentId = nil,
  triggerId = nil,
  activeOptionId = nil,
  committedValue = nil,
  scrollOffset = 0,
  pointerId = nil,
  dragOriginY = nil,
  dragOriginScroll = nil,
  placement = nil,
}
```

The descriptor remains controlled: `descriptor.value` is authoritative. Opening copies it into `committedValue` and focuses its selectable option, or the first enabled option. Navigation changes only `activeOptionId`. Confirm emits one action payload:

```lua
{
  componentId = "sort",
  value = "dex",
  optionId = "dex",
}
```

The source action owns mutation. Cancel and outside click emit no change action.

#### Dropdown transition table

| State | Intent | Result |
|---|---|---|
| closed | activate/click trigger | Open, measure placement, trap focus, focus current or first enabled choice. |
| open | up/down | Move to previous/next selectable option, skipping headings and disabled rows; reveal it. |
| open | wheel | Scroll within clamped range; keep focus in overlay. |
| open | activate/click enabled option | Emit named action once, close, restore trigger focus. |
| open | activate…904 tokens truncated…leases leases immediately.
10. The last-good private canvas may be composited during the restoration frame, preventing a blank flash while native visibility returns.

Core never writes `render_visible` directly; only the product’s suppression implementation can do so.

### 6.11 API V3

| File | Responsibility |
|---|---|
| `core.lua` | Capability names and runtime composition. |
| `v3/panel.lua` | Strict panel/component descriptor validation shared by registration and previews. |
| `v3/contract.lua` | V3 contract validation and editor-safe descriptors. |
| `v3/registry.lua` | Atomic owner/contract storage and deterministic indexes. |
| `shell/runtime.lua` | V3 named-action, dropdown, modal, and close dispatch. |
| `shell/content.lua` | Generic shell models, including V3 panel previews. |
| `integration/start_menu.lua` | Deterministic start-menu composition and V3 extension contributions. |
| `gallery/catalog.lua` | Data-only Gallery fixtures. |
| `v3/host.lua` | Public `cleanUiHost` facade. |

Public facade:

```lua
{
  apiVersion = 3,
  coreVersion = "...",
  productId = "gen2_clean_ui",
  game = "gen2",
  capabilities = { ... },
  supports = function(capability, minimumVersion) ... end,
  register = function(ownerId, contract) ... end,
  unregister = function(ownerId, contractId) ... end,
  openGallery = function(filter) ... end,
}
```

#### Registry rules

- Key: `ownerId .. "\0" .. contract.id`.
- The whole contract is validated into a staging record before registry mutation.
- Registering the same key replaces it atomically and increments one registry revision.
- A failed replacement leaves the previous registration untouched.
- `games` must include the running product game.
- IDs, action references, option IDs, extension targets, screen validators, surface mode, and Gallery fixtures are validated before commit.
- Data snapshots and descriptor data reject functions; functions are permitted only in documented callback slots such as actions, exact validators, and custom-surface `update`/`draw`.
- Contributions are indexed in deterministic order `(priority, ownerId, contractId, contributionId)`.
- `unregister` is idempotent and closes any overlay/surface owned by the removed registration.
- Owner disappearance on `mods.loaded`/reload removes active runtime state but may be re-registered without stale references.
- Registration errors return `nil, code, message`; ordinary bad input does not throw.

Required initial capabilities include `data_screens`, `additive_extensions`, `dropdown`, `modal_overlay`, `custom_fields`, `footer_lists`, `custom_surface`, `isolated_shader`, `themes`, `frames`, `gallery`, and `start_menu_pinning`.

### 6.12 Protected custom surfaces

| File | Responsibility |
|---|---|
| `surfaces/schema.lua` | Validates exact match, mode, logical bounds, callbacks, and data source. |
| `surfaces/context.lua` | Read-only frame context: time, dt, bounds, scale, safe area, palette helpers, pointer registration. |
| `surfaces/graphics_state.lua` | Captures/restores all required LÖVE graphics state. |
| `surfaces/transaction.lua` | Runs callbacks on a private canvas under protected state. |
| `surfaces/runtime.lua` | Per-owner surface lifecycle, update/draw isolation, and fault disabling. |
| `surfaces/palette.lua` | Scoped palette, silhouette, and true-color helper construction. |
| `surfaces/pointers.lua` | Surface-local pointer regions transformed to physical space. |

`graphics_state.lua` captures at least:

- canvas and active canvas slice;
- transform;
- shader;
- color;
- blend mode and alpha mode;
- scissor;
- font;
- line width/style/join;
- point size;
- color mask and stencil mode where available.

Transaction outline:

```lua
local before = GraphicsState.capture(love.graphics)
local canvas = pool:acquire(width, height)
local ok, valueOrError = xpcall(function()
  love.graphics.push("all")
  love.graphics.setCanvas(canvas)
  love.graphics.clear(0, 0, 0, 0)
  love.graphics.origin()
  return callback(ctx, snapshot)
end, traceback)

pcall(love.graphics.pop)
GraphicsState.restore(love.graphics, before)
```

Explicit restoration always runs even if the callback corrupts the push/pop stack. Tests use a spy graphics object that mutates every tracked property, throws midway, and verifies exact restoration.

Overlay is the default mode. Replace mode is accepted only when the registration specifies an exact screen ID and validator and the product provider supplies a complete-stack suppression proof. Core cannot manufacture that proof.

### 6.13 Settings, Mod Menus, and pins

| File | Responsibility |
|---|---|
| `integration/settings_schema.lua` | Minimal main and Compatibility settings schemas. |
| `integration/settings.lua` | Reads controlled values and writes only through public `mod.options:set`. |
| `integration/catalog.lua` | Deterministic catalog of Clean UI and third-party menu actions. |
| `integration/legacy_entries.lua` | Adapts discoverable hook-added entries with stable-ID/label rules. |
| `integration/pins.lua` | Per-save pin records keyed by `owner_id + entry_id`. |
| `integration/start_menu.lua` | Inserts pinned block and `MOD MENUS` at the required stock anchors. |
| `integration/mod_menus.lua` | NAV-envelope complete catalog and callback isolation. |

Core never calls a private manager writer. Reset Defaults iterates the registered schema and calls `mod.options:set(row.key, row.default)` for each setting, collecting any structured errors.

Pin records contain only stable data:

```lua
{
  version = 1,
  keys = {
    ["owner_id\0entry_id"] = true,
  },
}
```

Pins never serialize callbacks. Dormant keys remain stored. Catalog order determines pin order. Duplicate label-only legacy entries are listed but receive `pinnable=false` and the explanatory status `stable ID required`.

### 6.14 Gallery

| File | Responsibility |
|---|---|
| `gallery/catalog.lua` | Merges product records, shared fixtures, and V3 fixtures for the running game. |
| `gallery/fixtures.lua` | Validates/copies data-only fixture descriptors. |
| `gallery/content_levels.lua` | EMPTY, MINIMAL, NORMAL, FULL, and OVERFLOW deterministic variants. |
| `gallery/controller.lua` | Index/preview navigation and temporary QA settings. |
| `gallery/model.lua` | Builds Gallery UI models. |
| `gallery/preview.lua` | Invokes the same production presenter/layout path as gameplay. |
| `gallery/status.lua` | Native/deferred exact-ID cards with reason and milestone. |

Gallery fixture IDs are stable and generation-qualified, such as `gen2.party.actions` and `gen1.battle.moves`.

Index mode:

- Left/Right: family.
- Up/Down: fixture.
- A: preview.
- B: close.

Preview mode:

- Left/Right: fixture.
- Up/Down: content level.
- A: UI size.
- Select: font step.
- Start: System/Plain Pixel.
- B: index.

QA settings are held in Gallery controller memory and never written to `mod.options`. Fixture descriptors contain data only. Product fixture construction occurs at load time from literal/synthetic data builders that receive no game, mod-save, audio, callback, or source-screen references. Tests inject mutation/audio/callback spies and assert zero calls.

Dropdown fixtures must cover short, grouped, disabled, overflow, edge-flip, pointer, touch-drag, and controlled-value reconciliation variants. Pinning fixtures cover dormant pins, duplicate legacy labels, many pins, and callback failure.

### 6.15 Diagnostics

| File | Responsibility |
|---|---|
| `diagnostics/events.lua` | Ring buffer of layout, registry, surface, action, and fallback events. |
| `diagnostics/report.lua` | Structured snapshot suitable for logs and Gallery status cards. |
| `diagnostics/bounds.lua` | Envelope, safe-area, content, clip, scroll, pointer, and overflow rectangles. |
| `diagnostics/overlay.lua` | Developer bounds overlay with legend and layer toggles. |
| `diagnostics/contracts.lua` | Coverage report for product screen IDs and V3 contributions. |

Diagnostics must redact function values and avoid retaining live source-screen objects. Errors are deduplicated by `(code, owner, contract, screenId)` and rate-limited while preserving the first traceback.

## 7. Core runtime lifecycle

`Core.new(config)` validates the provider and constructs independent services. `install()` is idempotent and performs this order:

1. Define the product’s minimal option schema.
2. Load theme/font resources lazily.
3. Construct V3 registry and publish `mod.exports.cleanUiHost`.
4. Register product contracts and shared fixtures.
5. Restore per-save pins as stable keys only.
6. Install host events/hooks through one product adapter.
7. Leave every source screen native until a complete candidate succeeds.

Per-frame order:

```text
input intents
  → controlled component reconciliation
  → source action dispatch requests
  → surface updates
  → exact stack inventory
  → snapshot validation
  → locked-session layout
  → offscreen render/transaction
  → suppression proof/lease renewal
  → composition
  → optional diagnostics overlay
```

`uninstall()` releases all suppression leases, closes overlays, clears transient canvases, unregisters owned handlers where host tokens permit, and removes the exported host only if it still points to this runtime.

## 8. Test architecture

### 8.1 Test runner

`tests/main.lua` is a small LÖVE runner. It loads production modules through `bootstrap.lua`, discovers a statically listed suite from `tests/suite_manifest.lua`, and exits nonzero on failure. Test selection uses `CLEAN_UI_TEST_FILTER`; seed uses `CLEAN_UI_TEST_SEED` and is printed on every run.

Pure modules receive fake dependencies and do not require a graphics context. Graphics tests use either a spy object or real LÖVE canvases. The test runner must not duplicate production algorithms.

`scripts/invoke_tests.ps1` runs suites separately so failures are attributable:

```text
syntax → dependency graph → unit → integration → contracts → visual → matrix
```

### 8.2 Test support files

| File | Responsibility |
|---|---|
| `tests/support/assertions.lua` | Equality, rectangle containment, no-overlap, stable-bounds, structured-error assertions. |
| `tests/support/fake_mod.lua` | `mod:read`, assets, events, hooks, save, options including public `set`, log, and exports. |
| `tests/support/fake_provider.lua` | Exact screen records, source tokens, stack, action spy, and suppression leases. |
| `tests/support/fake_love.lua` | Minimal headless LÖVE objects. |
| `tests/support/graphics_spy.lua` | Full mutable graphics-state spy and call ledger. |
| `tests/support/font_spy.lua` | Deterministic font metrics and `newFont` size ledger. |
| `tests/support/mutation_spy.lua` | Fails on save/audio/callback/source-screen mutation. |
| `tests/support/generator.lua` | Seeded table/string/viewport generators for property tests. |
| `tests/support/layout_snapshot.lua` | Canonical sorted serialization of measured geometry. |

### 8.3 Required unit suites

- `geometry_rect_test.lua`: finite values, inset/clamp/intersection, edge inclusion.
- `preset_test.lua`: exact immutable dimensions and BATTLE_WIDE behavior.
- `scale_test.lua`: monotonic AUTO growth, fit caps, safe bounds, 4K/5K enlargement.
- `font_policy_test.lua`: every setting and fallback; Plain Pixel only 15/30/45/60.
- `wrap_test.lua`: long words, Unicode/fallback runs, explicit newlines, empty strings.
- `layout_solver_test.lua`: overflow order and rejection of unresolved required content.
- `layout_session_test.lua`: page/record/pocket/selection/modal changes preserve outer bounds and font step.
- `list_layout_test.lua`: no row overlap, selected row reveal, EMPTY through OVERFLOW.
- `details_layout_test.lua`: column reflow, footer bottom anchor, sprite-space reduction, shrink-to-fit.
- `dropdown_reducer_test.lua`: every transition in the table.
- `dropdown_layout_test.lua`: above/below choice, clamp, long-list scroll, edge placement.
- `focus_test.lua`: disabled skipping, modal trap, trigger restoration.
- `registry_test.lua`: atomic replacement, stable ordering, idempotent unregister, game filtering.
- `data_test.lua`: reject functions/cycles/metatables/userdata in snapshots.
- `pins_test.lua`: persistence, dormant records, duplicate labels, deterministic ordering, unlimited scroll.
- `graphics_state_test.lua`: success and exception restore every tracked property.

### 8.4 Required integration suites

- `bootstrap_test.lua`: source and vendored roots load identically; bad/cyclic modules fail structurally.
- `runtime_install_test.lua`: idempotent install/export/uninstall.
- `presentation_pipeline_test.lua`: prepare-before-suppress and last-good-frame behavior.
- `fail_open_test.lua`: unknown, malformed, custom-draw, capture mode, exception, and contract drift restore native immediately.
- `stack_test.lua`: parent + modal, CallerBox + dialogue, Oak child overlay, and battle + child-native fallback.
- `dropdown_input_test.lua`: controller, keyboard, pointer, wheel, touch drag, outside dismiss.
- `action_isolation_test.lua`: callback failure leaves Start/Mod Menus alive and logs once.
- `surface_transaction_test.lua`: update/draw failure isolation and graphics restoration on a real private canvas.
- `gallery_safety_test.lua`: fixture browsing produces no source callbacks, audio, saves, or live screens.
- `gallery_production_path_test.lua`: fixture and gameplay model hit the same presenter/layout/render entry point.
- `settings_test.lua`: all writes use `mod.options:set`; Reset Defaults never reaches private manager state.

### 8.5 Contract and matrix suites

`tests/contracts/provider_inventory_test.lua` is parameterized by a product inventory. It requires one exact record for every host-declared screen ID and allows only `supported`, `native`, or `deferred` statuses. New IDs fail development coverage while runtime remains native.

`tests/contracts/v3_contract_test.lua` exercises valid, incomplete, malformed, unknown-action, duplicate, cross-game, custom-surface, and exception-producing registrations.

`tests/contracts/stable_bounds_test.lua` cycles all declared records/pages/pockets/modes/selections and compares outer bounds from canonical layout snapshots.

The viewport matrix is literal test data:

```lua
{
  {320,180}, {640,360}, {360,640}, {390,844},
  {1024,768}, {1280,720}, {1280,1024}, {1600,1000},
  {1920,1080}, {2560,1440}, {3440,1440},
  {3840,2160}, {5120,2784},
}
```

For every production fixture, matrix tests combine:

- viewport and representative touch-safe insets;
- UI Size Auto/Small/Medium/Large;
- Plain Pixel Auto/1×/2×/3×/4× and System;
- Density Auto/Comfortable/Compact;
- Clean/Dark/High Contrast;
- NORMAL and OVERFLOW content, plus maximum combined settings.

Assertions include finite geometry, outer inside safe area, frame/fill separation, no required overlap, explicit clips only, reachable scroll extent, hit targets inside visible regions, whole-step fonts, and stable outer bounds.

The full Cartesian matrix can be sharded in CI by fixture hash. A deterministic smoke subset runs on every local invocation.

### 8.6 Visual tests

Geometry snapshots are the portable golden source. Real-render tests supplement them with:

- pixel probes around all frame interior edges;
- dropdown above/below placement captures;
- selection/header separation;
- High Contrast focus visibility;
- Plain Pixel nearest-neighbor integrity at each step;
- private-surface clipping and shader restoration.

PNG artifacts are emitted on failure but are not the sole pass/fail oracle across graphics drivers.

### 8.7 Test-to-requirement traceability

`tests/REQUIREMENTS.md` assigns each approved-plan requirement a stable ID, for example:

- `LAYOUT-STABLE-001`
- `FONT-WHOLE-001`
- `DROPDOWN-FOCUS-001`
- `V3-ATOMIC-001`
- `SURFACE-RESTORE-001`
- `NATIVE-FAILOPEN-001`
- `GALLERY-NOMUTATE-001`
- `PINS-DORMANT-001`

Every test declares one or more IDs. CI fails if a required ID has no test or if a removed test leaves an ID uncovered.

## 9. Deterministic vendoring contract

`scripts/export_core.ps1` exports only the sorted paths listed in `module_manifest.lua` plus required license/notice files. It normalizes text files to LF and rejects generated timestamps.

Each product receives:

```text
mods/<product>/vendor/clean_ui_core/...
clean-ui-core.lock.json
```

The lock records:

```json
{
  "schema": 1,
  "coreTag": "v0.1.0",
  "coreCommit": "<40-hex commit>",
  "files": [
    { "path": "bootstrap.lua", "sha256": "..." }
  ]
}
```

Files sort by normalized forward-slash path. SHA-256 is over exact exported bytes. Product CI regenerates the snapshot from either a local sibling checkout or a tagged archive and fails on any missing, extra, modified, or stale file.

## 10. Implementation sequence

### Milestone 0A — repository skeleton and invariants

1. Commit the approved plan as the first commit.
2. Add this architecture, MIT license, module loader, manifest, Result/Data/Order/Rect primitives, and test runner.
3. Add dependency-layer and deterministic-export checks.

Exit criterion: source and a copied vendor tree load identically; syntax and dependency checks pass.

### Milestone 0B — deterministic layout and fonts

1. Implement themes/tokens/presets/frame.
2. Implement font catalog/policy/measurement.
3. Implement request, scale, envelope, session, regions, flow/grid/list/details, overflow, and solver.
4. Run the entire viewport/settings matrix on synthetic component trees.

Exit criterion: no unresolved required overflow in supported matrix fixtures; all Plain Pixel allocations are whole-step; stable-session tests pass.

### Milestone 0C — dropdown and interaction foundation

1. Implement intents, focus, overlay stack, pointer, scroll, and repeat.
2. Implement component host and dropdown reducer/layout/rendering.
3. Add all dropdown Gallery fixtures and input tests.

Exit criterion: every dropdown transition and input modality passes, including edge flip and overflow.

### Milestone 0D — V3, surfaces, and integration

1. Implement atomic V3 registry, actions, extensions, themes/frames, and public host.
2. Implement canvas pool, graphics-state transaction, surface runtime, palettes, and pointers.
3. Implement settings, Mod Menus, legacy entry discovery, and per-save pins.
4. Add the seven source examples and local ZIP builders.

Exit criterion: V3 contract suite, graphics restoration, callback isolation, settings writer, and pin suites pass.

### Milestone 0E — Gallery, diagnostics, and presentation safety

1. Implement Gallery catalog/controller/preview/status.
2. Implement bounds diagnostics and contract reports.
3. Implement provider contract, presentation sessions, complete-stack proof, and suppression leases.

Exit criterion: fail-open tests prove no invalid/failed screen remains hidden, and Gallery safety proves zero game mutation.

Only after all Milestone 0 exits pass should `gen2-clean-ui` begin production screen presenters.

## 11. Review gates

A core release candidate is rejected if any of these are true:

- A module imports across a forbidden dependency layer.
- A layout path measures text during drawing.
- A Plain Pixel font is created at a non-multiple of 15 or outside 1×–4×.
- A page/content change alters a live session’s outer bounds.
- A dropdown changes a parent layout, loses focus outside the top overlay, or mutates on cancel.
- A failed V3 replacement partially changes registry indexes.
- A surface exception leaves any tracked graphics state changed.
- A Gallery fixture invokes a source callback, audio, save write, or live-screen constructor.
- Core directly suppresses a source screen or clears a shared canvas.
- Reset Defaults uses anything except public `mod.options:set`.
- A supported presentation can hide native UI before a complete offscreen replacement and suppression proof exist.

This architecture intentionally keeps generation knowledge out of core while making the safety, layout, interaction, extension, and QA mechanisms reusable and independently testable.
