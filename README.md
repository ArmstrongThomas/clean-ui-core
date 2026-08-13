# Clean UI Core

Shared, non-installable source for Gen1 Clean UI and Gen2 Clean UI.

The core owns the design system, stable layout envelopes, whole-step Plain
Pixel policy, controlled dropdowns, Mod Menus and pins, Clean UI API V3,
Gallery, protected custom surfaces, diagnostics, and fail-open presentation.
Generation products own exact screen contracts, model extraction, action
mapping, sprites, palettes, and narrowly scoped native suppression.

This repository is intentionally modular. `bootstrap.lua` only loads the
declared module graph, while `core.lua` composes focused services. Product
`main.lua` files are bootstraps and are guarded by source-size tests.

See [the preserved rebuild plan](docs/CLEAN_UI_REWORK_PLAN.md), the
[current session handoff](docs/CLEAN_UI_SESSION_HANDOFF.md), and
[architecture](docs/ARCHITECTURE.md). The source-only loader and examples are
covered by the [sandbox compatibility contract](docs/SANDBOX_COMPATIBILITY.md)
and its local release scanner.
