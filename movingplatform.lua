--------------------------------------------------------------
-- MOVING PLATFORM — now top-aligned + padded horizontal track
--------------------------------------------------------------

local Level = require("level")
local Theme = require("theme")
local Plate = require("pressureplate")

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
local function applyPosition(p)
    local eased = smoothstep(p.t)

    --------------------------------------------------------------
    -- NEW: Horizontal tracks shave 4px from each end
    --------------------------------------------------------------
    local offset
    if p.dir == "horizontal" then
        local effective = p.travel - 8   -- shorten total by 8px
        if effective < 0 then effective = 0 end
        offset = eased * effective

        p.cx = p.anchorCX + offset + 4   -- shift start by 4px
        p.cy = p.anchorCY
    else
        offset = eased * p.travel

        p.cx = p.anchorCX
        p.cy = p.anchorCY + offset
    end

    p.x = p.cx - p.w / 2
    p.y = p.cy - p.h / 2
end

function MovingPlatform.spawn(x, y, opts)
    opts = opts or {}
    TILE = Level.tileSize or TILE

    local w = TILE - 4
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

    local pressToLift = (opts.active == false and opts.target ~= nil)

    local platform = {
        anchorCX = anchorCX,
        anchorCY = anchorCY,

        cx = anchorCX,
        cy = anchorCY,

        x = anchorCX - w / 2,
        y = anchorCY - h / 2,
        w = w,
        h = h,

        prevX = anchorCX - w / 2,
        prevY = anchorCY - h / 2,
        dx = 0,
        dy = 0,
        vx = 0,
        vy = 0,

        dir       = opts.dir or "horizontal",
        t         = pressToLift and 1 or 0,
        direction = pressToLift and -1 or 1,
        speed     = opts.speed or 0.4,
        travel    = travelPx,

        always  = (opts.active ~= false and opts.target == nil),
        waiting = (not pressToLift) and (opts.active == false),
        target  = opts.target,
        pressToLift = pressToLift,
    }

    applyPosition(platform)

    table.insert(MovingPlatform.list, platform)
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
        p.prevX = p.x
        p.prevY = p.y

        local targetT
        if p.pressToLift then
            local isPressed = Plate.isDown(p.target)
            targetT = isPressed and 0 or 1

            if targetT > p.t then
                p.direction = 1
            elseif targetT < p.t then
                p.direction = -1
            else
                p.direction = 0
            end
        elseif p.target and p.waiting then
            goto continue
        end

        ------------------------------------------------------
        -- Parametric motion t ∈ [0,1]
        ------------------------------------------------------
        if p.direction ~= 0 then
            p.t = p.t + p.speed * dt * p.direction

            if targetT then
                if p.direction > 0 and p.t > targetT then
                    p.t = targetT
                elseif p.direction < 0 and p.t < targetT then
                    p.t = targetT
                end
            elseif p.t > 1 then
                p.t = 1
                p.direction = -1
            elseif p.t < 0 then
                p.t = 0
                p.direction = 1
            end
        end

        applyPosition(p)

        p.dx = p.x - p.prevX
        p.dy = p.y - p.prevY
        p.vx = p.dx / dt
        p.vy = p.dy / dt

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
