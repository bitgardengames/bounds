return function(Decorations)
    local Theme = require("theme")

    local OUTLINE_COLOR = Theme.outline
    local OUTLINE_SIZE  = 4
	local BASE_COLOR    = Theme.level.platformTop

    local prefab = {
        w = 1,
        h = 1,

        init = function(inst, entry)
            ----------------------------------------------------
            -- Sizing
            ----------------------------------------------------
            local ts = inst.config.tileSize or 48

            local tilesWide = entry.w or 1
            inst.w = tilesWide * ts
            inst.h = 10

            ----------------------------------------------------
            -- Position offsets
            -- Shift LEFT by 1 tile
            ----------------------------------------------------
            inst.x = inst.x - ts
        end,

        draw = function(x, y, w, h, inst)
            ----------------------------------------------------
            -- 1. Draw outline rectangle (slightly larger)
            ----------------------------------------------------
            love.graphics.setColor(OUTLINE_COLOR)
            love.graphics.rectangle(
                "fill",
                x - OUTLINE_SIZE,
                y - OUTLINE_SIZE + 2,
                w + OUTLINE_SIZE * 2,
                inst.h + OUTLINE_SIZE * 2,
                4, 4
            )

            ----------------------------------------------------
            -- 2. Draw filled strip
            ----------------------------------------------------
            love.graphics.setColor(BASE_COLOR)
            love.graphics.rectangle(
                "fill",
                x,
                y + 2,
                w,
                inst.h,
                4, 4
            )
        end,
    }

    Decorations.register("platformstrip", prefab)
end