local Events = require("systems.events")
--local LaserEmitter = require("objects.laseremitter")

local chamber = {
    name   = "Test Chamber 4",
    width  = 40,
    height = 23,

    ----------------------------------------------------------
    -- Door opens ONLY when the exit plate is held
    ----------------------------------------------------------
    doorCriteria = {
        plates = { mode = "all", ids = { "plate_exit" } },
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
        -- DECOR
        ------------------------------------------------------
        {
            name = "Decor",
            kind = "decor",
            objects = {
                { type="sign", tx=4, ty=18, data={text="CH-04"} },
            },
        },

        ------------------------------------------------------
        -- SOLIDS
        ------------------------------------------------------
        {
            name  = "Solids",
            kind  = "rectlayer",
            solid = true,
            rects = {
                -- Floor
                {x = 2,  y = 22, w = 38, h = 1},

                -- Raised right ledge (exit)
                {x = 33, y = 18, w = 7, h = 1},
            },
        },

        {
            name = "Background",
            kind = "rectlayer",
            solid = false,
            rects = {},
        },
    },

    ----------------------------------------------------------
    -- OBJECTS
    ----------------------------------------------------------
    objects = {

        ------------------------------------------------------
        -- EXIT
        ------------------------------------------------------
        door = { tx = 36, ty = 15 },

        ------------------------------------------------------
        -- DROP TUBE
        ------------------------------------------------------
        dropTubes = {
            { tx = 3, ty = 1 },
        },
		
		plates = {
            { tx = 10, ty = 20, id = "plate_1"},
        },
		
        cubes = {
            { tx = 23, ty = 20},
        },

		laserEmitters = {
			{tx = 20, ty = 19, dir = "right"},
		},

		laserReceivers = {
			{tx = 25, ty = 19, dir = "right", id = "laser_lift"},
		},

        ------------------------------------------------------
        -- MOVING PLATFORM (button-powered)
        ------------------------------------------------------
        movingPlatforms = {
            {
                tx = 22,
                ty = 20,
                dir = "vertical",
                trackTiles = 2,
                widthTiles = 2,
                speed = 0.5,
                active = false,
                target = "plate_1",
                loop = false,
            },
			
            {
                tx = 30,
                ty = 17,
                dir = "vertical",
                trackTiles = 5,
                widthTiles = 2,
                speed = 0.5,
                active = false,
                target = "laser_lift",
            },
        },

        ------------------------------------------------------
        -- MONITOR
        ------------------------------------------------------
        monitors = {
            { tx = 38, ty = 5, dir = -1 },
        },

        --[[saws = {
            -- Vertical saw riding alongside the lift
            {
                tx = 22,
                ty = 14,
                dir = "vertical",
                length = 4,
                speed = 1,
                active = true,
            },

            -- Horizontal saw guarding the lower gap
            {
                tx = 18,
                ty = 21,
                dir = "horizontal",
                length = 4,
                speed = 1,
                active = true,
            },
        },]]
    },

    ----------------------------------------------------------
    -- INDICATOR LOGIC
    ----------------------------------------------------------
    indicatorLogic = function(Plate, MovingPlatform)
        return {
            indicator_lift = MovingPlatform.list[1] and
                             not MovingPlatform.list[1].waiting,
        }
    end,

    contextZones = {},
}

-- Triggers
Events.on("laser_connected", function(e)

end)

Events.on("laser_disconnected", function(e)

end)

return chamber