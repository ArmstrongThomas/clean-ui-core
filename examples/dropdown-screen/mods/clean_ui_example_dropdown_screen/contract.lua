return function(mod)
  local selected = "dex"

  local function makeScreen()
    return {
      id = "sort_screen",
      type = "panel",
      title = "ENCOUNTER SORT",
      preset = "M",
      components = {
        {
          type = "label",
          id = "instructions",
          text = "Choose how encounter results are ordered.",
          layout = { wrap = true },
        },
        {
          type = "dropdown",
          id = "sort",
          label = "SORT BY",
          value = selected,
          action = "change_sort",
          options = {
            { id = "dex", label = "DEX NUMBER", value = "dex",
              description = "National species order." },
            { id = "name", label = "NAME", value = "name",
              group = "ALPHABETICAL" },
            { id = "type", label = "TYPE", value = "type" },
            { id = "level", label = "LEVEL", value = "level",
              group = "ENCOUNTER DATA" },
            { id = "rate", label = "ENCOUNTER RATE", value = "rate" },
            { id = "morning", label = "MORNING RATE", value = "morning" },
            { id = "day", label = "DAY RATE", value = "day" },
            { id = "night", label = "NIGHT RATE", value = "night" },
            { id = "distance", label = "DISTANCE", value = "distance",
              disabled = true, description = "Unavailable on this map." },
          },
        },
      },
      footer = { text = "A choose   B back" },
    }
  end

  local contract = {
    id = "dropdown_screen",
    version = "1.0.0",
    games = { "gen1", "gen2" },
    screens = { makeScreen() },
    extensions = {
      {
        id = "open_dropdown",
        type = "start.action",
        target = "mod_menus",
        label = "DROPDOWN EXAMPLE",
        description = "Open the controlled dropdown example.",
        icon = "list",
        action = "open_dropdown",
        pinnable = true,
      },
    },
    gallery = {
      {
        id = "dropdown.grouped",
        games = { "gen1", "gen2" },
        family = "examples",
        title = "Grouped Dropdown",
        support = "supported",
        variant = "grouped_disabled_overflow",
        preset = "M",
        screen = "sort_screen",
        content_levels = { "MINIMAL", "NORMAL", "OVERFLOW" },
      },
    },
    actions = {},
  }

  contract.actions.open_dropdown = function(ctx, payload)
    return makeScreen()
  end

  contract.actions.change_sort = function(ctx, payload)
    if payload and payload.value ~= nil then selected = payload.value end
    return makeScreen()
  end

  return contract
end

