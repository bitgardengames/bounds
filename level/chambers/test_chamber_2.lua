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
                {type="sign", tx=4, ty=5, data={text="CH-02"}},

                {type="conduit_curve_br",  tx=6, ty=14},
                {type="conduit_h_join",    tx=7, ty=14},
                {type="conduit_h",         tx=8, ty=14},
                {type="conduit_h",         tx=9, ty=14},
                {type="conduit_h_join",    tx=10, ty=14},
                {type="conduit_h", tx=11, ty=14},
                {type="conduit_indicator", tx=11, ty=14},
                {type="conduit_h_join",    tx=12, ty=14},
                {type="conduit_h",         tx=13, ty=14},
                {type="conduit_h",         tx=14, ty=14},
                {type="conduit_h_join",    tx=15, ty=14},
				{type="conduit_curve_bl",  tx=16, ty=14},
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
                {x = 2,  y = 14, w = 14, h = 1},

                -- Right platform
                {x = 26, y = 14, w = 14, h = 1},
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
        door = { tx = 36, ty = 11, open = true},

        ------------------------------------------------------
        -- Cube on the starting ground floor
        ------------------------------------------------------
        cubes = {
            { tx = 23, ty = 11 },
        },

        monitors = {
            {tx = 38, ty = 5, dir = -1},
        },

        ------------------------------------------------------
        -- Pressure plate on far-right raised platform
        ------------------------------------------------------
        plates = {
            { tx = 6, ty = 12, id = "plate_1" },
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
                tx = 16,            -- start roughly centered in the gap
                ty = 13,            -- same height as the raised floor (tile above it)
                dir = "horizontal",
                trackTiles = 8,    -- spans left ↔ right comfortably, crossing gap fully
				widthTiles = 3,
                speed = 0.2,
                active = false,      -- always moving
				loop = true,
				target = "plate_1",
            },
        },
    },

    contextZones = {},
}

return chamber