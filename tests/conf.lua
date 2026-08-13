function love.conf(t)
  t.console = true
  -- Hidden graphics context: production replacement tests exercise real
  -- canvases and fonts without presenting a visible test window.
  t.window = t.window or {}
  t.window.width = 640
  t.window.height = 360
  t.window.visible = false
  t.audio = nil
end
