# Clean UI Ground-Up Rebuild Plan

## Summary

Replace the retired monolithic Modern UI with three MIT-licensed repositories:

- `clean-ui-core`: shared source, design system, layout engine, components, V3 API, Gallery, diagnostics, and tests. It is not an installable mod.
- `gen1-clean-ui`: installable `gen1_clean_ui` mod and its single updater-compatible release ZIP.
- `gen2-clean-ui`: installable `gen2_clean_ui` mod and its single updater-compatible release ZIP.
- Freeze `gen1-modern-ui` after one final Gen1-only `0.9.1` retirement commit.

The rebuild is a clean break:

- No old settings or pin import.
- No legacy settings/pin imports or loader-level product aliases. Product
  builds may expose an explicit Modern UI v1/v2 compatibility facade so
  existing source mods can migrate to V3 without losing presentation support.
- Existing hook-added Start-menu entries remain generically discoverable, but richer integration uses Clean UI API V3.
- Gen2 is implemented first; Gen1 follows after Gen2's non-battle UI is stable.
- Plain Pixel is the default font.
- Dropdowns, Mod Menus, and Start-menu pinning are foundation features, implemented before broad screen coverage.
- Product `main.lua` files remain tiny bootstraps. Shared systems and each coherent screen family live in focused modules.

## 1. Repository and Delivery Structure

### Preserve and retire `gen1-modern-ui`

- Back up the current dirty Gold prototype as a binary patch plus copied untracked files and a SHA-256 inventory outside the legacy repository.
- Stash the dirty tree, including untracked files, and retain that stash until useful Gold research has been transferred.
- Rebuild the retirement release from clean `v0.9.0`.
- Produce `0.9.1` with:
  - Explicit `"games": ["gen1"]`.
  - No Gen2 code, contracts, docs, flags, or claims.
  - The taller, narrower Start-menu `NAV` envelope at `320–440x560`, with
    width chosen from required content and locked while open.
  - Only additional RBY changes that have an isolated regression test, contain no Gen2 symbols, and demonstrably fix behavior absent from `v0.9.0`.
  - Frozen V1/V2 documentation and a retirement notice.
  - A conflict with `gen1_clean_ui`.
- Build and verify `gen1_modern_ui-0.9.1.zip`.
- Make one local retirement commit and fast-forward local `main`.
- Do not push, tag, publish, delete the prototype stash, or archive the GitHub repository without a separate request.

### Create the new repositories

- The first new commit creates and preserves this plan as `docs/CLEAN_UI_REWORK_PLAN.md`.
- Each product vendors a pinned snapshot under `vendor/clean_ui_core`; there is no runtime core mod dependency.
- `clean-ui-core.lock.json` records the core tag, commit, and per-file SHA-256 values.
- Deterministic sync scripts accept either a local sibling checkout for development or a tagged core archive for CI.
- CI rejects modified or stale vendored core files.
- Each product has:
  - `build_release.ps1`
  - A `.cmd` wrapper matching the existing workflow
  - Exactly one ZIP whose root is the matching mod directory
  - Independent semantic versions and GitHub releases
- Product manifests use API 2, `profile: "overhaul"`, `priority: 100`, `affects_link: false`, and only the required game:
  - Gen1: `"games": ["gen1"]`
  - Gen2: `"games": ["gen2"]`
- Both products conflict with `gen1_modern_ui` to reject accidentally installed prototype builds.
- Core and original code use MIT. Plain Pixel remains host-provided under CC BY 4.0 and receives attribution in each product's `THIRD_PARTY_NOTICES.md`.

### Required host API addition

Add an upstream, public `mod.options:set(key, value)` method before releasing either Clean UI product:

