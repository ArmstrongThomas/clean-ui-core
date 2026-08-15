# Clean UI Session Handoff

Last updated: 2026-08-15

This is the continuation document for the Clean UI ground-up rebuild. Read
this file and [the authoritative rebuild plan](CLEAN_UI_REWORK_PLAN.md) in full
before changing code. The plan owns product scope and architecture; this file
records the current workspace state, what is actually integrated, and the next
safe work sequence.

## Latest session update (2026-08-15, battle architecture deferred)

- The experimental Core battle scene-frame, renderer-expansion, ownership-latch,
  and responsive battle-envelope work has been archived after the Gen2 live
  battle UI failed to progress reliably beyond intro and could expose native
  UI during refresh/redraw boundaries.
- The active Core tree no longer treats that architecture as a supported
  battle contract. Gen2 battle remains native/deferred, and a future rewrite
  must begin from newly audited host V3 seams rather than restoring the
  archived renderer or latch incrementally.
- The retained Core changes in this slice are non-battle: shared naming
  presentation data, released-host asset/settings compatibility, and their
  deterministic coverage. No launcher or host repository was changed.

## Latest session update (2026-08-14, cross-generation V3 contracts)

- V3 contracts now accept `all_generations = true` as a universal
  applicability declaration. The same screens, actions, and surfaces can be
  registered by both Clean UI products without repeating `games`.
- The flag is validated atomically, preserved in the editor-safe contract
  catalog, and covered by Core registration tests on both `gen1` and `gen2`.
  The launcher manifest still lists eligible products because manifest
  filtering happens before V3 host discovery.
- Both product vendors are synced to Core `0.1.0-alpha.12-local` at
  `cfed683ff907a1cad57331058ebc6f23bf4f5110`; no commit or push was made.

## Latest session update (2026-08-14, stable battle envelope and OAM handoff)

- Core battle layout now reserves one phase-independent envelope sized for the
  four-move state, keeping the field, cards, sprites, and arena stationary as
  the command menu and move list open. Player cards render HP above EXP.
- The live OAM crop-index multi-return regression is fixed. Optional effect
  sheet failures skip only the unavailable effect tile, so intro/send-out,
  move, item, and Poké Ball frames no longer expose native battle UI because
  of a renderer exception. Full source timing/scanline parity and complete
  child-stack ownership remain explicit V3 gaps.
- No commit or push was performed.

## Latest session update (2026-08-14, official V3 catalog)

- Gen2 now publishes `gen2_official_catalog` through the API V3 contract
  catalog. It is a callback-free, metadata-only inventory of all 51 exact host
  screen IDs, including support state, milestone, and native fallback reason.
- This closes the editor/diagnostic visibility gap without claiming new V3
  replacements: the 41 production presenters and 10 native boundaries remain
  unchanged, and no commit or push was made.

## Latest session update (2026-08-14, first-class device/map V3 kinds)

- Core now validates and renders portable `device` and `map` presentation
  models, including responsive handheld descriptors, dense landmark/Fly rows,
  native tilemap geometry, and cursor-sheet metadata. The editor fixture covers
  both direct kinds without callbacks.
- Gen2 Pokegear now emits `kind="device"` for its shell/cards and
  `kind="map"` for Map/Fly, while preserving source-owned input and fail-open
  asset behavior. The former product-scoped menu-extension gap is closed;
  live animation timing/source identity and complete child-stack ownership
  remain the next V3 gap. No Studio files, commits, or pushes were changed.

## Latest session update (2026-08-14, V3 gap register)

- The next roadmap boundary remains explicit in `API_V3.md` and the rebuild
  plan: live animation timing/source identity and complete child-stack
  ownership are not yet portable V3 capabilities.
- The V3 animation kind remains a deterministic visual-frame contract, not a
  scheduler or complete child-stack ownership contract. Live battle intro,
  move/item, and Poké Ball frames now use the detached V3 OAM handoff; source-
  owned timing/identity, full scanline/background parity, faint/experience
  progression, and complete child-stack ownership remain explicit gaps.
- No Studio editor files were changed in this slice. The remaining animation
  capability must reach editor parity before it is advertised as supported;
  no commit or push was made.

## Latest session update (2026-08-14, native boundary guard)

- Gen2 product smoke now asserts the exact ten native-by-design official IDs,
  including the Copyright, Game Freak Presents, Gold/Silver Intro, and Title
  screens whose experimental raster presenters showed corruption. The 41/10
  split is therefore protected against accidental presenter re-registration;
  no Studio files or runtime ownership boundaries changed.

## Latest session update (2026-08-14, battle animation conformance coverage)

- Gen2 battle regression coverage now verifies that live move/item/Poké Ball
  animation frames remain detached data inside the canonical V3 `battle` model,
  including source sheet geometry and OAM objects. The regression suite also
  covers the no-native-fallback crop path. This protects the current
  product-scoped frame-data extension without pretending that Core owns battle
  timing or source identity.
