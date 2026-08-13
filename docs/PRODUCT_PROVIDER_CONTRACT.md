# Product Provider Contract

`clean-ui-core` has no knowledge of Red/Blue/Yellow or Gold screen classes.
Each installable product supplies a generation provider that translates exact
source contracts into shared presentation services.

## Product organization

Product `main.lua` is intentionally a thin bootstrap:

```text
mods/gen2_clean_ui/
├── main.lua                         # read bootstrap + provider; install
├── provider.lua                     # provider composition root
├── provider/
│   ├── inventory.lua                # exact screen registry
│   ├── stack.lua                    # visible-stack inventory
│   ├── suppression.lua              # scoped leases
│   ├── sprites.lua                  # color/palette policy
│   ├── actions.lua                  # source-owned dispatch mappings
│   └── screens/
│       ├── core.lua
│       ├── party.lua
│       ├── summary.lua
│       ├── pokedex.lua
│       ├── storage.lua
│       └── services.lua
└── vendor/clean_ui_core/
```

Coherent screen families have focused adapters/presenters. Shared systems are
vendored core modules. No product should accumulate its implementation into a
single entry file.

## Provider object

```lua
local provider = {
  productId = "gen2_clean_ui",
  game = "gen2",
  inventory = { ... },

  currentGame = function(self) ... end,
  visibleStack = function(self, game) ... end,
  inspectScreen = function(self, state) ... end,
  extractModel = function(self, record, state, game) ... end,
  dispatch = function(self, mapping, game, state, payload) ... end,
  resolveAsset = function(self, request, state, game) ... end,
  pointerMap = function(self, layout, state, game) ... end,
  proveReplacement = function(self, candidate, stack) ... end,
  acquireSuppression = function(self, proof) ... end,
  releaseSuppression = function(self, lease) ... end,
}
```

The composition root validates this interface before installing hooks.

## Exact screen inventory

Every host-declared screen ID has exactly one record:

```lua
{
  id = "Gen2PartyMenu",
  support = "supported", -- supported | native | deferred
  family = "party",
  presenter = "party.main",
  preset = "L",
  toggle = "pokemon",
  validator = validateParty,
  extract = extractParty,
  actions = PARTY_ACTIONS,
  gallery = { "gen2.party.normal", "gen2.party.actions" },
  fallback_reason = nil,
}
```

Native/deferred records omit presenter/extract/action mappings and require a
human-readable fallback reason and milestone.

Detection rules:

- match exact registered source ID;
- verify the expected source class when the host exposes it;
- run the record's shape validator;
- reject custom source draw overrides unless explicitly audited;
- never infer support from a suffix, similar RBY name, or loose table shape.

New beta IDs fail inventory coverage tests in development but remain native at
runtime.

## Validators

A validator is pure and defensive. It returns `true` or
`nil, code, message`; it does not throw for ordinary drift.

It verifies only fields required to build the complete presenter model and
source action map. Optional fields are normalized by extraction. A validator
must reject:

- missing or wrong-typed required fields;
- invalid selection/scroll ranges that cannot be mapped safely;
- an unrecognized mode or phase;
- replaced/custom draw ownership;
- a screen instance no longer present in the inspected stack.

Validators must not mutate source state, call callbacks, play audio, or create
screens.

## Model extraction

Extraction produces an acyclic, metatable-free snapshot. It may read live
source state but cannot retain it in the result. Models use stable IDs rather
than callbacks.

For Pokémon art, the provider resolves generation-appropriate full-color
assets and palette metadata. A monochrome fallback is explicit diagnostic
behavior, not the default for Gen2.

If a model declares sprite artwork, that image and any exact integer
`crop`/`sourceRect` must be renderable before suppression is proved. Missing
images, invalid or out-of-bounds source rectangles, and unavailable Quads fail
the complete offscreen render and leave the source screen native. Providers
omit the descriptor only when the artwork is intentionally optional.

Pages are named by purpose—status, moves, and stats—not by source palette
color. All appropriate pages retain the Pokémon sprite and source information.

## Source action mapping

The provider maps a component action to the source screen's existing operation.
It does not reimplement game rules.

```lua
local PARTY_ACTIONS = {
  choose = { source = "confirmSelection" },
  cancel = { source = "cancel" },
  switch = { source = "beginSwitch" },
  take_item = { source = "takeHeldItem" },
  give_item = { source = "openItemPicker" },
}
```

Dispatch validates that the source instance and mode still match the mapping,
then invokes the source-owned operation under error isolation. CANCEL/BACK is
always represented meaningfully; a selectable source cancel row cannot become
an unexplained blank modern page.

## Visible-stack inventory

The provider inspects every visible state from bottom to top and returns a
record for each draw owner, including embedded source modals where they have a
stable seam.

A stack candidate records:

- exact screen ID and instance token;
- source opacity/render visibility before Clean UI changes;
- validator result and model revision;
- selected presenter and toggle;
- custom-draw/capture flags;
- parent/child ownership;
- whether the layer is world-owned and unsuppressible.

The world canvas is never treated as an expendable UI layer.

## Prepare before suppress

Replacement order is mandatory:

1. Inventory the complete visible stack.
2. Validate every layer that would disappear.
3. Extract copied models.
4. Solve locked layouts.
5. Render the complete replacement offscreen.
6. Validate the offscreen result and all required bounds.
7. Ask the provider for a complete-stack proof.
8. Acquire narrowly scoped `screen.render_visible` leases.
9. Compose the prepared result.

The core cannot create a suppression proof. A proof identifies exact instance
tokens, state revisions, presenter results, and original opacity values and is
valid for one frame/revision only.

## Suppression leases

A lease changes only the proven source state's `screen.render_visible` value.
It records the prior value and restores it when:

- the proof expires;
- the state leaves the stack;
- a validator or presenter fails;
- the user enables the relevant Use Native UI switch;
- capture mode or a custom draw override appears;
- the runtime uninstalls;
- any exception escapes preparation or composition.

Never clear a shared world/UI/scene canvas. Never set broad stack opacity based
on a single recognized child.

## Complete-stack examples

These require all-or-native decisions:

- world + Start Menu;
- PC root + picker + quantity + confirmation;
- parent menu + embedded message;
- CallerBox + shared dialogue;
- audited Oak artwork + supported child dialogue/naming;
- battle + Party/Pack/naming child.

Gen2 battle and every child opened over it remain wholly native until the
separate battle milestone. A supported Party presenter in the overworld does
not authorize presenting that Party state over an unsupported battle.

## Native and partial seams

Partial modernization is allowed only at an independently suppressible child
seam. Examples include an audited TextBox over native Oak artwork. It is not
allowed for a world-owned picture window whose draw cannot be separated from
its parent.

Native/deferred Gallery records make these choices visible; they never imply
that the parent screen is suppressed.

## Pointer mapping

The provider maps measured component IDs and hit regions to source selection,
scroll, and activation operations. Pointer geometry is presentation-only. The
source remains authoritative for whether an action is legal.

## Failure contract

Unknown IDs, malformed states, exceptions, missing assets, incomplete layouts,
custom draws, capture modes, and contract drift all fail open immediately.

The runtime may retain a last-good offscreen frame only while its exact source
instance/revision proof remains valid. It must never display a stale frame over
a changed or unvalidated source stack.

## Product acceptance

A product cannot mark a record `supported` until it has:

- exact validator and malformed-state tests;
- live extraction and synthetic Gallery fixtures;
- action/pointer mappings for every visible source operation;
- stable-envelope tests across all modes/pages/content;
- complete-stack and exception fail-open tests;
- a real-route smoke test.
