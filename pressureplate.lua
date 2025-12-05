--------------------------------------------------------------
-- PRESSURE PLATE — SIDE VIEW (supports cubes + player)
--------------------------------------------------------------

local Theme = require("theme")

local Plate = {}

--------------------------------------------------------------
-- CONSTANTS
--------------------------------------------------------------

local TILE       = 48
local OUTLINE    = 4
local EASE       = 12
local PRESS_DEPTH = 10

-- Visual sizes
local BASE_H     = 6
local BUTTON_H   = 10
local BUTTON_W   = 38

-- Vertical offsets
local BASE_OFFSET = 4
local BASE_UP     = 3
local BUTTON_PEEK = 4

--------------------------------------------------------------
-- INTERNAL STATE
--------------------------------------------------------------

Plate.x = 0
Plate.y = 0
Plate.active  = false
Plate.pressed = false
Plate.t       = 0

--------------------------------------------------------------
-- SPAWN
--------------------------------------------------------------

function Plate.spawn(x, y)
    Plate.x = x
    Plate.y = y
    Plate.active  = true
    Plate.pressed = false
    Plate.t       = 0
end

function Plate.clear()
    Plate.active = false
    Plate.pressed = false
    Plate.t = 0
end

--------------------------------------------------------------
-- QUERY
--------------------------------------------------------------

function Plate.isDown()
    return Plate.pressed
end

--------------------------------------------------------------
-- HELPER: check pressure from one object (player or cube)
--------------------------------------------------------------

local PRESS_TOLERANCE   = 2
local PRESS_HEIGHT      = BUTTON_H + BASE_H
local PRESS_FLOOR_OFFSET = 2

local function pressBounds(x, y)
    -- Gameplay coordinates treat x,y as the TILE's top-left corner. The visual
    -- art sits lower in the tile, but the collision band should hug the floor
    -- so the player’s feet can actually reach it. Anchor the band near the
    -- tile surface and keep it compact so a mid-air jump doesn't accidentally
    -- trigger the plate.

    local px1 = x
    local px2 = x + TILE

    local bandTop    = y + PRESS_FLOOR_OFFSET - PRESS_TOLERANCE
    local bandBottom = bandTop + PRESS_HEIGHT + PRESS_TOLERANCE * 2

    return px1, px2, bandTop, bandBottom
end

local function objectPressing(obj, px1, px2, bandTop, bandBottom)
    local ox, oy = obj.x, obj.y
    local ow, oh = obj.w, obj.h

    -- object feet
    local footX1 = ox
    local footX2 = ox + ow
    local footY  = oy + oh

    local touchingX = (footX2 >= px1 and footX1 <= px2)
    local touchingY = (footY >= bandTop and footY <= bandBottom)

    return touchingX and touchingY
end

--------------------------------------------------------------
-- UPDATE
--------------------------------------------------------------

function Plate.update(dt, player, cubes)
    if not Plate.active then return end

    local px1, px2, bandTop, bandBottom = pressBounds(Plate.x, Plate.y)

    ----------------------------------------------------------
    -- PLAYER PRESSING?
    ----------------------------------------------------------
    local pressed = objectPressing(player, px1, px2, bandTop, bandBottom)

    ----------------------------------------------------------
    -- ANY CUBE PRESSING?
    ----------------------------------------------------------
    if cubes then
        for _, c in ipairs(cubes) do
            if objectPressing(c, px1, px2, bandTop, bandBottom) then
                pressed = true
                break
            end
        end
    end

    Plate.pressed = pressed

    ----------------------------------------------------------
    -- SMOOTH ANIMATION
    ----------------------------------------------------------
    local target = Plate.pressed and 1 or 0
    Plate.t = Plate.t + (target - Plate.t) * dt * EASE
end

--------------------------------------------------------------
-- DRAW
--------------------------------------------------------------

function Plate.draw()
    if not Plate.active then return end

    local x, y = Plate.x, Plate.y
    local t = Plate.t

    ----------------------------------------------------------
    -- BASE POSITION
    ----------------------------------------------------------
    local baseTop = y + (TILE - BASE_H) + BASE_OFFSET - BASE_UP - 3

    ----------------------------------------------------------
    -- BUTTON SHRINK (instead of sliding)
    ----------------------------------------------------------
    local compress = PRESS_DEPTH * t
    local visualH = BUTTON_H - compress
    if visualH < 2 then visualH = 2 end

    local btnX = x + (TILE - BUTTON_W) * 0.5
    local btnY = baseTop - visualH

    ----------------------------------------------------------
    -- BUTTON (draw first)
    ----------------------------------------------------------
    love.graphics.setColor(Theme.pressurePlate.outline)
    love.graphics.rectangle(
        "fill",
        btnX - OUTLINE,
        btnY - OUTLINE,
        BUTTON_W + OUTLINE*2,
        visualH + OUTLINE*2,
        6,6
    )

    love.graphics.setColor(Theme.pressurePlate.button) -- cute red button
    love.graphics.rectangle(
        "fill",
        btnX,
        btnY,
        BUTTON_W,
        visualH,
        6,6
    )

    love.graphics.setColor(Theme.pressurePlate.buttonGlow)
    love.graphics.rectangle(
        "fill",
        btnX + 5,
        btnY + 3,
        BUTTON_W - 10,
        visualH * 0.35,
        6,6
    )

    ----------------------------------------------------------
    -- BASE (draw second)
    ----------------------------------------------------------
    love.graphics.setColor(Theme.pressurePlate.outline)
    love.graphics.rectangle(
        "fill",
        x - OUTLINE,
        baseTop - OUTLINE,
        TILE + OUTLINE*2,
        BASE_H + OUTLINE*2,
        4,4
    )

    love.graphics.setColor(Theme.pressurePlate.base)
    love.graphics.rectangle(
        "fill",
        x,
        baseTop,
        TILE,
        BASE_H,
        4,4
    )
end

return Plate