- The V3 gap register remains authoritative: first-class `device`/`map` kinds
  and a portable live-animation scheduler/source seam still require a future
  Core + validation + responsive renderer + Gallery + Studio milestone.
- No commit or push was performed.

## Latest session update (2026-08-14, provider V3 gate)

- Gen2's provider now fail-opens a presenter before suppression unless its V3
  model carries the canonical `clean_ui.v3.presentation.v1` schema,
  `apiVersion=3`, and a non-empty presentation `kind`. Core remains the final
  full-shape validator; this earlier product boundary improves diagnostics and
  prevents malformed presenter markers from reaching offscreen composition.
- Contract regression coverage proves both rejection of an incomplete marker
  and acceptance of a canonical V3 menu. No Studio files, commits, or pushes
  were made.

## Latest session update (2026-08-14, Gallery V3 validation)

- Gen2 product smoke now validates every model-ready production Gallery fixture
  with the vendored Core V3 model validator, in addition to checking the
  canonical schema, API version, and kind markers. This verifies that the
  callback-free catalog/editor examples use the same presentation contract as
  gameplay presenters rather than only being function-free tables.
- No Studio files, commits, or pushes were made.

## Latest session update (2026-08-14, manifest-driven release smoke)

- Gen2 release-tool smoke now reads the manifest version and automatically
  resolves the matching `docs/releases/v<version>.md` blurb, archive name, and
  tag. It also verifies that the rendered notes contain that exact curated
  body, the generated change section, and the archive hash.
- This removes the last hard-coded `0.2.0` assumption from the release smoke
  path. No Studio files, commits, or pushes were made.

## Latest session update (2026-08-14, scaffold release-note gate)

- Gen2 scaffold verification now requires a non-empty curated release blurb
  matching the manifest version. Release-note maintenance is therefore part of
  the normal local/CI validation path, not only the publication job.
- No Studio files, commits, or pushes were made.

## Latest session update (2026-08-14, native boot correction)

- Real-host verification exposed raster-strip corruption in the experimental
  V3 Copyright, Game Freak Presents, Gold/Silver Intro, and Gold title
  presenters. Those four official screens are now explicit native boundaries;
  their production presenters are not registered for gameplay. Their
  callback-free V3 fixtures remain editor experiments only.
- Gen2 now has 41 integrated official presenters and 10 explicit native
  boundaries. Contract, product-smoke, release, and sandbox documentation was
  updated to match; no commit or push was made.

## Earlier session update (2026-08-14, continued)

- Core now has a shared strict `v3.panel` validator for panel screens. It checks
  dense component arrays, unique IDs, known fields, nested option/field/footer
  list schemas, and type-specific required payloads before atomic registration;
  Core suite coverage is now 255 checks per suite.
- Studio mirrors this panel contract locally for authoring/export diagnostics,
  and its suite now passes 54 checks. Gen2's vendored Core copy and editor
  smoke fixture were updated to the same panel shape.
- Core and Studio now enforce the same complete V3 animation-sprite descriptor
  shape: asset path, placement rectangle, integer crop, flips, and palettes
  are validated before drawing. The Gen2 product smoke validates every direct
  screen published by its callback-free V3 catalog, making the catalog a
  real API conformance target rather than only a sample list.
- The next source-complete Gen2 cinematics, Egg Hatch, Evolution, and
  Gold/Silver Intro, now use the canonical V3 animation seam. The product emits
  callback-free
  `gen2_cinematic_animations` catalog examples while preserving source-owned
  beat timing and input, extracted art/palettes, crack frames, blackout flash,
  and expanding light-circle particles.
- The Gen2 product now has 45 integrated official V3 presenters and 6 explicit
  native boundaries. The cinematic adapters fail open when their live art/data
  cannot be proven, and their production contract tests cover both Egg Hatch
  phases plus Evolution flash/reveal phases.
- The Gen2 focused suite passes syntax for 201 files, 740 contract checks,
  product smoke, and the full downstream presenter, Gallery, and responsive
  matrices. No commits or pushes were made during this slice.

## Latest session update (2026-08-14)

- Pokegear shell geometry now chooses a landscape 16:9 device on wide
  viewports and a portrait 9:16 device on tall viewports, so landscape screens
  no longer render a tiny phone surrounded by unused space.
- Pokegear Fly uses a responsive split surface with the extracted native map
  above the destination list; selected landmarks use the native cursor-sheet
  artwork when the host asset loader is available.
- API V3 now advertises `contract_catalog = "0.1.0"`. The public host exposes
  `listContracts(filter)` with copied declarative descriptors and sorted action
  IDs, intentionally omitting runtime callbacks so an editor can inspect live
  registrations safely.
- The V3 shell can preview panel descriptors with labels, dropdowns, buttons,
  named actions, modal responses, and close results. The
  `examples/ui-editor-fixture` is the deterministic WIP target for the
  standalone editor; it is not itself the standalone editor.
- V3 registration now rejects malformed or missing screen-component action
  references atomically, before a contract can enter the registry; the old
  registration remains active on a failed replacement.
