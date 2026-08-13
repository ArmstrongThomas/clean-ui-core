return function(mod)
  local trainingPage = {
    id = "training",
    title = "TRAINING",
    icon = "chart",
    components = {
      {
        type = "details",
        id = "training_details",
        title = "TRAINING NOTES",
        fields = {
          { id = "role", label = "ROLE", value = "FAST SUPPORT" },
          { id = "nature", label = "TEMPERAMENT", value = "CURIOUS" },
        },
        custom_fields = {
          columns = 3,
          data = {
            { id = "wins", label = "WINS", value = 12 },
            { id = "steps", label = "STEPS", value = 3480 },
            { id = "bond", label = "BOND", value = "HIGH",
              style = "accent" },
          },
        },
        footer_lists = {
          {
            id = "goals",
            title = "NEXT GOALS",
            items = {
              { label = "LEARN", value = "REFLECT" },
              { label = "REACH", value = "Lv 25" },
            },
          },
        },
      },
    },
  }

  return {
    id = "extra_summary_page",
    version = "1.0.0",
    games = { "gen1", "gen2" },

    extensions = {
      {
        id = "training_page",
        type = "summary.page",
        target = "summary.pages",
        insert_after = "stats",
        page = trainingPage,
      },
    },

    gallery = {
      {
        id = "summary.training",
        games = { "gen1", "gen2" },
        family = "examples",
        title = "Extra Summary Page",
        support = "supported",
        variant = "training",
        preset = "L",
        extension = "training_page",
        content_levels = { "NORMAL", "FULL", "OVERFLOW" },
        model = { page = trainingPage, pokemon = "SPROUT", level = 24 },
      },
    },

    actions = {},
  }
end

