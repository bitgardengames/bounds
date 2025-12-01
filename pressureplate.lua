--------------------------------------------------------------
-- PRESSURE PLATE — SIDE VIEW (cute, thin base + button peek)
--------------------------------------------------------------

local Plate = {}

--------------------------------------------------------------
-- CONSTANTS
--------------------------------------------------------------

local TILE       = 48
local OUTLINE    = 4
local EASE       = 12
local PRESS_DEPTH = 10

-- Visual sizes
local BASE_H     = 6      -- thinner base height
local BUTTON_H   = 10     -- thinner button
local BUTTON_W   = 38

-- Vertical offsets
local BASE_OFFSET = 4     -- previous downward offset
local BASE_UP     = 3     -- pull base up by 2px now
local BUTTON_PEEK = 4     -- how much button shows under base at full press

--------------------------------------------------------------
-- INTERNAL STATE
--------------------------------------------------------------

Plate.x = 0
Plate.y = 0
Plate.active  = false
Plate.pressed = false
Plate.t       = 0         -- 0 = up, 1 = down

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

--------------------------------------------------------------
-- QUERY
--------------------------------------------------------------

function Plate.isDown()
    return Plate.pressed
end

--------------------------------------------------------------
-- PLAYER DETECTION (side-view foot test)
--------------------------------------------------------------

local function playerOnPlate(player)
    local px = player.x + player.w * 0.5
    local footY = player.y + player.h

    -- Compute base + button region
    local baseTop   = Plate.y + (TILE - BASE_H) + BASE_OFFSET - BASE_UP
    local buttonTop = baseTop - BUTTON_H

    -- Horizontal alignment
    local withinX = (px >= Plate.x and px <= Plate.x + TILE)

    -- Vertical overlap with button region
    local standing = (footY >= buttonTop and footY <= baseTop + BASE_H)

    return withinX and standing
end

--------------------------------------------------------------
-- UPDATE
--------------------------------------------------------------

function Plate.update(dt, player)
    if not Plate.active then return end

    Plate.pressed = playerOnPlate(player)

    -- Smooth 0→1 animation
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
    local baseTop = y + (TILE - BASE_H) + BASE_OFFSET - BASE_UP

    ----------------------------------------------------------
    -- BUTTON POSITION (slides down + peeks under)
    ----------------------------------------------------------
    local buttonTop =
        baseTop - BUTTON_H            -- normal button rest height
        + PRESS_DEPTH * t             -- depression animation
        + BUTTON_PEEK * t             -- peek under base

    local btnX = x + (TILE - BUTTON_W) * 0.5

    ----------------------------------------------------------
    -- BUTTON (DRAW FIRST so base covers it)
    ----------------------------------------------------------
	local compress = PRESS_DEPTH * t               -- how much to shrink
	local visualH = BUTTON_H - compress            -- new height
	if visualH < 2 then visualH = 2 end            -- safety floor

	local btnX = x + (TILE - BUTTON_W) * 0.5
	local btnY = baseTop - visualH                 -- keep seated on base

	-- OUTLINE
	love.graphics.setColor(0,0,0)
	love.graphics.rectangle(
		"fill",
		btnX - OUTLINE,
		btnY - OUTLINE,
		BUTTON_W + OUTLINE*2,
		visualH + OUTLINE*2,
		6,6
	)

	-- FILL
	love.graphics.setColor(0.92, 0.92, 0.95)
	love.graphics.rectangle(
		"fill",
		btnX,
		btnY,
		BUTTON_W,
		visualH,
		6,6
	)

	-- HIGHLIGHT
	love.graphics.setColor(1,1,1,0.18)

	love.graphics.rectangle(
		"fill",
		btnX + 5,
		btnY + 3,
		BUTTON_W - 10,
		visualH * 0.35,
		6,6
	)

    ----------------------------------------------------------
    -- BASE (DRAW SECOND — hides upper part of sinking button)
    ----------------------------------------------------------
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle(
        "fill",
        x - OUTLINE,
        baseTop - OUTLINE,
        TILE + OUTLINE * 2,
        BASE_H + OUTLINE * 2,
        4, 4
    )

    love.graphics.setColor(0.20, 0.20, 0.22)
    love.graphics.rectangle(
        "fill",
        x,
        baseTop,
        TILE,
        BASE_H,
        4, 4
    )
end

return Plate