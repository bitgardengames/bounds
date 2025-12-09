--[[
	Notes
	Could add the sequence here where the player drops in, looks at the puzzle, steps on the plate. after a moment of stepping off the plate the player has a conundrum moment... I don't have the tools to solve this. Then the drop tube coughs up a cube.
	Soft lock potential - If the player sends the cube back across the gap, they're stuck at the start. despawn cube and drop a new one from the delivery tube
--]]

local chamber = {
    name   = "Test Chamber 3",
    width  = 40,
    height = 23,

	doorCriteria = {
		plates = { mode = "all", ids = { "plate_1", "plate_2" } },
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
                {type="sign", tx=4, ty=5, data={text="CH-03"}},
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
                -- Ground floor (unchanged)
                {x = 2,  y = 14, w = 6, h = 1},

                -- Floor 2: right segment (holds plate + door)
                {x = 25, y = 18, w = 15, h = 1},
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
           -- { tx = 26, ty = 12 },
        },

        monitors = {
            {tx = 38, ty = 5, dir = -1},
        },

        ------------------------------------------------------
        -- Pressure plate on far-right raised platform
        ------------------------------------------------------
        plates = {
          --  { tx = 6, ty = 12, id = "plate_1" },
        },

        dropTubes = {
            {tx = 3, ty = 1},
        },

        ------------------------------------------------------
        -- MOVING PLATFORMS
        ------------------------------------------------------
        movingPlatforms = {
            {
                tx = 23,
                ty = 17,
                dir = "vertical",
                trackTiles = 6,
				widthTiles = 1,
                speed = 0.2,
				loop = true,
            },
        },
    },

    contextZones = {},
}

return chamber