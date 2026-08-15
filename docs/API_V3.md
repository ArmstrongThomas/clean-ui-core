# Clean UI API V3

Status: normative design contract for Clean UI products. API version: `3`.

Clean UI API V3 is the only extension API shipped by `gen1_clean_ui` and
`gen2_clean_ui`. The core repository is vendored source, not a separately
installed runtime mod. A source mod registers with whichever product exists in
the running game.

## Design rules

- Registration is atomic, idempotent, deterministic, and scoped by owner.
- Models and component descriptors are data. Ordinary behavior is referenced
  through named actions.
- The source game or source mod retains update, navigation, audio, mutation,
  callback, and transition ownership.
- Clean UI presents state; it does not simulate source UI behavior.
- Invalid integrations fail without hiding native UI.
- Product-specific screen knowledge never belongs in `clean-ui-core`.

## Discovering the host

List both products as optional dependencies so the running game's product is
ordered before your mod when present:

```json
{
  "optional_dependencies": [
    "gen1_clean_ui@>=0.1.0 <2.0.0",
    "gen2_clean_ui@>=0.1.0 <2.0.0"
  ]
}
```

Attempt registration immediately and again after `mods.loaded`. `mod:find`
returns a public handle, never the other mod object.

```lua
local function findCleanUi(mod)
  for _, productId in ipairs({ "gen1_clean_ui", "gen2_clean_ui" }) do
    local dependency = mod:find(productId)
    local host = dependency and dependency.exports
      and dependency.exports.cleanUiHost
    if type(host) == "table" and host.apiVersion == 3 then
      return host
    end
  end
end
```

Do not read product-private files, inspect private manager state, or assume
that both products are installed.

## Public host

Each product exports:

```lua
mod.exports.cleanUiHost = {
  apiVersion = 3,
  coreVersion = "0.1.0-alpha.12",
  productId = "gen2_clean_ui", -- or gen1_clean_ui
  game = "gen2",               -- or gen1
  capabilities = {
    data_screens = "0.1.0",
    additive_extensions = "0.1.0",
    dropdown = "0.1.0",
    modal_overlay = "0.1.0",
    custom_fields = "0.1.0",
    footer_lists = "0.1.0",
    custom_surface = "0.1.0",
    isolated_shader = "0.1.0",
    themes = "0.1.0",
    frames = "0.1.0",
    gallery = "0.1.0",
    contract_catalog = "0.1.0",
    presentation_models = "0.1.0",
    start_menu_pinning = "0.1.0",
  },

  supports = function(capability, minimumVersion) ... end,
  register = function(ownerId, contract) ... end,
  unregister = function(ownerId, contractId) ... end,
  openGallery = function(filter) ... end,
}
```

`supports` returns a boolean. `register` and `unregister` return `true` on
success or `nil, code, message` for expected failures. They do not throw for a
bad third-party contract. `openGallery(filter)` returns `true`, or the same
structured error tuple when Gallery cannot be opened.

### Editor contract catalog

Standalone tools may feature-detect `contract_catalog` and call
`host.listContracts(filter)` to inspect the V3 registrations available in the
running product. The returned descriptors are deterministic, copied data: they
include declarative screens, extensions, surfaces, themes, frames, Gallery
metadata, and sorted `actionIds`, but never return action, draw, update, or
validator functions. The optional filter supports `ownerId` and contract `id`.

```lua
local host = dependency.exports.cleanUiHost
if host:supports("contract_catalog", "0.1.0") then
  local contracts = host:listContracts({ ownerId = "my_ui_editor_fixture" })
  -- Render or edit the returned data without executing source callbacks.
end
```

This catalog is an inspection bridge for editor and diagnostics tooling; it
does not grant ownership of a source screen or allow a tool to invoke an
action. Actions still execute only through the registered contract and the
source-owned dispatcher.

### Direct presentation-model screens

The shell also accepts a direct V3 presentation model as a screen descriptor
for editor previews and source-owned action results. The supported model kinds
are `menu`, `dialogue`, `choice`, `battle`, `animation`, `device`, and `map`;
each uses the same
data-only model vocabulary as the product presentation runtime. For example:

```lua
{
  id = "dialogue_preview",
  kind = "dialogue",
  schema = "clean_ui.v3.presentation.v1",
  apiVersion = 3,
  preset = "XS",
  anchor = "bottom",
  lines = { "A complete message can reflow across the available surface." },
  inputReady = true,
  more = true,
  controls = "A/B CONTINUE",
}
```

This does not replace source-owned timing or input. The product remains
responsible for extracting live state and dispatching actions; V3 gives that
runtime and the standalone editor one stable, inspectable model shape.

`device` models require a data-only `device` descriptor with a non-empty
`kind`, optional `family`/`title`, and a `portrait` or `landscape` orientation
when one is known. Optional `apps`, `activeApp`, `statusBar`, `launcher`, and
`navigation` fields describe a responsive handheld shell without embedding a
renderer or callback. `map` models require a data-only `map` descriptor with
a non-empty `region` and dense marker rows. Optional `current`, `player`, and
`flyRows` fields preserve source selection state. A native-art tilemap graphic
may include a positive `width`/`height`, a source sheet, dense tile arrays, a
cursor sheet, and palette metadata; missing art remains a valid fail-open
state rather than a reason to invent a placeholder graphic.

### Naming keyboard presentation

A menu presentation may carry an optional `naming` descriptor when the source
screen owns a naming cursor but the product supplies the visual keyboard. The
descriptor is data-only and keeps the source's zero-based cursor and action
semantics intact:

```lua
{
  entry = { text = "TOT", sourceLength = 3, maxLength = 10 },
  case = "upper",
  keyboard = {
    columns = 9,
    rows = { { "A", "B", "C" } },
    bottom = { { label = "lower" }, { label = "DEL" }, { label = "END" } },
  },
  cursor = { row = 0, col = 0, bottomRow = false },
}
```

Core renders the entry slots and card grid, while the source remains
authoritative for movement, character insertion, case changes, deletion, and
completion. Products must leave unsupported naming contexts native and must
not invent submit or delete callbacks in the presentation model.

### V3 gap register

The device/map gap is closed for the declarative visual model: Core validates
and renders first-class `device` and `map` kinds, and products can publish
callback-free shell, marker, tilemap, and Fly data without Gen2-specific menu
extensions. Source-owned navigation and asset loading remain outside the
model, as they do for every direct V3 presentation.

The remaining roadmap gap is live animation timing and source identity. An
`animation` model describes
  one deterministic visual frame; it does not own a scheduler, source input,
  gameplay mutation, or the identity of a complete child stack. Intro/send-out,
  move/item, faint, experience, and other timing-heavy battle states therefore
  remain source-owned or fail-open until the host supplies those seams. A
  custom surface is not a substitute for missing source ownership evidence.

This is a roadmap gap, not an advertised capability. It must be implemented
in Core with validation, responsive layout/rendering, Gallery fixtures, and
editor parity before a product claims timing-heavy animation ownership as
fully portable V3. Until then, products should keep using canonical V3 models
and explicitly document source-owned timing and child-stack boundaries.

The experimental live battle scene-frame and ownership-latch architecture is
deferred and archived. Core does not advertise live battle reconstruction;
products must keep battle native/deferred until a replacement design proves
source identity, timing, suppression, and complete visible-stack ownership.

### Panel screen descriptors

The component-oriented screen shape is a strict V3 panel descriptor:

```lua
{
  id = "encounter_reference",
  type = "panel",
  preset = "M",
  components = {
    { id = "route", type = "label", text = "ROUTE 29" },
    { id = "mode", type = "dropdown", label = "MODE", value = "day",
      options = { { id = "day", label = "DAY", value = "day" } } },
  },
}
```

Registration validates the panel ID, preset, dense component and nested option
arrays, unique component IDs, known component fields, and the required payload
for each component type. Details fields/footer lists, modal options, status-card
metadata, and named action references are validated before the registry swaps a
new contract into place. A malformed panel therefore fails atomically and never
reaches the renderer. Studio uses the same rules locally so an editor project
can be rejected before export or host registration.

