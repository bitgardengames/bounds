--------------------------------------------------------------
-- PRESSURE PLATE — SIDE VIEW (supports cubes + player)
--------------------------------------------------------------

local Theme = require("theme")
local Decorations = require("decorations.init")

local Plate = { list = {} }

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

local function resetPlateState()
    return {
        id = nil,
        x = 0,
        y = 0,
        active  = false,
        pressed = false,
        t       = 0,
    }
end

function Plate.spawn(x, y, opts)
    opts = opts or {}

    local plate = resetPlateState()
    plate.id = tostring(opts.id or string.format("plate_%d", #Plate.list + 1))
    plate.x = x
    plate.y = y
    plate.active = true
	plate.oldPressed = false         -- for detecting press transitions
	plate.timer = opts.timer       -- id of timer_display to trigger (optional)

    table.insert(Plate.list, plate)
end

function Plate.clear()
    Plate.list = {}
end

local function findPlate(id)
    for _, p in ipairs(Plate.list) do
        if p.id == id then
            return p
        end
    end
end

function Plate.isDown(id)
    if id then
        local plate = findPlate(id)
        return plate and plate.pressed or false
    end

    for _, p in ipairs(Plate.list) do
        if p.pressed then return true end
    end

    return false
end

function Plate.allDown()
    if #Plate.list == 0 then return false end

    for _, p in ipairs(Plate.list) do
        if not p.pressed then
            return false
        end
    end

    return true
end

--------------------------------------------------------------
-- HELPER: check pressure from one object (player or cube)
--------------------------------------------------------------

local PRESS_TOLERANCE   = 2
local PRESS_HEIGHT      = BUTTON_H + BASE_H
local PRESS_FLOOR_OFFSET = 2

local function pressBounds(x, y)
    -- Gameplay coordinates treat x,y as the TILE's top-left corner. The visual
    -- art sits lower in the tile, but the collision band should hug the floor,
    -- not float near the tile's top. Anchor the band at the tile's floor so a
    -- walking player or a resting cube naturally overlaps it, while keeping
    -- the vertical span compact enough that jumping mid-air won't trigger it.

    local px1 = x
    local px2 = x + TILE

    local floorY     = y + TILE
    local bandBottom = floorY + PRESS_FLOOR_OFFSET + PRESS_TOLERANCE
    local bandTop    = bandBottom - PRESS_HEIGHT - PRESS_TOLERANCE * 2

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
    for _, p in ipairs(Plate.list) do
        if p.active then
            local px1, px2, bandTop, bandBottom = pressBounds(p.x, p.y)

            ------------------------------------------------------
            -- PLAYER PRESSING?
            ------------------------------------------------------
            local pressed = objectPressing(player, px1, px2, bandTop, bandBottom)

            ------------------------------------------------------
            -- ANY CUBE PRESSING?
            ------------------------------------------------------
            if cubes then
                for _, c in ipairs(cubes) do
                    if objectPressing(c, px1, px2, bandTop, bandBottom) then
                        pressed = true
                        break
                    end
                end
            end

            ------------------------------------------------------
            -- APPLY NEW PRESS STATE
            ------------------------------------------------------
            p.pressed = pressed

            ------------------------------------------------------
            -- DETECT **PRESS EVENT** (just pressed this frame)
            ------------------------------------------------------
            if not p.oldPressed and p.pressed then
                -- If this plate has a designated timer, trigger it
                if p.timer then
                    Decorations.startTimer(p.timer)
                end
            end

            ------------------------------------------------------
            -- REMEMBER STATE FOR NEXT FRAME
            ------------------------------------------------------
            p.oldPressed = p.pressed

            ------------------------------------------------------
            -- SMOOTH ANIMATION
            ------------------------------------------------------
            local target = p.pressed and 1 or 0
            p.t = p.t + (target - p.t) * dt * EASE
        end
    end
end

function Plate.draw()
    for _, p in ipairs(Plate.list) do
        if p.active then
            local x, y = p.x, p.y
            local t = p.t

            --------------------------------------------------
            -- BASE POSITION
            --------------------------------------------------
            local baseTop = y + (TILE - BASE_H) + BASE_OFFSET - BASE_UP - 3

            --------------------------------------------------
            -- BUTTON SHRINK (instead of sliding)
            --------------------------------------------------
            local compress = PRESS_DEPTH * t
            local visualH = BUTTON_H - compress
            if visualH < 2 then visualH = 2 end

            local btnX = x + (TILE - BUTTON_W) * 0.5
            local btnY = baseTop - visualH

            --------------------------------------------------
            -- BUTTON (draw first)
            --------------------------------------------------
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

            --------------------------------------------------
            -- BASE (draw second)
            --------------------------------------------------
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
    end
end

return Plate