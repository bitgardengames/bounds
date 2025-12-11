local chamber = {
    name   = "Test Chamber 3",
    width  = 40,
    height = 23,

	doorCriteria = {
		plates = {mode = "all", ids = {"plate_1"}},
	},

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
                {type="sign", tx=4, ty=18, data={text="CH-03"}},

                {type="conduit_curve_tr",  tx=22, ty=20},
				{type="conduit_h_join",         tx=23, ty=20},
				{type="conduit_h",    tx=24, ty=20},
                {type="timer_display", tx=24, ty=20, data={id="timer_1", dur = 5.5}},
                {type="conduit_h_join", tx=25, ty=20},
				{type="conduit_curve_tl",  tx=26, ty=20},
				
                {type="conduit_curve_tr",  tx=32, ty=16},
				{type="conduit_h_join",         tx=33, ty=16},
				{type="conduit_h",         tx=34, ty=16},
				{type="conduit_indicator", tx=34, ty=16, data = {id = "indicator_1"}},
				{type="conduit_h_join",    tx=35, ty=16},
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
                {x = 2,  y = 22,  w = 38, h = 1},

                -- Floor 2: right segment (holds plate + door)
                {x = 31, y = 18, w = 9, h = 1},
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
        door = { tx = 36, ty = 15},

        ------------------------------------------------------
        -- Cube on the starting ground floor
        ------------------------------------------------------
        cubes = {
           { tx = 12, ty = 18 },
        },

        monitors = {
            {tx = 38, ty = 5, dir = -1},
        },

        ------------------------------------------------------
        -- Pressure plate on far-right raised platform
        ------------------------------------------------------
        plates = {
            {tx = 31, ty = 16, id = "plate_1"},
			{tx = 21, ty = 20, id = "plate_2", timer = "timer_1"},
        },

        dropTubes = {
            {tx = 3, ty = 1},
        },

        ------------------------------------------------------
        -- MOVING PLATFORMS
        ------------------------------------------------------
        movingPlatforms = {
            {
                tx = 28,
                ty = 17,
                dir = "vertical",
                trackTiles = 5,
				widthTiles = 2,
                speed = 0.2,
				active = false,
				target = "plate_2"
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