- V3 now validates direct presentation screens at registration and action
  boundaries: `menu`, `dialogue`, `choice`, `battle`, and `animation` require the canonical
  `clean_ui.v3.presentation.v1` schema, `apiVersion = 3`, and a non-empty
  preset. Invalid replacements and invalid action results fail without
  changing the active screen.
- V3 direct presentation screens now cover `menu`, `dialogue`, `choice`,
  `battle`, `animation`, `device`, and `map` models. The Gen2 product's Main Menu, Start Menu, Options, TextBox,
  ChoiceBox, Party, Summary, Pack, Pokegear, Map Radio, Pokedex, Trainer Card,
  Save, and Battle presenters emit the canonical
  `clean_ui.v3.presentation.v1` shape and register callback-free
  `gen2_foundation_menus`/`gen2_shared_dialogue`/`gen2_party_menus`/
  `gen2_inventory_device`/`gen2_progress_menus`/`gen2_battle_preview`/
  `gen2_battle_animations`/`gen2_boot_animations`/
  `gen2_cinematic_animations`/`gen2_extended_menus`
  contracts for editor/catalog
  inspection; source-owned
  input and timing remain
  unchanged.
- The shared presentation runtime now reuses one canonical V3 model validator
  at the final pre-measure/render boundary. A direct model with the wrong
  schema, API version, kind, preset, or required payload shape fails open
  before it can suppress native UI. Its ordered payloads are also checked as
  dense arrays with the expected item types, and present selection fields must
  be positive integer indices; legacy/custom surfaces remain their own
  explicitly validated compatibility path.
- The standalone Studio bridge now boots and installs the same core source when
  it is beside the editor. Core exposes data-only `validateV3`, `measureV3`,
  `drawV3`, and `renderV3` embedding methods, while the existing Studio bridge
  preserves callback-free direct `menu`, `dialogue`, `choice`, `battle`, and
  `animation` models during catalog import and export instead of coercing them
  into empty panels. The connected Core fixture catalog now exercises all
  seven direct kinds; Studio parity for the new `device`/`map` kinds remains
  with the separate Studio workstream.
  pass `51` checks and core suites pass `250` checks each after this bridge
  slice.
- Core dependency verification now includes the V3 shell's
  `foundation.data` edge. Core suites pass `250` checks each, including a
  real load/validation/catalog check for the checked-in editor fixture, and
  the Gen2 product suite passes after the vendored-core sync.
- The Gen2 product now enforces the canonical V3 presentation model for all
  41 integrated official production presenters. `Gen2BattleTransition` emits
  a transparent V3 animation overlay over the source-owned world, and Credits
  remains on its separately audited V3 animation path. The Gen II Copyright
  splash, Game Freak Presents splash, Gold/Silver intro, and Gold title screen
  remain explicitly native/source-owned until their raster seams are proven.
  Core/Studio support ordered V3 animation text layers, cropped normalized OAM
  sprites, and normalized filled circles for the proven cinematic examples;
  native-by-design records and unproven child stacks remain explicit
  boundaries. Egg Hatch is covered by the same canonical animation seam.
- Delegated work is capped at four sub-agents for this task. The primary agent
  must review and integrate every delegated result before completion.
- No screenshots or visual-audit captures are part of the source or release
  artifacts; they remain local testing evidence only.

## Latest session update (2026-08-14)

- The next source-complete Gen2 cinematic, Game Freak Presents, now uses the
  V3 animation seam: extracted splash tile sheets, palette rotation, sparse
  background tiles, live OAM crops, hardware flips, and offscreen normalized
  coordinates remain data-only and responsive. The Gen2 product now has 42
  integrated official V3 presenters and 9 explicit native boundaries.
- Core V3 animation sprites accept an explicit `normalized` flag so source
  coordinates just outside the viewport remain portable instead of being
  misread as pixel coordinates. Core suites pass 247 checks each; no commits
  or pushes were made during this slice.

## Previous session update (2026-08-13)

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
- Gen2 Clean UI `v0.1.0` is now published with its updater-ready archive;
  the GitHub asset digest is recorded in the product release status and
  changelog.
- The release publication workflow is fixed by product commit `115e1bb`, which
  binds `GH_TOKEN` for the `gh release create` step.
- Gen2 release validation now also runs an isolated release-tool smoke that
  rebuilds the archive twice, checks its deterministic hash and root ordering,
  verifies the manifest/version and vendored-core entries, then removes its
  temporary copy. The local smoke currently passes with the recorded archive
  digest `2B6ECE65D7A52B8EFE372FA1A54CD06BAD3203D2BFAC68373FF2C36DFA129EA2`.
- The Gold route validator now resolves the platform-specific LOVE cache when
  `GOLD_CACHE` is not provided; the Windows Gold cache passes its 4 shape,
  geometry, and milestone checks through the LOVE runner.
