local chamber = {
    name   = "Test Chamber 1",
    width  = 40,
    height = 23,

    doorCriteria = {
        plates = { mode = "all", ids = { "plate_1" } },
        lasers = { mode = "all", ids = { "receiver_1" } },
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
            name  = "Decor",
            kind  = "decor",
            objects = {
				{type="sign", tx=4, ty = 5, data = {text = "CH-02"}},
                {type="vent",       tx=12, ty=5},
                {type="vent",       tx=27, ty=13},
                {type="vent",       tx=5,  ty=18},

                {type="vent_round", tx=20, ty=6},
                {type="vent_round", tx=7,  ty=12},
                {type="vent_round", tx=30, ty=18},

                {type="panel_tall", tx=8,  ty=4},
                {type="panel_tall", tx=22, ty=10},
                {type="panel_tall", tx=4,  ty=14},
                {type="panel_tall", tx=10, ty=16},
                {type="panel_tall", tx=18, ty=6},
                {type="panel_tall", tx=26, ty=12},
                {type="panel_tall", tx=28, ty=5},
                {type="panel_tall", tx=34, ty=16},

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

                {type="conduit_v_double_join",       tx=13, ty=21},
                {type="conduit_v_double",       tx=13, ty=20},
                {type="conduit_v_double",  tx=13, ty=19},
                {type="conduit_v_double",       tx=13, ty=18},
                {type="conduit_v_double_join",       tx=13, ty=17},
                {type="conduit_curve_tr_double",tx=13, ty=16},
                {type="conduit_h_double_join",       tx=14, ty=16},
                {type="conduit_h_double",       tx=15, ty=16},

                {type="fan",       tx=15, ty=8},
                {type="fan_large", tx=15, ty=15},
                {type="fan_3",     tx=26, ty=8},

                {type="pipe_big_h",          tx=38, ty=2},
                {type="pipe_big_h_join",     tx=37, ty=2},
                {type="pipe_big_h",          tx=36, ty=2},
                {type="pipe_big_steamvent_burst", tx=35, ty=2},
                {type="pipe_big_h",          tx=34, ty=2},
                {type="pipe_big_h_join",     tx=33, ty=2},
                {type="pipe_big_curve_br",   tx=32, ty=2},
                {type="pipe_big_v",          tx=32, ty=1},

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
                {type="pipe_cap", tx=2, ty=18},
            },
        },

        {
            name  = "Solids",
            kind  = "rectlayer",
            solid = true,

            rects = {
                {x = 15, y = 20, w = 8, h = 1},
                {x = 2,  y = 8,  w = 5, h = 1},
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
            {tx = 27, ty = 21, id = "plate_1"},
        },

        cubes = {
            {tx = 17, ty = 19},
        },

        monitors = {
            {tx = 38, ty = 5, dir = -1},
        },
    },

    contextZones = {
        {name = "camera_attention", tx = 2, ty = 5, w = 3, h = 2, effects = {look_up = 0.8}},
        {name = "plate_excitment", tx = 26, ty = 21, w = 3, h = 1, effects = {wiggle = 0.8}},
    },
}

return chamber
