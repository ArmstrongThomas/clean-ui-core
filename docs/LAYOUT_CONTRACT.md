# Clean UI Layout Contract

Clean UI uses stable preset envelopes, measured content, and one immutable
layout result per revision. The outer panel does not chase its current page or
selection.

## Logical presets

| Preset | Logical size | Intended use |
|---|---:|---|
| `XS` | 320×200 | Confirmation, quantity, caller strip |
| `S` | 400×300 | Short utility menus |
| `NAV` | 320–440×560 | Start and Mod Menus; content-driven width |
| `M` | 320–600×420 | Main, Options, Save, PC roots; plain menus are content-driven |
| `L` | 760×540 | Party, Summary, Pack, Pokédex, services |
| `XL` | 960×640 | Box storage, Naming, Mail Compose |
| `BATTLE_WIDE` | 640×360 | Legacy/future Gen1 battle surface; not active in Gen2 |

The default frame is a two-logical-pixel cut-corner frame. Panel fill starts
inside its calculated inset; no background spill may touch the frame artwork's
inner edge.

## Stable screen lifetime

A product supplies a unique screen-instance token. The runtime locks preset,
physical outer bounds, density, and font step for that instance. NAV and
content-driven M menus also lock their chosen content width for that instance;
M menus retain their full 420-pixel logical height.

These changes do not resize the outer frame:

- selected Pokémon, item, record, or menu row;
- Summary or Pokédex page;
- Pack pocket, PC mode, or Trainer Card side;
- submenu, quantity prompt, confirmation, or other embedded modal;
- row count, message length, selection, or scroll offset.

NAV and ordinary M menus are the adaptive exceptions to the fixed-width preset
table. Their outer width is measured from the title, description, rows, and
plain details, then clamped to 320–440 or 320–600 logical pixels respectively.
Rich detail/sprite menus retain their full declared width. An adaptive width is
never widened by a later row, pin, or selection change. A new view,
viewport/safe-area change, or relevant setting revision may choose a new width.

Only reopen, viewport/safe-area/orientation change, or a relevant user
setting/theme revision creates a new layout session.

Presenters declare their worst-case regions up front. Dynamic content reflows,
wraps, or scrolls inside those locked regions.

## Scale resolution

For a safe viewport and preset:

```text
fitCap       = min(safeWidth / presetWidth, safeHeight / presetHeight)
targetScale  = resolveUiSize(setting, safeWidth, safeHeight)
panelScale   = min(fitCap, targetScale)
outerWidth   = floor(presetWidth  * panelScale)
outerHeight  = floor(presetHeight * panelScale)
```

All outer bounds remain inside the safe viewport. AUTO is monotonic in the
safe viewport's short edge, so panels become physically larger on 4K and 5K
displays instead of remaining 1080p-sized. Small, Medium, and Large are
documented multipliers on the same baseline and are still capped by `fitCap`.

The panel scale may be continuous. Final core-widget coordinates are integer
physical pixels.

## Image and sprite scaling

All Core-owned image descriptors (including cropped sprite sheets, party
icons, gender assets, map tiles, and animation sprites) use the shared image
renderer. It applies nearest-neighbor minification/magnification, snaps the
destination origin to integer physical pixels, and prefers whole-pixel
magnification or exact reciprocal reduction (for example 16px to 8px) before
rounding the final output width and height. If a non-divisible source crop
cannot satisfy that policy, nearest filtering and integer extents remain the
safe fallback. Callers should provide the source crop and a measured
destination rectangle; they must not draw the image directly or scale it again
in presenter code.
Native tilemaps apply the same chosen scale to every cell and round the map
origin once, so responsive rounding cannot create per-column seams.

## Font policy

Configured faces are created only at authored family-relative sizes. Plain
Pixel and System use 15px at 1×; OpenTTD Mono uses 10px at 1×:

```text
Plain Pixel/System: 1× = 15 px, 2× = 30 px, 3× = 45 px, 4× = 60 px
OpenTTD Mono:       1× = 10 px, 2× = 20 px, 3× = 30 px, 4× = 40 px
```