An `animation` model is the direct V3 shape for a timed visual frame that is
not itself an interactive menu. It requires an `animation.id` and may expose
`frame`/`duration` or normalized `progress`, a display `label`/`message`, and
data-only sprite or overlay descriptors. Set `animation.overlay = true` for a
transparent full-viewport effect that decorates a source-owned underlay; its
normalized `animation.overlays` are painted in order and can carry RGBA
`color` arrays. Each overlay uses normalized `x`, `y`, `w`, and `h` values,
must fit inside the `[0,1]` viewport, and may use three or four channel values
between `0` and `1`. This is the V3 seam for timed wipes and transitions
without inventing a centered panel over the world. The source still owns the
clock, cancellation, and gameplay mutation; the model makes the visual state
available to the shared renderer and editor without smuggling a callback into
the contract. Ordered `animation.circles` may add source-authored filled
particle effects. A circle uses normalized `x`/`y` coordinates (centers may
extend from `-1` to `2` for off-screen effects), a normalized `radius` measured
against the stage width, and optional RGB/RGBA `color`. Ordered
`animation.tilemap` is the portable seam for source-authored scrolling raster
backgrounds. It names an asset `path`, source-pixel `tileWidth`/`tileHeight`,
the `mapWidth`/`mapHeight` tile grid, `sheetColumns`, and a dense `tiles` array.
Optional source-pixel `scrollX`/`scrollY` values preserve camera movement;
`scanlineOffsets` can provide one finite `{x, y}` offset per logical scanline
for effects such as Gen II's water wave. The renderer expands the tilemap at
the current responsive stage while preserving the source palette and crop
data.
`animation.tilemap` is intentionally data-only: the product still owns frame
timing, input, and source-state mutation. Ordered
`animation.labels` may add source-authored text over the
animation. A label has normalized `x`/`y` coordinates, string `text`, and an
optional `align` (`left`, `center`, or `right`), normalized `maxWidth`, and
RGBA `color`. Labels are rendered after sprites, so a cinematic can keep its
art and text in one portable V3 model without falling back to a product-only
text renderer.

`animation.backgroundSprites` is an optional ordered sprite layer painted
before `animation.tilemap`; it is useful for source effects whose objects pass
behind a scrolling background. `animation.sprites` is painted after the
tilemap. Sprite descriptors normally infer normalized rectangles when all four
coordinates fit within `0..1`. A descriptor may set `normalized = true` to
keep normalized coordinates outside that range, which is useful for cropped
sprites entering or leaving the viewport (such as source OAM animation). The
flag is data-only and keeps the same model portable across portrait,
landscape, and high-resolution layouts. Every sprite descriptor must provide a
non-empty `path` (or `asset`) and a complete positive `rect`; optional crops
must use a non-negative integer origin and positive integer size, and optional
flips and palettes are validated before the model reaches the renderer. This
makes missing geometry a contract error instead of a late, silent draw failure.

Direct presentation models must include `schema =
"clean_ui.v3.presentation.v1"`, `apiVersion = 3`, and a non-empty `preset`.
The registry rejects a direct screen that omits or mismatches any of those
fields atomically. Ordered payloads are dense arrays: menu rows, dialogue
lines, choice options, battle actions, animation sprites, animation overlays,
  and animation labels/circles/tilemap data cannot be keyed maps, contain holes, contain the wrong
item type, or
escape their normalized bounds. Present selection fields
must be positive integer indices. Panel descriptors remain the
component-oriented shape; the shell converts validated panels to the same canonical
menu model before rendering. The shared presentation runtime applies the same
validation immediately before measurement and rendering, so a malformed or
non-canonical direct model cannot reach the renderer through a product provider
or action result. Legacy/custom surfaces remain the explicit compatibility
escape hatch and are validated by their own surface contract.

Generation providers should apply the same V3 marker gate before suppression:
when a registered record declares `presentationApi = 3`, a prepared model must
carry the canonical schema, `apiVersion = 3`, and a non-empty `kind`. Missing
markers fail open to the source UI before offscreen composition; Core remains
the final full-shape validator. This two-stage boundary keeps diagnostics close
to the product seam without duplicating Core's complete model rules.

### Standalone embedding bridge