- It writes only to the calling mod's option namespace.
- It validates toggle, choice, number, and text values against the registered schema.
- It updates the live loader and profile-wide `options.modOptions`.
- It persists through the same engine path as `ManagerState:setOption`.
- It emits `mod.options_changed`.
- It returns `true`, or `nil, code, message` for an invalid key/value.
- Reset Defaults is implemented by setting schema defaults through this public method.
- No private `ManagerState` writer fallback is allowed.

Development starts against the current official Gold-capable host, `v0.1.79`. The release manifest floor becomes the first tagged host containing `mod.options:set` that passes the complete product contract suite.

## 2. Shared Design and Interaction System

### Visual identity

Use one minimal pixel-modern system with restrained generation accents:

- Default Clean theme:
  - Paper `#F4F1E5`
  - Raised surface `#E5E4DA`
  - Ink `#20242A`
  - Muted text `#66727A`
  - Selection `#BCCAC4`
  - Gen1 accent `#356AC3`
  - Gen2 accent `#B3882D`
- Dark theme uses `#171A1F` surfaces with `#F4F1E8` text.
- High Contrast uses black/white with `#FFD83D` focus.
- Text and essential controls maintain at least 4.5:1 contrast.
- The default frame is one clean two-logical-pixel cut-corner frame. There is no user-facing frame-style setting.
- Themes registered through V3 may reference registered custom frames.
- Panel fill begins inside the calculated frame inset; no white/background spill may touch the inner frame artwork.

### Stable layout envelopes

| Preset | Logical size | Intended use |
|---|---:|---|
| XS | 320x200 | Confirmation, quantity, caller strip |
| S | 400x300 | Short utility menus |
| NAV | 320–440x560 | Start and Mod Menus; content-driven width |
| M | 320–600x420 | Main, Options, Save, PC roots; plain menus are content-driven |
| L | 760x540 | Party, Summary, Pack, Pokedex, services |
| XL | 960x640 | Box storage, Naming, Mail Compose |
| Battle | 640x360 landscape / 360x640 portrait | Gen2 stable battle frames |
| Battle Wide | 640x360 | Gen1 2D battle only |

Rules:

- A screen's envelope is fixed for its lifetime. Page, Pokemon, pocket, selection, submenu, and content changes never resize its outer frame.
- NAV chooses a width from 320–440 logical pixels, and ordinary M menus from
  320–600, using their required title/description/row footprint when opened;
  both retain their full logical heights and lock the chosen width for the view
  lifetime. Rich detail/sprite M menus retain their full width. Neither mode
  widens when rows, pins, or selections change.
- Recalculate only after reopen, viewport/safe-area/orientation changes, or a user setting/theme change.
- Use measured header, footer, body, scrolling, clipping, and pointer geometry from one layout result.
- Overflow order is: reflow columns, wrap, scroll, tighten optional spacing/chrome, then lower the font step.
- Never silently overlap or clip required content.
- AUTO scaling grows on 4K/5K displays, but final bounds must remain inside the safe viewport.
- Gen2 battle uses the responsive `Battle` envelope. Stable menu, move,
  message, and status frames may be replaced; transition, animation, and
  battle-owned child states remain native until their timing contracts are
  independently proven.
- The Gen1 battle presenter uses only the `640x360` wide design. If a narrow or
  portrait viewport cannot fit it legibly at Plain Pixel 1x, leave Gen1 battle
  native instead of inventing a stacked battle layout.
- Enemy status stays above/within the enemy side of the renderer, never directly stacked above the player status panel.

### Font and settings

Plain Pixel is the default and is created only at authored 15-pixel multiples:

- AUTO
- 1x
- 2x
- 3x
- 4x

AUTO selects the largest complete whole step that satisfies the physical-size target and all bounds. A manually requested step is capped downward when necessary. System font uses equivalent measured scaling and remains the missing-glyph fallback.

The main settings screen contains only:

- Theme: Clean, Dark, High Contrast, plus registered themes
- UI Size: Auto, Small, Medium, Large
- Text Size: Auto, 1x, 2x, 3x, 4x
- Font: Plain Pixel, System
- Density: Auto, Comfortable, Compact
- Pointer & Touch: On/Off
- Compatibility
- Reset Defaults

