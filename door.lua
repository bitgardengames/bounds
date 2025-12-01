--------------------------------------------------------------
-- DOOR (Single instance) — 48×48 Sliding Mechanical Door
--------------------------------------------------------------

local Door = {}

--------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------

local TILE = 48
local OUTLINE = 4

local PANEL_COLOR   = {0.92, 0.92, 0.92, 1}
local OUTLINE_COLOR = {0, 0, 0,   1}
local DEPTH_COLOR   = {0, 0, 0,   1}

local OPEN_RANGE = 10   -- distance panels slide outward (px)
local EASE       = 1.6

--------------------------------------------------------------
-- INTERNAL STATE
--------------------------------------------------------------

Door.x = 0
Door.y = 0
Door.w = TILE
Door.h = TILE

Door.openState = false  -- target state (open vs closed)
Door.t = 0              -- animation (0 = closed, 1 = fully open)

Door.active = false     -- whether a door exists in the level

--------------------------------------------------------------
-- SPAWN
--------------------------------------------------------------

function Door.spawn(x, y)
    Door.x = x
    Door.y = y
    Door.w = TILE
    Door.h = TILE

    Door.openState = false
    Door.t = 0
    Door.active = true
end

--------------------------------------------------------------
-- CONTROL
--------------------------------------------------------------

function Door.open()
    Door.openState = true
end

function Door.close()
    Door.openState = false
end

--------------------------------------------------------------
-- UPDATE
--------------------------------------------------------------

function Door.update(dt)
    if not Door.active then return end

    local target = Door.openState and 1 or 0
    local diff = target - Door.t

    if math.abs(diff) > 0.0001 then
        Door.t = Door.t + diff * dt * (3.2 + math.abs(diff) * EASE)
    else
        Door.t = target
    end
end

--------------------------------------------------------------
-- DRAW
--------------------------------------------------------------

function Door.draw()
    if not Door.active then return end

    local x, y, w, h = Door.x, Door.y, Door.w, Door.h
    local panelW = w * 0.5      -- 24px
    local t = Door.t

    ------------------------------------------------------
    -- DEPTH BACKGROUND (revealed only when opening)
    ------------------------------------------------------
    if t > 0 then
        love.graphics.setColor(DEPTH_COLOR)
        love.graphics.rectangle("fill", x, y, w, h)
    end

    ------------------------------------------------------
    -- PANEL POSITIONS
    ------------------------------------------------------
    local offset = OPEN_RANGE * t

    local leftX  = x + (panelW - panelW) - offset
    local rightX = x + panelW + offset

    ------------------------------------------------------
    -- PANEL DRAW FUNCTION
    ------------------------------------------------------
    local function drawPanel(px)
        -- outline
        love.graphics.setColor(OUTLINE_COLOR)
        love.graphics.rectangle(
            "fill",
            px - OUTLINE,
            y - OUTLINE,
            panelW + OUTLINE*2,
            h + OUTLINE*2,
            6, 6
        )

        -- fill
        love.graphics.setColor(PANEL_COLOR)
        love.graphics.rectangle(
            "fill",
            px,
            y,
            panelW,
            h,
            4, 4
        )
    end

    drawPanel(leftX)
    drawPanel(rightX)
end

return Door