The source runtime also exposes a small embedding bridge for tools such as
Clean UI Studio. `validateV3(contract)` returns data-only diagnostics,
`measureV3(screen, width, height, options)` solves the responsive envelope and
measures the canonical presentation model, and `drawV3`/`renderV3` reuse the
same presentation renderer. These methods are intentionally lower-level than
`cleanUiHost`: they are for an editor or test harness that boots the core
source beside its own window, not for product mods to call through private
state. A tool may use them when available and retain a portable fallback when
the core checkout is not bundled.

## Contract shape

```lua
local contract = {
  id = "dex_tools",
  version = "1.0.0",
  games = { "gen1", "gen2" },
  priority = 0,

  screens = { ... },
  extensions = { ... },
  surfaces = { ... },
  themes = { ... },
  frames = { ... },
  gallery = { ... },

  actions = {
    open_search = function(ctx, payload) ... end,
  },
}
```

Required fields are `id` and `version`, plus either `games` or the universal
flag `all_generations = true`. IDs use lower-case ASCII letters, digits, `_`,
`.`, and `-`; they must begin and end with a letter or digit. The running
product game must appear in `games` unless `all_generations` is true.

Use the flag when the same contract, screen models, and named actions are
valid for every Clean UI generation:

```lua
local contract = {
  id = "shared_party_tools",
  version = "1.0.0",
  all_generations = true,
  screens = { ... },
  actions = { open = function(ctx, payload) ... end },
}
```

This is a contract-level declaration: one registration is accepted by both
`gen1_clean_ui` and `gen2_clean_ui`, and the editor catalog preserves the flag.
The package manifest must still list the generations it wants the launcher to
load, because manifest filtering happens before a V3 host can be discovered.
Use `ctx.game` or the host's `game` field only when source data genuinely
differs; the flag does not pretend that generation-specific state has the same
shape.

`games` remains supported for generation-specific or selectively shared
contracts. If present alongside `all_generations = true`, it is retained as
descriptive metadata but does not limit registration. `priority` defaults to
zero and should be changed only when ordering is meaningful.

The registry key is `ownerId + contract.id`. Registering that key again stages
and validates a complete replacement, then swaps it in one operation. A failed
replacement leaves the prior contract active. `unregister` is idempotent and
closes overlays or surfaces owned by that registration.

Contribution order is deterministic:

```text
priority, ownerId, contractId, contributionId
```

## Data and callback boundary

All screen models, component descriptors, style values, Gallery fixtures, and
action payloads must be acyclic, metatable-free data composed of:

- strings, finite numbers, booleans, and `nil`;
- arrays;
- string-keyed tables.

Functions, userdata, threads, metatables, and cycles are rejected in data.
Functions are accepted only in these documented slots:

- `actions[name]`;
- an exact screen or surface `validator`;
- custom-surface `update` and `draw`.

The registry copies validated data. Re-register to publish a changed static
model. Live source-state models are extracted by a generation product provider,
not captured from a third-party closure.

Every `action` reference inside a declarative screen is checked against the
contract's `actions` table during registration. A missing or malformed named
action rejects the complete registration and leaves an existing replacement
untouched; it is not deferred until a user activates the component.

## Data-first screens

A screen contribution describes a screen that Clean UI itself may open. It
does not claim ownership of an existing game screen.

```lua
{
  id = "encounter_reference",
  type = "panel",
  title = "Encounter Reference",
  preset = "L",
  components = {
    { type = "label", id = "route", text = "Route 29" },
    { type = "dropdown", id = "time", label = "Time", value = "day",
      options = {
        { id = "morning", label = "Morning", value = "morning" },
        { id = "day", label = "Day", value = "day" },
        { id = "night", label = "Night", value = "night" },
      }, action = "change_time" },
  },
}
```

Screen `preset` is one of `XS`, `S`, `NAV`, `M`, `L`, or `XL`. The product
locks that envelope for the screen instance's lifetime. NAV may choose a
content-driven width between 320 and 440 logical pixels, and ordinary M menus
between 320 and 600, when they open. Each chosen width remains locked until
the view is reopened or its layout context changes; the 560-pixel NAV and
420-pixel M logical heights are preserved. Rich detail/sprite M menus retain
their full declared width.

## Extensions

