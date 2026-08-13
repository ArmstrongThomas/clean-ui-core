# Clean UI Session Handoff

Last updated: 2026-08-13

This is the continuation document for the Clean UI ground-up rebuild. Read
this file and [the authoritative rebuild plan](CLEAN_UI_REWORK_PLAN.md) in full
before changing code. The plan owns product scope and architecture; this file
records the current workspace state, what is actually integrated, and the next
safe work sequence.

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
| `G:\dev\misc\clean-ui-core` | Shared, non-installable runtime | Substantial modular implementation and tests; implementation files are currently untracked |
| `G:\dev\misc\gen2-clean-ui` | Installable Gold product | Active product; foundation and 0.2 families integrated, 0.3 families implemented but not yet wired |
| `G:\dev\misc\gen1-clean-ui` | Installable RBY product | Native-safe scaffold only; intentionally waiting behind Gen2 |
| `G:\dev\misc\gen1-modern-ui` | Retired legacy product | Clean retirement release at 0.9.1; Gold prototype retained in a stash and external backups |
| `G:\dev\misc\gen1recomp-grandmas-kitchen` | Local patched host for sandbox/API development | Dirty `clean-ui/sandbox-audit` branch with required host APIs and local Gold launcher |

## Authoritative product decisions

- There are three repositories: shared `clean-ui-core`, `gen1-clean-ui`, and
  `gen2-clean-ui`.
- Each installable product vendors a pinned core snapshot; core is not a
  runtime mod dependency.
- The two products have independent updater-compatible repositories and one
  release ZIP each.
- This is a clean break. Do not import legacy settings or pins and do not ship
  V1/V2 compatibility aliases.
- Gen2 non-battle UI is the first implementation priority. Gen1 follows after
  Gen2 is stable.
- Plain Pixel is the default and may only use authored whole steps 1x, 2x, 3x,
  or 4x.
- Stable envelopes never resize while users change pages, Pokemon, pockets,
  selections, modes, or embedded prompts.
- Dropdowns, Mod Menus, and Start-menu pinning are foundation features.
- Gold battle and menus opened over Gold battle remain native through Gen2
  1.0.
- Gen1 battle is a later wide-only 640x360 presenter. Three-dimensional battle
  HUD ownership remains external.

## `clean-ui-core`

Path: `G:\dev\misc\clean-ui-core`

- Branch: `main`
- HEAD: `95a0f10`
- Core version in source: `0.1.0-alpha.10`
- Only the authoritative plan commit exists. The implementation tree is still
  untracked, including source, tests, examples, scripts, README, license, and
  supporting documentation.
- The implementation is deliberately modular: 70 shipped Lua files rather
  than a monolithic `main.lua`.

Implemented shared capabilities include:

- design tokens, themes, measured layout, safe areas, and stable envelopes;
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
  each completed with `167 checks passed`;
- source-tree verification passed;
- sandbox verification passed for all 70 shipped Lua files.

Normal commands from the core root:

```powershell
.\scripts\invoke_tests.ps1
.\scripts\verify_sandbox.ps1
.\scripts\verify_source_tree.ps1
```

The product core locks currently identify commit
`95a0f10cfea08f4c5340d2d220bc34788fa163ef` and contain hashes for the current
dirty source snapshot. That is acceptable for local development only. Before
any release, commit/tag core intentionally and regenerate both product locks
against the real immutable core commit and tag.

## `gen2-clean-ui`

Path: `G:\dev\misc\gen2-clean-ui`

- The repository has no first commit yet; the entire project is untracked.
- Manifest version: `0.1.0`.
- Manifest is Gen2-only, API 2, overhaul profile, priority 100,
  `affects_link: false`, experimental, and conflicts with `gen1_modern_ui`.
- The host floor is deliberately `0.0.0-dev`, so release building remains
  blocked until a tagged official host includes and passes the required APIs.
- `main.lua` is a tiny modular bootstrap.
- Vendored core is `0.1.0-alpha.10` and its lock currently points at the core
  plan commit plus the hashed development snapshot described above.

### Actually integrated and locally testable

These exact production IDs are registered and can participate in fail-open
replacement during local Gold gameplay:

- `Gen2MainMenu`
- `Gen2StartMenu`
- `Gen2OptionsMenu`
- `Gen2PackMenu`
- `Gen2PartyMenu`
- `Gen2SummaryMenu`
- `Gen2PokedexMenu`
- `Gen2TrainerCard`
- `Gen2SaveMenu`
- `Gen2NamingScreen`
- `Gen2CenterPcMenu`
- `Gen2PcMenu`
- `Gen2BoxMenu`
- `Gen2ItemPcMenu`
- shared `TextBox` and `ChoiceBox` flows

The core shell, clean settings, dropdowns, Mod Menus/pinning, API V3 host, and
UI Gallery are also active. The production Gallery currently has 59
model-ready fixtures: 12 foundation/shared fixtures and 47 gameplay/storage
fixtures.

Fresh aggregate verification on 2026-08-13:

- Lua syntax: 173 checks;
- contracts: 697 checks;
- foundation: 117 checks;
- shared UI: 43 checks;
- Party/Summary: 53 checks;
- Pack/Pokedex/Trainer/Save: 65 checks;
- Naming/storage: 112 checks;
- production Gallery: 779 checks;
- product smoke, core lock, scaffold, and sandbox scans all passed;
- sandbox scan covered 143 product and vendored-core Lua files.

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

### Implemented and focused-tested, but not integrated

The following 0.3 work exists in source and passes its focused suites, but is
intentionally absent from `src/product.lua`, production Gallery conversion,
and `tests/run_all.lua`. These screens therefore remain native in real
gameplay right now.

1. Pokegear and Map Radio

   - `Gen2Pokegear`
   - `Gen2MapRadio`
   - 165 focused checks pass.
   - Covers the strip, clock, map, Fly, radio, phone lists/submenus/calls,
     no-signal states, and wall radio.
   - `CallerBox` must remain native because the current public host seam does
     not expose a proven exact identity for it.

2. Services and commerce

   - `Gen2MartMenu`
   - `Gen2ScriptMenu`
   - `Gen2BankOfMom`
   - `Gen2ContestMenu`
   - `Gen2DayCareMenu`
   - `Gen2HeldItemMenu`
   - `Gen2ElevatorMenu`
   - `Gen2MoveDeleter`
   - 240 focused checks pass.

3. Mail and specialty displays

   - `Gen2MailCompose`
   - `Gen2MailMenu`
   - `Gen2MailRead`
   - `Gen2MailboxMenu`
   - `Gen2DecorationMenu`
   - `Gen2TradeMenu`
   - `Gen2NamePick`
   - `Gen2InitClock`
   - `Gen2Diploma`
   - `Gen2PhotoStudio`
   - `Gen2UnownPrinter`
   - `Gen2HallOfFame`
   - 412 focused checks pass.
   - Hall of Fame support is viewer/display only. Induction remains native.
   - Trade animation and unproven party-picker stacks remain native.

### Required fixes before integrating 0.3

Correct three central contract validators in:

`G:\dev\misc\gen2-clean-ui\mods\gen2_clean_ui\src\contracts\families\services.lua`

- `Gen2MartMenu`: accept zero-based `martId >= 0`; the current validator
  incorrectly requires `>= 1`.
- `Gen2MailCompose`: accept host coordinates `row = 0..5` and `col = 0..9`;
  the current validator incorrectly expects one-based values.
- `Gen2TradeMenu`: accept host IDs `0..5`; the current validator incorrectly
  requires `>= 1`.

Add exact host-shape regression cases to the aggregate contract tests before
wiring any presenter.

Also review the shared contract metadata for `gold.CallerBox`. It currently
looks supported/pending, but production must describe it as native/pending
with an explicit missing-identity reason unless the host first gains a proven
public exact-class seam.

### Recommended next work sequence

1. Fix the three zero-based validators and add aggregate regression tests.
2. Run the existing aggregate and all three focused suites.
3. Extend `src/product.lua` to load/register:
   - Pokegear and MapRadio models/presenters;
   - services/commerce models/presenters;
   - mail/specialty models/presenters;
   - all corresponding production IDs and Gallery fixtures.
4. Extend `src/gallery/catalog.lua` conversion routing so every new fixture
   uses the same production presenter as gameplay.
5. Add these focused runners to `tests/run_all.lua`:
   - `run_pokegear_tests.lua`
   - `run_services_commerce_tests.lua`
   - `run_mail_specialty_tests.lua`
6. Update README and Gen2 contract documentation to distinguish newly
   integrated presenters from native/deferred ones.
7. Run aggregate tests, focused tests, scaffold, sandbox, core-lock, and
   `gen2check --strict --notes`.
8. Smoke-test real Gold routes using the local launcher. Do not suppress a
   source screen unless its complete visible stack renders successfully.

Inspect converter signatures before wiring. Existing modules are expected to
use `Presenter.convert(model)` for Pokegear/MapRadio and
`Presenters.convert(screenId, model)` for grouped services and mail/specialty
families; verify this from source rather than assuming it.

## `gen1-clean-ui`

Path: `G:\dev\misc\gen1-clean-ui`

- The repository has no first commit; the scaffold is untracked.
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

Only the integrated screen list above is expected to modernize in this local
build. The three 0.3 groups should remain native until their central validators
are corrected and integration is complete.

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
Continue Gen2 first. The immediate task is to fix the three zero-based Gen2
validators (Mart, Mail Compose, Trade), add exact host-shape regression tests,
then safely integrate the focused-tested Pokegear/MapRadio, services/commerce,
and mail/specialty families into product composition, production Gallery
conversion, and tests/run_all.lua. Keep CallerBox native without a proven exact
host identity. Preserve fail-open behavior and complete-stack suppression
proofs. Run all aggregate, focused, sandbox, core-lock, scaffold, gen2check,
and relevant host API tests. Update docs to reflect what is truly active.

Do not commit, push, tag, publish, create remotes, archive repositories, delete
stashes/backups, or overwrite unrelated dirty work. Use safe local tools without
asking repeatedly. Use no more than four subagents and close them when done.
Keep main.lua tiny and all implementation modular.
```