- The Gold route harness now vetoes live slot writes by default; explicit
  `POKEPORT_GOLD_ALLOW_SAVE=1` is required to opt into a real slot write.
  Checkpoints remain separate and usable for retry/resume work.
- The Gen2 Hall of Fame ceremony now routes its in-ceremony SaveGameData call
  through the owning game's canonical writer instead of calling the Gold
  serializer directly. This makes the existing `save.write` veto effective at
  that boundary and is covered by the Gen2 Hall of Fame continuation fixture.
- A Champion route attempt reached `EVENT_BEAT_CHAMPION_LANCE` and the
  `18.20` Hall of Fame boundary after seven retries, but remains progression
  evidence only because the long replay contained two pre-League harness
  teleports, one `13.g` route failure, and five bounded travel-loop
  recoveries. The post-fix no-save replay preserved the original Gold slot
  byte-for-byte, but did not independently re-prove Champion before its retry
  budget expired. Retained logs are
  `G:\dev\misc\gold-route-18.20-champion-finish.log` and
  `G:\dev\misc\gold-route-18.20-champion-no-save-fixed.log`.
- A clean ephemeral League-segment replay now starts from the preserved full-
  party `18.4c` checkpoint and reaches `18.20` after a real Champion win, with
  zero harness teleports, zero travel-loop give-ups, zero route failures, and
  eight bounded battle retries. The route harness holds the post-credits title
  reset in memory while vetoing live saves; the original 4,345-byte Gold slot
  remains unchanged. Retained log:
  `G:\dev\misc\gold-route-18.20-champion-ephemeral-no-save.log`.
- A single continuous ephemeral replay now covers the untouched initial Gold
  slot through the Champion and `18.20` Hall of Fame boundary. It records zero
  harness teleports, zero travel-loop give-ups, zero route failures, one real
  Champion win, and eight bounded battle retries; the live slot remains the
  original 4,345 bytes. Retained log:
  `G:\dev\misc\gold-route-18.20-full-ephemeral-no-save.log`.
- The Gold route bot now treats live `SMASHABLE_ROCK` objects as Rock Smash
  interactions: it uses the real A-press script when a reachable rock blocks
  a planned route, then re-plans before entering the warp.
- Gold connected-edge navigation now validates each destination landing strip
  before selecting a source border cell. The Route 37 -> Ecruteak probe now
  chooses `(8,0)` and lands at `(18,35)`; the prior nearest-cell choice landed
  in scenery and could not cross.
- Gold route recovery now only considers live sighted trainers with an attached
  trainer record, skips beaten trainers, and caps failed interactions. This
  removes the false-positive recovery loop observed on an ordinary Route 36
  NPC. A defeated trainer that leaves the player boxed against its approach
  cell now triggers a bounded retreat and re-plan.
- Gold route recovery also escapes fixed map-object blockers such as Route 36's
  fruit tree when the player is left on its approach cell. Direct route
  preferences now keep Ecruteak on Route 36 -> Route 37 and Blackthorn Gym
  objectives on Route 45 -> Blackthorn City. A fresh-slot, no-write replay
  reaches `13.29a0` at row `264/315` and pushes the first Blackthorn Gym 2F
  boulder with zero harness teleports and zero travel-loop give-ups; the
  retained log is `G:\dev\misc\gold-route-13.29a0-final-replay.log`, and the
  Gold save remained unchanged.
- Connected-edge landing validation now recognizes a Surf-capable water border
  as a shore-to-water transition while still on foot. Focused native LOVE seam
  checks pass for boarding Surf and for an already-Surfing crossing; this is the
  targeted fix for the Cianwood City -> Route 41 failure.
- Region-aware travel now carries the intended destination region through edge
  hops and filters candidate landings with a static forward/reverse destination
  fill. A native behavior check excludes a disconnected destination pocket as
  expected. Arrival-warp re-arming now precedes edge-target selection, live
  source-region exits can replace stale pre-warp hints, and a failed border
  walk is rescanned after dynamic trainer recovery.
- The patched host's public `mod.options:set` contract now has focused `74/74`
  regression coverage across toggle, choice, number, and text values,
  persistence, live/profile updates, post-write events, and atomic invalid
  writes. This proves the local implementation only; the release floor still
  waits for the first official tagged host carrying the API.
- The current Gen2 product working tree also rebuilds its deterministic
  153-entry `gen2_clean_ui-0.1.0.zip` locally with SHA-256
  `2B6ECE65D7A52B8EFE372FA1A54CD06BAD3203D2BFAC68373FF2C36DFA129EA2`.
  This is an unpublished validation artifact and does not replace the
  recorded GitHub asset.
- Real Gold battle-host probes now pass trainer intro/sprite scaling, battle
  Pack refusal and return, forced-switch Party selection, and catch through
  post-catch state. Visual evidence is retained under
  `G:\dev\misc\gen1recomp-grandmas-kitchen\tests\shots\battle-audit*`;
  battle-owned Pack/Party and post-catch child stacks remain native by design.
