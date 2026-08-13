return function(mod)
  local function detailsScreen()
    return {
      id = "oddish_details",
      type = "panel",
      title = "DEXNAV DETAILS",
      preset = "L",
      components = {
        {
          type = "details",
          id = "oddish",
          title = "ODDISH",
          sprite = { asset = "pokemon/oddish", palette = "true_color" },
          fields = {
            { id = "species", label = "SPECIES", value = "WEED" },
            { id = "level", label = "LEVEL", value = "Lv 15 - 17" },
          },
          custom_fields = {
            columns = 4,
            data = {
              { id = "hp", label = "HP", value = 45 },
              { id = "attack", label = "ATK", value = 50 },
              { id = "defense", label = "DEF", value = 55 },
              { id = "speed", label = "SPD", value = 30 },
              { id = "special", label = "SPC", value = 75 },
              { id = "total", label = "TOTAL", value = 255,
                style = "accent" },
            },
          },
          footer_lists = {
            {
              id = "encounter",
              title = "ENCOUNTER",
              items = {
                { label = "GRASS", value = "24%" },
                { label = "MORNING", value = "COMMON" },
              },
            },
            {
              id = "moves",
              title = "KNOWN MOVES",
              items = {
                { label = "ABSORB" },
                { label = "SWEET SCENT" },
                { label = "POISONPOWDER" },
              },
            },
          },
          layout_options = {
            overflow = "shrink_to_fit",
            max_content_height = "100%",
          },
        },
      },
    }
  end

  local contract = {
    id = "details_fields_footer_lists",
    version = "1.0.0",
    games = { "gen1", "gen2" },
    screens = { detailsScreen() },
    extensions = {
      {
        id = "open_details",
        type = "start.action",
        target = "mod_menus",
        label = "DETAILS EXAMPLE",
        description = "Open auto-fitted details and footer lists.",
        icon = "info",
        action = "open_details",
        pinnable = true,
      },
    },
    gallery = {
      {
        id = "details.fields_footer_lists",
        games = { "gen1", "gen2" },
        family = "examples",
        title = "Fields and Footer Lists",
        support = "supported",
        variant = "full",
        preset = "L",
        screen = "oddish_details",
        content_levels = { "MINIMAL", "NORMAL", "FULL", "OVERFLOW" },
      },
    },
    actions = {},
  }

  contract.actions.open_details = function(ctx, payload)
    return detailsScreen()
  end

  return contract
end