Compatibility is a separate page with generation-relevant "Use Native UI" switches for Dialogue, Menus, Pokemon, Storage, Services, Manager, and Gen1 Battle. Defaults use Clean UI. Unknown or invalid screens remain native regardless of these switches.

### Dropdown component - milestone zero

Implement robust controlled single-select dropdowns before production presenters:

- Anchored overlay that never resizes its parent panel.
- Automatically opens above or below and clamps to the safe viewport.
- Scrolls long lists.
- Supports icons, group headings, disabled choices, descriptions, and current-value indicators.
- A/click opens and commits; B/outside click dismisses without mutation.
- Up/Down navigates selectable entries; wheel and touch drag scroll.
- Focus remains trapped in the top dropdown and returns to its trigger when closed.
- Pointer/touch receives a visible hit target; controller behavior requires no mouse.
- No search, multi-select, or freeform entry in the initial release.

V3 descriptor:

```lua
{
  type = "dropdown",
  id = "sort",
  label = "Sort By",
  value = "dex",
  options = {
    { id = "dex", label = "Dex Number", value = "dex" },
    { id = "name", label = "Name", value = "name", group = "Alphabetical" },
    { id = "locked", label = "Unavailable", disabled = true }
  },
  action = "change_sort"
}
```

The action receives `{ componentId, value, optionId }`.

### Mod Menus and Start-menu pinning

Preserve and improve the legacy behavior in both products:

- `MOD MENUS` is a complete catalog of third-party menu actions plus `CLEAN UI SETTINGS` and `UI GALLERY`.
- Pinning promotes a shortcut onto Start without removing it from Mod Menus.
- Keyboard/controller `SELECT` toggles a pin.
- Pointer/touch uses an explicit pin icon on each row.
- Pinned rows display a clear pin marker.
- Pinned rows appear as one block immediately above `MOD MENUS`; `MOD MENUS` is inserted before the stock `MODS` row, or before `SAVE` when `MODS` is absent.
- Start and Mod Menus use the tall `NAV` envelope and show at least eight normal rows before scrolling.
- There is no hard pin limit and no manual reordering in V1 of the new products; pins follow deterministic catalog order.
- V3 identity is `owner_id + entry_id`.
- Legacy hook additions with a unique stable `item.id` remain pinnable. A unique label may be used as a compatibility fallback. Duplicate label-only entries remain accessible but display "stable ID required" instead of allowing an ambiguous pin.
- Missing/disabled mods leave dormant pins intact so shortcuts return if the mod returns.
- Pins are per-save through `mod.save`; no legacy pins are imported.
- Source mods retain callback, navigation, audio, mutation, and transition ownership.
- Callback errors are caught, reported non-destructively, and never remove the Start menu.

## 3. Clean UI API V3

Each product exports the same host:

```lua
mod.exports.cleanUiHost = {
  apiVersion = 3,
  coreVersion = "...",
  productId = "gen1_clean_ui", -- or gen2_clean_ui
  game = "gen1",              -- or gen2
  capabilities = { ... },

  supports = function(capability, minimumVersion) ... end,
  register = function(ownerId, contract) ... end,
  unregister = function(ownerId, contractId) ... end,
  openGallery = function(filter) ... end,
}
```

Registration is idempotent and replaces the same `ownerId + contract.id`. External mods list both Clean UI products as optional dependencies, attempt immediate registration, and retry on `mods.loaded`. Only the product for the running game can be found.

A contract contains:

- `id`, `version`, and `games`
- `screens`: validated data-first screens
- `extensions`: Start actions, menu actions, row decorators/icons, Party actions, Summary pages, Pokedex pages
- `surfaces`: custom coordinate overlays or replacements
- `themes` and `frames`
- `gallery`: synthetic fixtures
- `actions`: the only ordinary callback table

