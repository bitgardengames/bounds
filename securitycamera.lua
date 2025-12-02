-- securitycamera.lua
------------------------------------------------------------
-- Single-instance decorative security camera
-- Smooth tracking, LED pulse, full draw logic
------------------------------------------------------------

local Player = require("player")  -- direct access to player

local SecurityCamera = {
    tileSize = 48,
    active = false,
    x = 0,
    y = 0,
    angle = 0,
    ledTimer = 0
}

------------------------------------------------------------
-- SPAWN (single camera)
------------------------------------------------------------
function SecurityCamera.spawn(tx, ty)
    SecurityCamera.x = tx * SecurityCamera.tileSize
    SecurityCamera.y = ty * SecurityCamera.tileSize
    SecurityCamera.angle = 0
    SecurityCamera.ledTimer = math.random() * 2
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

    local px = player.x + player.w / 2
    local py = player.y + player.h / 2

    local cx = SecurityCamera.x + SecurityCamera.tileSize / 2
    local cy = SecurityCamera.y + SecurityCamera.tileSize / 2

    local dx = px - cx
    local dy = py - cy
    local targetAngle = math.atan2(dy, dx)

    SecurityCamera.angle =
        SecurityCamera.angle + (targetAngle - SecurityCamera.angle) * 0.18

    SecurityCamera.ledTimer = SecurityCamera.ledTimer + dt
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

    ------------------------------------------------------
    -- LEFT MOUNT PLATE (adjusted as requested)
    ------------------------------------------------------
    local plateW = 4       -- thinner (was 6)
    local plateH = 32      -- taller (was 24)
    local plateX = x  -- moved 12px further left
    local plateY = y + h/2 - plateH/2

    -- outline
    love.graphics.setColor(0,0,0,1)
    love.graphics.rectangle("fill",
        plateX - 4, plateY - 4,
        plateW + 8, plateH + 8,
        4, 4
    )

    -- fill
    love.graphics.setColor(0.20, 0.20, 0.22, 1)
    love.graphics.rectangle("fill",
        plateX, plateY,
        plateW, plateH,
        3, 3
    )

    ------------------------------------------------------
    -- ARM (still 6px tall, connects to camera body)
    ------------------------------------------------------
    local armX = x + 8
    local armY = y + h/2 - 3
    local armW = 20
    local armH = 6

    -- outline
    love.graphics.setColor(0,0,0,1)
    love.graphics.rectangle("fill",
        armX - 4, armY - 4,
        armW + 8, armH + 8
    )

    -- fill
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
    local bodyW = 38
    local bodyH = 28

    -- outline
    love.graphics.setColor(0,0,0,1)
    love.graphics.rectangle("fill",
        bodyX - ox, bodyY - ox,
        bodyW + ox*2, bodyH + ox*2,
        10, 10
    )

    -- fill
    love.graphics.setColor(S.grill)
    love.graphics.rectangle("fill",
        bodyX, bodyY,
        bodyW, bodyH,
        8, 8
    )

    ------------------------------------------------------
    -- LED (top-left)
    ------------------------------------------------------
    local pulse = (math.sin(SecurityCamera.ledTimer * 4) + 1)*0.5
    local ledAlpha = 0.32 + pulse * 0.45

    love.graphics.setColor(1,0.25,0.25, ledAlpha)
    love.graphics.circle("fill",
        bodyX + 6,
        bodyY + 6,
        2.2
    )

    ------------------------------------------------------
    -- LENS (right side)
    ------------------------------------------------------
    local lx = bodyX + bodyW * 0.62
    local ly = bodyY + bodyH/2

    love.graphics.setColor(S.dark)
    love.graphics.circle("fill", lx, ly, 12)

    -- pupil
    local pupilDist = 4
    local pupilX = lx + math.cos(angle)*pupilDist
    local pupilY = ly + math.sin(angle)*pupilDist

    love.graphics.setColor(1,1,1)
    love.graphics.circle("fill", pupilX, pupilY, 5)
end

return SecurityCamera