- The real post-catch nickname path now passes end to end: YES opens the Clean
  UI naming keyboard, directional input enters `CATCH`, and the settled party
  record retains the nickname. Evidence is retained under
  `G:\dev\misc\gold-battle-nickname-normal`.
- The full-party catch boundary also passes on the real host: with six party
  members, a caught Pidgey is inserted at slot 1 of the active PC box while the
  party remains full. Evidence is retained under
  `G:\dev\misc\gold-battle-boxfull-next`.
- Additional native-boundary probes pass on the same host: the EXP-bar crawl
  reaches level 10 through intermediate widths, and the naming/party flow
  passes full-name entry, spaces, NPC-held item display, and TAKE-to-bag
  behavior. These progression and child-stack paths remain native by design.
- Native battle-boundary smoke also passes all 17 sampled move animations, a
  benched REVIVE, and ETHER through the real move-selection screen. The host
  PP dispatch now normalizes the 1-based move index returned by both field and
  battle selectors; the probe explicitly honors Gold's persistent last-picked
  party cursor.
- Focused Gen 2 item coverage is green: 104/104 field checks and 94/94 battle
  checks. The battle fixture now supplies the A edges required by PromptButton
  text waits, so its headless turn drain matches the native host contract.
- The native battle-item probe was rerun against the established
  `pokemon-love2d` Gold cache identity and exited cleanly with both REVIVE on a
  benched mon and ETHER through move selection passing. The original Gold save
  remained byte-for-byte unchanged.
- The deferred battle-child boundary was re-verified after the route save
  lifecycle fix: the live move-learning prompt replaced TACKLE with QUICK
  ATTACK in slot 1, and the battle Pack revived a benched TOTODILE before
  restoring PP through the move list with ETHER. These drivers kept the stable
  battle frame on the Clean UI boundary while leaving the child stacks native;
  the Gold slot remained byte-for-byte unchanged. Move-learning screenshots
  are retained under `G:\dev\misc\gold-battle-learn-next`.
- Additional real-host child-state smoke passes Gold evolution, including
  B-cancel, PC move-to-box, Pack item submenu/toss, Egg summary rendering, and
  the live battle move-learning prompt/list path through `BattleState`. These
  remain explicit source-owned seams and do not claim stable-frame replacement.
- The evolution driver now keys B cancellation to the native flash/wait phase
  instead of a local screenshot-loop counter. The explicit rerun passes both
  Chikorita -> Bayleef completion and held-B cancellation back to Chikorita;
  evidence is retained under
  `G:\dev\misc\gold-evolution-next-fixed3`, with the original Gold save still
  byte-for-byte unchanged.
- Real-host Summary coverage now captures the party list, all three pages,
  poisoned and dual-type cases, and move descriptions. The naming/trade probe
  passes full rival-name keyboard edges, Kyle's named BITTER BERRY Onix, and
  TAKE-to-bag behavior; evidence is retained under
  `G:\dev\misc\gold-summary-next` and
  `G:\dev\misc\gold-naming-trade-next`.
- The native Egg boundary passes its full crack/wobble/burst/fragment sequence
  and the Sentret hatch-state Summary page. Evidence is retained under
  `G:\dev\misc\gold-egg-next`; hatch and evolution animation paths remain
  native by contract.
- The real-host faint/forced-switch probe also passes: the fainted sprite exits
  its frame, the native party list rejects the fainted slot, accepts the healthy
  replacement, and the trainer sends out its next Pokémon. The animation and
  child list remain native by contract.
- Latest retained faint/forced-switch frames are under
  `G:\dev\misc\gold-battle-faint-next`.
- Follow-up no-write Gold probes, each started from the fresh slot, passed
  `12.0c` (Ecruteak), `12.9b` (Radio Tower Executive), `12.33` (Radio Tower
  clear), `13.10b` (Ice Path HM07 acquisition/teaching), `13.11` (Ice Path
  B1F), and `13.12a` (the first Strength boulder push), reaching route row
  `234/315` in the clean probe; the bot summary reported `233/315` completed
  after optional misses. Two independent no-write probes also completed
  `13.12b` (the full 11-tile second boulder push), reaching row `235/315`, but
  used one or two pre-Ice-Path harness teleports. A targeted no-write Love2D
  probe now clears the Dark Cave Violet rocks at `(7,14)` and `(16,14)` through
  the real Rock Smash script and enters Route 46 from `(35,33)` without a
  teleport shortcut. These are separate gameplay probes rather than a saved
  resume from `11.44`; the original save remained untouched. A subsequent full
  no-write replay from the untouched initial save reached `13.12c` with no
  Dark Cave shortcut. The targeted Route 37 -> Ecruteak crossing and later
  full-route crossings are natural; the latest replay also crossed Route 42's
  east seam at `(59,6)` without a Route 42 shortcut, selected Lake of Rage's
  main region for both travel and the Red Gyarados battle, completed the
  Mahogany staircase scene, and reached `13.12c` with zero teleport shortcuts.
  The retained log is
  `G:\dev\misc\gold-route-13.12c-lake-battle-region-fixed-replay.log`.
