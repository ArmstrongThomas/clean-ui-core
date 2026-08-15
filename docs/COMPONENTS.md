# Clean UI Components

This document defines the initial data-first component vocabulary used by
Clean UI API V3. Components are controlled descriptors: source data owns their
value; the runtime owns only ephemeral focus, hover, open, and scroll state.

## Common fields

Every component has:

| Field | Type | Meaning |
|---|---|---|
| `type` | string | Registered component type. |
| `id` | string | Stable within its containing screen. |
| `visible` | boolean | Optional; defaults to `true`. |
| `enabled` | boolean | Optional; defaults to `true`. |
| `label` | string | Optional visible label. |
| `description` | string | Optional help text. |
| `style` | string/table | Semantic style token or validated overrides. |
| `layout` | table | Declarative width, span, alignment, wrap, and scroll hints. |

Unknown screen, component, option, field, and footer-list fields are rejected
in strict descriptors. Layout/style override tables remain intentionally
extensible data owned by the presenter. Required content cannot be marked
decorative to bypass overflow checks.

Component IDs are the focus and reconciliation identity. Changing a label does
not create a new component; changing an ID does.

## Screen descriptor

```lua
{
  id = "example_screen",
  type = "panel",
  title = "EXAMPLE",
  preset = "M",
  header = { ... },
  components = { ... },
  footer = {
    text = "A choose   B back",
  },
}
```

`preset` is fixed for the screen instance. NAV may choose its width from the
320–440 logical-pixel content range, and ordinary M menus may choose from
320–600, when opened. Those widths and their full 560- or 420-pixel logical
heights are then fixed. Rich detail/sprite M menus retain their full width.
Header, body, footer, overlay host, clip rectangles, scroll ranges, and hit
regions are all produced by one measurement result.

## Label

```lua
{ type = "label", id = "route", text = "ROUTE 29",
  style = "heading", layout = { wrap = true } }
```

`text` is required. Set `layout.truncatable = true` only for genuinely optional
display text; otherwise the solver wraps or scrolls it.

## Button

```lua
{ type = "button", id = "search", label = "SEARCH",
  action = "open_search", description = "Choose encounter filters." }
```

Activation dispatches:

```lua
{ componentId = "search" }
```

## List

```lua
{
  type = "list",
  id = "results",
  value = "oddish",
  action = "choose_result",
  items = {
    { id = "oddish", label = "ODDISH", value = "oddish",
      icon = "pokemon/oddish", description = "Grass / Poison" },
    { id = "locked", label = "UNAVAILABLE", disabled = true },
  },
  layout = { scroll = true, minimum_visible_rows = 6 },
}
```

The selected item is controlled by `value`. Navigation skips disabled rows and
keeps the selected row visible. Activation dispatches:

```lua
{ componentId = "results", value = "oddish", itemId = "oddish" }
```

## Dropdown

Dropdowns are milestone-zero components and must not resize their parent.

```lua
{
  type = "dropdown",
  id = "sort",
  label = "SORT BY",
  value = "dex",
  options = {
    { id = "dex", label = "DEX NUMBER", value = "dex" },
    { id = "name", label = "NAME", value = "name",
      group = "ALPHABETICAL" },
    { id = "locked", label = "UNAVAILABLE", disabled = true },
  },
  action = "change_sort",
}
```

Option fields:

| Field | Required | Meaning |
|---|---:|---|
| `id` | yes | Stable option identity. |
| `label` | yes | Visible text. |
| `value` | yes | Controlled value returned on commit. |
| `group` | no | Non-selectable heading emitted before this group. |
| `icon` | no | Registered icon/asset reference. |
| `description` | no | Secondary text. |
| `disabled` | no | Visible but not selectable. |

Behavior:

- A/click opens; A/click on an option commits.
- B or an outside click dismisses without mutation.
- Up/Down navigates selectable options.
- Wheel and touch drag scroll long lists.
- The overlay opens below or above its trigger and clamps to the safe viewport.
- Focus is trapped in the top dropdown and returns to its trigger on close.
- The current value receives a visible indicator.

