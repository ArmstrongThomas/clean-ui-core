return function(mod)
  return {
    id = "party_row_colors",
    version = "1.0.0",
    games = { "gen1", "gen2" },

    extensions = {
      {
        id = "row_colors",
        type = "party.row_style",
        target = "party.rows",
        rules = {
          { when = { field = "slot", one_of = { 1, 3, 5 } },
            style = { background = "#E7EEF8" } },
          { when = { field = "slot", one_of = { 2, 4, 6 } },
            style = { background = "#F4F1E5" } },
          { when = { field = "status", not_equals = "OK" },
            style = { background = "#F5D8D3", accent = "#A63E36" } },
          { when = { field = "isEgg", equals = true },
            style = { background = "#FFF1C8", accent = "#B3882D" } },
        },
      },
    },

    gallery = {
      {
        id = "party.rows.normal",
        games = { "gen1", "gen2" },
        family = "examples",
        title = "Party Row Colors",
        support = "supported",
        variant = "normal_status_egg",
        preset = "L",
        extension = "row_colors",
        content_levels = { "MINIMAL", "NORMAL", "FULL", "OVERFLOW" },
        model = {
          rows = {
            { slot = 1, name = "SPROUT", level = 18, status = "OK" },
            { slot = 2, name = "QUIL", level = 17, status = "PSN" },
            { slot = 3, name = "EGG", isEgg = true, status = "OK" },
          },
        },
      },
    },

    actions = {},
  }
end