Extensions add to a production presenter without replacing it. Every extension
has `id`, `type`, and `target`.

Supported initial extension types are:

| Type | Purpose |
|---|---|
| `start.action` | Add a stable Mod Menus action eligible for pinning. |
| `menu.action` | Add an action to a named source menu seam. |
| `party.row_style` | Apply declarative row backgrounds or accents. |
| `party.row_decorator` | Add a text/icon badge in the reserved row slot. |
| `party.action` | Add an action to a Pokémon action menu. |
| `summary.page` | Add a fixed-envelope Summary page. |
| `pokedex.page` | Add a fixed-envelope Pokédex page. |

An extension cannot alter the parent envelope. Product providers publish the
supported `target` IDs for their game. Unknown targets reject registration.

Example Start action:

```lua
{
  id = "open_tools",
  type = "start.action",
  target = "mod_menus",
  label = "DEX TOOLS",
  description = "Open encounter tools.",
  icon = "search",
  action = "open_tools",
  pinnable = true,
}
```

V3 identity is always `ownerId + extension.id`. Labels are display text, not
identity.

### Declarative row rules

`party.row_style` uses ordered rules rather than a draw callback:

```lua
{
  id = "party_tints",
  type = "party.row_style",
  target = "party.rows",
  rules = {
    { when = { field = "slot", equals = 1 },
      style = { background = "#DCE8FF" } },
    { when = { field = "isEgg", equals = true },
      style = { background = "#FFF1C8" } },
  },
}
```

Supported predicates are `equals`, `not_equals`, `less_than`,
`less_or_equal`, `greater_than`, `greater_or_equal`, `present`, and `one_of`.
Rules are evaluated in declaration order; later matching style fields override
earlier ones. Product providers expose the fields available to each target.

## Components and actions

Components reference actions by string. See [COMPONENTS.md](COMPONENTS.md) for
descriptor schemas and payloads.

An action receives a read-only context and a copied payload:

```lua
actions = {
  change_sort = function(ctx, payload)
    -- payload = { componentId, value, optionId }
  end,
}
```

The context contains stable identity, product/game metadata, logging, and only
the source-owned dispatcher capabilities granted for that contribution. Action
errors are caught and reported; the surrounding menu remains open.

An action may return:

- `nil` to make no Clean UI navigation change;
- a data-first screen descriptor;
- a modal descriptor;
- `{ type = "close" }` to close the Clean UI-owned top surface.

Returning data does not bypass the source action. For extensions attached to a
source screen, source-owned action dispatch occurs through the product's
validated mapping.

## Modal overlay

```lua
return {
  type = "modal_overlay",
  id = "confirm_register",
  title = "REGISTER?",
  message = "Save this selection?",
  dim_background = true,
  dim_opacity = 0.4,
  options = {
    { id = "yes", label = "YES", action = "confirm" },
    { id = "no", label = "NO", action = "cancel" },
  },
}
```

Modal overlays preserve the parent panel, trap focus, and restore focus to the
trigger when dismissed.

## Details fields and footer lists

Details cards can reserve data columns and bottom-anchored lists without manual
screen math:

```lua
details = {
  species = "Oddish",
  level = "Lv 15 - 17",
  sprite = { asset = "pokemon/oddish", palette = "true_color" },
  custom_fields = {
    columns = 4,
    data = {
      { id = "hp", label = "HP", value = 45 },
      { id = "total", label = "TOTAL", value = 255, style = "accent" },
    },
  },
  footer_lists = {
    { id = "encounter", title = "ENCOUNTER",
      items = { { label = "GRASS", value = "24%" } } },
    { id = "moves", title = "KNOWN MOVES",
      items = { { label = "ABSORB" } } },
  },
  layout_options = {
    overflow = "shrink_to_fit",
    max_content_height = "100%",
  },
}
```

The layout engine measures header and footer content first, anchors footer
lists to the card bottom, and reduces sprite space to the remaining measured
area. Required text is wrapped or scrolled before the font is reduced.

## Custom surfaces

Custom surfaces are the explicit escape hatch for grids, live animation, and
shaders. Overlay is the default. Replace mode requires exact source-screen
identity, a validator, and a product-issued complete-stack proof.

