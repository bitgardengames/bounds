-- monitor.lua
------------------------------------------------------------
-- Decorative monitor with tracking + refocus
-- Now supports left/right mounting via dir = 1 or -1
------------------------------------------------------------

local Player = require("player")  -- direct access to player
local Theme = require("theme")

local Monitor = {
    tileSize = 48,
    active   = false,
    x        = 0,
    y        = 0,
    angle    = 0,
    time     = 0,

    dir      = 1,    -- 1 = left wall (default), -1 = right wall

    --------------------------------------------------------
    -- Refocus animation state
    --------------------------------------------------------
    pupilScale    = 1.0,  -- 1.0 = normal, 0.65 = contracted
    refocusTimer  = 0,
    refocusActive = false,
    nextRefocus   = 2.0,
}

local player = Player.get()

------------------------------------------------------------
-- helpers
------------------------------------------------------------
local function randomRefocusDelay()
    return 30 + love.math.random() * 60 -- 30–90 second range
end

local function startRefocus()
    Monitor.refocusTimer  = 0
    Monitor.refocusActive = true
end

------------------------------------------------------------
-- SPAWN
------------------------------------------------------------
-- tx, ty: tile coordinates
-- dir: 1 (left wall, looking right) or -1 (right wall, looking left)
function Monitor.spawn(tx, ty, dir)
    Monitor.x = tx * Monitor.tileSize
    Monitor.y = ty * Monitor.tileSize

    Monitor.angle = 0
    Monitor.time  = 0

    Monitor.dir   = dir or 1

    Monitor.pupilScale    = 1
    Monitor.refocusTimer  = 0
    Monitor.refocusActive = false
    Monitor.nextRefocus   = randomRefocusDelay()

    Monitor.active = true
end

------------------------------------------------------------
-- CLEAR
------------------------------------------------------------
function Monitor.clear()
    Monitor.active = false
end

------------------------------------------------------------
-- UPDATE
------------------------------------------------------------
function Monitor.update(dt)
    if not Monitor.active then return end
    if not player then return end

    Monitor.time = Monitor.time + dt

    ----------------------------------------------------------------
    -- TARGET TRACKING (no dir-flip here; we handle mirroring in draw)
    ----------------------------------------------------------------
    local px = player.x + player.w / 2
    local py = player.y + player.h / 2

    local cx = Monitor.x + Monitor.tileSize / 2
    local cy = Monitor.y + Monitor.tileSize / 2

    local dx = px - cx
    local dy = py - cy

	local targetAngle
        if Monitor.dir == 1 then
                -- mounted on left wall, camera faces right
                targetAngle = math.atan2(dy, dx)
        else
                -- mounted on right wall, camera faces left (mirror X)
                targetAngle = math.atan2(dy, -dx)
        end

    Monitor.angle = Monitor.angle + (targetAngle - Monitor.angle) * 0.18

    ----------------------------------------------------------------
    -- PREMIUM REFOCUS ANIMATION
    ----------------------------------------------------------------
    -- Trigger extra refocus when the player dies
    if player.dead and not Monitor.refocusActive then
        startRefocus()
    end

    -- Idle randomized refocus timing
    if not Monitor.refocusActive then
        Monitor.nextRefocus = Monitor.nextRefocus - dt
        if Monitor.nextRefocus <= 0 then
            startRefocus()
            Monitor.nextRefocus = randomRefocusDelay()
        end
    end

    -- Animation curve (fast pinch → smooth relax)
    if Monitor.refocusActive then
        Monitor.refocusTimer = Monitor.refocusTimer + dt

        local t = Monitor.refocusTimer

        if t < 0.08 then
            -- Fast contraction (linear)
            Monitor.pupilScale = 1 - t / 0.08 * 0.35  -- down to ~0.65
        else
            -- Smooth recovery
            local k = (t - 0.08) / 0.22  -- ~220ms recover
            k = math.min(k, 1)
            Monitor.pupilScale = 0.65 + (1 - 0.65) * (k * k * (3 - 2*k))
        end

        if t >= 0.30 then
            Monitor.refocusActive = false
            Monitor.pupilScale = 1
        end
    end
end

------------------------------------------------------------
-- DRAW
------------------------------------------------------------
local visualOffset = 2

function Monitor.draw()
    if not Monitor.active then return end

    local S = Theme.decorations
    local x = Monitor.x
    local y = Monitor.y
    local w = Monitor.tileSize
    local h = Monitor.tileSize
    local angle = Monitor.angle
    local t = Monitor.time
    local dir = Monitor.dir or 1  -- 1 or -1

    ----------------------------------------------------------------
    -- UNIFORM BLINK
    ----------------------------------------------------------------
    local blinkCycle = 1.6
    local blink = (math.sin((t / blinkCycle) * math.pi * 2) + 1) * 0.5
    local ledAlpha = 0.25 + blink * 0.55

    ------------------------------------------------------
    -- GEOMETRY (dir-aware positions)
    ------------------------------------------------------
    local plateW = 4
    local plateH = 32

    -- plate near left or right wall
    local plateX
    if dir == 1 then
        plateX = x + visualOffset
    else
        plateX = x + w - visualOffset - plateW
    end
    local plateY = y + h/2 - plateH/2

    -- arm
    local armW = 12
    local armH = 6
    local armGap = 8 -- distance between plate & arm

    local armX
    if dir == 1 then
        armX = plateX + armGap
    else
        armX = plateX - armGap - armW + 4
    end
    local armY = y + h/2 - armH/2

    -- body
    local bodyW = 42
    local bodyH = 28

    local bodyX
    if dir == 1 then
        bodyX = armX + armW
    else
        bodyX = armX - bodyW
    end
    local bodyY = y + 8

    -- LED position (one side of the body)
    local ledOffsetX = 8
    local ledX
    if dir == 1 then
        ledX = bodyX + ledOffsetX
    else
        ledX = bodyX + bodyW - ledOffsetX
    end
    local ledY = bodyY + 8
    local ledR = 2.2

    -- Lens position inside body (mirrored)
    local lensOffset = bodyW * 0.62 + 2
    local lx
    if dir == 1 then
        lx = bodyX + lensOffset
    else
        lx = bodyX + bodyW - lensOffset
    end
    local ly = bodyY + bodyH/2

    ------------------------------------------------------
    -- MOUNT PLATE
    ------------------------------------------------------
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
    love.graphics.setColor(S.dark)
    love.graphics.circle("fill", ledX, ledY, ledR + 4)

    love.graphics.setColor(S.dark)
    love.graphics.circle("fill", ledX, ledY, ledR + 1)

    love.graphics.setColor(1, 0.25, 0.25, ledAlpha)
    love.graphics.circle("fill", ledX, ledY, ledR)

    ------------------------------------------------------
    -- LENS + REFOCUSING PUPIL
    ------------------------------------------------------
    -- Lens housing
    love.graphics.setColor(S.dark)
    love.graphics.circle("fill", lx, ly, 12)

	-- Tracking pupil (scaled + correctly mirrored horizontally)
        local pupilDist = 4 * Monitor.pupilScale

	local dx = math.cos(angle) * pupilDist * dir   -- mirror horizontally (once)
	local dy = math.sin(angle) * pupilDist         -- do not mirror Y

	local pupilX = lx + dx
	local pupilY = ly + dy
        local pupilR = 5 * Monitor.pupilScale

	love.graphics.setColor(1,1,1)
	love.graphics.circle("fill", pupilX, pupilY, pupilR)
end

return Monitor
