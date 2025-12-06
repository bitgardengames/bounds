--------------------------------------------------------------
-- MOVING PLATFORM — now top-aligned + padded horizontal track
--------------------------------------------------------------

local Level = require("level")
local Theme = require("theme")

local MovingPlatform = { list = {} }

--------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------
local OUTLINE = 4
local TILE    = 48

local PLATFORM_H = 8

local COLOR_FILL    = Theme.level.solid
local COLOR_OUTLINE = Theme.outline
local COLOR_FOOT    = (Theme.decorations and Theme.decorations.metal) or COLOR_FILL

local function smoothstep(t)
    return t * t * (3 - 2 * t)
end

--------------------------------------------------------------
-- SPAWN
--------------------------------------------------------------
function MovingPlatform.spawn(x, y, opts)
    opts = opts or {}
    TILE = Level.tileSize or TILE

    local w = TILE
    local h = PLATFORM_H

    ----------------------------------------------------------
    -- TRACK LENGTH FROM TILES
    ----------------------------------------------------------
    local trackTiles = opts.trackTiles
    local travelPx

    if trackTiles and trackTiles > 0 then
        travelPx = (trackTiles - 1) * TILE
    else
        travelPx = opts.length or (2 * TILE)
    end

    ----------------------------------------------------------
    -- PLATFORM IS NOW TOP-ALIGNED IN TILE SPACE
    ----------------------------------------------------------
    -- Instead of centering: anchorCY = y + TILE/2
    -- We position the platform so its top touches top of tile.
    -- tile top Y = y
    -- platform height = h
    -- so center is: y + TILE - h/2
    ----------------------------------------------------------
    local anchorCX = x + TILE / 2
    local anchorCY = y + h

    table.insert(MovingPlatform.list, {
        anchorCX = anchorCX,
        anchorCY = anchorCY,

        cx = anchorCX,
        cy = anchorCY,

        x = anchorCX - w / 2,
        y = anchorCY - h / 2,
        w = w,
        h = h,

        dir       = opts.dir or "horizontal",
        t         = 0,
        direction = 1,
        speed     = opts.speed or 0.4,
        travel    = travelPx,

        always  = (opts.active ~= false and opts.target == nil),
        waiting = (opts.active == false),
        target  = opts.target,
    })
end

--------------------------------------------------------------
-- ACTIVATION
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
    TILE = Level.tileSize or TILE

    for _, p in ipairs(MovingPlatform.list) do
        if p.target and p.waiting then
            goto continue
        end

        ------------------------------------------------------
        -- Parametric motion t ∈ [0,1]
        ------------------------------------------------------
        p.t = p.t + p.speed * dt * p.direction

        if p.t > 1 then
            p.t = 1
            p.direction = -1
        elseif p.t < 0 then
            p.t = 0
            p.direction = 1
        end

        local eased = smoothstep(p.t)

        ------------------------------------------------------
        -- NEW: Horizontal tracks shave 4px from each end
        ------------------------------------------------------
        local offset
        if p.dir == "horizontal" then
            local effective = p.travel - 8   -- shorten total by 8px
            if effective < 0 then effective = 0 end
            offset = eased * effective
        else
            offset = eased * p.travel
        end

        ------------------------------------------------------
        -- Apply to center
        ------------------------------------------------------
        if p.dir == "horizontal" then
            p.cx = p.anchorCX + offset + 4   -- shift start by 4px
            p.cy = p.anchorCY
        else
            p.cx = p.anchorCX
            p.cy = p.anchorCY + offset
        end

        p.x = p.cx - p.w / 2
        p.y = p.cy - p.h / 2

        ::continue::
    end
end

--------------------------------------------------------------
-- DRAW
--------------------------------------------------------------
function MovingPlatform.draw()
    for _, p in ipairs(MovingPlatform.list) do
        -- BODY OUTLINE
        love.graphics.setColor(COLOR_OUTLINE)
        love.graphics.rectangle(
            "fill",
            p.x - OUTLINE,
            p.y - OUTLINE,
            p.w + OUTLINE * 2,
            p.h + OUTLINE * 2,
            6, 6
        )

        -- BODY FILL
        love.graphics.setColor(COLOR_FILL)
        love.graphics.rectangle(
            "fill",
            p.x,
            p.y,
            p.w,
            p.h,
            6, 6
        )

        -- FOOT
        local footW = 12
        local footH = 4
        local r     = 3

        local footX = p.cx - footW / 2
        local footY = p.y + p.h + 4

        love.graphics.setColor(COLOR_OUTLINE)
        love.graphics.rectangle(
            "fill",
            footX - OUTLINE,
            footY - OUTLINE,
            footW + OUTLINE * 2,
            footH + OUTLINE * 2,
            r, r
        )

        love.graphics.setColor(COLOR_FOOT)
        love.graphics.rectangle(
            "fill",
            footX,
            footY,
            footW,
            footH,
            r, r
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