function love.conf(t)
  t.console = true
  -- Core tests exercise graphics and filesystem behavior only.  Do not let
  -- headless CI initialize ALSA when no playback device is available.
  t.modules = t.modules or {}
  t.modules.audio = false
  t.modules.sound = false
  -- Hidden graphics context: production replacement tests exercise real
  -- canvases and fonts without presenting a visible test window.
  t.window = t.window or {}
  t.window.width = 640
  t.window.height = 360
  t.window.visible = false
end