- Two additional fresh-slot, no-write Gold replays now cross the remaining
  first Ice Path B3 pushes: one reaches `13.12d`, and the complete replay
  reaches the flag-backed `13.12` objective at route row `239/315`. The
  retained logs are `G:\dev\misc\gold-route-13.12d-boundary-replay.log` and
  `G:\dev\misc\gold-route-13.12-first-boulder-complete.log`; the original
  save remains untouched.
- A further fresh-slot, no-write replay completes the second Ice Path B3
  sequence through `13.13a`–`13.13d` and the flag-backed `13.13` objective at
  route row `244/315`. The retained log is
  `G:\dev\misc\gold-route-13.13-second-boulder-complete.log`.
- Another fresh-slot, no-write replay completes the third Ice Path B3 sequence
  through `13.14a`–`13.14c` and the flag-backed `13.14` objective at route row
  `248/315`. The retained log is
  `G:\dev\misc\gold-route-13.14-third-boulder-complete.log`.
- A fresh-slot, no-write replay completes the fourth Ice Path B1F sequence
  through `13.15a`–`13.15d` and the flag-backed `13.15` objective at route row
  `253/315`. The retained log is
  `G:\dev\misc\gold-route-13.15-fourth-boulder-complete.log`.
- The Gold route planner now chains an Ice Path slide after a ledge jump,
  matching the live host's movement semantics. A fresh-slot, no-write replay
  reaches Blackthorn through `13.26` and completes the `13.27` heal at route
  row `255/315` with zero harness teleports. The retained log is
  `G:\dev\misc\gold-route-13.27-blackthorn-heal-fixed.log`.
- The same fresh-slot, no-write route reaches optional `13.26b`, buying two
  FULL RESTOREs at Blackthorn for ¥6000. The retained log is
  `G:\dev\misc\gold-route-13.26b-full-restores.log`.
- The fresh-slot, no-write route then satisfies the `13.g` level gate and
  reaches `13.28` at route row `258/315` (Blackthorn Gym 1F) with zero
  harness teleports. The retained log is
  `G:\dev\misc\gold-route-13.28-blackthorn-gym.log`.
- The next fresh-slot, no-write replay reaches `13.28b` at route row
  `259/315` (Blackthorn Gym 2F) with zero harness teleports. The retained log
  is `G:\dev\misc\gold-route-13.28b-gym2f.log`.
- A follow-up fresh-slot, no-write replay exercises the Gym trainer slice:
  `13.28c` reaches the live Fran/Cody battles, `13.28d` confirms the Fran
  event, and `13.28h` heals at Blackthorn's Pokécenter (`262/315`). It uses
  zero harness teleports. The retained log is
  `G:\dev\misc\gold-route-13.28h-gym-heal.log`.
- The next fresh-slot, no-write replay reaches `13.29a0` at row `264/315` and
  pushes the first Blackthorn Gym 2F boulder. The replay has zero harness
  teleports and zero travel-loop give-ups after the fixed-object recovery and
  direct Route 36/Ecruteak and Route 45/Blackthorn preferences; its retained
  log is `G:\dev\misc\gold-route-13.29a0-final-replay.log`, and the Gold save
  remained unchanged.
- The next fresh-slot, no-write replay completes the remaining Blackthorn Gym
  2F boulder puzzle through `13.29a`–`13.29f`, reaching route row `272/315`
  with zero harness teleports and zero travel-loop give-ups. The retained log
  is `G:\dev\misc\gold-route-13.29f-boulders.log`; the Gold save remained
  unchanged.
- Gold route battle healing now sizes items from the active battle Pokémon
  after a switch rather than party slot 1, preventing repeated no-effect item
  turns on a healthy replacement. A fresh no-write replay defeats Clair at
  `13.30` (route row `274/315`) with zero harness teleports, zero travel-loop
  give-ups, and zero no-effect item retries. The retained log is
  `G:\dev\misc\gold-route-13.30-clair-fixed.log`; the Gold save remained
  unchanged.
- A further fresh-slot, no-write replay continues through the Dragon's Den
  boundary: `13.32` arrival, `13.33` Dragon Fang, and the flag-backed
  `13.33b` `ENGINE_RISINGBADGE` check at route row `277/315`. The replay used
  no harness teleport shortcut, recorded no travel-loop give-up, and recorded
  no no-effect item retry. Clair required one bounded retry before her defeat;
  the retained log is
  `G:\dev\misc\gold-route-13.33b-risingbadge.log`, and the Gold save remained
  unchanged.
- The Gold route now models HM07 Waterfall as a real climb from shore/current
  tiles and adds an explicit full-party heal after the Dragon's Den badge
  check (`13.33c`) before Route 27's trainer gauntlet. A second fresh-slot,
  no-write replay reaches the Victory Road gate at `16.55` (route row
  `290/316`), including the Tohjo Falls climb and Route 27 -> Route 26 seam,
  with zero harness teleport shortcuts and no route-row failures. One bounded
  travel-loop recovery occurred while the pre-gate heal searched from the
  Victory Road Gate; the retained log is
  `G:\dev\misc\gold-route-16.55-victory-gate-healed-2.log`, and the Gold save
  remained unchanged.
