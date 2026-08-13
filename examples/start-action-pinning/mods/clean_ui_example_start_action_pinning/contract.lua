return function(mod)
  local contract = {
    id = "start_action_pinning",
    version = "1.0.0",
    games = { "gen1", "gen2" },
    extensions = {
      {
        id = "field_notes",
        type = "start.action",
        target = "mod_menus",
        label = "FIELD NOTES",
        description = "Open the example source mod menu.",
        icon = "notes",
        action = "open_field_notes",
        pinnable = true,
      },
    },
    gallery = {
      {
        id = "start.pinnable_action",
        games = { "gen1", "gen2" },
        family = "examples",
        title = "Pinnable Start Action",
        support = "supported",
        variant = "pinned",
        preset = "NAV",
        extension = "field_notes",
        content_levels = { "NORMAL", "OVERFLOW" },
      },
    },
    actions = {},
  }

  contract.actions.open_field_notes = function(ctx, payload)
    return {
      type = "modal_overlay",
      id = "field_notes_about",
      title = "FIELD NOTES",
      message = "This action stays in MOD MENUS even when pinned to Start.",
      dim_background = true,
      dim_opacity = 0.4,
      options = {
        { id = "done", label = "DONE", action = "close_notes" },
      },
    }
  end

  contract.actions.close_notes = function(ctx, payload)
    return { type = "close" }
  end

  return contract
end

