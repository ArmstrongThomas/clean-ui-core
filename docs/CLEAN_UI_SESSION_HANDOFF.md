# Clean UI Session Handoff

Last updated: 2026-08-13

This is the continuation document for the Clean UI ground-up rebuild. Read
this file and [the authoritative rebuild plan](CLEAN_UI_REWORK_PLAN.md) in full
before changing code. The plan owns product scope and architecture; this file
records the current workspace state, what is actually integrated, and the next
safe work sequence.

## Latest session update (2026-08-13)

- Content-driven menu sizing now measures the active font against both row
  columns and plain detail panels, so Continue/save summaries and other
  text-heavy menus widen before labels or values are ellipsized.
- Shared dialogue extraction keeps native continuation-only pauses inside one
  reflowable Clean UI message while preserving true page breaks, typewriter
  timing, and source-owned input.
- The real Gold route smoke reached the Pryce gym milestone (`11.44`) with
  the Clean UI opt-in enabled; the original `slot1.lua` save was restored from
  `G:\dev\misc\gold-route-slot1-backup.lua` afterward.
- Focused verification is green: core `208` checks, product shared UI `45`
  checks, full product Lua suite, responsive NAV/M and battle matrices,
  scaffold, core lock, and sandbox gates.

## Working rules

- Work under `G:\dev\misc`.
- Do not commit, push, tag, publish, create remote repositories, or archive a
  repository unless Tommy explicitly asks.
- Preserve every dirty worktree, stash, backup, and user-authored change.
- Use safe local diagnostics, tests, and LOVE tools without repeatedly asking
  for approval.
- Use no more than four subagents at once and close them when their work is
  complete.
- Keep the rewrite modular. Product `main.lua` files remain tiny bootstraps;
  screen-family work belongs in focused modules.
- Be precise about status: "implemented and focused-tested" does not mean
  "integrated into gameplay."
- Keep native rendering visible whenever a contract, stack, or presenter is
  not proven complete.

## Repository map

| Repository | Role | Current state |
|---|---|---|
| `G:\dev\misc\clean-ui-core` | Shared, non-installable runtime | Core runtime and tests are committed locally; current working tree adds responsive NAV/M widths and stable battle presentation |
| `G:\dev\misc\gen2-clean-ui` | Installable Gold product | Active product; foundation, 0.2, and 0.3 families are integrated and aggregate-tested |
| `G:\dev\misc\gen1-clean-ui` | Installable RBY product | Initial scaffold commit `e2778d7`; clean local `main`, intentionally waiting behind Gen2 |
| `G:\dev\misc\gen1-modern-ui` | Retired legacy product | Clean retirement release at 0.9.1; Gold prototype retained in a stash and external backups |
| `G:\dev\misc\gen1recomp-grandmas-kitchen` | Local patched host for sandbox/API development | Dirty `clean-ui/sandbox-audit` branch with required host APIs and local Gold launcher |

## Authoritative product decisions

- There are three repositories: shared `clean-ui-core`, `gen1-clean-ui`, and
  `gen2-clean-ui`.
- Each installable product vendors a pinned core snapshot; core is not a
  runtime mod dependency.
- The two products have independent updater-compatible repositories and one
  release ZIP each.
- Do not import legacy settings or pins or create a loader-level product alias.
  Product-scoped V1/V2 compatibility facades may preserve existing presentation
  contracts while source mods migrate to V3.
- Gen2 non-battle UI is the first implementation priority. Gen1 follows after
  Gen2 is stable.
- Plain Pixel is the default and may only use authored whole steps 1x, 2x, 3x,
  or 4x.
- Stable envelopes never resize while users change pages, Pokemon, pockets,
  selections, modes, or embedded prompts.
- NAV chooses and locks a 320–440 logical-pixel width from its required content
  when a view opens; later row/pin changes never widen it.
- Ordinary M list menus choose and lock a 320–600 logical-pixel width from
  their content while retaining the full 420-pixel logical height; rich
  detail/sprite menus remain full-width.
- Dropdowns, Mod Menus, and Start-menu pinning are foundation features.
 - Stable Gold battle decision/message frames use the Clean UI responsive battle
   presenter with the native Gen II diagonal (enemy status upper-left/enemy
   sprite upper-right, player sprite lower-left/player status lower-right);
   transitions, animations, and battle-owned child stacks remain native/deferred
   through Gen2 1.0.
- Gen1 battle is a later wide-only 640x360 presenter. Three-dimensional battle
  HUD ownership remains external.

## `clean-ui-core`

