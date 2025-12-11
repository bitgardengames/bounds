local chamber = {
    name   = "Test Chamber 2",
    width  = 40,
    height = 23,

	doorCriteria = {},

    layers = {

        ------------------------------------------------------
        -- FRAME
        ------------------------------------------------------
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

        ------------------------------------------------------
        -- DECOR (still minimal)
        ------------------------------------------------------
        {
            name = "Decor",
            kind = "decor",
            objects = {
				--{ type = "panelseams", tx = 1, ty = 1, w = 38, h = 21 },
                {type="sign", tx=4, ty=15, data={text="CH-02"}},

                {type="conduit_curve_tr",  tx=7, ty=17},
                {type="conduit_h_join",    tx=8, ty=17},
                {type="conduit_h",         tx=9, ty=17},
                {type="conduit_h_join",    tx=10, ty=17},
                {type="conduit_h", tx=11, ty=17},
                {type="conduit_indicator", tx=11, ty=17, data = {id = "indicator_1"}},
                {type="conduit_h_join",    tx=12, ty=17},
                {type="conduit_h",         tx=13, ty=17},
				{type="conduit_curve_tl",  tx=14, ty=17},
            }
        },

		{
			name  = "Water",
			kind  = "liquid",
			solid = false,
			rects = {
				--{x=2, y=20, w=38, h=3}, -- one tile high pool
				{x=2, y=20, w=38, h=1},
				{x=2, y=21, w=38, h=1},
				{x=2, y=22, w=38, h=1},
			}
		},

        ------------------------------------------------------
        -- SOLIDS — Updated Floor 2 with a 6-tile gap
        ------------------------------------------------------
        {
            name  = "Solids",
            kind  = "rectlayer",
            solid = true,
            rects = {
                -- Left plaform
                {x = 2,  y = 19, w = 14, h = 1},

                -- Right platform
                {x = 26, y = 19, w = 14, h = 1},
            },
        },

        {
            name  = "Background",
            kind  = "rectlayer",
            solid = false,
            rects = {}
        },
    },

    ----------------------------------------------------------
    -- OBJECTS
    ----------------------------------------------------------
    objects = {
        ------------------------------------------------------
        -- Door on raised right platform
        ------------------------------------------------------
        door = { tx = 36, ty = 16, open = true},

        ------------------------------------------------------
        -- Cube on the starting ground floor
        ------------------------------------------------------
        cubes = {
            { tx = 23, ty = 17 },
        },

        monitors = {
            {tx = 38, ty = 5, dir = -1},
        },

        ------------------------------------------------------
        -- Pressure plate on far-right raised platform
        ------------------------------------------------------
        plates = {
            { tx = 6, ty = 17, id = "plate_1" },
        },

        dropTubes = {
            {tx = 3, ty = 1},
        },

        ------------------------------------------------------
        -- MOVING PLATFORMS
        -- Horizontal platform traverses the 6-tile gap
        ------------------------------------------------------
        movingPlatforms = {
            {
                tx = 15,            -- start roughly centered in the gap
                ty = 18,            -- same height as the raised floor (tile above it)
                dir = "horizontal",
                trackTiles = 8,
				widthTiles = 3,
                speed = 0.15,
                active = false,      -- always moving
				loop = true,
				target = "plate_1",
            },
        },
    },

	indicatorLogic = function(Plate)
		return {
			indicator_1 = Plate.isDown("plate_1"),
		}
	end,

    contextZones = {},
}

return chamber