- The Section 16 route now uses the documented Route 26 heal house (`16.43b`)
  before the Victory Road trainer run. A fresh-slot, no-write replay reaches
  the Victory Road rival at `17.15` (route row `294/317`) and defeats Silver
  with zero harness teleport shortcuts, zero route-row failures, and zero
  no-effect item retries. Two bounded travel-loop recoveries occurred early
  in the fresh replay; the retained log is
  `G:\dev\misc\gold-route-17.15-rival-healhouse.log`, and the Gold save
  remained unchanged.
- A fresh-slot, no-write replay now reaches the Pokémon League entrance at
  `18.4` (route row `295/317`) after the Victory Road rival, with zero harness
  teleport shortcuts and no route-row failures. Two bounded travel-loop
  recoveries occurred during the long fresh replay; the retained log is
  `G:\dev\misc\gold-route-18.4-league-entrance.log`, and the Gold save remained
  unchanged. This proves League entry only; the one-way Elite Four gauntlet
  remains the next host smoke boundary.
- League preparation now passes through `18.4c` (route row `301/317`): the
  Victory Road grind reaches its configured lead-level gate, the pre-gauntlet
  shop restocks HYPER POTION, FULL RESTORE, and REVIVE, and the party heals at
  Indigo Plateau. The fresh no-write replay used zero harness teleports and
  zero travel-loop give-ups; its only route failure was the pre-existing early
  optional `01.6` row. The retained log is
  `G:\dev\misc\gold-route-18.4c-league-prep.log`, and the Gold save remained
  unchanged.
- The first one-way Elite Four battle now passes: a fresh replay reaches
  `18.9` (route row `304/317`) and defeats Will with no route-row failure and
  no no-effect item retry. That long replay had one pre-League Dark Cave
  harness fallback and four bounded early travel-loop recoveries; the retained
  log is `G:\dev\misc\gold-route-18.9-will.log`, and the Gold save remained
  unchanged. Koga, Bruno, Karen, Lance, and the Champion remain unproven.
- The Route 26 heal-house row now suppresses the generic pre-row heal, so the
  real teacher interaction is not preceded by a detour through the Slowpoke
  Well pocket. A fresh no-write replay then defeats Will (`18.9`), Koga
  (`18.11c`), and Bruno (`18.13c`) with zero harness teleports, zero
  travel-loop give-ups, zero route-row failures, and zero no-effect item
  retries. The retained log is
  `G:\dev\misc\gold-route-18.13c-bruno-healhouse-fixed.log`, and the Gold
  save remained unchanged. Karen, Lance, and the Champion remain unproven.
- A fresh no-write replay continues the one-way gauntlet through Karen
  (`18.15c`, route row `313/317`) after Bruno, with zero harness teleports,
  zero travel-loop give-ups, zero route-row failures, and zero no-effect item
  retries. The retained log is
  `G:\dev\misc\gold-route-18.15c-karen.log`, and the Gold save remained
  unchanged. Lance and the Champion remain unproven.

## Working rules

- Work under `G:\dev\misc`.
- Do not commit, push, tag, publish, create remote repositories, or archive a
  repository unless Tommy explicitly asks.
- Preserve every dirty worktree, stash, backup, and user-authored change.
- Use safe local diagnostics, tests, and LOVE tools without repeatedly asking
  for approval.
- This task may use at most four delegated sub-agents in parallel. Assign each
  sub-agent a disjoint write scope, and require the primary agent to review
  and integrate every result before it is treated as complete.
- Keep the rewrite modular. Product `main.lua` files remain tiny bootstraps;
  screen-family work belongs in focused modules.
- Be precise about status: "implemented and focused-tested" does not mean
  "integrated into gameplay."
- Keep native rendering visible whenever a contract, stack, or presenter is
  not proven complete.

## Repository map

| Repository | Role | Current state |
|---|---|---|
| `G:\dev\misc\clean-ui-core` | Shared, non-installable runtime | Core runtime and tests are committed locally at `cfed683`; local snapshot `0.1.0-alpha.12` is in progress |
| `G:\dev\misc\gen2-clean-ui` | Installable Gold product | Active product; `v0.1.0` is published, with an uncommitted release-document refresh in the local tree |
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
   unproven animation-heavy sequences and battle-owned child stacks remain
   explicit native/deferred boundaries
   through Gen2 1.0.
- Gen1 battle is a later wide-only 640x360 presenter. Three-dimensional battle
  HUD ownership remains external.

## `clean-ui-core`

Path: `G:\dev\misc\clean-ui-core`

