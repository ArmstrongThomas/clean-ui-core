# Changelog

## Unreleased

- Added bounded document image sizing and optional three-column list rows with
  dotted leaders, preserving the generic two-column list fallback.
- Added a reusable document scrollbar component with proportional thumb,
  directional arrows, bounded region clipping, and explicit multi-column
  document composition for list/rail/detail reference pages.
- Added the first V3 document-page contract and shared renderer/layout slice for
  page-specific reference screens such as Pokédex info, habitat, evolution,
  moves, and machine compatibility. Document pages are data-only; products
  still own source navigation and input dispatch.
- Added document-page Gallery expansion so empty, minimal, dense, and overflow
  previews exercise the same structured regions used at runtime.
- Made OpenTTD Mono the default bundled font family. The public choices are
  OpenTTD Mono, Plain Pixel, and System; public text steps are AUTO/1x/2x/3x.
  Explicit internal 4x remains available for authored display styles only.
- Added the shared largest-fitting font-step probe: required text is measured
  before rendering and falls back one authored step at a time instead of being
  truncated with an ellipsis.
- Added reusable semantic text roles for body, label, value, caption, strong,
  subheading, heading, title, display, accent, and muted rendering. Heading,
  title, and display runs can request larger family-relative whole-step faces
  (including the reserved internal 4x display step); each run still falls
  back independently when it cannot fit, without changing neighboring text.
- Tightened the detached party/summary compositions with six fixed party slots,
  animated sprite-sheet crop selection, structured summary field cards, and
  stronger section/tab hierarchy.
- Added shared detached party-list and summary-page layout/render primitives
  for the Gen2-first Party/Summary redesign: stable row geometry, top-right
  tab geometry, beveled semantic badges, and independent move information
  regions. These are generic data-first primitives; source navigation remains
  outside Core.
- Added regression coverage for six-row party envelopes, tab order, move-slot
  containment, and source-index-preserving hit geometry.
- Centralized Core-owned image presentation: loaded images use nearest-neighbor
  filtering, sprite/tile/crop destinations are integer-aligned, and raster
  scaling uses whole-pixel magnification or exact reciprocal reduction where
  the source crop permits it. Gender icons size from the selected font's pixel
  height without forcing a fractional source scale. Native tilemaps also
  choose one shared pixel scale for the full tile grid so responsive cells do
  not accumulate rounded seams.
- Made Clean UI settings durable on released hosts that expose
  `mod.options:define/get` but not `mod.options:set` by persisting the
  compatibility fallback through the public `mod.storage` facade. Hosts with
  the official writer continue to use it directly; settings remain session-only
  only before a playthrough storage context exists.
- Routed the shared shell's normal, V3, and Gallery-preview theme selection
  through the same Core settings adapter. The Mod Menus page no longer falls
  back to the native options reader's default Clean theme on released hosts.
- Added Red, Blue, Yellow, Gold, Silver, and Crystal built-in themes with
  matching settings choices and validated readable contrast palettes.
- Added a shared Dark Mode toggle that resolves each game palette to its dark
  variant, adds Light High Contrast, and keeps Clean/Dark as opposites.
- Restored presentation invalidation listeners for `screen.pushed` and
  `screen.popped`. Deferring the experimental battle architecture must not
  remove this shared lifecycle contract; isolated Gen2 product smoke now
  remains compatible with the current Core snapshot.
- Extended the V3 `map` marker descriptor with an optional boolean `nest` flag
  and a distinct responsive diamond marker. This is used by Gen1 TownMap Area
  mode; it carries presentation data only and does not change source ownership.
- Added first-class V3 `device` and `map` presentation kinds with strict
  descriptor, marker, tilemap, and cursor-sheet validation plus the shared
  responsive menu renderer and embedding bridge.
- Added Core editor-fixture coverage for both direct kinds. The remaining V3
  gap is live source-owned animation timing, source identity, and complete
  child-stack ownership; products continue to fail open at those boundaries.
- Deferred the experimental Core battle scene-frame, ownership-latch, and
  responsive battle-envelope work after official-launcher failures beyond the
  intro. Gen2 battle remains native/deferred while a new architecture is
  designed; see `docs/archive/battle-ui-deferred-2026-08-15/`.
- Kept the V3 naming presentation data-only: Core may render entry slots and a
  keyboard surface while the source retains cursor, text, and completion
  ownership.
- Added the V3 `all_generations = true` contract flag. A shared contract can
  now register against every Clean UI generation without duplicating its
  `games` list; manifests still declare launcher eligibility, and the editor
  catalog preserves the universal declaration.

## 0.1.0-alpha.10 — 2026-08-13

- Added content-driven NAV shell width, clamped to 320–440 logical pixels and
  locked for the lifetime of each open shell view.
- Added content-driven width for ordinary M list menus, clamped to 320–600
  logical pixels while preserving their full 420-pixel logical height; rich
  detail/sprite menus remain full-width.
- Made content sizing font-aware for right-hand row values and paired detail
  columns, including regression coverage for large text settings.
- Added shared-dialogue support for folding native continuation-only breaks
  into one reflowable message without changing true page boundaries.
- Preserved stable height, safe-area containment, whole-step font sizing, and
  fail-open layout behavior.
- Added regression coverage for compact width and width locking when content
  changes during one open view.
- Applied the same bounded-width calculation to production NAV menu models,
  including the Gen2 Start Menu, while preserving the full tall envelope.
- Added the presentation-runtime seam used by product-scoped Modern UI v2
  compatibility surfaces: private-canvas rendering, protected composition,
  and native fail-open handling.
- Hardened the responsive battle presenter around the native Gen II diagonal:
  enemy status upper-left with enemy sprite upper-right, player sprite
  lower-left with player status lower-right. The two-row geometry preserves
  compact low-resolution cards and overlap/containment probes for large text
  settings.
- Battle status cards now render applicable gender, major and volatile
  conditions, wild catch state, and the player's live EXP progress while
  retaining bounded compact-card fallbacks.
