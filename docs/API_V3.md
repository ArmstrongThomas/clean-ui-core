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
  coreVersion = "0.1.0",
  productId = "gen2_clean_ui", -- or gen1_clean_ui
  game = "gen2",               -- or gen1
  capabilities = {
    data_screens = "1.0.0",
    additive_extensions = "1.0.0",
    dropdown = "1.0.0",
    modal_overlay = "1.0.0",
    custom_fields = "1.0.0",
    footer_lists = "1.0.0",
    custom_surface = "1.0.0",
    isolated_shader = "1.0.0",
    themes = "1.0.0",
    frames = "1.0.0",
    gallery = "1.0.0",
    start_menu_pinning = "1.0.0",
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

Required fields are `id`, `version`, and `games`. IDs use lower-case ASCII
letters, digits, `_`, `.`, and `-`; they must begin and end with a letter or
digit. The running product game must appear in `games`. `priority` defaults to
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
locks that envelope for the screen instance's lifetime.

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

Clean UI is a clean break. There are no compatibility aliases or adapters for
the retired Modern UI APIs. Integrations register an explicit V3 contract and
feature-detect capabilities with `supports`.
