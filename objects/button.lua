--------------------------------------------------------------
-- BUTTON — Tall Pressure Plate Variant (Player Only)
-- • Presses only when landed on from above
-- • Subtle resistance → delayed heavy commit
-- • Fires once, remains permanently depressed
--------------------------------------------------------------

local Theme  = require("theme")
local Events = require("systems.events")

local Button = { list = {} }

--------------------------------------------------------------
-- CONSTANTS
--------------------------------------------------------------

local TILE        = 48
local OUTLINE     = 4

-- Animation tuning
local SOFT_PRESS_AMOUNT = 0.18   -- initial give
local SOFT_PRESS_TIME   = 0.08   -- quick resistance
local COMMIT_DELAY      = 0.10   -- hesitation before give
local COMMIT_SPEED      = 6.5    -- slow heavy sink

local PRESS_DEPTH = 12

-- Visual sizes
local BASE_H     = 6
local BUTTON_H   = 24
local BUTTON_W   = 38

-- Vertical offsets
local BASE_OFFSET = 4
local BASE_UP     = 3

--------------------------------------------------------------
-- STATE
--------------------------------------------------------------

local function resetState()
    return {
        id          = nil,
        x           = 0,
        y           = 0,

        active      = false,
        pressed     = false,
        oldPressed  = false,
        latched     = false,
        fired       = false,   -- 🔑 ensures one-shot behavior

        -- animation
        t           = 0,
        pressPhase  = "idle",  -- idle → soft → commit → latched
        phaseTimer  = 0,
    }
end

--------------------------------------------------------------
-- SPAWN / CLEAR
--------------------------------------------------------------

function Button.spawn(tx, ty, opts)
    opts = opts or {}

    local b = resetState()
    b.id = tostring(opts.id or string.format("button_%d", #Button.list + 1))
    b.x  = tx * TILE
    b.y  = ty * TILE

    table.insert(Button.list, b)
end

function Button.clear()
    Button.list = {}
end

--------------------------------------------------------------
-- QUERY
--------------------------------------------------------------

local function find(id)
    for _, b in ipairs(Button.list) do
        if b.id == id then return b end
    end
end

function Button.isDown(id)
    local b = find(id)
    return b and b.latched or false
end

function Button.isActive(id)
    local b = find(id)
    return b and b.active or false
end

--------------------------------------------------------------
-- TOP SURFACE (used by player collision + press detection)
--------------------------------------------------------------

function Button.getTopSurface(b)
    local baseTop = b.y + (TILE - BASE_H) + BASE_OFFSET - BASE_UP - 3

    local compress = PRESS_DEPTH * b.t
    local visualH  = BUTTON_H - compress
    if visualH < 4 then visualH = 4 end

    local topY = baseTop - visualH
    local inset = 4   -- trim collision edges

    return {
        x1 = b.x + inset,
        x2 = b.x + TILE - inset,
        y  = topY
    }
end

--------------------------------------------------------------
-- UPDATE
--------------------------------------------------------------

function Button.update(dt, player)
    for _, b in ipairs(Button.list) do

        ------------------------------------------------------
        -- PRESS DETECTION (LANDING ONLY)
        ------------------------------------------------------
        local surf = Button.getTopSurface(b)
        local pressedNow = false

        if surf and not b.latched then
            local px1, px2 = player.x, player.x + player.w
            local py2 = player.y + player.h
            local prevFoot = (player.prevY or player.y) + player.h

            local overlapX = math.min(px2, surf.x2) - math.max(px1, surf.x1)
            local fromAbove = prevFoot <= surf.y + 1 and player.vy >= 0

            if overlapX > 0 and fromAbove and py2 >= surf.y then
                pressedNow = true
            end
        end

        b.pressed = pressedNow

        ------------------------------------------------------
        -- FIRE EVENT ONCE (BUT DO NOT LATCH YET)
        ------------------------------------------------------
        if b.pressed and not b.fired then
            b.fired  = true
            b.active = true
            Events.emit("button_pressed", { id = b.id })

            b.pressPhase = "soft"
            b.phaseTimer = 0
        end

        ------------------------------------------------------
        -- PRESS ANIMATION STATE MACHINE
        ------------------------------------------------------

        if b.pressPhase == "soft" then
            b.phaseTimer = b.phaseTimer + dt
            local k = math.min(b.phaseTimer / SOFT_PRESS_TIME, 1)
            b.t = SOFT_PRESS_AMOUNT * k

            if k >= 1 then
                b.pressPhase = "commit"
                b.phaseTimer = 0
            end

        elseif b.pressPhase == "commit" then
            b.phaseTimer = b.phaseTimer + dt

            if b.phaseTimer >= COMMIT_DELAY then
                b.t = b.t + (1 - b.t) * dt * COMMIT_SPEED
                if b.t >= 0.995 then
                    b.t = 1
                    b.latched = true     -- 🔒 latch ONLY here
                    b.pressPhase = "latched"
                end
            end

        elseif b.pressPhase == "latched" then
            b.t = 1
            b.active = true
        end

        b.oldPressed = b.pressed
    end
end

--------------------------------------------------------------
-- DRAW
--------------------------------------------------------------

function Button.draw()
    for _, b in ipairs(Button.list) do
        local x, y = b.x, b.y
        local t = b.t

        local baseTop = y + (TILE - BASE_H) + BASE_OFFSET - BASE_UP - 3

        --------------------------------------------------
        -- BUTTON COLUMN
        --------------------------------------------------
        local compress = PRESS_DEPTH * t
        local visualH  = BUTTON_H - compress
        if visualH < 4 then visualH = 4 end

        local btnX = x + (TILE - BUTTON_W) * 0.5
        local btnY = baseTop - visualH

        love.graphics.setColor(Theme.buttons.outline)
        love.graphics.rectangle(
            "fill",
            btnX - OUTLINE,
            btnY - OUTLINE,
            BUTTON_W + OUTLINE * 2,
            visualH + OUTLINE * 2,
            6, 6
        )

        love.graphics.setColor(
            b.latched and Theme.buttons.capPressed
            or Theme.buttons.cap
        )

        love.graphics.rectangle(
            "fill",
            btnX,
            btnY,
            BUTTON_W,
            visualH,
            6, 6
        )

        --------------------------------------------------
        -- BASE
        --------------------------------------------------
        love.graphics.setColor(Theme.buttons.outline)
        love.graphics.rectangle(
            "fill",
            x - OUTLINE,
            baseTop - OUTLINE,
            TILE + OUTLINE * 2,
            BASE_H + OUTLINE * 2,
            4, 4
        )

        love.graphics.setColor(Theme.buttons.base)
        love.graphics.rectangle(
            "fill",
            x,
            baseTop,
            TILE,
            BASE_H,
            4, 4
        )
    end
end

return Button