# Clean UI Gallery

The UI Gallery is an in-game QA catalog backed by the same production
presenters, component host, layout solver, and renderer used during gameplay.
It is not a collection of screenshots and it never constructs live game
screens.

## Catalog scope

One Gallery opens for the running product:

- Gen1 shows Gen1 production fixtures and compatible shared integrations.
- Gen2 shows Gen2 production fixtures and compatible shared integrations.
- Third-party V3 fixtures appear only when their `games` includes the running
  game. A contract may use `all_generations = true` to declare that its shared
  screens and actions apply to every Clean UI product; fixture metadata should
  still use `games` when the fixture itself is generation-specific.

Tooling may request an unfiltered catalog, but the player-facing Gallery never
mixes generations.

Stable IDs are generation-qualified for product fixtures and owner-qualified
internally for third-party fixtures:

```text
gen1.battle.moves
gen2.party.actions
gen2.pokedex.search
example_dropdown:dropdown.grouped
```

Renaming visible text must not change a fixture ID.

## Fixture descriptor

```lua
{
  id = "party.actions",
  games = { "gen2" },
  family = "party",
  title = "Party Actions",
  description = "Pokémon selection with its action menu open.",
  support = "supported",
  variant = "actions",
  preset = "L",
  screen = "party_screen",
  content_levels = { "EMPTY", "MINIMAL", "NORMAL", "FULL", "OVERFLOW" },
  model = { ... },
}
```

Required metadata is `id`, `games`, `family`, `title`, `support`, and `preset`.
`support` is one of:

- `supported`: previews the production presenter;
- `native`: intentionally remains source-rendered;
- `deferred`: planned but not yet modernized.

Native/deferred fixtures provide exact `screen_id`, `reason`, and `milestone`
and render as status cards.

## Content levels

The standard levels are:

| Level | Purpose |
|---|---|
| `EMPTY` | No records and explicit empty-state copy. |
| `MINIMAL` | Smallest valid model. |
| `NORMAL` | Typical gameplay content. |
| `FULL` | Normal capacity with every optional field populated. |
| `OVERFLOW` | Long labels, maximum rows, wrapped text, and scrolling. |

A fixture may omit meaningless levels, but `NORMAL` and `OVERFLOW` are required
for production presenters. Level changes update body content without changing
the preview's locked outer envelope.

## Index controls

- Left/Right changes family.
- Up/Down selects a fixture.
- A opens its preview.
- B closes Gallery.

The index itself uses a stable `NAV` envelope and remains usable with many
families or fixtures through deterministic scrolling.

## Preview controls

- Left/Right changes fixture.
- Up/Down changes content level.
- A cycles UI Size.
- Select cycles Text Size.
- Start toggles System/Plain Pixel.
- B returns to the index.

Preview settings are held only in Gallery controller memory. They never call
`mod.options:set` and disappear when Gallery closes.

## Required shared fixtures

Dropdown coverage:

- short list;
- grouped choices;
- disabled choices;
- overflow with wheel/controller scrolling;
- edge flip above the trigger;
- pointer outside-dismiss;
- touch drag;
- controlled-value reconciliation.

Mod Menus and pin coverage:

- normal pinned action;
- dormant pin whose owner is absent;
- duplicate label-only legacy entries;
- enough pins to scroll;
- source callback failure.

Layout coverage includes every preset, explicit header/footer pressure,
long localized strings, `custom_fields`, bottom-anchored `footer_lists`, and a
surface status/error card.

## Safety contract

Synthetic fixture construction receives no live game, save, audio, callback,
screen, or transition object. Merely listing, opening, or cycling a fixture
must perform zero source mutations.

Tests install spies that fail if Gallery:

- creates a source game screen;
- invokes a source callback or registered action during preview construction;
- writes profile options or mod save data;
- plays audio;
- pushes source navigation;
- acquires a native suppression lease.

Interactive activation inside a preview uses a Gallery action spy unless a
fixture explicitly tests action isolation. It still cannot reach gameplay.

## Production-path guarantee

A supported fixture supplies synthetic model data to the same product adapter
and presenter entry point used for live gameplay:

```text
fixture model ─┐
               ├─> production presenter -> layout -> render
live snapshot ─┘
```

There is no Gallery-only presenter. A fixture that cannot use the production
path is invalid.

## Developer bounds overlay

Gallery can overlay individually colored rectangles for:

- viewport and touch safe area;
- fixed envelope and frame inset;
- header, body, footer, and overlay host;
- component content bounds;
- clip rectangles and scroll extents;
- visible and expanded pointer targets;
- unresolved overflow.

The overlay consumes the immutable layout result and never remeasures content.
Diagnostics redact callbacks and do not retain source state objects.

## Third-party fixtures

Third-party fixtures are part of the same V3 contract as their feature. They
are removed when the owner unregisters. IDs are unique within the contract;
the runtime namespaces them by owner and contract.

Fixtures should demonstrate behavior, not depend on a particular save. Prefer
literal species names, values, and placeholder asset IDs that are legal in
both products when `games` contains both generations.
