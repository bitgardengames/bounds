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
				{type="sign", tx=4, ty = 5, data = {text = "CH-02"}},
            },
        },

        {
            name  = "Solids",
            kind  = "rectlayer",
            solid = true,

            rects = {
			
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
    },
}

return chamber
