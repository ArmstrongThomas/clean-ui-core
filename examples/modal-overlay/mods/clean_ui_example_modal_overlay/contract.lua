return function(mod)
  local function confirmation()
    return {
      type = "modal_overlay",
      id = "register_entry",
      title = "REGISTER?",
      message = "Save ODDISH as the active search target?",
      dim_background = true,
      dim_opacity = 0.4,
      options = {
        { id = "yes", label = "YES", action = "confirm" },
        { id = "no", label = "NO", action = "cancel" },
      },
    }
  end

  local contract = {
    id = "modal_overlay",
    version = "1.0.0",
    games = { "gen1", "gen2" },
    extensions = {
      {
        id = "open_modal",
        type = "start.action",
        target = "mod_menus",
        label = "MODAL EXAMPLE",
        description = "Open a focus-trapped confirmation overlay.",
        icon = "dialogue",
        action = "open_modal",
        pinnable = true,
      },
    },
    gallery = {
      {
        id = "modal.confirmation",
        games = { "gen1", "gen2" },
        family = "examples",
        title = "Modal Confirmation",
        support = "supported",
        variant = "dimmed",
        preset = "XS",
        model = confirmation(),
        content_levels = { "MINIMAL", "NORMAL", "OVERFLOW" },
      },
    },
    actions = {},
  }

  contract.actions.open_modal = function(ctx, payload)
    return confirmation()
  end

  contract.actions.confirm = function(ctx, payload)
    mod.log:info("Modal example confirmed")
    return { type = "close" }
  end

  contract.actions.cancel = function(ctx, payload)
    return { type = "close" }
  end

  return contract
end