Data snapshots remain function-free. Components reference named actions. Actions may return modal descriptors, including:

```lua
{
  type = "modal_overlay",
  dim_background = true,
  dim_opacity = 0.4,
  options = { ... }
}
```

Details presenters support:

- `custom_fields` with automatic column fitting
- `footer_lists` anchored to the card bottom
- `layout_options.overflow = "shrink_to_fit"`
- `layout_options.max_content_height`
- Dynamic sprite-space reduction after measured text/footer reservation

Custom surfaces explicitly support FelizNavidad-D's requirements:

- Arbitrary logical coordinates and grids
- Per-frame `update(ctx, dt)` and `draw(ctx, snapshot)`
- `ctx.time`, bounds, scale, safe area, palette helpers, and pointer regions
- Scoped shaders, silhouettes, palettes, and true-color rendering
- Overlay mode by default
- Replace mode only with an exact screen ID, validator, and complete-stack suppression proof

Every custom draw runs on a private canvas inside a protected graphics-state transaction. Canvas, transform, shader, color, blend mode, scissor, and font are restored even after exceptions.

V3 remains the primary integration surface. Product repositories may retain a
scoped v1/v2 facade with the same data-only and fail-open boundaries as the
retired Modern UI API; no loader-level product alias or legacy state import is
allowed.

Source examples in `clean-ui-core/examples` cover:

- Party row background colors
- Extra Trainer/Summary page
- Dropdown-driven screen
- Start-menu action and pinning
- Custom fields and bottom-anchored footer lists
- Modal overlay
- Animated grid/custom-coordinate surface with shaders

Each example has its own local ZIP build script, but example ZIPs are not published as multiple updater releases from the core repository.

## 4. Product Roadmaps

### Gen2 Clean UI first

Maintain an exact record for every ID in `Screens.GEN2_IDS`. Each record declares supported, native, or deferred status, validator, presenter, envelope, Gallery fixtures, and fallback reason.

- `0.1.0 alpha`: core integration, dropdown settings, Mod Menus/pins, Gallery, Manager, `Gen2MainMenu`, `Gen2StartMenu`, `Gen2OptionsMenu`, shared TextBox/ChoiceBox, and nickname prompts.
- `0.2.0 alpha`: Pack, Party, three Summary pages, moves/reordering, held-item flows, Pokedex, Trainer Card, Save, Naming, Center/Player/Box/Item PCs.
- `0.3.0 beta`: Pokegear, MapRadio/CallerBox, Mart, ScriptMenu, bank, contest, daycare, held-item, elevator, move deleter, mail, decoration, trade, NamePick, clock, Diploma, Photo Studio, Unown Printer, and Hall of Fame viewer.
- `1.0.0`: complete contract audit including stable battle presentation,
  responsive QA, documentation, and stable release.

Party/Summary acceptance includes:

- CANCEL/BACK is always represented meaningfully.
- Full-color Pokemon art appears on every appropriate page.
- Pink/green/blue source pages are represented by purpose-status, moves, and stats-not by color names.
- Move order and held-item actions remain source-owned and usable.
- The outer L envelope remains stable across every page and Pokemon.

Remain native through Gen2 1.0:

- Battle transition, battle animations, and child menus opened over battle
- Card Flip, slots, and Unown Puzzle
- Splash, title cinematic, credits
- Hatch, evolution, trade, and Magnet Train animations
- Oak's parent artwork/state, while audited child dialogue/naming may be modern
- Hall of Fame induction
- World-owned picture windows without an independent suppression seam

Gen2 battle's stable decision/message frames are part of the 1.0 scope;
animation-heavy and child-owned battle states remain explicit native seams.

### Gen1 Clean UI second

Reimplement from contracts rather than copying the legacy 19,000-line module:

- Main, Start, Options, Dialogue/Choice/PicBox/Naming
- Party, Summary, move learning, Pokedex/Dex Entry, Town Map
- Bag, shops, Trainer Card, Save/Load Report
- PC, Boxes, Item PC
- Mod Manager and shared integration surfaces
- UI Gallery and all V3 examples
- Complete redesigned RBY 2D wide battle UI before `1.0.0`

The first stable Gen1 release must:

- Keep Start tall/narrow with Mod Menus and pinning.
- Handle all RBY 2D battle phases without lingering text boxes.
- Keep all source battle information visible.
- Leave every 3D/voxel-owned battle and child interface entirely native.
- Fail open to native when wide battle cannot fit safely.

Cinematics and animation-heavy native scenes remain native unless later given an explicit design milestone.

## 5. Safety, Gallery, Testing, and Acceptance

### Presentation safety

- Generation providers own exact screen detection, validation, model extraction, palette/sprite resolution, pointer mapping, and suppression policy.
- The shared core owns measurement, layout, drawing, themes, controls, diagnostics, and V3 registries.
- Build the complete replacement offscreen before suppressing native rendering.
- Suppress only `screen.render_visible` for proven complete stacks; never clear shared world/UI canvases.
- Unknown IDs, malformed fields, custom source draw overrides, contract drift, capture modes, and exceptions immediately restore native rendering.
- The source screen always owns update, input semantics, callbacks, audio, save mutation, and transitions.

### UI Gallery

- Shows only the running game's production presenters plus shared integration fixtures.
- Uses stable IDs such as `gen2.party.actions` and `gen1.battle.moves`.
- Index mode navigates families and fixtures.
- Preview mode cycles fixture, EMPTY through OVERFLOW content, UI size, font/step, and system/Plain Pixel.
- Includes dropdown short/grouped/disabled/overflow/edge-flip fixtures and Mod Menus/pinning fixtures.
- Native/deferred screens display exact ID, reason, and planned milestone.
- Synthetic fixtures never construct live screens, invoke source callbacks, play audio, or mutate saves.
- A developer bounds overlay displays envelope, safe area, content, clip, scroll, pointer, and overflow rectangles.

### Required test matrix

- Viewports: 320x180, 640x360, 360x640, 390x844, 1024x768, 1280x720, 1280x1024, 1600x1000, 1920x1080, 2560x1440, 3440x1440, 3840x2160, and 5120x2784.
- Touch safe areas, portrait, short landscape, desktop, ultrawide, 4K, and 5K.
- Plain Pixel AUTO and 1x-4x plus System font.
- Every UI size, density, theme, and maximum combined setting.
- Stable outer bounds across records, pages, pockets, modes, selections, and embedded prompts.
- Valid, incomplete, malformed, unknown, custom-draw, and exception-producing contracts.
- Full screen stacks, including parent plus modal and battle plus child-native fallback.
- Dropdown focus, disabled entries, grouping, scrolling, placement, dismissal, pointer, touch, and controller behavior.
- Pin persistence, dormant pins, duplicate legacy entries, many-pin scrolling, source reload, and callback failure.
- V3 custom surfaces verify graphics-state restoration and error isolation.
- Real route smoke tests for every supported screen family.
- Gen2 runs `gen2check --strict --notes`.
- Both products run syntax, archive structure, manifest, updater naming, core-lock, and official-host load tests.

No stable release is accepted while any supported screen can hide native UI without successfully rendering its complete replacement.

## Assumptions

- New products start at `0.1.0`; `1.0.0` marks their first complete stable scope.
- Settings are profile-wide; pins are per-save.
- New installations start from clean defaults with no import prompt.
- Plain Pixel remains host-provided, whole-step, and attributed.
- The Gen2 prototype is research material only, not a codebase to transplant.
- FelizNavidad-D's 3D battle mod remains independent; Clean UI supplies V3 facilities but does not absorb ownership of 3D battle HUDs.
- No remote repository creation, push, tag, release, or GitHub archival occurs without separate authorization.