Path: `G:\dev\misc\clean-ui-core`

- Branch: `main`
- HEAD: `96be904` (dirty working tree preserves the current local roadmap work)
- Core version in source: `0.1.0-alpha.10`
- The modular implementation, tests, examples, scripts, README, license, and
  supporting documentation are committed locally. The core has not been tagged
  or published.
- The implementation is deliberately modular: 70 shipped Lua files rather
  than a monolithic `main.lua`.

Implemented shared capabilities include:

- design tokens, themes, measured layout, safe areas, stable envelopes, and
  content-driven NAV/M widths;
- whole-step Plain Pixel sizing and large-monitor AUTO scaling;
- controlled dropdowns with groups, disabled options, scrolling, focus,
  pointer/touch handling, and edge flipping;
- settings shell, Gallery shell, diagnostics, and developer bounds overlays;
- Mod Menus and per-save Start-menu pinning;
- API V3 registration, extensions, details fields, footer lists, modal
  descriptors, custom surfaces, and protected graphics-state restoration;
- sandbox-compatible source loading and release scanners;
- examples for row colors, extra pages, dropdowns, Start actions/pins, details
  fields/footer lists, modal overlays, and animated shader grids.

Fresh verification on 2026-08-13:

- syntax, dependency, unit, integration, contracts, visual, and matrix suites
  each completed with `204 checks passed`;
- source-tree verification passed;
- sandbox verification passed for all 70 shipped Lua files.

Normal commands from the core root:

```powershell
.\scripts\invoke_tests.ps1
.\scripts\verify_sandbox.ps1
.\scripts\verify_source_tree.ps1
```

The product lock currently points to the development core snapshot identified
as `0.1.0-alpha.10` at `c3ead39e4daf3b03f281e0d58d23b0a6b555b96f`.
The source core changes remain uncommitted and the lock is not an immutable
public release. Before any release, create the intentional core tag and
regenerate both product locks against that official tagged commit and tag.

## `gen2-clean-ui`

Path: `G:\dev\misc\gen2-clean-ui`

- The product repository is on local HEAD `031cb3c`; its current working tree
  contains the uncommitted Gen2 integration, responsive, battle, and release
  documentation work. It has no release tag yet.
- Manifest version: `0.1.0`.
- Manifest is Gen2-only, API 2, overhaul profile, priority 100,
  `affects_link: false`, experimental, and conflicts with `gen1_modern_ui`.
- The host floor is deliberately `0.0.0-dev`, so release building remains
  blocked until a tagged official host includes and passes the required APIs.
- `main.lua` is a tiny modular bootstrap.
- Vendored core is `0.1.0-alpha.10` and its lock currently points at the
  development snapshot described above.

### Actually integrated and locally testable

All 37 supported production records are registered and can participate in
fail-open replacement during local Gold gameplay. The exact split remains in
the product's `docs/GEN2_CONTRACTS.md`; stable battle frames are included,
while battle transitions, animations, and child-owned stacks remain native or
deferred.

The core shell, clean settings, dropdowns, Mod Menus/pinning, API V3 host,
Modern UI V1/V2 compatibility facade, and UI Gallery are also active.

Fresh aggregate verification on 2026-08-13:

- Lua syntax: 178 files;
- contracts: 714 checks;
- foundation: 117 checks;
- shared UI: 44 checks;
- Party/Summary: 53 checks;
- Pack/Pokedex/Trainer/Save: 65 checks;
- Naming/storage: 112 checks;
- production Gallery: 779 checks;
- Modern UI compatibility: 33 checks;
- Pokegear/Map Radio: 165; services/commerce: 240; mail/specialty: 412;
- integrated Gallery: 174; production Gallery: 779;
- responsive NAV/M: 34,325; responsive battle: 21,859;
- product smoke, core lock, scaffold, and sandbox scans all passed.

Run from the product root:

```powershell
.\tests\verify_scaffold.ps1
.\scripts\verify_core_lock.ps1
python ..\gen1recomp-grandmas-kitchen\tools\modkit.py gen2check `
  .\mods\gen2_clean_ui --strict --notes
