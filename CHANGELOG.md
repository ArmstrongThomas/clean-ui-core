# Changelog

## Unreleased

- Added first-class V3 `device` and `map` presentation kinds with strict
  descriptor, marker, tilemap, and cursor-sheet validation plus the shared
  responsive menu renderer and embedding bridge.
- Added Core editor-fixture coverage for both direct kinds. The remaining V3
  gap is live source-owned animation timing, source identity, and complete
  child-stack ownership; products continue to fail open at those boundaries.
- Hardened the V3 battle presenter so message, command-menu, and four-move
  phases reserve the same battlefield envelope instead of shrinking the HUD;
  player status cards now place HP above EXP consistently.
- Fixed live battle OAM animation crop resolution to preserve both values
  returned by the animation-sheet lookup. Optional effect-sheet failures now
  skip only that effect tile, keeping the Clean UI frame active instead of
  exposing the native battle renderer.
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