Commit payload:

```lua
{ componentId = "sort", value = "name", optionId = "name" }
```

The action does not mutate the descriptor automatically. Publish the new
controlled value through source state or a re-registered data model.

## Tab strip

```lua
{
  type = "tabs",
  id = "summary_page",
  value = "moves",
  action = "change_page",
  tabs = {
    { id = "status", label = "STATUS", value = "status" },
    { id = "moves", label = "MOVES", value = "moves" },
    { id = "stats", label = "STATS", value = "stats" },
  },
}
```

Tab changes preserve the parent envelope. Payload uses `tabId` and `value`.

## Card and details

```lua
{
  type = "details",
  id = "oddish",
  title = "ODDISH",
  sprite = { asset = "pokemon/oddish", palette = "true_color" },
  fields = {
    { id = "species", label = "SPECIES", value = "WEED" },
    { id = "level", label = "LEVEL", value = "15 - 17" },
  },
  custom_fields = {
    columns = 4,
    data = {
      { id = "hp", label = "HP", value = 45 },
      { id = "total", label = "TOTAL", value = 255, style = "accent" },
    },
  },
  footer_lists = {
    { id = "encounters", title = "ENCOUNTERS",
      items = { { label = "GRASS", value = "24%" } } },
  },
  layout_options = {
    overflow = "shrink_to_fit",
    max_content_height = "100%",
  },
}
```

`custom_fields.columns` is a preferred maximum, not permission to overlap.
Columns reflow before text size is lowered. Footer lists are measured and
anchored to the card bottom. Sprite bounds consume only the safe area left
after required text and footers.

`sprite.crop` (or `sprite.sourceRect`) may select an exact source rectangle as
`{ x, y, w, h }` or `{ x=..., y=..., w=..., h=... }`. Coordinates and sizes
are integer source pixels and must remain wholly inside the loaded image. The
renderer uses a LÖVE `Quad`, nearest-neighbor filtering, and the descriptor's
palette shader. A declared sprite is required presentation data: a missing
image, invalid crop, unavailable/rejected Quad, or failed sprite draw makes the
offscreen frame incomplete so the product leaves the native UI visible. Omit
the sprite descriptor when artwork is genuinely optional.

## Modal overlay

```lua
{
  type = "modal_overlay",
  id = "confirm",
  title = "CONFIRM",
  message = "REGISTER THIS ENTRY?",
  dim_background = true,
  dim_opacity = 0.4,
  options = {
    { id = "yes", label = "YES", action = "confirm" },
    { id = "no", label = "NO", action = "cancel" },
  },
}
```

The modal uses an `XS` or `S` envelope inside the existing overlay host and
never changes the parent's outer bounds. B dismisses unless `cancelable` is
explicitly false.

## Status card

Status cards document native or deferred screens in Gallery:

```lua
{
  type = "status_card",
  id = "battle_native",
  screen_id = "Gen2BattleState",
  support = "deferred",
  reason = "Battle is outside Gen2 1.0 scope.",
  milestone = "post-1.0",
}
```

They are informational and never suppress the named source screen.

## Icons and assets

Asset references are opaque IDs resolved by the owning product or contract.
Descriptors must not pass live `Image`, `Canvas`, `Font`, or `Shader` userdata.
Pokémon art requests include an explicit palette policy; Gen2 defaults to
full-color art rather than monochrome fallback.

## Pointer and touch

Every actionable component receives both visible geometry and an expanded
minimum touch hit region. Hit testing consumes the measured layout result.
Components do not calculate their own screen coordinates while drawing.

## Action isolation

Named actions are called under a protected boundary. An exception:

- is logged with owner, contract, action, and component IDs;
- closes only transient UI owned by the failed action when necessary;
- does not remove Start, Mod Menus, or the native source screen;
- does not leave focus trapped in a dead overlay.
