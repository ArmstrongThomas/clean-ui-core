# Clean UI V3 Extension Proposal

Status: design proposal for additive, backward-compatible V3 work.

This proposal is driven by the Pokédex redesign, but the API should remain
useful for any mod that needs an encyclopedia, quest journal, crafting
catalog, bestiary, map book, achievement page, or other information-heavy UI.

## Current strengths

V3 already provides the right safety foundation:

- atomic owner-scoped registration;
- data-only presentation models;
- named action references instead of embedded callbacks;
- capability discovery;
- fail-open native ownership rules;
- deterministic Gallery and contract inspection;
- shared responsive layout and rendering.

Those properties must not be weakened.

## Current gaps

### 1. Rich pages are forced into menu-shaped models

`menu`, `device`, and `map` cover important cases, but a reference page usually
needs a composition such as:

- identity header;
- one or more content regions;
- metadata grid;
- artwork;
- prose;
- related-item list;
- map or progression diagram;
- persistent controls.

Today, products either encode those ideas as a right-hand `details` panel or
fall back to a custom surface. That makes the generated Pokédex layouts
difficult to express and encourages product-specific renderer code.

### 2. Custom surfaces are too large a step

Custom surfaces are useful for unusual or highly animated UI, but they require
renderer callbacks, private-canvas handling, and a separate validation path.
They are not the best default for ordinary mod developers who only need a
well-composed data page.

### 3. Focus and responsive intent are under-described

Named actions exist, but a model does not yet describe enough of its intended
focus order, region priority, or compact fallback behavior. Products therefore
have to infer navigation from the model's incidental row order.

### 4. Editor parity stops at model inspection

The contract catalog can inspect declarative data, but an editor needs to know
the canonical layout vocabulary and expected responsive variants without
executing product code.

## Proposed additive capabilities

### A. `document` presentation kind

Add a data-only `document` model for information-heavy pages:

```lua
{
  schema = "clean_ui.v3.presentation.v1",
  apiVersion = 3,
  kind = "document",
  preset = "L",
  title = "PIDGEY / INFO",
  regions = {
    {
      id = "identity",
      role = "header",
      priority = 100,
      components = {
        { type = "image", asset = "pokemon/pidgey/front.png",
          fit = "contain", emphasis = "primary" },
        { type = "heading", text = "PIDGEY", style = "display" },
        { type = "label", text = "No.016 · TINY BIRD POKÉMON" },
        { type = "badges", values = { "NORMAL", "FLYING" } },
      },
    },
    {
      id = "facts",
      role = "metadata",
      components = {
        { type = "metadata", items = {
          { label = "HEIGHT", value = "1'00\"" },
          { label = "WEIGHT", value = "4.0 lbs." },
          { label = "STATUS", value = "OWNED", tone = "accent" },
        } },
      },
    },
    {
      id = "entry",
      role = "prose",
      components = {
        { type = "heading", text = "POKÉDEX ENTRY" },
        { type = "text", lines = {
          "It usually hides in tall grass.",
          "Because it dislikes fighting, it protects itself",
          "by kicking up sand with its wings.",
        } },
      },
    },
  },
  footer = {
    controls = "LEFT/RIGHT PAGE   A SELECT   B BACK",
  },
}
```

The first implementation should support only a small stable vocabulary:

- `heading`
- `label`
- `text`
- `image`
- `badges`
- `metadata`
- `list`
- `map`
- `divider`

Products should compose these components; they should not add a new renderer
for each game-specific page.

### B. Declarative region constraints

Each region should support data-only responsive intent:

```lua
{
  id = "facts",
  minWidth = 180,
  preferredWidth = 280,
  priority = 70,
  collapse = "stack",
  overflow = "scroll",
}
```

The solver may stack, compact, or hide only components explicitly marked
optional. Required identity and control components must remain visible or cause
the presentation to fail open.

### C. Semantic focus descriptors

Add an optional model-level focus descriptor:

```lua
focus = {
  initial = "route_29",
  order = { "route_29", "route_30", "route_31" },
  groups = {
    { id = "pages", direction = "horizontal",
      targets = { "info", "area", "evo", "moves", "tm" } },
    { id = "content", direction = "vertical",
      targets = { "route_29", "route_30", "route_31" } },
  },
}
```

This describes visual focus and editor previews only. It must not bypass
source-owned update/navigation. A source action remains the authority for
actually changing game state or changing the source screen.

### D. Structured control hints

Replace free-form footer strings over time with optional data:

```lua
controls = {
  { input = "left", label = "PAGE" },
  { input = "a", label = "SELECT", action = "page.select" },
  { input = "b", label = "BACK", action = "page.back" },
}
```

The existing string form remains supported. Products can render the structured
form consistently across keyboard, controller, touch, and Gallery previews.

### E. Capability versioning

Advertise the new vocabulary independently:

```lua
capabilities = {
  document_pages = "0.1.0",
  semantic_focus = "0.1.0",
  structured_controls = "0.1.0",
}
```

Third-party mods can fall back to an ordinary `menu` or native UI when these
capabilities are unavailable.

### F. Editor and Gallery fixtures

Every new component and document region should have:

- a data-only contract descriptor;
- malformed-model rejection tests;
- compact and expanded layout fixtures;
- Gallery preview data;
- a contract-catalog representation;
- at least one keyboard/controller control fixture.

The editor should be able to render a document entirely from the copied model
and capability descriptor without invoking mod callbacks.

## What should not change

- Do not expose the host's private screen objects.
- Do not allow arbitrary draw callbacks in ordinary document models.
- Do not let a presentation model mutate saves, world state, or source cursors.
- Do not infer source navigation from visual focus and dispatch it implicitly.
- Do not make a document model a replacement for complete-stack ownership.
- Do not require `gen1recomp` changes for these additive Clean UI capabilities.

## Recommended implementation order

1. Add `document` validation and a minimal component vocabulary.
2. Add responsive region measurement and rendering in shared Core.
3. Add structured controls and semantic focus metadata.
4. Add contract-catalog and Gallery descriptors.
5. Convert Gen 2 Pokédex Info to `document`.
6. Convert Gen 2 Pokédex Habitat to `document` plus the existing map component.
7. Reuse the same components for Evolution, Moves, and TM/HM pages.
8. Evaluate whether Gen 1 products need any compatibility-only adaptations.

This keeps the Pokédex redesign useful as an API test case without making the
API Pokédex-specific.