- Branch: `main`
- HEAD: `cfed683` (`0.1.0-alpha.10`, previous committed base; local snapshot is `0.1.0-alpha.12`)
- Core version in source: `0.1.0-alpha.12`
- The modular implementation, tests, examples, scripts, README, license, and
  supporting documentation are committed locally. The core snapshot is locally
  tagged and is pinned by the Gen2 0.1.0 product.
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

The Gen2 product lock points to the local `0.1.0-alpha.12` snapshot at
`cfed683ff907a1cad57331058ebc6f23bf4f5110`. The Gen2 product's first public
release has been published; Gen1's lock remains an independent future task.

## `gen2-clean-ui`

Path: `G:\dev\misc\gen2-clean-ui`

- The product repository's last published commit remains `115e1bb`; no commit
  or push was made during the current V3 migration slice.
- Manifest version: `0.2.0`.
- Manifest is Gen2-only, API 2, overhaul profile, priority 100,
  `affects_link: false`, experimental, and conflicts with `gen1_modern_ui`.
- The published 0.1.0 host floor is `>=0.1.79 <2.0.0`; the product remains
  experimental while the patched local host continues API hardening.
- `main.lua` is a tiny modular bootstrap.
- Vendored core is `0.1.0-alpha.12` and its lock points at the local
  snapshot described above.

### Actually integrated and locally testable

All 41 supported production records are registered and can participate in
fail-open replacement during local Gold gameplay. The exact split remains in
the product's `docs/GEN2_CONTRACTS.md`; stable battle frames are included,
while unproven animation-heavy sequences and child-owned stacks remain native or
deferred.

The core shell, clean settings, dropdowns, Mod Menus/pinning, API V3 host,
Modern UI V1/V2 compatibility facade, and UI Gallery are also active.

Fresh aggregate verification on 2026-08-14:

- Lua syntax: 201 files;
- contracts: 740 checks;
- foundation: 118 checks;
- shared UI: 47 checks;
- Party/Summary: 54 checks;
- Pack/Pokedex/Trainer/Save: 69 checks;
- Naming/storage: 112 checks;
- production Gallery: 779 checks;
- Modern UI compatibility: 33 checks;
- Pokegear/Map Radio: 203; services/commerce: 240; mail/specialty: 412;
- integrated Gallery: 174; production Gallery: 779;
- responsive NAV/M: 34,325; responsive battle: 21,884;
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

- All 41 supported records (foundation, 0.2, and 0.3 plus stable battle and
  source-complete cinematics) are
  registered with production model adapters and presenters; Hall of Fame is
  viewer-only.
- The 0.3 focused suites are part of `tests/run_all.lua`: Pokegear/MapRadio
  212 checks, services/commerce 240, mail/specialty 412, plus integrated
  Gallery and production Gallery checks.
- The aggregate suite passes syntax 201 files, contracts 740, foundation 118,
  shared 47, product smoke, Party/Summary 54, Pack/Dex/Trainer/Save 69,
  naming/storage 112, Pokegear 203, services 240, mail 412, integrated
  Gallery 174, production Gallery 779, responsive NAV/M 34,325, and
  responsive battle 21,884 checks.
- Mart, Mail Compose, and Trade use the host's exact zero-based ranges.
  `gold.CallerBox` remains explicitly native/pending until an exact public
  identity seam exists.
- The Gen2 V3 host now also publishes `gen2_official_catalog`, a callback-free
  51-entry status inventory carrying each exact screen ID, support state,
  milestone, and native reason for editor/diagnostic inspection. It does not
  register replacement screens or change native suppression behavior.
- The next 1.0 work is expanding the real-host smoke as the next Grandma's
  Kitchen build becomes available. The no-write route now reaches `13.30`
  with zero teleport shortcuts and zero travel-loop give-ups; the Route 42
  east seam, Dark Cave Rock Smash, connected-edge landing, and required
  responsive viewport/font matrices are green.
- The synthetic production-path NAV/M matrix passes 34,325 checks and the
  battle matrix passes 21,884 checks across short landscape, portrait, desktop,
  ultrawide, 4K, and 5K settings, including the native diagonal card/sprite
  order plus metadata-rich gender/condition/catch/EXP card rendering. A full
  no-write real Gold replay reaches `13.30` with zero teleport shortcuts and
  zero travel-loop give-ups. The targeted diagnostic is retained in
  `G:\dev\misc\gold-travel-dark-cave-violet.log`.
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
regressions are complete. `gold.CallerBox`, animation-heavy states, and
unproven child stacks remain explicit native/deferred seams; the Gen2 battle
transition itself is covered by the V3 transparent overlay path.

The next work is broader next-host readiness after the verified continuous
fresh-slot-to-Champion proof: expand real-host child-state coverage where the
contract still marks a native/deferred boundary, then rerun the same probes
against the next official Grandma's Kitchen build when it is available.
Preserve the full vertical envelopes when narrowing
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
Continue Gen2 first. The immediate task is to expand the real-host smoke as
the next Grandma's Kitchen build becomes available, then investigate newly
exposed host blockers and prepare the next official-host
integration. Keep
CallerBox, battle
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
