--------------------------------------------------------------
-- MOVING PLATFORM — mockup module for Bounds
-- • Small ½-tile platform
-- • Moves along a linear track (horizontal or vertical)
-- • Either always moving OR movement is state-gated by activator
-- • You decorate the rails using your Decorations layer
--------------------------------------------------------------

local level = require("level")
local Theme = require("theme")

local MovingPlatform = { list = {} }

--------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------

local OUTLINE = 4
local TILE = 48 -- updated at load
local PLATFORM_W = TILE
local PLATFORM_H = 12

local COLOR_FILL    = Theme.level.solid
local COLOR_FOOT    = Theme.decorations.metal
local COLOR_OUTLINE = Theme.outline

--------------------------------------------------------------
-- SPAWN
--------------------------------------------------------------
-- opts:
--   dir = "horizontal" or "vertical"
--   length = travel distance in pixels
--   speed = movement speed (pixels/sec)
--   active = true/false (if false, waits for activation)
--   target = string or object reference (pressure plate ID)
--   phaseOffset = optional start offset (for constant movers)
--
-- Example:
-- MovingPlatform.spawn(tx*TILE, ty*TILE, {
--     dir = "horizontal",
--     length = 160,
--     speed = 70,
--     active = false,
--     target = "plate_1",
-- })
--------------------------------------------------------------

function MovingPlatform.spawn(x, y, opts)
    opts = opts or {}

    table.insert(MovingPlatform.list, {
        anchorX = x,
        anchorY = y,
        x = x,
        y = y,

        dir = opts.dir or "horizontal",
        length = opts.length or 120,
        speed = opts.speed or 60,
        progress = opts.phaseOffset or 0,
        direction = 1,

        always = (opts.active ~= false and opts.target == nil),
        waiting = (opts.active == false),
        target = opts.target,

        w = PLATFORM_W,
        h = PLATFORM_H,
    })
end


--------------------------------------------------------------
-- ACTIVATION HOOK
--------------------------------------------------------------
-- Call externally when a pressure plate toggles.
-- Example: MovingPlatform.activate("plate_1")
--------------------------------------------------------------

function MovingPlatform.activate(id)
    for _, p in ipairs(MovingPlatform.list) do
        if p.target == id then
            p.waiting = false
        end
    end
end

function MovingPlatform.deactivate(id)
    for _, p in ipairs(MovingPlatform.list) do
        if p.target == id then
            p.waiting = true
        end
    end
end


--------------------------------------------------------------
-- UPDATE
--------------------------------------------------------------

function MovingPlatform.update(dt)
    TILE = level.tileSize or TILE

    for _, p in ipairs(MovingPlatform.list) do

        -- If it requires activation but hasn't been activated yet
        if p.target and p.waiting then
            goto continue
        end

        -- If always moving or activated, advance the progress
        p.progress = p.progress + p.speed * dt * p.direction

        -- Bounce at edges
        if p.progress > p.length then
            p.progress = p.length
            p.direction = -1
        elseif p.progress < 0 then
            p.progress = 0
            p.direction = 1
        end

        -- Apply track direction
        if p.dir == "horizontal" then
            p.x = p.anchorX + p.progress
            p.y = p.anchorY
        else
            p.x = p.anchorX
            p.y = p.anchorY + p.progress
        end

        ::continue::
    end
end


--------------------------------------------------------------
-- DRAW
--------------------------------------------------------------

function MovingPlatform.draw()
    for _, p in ipairs(MovingPlatform.list) do

        -- OUTLINE
        love.graphics.setColor(COLOR_OUTLINE)
        love.graphics.rectangle(
            "fill",
            p.x - OUTLINE,
            p.y - OUTLINE,
            p.w + OUTLINE * 2,
            p.h + OUTLINE * 2,
            6, 6
        )

        -- FILL
        love.graphics.setColor(COLOR_FILL)
        love.graphics.rectangle(
            "fill",
            p.x,
            p.y,
            p.w,
            p.h,
            6, 6
        )

        ------------------------------------------------------------------
        -- NEW: Small 12px-wide bottom block with 4px outline
        ------------------------------------------------------------------
        local footW = 18
        local footH = 4
        local footRadius = 3

        local footX = p.x + p.w/2 - footW/2
        local footY = p.y + p.h + 4 -- sits directly under the platform

        -- Outline
        love.graphics.setColor(COLOR_OUTLINE)
        love.graphics.rectangle(
            "fill",
            footX - OUTLINE,
            footY - OUTLINE,
            footW + OUTLINE * 2,
            footH + OUTLINE * 2,
            footRadius, footRadius
        )

        -- Fill
        love.graphics.setColor(COLOR_FOOT)
        love.graphics.rectangle(
            "fill",
            footX,
            footY,
            footW,
            footH,
            footRadius, footRadius
        )
    end
end


--------------------------------------------------------------
-- CLEAR
--------------------------------------------------------------
function MovingPlatform.clear()
    MovingPlatform.list = {}
end

return MovingPlatform