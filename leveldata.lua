local LevelData = {
    tileSize = 48,
    chambers = {
        {
            name = "Test Chamber 1",
            width = 40,
            height = 23,
            layers = {
                {
                    name = "Decor",
                    kind = "decor",
                    objects = {
						-- Vents
                        {type="vent", tx=12, ty=5},
                        {type="vent", tx=27, ty=13},
                        {type="vent", tx=14, ty=16},

                        {type="vent_round", tx=20, ty=6},
                        {type="vent_round", tx=7,  ty=12},
                        {type="vent_round", tx=30, ty=18},

                        -- Panels
                        {type="panel_tall", tx=8, ty=4},
                        {type="panel_tall", tx=22, ty=10},
                        {type="panel_tall", tx=4, ty=14},
                        {type="panel_tall", tx=10, ty=16},
                        {type="panel_tall", tx=18, ty=6},
                        {type="panel_tall", tx=26, ty=12},
                        {type="panel_tall", tx=28, ty=5},
                        {type="panel_tall", tx=34, ty=16},


						-- Fans
						{type="fan", tx=15, ty=8},
                        {type="fan_large", tx=23, ty=15},

						-- Pipes
						{type="pipe_big_h", tx=38,  ty=2},
						{type="pipe_big_h_join", tx=37,  ty=2},
						{type="pipe_big_h", tx=36,  ty=2},
						{type="pipe_big_steamvent_burst", tx=35,  ty=2},
						{type="pipe_big_h", tx=34,  ty=2},
						{type="pipe_big_h_join", tx=33,  ty=2},
						{type="pipe_big_curve_br", tx=32,  ty=2},
						{type="pipe_big_v", tx=32,  ty=1},

						{type="pipe_big_v_join", tx=2,  ty=8},
						{type="pipe_big_v", tx=2,  ty=9},
						{type="pipe_big_v", tx=2,  ty=10},
						{type="pipe_big_v_join", tx=2,  ty=11},
						{type="pipe_big_v", tx=2,  ty=12},
						{type="pipe_big_v", tx=2,  ty=13},
						{type="pipe_big_v_join", tx=2,  ty=14},
						{type="pipe_big_t_left", tx=2,  ty=15},
						{type="pipe_big_v_join", tx=2,  ty=16},
						{type="pipe_big_v", tx=2,  ty=17},
						{type="pipe_big_v", tx=2,  ty=18},
						{type="pipe_big_v_join", tx=2,  ty=19},
						{type="pipe_big_curve_bl", tx=2,  ty=20},
						{type="pipe_big_h", tx=1,  ty=15},
						{type="pipe_big_h", tx=1,  ty=20},

						-- Conduit
						{type="pipe_v", tx=27,  ty=21},
						{type="pipe_curve_tr", tx=27,  ty=20},
						{type="pipe_h", tx=28,  ty=20},
						{type="pipe_h", tx=29,  ty=20},
						{type="pipe_h", tx=30,  ty=20},
						{type="pipe_junctionbox", tx=31,  ty=20},
						{type="pipe_h", tx=32,  ty=20},
						{type="pipe_h", tx=33,  ty=20},
						{type="pipe_h", tx=34,  ty=20},
						{type="pipe_h", tx=35,  ty=20},
                    },
                },

                {
                    name  = "Solids",
                    kind  = "rectlayer",
                    solid = true,

                    rects = {
                        -- Room border
                        {x = 1,  y = 1,  w = 40, h = 1},   -- ceiling
                        {x = 1,  y = 23, w = 40, h = 1},   -- floor
                        {x = 1,  y = 1,  w = 1,  h = 23},  -- left wall
                        {x = 40, y = 1,  w = 1,  h = 23},  -- right wall

                        -- Mid-room platform
                        {x = 15, y = 20, w = 8, h = 1},

                        -- Upper-left ledge
                        {x = 2, y = 8, w = 5, h = 1},
                    },
                },

                {
                    name = "Background",
                    kind = "rectlayer",
                    solid = false,
                    rects = {}
                }
            },

            objects = {
                playerStart = {tx = 3, ty = 4},
                door = {tx = 36, ty = 20},
                plates = {
                    {tx = 27, ty = 21},
                },
                cubes = {
                    {tx = 17, ty = 19},
                },
                securityCameras = {
                    {tx = 1, ty = 2},
                },
            },
        },

         {
            name = "Test Chamber 2",
            width = 40,
            height = 23,
            layers = {
                {
                    name = "Decor",
                    kind = "decor",
                    objects = {
                        { type="vent", tx=12, ty=5},
                        { type="vent", tx=27, ty=13},
                        { type="vent", tx=14, ty=18},
                        --{ type="panel", tx=6,  ty=18},
                        { type="fan", tx=15, ty=8},
                        --{ type="light", tx=20, ty=3},

                        -- Tall panels
                        { type="panel_tall", tx=8, ty=4},
                        { type="panel_tall", tx=22, ty=10},
                        { type="panel_tall", tx=4, ty=14},
                        { type="panel_tall", tx=10, ty=16},
                        { type="panel_tall", tx=18, ty=6},
                        { type="panel_tall", tx=26, ty=12},
                        { type="panel_tall", tx=28, ty=5},
                        { type="panel_tall", tx=34, ty=16},

                        { type="vent_round", tx=20, ty=6 },
                        { type="vent_round", tx=7,  ty=12 },
                        { type="vent_round", tx=30, ty=18 },

                        { type="fan_large", tx=23, ty=15 },

                        { type="pipe_v", tx=6,  ty=1 },
                        { type="pipe_curve_br", tx=6,  ty=2 },
                        { type="pipe_h", tx=7,  ty=2 },
                        { type="pipe_h", tx=8,  ty=2 },
                        { type="pipe_h", tx=9,  ty=2 },
                        { type="pipe_junctionbox", tx=10,  ty=2 },
                        { type="pipe_h", tx=11,  ty=2 },
                        { type="pipe_curve_bl", tx=12,  ty=2 },
                        { type="pipe_v", tx=12,  ty=1 },
                    },
                },

                {
                    name  = "Solids",
                    kind  = "rectlayer",
                    solid = true,

                    rects = {
                        ----------------------------------------------------------
                        -- ROOM BORDER
                        ----------------------------------------------------------
                        { x = 1,  y = 1,  w = 40, h = 1 },   -- ceiling
                        { x = 1,  y = 23, w = 40, h = 1 },   -- floor
                        { x = 1,  y = 1,  w = 1,  h = 23 },  -- left wall
                        { x = 40, y = 1,  w = 1,  h = 23 },  -- right wall

                        ----------------------------------------------------------
                        -- NEW: SMALL INTERNAL PLATFORMS
                        ----------------------------------------------------------
                        -- Left step (at ground level)
                        { x = 5, y = 20, w = 4, h = 1 },

                        -- Mid-room platform
                        { x = 14, y = 15, w = 6, h = 1 },

                        -- Right shelf
                        { x = 29, y = 11, w = 4, h = 1 },

                        -- Upper-left ledge
                        { x = 2, y = 8, w = 5, h = 1 },

                        ----------------------------------------------------------
                        -- NEW: WALL-KICK CHANNEL
                        ----------------------------------------------------------
                        -- Two walls separated by a 3-tile gap (x = 32 .. 34 gap)
                        -- Left wall of the channel
                        { x = 31, y = 6, w = 1, h = 10 },

                        -- Right wall of the channel
                        { x = 35, y = 6, w = 1, h = 10 },
                    },
                },

                {
                    name = "Background",
                    kind = "rectlayer",
                    solid = false,
                    rects = {}
                }
            },

            objects = {
                playerStart = { tx = 3, ty = 4 },
                door = { tx = 16, ty = 20 },
                plates = {
                    { tx = 12, ty = 21 },
                },
                cubes = {
                    { tx = 10, ty = 20 },
                },
                securityCameras = {
                    { tx = 1, ty = 2 },
                },
                saws = {
                    { tx = 20, ty = 1, dir = "horizontal", mount = "top", speed = 1 },
                    { tx = 31, ty = 13, dir = "vertical", mount = "left", speed = 1 },
                },
            },
        },
	},
}

return LevelData