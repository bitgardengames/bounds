-- securitycamera.lua
------------------------------------------------------------
-- Single-instance decorative security camera
-- Smooth tracking, UNIFORM LED pulse, full draw logic
------------------------------------------------------------

local Player = require("player")  -- direct access to player

local SecurityCamera = {
    tileSize = 48,
    active = false,
    x = 0,
    y = 0,
    angle = 0,
    time = 0
}

------------------------------------------------------------
-- SPAWN (single camera)
------------------------------------------------------------
function SecurityCamera.spawn(tx, ty)
    SecurityCamera.x = tx * SecurityCamera.tileSize
    SecurityCamera.y = ty * SecurityCamera.tileSize
    SecurityCamera.angle = 0
    SecurityCamera.time = 0
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

    local player = Player.get()
    if not player then return end

    SecurityCamera.time = SecurityCamera.time + dt

    local px = player.x + player.w / 2
    local py = player.y + player.h / 2

    local cx = SecurityCamera.x + SecurityCamera.tileSize / 2
    local cy = SecurityCamera.y + SecurityCamera.tileSize / 2

    local dx = px - cx
    local dy = py - cy
    local targetAngle = math.atan2(dy, dx)

    SecurityCamera.angle =
        SecurityCamera.angle + (targetAngle - SecurityCamera.angle) * 0.18
end

------------------------------------------------------------
-- DRAW
------------------------------------------------------------
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
    local plateX = x
    local plateY = y + h/2 - plateH/2

    love.graphics.setColor(0,0,0,1)
    love.graphics.rectangle("fill",
        plateX - 4, plateY - 4,
        plateW + 8, plateH + 8,
        4, 4
    )

    love.graphics.setColor(S.dark)
    love.graphics.rectangle("fill",
        plateX, plateY,
        plateW, plateH,
        3, 3
    )

    ------------------------------------------------------
    -- ARM
    ------------------------------------------------------
    local armX = x + 8
    local armY = y + h/2 - 3
    local armW = 16
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
    -- CAMERA BODY  (WIDTH +2)
    ------------------------------------------------------
    local ox = 4
    local bodyX = armX + armW
    local bodyY = y + 8
    local bodyW = 42   -- WAS 40 → now 42
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
    -- LED BACKING (shifted left 2px, down 2px)
    ------------------------------------------------------
    local ledX = bodyX + 8      -- WAS +6 → now 2px left
    local ledY = bodyY + 8      -- WAS +6 → now 2px down
    local ledR = 2.2

    -- Outline
    love.graphics.setColor(S.dark)
    love.graphics.circle("fill", ledX, ledY, ledR + 4)

    -- Dark fill
    love.graphics.setColor(S.dark)
    love.graphics.circle("fill", ledX, ledY, ledR + 1)

    ------------------------------------------------------
    -- LED (uniform glow)
    ------------------------------------------------------
    love.graphics.setColor(1, 0.25, 0.25, ledAlpha)
    love.graphics.circle("fill", ledX, ledY, ledR)

    ------------------------------------------------------
    -- LENS (auto-adjusts to new body width)
    ------------------------------------------------------
    local lx = bodyX + bodyW * 0.62 + 2
    local ly = bodyY + bodyH/2

    love.graphics.setColor(S.dark)
    love.graphics.circle("fill", lx, ly, 12)

    local pupilDist = 4
    local pupilX = lx + math.cos(angle) * pupilDist
    local pupilY = ly + math.sin(angle) * pupilDist

    love.graphics.setColor(1,1,1)
    love.graphics.circle("fill", pupilX, pupilY, 5)
end

return SecurityCamera