```lua
{
  id = "animated_grid",
  mode = "overlay",
  target = { screen_id = "Gen2PokedexMenu" },
  logical_size = { w = 320, h = 180 },
  snapshot = { columns = 5, rows = 4 },
  update = function(ctx, dt)
    ctx.localState.phase = (ctx.localState.phase or 0) + dt
  end,
  draw = function(ctx, snapshot)
    local g = ctx.graphics
    g.rectangle("line", 0, 0, ctx.bounds.w, ctx.bounds.h)
  end,
}
```

The context exposes `time`, `dt`, logical and physical bounds, safe area,
scale, a scoped graphics facade, palette helpers, cached shader creation, and
surface-local pointer registration. Drawing runs on a private canvas inside a
protected graphics-state transaction. Canvas, transform, shader, color, blend
mode, scissor, font, line state, point size, color mask, and stencil state are
restored after success or failure.

Do not retain `ctx`, its graphics facade, a source state, or a canvas between
callbacks. Persistent animation values belong in `ctx.localState`; immutable
input belongs in `snapshot`.

## Themes and frames

Theme and frame registrations are owner-scoped. A theme may reference only a
built-in frame or a frame registered by the same contract.

```lua
frames = {
  { id = "thin_gold", type = "nine_slice",
    asset = "assets/thin_gold.png", inset = 6 },
},
themes = {
  { id = "field_notes", name = "Field Notes", frame = "thin_gold",
    colors = {
      paper = "#F4F1E5", raised = "#E5E4DA", ink = "#20242A",
      muted = "#66727A", selection = "#BCCAC4", accent = "#B3882D",
    } },
},
```

The registry rejects essential text/control contrast below 4.5:1.

## Gallery fixtures

Gallery fixtures are synthetic data and use the same screen/extension/surface
path as gameplay. A fixture never constructs a live screen or invokes an
action merely by being previewed.

```lua
gallery = {
  {
    id = "dropdown.grouped",
    games = { "gen1", "gen2" },
    family = "examples",
    title = "Grouped Dropdown",
    support = "supported",
    preset = "M",
    screen = "sort_screen",
    content_levels = { "EMPTY", "NORMAL", "OVERFLOW" },
  },
}
```

See [GALLERY.md](GALLERY.md) for controls, metadata, and safety requirements.

## Registration lifecycle

```lua
return function(mod)
  local contract = requireContractThroughModRead(mod)
  local activeHost

  local function install()
    local host = findCleanUi(mod)
    if not host then return end
    if activeHost and activeHost ~= host then
      activeHost.unregister(mod.id, contract.id)
    end
    local ok, code, message = host.register(mod.id, contract)
    if ok then activeHost = host
    else mod.log:warn("Clean UI registration failed: %s: %s", code, message) end
  end

  install()
  mod.events:on("mods.loaded", install)
end
```

The examples use `mod:read` plus sandboxed `load`/`loadstring`; loaded chunks
inherit the calling mod's private `_G`. They never touch a process-wide module
path or raw filesystem API. Persistent data belongs in `mod.storage` (or the
specific save/options API documented by the host), and cross-mod APIs belong on
`mod.exports`. Run `scripts\verify_sandbox.cmd` before publishing an example
ZIP. The complete compatibility rules and replacement table are in
[SANDBOX_COMPATIBILITY.md](SANDBOX_COMPATIBILITY.md).

## Error codes

Stable expected codes include:

- `invalid_owner_id`
- `invalid_contract`
- `unsupported_game`
- `unsupported_capability`
- `unknown_target`
- `unknown_action`
- `invalid_data`
- `invalid_surface`
- `replacement_not_proven`
- `gallery_unavailable`

Messages are for humans and may gain detail; code values are the programmatic
contract.

## Migration policy

API V3 is the preferred Clean UI contract. Product repositories may also ship
an explicit, product-scoped Modern UI v1/v2 compatibility facade for existing
source mods. That facade must retain the old data/callback boundary, private
surface transactions, and native fail-open behavior; it must not create a
loader-level `gen1_modern_ui` alias or import legacy settings/pins. New
integrations should feature-detect `cleanUiHost` and register V3 contracts.
