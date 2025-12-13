local chamber = {
    name   = "Test Chamber 4",
    width  = 40,
    height = 23,

    doorCriteria = {
        plates = { mode = "all", ids = { "plate_1" } },
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
				{type="sign", tx=4, ty = 18, data = {text = "CH-04"}},
            },
        },

        {
            name  = "Solids",
            kind  = "rectlayer",
            solid = true,

            rects = {
				{x = 2,  y = 22,  w = 38, h = 1},
                {x = 15, y = 20, w = 8, h = 1},
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
        door = {tx = 36, ty = 19},

        --[[plates = {
            {tx = 27, ty = 20, id = "plate_1"},
        },]]

        dropTubes = {
            {tx = 3, ty = 1},
        },

        --[[cubes = {
            {tx = 17, ty = 19},
        },]]

        monitors = {
            {tx = 38, ty = 5, dir = -1},
        },

		buttons = {
		{ tx = 17, ty = 18, mode = "oneshot", id = "button_1" },
		--	{ tx = 8, ty = 21, mode = "timed", duration = 4, id = "btn_timer" },
		},
    },

	indicatorLogic = function(Plate)
		return {
			indicator_1 = Plate.isDown("plate_1"),
		}
	end,

    contextZones = {
        {name = "camera_attention", tx = 2, ty = 5, w = 3, h = 2, effects = {look_up = 0.8}},
        {name = "plate_excitment", tx = 26, ty = 21, w = 3, h = 1, effects = {wiggle = 0.8}},
    },
}

return chamber
