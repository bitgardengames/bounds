-- securitycamera.lua
------------------------------------------------------------
-- Single-instance decorative security camera
-- Smooth tracking, UNIFORM LED pulse, full draw logic
-- With premium pupil "refocus" animation
------------------------------------------------------------

local Player = require("player")  -- direct access to player

local SecurityCamera = {
    tileSize = 48,
    active = false,
    x = 0,
    y = 0,
    angle = 0,
    time = 0,

    --------------------------------------------------------
    -- NEW: Refocus animation state
    --------------------------------------------------------
    pupilScale = 1.0,       -- 1.0 = normal, 0.65 = contracted
    refocusTimer = 0,       -- counts up during contraction
    refocusActive = false,
    nextRefocus = 2.0       -- randomized on spawn and each cycle
}

local player = Player.get()

------------------------------------------------------------
-- helpers
------------------------------------------------------------
local function randomRefocusDelay()
    return 30 + love.math.random() * 60 -- 30–90 second range
end

local function startRefocus()
    SecurityCamera.refocusTimer = 0
    SecurityCamera.refocusActive = true
end

------------------------------------------------------------
-- SPAWN (single camera)
------------------------------------------------------------
function SecurityCamera.spawn(tx, ty)
    SecurityCamera.x = tx * SecurityCamera.tileSize
    SecurityCamera.y = ty * SecurityCamera.tileSize

    SecurityCamera.angle = 0
    SecurityCamera.time  = 0

    SecurityCamera.pupilScale = 1
    SecurityCamera.refocusTimer = 0
    SecurityCamera.refocusActive = false
    SecurityCamera.nextRefocus = randomRefocusDelay()

    SecurityCamera.active = true
end

------------------------------------------------------------
-- CLEAR
------------------------------------------------------------
function SecurityCamera.clear()
    SecurityCamera.active = false
end

------------------------------------------------------------
-- UPDATE
------------------------------------------------------------
function SecurityCamera.update(dt)
    if not SecurityCamera.active then return end

    if not player then return end

    SecurityCamera.time = SecurityCamera.time + dt

    ----------------------------------------------------------------
    -- TARGET TRACKING
    ----------------------------------------------------------------
    local px = player.x + player.w / 2
    local py = player.y + player.h / 2

    local cx = SecurityCamera.x + SecurityCamera.tileSize / 2
    local cy = SecurityCamera.y + SecurityCamera.tileSize / 2

    local dx = px - cx
    local dy = py - cy

    local targetAngle = math.atan2(dy, dx)

    SecurityCamera.angle =
        SecurityCamera.angle + (targetAngle - SecurityCamera.angle) * 0.18

    ----------------------------------------------------------------
    -- PREMIUM REFOCUS ANIMATION
    ----------------------------------------------------------------
    -- Trigger extra refocus when the player dies
    if player.dead and not SecurityCamera.refocusActive then
        startRefocus()
    end

    -- Idle randomized refocus timing
    if not SecurityCamera.refocusActive then
        SecurityCamera.nextRefocus = SecurityCamera.nextRefocus - dt
        if SecurityCamera.nextRefocus <= 0 then
            startRefocus()
            SecurityCamera.nextRefocus = randomRefocusDelay()
        end
    end

    -- Animation curve (fast pinch → smooth relax)
    if SecurityCamera.refocusActive then
        SecurityCamera.refocusTimer = SecurityCamera.refocusTimer + dt

        local t = SecurityCamera.refocusTimer

        if t < 0.08 then
            -- Fast contraction (linear)
            SecurityCamera.pupilScale = 1 - t / 0.08 * 0.35  -- down to ~0.65
        else
            -- Smooth recovery
            local k = (t - 0.08) / 0.22  -- ~220ms recover
            k = math.min(k, 1)
            SecurityCamera.pupilScale = 0.65 + (1 - 0.65) * (k * k * (3 - 2*k))
        end

        if t >= 0.30 then
            SecurityCamera.refocusActive = false
            SecurityCamera.pupilScale = 1
        end
    end
