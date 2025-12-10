function love.conf(t)
	t.console = true -- debug

    t.window.title = "Bounds"

    t.window.fullscreen = true
    t.window.fullscreentype = "desktop"  -- borderless fullscreen at desktop resolution

    t.window.vsync = 1
    t.window.msaa = 8
end