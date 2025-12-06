local chamber = {
    name   = "Test Chamber 2",
    width  = 40,
    height = 23,

    doorCriteria = {
        plates = { mode = "all" },
    },

    layers = {
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

        {
            name  = "Solids",
            kind  = "rectlayer",
            solid = true,

            rects = {
                { x = 5,  y = 20, w = 4, h = 1 },
                { x = 14, y = 15, w = 6, h = 1 },
                { x = 29, y = 11, w = 4, h = 1 },
                { x = 2,  y = 8,  w = 5, h = 1 },
                { x = 31, y = 6,  w = 1, h = 10 },
                { x = 35, y = 6,  w = 1, h = 10 },
            },
        },

        {
            name  = "Background",
            kind  = "rectlayer",
            solid = false,
            rects = {}
        }
    },

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
}

return chamber
