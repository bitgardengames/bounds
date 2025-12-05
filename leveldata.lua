local LevelData = {
    tileSize = 48,
    chambers = {

        ----------------------------------------------------------------------
        -- TEST CHAMBER 1
        ----------------------------------------------------------------------
        {
            name   = "Test Chamber 1",
            width  = 40,
            height = 23,

            layers = {

                --------------------------------------------------------------
                -- NEW FRAME LAYER (outer chamber walls)
                --------------------------------------------------------------
                {
                    name  = "Frame",
                    kind  = "rectlayer",
                    solid = true,
                    frame = true,

                    rects = {
                        {x = 1,  y = 1,  w = 40, h = 1},   -- ceiling
                        {x = 1,  y = 23, w = 40, h = 1},   -- floor
                        {x = 1,  y = 1,  w = 1,  h = 23},  -- left wall
                        {x = 40, y = 1,  w = 1,  h = 23},  -- right wall
                    },
                },

                --------------------------------------------------------------
                -- DECORATION LAYER
                --------------------------------------------------------------
                {
                    name  = "Decor",
                    kind  = "decor",
                    objects = {

                        -- Vents
                        {type="vent",       tx=12, ty=5},
                        {type="vent",       tx=27, ty=13},
                        {type="vent",       tx=14, ty=16},

                        {type="vent_round", tx=20, ty=6},
                        {type="vent_round", tx=7,  ty=12},
                        {type="vent_round", tx=30, ty=18},

                        -- Panels
                        {type="panel_tall", tx=8,  ty=4},
                        {type="panel_tall", tx=22, ty=10},
                        {type="panel_tall", tx=4,  ty=14},
                        {type="panel_tall", tx=10, ty=16},
                        {type="panel_tall", tx=18, ty=6},
                        {type="panel_tall", tx=26, ty=12},
                        {type="panel_tall", tx=28, ty=5},
                        {type="panel_tall", tx=34, ty=16},

                        -- Fans
                        {type="fan",       tx=15, ty=8},
                        {type="fan_large", tx=23, ty=15},
                        {type="fan_3",     tx=26, ty=8},

                        -- Pipes (big)
                        {type="pipe_big_h",          tx=38, ty=2},
                        {type="pipe_big_h_join",     tx=37, ty=2},
                        {type="pipe_big_h",          tx=36, ty=2},
                        {type="pipe_big_steamvent_burst", tx=35, ty=2},
                        {type="pipe_big_h",          tx=34, ty=2},
                        {type="pipe_big_h_join",     tx=33, ty=2},
                        {type="pipe_big_curve_br",   tx=32, ty=2},
                        {type="pipe_big_v",          tx=32, ty=1},

                        -- Pipes (left vertical stack)
                        {type="pipe_big_v_join", tx=2,  ty=8},
                        {type="pipe_big_v",      tx=2,  ty=9},
                        {type="pipe_big_v",      tx=2,  ty=10},
                        {type="pipe_big_v_join", tx=2,  ty=11},
                        {type="pipe_big_v",      tx=2,  ty=12},
                        {type="pipe_big_v",      tx=2,  ty=13},
                        {type="pipe_big_v_join", tx=2,  ty=14},
                        {type="pipe_big_t_left", tx=2,  ty=15},
                        {type="pipe_big_v_join", tx=2,  ty=16},
                        {type="pipe_big_v",      tx=2,  ty=17},
                        {type="pipe_big_v",      tx=2,  ty=18},
                        {type="pipe_big_v_join", tx=2,  ty=19},
                        {type="pipe_big_curve_bl", tx=2, ty=20},
                        {type="pipe_big_h",        tx=1, ty=15},
                        {type="pipe_big_h",        tx=1, ty=20},

                        -- Conduit
                        {type="conduit_v",          tx=27, ty=21},
                        {type="conduit_curve_tr",   tx=27, ty=20},
                        {type="conduit_h_join",     tx=28, ty=20},
                        {type="conduit_h",          tx=29, ty=20},
                        {type="conduit_h_join",     tx=30, ty=20},
                        {type="conduit_junctionbox",tx=31, ty=20},
                        {type="conduit_h_join",     tx=32, ty=20},
                        {type="conduit_h",          tx=33, ty=20},
                        {type="conduit_h",          tx=34, ty=20},
                        {type="conduit_h_join",     tx=35, ty=20},

						{type="conduit_v_double",     tx=14, ty=21},
						{type="conduit_v_double",     tx=14, ty=20},

                        -- Sign
                        {type="sign", tx=4, ty=5, data={ text = "CH-01" }},
                    },
                },

                --------------------------------------------------------------
                -- GAMEPLAY SOLIDS (platforms)
                --------------------------------------------------------------
                {
                    name  = "Solids",
                    kind  = "rectlayer",
                    solid = true,

                    rects = {
                        -- Mid-room platform
                        {x = 15, y = 20, w = 8, h = 1},

                        -- Upper-left ledge
                        {x = 2,  y = 8,  w = 5, h = 1},
                    },
                },

                --------------------------------------------------------------
                -- OPTIONAL BACKGROUND LAYER
                --------------------------------------------------------------
                {
                    name = "Background",
                    kind = "rectlayer",
                    solid = false,
                    rects = {}
                }

            }, -- end layers

            --------------------------------------------------------------
            -- OBJECTS
            --------------------------------------------------------------
            objects = {
                playerStart = {tx = 3, ty = 4},
                door        = {tx = 36, ty = 20},

                plates = {
                    {tx = 27, ty = 21},
                },

                cubes = {
                    {tx = 17, ty = 19},
                },

                monitors = {
                    {tx = 38, ty = 5, dir = -1},
					--{tx = 1, ty = 2},
                },
            },
        },

        ----------------------------------------------------------------------
        -- TEST CHAMBER 2
        ----------------------------------------------------------------------
        {
            name   = "Test Chamber 2",
            width  = 40,
            height = 23,

            layers = {

                --------------------------------------------------------------
                -- FRAME LAYER
                --------------------------------------------------------------
                {
                    name  = "Frame",
                    kind  = "rectlayer",
                    solid = true,
                    frame = true,

                    rects = {
                        {x = 1,  y = 1,  w = 40, h = 1},
                        {x = 1,  y = 23, w = 40, h = 1},
                        {x = 1,  y = 1,  w = 1,  h = 23},
                        {x = 40, y = 1,  w = 1,  h = 23},
                    },
                },

                --------------------------------------------------------------
                -- DECOR
                --------------------------------------------------------------
                {
                    name = "Decor",
                    kind = "decor",
                    objects = {
                        { type="vent", tx=12, ty=5},
                        { type="vent", tx=27, ty=13},
                        { type="vent", tx=14, ty=18},

                        { type="panel_tall", tx=8,  ty=4},
                        { type="panel_tall", tx=22, ty=10},
                        { type="panel_tall", tx=4,  ty=14},
                        { type="panel_tall", tx=10, ty=16},
                        { type="panel_tall", tx=18, ty=6},
                        { type="panel_tall", tx=26, ty=12},
                        { type="panel_tall", tx=28, ty=5},
                        { type="panel_tall", tx=34, ty=16},

                        { type="vent_round", tx=20, ty=6 },
                        { type="vent_round", tx=7,  ty=12 },
                        { type="vent_round", tx=30, ty=18 },

                        { type="fan",       tx=15, ty=8},
                        { type="fan_large", tx=23, ty=15},

                        -- Pipe run
                        { type="conduit_v", tx=6,  ty=1 },
                        { type="conduit_curve_br", tx=6,  ty=2 },
                        { type="conduit_h", tx=7,  ty=2 },
                        { type="conduit_h", tx=8,  ty=2 },
                        { type="conduit_h", tx=9,  ty=2 },
                        { type="conduit_junctionbox", tx=10, ty=2 },
                        { type="conduit_h", tx=11, ty=2 },
                        { type="conduit_curve_bl", tx=12, ty=2 },
                        { type="conduit_v", tx=12, ty=1 },
                    },
                },

                --------------------------------------------------------------
                -- SOLID PLATFORMS
                --------------------------------------------------------------
                {
                    name  = "Solids",
                    kind  = "rectlayer",
                    solid = true,

                    rects = {
                        -- Left step
                        { x = 5,  y = 20, w = 4, h = 1 },

                        -- Mid-room platform
                        { x = 14, y = 15, w = 6, h = 1 },

                        -- Right shelf
                        { x = 29, y = 11, w = 4, h = 1 },

                        -- Upper-left ledge
                        { x = 2,  y = 8,  w = 5, h = 1 },

                        -- Wall-kick channel
                        { x = 31, y = 6,  w = 1, h = 10 },
                        { x = 35, y = 6,  w = 1, h = 10 },
                    },
                },

                --------------------------------------------------------------
                -- OPTIONAL BACKGROUND
                --------------------------------------------------------------
                {
                    name  = "Background",
                    kind  = "rectlayer",
                    solid = false,
                    rects = {}
                }
            },

            --------------------------------------------------------------
            -- OBJECTS
            --------------------------------------------------------------
            objects = {
                playerStart = { tx = 3, ty = 4 },
                door        = { tx = 16, ty = 20 },

                plates = {
                    { tx = 12, ty = 21 },
                },

                cubes = {
                    { tx = 10, ty = 20 },
                },

                monitors = {
                    { tx = 1, ty = 2 },
                },

                saws = {
                    { tx = 20, ty = 1,  dir = "horizontal", mount="top",  speed=1 },
                    { tx = 31, ty = 13, dir = "vertical",   mount="left", speed=1 },
                },
            },
        },
    }
}

return LevelData