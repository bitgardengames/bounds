--------------------------------------------------------------
-- STOOMP BUTTON
-- A chunky pressure-plate-style button that:
-- • Activates ONLY when the player lands on it
-- • Slowly sinks with resistance, then ker-chunks
-- • Supports 3 modes:
--      "oneshot" (permanent press)
--      "timed"   (press activates target for N seconds)
--      "toggle"  (each press toggles state)
-- • Does NOT stay down due to weight (player or cube)
-- • Cubes CANNOT press it
--------------------------------------------------------------

local Theme = require("theme")
local Timer = require("systems.timer")

local StoompButton = { list = {} }

--------------------------------------------------------------
-- CONSTANTS
--------------------------------------------------------------

local TILE        = 48
local OUTLINE     = 4

-- Button geometry
local CAP_HEIGHT  = 20       -- taller than pressure plates
local CAP_PRESSED = 16       -- how far it sinks fully
local BASE_HEIGHT = 6

-- Animation
local RESIST_DELAY   = 0.10   -- hesitation before sinking
local SINK_TIME      = 0.18   -- duration of the actual sink
local RISE_TIME      = 0.25   -- spring-back for timed/toggle
local PRESS_THRESHOLD = -60   -- player vy must be this negative to count as a press

--------------------------------------------------------------
-- MODES:
--  "oneshot" — sinks once, stays down forever
--  "timed"   — sinks, stays for "duration", then rises back up
--  "toggle"  — press toggles active state; button rises after
--------------------------------------------------------------

local VALID_MODES = {
    oneshot = true,
    timed   = true,
    toggle  = true,
}

--------------------------------------------------------------
-- INTERNAL: Create a new button state
--------------------------------------------------------------

