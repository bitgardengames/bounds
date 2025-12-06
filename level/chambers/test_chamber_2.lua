local chamber = {
    name   = "Test Chamber 2",
    width  = 40,
    height = 23,

    ----------------------------------------------------------
    -- DOOR opens when ALL plates are down
    ----------------------------------------------------------
    doorCriteria = {
        plates = { mode = "all", ids = { "plate_1" } },
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
                {type="sign", tx=4, ty=5, data={text="CH-02"}},
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
                {x = 2,  y = 14, w = 15, h = 1},

                -- Floor 2: right segment (holds plate + door)
                {x = 25, y = 14, w = 15, h = 1},
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
        playerStart = { tx = 3, ty = 3 },

        ------------------------------------------------------
        -- Door on raised right platform
        ------------------------------------------------------
        door = { tx = 37, ty = 11 },

        ------------------------------------------------------
        -- Cube on the starting ground floor
        ------------------------------------------------------
        cubes = {
            { tx = 10, ty = 3 },
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
                speed = 0.15,
                active = true,      -- always moving
            },
        },
    },

    contextZones = {},
}

return chamber
