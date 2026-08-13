local SHADER_SOURCE = [[
extern number pulse;

vec4 effect(vec4 color, Image texture, vec2 textureCoords, vec2 screenCoords)
{
  vec4 pixel = Texel(texture, textureCoords);
  return vec4(pixel.rgb * (0.72 + 0.28 * pulse), pixel.a) * color;
}
]]

return function(mod)
  local screenId = "animated_grid_screen"

  local function gridScreen()
    return {
      id = screenId,
      type = "panel",
      title = "ANIMATED GRID",
      preset = "L",
      components = {
        { type = "label", id = "help",
          text = "A protected custom surface is rendered below.",
          layout = { wrap = true } },
      },
    }
  end

  local contract = {
    id = "animated_shader_grid",
    version = "1.0.0",
    games = { "gen1", "gen2" },
    screens = { gridScreen() },
    extensions = {
      {
        id = "open_grid",
        type = "start.action",
        target = "mod_menus",
        label = "SHADER GRID",
        description = "Open custom coordinates and scoped animation.",
        icon = "grid",
        action = "open_grid",
        pinnable = true,
      },
    },
    surfaces = {
      {
        id = "grid_surface",
        mode = "overlay",
        target = { screen_id = screenId },
        logical_size = { w = 320, h = 180 },
        snapshot = { columns = 5, rows = 4, selected = 7 },
        validator = function(screen)
          return type(screen) == "table" and screen.id == screenId
        end,
        update = function(ctx, dt)
          ctx.localState.phase = (ctx.localState.phase or 0) + dt
        end,
        draw = function(ctx, snapshot)
          local g = ctx.graphics
          local phase = ctx.localState.phase or ctx.time or 0
          local shader = ctx.shaders:get("pulse", SHADER_SOURCE)
          shader:send("pulse", 0.5 + 0.5 * math.sin(phase * 2.0))
          g.setShader(shader)

          local gap, cell = 6, 48
          local originX, originY = 28, 14
          for row = 1, snapshot.rows do
            for column = 1, snapshot.columns do
              local index = (row - 1) * snapshot.columns + column
              local x = originX + (column - 1) * (cell + gap)
              local y = originY + (row - 1) * (cell - 8)
                + math.floor(math.sin(phase * 3 + index) * 3)
              if index == snapshot.selected then
                g.setColor(0.70, 0.82, 0.78, 1.0)
              else
                g.setColor(0.90, 0.89, 0.83, 1.0)
              end
              g.rectangle("fill", x, y, cell, cell - 12)
              g.setColor(0.13, 0.15, 0.17, 1.0)
              g.rectangle("line", x, y, cell, cell - 12)
              ctx.pointer:region({
                id = "cell_" .. index,
                x = x, y = y, w = cell, h = cell - 12,
                action = "choose_cell",
                payload = { index = index },
              })
            end
          end

          g.setShader()
          g.setColor(1, 1, 1, 1)
        end,
      },
    },
    gallery = {
      {
        id = "surface.animated_shader_grid",
        games = { "gen1", "gen2" },
        family = "examples",
        title = "Animated Shader Grid",
        support = "supported",
        variant = "five_by_four",
        preset = "L",
        screen = screenId,
        surface = "grid_surface",
        content_levels = { "NORMAL", "FULL" },
      },
    },
    actions = {},
  }

  contract.actions.open_grid = function(ctx, payload)
    return gridScreen()
  end

  contract.actions.choose_cell = function(ctx, payload)
    mod.log:info("Selected shader-grid cell %s",
      tostring(payload and payload.index))
  end

  return contract
end