local function newButton(opts)
    local b = {
        id       = opts.id or ("button_" .. tostring(#StoompButton.list + 1)),
        x        = opts.x,
        y        = opts.y,
        tx       = opts.tx,
        ty       = opts.ty,

        mode     = opts.mode or "oneshot",
        duration = opts.duration or 3.0,  -- only used for "timed"

        active   = false,     -- logic state: ON/OFF
        pressing = false,     -- animation internal flag

        t        = 0,         -- animation timer 0..1 for sinking
        state    = "idle",    -- "idle", "resist", "sinking", "pressed", "rising"

        -- visuals
        capColor     = opts.capColor     or Theme.buttons.cap,
        capPressedColor = opts.capPressedColor or Theme.buttons.capPressed,
        baseColor    = opts.baseColor    or Theme.buttons.base,
        outlineColor = opts.outlineColor or Theme.outline,
    }

    return b
end

--------------------------------------------------------------
-- SPAWN
--------------------------------------------------------------

function StoompButton.spawn(tx, ty, opts)
    opts = opts or {}
    opts.tx = tx
    opts.ty = ty
    opts.x = tx * TILE
    opts.y = ty * TILE

    -- validate mode
    if not VALID_MODES[opts.mode] then
        print("Warning: invalid stoomp button mode '" .. tostring(opts.mode) .. "'; using 'oneshot'")
        opts.mode = "oneshot"
    end

    local b = newButton(opts)
    table.insert(StoompButton.list, b)
end

--------------------------------------------------------------
-- CLEAR
--------------------------------------------------------------

function StoompButton.clear()
    StoompButton.list = {}
end

--------------------------------------------------------------
-- CHECK PLAYER PRESS
--------------------------------------------------------------

local function playerPressedButton(b, player)
    -- Press only if landing onto TOP of the button
    local px, py = player.x, player.y
    local pw, ph = player.w, player.h

    -- Player's feet
    local footY = py + ph
    local footX1 = px
   local footX2 = px + pw

    -- Button top area
    local topY = b.y + (TILE - CAP_HEIGHT)
    local leftX  = b.x
    local rightX = b.x + TILE

    -- Check horizontal overlap
    local overlapX = (footX2 >= leftX) and (footX1 <= rightX)

    -- Check vertical touchdown (player coming DOWN)
    local descending = (player.vy < PRESS_THRESHOLD)

    -- Check if foot is entering button top region
    local hittingTop = (footY >= topY and footY <= topY + 12)

    return overlapX and descending and hittingTop
end

--------------------------------------------------------------
-- PRESS LOGIC
--------------------------------------------------------------

local function activateButton(b)
    if b.mode == "oneshot" then
        b.active = true
        b.state  = "pressed"

        -- never rises again
        return
    end

    if b.mode == "toggle" then
        b.active = not b.active
        b.state = "pressed"

        -- rise back up after small delay
        Timer.after(0.15, function()
            b.state = "rising"
            b.t = 1 -- start from fully pressed
        end)
        return
    end

    if b.mode == "timed" then
        b.active = true
        b.state = "pressed"

        -- Begin countdown
        Timer.after(b.duration, function()
            b.active = false
            b.state = "rising"
            b.t = 1
        end)
        return
    end
end

--------------------------------------------------------------
-- UPDATE
--------------------------------------------------------------

function StoompButton.update(dt, player)
    for _, b in ipairs(StoompButton.list) do

        ----------------------------------------------------------
        -- Detect Press (only when button is not already committed)
        ----------------------------------------------------------
        if b.state == "idle" and playerPressedButton(b, player) then
            b.state = "resist"
            b.t = 0
        end

        ----------------------------------------------------------
        -- Animation state machine
        ----------------------------------------------------------

        if b.state == "resist" then
            b.t = b.t + dt

            if b.t >= RESIST_DELAY then
                b.state = "sinking"
                b.t = 0
            end

        elseif b.state == "sinking" then
            b.t = b.t + dt / SINK_TIME

            if b.t >= 1 then
                b.t = 1
                activateButton(b)
            end

        elseif b.state == "pressed" then
            -- oneshot: stay pressed forever
            -- timed: timer callback handles rising later
            -- toggle: rising is scheduled separately
            if b.mode == "oneshot" then
                b.t = 1
            end

        elseif b.state == "rising" then
            b.t = b.t - dt / RISE_TIME

            if b.t <= 0 then
                b.t = 0
                b.state = "idle"
            end
        end
    end
end

--------------------------------------------------------------
-- DRAW
--------------------------------------------------------------

function StoompButton.draw()
    for _, b in ipairs(StoompButton.list) do
        local x, y = b.x, b.y
        local t = b.t

        ----------------------------------------------------------
        -- Compute cap vertical offset
        ----------------------------------------------------------
        local capTop       = y + (TILE - CAP_HEIGHT)
        local pressedDepth = CAP_PRESSED

        -- For "sinking" and "pressed", t = 0..1
        local offset = 0

        if b.state == "resist" then
            offset = 2  -- tiny squish

        elseif b.state == "sinking" then
            offset = pressedDepth * t

        elseif b.state == "pressed" then
            offset = pressedDepth

        elseif b.state == "rising" then
            offset = pressedDepth * t
        end

        ----------------------------------------------------------
        -- Draw base (outline + fill)
        ----------------------------------------------------------
        love.graphics.setColor(b.outlineColor)
        love.graphics.rectangle(
            "fill",
            x - OUTLINE,
            y + (TILE - BASE_HEIGHT) - OUTLINE,
            TILE + OUTLINE * 2,
            BASE_HEIGHT + OUTLINE * 2,
            6, 6
        )

        love.graphics.setColor(b.baseColor)
        love.graphics.rectangle(
            "fill",
            x,
            y + (TILE - BASE_HEIGHT),
            TILE,
            BASE_HEIGHT,
            6,6
        )

        ----------------------------------------------------------
        -- Draw cap
        ----------------------------------------------------------
        local capY = capTop + offset

        if b.active then
            love.graphics.setColor(b.capPressedColor)
        else
            love.graphics.setColor(b.capColor)
        end

        -- outline
        love.graphics.setColor(b.outlineColor)
        love.graphics.rectangle(
            "fill",
            x - OUTLINE,
            capY - OUTLINE,
            TILE + OUTLINE * 2,
            CAP_HEIGHT + OUTLINE * 2,
            6,6
        )

        -- cap fill
        love.graphics.setColor(b.active and b.capPressedColor or b.capColor)
        love.graphics.rectangle(
            "fill",
            x,
            capY,
            TILE,
            CAP_HEIGHT,
            6,6
        )
    end
end

return StoompButton