The public settings expose OpenTTD Mono, Plain Pixel, and System plus AUTO/1×/
2×/3×. AUTO tries the largest public step through 1× and chooses the largest
complete layout that meets the physical-size target and all bounds. Explicit
4× remains an internal authored-style option. A manual step is a requested
maximum; the solver may cap it downward to prevent required overlap or
clipping.

Required text is measured as part of each presentation probe. If the selected
step would truncate a required line, the solver retries the next lower step;
renderers must not replace that line with an ellipsis.

System font uses the same measured layout contract and missing-glyph fallback.
Drawing never creates or scales a Plain Pixel font independently.

## Measurement pipeline

For each allowed font/density candidate:

1. Measure frame, header, footer, and fixed chrome.
2. Reflow declared responsive columns.
3. Wrap wrappable text.
4. Assign scrolling to declared scroll regions.
5. Tighten optional spacing and optional chrome.
6. Try the next lower font step if required content still does not fit.
7. Reject the candidate if any required overlap or clip remains.

Only explicit scroll viewports may clip required content. Decorative or
truncatable content must be marked as such by its contract.

The accepted result contains all geometry used by rendering and input:

```lua
{
  revision = 17,
  preset = "L",
  viewport = { x = 0, y = 0, w = 1920, h = 1080 },
  safeArea = { x = 0, y = 0, w = 1920, h = 1040 },
  outer = { ... },
  frameInset = { left = 4, top = 4, right = 4, bottom = 4 },
  regions = { header = ..., body = ..., footer = ..., overlayHost = ... },
  scale = 1.5,
  font = { family = "plain_pixel", step = 2, physicalPx = 30 },
  density = "comfortable",
  nodes = { ... },
  clipRects = { ... },
  scrollRanges = { ... },
  hitRegions = { ... },
  overflow = { resolved = { ... }, unresolvedRequired = {} },
  diagnostics = { decisions = { ... }, warnings = {} },
}
```

Render and pointer routing consume this result without remeasurement.

## Header and selection separation

Headers own a measured region that rows cannot enter. A selected first row may
touch neither heading text nor its separator. Scroll reveal clamps the first
row to the body's top inset, preventing the common highlight-over-header bug.

## Details cards

Details layout reserves space in this order:

1. title and fixed metadata;
2. bottom-anchored footer lists;
3. custom-field grid after responsive column reflow;
4. remaining sprite region.

Sprite size is derived from the remaining measured rectangle. It is never
allowed to force footer lists beyond the card or to cover required text.

`layout_options.overflow = "shrink_to_fit"` enables the normal solver fallback
sequence; it is not arbitrary fractional text scaling. Plain Pixel still moves
only between whole authored steps.

## Dropdown placement

A dropdown is an overlay rooted at its trigger geometry. It does not
participate in parent flow after opening.

Placement tries below and above, chooses the side with enough space or the
larger available span, clamps horizontally and vertically to the safe area,
then adds an internal scroll viewport when all options cannot fit. The trigger
remains visible and receives focus again when the overlay closes.

## Touch geometry

Each actionable node has:

- visible bounds used for drawing;
- an expanded minimum hit region clamped to its owning visible region.

Pointer, touch, controller, and keyboard navigation all refer to component IDs
from the same layout result.

## Battle boundary

Battle presentation is currently deferred in the active Core roadmap. The
committed `BATTLE_WIDE` geometry remains a legacy/future contract for later
design work, but no product may claim live battle ownership from it. If a
battle surface is not explicitly proven by a future product/provider contract,
the entire battle stack remains native.

Enemy status belongs above or within the enemy side of the renderer. It is
never stacked directly above the player status panel. Every battle phase must
retain all source information, and transition text boxes may not linger after
their source phase ends.

## Failure behavior

A layout is complete only when:

- all numbers and rectangles are finite;
- `outer` is contained by `safeArea`;
- required nodes do not overlap;
- every required clip belongs to an explicit scroll viewport;
- scroll extents make all required content reachable;
- Plain Pixel uses a legal whole step;
- hit regions are reachable and bounded;
- `unresolvedRequired` is empty.

If no candidate is complete, the product must not suppress native UI.
