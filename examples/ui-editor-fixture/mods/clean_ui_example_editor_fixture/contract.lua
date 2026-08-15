return function(mod)
  local mode = "MAP"

  local function makeScreen()
    return {
      id = "editor_playground",
      type = "panel",
      title = "UI EDITOR PLAYGROUND",
      preset = "M",
      components = {
        { type = "label", id = "intro",
          text = "A deterministic V3 screen for editor previews.",
          layout = { wrap = true } },
        { type = "dropdown", id = "mode", label = "MODE", value = mode,
          action = "set_mode", options = {
            { id = "map", label = "MAP", value = "MAP",
              description = "Native-art map composition." },
            { id = "battle", label = "BATTLE", value = "BATTLE",
              description = "Metadata-rich battle composition." },
            { id = "party", label = "PARTY", value = "PARTY",
              description = "Bars, badges, and summary rows." },
          } },
        { type = "button", id = "apply", label = "OPEN CONFIRMATION",
          action = "apply", description = "Exercise a named modal action." },
        { type = "button", id = "open_dialogue", label = "OPEN DIALOGUE",
          action = "open_dialogue",
          description = "Exercise a direct V3 dialogue model." },
      },
      footer = { text = "UP/DOWN MOVE   A CHOOSE   B BACK" },
    }
  end

  local function dialogue()
    return {
      id = "editor_dialogue_preview", kind = "dialogue",
      schema = "clean_ui.v3.presentation.v1", apiVersion = 3,
      preset = "XS", opaque = false, anchor = "bottom",
      lines = {
        "Direct V3 dialogue uses the same reflowable model as production",
        "TextBox presentations while the source owns timing and input.",
      },
      inputReady = true, more = true, controls = "A/B CONTINUE",
    }
  end

  local function menu()
    return {
      id = "editor_menu_preview", kind = "menu",
      schema = "clean_ui.v3.presentation.v1", apiVersion = 3,
      preset = "M", title = "DIRECT MENU PREVIEW",
      rows = { { id = "map", label = "MAP", right = "OPEN" },
        { id = "battle", label = "BATTLE", right = "OPEN" } },
      selected = 1, description = "A direct V3 menu model.",
    }
  end

  local function choice()
    return {
      id = "editor_choice_preview", kind = "choice",
      schema = "clean_ui.v3.presentation.v1", apiVersion = 3,
      preset = "XS", anchor = "above_dialogue", title = "CHOOSE A MODE",
      options = {
        { id = "map", label = "MAP", value = "MAP" },
        { id = "battle", label = "BATTLE", value = "BATTLE" },
      },
      selected = 1, description = "The source owns the committed choice.",
    }
  end

  local function battle()
    return {
      id = "editor_battle_preview", kind = "battle",
      schema = "clean_ui.v3.presentation.v1", apiVersion = 3,
      preset = "BATTLE", title = "EDITOR BATTLE PREVIEW", phase = "commands",
      enemy = { name = "RATTATA", level = 3, hp = 13, maxHp = 13,
        types = { "NORMAL" } },
      player = { name = "TOTODILE", level = 5, hp = 20, maxHp = 20,
        exp = 0.35, types = { "WATER" } },
      actions = { { id = "fight", label = "FIGHT" },
        { id = "pokemon", label = "POKEMON" },
        { id = "pack", label = "PACK" }, { id = "run", label = "RUN" } },
      selected = 1,
    }
  end

  local function animation()
    return {
      id = "editor_animation_preview", kind = "animation",
      schema = "clean_ui.v3.presentation.v1", apiVersion = 3,
      preset = "ANIMATION", title = "DIRECT ANIMATION PREVIEW",
      animation = {
        id = "battle.move", frame = 12, duration = 32, progress = 0.375,
        label = "MOVE EFFECT",
        message = "The source owns timing; V3 owns the visual frame.",
      },
    }
  end

  local function device()
    return {
      id = "editor_device_preview", kind = "device",
      schema = "clean_ui.v3.presentation.v1", apiVersion = 3,
      preset = "L", appShell = true,
      device = { kind = "smartphone", family = "fixture",
        orientation = "landscape", aspect = "16:9" },
      statusBar = { time = "10:37 AM", region = "JOHTO" },
      launcher = { selected = 1 },
      apps = { { id = "clock", label = "CLOCK", selected = true },
        { id = "map", label = "MAP" } },
      activeApp = { id = "clock", label = "CLOCK" },
      screen = { id = "clock", title = "CLOCK" },
      rows = {}, details = { { label = "TIME", value = "10:37 AM" } },
      description = "LEFT/RIGHT CARD   B BACK",
    }
  end

  local function map()
    return {
      id = "editor_map_preview", kind = "map",
      schema = "clean_ui.v3.presentation.v1", apiVersion = 3,
      preset = "L",
      map = {
        region = "JOHTO",
        rows = { { id = "route29", name = "ROUTE 29", index = 1,
          x = 0, y = 0, selected = true } },
        current = { name = "ROUTE 29", index = 1 },
        player = { name = "ROUTE 29", index = 1 },
        graphic = { kind = "tilemap", width = 2, height = 2,
          sheet = { path = "assets/generated/map/tiles.png", wide = 2 },
          map = { 0, 1, 2, 3 } },
      },
      description = "UP/DOWN LANDMARK   B BACK",
    }
  end

  local function modal()
    return {
      type = "modal_overlay", id = "editor_confirm", title = "CONFIRM",
      message = "Apply the current editor fixture selection?",
      dim_background = true, dim_opacity = 0.4,
      options = {
        { id = "yes", label = "YES", action = "confirm" },
        { id = "no", label = "NO", action = "cancel" },
      },
    }
  end

  local contract = {
    id = "ui_editor_fixture",
    version = "1.0.0",
    all_generations = true,
    screens = { makeScreen(), menu(), dialogue(), choice(), battle(),
      animation(), device(), map() },
    extensions = {
      { id = "open_editor_fixture", type = "start.action",
        target = "mod_menus", label = "UI EDITOR FIXTURE",
        description = "Open the deterministic V3 editor playground.",
        icon = "edit", action = "open_fixture", pinnable = true },
    },
    gallery = {
      { id = "editor.playground.normal", games = { "gen1", "gen2" },
        family = "editor", title = "V3 Editor Playground", support = "supported",
        variant = "normal", preset = "M", screen = "editor_playground",
        content_levels = { "MINIMAL", "NORMAL", "OVERFLOW" } },
    },
    actions = {},
  }

  contract.actions.open_fixture = function()
    return makeScreen()
  end
  contract.actions.set_mode = function(_, payload)
    if payload and payload.value ~= nil then mode = payload.value end
    return makeScreen()
  end
  contract.actions.apply = function() return modal() end
  contract.actions.open_dialogue = dialogue
  contract.actions.open_choice = choice
  contract.actions.open_battle = battle
  contract.actions.open_animation = animation
  contract.actions.open_device = device
  contract.actions.open_map = map
  contract.actions.confirm = function()
    mod.log:info("Clean UI editor fixture confirmed")
    return { type = "close" }
  end
  contract.actions.cancel = function() return { type = "close" } end

  return contract
end