```

`gen2check --strict --notes` currently passes with expected static notes about
dynamic/literal module names. Full standalone `modkit validate` still needs a
standalone LuaJIT executable; LOVE's embedded LuaJIT is not that executable.

### Current Gen2 state

The following status is current:

- All 37 supported records (foundation, 0.2, and 0.3 plus stable battle) are
  registered with production model adapters and presenters; Hall of Fame is
  viewer-only.
- The 0.3 focused suites are part of `tests/run_all.lua`: Pokegear/MapRadio
  165 checks, services/commerce 240, mail/specialty 412, plus integrated
  Gallery and production Gallery checks.
- The aggregate suite passes syntax 178 files, contracts 714, foundation 117,
  shared 44, product smoke, Party/Summary 53, Pack/Dex/Trainer/Save 65,
  naming/storage 112, Pokegear 165, services 240, mail 412, integrated
  Gallery 174, production Gallery 779, responsive NAV/M 34,325, and
  responsive battle 21,859 checks.
- Mart, Mail Compose, and Trade use the host's exact zero-based ranges.
  `gold.CallerBox` remains explicitly native/pending until an exact public
  identity seam exists.
- The next 1.0 work is extending real-route smoke beyond the Lake of Rage
  checkpoint, closing any newly exposed host blockers, and release-host
  readiness; the required responsive viewport/font matrices are green.
- The synthetic production-path NAV/M matrix passes 34,325 checks and the
  battle matrix passes 21,859 checks across short landscape, portrait, desktop,
  ultrawide, 4K, and 5K settings, including the native diagonal card/sprite
  order plus metadata-rich gender/condition/catch/EXP card rendering. The real
  Gold smoke has reached the Lake of
  Rage/Lance milestone (`10.34`) with zero teleport shortcuts; remaining route
  work is coverage beyond that checkpoint and any newly exposed host blockers.
- Real-gameplay smoke is sampled integration evidence, not a claim that every
  possible popup has been encountered. The product contract/catalog, focused
  presenter suites, Gallery, and visual smoke remain the authoritative coverage
  for integrated Clean UI surfaces; native-by-design and deferred records stay
  explicitly outside replacement coverage.

### Completed integration history

The former 0.3 “pre-integration” checklist is historical only. Pokegear/Map
Radio, services/commerce, and mail/specialty families are now registered in
`src/product.lua`, routed through production Gallery conversion, and included
in `tests/run_all.lua`. Their focused suites pass 165, 240, and 412 checks.
The exact current supported/native/deferred split is authoritative in the
Gen2 product's `docs/GEN2_CONTRACTS.md` and `docs/RELEASE_STATUS.md`.

The three zero-based host validators (Mart, Mail Compose, and Trade) and their
regressions are complete. `gold.CallerBox`, battle transitions, animation-heavy
states, and unproven child stacks remain explicit native/deferred seams.

The next work is real-route coverage beyond the Lake of Rage checkpoint and
release-host readiness. Preserve the full vertical envelopes when narrowing
menus and keep rich detail/sprite surfaces wide when their measured content
requires it.

## `gen1-clean-ui`

Path: `G:\dev\misc\gen1-clean-ui`

- The initial native-safe scaffold is committed locally at `e2778d7`; the
  repository has no remote or release tag yet.
- It is Gen1-only, modular, sandbox-ready, and native-safe.
- No broad production Gen1 screen implementation has started.
- Gen1 Battle Wide remains deferred and cannot suppress native battle or child
  UI.
- Fresh scaffold checks passed with 247 Lua assertions and 24 static
  assertions.

Run from the product root:

```powershell
.\tests\verify_scaffold.ps1
```

Do not start broad Gen1 work until the Gen2 non-battle product is stable unless
Tommy explicitly changes the priority.

## Retired `gen1-modern-ui`

Path: `G:\dev\misc\gen1-modern-ui`

- Branch: `main`
- HEAD/tag: `bcb41ab`, `v0.9.1`
- Worktree is clean.
- Retirement commit message: `Retire Gen1 Modern UI at 0.9.1`.
- The release is explicitly Gen1-only and retains the tall/narrow Start menu.
- Do not add the abandoned Gold prototype back to this product.

Retained research/recovery material:

- `stash@{0}: On main: Gold prototype before Clean UI rebuild (2026-08-12)`
- `G:\dev\misc\gen1-modern-ui-gold-prototype-20260812`
- `G:\dev\misc\gen1-modern-ui-retirement`

Do not drop the stash, delete either backup, or perform remote archival without
an explicit request.

## Patched local host and sandbox transition

Path: `G:\dev\misc\gen1recomp-grandmas-kitchen`

- Branch: `clean-ui/sandbox-audit`
- HEAD: `d38faab0`
- The worktree contains a substantial, intentional, uncommitted host API patch.
  Treat all tracked and untracked files as active user work.

Locally implemented host capabilities include:

- public `mod.options:set(key, value)` with typed validation, live/profile
  update, persistence, event emission, and atomic failure;
- `ManagerState` delegation to that public writer;
- `render.ui.prepare` and `input.wheel`;
- Gold widescreen paths honoring `screen.render_visible`;
- `mod.ui.isBuiltinScreen`, `mod.ui.isSharedUI`, constrained `sourceImage`,
  and `pokemonPalette` helpers;
- Gen2 Naming source descriptors retaining full-color icon/palette data.

Fresh focused host verification on 2026-08-13:

- option writer: 6/6;
- UI identity/image/palette: 26/26;
- naming descriptors: 23/23;
- widescreen visibility: 14/14;
- hooks and graphics restoration: 41/41;
- Gen2 API gate: 921/921;
- manifest/options API: 123/123;
- `git diff --check` passed.

Known host-test caveats:

- `tests/mod_ui_tests.lua` cannot complete in this checkout because
  `data/generated/field.lua` is absent. This is a local host-fixture limitation,
  not a demonstrated Clean UI regression.
- An earlier `gen2_menus_test.lua` run reported 628/630 because two Options
  row/index expectations were stale and outside the host API patch scope.

Bryan's upcoming sandbox removes raw `io`, unsafe `os`, `love.filesystem`,
thread/system/event access, package/debug loaders, and bytecode. Current core
and product scanners pass against that announced contract. Continue using
`mod:read`, sandboxed `load`, `mod.storage`, `mod.save`, `mod.options`,
`mod.events`, and `mod.hooks` only.

The release floor for either Clean UI product must become the first official
tagged host that includes public `mod.options:set` and passes the complete
product contract suite. Do not point a release at this local dirty branch.

## Local Gold testing

The patched host uses the normal `pokemon-love2d` identity, so it sees the
existing Gold import and save under:

```text
C:\Users\Tommy\AppData\Roaming\pokemon-love2d\gold
C:\Users\Tommy\AppData\Roaming\pokemon-love2d\saves\gold\slot1.lua
```

The host checkout already contains a development junction:

```text
G:\dev\misc\gen1recomp-grandmas-kitchen\mods\gen2_clean_ui
  -> G:\dev\misc\gen2-clean-ui\mods\gen2_clean_ui
