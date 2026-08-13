# Clean UI API V3 Examples

Each directory is a standalone API 2 mod with a thin `main.lua`, a separate
V3 `contract.lua`, and deterministic local ZIP wrappers. Examples list both
Clean UI products as optional dependencies and register only with the product
available for the running game.

- `party-row-colors`: declarative Party row backgrounds.
- `extra-summary-page`: an additional fixed-envelope Summary page.
- `dropdown-screen`: controlled grouped dropdown behavior.
- `start-action-pinning`: Mod Menus discovery and Start pinning.
- `details-fields-footer-lists`: automatic columns and bottom anchoring.
- `modal-overlay`: a dimmed, focus-trapped modal.
- `animated-shader-grid`: custom coordinates, animation, pointers, and shader isolation.

Run an example's `build_release.ps1` or `build_release.cmd`. Archives are
local demonstration artifacts and are not published as multiple updater
releases from this repository.

These examples intentionally contain no compatibility aliases. See
[`docs/API_V3.md`](../docs/API_V3.md) for the normative contract.
