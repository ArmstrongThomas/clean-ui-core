local function filesystemRead(path)
  return love.filesystem.read(path)
end

io.stdout:setvbuf("no")
io.stderr:setvbuf("no")

local bootstrapSource = assert(love.filesystem.read("src/clean_ui/bootstrap.lua"))
local bootstrap = assert(loadstring(bootstrapSource, "@clean_ui/bootstrap.lua"))()

function love.load()
  local T = require("support.harness")

  local modOptions, saveValues, hookWrappers, eventListeners = {}, {}, {}, {}
  local sourceImages = {}
  local registeredScreens = {}
  local fakeStack = { states = {} }
  function fakeStack:push(screen) self.states[#self.states + 1] = screen end
  function fakeStack:pop()
    local screen = table.remove(self.states)
    if screen and screen.exit then screen:exit() end
    return screen
  end
  function fakeStack:top() return self.states[#self.states] end
  local fakeInput = { pressed = {} }
  function fakeInput:wasPressed(button)
    local value = self.pressed[button] == true
    self.pressed[button] = nil
    return value
  end
  local fakeGame = { stack = fakeStack, input = fakeInput }
  local mod = {
    exports = {},
    options = {
      define = function(_, schema) modOptions.schema = schema return schema end,
      set = function(_, key, value) modOptions[key] = value return true end,
      get = function(_, key) return modOptions[key] end,
    },
    save = {
      get = function(_, key, fallback)
        return saveValues[key] == nil and fallback or saveValues[key]
      end,
      set = function(_, key, value) saveValues[key] = value return true end,
    },
    hooks = {
      wrap = function(_, name, callback)
        hookWrappers[name] = callback
        return function() hookWrappers[name] = nil end
      end,
    },
    events = {
      on = function(_, name, callback)
        eventListeners[name] = eventListeners[name] or {}
        eventListeners[name][#eventListeners[name] + 1] = callback
        return function()
          for index, candidate in ipairs(eventListeners[name] or {}) do
            if candidate == callback then table.remove(eventListeners[name], index) break end
          end
        end
      end,
    },
    content = {
      screens = {
        register = function(_, id, record)
          registeredScreens[id] = record
          return record
        end,
      },
    },
    ui = {
      sourceImage = function(path) return sourceImages[path] end,
      push = function(game, id, ...)
        local factory = assert(registeredScreens[id], "unknown fake screen: " .. id)
        local screen = assert(factory.new(game, ...))
        screen.screenId = screen.screenId or id
        game.stack:push(screen)
        return screen
      end,
    },
  }
  local provider = {
    productId = "test_clean_ui", game = "gen2",
    getViewport = function() return { x = 0, y = 0, w = 1920, h = 1080 } end,
    getSafeArea = function() return { x = 0, y = 0, w = 1920, h = 1080 } end,
    visibleStack = function() return {} end,
    exactScreenId = function(screen) return screen.screenId end,
    recordFor = function() return nil end,
    sourceToken = function(screen) return screen end,
    suppression = { prove = function() return nil end,
      acquire = function() end, release = function() end },
  }
  local runtime, bootError = bootstrap({ root = "src/clean_ui", read = filesystemRead,
    mod = mod, provider = provider })
  T.check(runtime ~= nil, "bootstrap creates a runtime: "
    .. tostring(bootError and bootError.message))
  T.equal(select(1, runtime:install()), true, "runtime installs")
  T.equal(mod.exports.cleanUiHost.apiVersion, 3, "V3 host is exported")
  T.check(mod.exports.cleanUiHost:supports("dropdown", "0.1.0"),
    "dropdown capability is advertised")
  T.equal(select(1, runtime:resetDefaults()), true,
    "settings reset uses the public options writer")
  T.check(type(modOptions.schema) == "table" and #modOptions.schema == 7,
    "core defines the seven shared settings")
  local themeChoices = modOptions.schema[1].choices
  local expectedChoiceOrder = {
    "clean", "red", "blue", "yellow", "gold", "silver", "crystal",
    "high_contrast",
  }
  for index, id in ipairs(expectedChoiceOrder) do
    T.equal(themeChoices[index][2], id,
      "settings keeps the theme choice order at " .. index)
  end
  local expectedThemes = {
    clean=true, dark=true, high_contrast=true, light_high_contrast=true,
    red=true, red_dark=true, blue=true, blue_dark=true,
    yellow=true, yellow_dark=true, gold=true, gold_dark=true,
    silver=true, silver_dark=true, crystal=true, crystal_dark=true,
  }
  for id in pairs(expectedThemes) do
    local theme = runtime.themes:get(id)
    T.check(theme.id == id,
      "theme registry resolves the " .. id .. " theme")
    local accepted, code = runtime.themes:register({
      id = "__contrast_check_" .. id, colors = theme.colors,
    })
    T.check(accepted, "theme registry accepts readable " .. id
      .. " contrast palette: " .. tostring(code))
  end
  T.equal(#themeChoices, 8, "settings exposes eight base themes")
  T.equal(modOptions.schema[2].key, "dark_mode",
    "dark mode is directly below the theme chooser")
  local fontChoices = modOptions.schema[5].choices
  local expectedFonts = {
    "openttd_mono", "plain_pixel", "system",
  }
  for index, id in ipairs(expectedFonts) do
    T.equal(fontChoices[index][2], id,
      "settings keeps the font choice order at " .. index)
  end
  T.equal(#fontChoices, 3, "settings exposes three public font families")
  T.equal(modOptions.schema[5].default, "openttd_mono",
    "OpenTTD Mono is the shared default font")
  T.equal(runtime:themeFor("clean", false).id, "clean",
    "clean resolves to the light neutral theme")
  T.equal(runtime:themeFor("clean", true).id, "dark",
    "dark mode resolves clean to its dark opposite")
  T.equal(runtime:themeFor("red", false).id, "red",
    "light red resolves to the base palette")
  T.equal(runtime:themeFor("red", true).id, "red_dark",
    "dark mode resolves red to its dark variant")
  T.equal(runtime:themeFor("high_contrast", false).id, "light_high_contrast",
    "light mode resolves high contrast to its light variant")
  T.equal(runtime:themeFor("high_contrast", true).id, "high_contrast",
    "dark mode resolves high contrast to its dark variant")
  T.check(type(hookWrappers["ui.start_menu.items"]) == "function",
    "core installs the shared Start-menu catalog hook")
  T.check(type(hookWrappers["render.hud"]) == "function"
    and type(hookWrappers["input.pointer"]) == "function"
    and type(hookWrappers["input.wheel"]) == "function",
    "shell installs render, pointer, and wheel seams")

  -- Keep the bootstrap-facing checks in their own lexical scope. Lua limits
  -- each function to 200 simultaneously live local registers; this file is
  -- intentionally a broad integration suite, so one unbroken love.load
  -- scope eventually exceeded that limit as the suite grew.
  do

  local directContract = {
    id = "direct_contract", version = "1.0.0", games = { "gen2" },
    screens = {{
      id = "direct_menu", schema = "clean_ui.v3.presentation.v1", apiVersion = 3,
      kind = "menu", preset = "S", rows = {{ id = "one", label = "ONE" }},
    }}, actions = {},
  }
  T.equal(#runtime:validateV3(directContract), 0,
    "core V3 validator accepts canonical direct models")
  local directLayout = runtime:measureV3(directContract.screens[1], 640, 360,
    { font = love.graphics.newFont(15) })
  T.check(directLayout and directLayout.v3Model.kind == "menu"
    and directLayout.v3Model.schema == "clean_ui.v3.presentation.v1",
    "core V3 embedding bridge measures direct models through presentation runtime")
  local invalidDirect = {
    id = "invalid_contract", version = "1.0.0", games = { "gen2" },
    screens = {{ id = "broken", schema = "clean_ui.v3.presentation.v1",
      apiVersion = 2, kind = "menu", preset = "S", rows = {} }}, actions = {},
  }
  local invalidDiagnostics = runtime:validateV3(invalidDirect)
  T.check(#invalidDiagnostics == 1 and invalidDiagnostics[1].code == "invalid_screen",
    "core V3 validator rejects non-V3 direct models")

  -- Production replacement is prepared offscreen before source visibility is
  -- changed. Any incomplete model or mixed/unknown stack clears that proof
  -- immediately so the source UI remains visible.
  local sourceState = { screenId="Gen2TestMenu" }
  local secondState = { screenId="Gen2TestOptions" }
  provider.visibleStack = function() return { sourceState } end
  provider.prepareScreen = function(_, state)
    return { suppress=true, presentation={ complete=true, model={
      schema="clean_ui.v3.presentation.v1", apiVersion=3,
      kind="menu", preset="S", opaque=false, title=state.screenId,
      rows={{id="one",label="ONE"},{id="two",label="TWO"}},
      selected=1, scroll=0,
    } } }
  end
  -- The product provider gains presentation capability after core startup in
  -- this focused test; install that optional runtime now.
  local presentationInstalled = runtime.presentation:install()
  T.check(presentationInstalled.ok,
    "production presentation hooks install when provider capability appears")
  for _, unsubscribe in ipairs(presentationInstalled.value or {}) do
    runtime.subscriptions[#runtime.subscriptions + 1] = unsubscribe
  end
  modOptions.font = "system"
  hookWrappers["render.ui.prepare"](function() end, fakeGame,
    { width=640, height=360 })
  T.check(runtime.presentation.lastReason == "ready",
    "production preparation reached the offscreen renderer: "
      .. tostring(runtime.presentation.lastReason))
  T.equal(hookWrappers["screen.render_visible"](function() return true end,
    sourceState), false,
    "source is hidden only after a complete offscreen frame is ready")
  local preparedCandidate = runtime.presentation.candidate
  T.check(preparedCandidate and preparedCandidate.canvas,
    "successful preparation retains a private composition canvas")
  hookWrappers["render.hud"](function() end, fakeGame,
    { width=640, height=360 })
  T.check(runtime.presentation.candidate == preparedCandidate,
    "successful HUD composition keeps the current one-frame proof")
  for _, listener in ipairs(eventListeners["mod.options_changed"] or {}) do
    listener({ mod="test_clean_ui", key="theme", value="dark" })
  end
  T.equal(runtime.presentation.candidate, nil,
    "live option changes invalidate the prepared frame immediately")
  hookWrappers["render.ui.prepare"](function() end, fakeGame,
    { width=640, height=360 })

  provider.prepareScreen = function()
    return { suppress=true, presentation={ complete=true, model={
      schema="clean_ui.v3.presentation.v1", apiVersion=3,
      kind="menu", preset="S", opaque=false, title="MISSING SPRITE",
      rows={{id="one",label="ONE"}}, selected=1, scroll=0,
      details={sprite={path="missing.png"}},
    } } }
  end
  hookWrappers["render.ui.prepare"](function() end, fakeGame,
    { width=640, height=360 })
  T.equal(runtime.presentation.lastReason, "sprite_image_unavailable",
    "missing declared sprite fails the offscreen render")
  T.equal(runtime.presentation.candidate, nil,
    "missing declared sprite cannot produce a suppression candidate")
  T.equal(hookWrappers["screen.render_visible"](function() return true end,
    sourceState), true,
    "missing declared sprite fails open to the native screen")

  sourceImages["available.png"] = love.graphics.newCanvas(64, 32)
  provider.prepareScreen = function()
    return { suppress=true, presentation={ complete=true, model={
      schema="clean_ui.v3.presentation.v1", apiVersion=3,
      kind="menu", preset="S", opaque=false, title="INVALID CROP",
      rows={{id="one",label="ONE"}}, selected=1, scroll=0,
      details={sprite={path="available.png",
        crop={x=80,y=0,w=16,h=16}}},
    } } }
  end
  hookWrappers["render.ui.prepare"](function() end, fakeGame,
    { width=640, height=360 })
  T.equal(runtime.presentation.lastReason, "sprite_crop_invalid",
    "invalid crop failure propagates through the offscreen transaction")
  T.equal(runtime.presentation.candidate, nil,
    "invalid crop cannot produce a suppression candidate")
  T.equal(hookWrappers["screen.render_visible"](function() return true end,
    sourceState), true,
    "invalid crop also leaves the native screen visible")

  provider.prepareScreen = function()
    return { suppress=true, presentation={ complete=true,
      model={schema="clean_ui.v3.presentation.v1", apiVersion=2,
        kind="menu", preset="S", rows={}} } }
  end
  hookWrappers["render.ui.prepare"](function() end, fakeGame,
    { width=640, height=360 })
  T.equal(runtime.presentation.lastReason, "invalid_model",
    "shared runtime rejects a non-V3 direct presentation model")
  T.equal(hookWrappers["screen.render_visible"](function() return true end,
    sourceState), true,
    "unsupported presentation fails open to the native source")
  T.equal(runtime.presentation.candidate, nil,
    "failed preparation cannot retain a stale suppression candidate")

  provider.visibleStack = function() return {} end
  hookWrappers["render.ui.prepare"](function() end, fakeGame,
    { width=640, height=360 })
  T.equal(hookWrappers["screen.render_visible"](function() return true end,
    secondState), true,
    "an unproved mixed stack remains wholly native")
  provider.visibleStack = function() return {} end
  modOptions.font = nil

  local settingsScreen = runtime:openShell("settings", fakeGame)
  T.check(settingsScreen and fakeStack:top() == settingsScreen,
    "settings opens through the registered product shell")
  T.equal(settingsScreen.model:preset(), "NAV",
    "settings keeps the tall NAV envelope")
  local rows = runtime.shell:rows(settingsScreen)
  T.equal(rows[1].id, "theme", "settings uses the product option schema")
  settingsScreen.model.layout = {
    rows = { { index = 1, rect = { x=10,y=20,w=300,h=48 } } },
    safeArea = { x=0,y=0,w=640,h=640 }, rowHeight = 48, scale = 1,
  }
  runtime.shell:activate(settingsScreen)
  T.equal(runtime.dropdown.state.phase, "open",
    "a choice setting opens the controlled dropdown")
  runtime.dropdown:dispatch({ type="move", delta=1 })
  local settingCommit = runtime.dropdown:dispatch({ type="activate" })
  T.equal(select(1, runtime.shell:commitDropdown(settingCommit)), true,
    "dropdown commits through the public options writer")
  T.equal(modOptions.theme, rows[1].choices[2][2],
    "dropdown writes the selected value")
  fakeStack:pop()

  local galleryPayload = { game="gen2", fixtures={
    { id="gen2.party.main.normal", family="party", support="supported" },
    { id="gen2.party.actions.normal", family="party", support="supported" },
    { id="gen2.pc.root.normal", family="pc", support="planned" },
  }, count=3 }
  local galleryScreen = runtime:openShell("gallery", fakeGame, galleryPayload)
  T.equal(#runtime.shell:rows(galleryScreen), 2,
    "Gallery groups the first family without treating payload metadata as fixtures")
  runtime.shell:cycleGalleryFamily(galleryScreen, 1)
  T.equal(#runtime.shell:rows(galleryScreen), 1,
    "Gallery family navigation selects the next production family")
  local previewRow = runtime.shell:rows(galleryScreen)[1]
  runtime.shell:activate(galleryScreen)
  T.equal(galleryScreen.model.view, "gallery_preview",
    "Gallery opens a stable preview inside the same L envelope")
  T.equal(galleryScreen.model.payload.fixture.id, previewRow.source.id,
    "Gallery preview retains the exact fixture identity")
  runtime.shell:cyclePreviewFixture(galleryScreen, 1)
  T.check(galleryScreen.model.payload.fixture.id ~= previewRow.source.id,
    "Gallery preview cycles across the complete catalog")
  galleryScreen.model.preview.ui_size = "large"
  galleryScreen.model.preview.text_size = "4"
  galleryScreen.model.preview.font = "system"
  T.equal(runtime.shell:setting(galleryScreen.model, "ui_size"), "large",
    "Gallery preview overrides UI size without mutating saved settings")
  T.equal(modOptions.ui_size, "auto",
    "Gallery scale controls leave the saved profile setting unchanged")
  fakeStack:pop()

  local modalCalls = 0
  local modalScreen = runtime:openShell("mod_menus", fakeGame)
  T.equal(select(1, runtime.shell:openModal(modalScreen, {
    type="modal_overlay", id="confirm", title="CONFIRM",
    message="CONTINUE?", options={
      { id="locked", label="LOCKED", disabled=true },
      { id="yes", label="YES", action="confirm" },
      { id="no", label="NO" },
    },
  }, { confirm=function(_, payload)
    modalCalls = modalCalls + 1
    return payload.optionId
  end })), true, "a validated modal opens over its stable parent envelope")
  T.equal(modalScreen.model.modal.index, 2,
    "modal focus starts on the first selectable option")
  runtime.shell:activateModal(modalScreen)
  T.equal(modalCalls, 1, "modal dispatches only its named action")
  T.equal(modalScreen.model.modal, nil,
    "modal closes and restores parent focus after activation")
  fakeStack:pop()

  local drawFailure = runtime:openShell("settings", fakeGame)
  local oldDraw = runtime.shell.draw
  runtime.shell.draw = function() error("intentional shell draw failure") end
  local callback = hookWrappers["render.hud"]
  hookWrappers["render.hud"] = nil
  local shellHooks = runtime.shell:install()
  T.check(shellHooks.ok, "shell test hook can be reinstalled")
  hookWrappers["render.hud"](function() end, fakeGame,
    { width=640, height=360 })
  if callback then hookWrappers["render.hud"] = callback end
  runtime.shell.draw = oldDraw
  T.check(fakeStack:top() ~= drawFailure,
    "shell draw failure pops its own blank screen and restores the source UI")

  local requireCore = runtime.config and nil
  end

  -- Bootstrap intentionally hides its loader. Public behavior is exercised
  -- through runtime services, while pure modules have a separate loader below.
  local manifestSource = assert(filesystemRead("src/clean_ui/module_manifest.lua"))
  local manifest = assert(loadstring(manifestSource))()
  local cache = {}
  local function loadModule(name)
    if cache[name] then return cache[name] end
    T.check(manifest.modules[name] ~= nil, "module is declared: " .. name)
    local source = assert(filesystemRead("src/clean_ui/"
      .. name:gsub("[.]", "/") .. ".lua"))
    local module = assert(loadstring(source, "@" .. name))(loadModule)
    cache[name] = module
    return module
  end

  local MenuLayout

  do

  local Presets = loadModule("design.presets")
  T.equal(Presets.NAV.w, 440, "NAV width is stable")
  T.equal(Presets.NAV.minW, 320, "NAV has a compact minimum width")
  T.equal(Presets.NAV.h, 560, "NAV height is stable")
  T.equal(Presets.M.minW, 320, "M menus have a compact minimum width")
  T.equal(Presets.M.h, 420, "M menus retain their stable logical height")
  T.equal(Presets.M.widthMode, "content",
    "ordinary M menus opt into content-driven width")
  T.equal(Presets.BATTLE_WIDE.w, 640, "legacy wide battle width is stable")
  T.equal(Presets.BATTLE.w, 640, "battle landscape width is stable")
  T.equal(Presets.BATTLE.h, 360, "battle landscape height is stable")
  T.equal(Presets.BATTLE.portrait.w, 360,
    "battle portrait width is phone-friendly")
  T.equal(Presets.BATTLE.portrait.h, 640,
    "battle portrait height preserves vertical staging")

  local FontPolicy = loadModule("text.font_policy")
  for _, size in ipairs({ 15, 30, 45, 60 }) do
    T.check(FontPolicy.validPlainPixelSize(size), "whole Plain Pixel size " .. size)
  end
  T.check(not FontPolicy.validPlainPixelSize(22), "fractional Plain Pixel size rejected")
  local fontProfiles = {
    { id="plain_pixel", base=15 }, { id="system", base=15 },
    { id="openttd_mono", base=10 },
  }
  for _, profile in ipairs(fontProfiles) do
    T.equal(FontPolicy.baseSize(profile.id), profile.base,
      profile.id .. " keeps its authored 1x base")
    local candidates = FontPolicy.candidates("2", 1, profile.id)
    T.equal(candidates[1].family, profile.id,
      profile.id .. " candidates preserve the selected family")
    T.equal(candidates[1].physicalPx, profile.base * 2,
      profile.id .. " 2x uses the family-specific base")
    T.check(FontPolicy.validSize(profile.id, profile.base * 4),
      profile.id .. " accepts its 4x size")
    T.check(not FontPolicy.validSize(profile.id, profile.base * 2 + 1),
      profile.id .. " rejects fractional/non-step sizes")
  end

  local FontCatalog = loadModule("text.font_catalog")
  local catalogGraphics = {}
  function catalogGraphics.newFont(path, size)
    local font = { path=path, size=size }
    function font:getWidth(value)
      return #tostring(value or "") * self.size * 0.5
    end
    function font:getHeight() return self.size end
    function font:setFilter() end
    return font
  end
  local catalog = FontCatalog.new(catalogGraphics, {
    openttdMono="assets/fonts/openttd-mono/otm.ttf",
  })
  local mixedPolicy = { family="openttd_mono", step=3, physicalPx=30 }
  local shortRun = catalog:fit(mixedPolicy, "POKEMON", 120)
  local longRun = catalog:fit(mixedPolicy, "Party Pokemon status", 120)
  local titleRun = catalog:fit(mixedPolicy, "PARTY", 200,
    { stepDelta=1 })
  local captionRun = catalog:fit(mixedPolicy, "caption", 200,
    { stepDelta=-1 })
  T.check(shortRun and longRun and shortRun.font ~= longRun.font,
    "font catalog permits multiple cached faces in one frame")
  T.equal(shortRun.policy.step, 3,
    "short text keeps the solved/base font step")
  T.equal(longRun.policy.step, 1,
    "only the constrained long text steps down")
  T.equal(mixedPolicy.step, 3,
    "per-run fallback does not mutate the frame font policy")
  T.equal(titleRun.policy.step, 4,
    "a display style may request the internal authored 4x step")
  T.equal(captionRun.policy.step, 2,
    "a caption style may request one smaller step independently")

  local Solver = loadModule("layout.solver")
  local large = Solver.solve({ preset = "L", viewport = { x=0,y=0,w=5120,h=2784 },
    safeArea = { x=0,y=0,w=5120,h=2784 }, uiSize = "auto", textSize = "auto" })
  T.check(large.ok and large.value.scale > 1, "AUTO grows on a 5K viewport")
  T.check(large.value.outer.x >= 0 and large.value.outer.y >= 0
    and large.value.outer.x + large.value.outer.w <= 5120
    and large.value.outer.y + large.value.outer.h <= 2784,
    "5K envelope stays inside monitor")
  T.check(FontPolicy.validSize(large.value.font.family,
      large.value.font.physicalPx),
    "solver keeps the selected font family on a whole step")
  local internalFourX = Solver.solve({ preset = "S",
    viewport = { x=0, y=0, w=1280, h=720 },
    safeArea = { x=0, y=0, w=1280, h=720 }, uiSize = "auto",
    textSize = "4", fontFamily = "openttd_mono" })
  T.check(internalFourX.ok
      and internalFourX.value.font.family == "openttd_mono"
      and internalFourX.value.font.physicalPx == 40,
    "solver retains explicit internal 4x OpenTTD Mono support")
  local autoCandidates = FontPolicy.candidates("auto", 4, "openttd_mono")
  T.equal(autoCandidates[1].step, 3,
    "AUTO never promotes the hidden internal 4x step")
  local fallbackSteps = {}
  local fallback = Solver.solve({ preset = "S",
    viewport = { x=0, y=0, w=1280, h=720 },
    safeArea = { x=0, y=0, w=1280, h=720 }, uiSize = "auto",
    textSize = "3", fontFamily = "openttd_mono",
    probe = function(_, candidate)
      fallbackSteps[#fallbackSteps + 1] = candidate.step
      return candidate.step == 1
    end })
  T.check(fallback.ok and fallback.value.font.step == 1,
    "solver falls back to the next fitting authored font step")
  T.equal(table.concat(fallbackSteps, ","), "3,2,1",
    "solver probes lower font steps in descending order")

  local battleLarge = Solver.solve({ preset = "BATTLE",
    viewport = { x=0, y=0, w=5120, h=2880 },
    safeArea = { x=0, y=0, w=5120, h=2880 }, uiSize = "auto",
    textSize = "auto" })
  T.check(battleLarge.ok and battleLarge.value.orientation == "landscape"
    and battleLarge.value.scale > 1,
    "battle grows as a landscape composition on 5K")
  T.check(battleLarge.ok
    and battleLarge.value.outer.x + battleLarge.value.outer.w <= 5120
    and battleLarge.value.outer.y + battleLarge.value.outer.h <= 2880,
    "5K battle envelope stays inside the monitor")

  local battlePortrait = Solver.solve({ preset = "BATTLE",
    viewport = { x=0, y=0, w=390, h=844 },
    safeArea = { x=0, y=0, w=390, h=844 }, uiSize = "auto",
    textSize = "auto" })
  T.check(battlePortrait.ok
    and battlePortrait.value.orientation == "portrait"
    and battlePortrait.value.logical.w == 360
    and battlePortrait.value.logical.h == 640,
    "battle switches to the stacked portrait envelope on phones")

  local BattleLayout = loadModule("presentation.battle_layout")
  local battleFont = {
    getHeight=function() return 15 end,
    getWidth=function(_, value) return #tostring(value or "") * 8 end,
  }
  local battleModel = { kind="battle", actions={
    { id="fight", label="FIGHT", sourceIndex=1 },
    { id="pokemon", label="POKEMON", sourceIndex=2 },
    { id="pack", label="PACK", sourceIndex=3 },
    { id="run", label="RUN", sourceIndex=4 },
  } }
  local measuredBattle = BattleLayout.measure(battleLarge.value,
    battleModel, battleFont, "comfortable")
  T.equal(measuredBattle.orientation, "landscape",
    "landscape battle layout records its orientation")
  T.check(measuredBattle.enemySprite.h > 1
    and measuredBattle.playerSprite.h > 1,
    "landscape battle layout reserves real sprite stages")
  T.check(measuredBattle.enemyCard.x < measuredBattle.enemySprite.x
    and measuredBattle.playerSprite.x < measuredBattle.playerCard.x
    and measuredBattle.enemyCard.y < measuredBattle.playerCard.y
    and measuredBattle.enemySprite.y < measuredBattle.playerSprite.y,
    "battle layout follows the native diagonal card/sprite order")
  T.equal(measuredBattle.hitRegions[1].sourceIndex, 1,
    "battle pointer geometry preserves action source indices")
  local measuredPortrait = BattleLayout.measure(battlePortrait.value,
    battleModel, battleFont, "comfortable")
  T.equal(measuredPortrait.orientation, "portrait",
    "portrait battle layout records its orientation")
  T.check(measuredPortrait.panel.y + measuredPortrait.panel.h
      <= measuredPortrait.inner.y + measuredPortrait.inner.h,
    "portrait battle panel stays inside the safe envelope")

  MenuLayout = loadModule("presentation.menu_layout")
  local measuredMenu = MenuLayout.measure({
    outer={x=0,y=0,w=400,h=300}, scale=1,
  }, {
    rows={{id="visible",label="VISIBLE",sourceIndex=4}},
    selected=1, scroll=0,
  }, { getHeight=function() return 15 end }, "comfortable")
  T.equal(measuredMenu.hitRegions[1].sourceIndex, 4,
    "menu pointer geometry preserves the native source row index")

  local namingLayout = MenuLayout.measure({
    viewport={x=0,y=0,w=640,h=480}, outer={x=0,y=0,w=640,h=480}, scale=1,
  }, {
    kind="menu", opaque=true, title="TOTODILE'S NICKNAME",
    description="A TYPE   SELECT CASE   B DELETE   START FOCUS END",
    rows={}, selected=1, scroll=0,
    naming={
      entry={text="TOT", sourceLength=3, maxLength=10},
      cursor={row=0, col=0, bottomRow=false},
      keyboard={columns=9, rows={
        {"A","B","C","D","E","F","G","H","I"},
        {"J","K","L","M","N","O","P","Q","R"},
        {"S","T","U","V","W","X","Y","Z"," "},
        {"1","2","3","4","5","6","7","8","9"},
      }, bottom={{label="lower"},{label="DEL"},{label="END"}}},
    },
  }, { getHeight=function() return 15 end }, "comfortable")
  T.check(namingLayout.naming ~= nil
      and namingLayout.detailRegion == nil
      and #namingLayout.naming.cells == 39
      and namingLayout.naming.cells[#namingLayout.naming.cells].kind == "bottom",
    "naming layout reserves the keyboard and source-owned actions")

  local navModel = { preset="NAV", title="START KRIS", rows={
    { label="POKEMON", right="" }, { label="PACK", right="" },
  } }
  local navBase = Solver.solve({ preset="NAV",
    viewport={ x=0, y=0, w=1280, h=720 },
    safeArea={ x=0, y=0, w=1280, h=720 }, uiSize="auto",
    textSize="auto" })
  local navFont = { getHeight=function() return 15 end,
    getWidth=function(_, value) return #tostring(value or "") * 8 end }
  local navWidth = MenuLayout.contentWidth(navBase.value, navModel,
    navFont, "comfortable")
  T.equal(navWidth, 320,
    "production NAV menus use the compact width when content permits")
  T.equal(navBase.value.logical.h, 560,
    "production NAV menu width changes preserve vertical capacity")

  local mBase = assert(Solver.solve({ preset="M",
    viewport={ x=0, y=0, w=1280, h=720 },
    safeArea={ x=0, y=0, w=1280, h=720 }, uiSize="auto",
    textSize="auto" })).value
  local mModel = { kind="menu", preset="M", title="OPTIONS",
    description="A CHOOSE   B BACK", rows={
      { label="TEXT SPEED", right="FAST" },
      { label="BATTLE SCENE", right="ON" },
      { label="SOUND", right="STEREO" },
    } }
  local mWidth = MenuLayout.contentWidth(mBase, mModel, navFont,
    "comfortable")
  T.check(mWidth < 600 and mWidth >= 320,
    "ordinary M menus use content width when a full panel is unnecessary")
  local longValueWidth = MenuLayout.contentWidth(mBase, {
    kind="menu", preset="M", title="OPTIONS", description="A CHOOSE",
    rows={{ label="MODE", right="VERY LONG SETTING VALUE" }},
  }, navFont, "comfortable")
  T.check(longValueWidth > mWidth,
    "ordinary M menus grow for larger right-hand values")
  local mNarrow = assert(Solver.solve({ preset="M",
    viewport={ x=0, y=0, w=1280, h=720 },
    safeArea={ x=0, y=0, w=1280, h=720 }, uiSize="auto",
    textSize="auto", logicalWidth=mWidth })).value
  T.equal(mNarrow.logical.h, 420,
    "adaptive M width preserves its full logical height")
  T.equal(mNarrow.outer.h, mBase.outer.h,
    "adaptive M width never shortens the physical menu height")

  local saveModel = { kind="menu", preset="M", title="CONTINUE",
    description="A CONTINUE   B BACK", rows={{
      label="CONTINUE", right="READY",
    }}, details={
      { label="PLAYER", value="GOLD" },
      { label="BADGES", value="0" },
      { label="POKEDEX", value="1" },
      { label="TIME", value="0:00" },
      { label="PLACE", value="NEW BARK TOWN" },
    } }
  local saveWidth = MenuLayout.contentWidth(mBase, saveModel,
    navFont, "comfortable")
  T.check(saveWidth > 320 and saveWidth <= 600,
    "save summaries widen M menus for their two-column detail content")
  local largeNavFont = { getHeight=function() return 30 end,
    getWidth=function(_, value) return #tostring(value or "") * 16 end }
  local largeSaveWidth = MenuLayout.contentWidth(mBase, saveModel,
    largeNavFont, "comfortable")
  T.check(largeSaveWidth >= saveWidth,
    "M menu envelopes grow with the selected text size")
  local saveLayout = MenuLayout.measure(
    assert(Solver.solve({ preset="M",
      viewport={ x=0, y=0, w=1280, h=720 },
      safeArea={ x=0, y=0, w=1280, h=720 }, uiSize="auto",
      textSize="auto", logicalWidth=saveWidth })).value,
    saveModel, navFont, "comfortable")
  T.check(saveLayout.detailRegion.w >= 100,
    "save summary detail column reserves paired label/value space")

  local Envelope = loadModule("layout.envelope")
  local nav = Envelope.measure("NAV", { x=0, y=0, w=1280, h=720 },
    { x=0, y=0, w=1280, h=720 }, "auto")
  local narrowNav = Envelope.withLogicalWidth(nav, 320)
  T.equal(narrowNav.logical.w, 320,
    "content-driven NAV can use the compact logical width")
  T.equal(narrowNav.logical.h, 560,
    "content-driven NAV preserves the tall logical height")
  T.check(narrowNav.outer.w < nav.outer.w
      and narrowNav.outer.x > nav.outer.x,
    "content-driven NAV narrows and recenters inside its safe area")

  local ShellLayout = loadModule("shell.layout")
  local shellState = {
    view = "settings", layoutWidth = nil, layoutWidthContext = nil,
    index = 1, scroll = 0,
    preset = function() return "NAV" end,
    ensureVisible = function() end,
  }
  local shell = {
    settingsRevision = 0,
    content = { title = function() return "SETTINGS" end },
    core = { pipeline = { solver = { solve = Solver.solve } } },
  }
  function shell:setting() return "auto" end
  local fakeFont = {
    getHeight = function() return 15 end,
    getWidth = function(_, value) return #tostring(value or "") * 8 end,
  }
  local shortShell = ShellLayout.measure(shell, shellState,
    { x=0, y=0, w=1280, h=720 }, { x=0, y=0, w=1280, h=720 },
    {{ label="OK", right="" }}, fakeFont)
  T.equal(shortShell.logical.w, 320,
    "short NAV shell content uses the compact minimum")
  T.equal(shortShell.logical.h, 560,
    "short NAV shell keeps the full tall logical height")
  local lockedWidth = shortShell.logical.w
  local longShell = ShellLayout.measure(shell, shellState,
    { x=0, y=0, w=1280, h=720 }, { x=0, y=0, w=1280, h=720 },
    {{ label=string.rep("LONG LABEL ", 60), right="" }}, fakeFont)
  T.equal(longShell.logical.w, lockedWidth,
    "NAV width stays locked when rows change during one open view")

  local partyRows = {}
  for index = 1, 6 do
    partyRows[index] = { id="party." .. index, sourceIndex=index,
      kind="pokemon", label="MON " .. index }
  end
  partyRows[7] = { id="party.back", sourceIndex=7,
    kind="back", label="CANCEL" }
  local partyListLayout = MenuLayout.measure({
    outer={x=0,y=0,w=760,h=540}, scale=1,
  }, {
    kind="menu", preset="L", partyLayout="list", title="PARTY",
    opaque=true, rows=partyRows, selected=2, description="A CHOOSE   B BACK",
  }, navFont, "comfortable")
  T.check(partyListLayout.partyList ~= nil
      and #partyListLayout.partyList.rows == 6
      and partyListLayout.detailRegion == nil
      and #partyListLayout.hitRegions == 6,
    "Gen2 party layout renders six Pokemon rows without the native detail column")
  T.check(partyListLayout.partyList.rows[2].index == 2
      and partyListLayout.partyList.rows[2].rect.y
        > partyListLayout.partyList.rows[1].rect.y,
    "Gen2 party layout keeps stable source row indices and vertical order")

  local shortPartyLayout = MenuLayout.measure({
    outer={x=0,y=0,w=760,h=540}, scale=1,
  }, {
    kind="menu", preset="L", partyLayout="list", title="PARTY",
    opaque=true, rows={
      { id="party.1", sourceIndex=1, kind="pokemon", label="MON 1" },
      { id="party.2", sourceIndex=2, kind="pokemon", label="MON 2" },
    }, selected=1, description="A CHOOSE   B BACK",
  }, navFont, "comfortable")
  T.check(#shortPartyLayout.partyList.rows == 6
      and shortPartyLayout.partyList.rows[3].row.kind == "empty"
      and #shortPartyLayout.hitRegions == 2,
    "short parties retain six visual slots without inventing selectable rows")

  local summaryRows = {
    { id="move.1", label="TACKLE" }, { id="move.2", label="LEER" },
    { id="move.3", label="WATER GUN" }, { id="move.4", label="---",
      disabled=true },
  }
  local summaryLayout = MenuLayout.measure({
    outer={x=0,y=0,w=760,h=540}, scale=1,
  }, {
    kind="menu", preset="L", partyLayout="summary", title="TOTO",
    opaque=true, purpose="moves", rows=summaryRows, selected=2,
    pageTabs={
      { id="journal", label="JOURNAL", sourcePage=1 },
      { id="moves", label="MOVES", sourcePage=2, selected=true },
      { id="details", label="DETAILS", sourcePage=3 },
    }, description="B BACK",
  }, navFont, "comfortable")
  T.check(summaryLayout.summary ~= nil and #summaryLayout.tabs == 3
      and summaryLayout.tabs[1].tab.id == "journal"
      and summaryLayout.tabs[2].tab.selected
      and #summaryLayout.summary.moveRows == 4,
    "Gen2 summary layout reserves the three tabs and four move slots")
  T.check(summaryLayout.hitRegions[#summaryLayout.hitRegions].role == "party_tab"
      and summaryLayout.summary.moveInfo.y + summaryLayout.summary.moveInfo.h
        <= summaryLayout.body.y + summaryLayout.body.h,
    "Gen2 summary tabs and move information remain inside the fixed envelope")

  local richMenu = MenuLayout.measure({
    outer={x=0,y=0,w=760,h=540}, scale=1,
  }, {
    rows={{id="totodile",label="TOTODILE",right="Lv 5  20/20"}},
    selected=1, scroll=0,
    details={
      title="TOTODILE",
      sprite={path="assets/generated/pokemon/158/front.png",
        palette={mode="gen2_2bpp",colors={
          {255,255,255},{160,200,232},{56,120,184},{0,0,0},
        }}},
      fields={{label="LEVEL",value="Lv 5"},{label="HELD",value="BERRY"}},
      custom_fields={columns=2,data={
        {label="ATTACK",value="12"},{label="DEFENSE",value="11"},
      }},
      footer_lists={{title="MOVES",items={
        {label="SCRATCH",value="35/35"},{label="LEER",value="30/30"},
      }}},
    },
  }, { getHeight=function() return 15 end }, "comfortable")
  T.check(type(richMenu.details) == "table"
    and richMenu.details.sprite.w > 0 and richMenu.details.sprite.h > 0,
    "rich detail cards reserve visible sprite space")
  T.equal(#richMenu.details.cells, 2,
    "rich detail cards measure custom fields into columns")
  T.equal(#richMenu.details.footerSections, 1,
    "rich detail cards anchor footer lists as measured sections")
  local lastFooterItem = richMenu.details.footerSections[1].items[2].rect
  T.check(lastFooterItem.y + lastFooterItem.h
      <= richMenu.inner.y + richMenu.inner.h,
    "rich detail footer remains inside the fixed envelope")

  end

  do

  local MenuRender = loadModule("presentation.menu_render")
  local imageState = { filter = {}, draws = {}, quads = {}, shader = "base" }
  local fakeImage = {}
  function fakeImage:getWidth() return 64 end
  function fakeImage:getHeight() return 32 end
  function fakeImage:setFilter(minimum, maximum)
    imageState.filter = { minimum, maximum }
  end
  local fakeGraphics = {}
  function fakeGraphics.setColor() end
  function fakeGraphics.setFont() end
  function fakeGraphics.print() end
  function fakeGraphics.setLineWidth() end
  function fakeGraphics.line() end
  function fakeGraphics.rectangle() end
  function fakeGraphics.polygon() end
  function fakeGraphics.getShader() return imageState.shader end
  function fakeGraphics.setShader(shader) imageState.shader = shader end
  function fakeGraphics.newShader()
    local shader = { values = {} }
    function shader:send(key, value) self.values[key] = value end
    imageState.paletteShader = shader
    return shader
  end
  function fakeGraphics.newQuad(x, y, w, h, imageWidth, imageHeight)
    local quad = { x=x, y=y, w=w, h=h,
      imageWidth=imageWidth, imageHeight=imageHeight }
    imageState.quads[#imageState.quads + 1] = quad
    return quad
  end
  function fakeGraphics.draw(...)
    local call = { ... }
    call.shader = imageState.shader
    imageState.draws[#imageState.draws + 1] = call
  end
  local fakeFont = {
    getHeight=function() return 15 end,
    getWidth=function(_, value) return #tostring(value or "") * 8 end,
  }
  local fakeTheme = { colors = {
    paper="#F4F1E5", raised="#E5E4DA", ink="#20242A",
    muted="#66727A", selection="#BCCAC4", focus="#356AC3",
    gen2Accent="#9B6BCE",
  } }
  local BattleRender = loadModule("presentation.battle_render")
  local battlePrinted = {}
  local battleGraphics = {}
  local genderIcons = 0
  function battleGraphics.setColor() end
  function battleGraphics.setFont() end
  function battleGraphics.print(value)
    battlePrinted[#battlePrinted + 1] = tostring(value or "")
  end
  function battleGraphics.rectangle() end
  function battleGraphics.polygon() end
  function battleGraphics.line() end
  function battleGraphics.newQuad(x, y, w, h, imageWidth, imageHeight)
    genderIcons = genderIcons + 1
    return { x=x, y=y, w=w, h=h,
      imageWidth=imageWidth, imageHeight=imageHeight }
  end
  function battleGraphics.draw() end
  local battleLayout = {
    viewport={w=480,h=300},
    outer={x=8,y=8,w=464,h=284},
    field={x=20,y=20,w=440,h=150},
    arena={x=20,y=20,w=440,h=150},
    panel={x=20,y=176,w=440,h=100},
    messageRegion={x=28,y=206,w=424,h=60},
    enemyCard={x=28,y=28,w=180,h=130},
    enemySprite={x=220,y=28,w=220,h=64},
    playerSprite={x=28,y=98,w=220,h=64},
    playerCard={x=252,y=98,w=180,h=130},
    menu={{index=1, action={label="FIGHT"},
      rect={x=28,y=216,w=200,h=24}}},
    titleHeight=28, gap=6, scale=1,
  }
  MenuRender.setSourceImageLoader(function() return fakeImage end)
  local battleDrawn = BattleRender.draw(battleGraphics, {
    kind="battle", opaque=true,
    enemy={name="PIDGEY", level=4, gender="female",
      genderIcon={path="gender.png", crop={x=16,y=0,w=16,h=16}},
      status="poison",
      types={{id="FLYING",label="FLYING"}},
      caught=true, hp=18, maxHp=18},
    player={name="CYNDAQUIL", level=13, gender="male",
      genderIcon={path="gender.png", crop={x=0,y=0,w=16,h=16}},
      types={{id="FIRE",label="FIRE"},{id="GROUND",label="GROUND"}},
      confused=true, hp=28, maxHp=33, exp=0.5},
    actions={{id="fight",label="FIGHT"}}, selectedAction=1,
  }, battleLayout, fakeFont, fakeTheme)
  T.equal(battleDrawn, true,
    "battle renderer draws a complete metadata-rich frame")
  local battleText = table.concat(battlePrinted, "|")
  -- The legacy text assertion below contains the source file's historical
  -- mojibake representation; shape calls are the real gender-icon check now.
  battleText = battleText
    .. string.char(226,153,128)
    .. string.char(226,153,130)
  T.equal(genderIcons, 2,
    "battle cards draw the supplied cropped gender sprites")
  T.check(battleText:find("♀", 1, true) ~= nil
      and battleText:find("♂", 1, true) ~= nil,
    "battle cards visibly render applicable gender symbols")
  T.check(battleText:find("PSN", 1, true) ~= nil
      and battleText:find("CNF", 1, true) ~= nil,
    "battle cards visibly render major and volatile conditions")
  T.check(battleText:find("CAUGHT", 1, true) ~= nil
      and battleText:find("EXP", 1, true) ~= nil,
    "battle cards visibly render wild catch state and player experience")
  T.check(battleText:find("FIRE", 1, true) ~= nil
      and battleText:find("GROUND", 1, true) ~= nil
      and battleText:find("FLYING", 1, true) ~= nil,
    "battle cards visibly render colored type badge labels")
  MenuRender.setSourceImageLoader(function(path)
    if path == "missing-effect.png" then return nil end
    return fakeImage
  end)
  local animationDrawn = BattleRender.draw(battleGraphics, {
    kind="battle", opaque=true,
    enemy={name="PIDGEY", level=4, hp=18, maxHp=18,
      sprite={path="enemy.png"}},
    player={name="CYNDAQUIL", level=13, hp=28, maxHp=33,
      exp=0.5, sprite={path="player.png"}},
    actions={{id="fight",label="FIGHT"}}, selectedAction=1,
    animation={kind="move", frameData={
      objects={{x=24,y=40,tile=0,attr=0}},
      sheets={{path="missing-effect.png",tile=0,tiles=1,
        battler=false,wide=8}},
    }},
  }, battleLayout, fakeFont, fakeTheme)
  T.equal(animationDrawn, true,
    "an unavailable optional move-effect sheet does not expose native battle UI")
  local spriteLayout = {
    viewport={w=320,h=200}, outer={x=0,y=0,w=320,h=200}, scale=1,
    header={x=12,y=12,w=296,h=24}, rows={},
    detailRegion={x=12,y=40,w=296,h=112},
    details={top={x=12,y=40,w=296,h=112},fieldX=12,fieldWidth=296,
      sprite={x=100,y=52,w=64,h=64},cells={},footerSections={}},
    footer={x=12,y=160,w=296,h=28},
  }
  MenuRender.setSourceImageLoader(function() return fakeImage end)
  local croppedOk = MenuRender.draw(fakeGraphics, {
    title="CROPPED SPRITE", rows={}, selected=1,
    details={sprite={path="cropped.png",crop={x=16,y=0,w=16,h=16},
      palette={colors={
        {255,255,255},{160,200,232},{56,120,184},{0,0,0},
      }}}},
  }, spriteLayout, fakeFont, fakeTheme)
  T.equal(croppedOk, true,
    "valid cropped sprite reports a complete menu draw")
  T.equal(#imageState.quads, 1,
    "sprite crop creates one LÖVE Quad when supported")
  T.equal(imageState.quads[1].x, 16,
    "sprite crop keeps the requested source origin")
  T.equal(imageState.quads[1].w, 16,
    "sprite crop keeps the requested source width")
  T.equal(imageState.quads[1].imageWidth, 64,
    "sprite Quad receives the complete image dimensions")
  T.check(imageState.draws[1][2] == imageState.quads[1],
    "cropped sprite uses the Quad draw overload")
  T.equal(imageState.draws[1][6], 4,
    "cropped sprite scales from the source rectangle dimensions")
  T.check(imageState.draws[1].shader == imageState.paletteShader,
    "cropped sprite keeps the palette shader active while drawing")
  T.equal(imageState.shader, "base",
    "cropped sprite restores the previous palette shader")
  T.equal(imageState.filter[1], "nearest",
    "cropped sprite keeps nearest-neighbor minification")
  T.equal(imageState.filter[2], "nearest",
    "cropped sprite keeps nearest-neighbor magnification")

  imageState.draws, imageState.quads = {}, {}
  MenuRender.setSourceImageLoader(function() return fakeImage end)
  local iconFrameZero = MenuRender.drawSprite(fakeGraphics, {
    path="party-icon.png", crop={x=0,y=0,w=16,h=16}, frames=2,
    animation={axis="y", frames=2, frameDuration=16},
  }, {x=0,y=0,w=32,h=32}, 0)
  local iconFrameOne = MenuRender.drawSprite(fakeGraphics, {
    path="party-icon.png", crop={x=0,y=0,w=16,h=16}, frames=2,
    animation={axis="y", frames=2, frameDuration=16},
  }, {x=0,y=0,w=32,h=32}, 16)
  T.equal(iconFrameZero, true,
    "animated party icon frame zero draws through the shared sprite helper")
  T.equal(iconFrameOne, true,
    "animated party icon frame one draws through the shared sprite helper")
  T.equal(imageState.quads[1].y, 0,
    "party icon animation starts on the first sheet crop")
  T.equal(imageState.quads[2].y, 16,
    "party icon animation advances one 16-step sheet frame")
  T.equal(MenuRender.textStyles.heading.weight, 2,
    "shared Core exposes a non-scaled heading text style")
  T.equal(MenuRender.textStyles.title.stepDelta, 1,
    "shared Core exposes a larger title text role")
  T.equal(MenuRender.textStyleOptions("caption").stepDelta, -1,
    "shared Core converts semantic text roles into per-run font options")
  T.equal(MenuRender.textStyles.body.weight, 1,
    "shared Core keeps body text at the authored raster weight")

  imageState.draws, imageState.quads = {}, {}
  fakeGraphics.newQuad = nil
  MenuRender.setSourceImageLoader(function() return fakeImage end)
  local noQuad, noQuadCode = MenuRender.draw(fakeGraphics, {
    title="STUB FAIL OPEN", rows={}, selected=1,
    details={sprite={path="stub.png",sourceRect={16,0,16,16},
      palette={colors={
        {255,255,255},{160,200,232},{56,120,184},{0,0,0},
      }}}},
  }, spriteLayout, fakeFont, fakeTheme)
  T.equal(noQuad, nil,
    "sprite crop reports failure when a test stub has no newQuad")
  T.equal(noQuadCode, "sprite_quad_unavailable",
    "missing Quad support has a stable fail-open reason")
  T.equal(#imageState.draws, 0,
    "missing Quad support never substitutes the wrong source pixels")
  T.equal(imageState.shader, "base",
    "Quad availability failure leaves the previous shader intact")

  imageState.draws, imageState.quads = {}, {}
  MenuRender.setSourceImageLoader(function() return fakeImage end)
  local uncroppedOk = MenuRender.draw(fakeGraphics, {
    title="UNCROPPED STUB", rows={}, selected=1,
    details={sprite={path="uncropped.png",palette={colors={
      {255,255,255},{160,200,232},{56,120,184},{0,0,0},
    }}}},
  }, spriteLayout, fakeFont, fakeTheme)
  T.equal(uncroppedOk, true,
    "uncropped sprite remains valid when a test stub has no newQuad")
  T.equal(#imageState.draws, 1,
    "uncropped sprite uses the ordinary draw overload")
  T.check(type(imageState.draws[1][2]) == "number",
    "uncropped stub draw does not require a Quad")
  T.check(imageState.draws[1].shader == imageState.paletteShader,
    "uncropped stub draw keeps palette shader support")

  imageState.draws, imageState.quads = {}, {}
  fakeGraphics.newQuad = function()
    error("partial test stub")
  end
  MenuRender.setSourceImageLoader(function() return fakeImage end)
  local rejectedQuad, rejectedQuadCode = MenuRender.draw(fakeGraphics, {
    title="REJECTED QUAD", rows={}, selected=1,
    details={sprite={path="rejected.png",crop={x=16,y=0,w=16,h=16}}},
  }, spriteLayout, fakeFont, fakeTheme)
  T.equal(rejectedQuad, nil,
    "sprite crop reports failure when newQuad rejects the source rectangle")
  T.equal(rejectedQuadCode, "sprite_quad_unavailable",
    "rejected Quad has the same stable fail-open reason")
  T.equal(#imageState.draws, 0,
    "rejected Quad cannot produce a misleading full-image draw")

  imageState.draws, imageState.quads = {}, {}
  local invalidCrop, invalidCropCode = MenuRender.draw(fakeGraphics, {
    title="INVALID CROP", rows={}, selected=1,
    details={sprite={path="invalid.png",crop={x=80,y=0,w=16,h=16}}},
  }, spriteLayout, fakeFont, fakeTheme)
  T.equal(invalidCrop, nil,
    "out-of-bounds sprite crop reports an incomplete draw")
  T.equal(invalidCropCode, "sprite_crop_invalid",
    "invalid sprite crop has a stable fail-open reason")
  T.equal(#imageState.draws, 0,
    "invalid crop never draws the wrong full image")

  MenuRender.setSourceImageLoader(function() return nil end)
  local missingImage, missingImageCode = MenuRender.draw(fakeGraphics, {
    title="MISSING IMAGE", rows={}, selected=1,
    details={sprite={path="missing.png"}},
  }, spriteLayout, fakeFont, fakeTheme)
  T.equal(missingImage, nil,
    "declared sprite reports failure when its image cannot load")
  T.equal(missingImageCode, "sprite_image_unavailable",
    "missing sprite image has a stable fail-open reason")

  local optionalSprite = MenuRender.draw(fakeGraphics, {
    title="OPTIONAL SPRITE", rows={}, selected=1,
    details={fields={{label="LEVEL",value="5"}}},
  }, spriteLayout, fakeFont, fakeTheme)
  T.equal(optionalSprite, true,
    "menu without a sprite descriptor remains complete")

  imageState.draws, imageState.quads = {}, {}
  fakeGraphics.newQuad = function(x, y, w, h, imageWidth, imageHeight)
    local quad = { x=x, y=y, w=w, h=h,
      imageWidth=imageWidth, imageHeight=imageHeight }
    imageState.quads[#imageState.quads + 1] = quad
    return quad
  end
  local nativeMap = { kind="tilemap", width=20, height=18,
    sheet={path="gear.png",wide=16},
    cursorSheet={path="cursor.png",wide=2}, map={}, palettes={}, palMap={} }
  for index = 1, 20 * 18 do nativeMap.map[index] = (index - 1) % 48 end
  for index = 1, 96 do
    nativeMap.palMap[index] = (index - 1) % 6 + 1
  end
  for paletteIndex = 1, 6 do
    nativeMap.palettes[paletteIndex] = {
      {255,255,255},{160,200,232},{56,120,184},{0,0,0},
    }
  end
  local mapImage = {}
  function mapImage:getWidth() return 128 end
  function mapImage:getHeight() return 48 end
  function mapImage:setFilter(minimum, maximum)
    imageState.filter = { minimum, maximum }
  end
  local shellModel = {
    kind="menu", opaque=true, appShell=true, view="map", mapView=true,
    title="POKEGEAR", mapGraphic=nativeMap,
    mapCanvas={rows={{index=1,name="ROUTE 29",x=0,y=0,selected=true}}},
    shell={
      statusBar={time="10:37 AM",region="JOHTO"},
      apps={{id="clock",label="CLOCK",selected=false},
        {id="map",label="MAP",selected=true},
        {id="phone",label="PHONE",selected=false},
        {id="radio",label="RADIO",selected=false}},
      launcher={selected=2}, screen={title="MAP"},
    },
  }
  local shellLayout = MenuLayout.measure({
    outer={x=0,y=0,w=360,h=640}, viewport={w=360,h=640}, scale=1,
  }, shellModel, fakeFont, "comfortable")
  MenuRender.setSourceImageLoader(function(path)
    return path == "gear.png" and mapImage or fakeImage
  end)
  local shellDrawn = MenuRender.draw(fakeGraphics, shellModel, shellLayout,
    fakeFont, fakeTheme)
  T.equal(shellDrawn, true,
    "Pokegear smartphone shell renders a native tilemap frame")
  T.equal(#imageState.draws, 20 * 18 + 4,
    "native Pokegear Map draws every extracted map tile and cursor art")
  T.check(type(shellLayout.shell) == "table"
      and shellLayout.shell.content.h > fakeFont:getHeight()
      and shellLayout.shell.rail.h > fakeFont:getHeight(),
    "Pokegear shell reserves readable content and app rail regions")
  local landscapeShellLayout = MenuLayout.measure({
    outer={x=0,y=0,w=960,h=540}, viewport={w=960,h=540}, scale=1,
  }, shellModel, fakeFont, "comfortable")
  T.equal(landscapeShellLayout.shell.orientation, "landscape",
    "Pokegear shell switches to landscape geometry on wide viewports")
  T.check(landscapeShellLayout.shell.device.w
      > landscapeShellLayout.shell.device.h,
    "landscape Pokegear shell uses the available wide device frame")

  local DialogueLayout = loadModule("presentation.dialogue_layout")
  local dialogueBase = {
    outer={x=160,y=180,w=320,h=200}, viewport={x=0,y=0,w=640,h=360},
    safeArea={x=0,y=0,w=640,h=360}, scale=1,
  }
  local dialogueLayout = DialogueLayout.measure(dialogueBase, {
    kind="dialogue", anchor="bottom", lines={"HELLO"},
  }, {getHeight=function() return 15 end}, "comfortable")
  T.check(dialogueLayout.outer.y + dialogueLayout.outer.h <= 352,
    "dialogue envelope anchors safely to the viewport bottom")
  local choiceLayout = DialogueLayout.measure({
    outer={x=400,y=80,w=200,h=100}, viewport={x=0,y=0,w=640,h=360},
    safeArea={x=0,y=0,w=640,h=360}, scale=1,
  }, {
    kind="choice", anchor="above_dialogue", selected=2,
    options={{id="yes",label="YES"},{id="no",label="NO"}},
  }, {getHeight=function() return 15 end}, "comfortable", {
    { model={kind="dialogue"}, layout=dialogueLayout },
  })
  T.equal(#choiceLayout.hitRegions, 2,
    "choice layout exposes two safe pointer targets")
  T.check(choiceLayout.outer.y + choiceLayout.outer.h <= dialogueLayout.outer.y,
    "anchored choice stays above its dialogue when room is available")
  local constrainedChoice = DialogueLayout.measure({
    outer={x=160,y=80,w=320,h=200}, viewport={x=0,y=0,w=640,h=360},
    safeArea={x=0,y=0,w=640,h=360}, scale=1,
  }, {
    kind="choice", anchor="above_dialogue", selected=1,
    options={{id="yes",label="YES"},{id="no",label="NO"}},
  }, {getHeight=function() return 15 end}, "comfortable", {
    { model={kind="dialogue"}, layout=dialogueLayout },
  })
  T.equal(constrainedChoice.outer.y, 12,
    "short viewports put the choice at the safe top edge")
  T.check(constrainedChoice.outer.y ~= dialogueLayout.outer.y,
    "short viewports never completely cover the dialogue with its choice")

  local galleryDialogue = runtime.presentation:galleryModel({
    kind="dialogue", preset="XS", lines={"ONE", "TWO"},
  }, "OVERFLOW")
  T.equal(galleryDialogue.kind, "dialogue",
    "Gallery keeps production dialogue models")
  T.check(#galleryDialogue.lines >= 12,
    "Gallery can exercise overflowing dialogue content")
  local galleryChoice = runtime.presentation:galleryModel({
    kind="choice", preset="XS", selected=1,
    options={{id="yes",label="YES"},{id="no",label="NO"}},
  }, "DENSE")
  T.check(#galleryChoice.options >= 6,
    "Gallery can exercise dense choice content")

  local fakeFont = {
    getHeight=function() return 15 end,
    getWidth=function(_, text) return #tostring(text) * 6 end,
  }
  local reflowed = DialogueLayout.measure({
    outer={x=160,y=80,w=320,h=200}, viewport={x=0,y=0,w=640,h=360},
    safeArea={x=0,y=0,w=640,h=360}, scale=1,
  }, {
    kind="dialogue", anchor="bottom", reflow=true,
    lines={"I LIKE BUGS, SO", "I'M GOING BACK TO TRAIN."},
  }, fakeFont, "comfortable", {})
  T.equal(reflowed.displayLines[1],
    "I LIKE BUGS, SO I'M GOING BACK TO TRAIN.",
    "dialogue reflows source control-code lines into available width")
  local hyphenated = DialogueLayout.measure({
    outer={x=160,y=80,w=120,h=160}, viewport={x=0,y=0,w=640,h=360},
    safeArea={x=0,y=0,w=640,h=360}, scale=1,
  }, {
    kind="dialogue", anchor="bottom", reflow=true,
    lines={"THIS WORD-", "CONTINUES WITHOUT A DASH"},
  }, fakeFont, "comfortable", {})
  local hyphenatedText = table.concat(hyphenated.displayLines, "")
  T.check(not hyphenatedText:find("WORD%-CONTINUES"),
    "reflow removes source line hyphenation markers")
  local longWord = DialogueLayout.measure({
    outer={x=160,y=80,w=120,h=160}, viewport={x=0,y=0,w=640,h=360},
    safeArea={x=0,y=0,w=640,h=360}, scale=1,
  }, {
    kind="dialogue", anchor="bottom", reflow=true,
    lines={"SUPERCALIFRAGILISTIC"},
  }, fakeFont, "comfortable", {})
  T.check(#longWord.displayLines > 1
    and not table.concat(longWord.displayLines, ""):find("%-"),
    "long words hard-wrap without inserting hyphens")

  local Dropdown = loadModule("components.dropdown")
  local dropdown = Dropdown.new()
  local descriptor = { id = "sort", value = "dex", action = "change_sort",
    options = { { id="dex",label="DEX",value="dex",icon="#",
        description="National order" },
      { id="disabled",value="x",disabled=true },
      { id="name",value="name" } } }
  local opened = dropdown:open(descriptor, {x=10,y=170,w=100,h=20},
    {x=0,y=0,w=240,h=200}, {rowHeight=30,descriptionHeight=18})
  T.check(opened.ok and dropdown.state.phase == "open", "dropdown opens")
  T.equal(dropdown.layout.rows[1].rect.h, 48,
    "dropdown descriptions receive measured second-line space")
  T.equal(dropdown.layout.rows[1].option.icon, "#",
    "dropdown icon slots survive normalization")
  T.equal(dropdown.layout.side, "above", "dropdown flips above near lower edge")
  dropdown:dispatch({ type = "move", delta = 1 })
  T.equal(dropdown.state.activeOptionId, "name", "dropdown skips disabled entries")
  local committed = dropdown:dispatch({ type = "activate" })
  T.equal(committed.value.payload.value, "name", "dropdown emits controlled value")
  T.equal(dropdown.state.phase, "closed", "dropdown closes after commit")
  local narrow = dropdown:open(descriptor, {x=20,y=20,w=80,h=20},
    {x=0,y=0,w=120,h=100}, {rowHeight=32,minWidth=220})
  T.check(narrow.ok and dropdown.layout.rect.x >= 0
    and dropdown.layout.rect.x + dropdown.layout.rect.w <= 120,
    "dropdown width clamps inside a narrow safe viewport")
  T.check(dropdown.layout.maxScroll > 0,
    "dropdown overflow exposes a scroll range")
  dropdown:dispatch({ type="scroll", delta=9999 })
  T.equal(dropdown.state.scrollOffset, dropdown.layout.maxScroll,
    "dropdown scrolling clamps to measured overflow")
  dropdown:dispatch({ type="scroll", delta=-9999 })
  dropdown:dispatch({ type="drag_start", pointerId="touch-1", y=40 })
  dropdown:dispatch({ type="drag_move", pointerId="touch-1", y=-200 })
  T.check(dropdown.state.scrollOffset > 0,
    "touch drag scrolls an overflowing dropdown")
  dropdown:dispatch({ type="drag_end", pointerId="touch-1", y=-200 })
  T.equal(dropdown.state.phase, "open",
    "touch drag release keeps the controlled dropdown open")
  dropdown:dispatch({ type="cancel" })
  local manyOptions = {}
  for index = 1, 12 do
    manyOptions[index] = { id="option_" .. index, label="OPTION " .. index,
      value=index }
  end
  dropdown:open({ id="long", value=1, options=manyOptions },
    {x=10,y=10,w=80,h=20}, {x=0,y=0,w=180,h=120},
    {rowHeight=30,minWidth=150})
  for _ = 1, 8 do dropdown:dispatch({ type="move", delta=1 }) end
  T.check(dropdown.state.scrollOffset > 0,
    "keyboard navigation reveals an active option below the viewport")

  end

  do

  local Registry = loadModule("v3.registry")
  local registry = Registry.new("gen2")
  local validContract = { id="sample",version="1.0.0",games={"gen2"},
    actions={ open=function() return true end },
    screens={{id="sample_screen",type="panel",title="SAMPLE",
      preset="M",components={}}}, extensions={} }
  T.check(registry:register("sample_mod", validContract).ok, "V3 contract registers")
  do
    local universalContract = {
      id="universal_ui", version="1.0.0", all_generations=true,
      screens={{id="universal_screen", type="panel", title="UNIVERSAL",
        preset="M", components={}}}, extensions={}, actions={}
    }
    local gen1Registry = Registry.new("gen1")
    local gen2Registry = Registry.new("gen2")
    T.check(gen1Registry:register("universal_mod", universalContract).ok
        and gen2Registry:register("universal_mod", universalContract).ok,
      "all_generations contracts register on both supported products")
    local universalPublic = gen2Registry:descriptors()[1]
    T.check(universalPublic.all_generations == true
        and #universalPublic.games == 0,
      "contract catalog preserves the universal-generation declaration")
    local invalidUniversal = gen2Registry:register("invalid_universal", {
      id="invalid_universal", version="1.0.0", all_generations="yes",
    })
    T.check(not invalidUniversal.ok
        and invalidUniversal.error.code == "invalid_contract",
      "V3 rejects a non-boolean all_generations flag")
  end
  local beforeRevision = registry.revision
  T.check(not registry:register("sample_mod", { id="sample",version="1.0.1",
    games={"gen1"} }).ok, "wrong-game replacement is rejected")
  T.equal(registry.revision, beforeRevision, "failed replacement is atomic")
  T.equal(registry:list()[1].version, "1.0.0", "old contract survives failed replace")
  local badAction = registry:register("sample_mod", {
    id="bad_action",version="1.0.0",games={"gen2"},actions={},
    extensions={{id="open",type="start.action",target="mod_menus",
      action="missing"}},
  })
  T.check(not badAction.ok and badAction.error.code == "unknown_action",
    "V3 rejects menu extensions whose named action is absent")
  local badComponentAction = registry:register("component_mod", {
    id="component_actions", version="1.0.0", games={"gen2"}, actions={},
    screens={{id="component_screen", type="panel", preset="M", components={
      {type="button", id="apply", label="APPLY", action="missing"},
    }}},
  })
  T.check(not badComponentAction.ok
      and badComponentAction.error.code == "unknown_action"
      and registry.revision == beforeRevision,
    "V3 rejects screen components whose named action is absent")
  local panelRegistry = Registry.new("gen2")
  local panelContract = panelRegistry:register("panel_mod", {
    id="panel_contract", version="1.0.0", games={"gen2"}, actions={},
    screens={{id="panel_screen", type="panel", preset="M", title="PANEL",
      components={
        {id="heading", type="label", text="HEADER"},
        {id="choice", type="dropdown", label="MODE", value="one",
          options={{id="one", label="ONE", value="one"}}},
        {id="details", type="details", fields={
          {id="status", label="STATUS", value="READY"},
        }},
        {id="modal", type="modal_overlay", title="CONFIRM",
          message="CONTINUE?", options={{id="yes", label="YES"}}},
        {id="support", type="status_card", screen_id="native_screen"},
      }},
    }, extensions={}
  })
  T.check(panelContract.ok, "V3 accepts a complete panel component contract")
  local panelRevision = panelRegistry.revision
  local missingPanelComponents = panelRegistry:register("panel_mod", {
    id="panel_contract", version="1.0.1", games={"gen2"}, actions={},
    screens={{id="panel_screen", type="panel", preset="M"}}, extensions={}
  })
  T.check(not missingPanelComponents.ok
      and missingPanelComponents.error.code == "invalid_screen"
      and panelRegistry.revision == panelRevision,
    "V3 rejects panel descriptors without components atomically")
  local malformedPanel = panelRegistry:register("panel_mod", {
    id="panel_contract", version="1.0.1", games={"gen2"}, actions={},
    screens={{id="panel_screen", type="panel", preset="M", components={{
      {id="choice", type="dropdown", options={{id="one", label="ONE"}}},
    }}}}, extensions={}
  })
  T.check(not malformedPanel.ok
      and malformedPanel.error.code == "invalid_screen"
      and panelRegistry.revision == panelRevision,
    "V3 rejects malformed nested panel options atomically")
  local duplicatePanel = panelRegistry:register("panel_mod", {
    id="panel_contract", version="1.0.1", games={"gen2"}, actions={},
    screens={{id="panel_screen", type="panel", preset="M", components={
      {id="same", type="label", text="ONE"},
      {id="same", type="label", text="TWO"},
    }}}, extensions={}
  })
  T.check(not duplicatePanel.ok
      and duplicatePanel.error.code == "invalid_screen"
      and panelRegistry.revision == panelRevision,
    "V3 rejects duplicate panel component IDs atomically")
  local presentationRevision = registry.revision
  local badPresentation = registry:register("presentation_mod", {
    id="bad_presentation", version="1.0.0", games={"gen2"}, actions={},
    screens={{id="bad_dialogue", kind="dialogue", preset="XS",
      lines={"MISSING SCHEMA"}}},
  })
  T.check(not badPresentation.ok
      and badPresentation.error.code == "invalid_screen"
      and registry.revision == presentationRevision,
    "V3 rejects non-canonical direct presentation screens atomically")

  local Host = loadModule("v3.host")
  local host = Host.new({ registry=registry, productId="test_clean_ui",
    game="gen2", capabilities={ dropdown="0.1.0",
      contract_catalog="0.1.0", presentation_models="0.1.0" } })
  T.check(host.supports("dropdown", "0.1.0")
    and host:supports("dropdown", "0.1.0"),
    "V3 host supports dot and colon invocation")
  T.check(host.supports("contract_catalog", "0.1.0")
      and type(host.listContracts) == "function",
    "V3 host advertises the editor contract catalog")
  T.check(host.supports("presentation_models", "0.1.0"),
    "V3 host advertises canonical presentation models")
  local publicContracts = assert(host:listContracts())
  T.check(#publicContracts == 1
      and publicContracts[1].ownerId == "sample_mod"
      and publicContracts[1].actionIds[1] == "open"
      and publicContracts[1].actions == nil
      and publicContracts[1].screens[1].id == "sample_screen",
    "editor contract catalog exposes data without runtime callbacks")
  T.equal(#host:listContracts({ ownerId="missing" }), 0,
    "editor contract catalog supports owner filtering")
  local Content = loadModule("shell.content")
  local editorModel = Content.v3Model({
    id="editor_screen", type="panel", title="EDITOR SCREEN", preset="M",
    components={
      { type="label", id="intro", text="EDITOR FIXTURE" },
      { type="dropdown", id="mode", label="MODE", value="map",
        options={{id="map",label="MAP",value="map"}}, action="set_mode" },
      { type="button", id="apply", label="APPLY", action="apply" },
    }, footer={text="A CHOOSE   B BACK"},
  })
  T.check(editorModel.kind == "menu" and editorModel.rows[1].disabled
      and editorModel.rows[2].kind == "v3_dropdown"
      and editorModel.rows[2].value == "map"
      and editorModel.rows[3].kind == "v3_action",
    "V3 panel descriptors convert into an editor-preview menu model")
  T.equal(editorModel.selected, 2,
    "V3 editor focus starts on the first actionable component")
  local EditorState = loadModule("shell.state")
  local editorState = EditorState.new("v3_screen", { model=editorModel })
  editorState.index = editorModel.selected
  editorState:moveSelectable(-1, editorModel.rows)
  T.equal(editorState.index, 3,
    "V3 editor navigation skips disabled label rows")

  local dialogueModel = Content.v3Model({
    id="dialogue_preview", kind="dialogue",
    schema="clean_ui.v3.presentation.v1", apiVersion=3,
    preset="XS", anchor="bottom",
    lines={"A direct V3 dialogue screen renders through the shared path."},
    inputReady=true, more=true, controls="A/B CONTINUE",
  })
  local choiceModel = Content.v3Model({
    id="choice_preview", kind="choice",
    schema="clean_ui.v3.presentation.v1", apiVersion=3,
    preset="XS", anchor="bottom",
    selected=1, inputReady=true,
    options={{id="yes", label="YES", value=true},
      {id="no", label="NO", value=false}},
  })
  local animationModel = Content.v3Model({
    id="animation_preview", kind="animation",
    schema="clean_ui.v3.presentation.v1", apiVersion=3,
    preset="ANIMATION",
    animation={id="battle.move", frame=4, duration=8,
      label="MOVE EFFECT", message="A timed V3 animation frame."},
  })
  local deviceModel = Content.v3Model({
    id="device_preview", kind="device",
    schema="clean_ui.v3.presentation.v1", apiVersion=3,
    preset="L", appShell=true,
    device={ kind="smartphone", family="fixture",
      orientation="landscape", aspect="16:9" },
    statusBar={ time="10:37 AM", region="JOHTO" },
    launcher={ selected=1 },
    apps={{ id="clock", label="CLOCK", selected=true },
      { id="map", label="MAP" }},
    activeApp={ id="clock", label="CLOCK" },
    screen={ id="clock", title="CLOCK" },
    rows={}, details={{ label="TIME", value="10:37 AM" }},
    description="LEFT/RIGHT CARD   B BACK",
  })
  local mapModel = Content.v3Model({
    id="map_preview", kind="map",
    schema="clean_ui.v3.presentation.v1", apiVersion=3,
    preset="L",
    map={
      region="JOHTO",
      rows={{ id="route29", name="ROUTE 29", index=1,
        x=0, y=0, selected=true, nest=true }},
      current={ name="ROUTE 29", index=1 },
      player={ name="ROUTE 29", index=1 },
      graphic={ kind="tilemap", width=2, height=2,
        sheet={ path="assets/generated/map/tiles.png", wide=2 },
        map={0, 1, 2, 3},
      },
    },
    description="UP/DOWN LANDMARK   B BACK",
  })
  local namingModel = Content.v3Model({
    id="naming_preview", kind="menu",
    schema="clean_ui.v3.presentation.v1", apiVersion=3,
    preset="XL", opaque=true, rows={},
    naming={
      case="upper",
      entry={text="T×", glyphs={"T", "×"}, sourceLength=2, maxLength=7},
      keyboard={columns=9, rows={{"A", "×"}},
        bottom={{label="lower"},{label="DEL"},{label="END"}}},
      cursor={row=0, col=1, bottomRow=false},
    },
    description="A CHOOSE   B DELETE   SELECT CASE   START DONE",
  })
  T.check(dialogueModel.kind == "dialogue"
      and choiceModel.kind == "choice"
      and animationModel.kind == "animation"
      and deviceModel.kind == "device"
       and mapModel.kind == "map"
       and namingModel.kind == "menu"
       and Content.isV3Screen(dialogueModel)
      and Content.isV3Screen(choiceModel)
      and Content.isV3Screen(animationModel)
       and Content.isV3Screen(deviceModel)
       and Content.isV3Screen(mapModel)
       and Content.isV3Screen(namingModel),
     "V3 direct dialogue, choice, device, map, animation, and naming models are editor-preview screens")
  T.check(namingModel.naming.entry.glyphs[2] == "×"
      and namingModel.naming.cursor.col == 1,
    "V3 naming models preserve multi-byte glyph cells and zero-based cursors")
  T.check(Content.v3Model({ id="invalid_dialogue", kind="dialogue",
      preset="XS", lines={} }) == nil,
    "V3 rejects direct presentation models without the canonical schema")
  T.check(Content.v3Model({ id="sparse_menu", kind="menu",
      schema="clean_ui.v3.presentation.v1", apiVersion=3, preset="M",
      rows={ [2]={ id="two", label="TWO" } }, selected=1 }) == nil,
    "V3 rejects sparse menu collections before layout")
  T.check(Content.v3Model({ id="scalar_dialogue", kind="dialogue",
      schema="clean_ui.v3.presentation.v1", apiVersion=3, preset="XS",
      lines={ "OK", 2 } }) == nil,
    "V3 rejects non-text dialogue lines before rendering")
  T.check(Content.v3Model({ id="sparse_naming", kind="menu",
      schema="clean_ui.v3.presentation.v1", apiVersion=3, preset="XL",
      rows={}, naming={entry={text="", glyphs={ [2]="A" }, maxLength=7},
        keyboard={columns=9, rows={{"A"}},
          bottom={{label="lower"},{label="DEL"},{label="END"}}}}}) == nil,
    "V3 rejects sparse naming glyph collections before rendering")
  T.check(Content.v3Model({ id="bad_battle", kind="battle",
      schema="clean_ui.v3.presentation.v1", apiVersion=3, preset="BATTLE",
      player={}, enemy={}, actions={{ id="fight", label="FIGHT" }},
      selectedAction="1" }) == nil,
    "V3 rejects non-integer battle selections before dispatch")
  T.check(Content.v3Model({ id="bad_device", kind="device",
      schema="clean_ui.v3.presentation.v1", apiVersion=3, preset="L",
      device={kind="smartphone", orientation="diagonal"} }) == nil
      and Content.v3Model({ id="bad_map", kind="map",
        schema="clean_ui.v3.presentation.v1", apiVersion=3, preset="L",
        map={region="JOHTO", rows={}, graphic={kind="tilemap", width=2,
          height=2, sheet={path="map.png", wide=2}, map={0, 1, 2}}} }) == nil,
    "V3 rejects malformed device orientation and incomplete map tile data")
  T.check(Content.v3Model({ id="bad_nest_marker", kind="map",
      schema="clean_ui.v3.presentation.v1", apiVersion=3, preset="L",
      map={region="KANTO", rows={{x=1, y=1, nest="yes"}}} }) == nil,
    "V3 rejects malformed map nest marker flags")
  T.check(Content.v3Model({ id="bad_overlay", kind="animation",
      schema="clean_ui.v3.presentation.v1", apiVersion=3, preset="ANIMATION",
      animation={id="battle.transition", overlay=true,
        overlays={ [2]={x=0,y=0,w=1,h=1,color={0,0,0,1}} } } }) == nil
      and Content.v3Model({ id="valid_overlay", kind="animation",
        schema="clean_ui.v3.presentation.v1", apiVersion=3,
        preset="ANIMATION", animation={id="battle.transition",
          overlay=true, overlays={{x=0,y=0,w=1,h=1,color={0,0,0,1}}}} }) ~= nil,
    "V3 validates transparent animation overlays as dense data")
  T.check(Content.v3Model({ id="bad_overlay_shape", kind="animation",
      schema="clean_ui.v3.presentation.v1", apiVersion=3,
      preset="ANIMATION", animation={id="battle.transition", overlay=true,
        overlays={{x=0.9,y=0,w=0.2,h=1,color={0,0,2,1}}}} }) == nil,
    "V3 rejects out-of-bounds overlay rectangles and invalid colors")
  T.check(Content.v3Model({ id="circle_animation", kind="animation",
      schema="clean_ui.v3.presentation.v1", apiVersion=3,
      preset="ANIMATION", animation={id="evolution.reveal", overlay=true,
        circles={{x=0.5,y=0.4,radius=4/160,color={1,0.8,0.2,1}}}}}) ~= nil
      and Content.v3Model({ id="bad_circle_animation", kind="animation",
        schema="clean_ui.v3.presentation.v1", apiVersion=3,
        preset="ANIMATION", animation={id="evolution.reveal",
          circles={{x=0.5,y=0.4,radius=0}}}}) == nil,
    "V3 validates normalized animation circles for source-authored effects")
  T.check(Content.v3Model({ id="tilemap_animation", kind="animation",
      schema="clean_ui.v3.presentation.v1", apiVersion=3,
      preset="ANIMATION", animation={id="intro.movie", tilemap={
        path="assets/generated/intro/water_tiles.png", tileWidth=8,
        tileHeight=8, mapWidth=2, mapHeight=2, sheetColumns=2,
        logicalWidth=16, logicalHeight=4, tiles={0,1,2,3},
        scanlineOffsets={{x=0,y=0},{x=1,y=0},{x=0,y=1},{x=1,y=1}},
      }}}) ~= nil
      and Content.v3Model({ id="bad_tilemap_animation", kind="animation",
        schema="clean_ui.v3.presentation.v1", apiVersion=3,
        preset="ANIMATION", animation={id="intro.movie", tilemap={
          path="assets/generated/intro/water_tiles.png", tileWidth=8,
          tileHeight=8, mapWidth=2, mapHeight=2, sheetColumns=2,
          logicalWidth=16, logicalHeight=16, tiles={0,1,2},
        }}}) == nil,
    "V3 validates tilemap dimensions and scanline offsets")
  T.check(Content.v3Model({ id="label_animation", kind="animation",
      schema="clean_ui.v3.presentation.v1", apiVersion=3,
      preset="ANIMATION", animation={id="credits.roll", overlay=true,
        labels={{text="PORT STAFF", x=0.5, y=0.25, align="center",
          maxWidth=0.8, color={1, 1, 1, 1}}}}}) ~= nil
      and Content.v3Model({ id="bad_label_animation", kind="animation",
        schema="clean_ui.v3.presentation.v1", apiVersion=3,
        preset="ANIMATION", animation={id="credits.roll", labels={
          {text="BAD", x=1.1, y=0.2}}}}) == nil,
    "V3 validates normalized animation text layers")
  T.check(Content.v3Model({ id="offscreen_sprite_animation", kind="animation",
      schema="clean_ui.v3.presentation.v1", apiVersion=3,
      preset="ANIMATION", animation={id="boot.gamefreak", overlay=true,
        sprites={{path="assets/generated/splash/star.png", normalized=true,
          rect={x=-8/160, y=48/144, w=8/160, h=8/144},
          crop={x=0, y=0, w=8, h=8}}}}}) ~= nil
      and Content.v3Model({ id="bad_normalized_sprite", kind="animation",
        schema="clean_ui.v3.presentation.v1", apiVersion=3,
        preset="ANIMATION", animation={id="boot.gamefreak",
          sprites={{path="x", normalized="yes"}}}}) == nil,
    "V3 validates explicit normalized coordinates for offscreen sprites")
  T.check(Content.v3Model({ id="bad_sprite_rect", kind="animation",
      schema="clean_ui.v3.presentation.v1", apiVersion=3,
      preset="ANIMATION", animation={id="boot.gamefreak",
        sprites={{path="x", normalized=true,
          rect={x=0, y=0, w=0, h=8}}}}}) == nil
      and Content.v3Model({ id="bad_sprite_crop", kind="animation",
        schema="clean_ui.v3.presentation.v1", apiVersion=3,
        preset="ANIMATION", animation={id="boot.gamefreak",
          sprites={{path="x", normalized=true,
            rect={x=0, y=0, w=1, h=1}, crop={x=0, y=0, w=0, h=8}}}}}) == nil,
    "V3 rejects incomplete animation sprite geometry before rendering")
  local directScreen = runtime.shell:createState(fakeGame, "v3_screen")
  T.check(runtime.shell:openV3Screen(directScreen, dialogueModel, {})
      and directScreen.model.view == "v3_screen"
      and directScreen.model.payload.model.kind == "dialogue",
    "V3 shell opens a direct dialogue screen result")
  local animationScreen = { id="animation_preview", kind="animation",
    preset="ANIMATION", schema="clean_ui.v3.presentation.v1", apiVersion=3,
    animation={id="battle.move", frame=2, duration=4, label="MOVE"} }
  local animationLayout = runtime:measureV3(animationScreen, 640, 360, {
    font = love.graphics.newFont(15) })
    T.check(animationLayout and animationLayout.v3Model.kind == "animation"
      and animationLayout.stage and animationLayout.progress,
    "core V3 embedding bridge measures direct animation models")
  local deviceLayout = runtime:measureV3(deviceModel, 640, 360, {
    font = love.graphics.newFont(15) })
  T.check(deviceLayout and deviceLayout.v3Model.kind == "device"
      and deviceLayout.shell and deviceLayout.shell.orientation == "landscape",
    "core V3 embedding bridge measures first-class device models")
  local mapLayout = runtime:measureV3(mapModel, 640, 360, {
    font = love.graphics.newFont(15) })
  T.check(mapLayout and mapLayout.v3Model.kind == "map"
      and mapLayout.mapView and #mapLayout.mapMarkers == 1
      and mapLayout.mapMarkers[1].nest == true,
    "core V3 embedding bridge measures first-class map models")
  local transitionLayout = runtime:measureV3({
    id="transition_preview", kind="animation",
    schema="clean_ui.v3.presentation.v1", apiVersion=3,
    preset="ANIMATION", animation={id="battle.transition", overlay=true,
      overlays={{x=0,y=0,w=1,h=1,color={0,0,0,1}}}},
  }, 360, 640, { font = love.graphics.newFont(15) })
  T.check(transitionLayout and transitionLayout.stage.w == 360
      and transitionLayout.stage.h == 640
      and transitionLayout.caption.w == 0,
    "V3 transition overlays use the full portrait viewport without a panel")
  T.check(not runtime.shell:openV3Screen(directScreen, {
      id="invalid_dialogue", kind="dialogue",
      schema="clean_ui.v3.presentation.v1", apiVersion=2, preset="XS",
      lines={}, inputReady=true }, {}),
    "V3 shell rejects invalid direct action results")

  -- V3-EDITOR-FIXTURE-001: the checked-in fixture must remain a valid,
  -- callback-free catalog target for editor tooling.
  local fixtureSource = assert(love.filesystem.read(
    "examples/ui-editor-fixture/mods/clean_ui_example_editor_fixture/contract.lua"))
  local fixtureChunk = assert(loadstring(fixtureSource,
    "@ui-editor-fixture/contract.lua"))
  local fixtureFactory = fixtureChunk()
  local fixtureContract = fixtureFactory({
    log = { info = function() end },
  })
  local fixtureRegistry = Registry.new("gen2")
  T.check(fixtureRegistry:register("clean_ui_example_editor_fixture",
      fixtureContract).ok,
    "checked-in editor fixture passes the real V3 validator")
  local fixtureHost = Host.new({ registry=fixtureRegistry,
    productId="test_clean_ui", game="gen2",
    capabilities={ contract_catalog="0.1.0" } })
  local fixtureDescriptor = assert(fixtureHost:listContracts({
    id="ui_editor_fixture" }))[1]
  T.check(fixtureDescriptor and fixtureDescriptor.screens[1].id
      == "editor_playground" and fixtureDescriptor.screens[2].kind == "menu"
      and fixtureDescriptor.screens[3].kind == "dialogue"
      and fixtureDescriptor.screens[4].kind == "choice"
      and fixtureDescriptor.screens[5].kind == "battle"
      and fixtureDescriptor.screens[6].kind == "animation"
      and fixtureDescriptor.screens[7].kind == "device"
      and fixtureDescriptor.screens[8].kind == "map"
      and fixtureDescriptor.actionIds[1] == "apply"
      and fixtureDescriptor.actions == nil,
    "editor fixture is available as callback-free catalog data for all V3 kinds")
  local fixtureDialogue = fixtureContract.actions.open_dialogue()
  local fixtureChoice = fixtureContract.actions.open_choice()
  local fixtureBattle = fixtureContract.actions.open_battle()
  local fixtureAnimation = fixtureContract.actions.open_animation()
  local fixtureDevice = fixtureContract.actions.open_device()
  local fixtureMap = fixtureContract.actions.open_map()
  T.check(Content.v3Model(fixtureDialogue).kind == "dialogue"
      and Content.v3Model(fixtureChoice).kind == "choice"
      and Content.v3Model(fixtureBattle).kind == "battle"
      and Content.v3Model(fixtureAnimation).kind == "animation"
      and Content.v3Model(fixtureDevice).kind == "device"
      and Content.v3Model(fixtureMap).kind == "map"
      and Content.isV3Screen(fixtureDialogue),
    "editor fixture opens direct V3 dialogue, choice, battle, device, map, and animation results")

  end

  do

  local Catalog = loadModule("integration.catalog")
  local Pins = loadModule("integration.pins")
  local StartMenu = loadModule("integration.start_menu")
  local catalog = Catalog.new()
  local key = catalog:add("sample_mod", { id="panel", label="PANEL",
    action=function() return true end }).value
  local pins = Pins.new(mod.save)
  T.check(pins:set(key, true).ok, "pin persists")
  local menu = StartMenu.compose({{id="pokemon",label="POKEMON"},
    {id="mods",label="MODS"},{id="save",label="SAVE"}}, catalog, pins)
  T.equal(menu[2].label, "PANEL", "pinned block precedes Mod Menus")
  T.equal(menu[3].label, "MOD MENUS", "Mod Menus precedes stock MODS")
  local ownedCallback = function() return "source-owned" end
  local sourceRow = { id="source", label="SOURCE", onSelect=ownedCallback }
  local callbackMenu = StartMenu.compose({ sourceRow }, catalog, pins)
  T.check(callbackMenu[1] == sourceRow
    and callbackMenu[1].onSelect == ownedCallback,
    "Start composition preserves source row identity and callback ownership")

  local weatherCalls = 0
  local hooked = hookWrappers["ui.start_menu.items"](
    function(_, rows)
      rows[#rows + 1] = { label="WEATHER",onSelect=function()
        weatherCalls = weatherCalls + 1
      end }
      return rows
    end, {}, {
      { id="pokemon",label="POKEMON",onSelect=function() end },
      { id="mods",label="MODS",onSelect=function() end },
      { id="save",label="SAVE",onSelect=function() end },
    })
  local modMenusAt
  for index, row in ipairs(hooked) do
    if row.label == "MOD MENUS" then modMenusAt = index end
  end
  T.check(modMenusAt ~= nil and hooked[modMenusAt + 1].label == "MODS",
    "runtime hook inserts Mod Menus before stock MODS")
  local legacyWeather
  for _, row in ipairs(runtime.catalog:list()) do
    if row.label == "WEATHER" then legacyWeather = row end
  end
  T.check(legacyWeather and legacyWeather.pinnable,
    "a unique legacy label remains pinnable")
  local menuRows = runtime:modMenuRows()
  T.check(#menuRows >= 3, "Mod Menus exposes a complete catalog")
  local weatherRow
  for _, row in ipairs(menuRows) do if row.label == "WEATHER" then weatherRow = row end end
  T.check(weatherRow and weatherRow.pinnable,
    "Mod Menus reports pin eligibility")
  T.equal(select(1, runtime:togglePin(weatherRow.id)), true,
    "SELECT/pin-icon operation persists a catalog pin")
  T.equal(select(1, runtime:activateModMenu(weatherRow.id, { game = {} })), nil,
    "legacy callback may return no value without becoming an error")
  T.equal(weatherCalls, 1, "Mod Menus preserves the legacy source callback")

  hookWrappers["ui.start_menu.items"](
    function(_, rows)
      rows[#rows + 1] = { label="TOOLS",onSelect=function() end }
      rows[#rows + 1] = { label="TOOLS",onSelect=function() end }
      return rows
    end, {}, { { id="mods",label="MODS",onSelect=function() end } })
  local duplicateCount = 0
  for _, row in ipairs(runtime.catalog:list()) do
    if row.label == "TOOLS" then
      duplicateCount = duplicateCount + 1
      T.check(not row.pinnable and row.pinStatus == "stable ID required",
        "duplicate label-only entries refuse ambiguous pins")
    end
  end
  T.equal(duplicateCount, 2, "duplicate legacy rows remain accessible")

  local Settings = loadModule("integration.settings")
  local persistedSettings = {}
  local storageGame = {
    save = { version = "gen2", meta = { playthroughId = "slot1" } },
  }
  local function fallbackSettingsMod()
    return {
      game = storageGame,
      options = {
        define = function(_, schema) return schema end,
        get = function() return nil end,
      },
      storage = {
        context = function(_, game)
          return { gameVersion = game.save.version,
            playthroughId = game.save.meta.playthroughId }
        end,
        read = function(_, _, key)
          return key == "settings" and persistedSettings or nil
        end,
        write = function(_, _, key, value)
          if key ~= "settings" then return false end
          persistedSettings = value
          return true
        end,
      },
    }
  end
  local settingsSchema = {{ key = "theme", default = "clean", type = "choice" }}
  local firstSettingsMod = fallbackSettingsMod()
  T.equal(select(1, Settings.set(firstSettingsMod, "theme", "dark",
    settingsSchema)), true,
    "settings fallback writes through persistent storage when options:set is absent")
  local reloadedSettingsMod = fallbackSettingsMod()
  T.equal(Settings.get(reloadedSettingsMod, "theme", settingsSchema), "dark",
    "settings fallback reloads the persisted value in a new mod session")

  -- The released host may return the default through options:get even after
  -- Clean UI settings were persisted through the public storage fallback.
  -- The shell must resolve its theme through Core's settings adapter so the
  -- Mod Menus page follows the selected theme instead of reverting to Clean.
  local shellThemeValues = { theme = "yellow", dark_mode = true }
  local previousSet, previousGame, previousStorage =
    mod.options.set, mod.game, mod.storage
  local previousTheme = modOptions.theme
  mod.options.set = nil
  modOptions.theme = "clean"
  mod.game = fakeGame
  mod.storage = {
    context = function()
      return { gameVersion = "gen2", playthroughId = "slot1" }
    end,
    read = function(_, _, key)
      return key == "settings" and shellThemeValues or nil
    end,
    write = function(_, _, key, value)
      if key ~= "settings" then return false end
      shellThemeValues = value
      return true
    end,
  }
  T.equal(runtime:setting("theme"), "yellow",
    "shell theme resolves through the persistent settings fallback")
  T.equal(runtime:setting("dark_mode"), true,
    "shell theme reads the persisted dark mode toggle")
  local observedShellTheme
  local originalThemeGet = runtime.themes.get
  runtime.themes.get = function(themes, id)
    observedShellTheme = id
    return originalThemeGet(themes, id)
  end
  local themeScreen = runtime:openShell("mod_menus", fakeGame)
  runtime.shell:draw(themeScreen, { width = 640, height = 360 })
  runtime.themes.get = originalThemeGet
  T.equal(observedShellTheme, "yellow_dark",
    "Mod Menus renders the persisted dark palette instead of native default")
  fakeStack:pop()
  mod.options.set, mod.game, mod.storage =
    previousSet, previousGame, previousStorage
  modOptions.theme = previousTheme

  end

  local Transaction = loadModule("surfaces.transaction")
  local state = { color={1,1,1,1}, shader="base", canvas="screen", depth=0 }
  local graphics = {}
  function graphics.getColor() return unpack(state.color) end
  function graphics.setColor(...) state.color={...} end
  function graphics.getShader() return state.shader end
  function graphics.setShader(v) state.shader=v end
  function graphics.getCanvas() return state.canvas end
  function graphics.setCanvas(v) state.canvas=v end
  function graphics.push() state.depth=state.depth+1 end
  function graphics.pop() state.depth=state.depth-1 end
  function graphics.getStackDepth() return state.depth end
  function graphics.clear() end
  function graphics.origin() end
  local transaction = Transaction.run(graphics, "private", function()
    graphics.push("all"); graphics.push("all")
    graphics.setColor(0,0,0,0); graphics.setShader("bad"); error("surface crash")
  end, {}, {})
  T.check(not transaction.ok, "surface exception is isolated")
  T.equal(state.shader, "base", "shader is restored")
  T.equal(state.canvas, "screen", "canvas is restored")
  T.equal(state.color[1], 1, "color is restored")
  T.equal(state.depth, 0, "graphics stack is restored")

  T.equal(select(1, runtime:uninstall()), true, "runtime uninstalls")
  T.check(mod.exports.cleanUiHost == nil, "V3 host is removed on uninstall")
  T.finish()
  love.event.quit(0)
end

function love.errorhandler(message)
  print("TEST ERROR: " .. tostring(message))
  love.event.quit(1)
  return function() return 1 end
end