```

Launch with:

```text
G:\dev\misc\gen1recomp-grandmas-kitchen\Play-Gen2-Clean-UI-Dev.cmd
```

That runs the source checkout with Gold, launcher, and developer flags. In the
launcher, open `MODS`, select Gold, enable the experimental `Gen2 Clean UI`,
confirm, and play Gold. Use F5 for hot reload.

The retired `gen1_modern_ui` declares only Gen1 and is skipped on Gold. Do not
create a second copy or junction under AppData: duplicate `gen2_clean_ui` IDs
would make test results ambiguous. A previous attempt to create an AppData
junction was blocked and did not create anything.

All supported records in the current product catalog are expected to
participate in local fail-open replacement when their complete visible stack is
proven. Native/deferred records and unsupported child stacks must remain native.

## Definition of a safe continuation

A successful next session should leave the workspace with:

- exact zero-based host contracts represented in tests;
- 0.3 families either fully integrated and aggregate-tested or still clearly
  native, never half-suppressing source UI;
- Gallery fixtures routed through production presenters;
- `tests/run_all.lua` covering every integrated family;
- documentation matching actual runtime status;
- all existing core, product, sandbox, lock, and host API gates green;
- no commits or remote changes unless newly authorized.

## Paste-ready prompt for the next session

```text
Continue the Clean UI ground-up rebuild in G:\dev\misc. First read these two
files completely:

G:\dev\misc\clean-ui-core\docs\CLEAN_UI_REWORK_PLAN.md
G:\dev\misc\clean-ui-core\docs\CLEAN_UI_SESSION_HANDOFF.md

Treat the handoff's integrated-vs-implemented distinction as authoritative.
Continue Gen2 first. The immediate task is to extend real Gold route coverage
beyond the Lake of Rage checkpoint, investigate any newly exposed host
blockers, and prepare the official-host release gate. Keep CallerBox, battle
transitions/animations, and unproven child stacks native without a proven
identity/timing seam. Preserve fail-open behavior and complete-stack
suppression proofs. Run all aggregate, focused, responsive, sandbox, core-lock,
scaffold, gen2check, and relevant host API tests. Update docs to reflect what
is truly active.

Do not commit, push, tag, publish, create remotes, archive repositories, delete
stashes/backups, or overwrite unrelated dirty work. Use safe local tools without
asking repeatedly. Use no more than four subagents and close them when done.
Keep main.lua tiny and all implementation modular.
```