end

------------------------------------------------------------
-- DRAW
------------------------------------------------------------
local visualOffset = 5

function SecurityCamera.draw(style)
    if not SecurityCamera.active then return end

    local S = style
    local x = SecurityCamera.x
    local y = SecurityCamera.y
    local w = SecurityCamera.tileSize
    local h = SecurityCamera.tileSize
    local angle = SecurityCamera.angle
    local t = SecurityCamera.time

    ----------------------------------------------------------------
    -- UNIFORM BLINK
    ----------------------------------------------------------------
    local blinkCycle = 1.6
    local blink = (math.sin((t / blinkCycle) * math.pi * 2) + 1) * 0.5
    local ledAlpha = 0.25 + blink * 0.55

    ------------------------------------------------------
    -- MOUNT PLATE
    ------------------------------------------------------
    local plateW = 4
    local plateH = 32
    local plateX = x + visualOffset
    local plateY = y + h/2 - plateH/2

    love.graphics.setColor(0,0,0,1)
    love.graphics.rectangle("fill",
        plateX - 4, plateY - 4,
        plateW + 8, plateH + 8,
        4, 4
    )

    love.graphics.setColor(0.20, 0.20, 0.22)
    love.graphics.rectangle("fill",
        plateX, plateY,
        plateW, plateH,
        3, 3
    )

    ------------------------------------------------------
    -- ARM
    ------------------------------------------------------
    local armX = x + 13
    local armY = y + h/2 - 3
    local armW = 12
    local armH = 6

    love.graphics.setColor(0,0,0,1)
    love.graphics.rectangle("fill",
        armX - 4, armY - 4,
        armW + 8, armH + 8
    )

    love.graphics.setColor(S.grill)
    love.graphics.rectangle("fill",
        armX, armY,
        armW, armH
    )

    ------------------------------------------------------
    -- CAMERA BODY
    ------------------------------------------------------
    local ox = 4
    local bodyX = armX + armW
    local bodyY = y + 8
    local bodyW = 42
    local bodyH = 28

    love.graphics.setColor(0,0,0,1)
    love.graphics.rectangle("fill",
        bodyX - ox, bodyY - ox,
        bodyW + ox*2, bodyH + ox*2,
        10, 10
    )

    love.graphics.setColor(S.grill)
    love.graphics.rectangle("fill",
        bodyX, bodyY,
        bodyW, bodyH,
        8, 8
    )

    ------------------------------------------------------
    -- LED
    ------------------------------------------------------
    local ledX = bodyX + 8
    local ledY = bodyY + 8
    local ledR = 2.2

    love.graphics.setColor(S.dark)
    love.graphics.circle("fill", ledX, ledY, ledR + 4)

    love.graphics.setColor(S.dark)
    love.graphics.circle("fill", ledX, ledY, ledR + 1)

    love.graphics.setColor(1, 0.25, 0.25, ledAlpha)
    love.graphics.circle("fill", ledX, ledY, ledR)

    ------------------------------------------------------
    -- LENS + REFOCUSING PUPIL
    ------------------------------------------------------
    local lx = bodyX + bodyW * 0.62 + 2
    local ly = bodyY + bodyH/2

    -- Lens housing
    love.graphics.setColor(S.dark)
    love.graphics.circle("fill", lx, ly, 12)

    -- Tracking pupil (scaled)
    local pupilDist = 4 * SecurityCamera.pupilScale
    local pupilX = lx + math.cos(angle) * pupilDist
    local pupilY = ly + math.sin(angle) * pupilDist
    local pupilR = 5 * SecurityCamera.pupilScale

    love.graphics.setColor(1,1,1)
    love.graphics.circle("fill", pupilX, pupilY, pupilR)
end

return SecurityCamera