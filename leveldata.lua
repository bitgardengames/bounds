-- Bounds — Test Chamber Room (40 × 23 tiles)

local LevelData = {
    tileSize = 48,
    width = 40,
    height = 23,

    layers = {
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
    }
}

return LevelData