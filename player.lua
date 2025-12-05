--------------------------------------------------------------
-- PLAYER MODULE (movement, collisions, deformation, drawing)
--------------------------------------------------------------

local Particles = require("particles")
local Blink = require("blink")
local Idle = require("idle")
local Input = require("input")
local Cube = require("cube")
local Collision = require("player.collision")
local Sleep = require("player.sleep")

local Player = {}

--------------------------------------------------------------
-- CONSTANTS
--------------------------------------------------------------

local GRAVITY        = 1350
local MAX_FALL_SPEED = 950
local WALL_SLIDE_FACTOR = 0.45
local WALL_JUMP_PUSH    = 260
local WALL_JUMP_UP      = -480
local PRE_JUMP_SQUISH_SCALE = 0.2
local CUBE_PUSH_MAX = 120

--------------------------------------------------------------
-- PLAYER DATA
--------------------------------------------------------------

local p = {
    x = 64,
    y = 128,

    spawnX = 64,
    spawnY = 128,

    w = 36,
    h = 36,

    radius  = 18,
    outline = 5,

    eyeDirX = 0,
    eyeDirY = 0,

    contactBottom = 0,
    contactTop    = 0,
    contactLeft   = 0,
    contactRight  = 0,

    springVert    = 0,
    springVertVel = 0,

    springHorz    = 0,
    springHorzVel = 0,

    vertK = 185,
    vertD = 22,

    horzK = 150,
    horzD = 20,

    vx = 0,
    vy = 0,

    maxSpeed        = 320,
    acceleration    = 2200,
    deceleration    = 3600,
    airAcceleration = 1750,
    airDeceleration = 1900,

    jumpStrength = -520,

    preJumpSquish = 0,

    -- jump anticipation state
    gathering      = false,
    gatherTime     = 0,
    gatherDuration = 0.02,

    onGround = false,
    pushingCube = false,
    pushingCubeDir = 0,
    pushingCubeRef = nil,
    pushingCubeGap = 0,

    coyoteTime       = 0.12,
    coyoteTimer      = 0,
    jumpBufferTime   = 0.12,
    jumpBufferTimer  = 0,

    wallCoyoteTime       = 0.15,
    wallCoyoteTimerLeft  = 0,
    wallCoyoteTimerRight = 0,

    lastDir = 0,

    respawnDelay = 1.0,
    respawnTimer = 0,
    dead = false,

    -- Sleep system
    idleTimer = 0,
    sleeping  = false,
    sleepEyeT = 0,
    sleepingTransition = false,
    sleepBubbleTimer = 0,

    prevY = 0,
}

--------------------------------------------------------------
-- INIT
--------------------------------------------------------------

function Player.init(Level)
    local TILE = (Level and Level.tileSize) or 48

    p.x = TILE * 2
    p.y = TILE * 4
    p.spawnX = p.x
    p.spawnY = p.y
end


local function clamp(v, mn, mx)
    return (v < mn and mn) or (v > mx and mx) or v
end

local function approach(a, b, dt, speed)
    if a < b then return math.min(a + speed * dt, b)
    else          return math.max(a - speed * dt, b)
    end
end

local function queueSleepBubbles()
    local breathe = Idle.getScale()
    local r = p.radius * breathe

    local headX = p.x + p.w * 0.5 + r * 0.55
    local headY = p.y + p.h - r - 4 - r * 0.65

    p.sleepBubbleQueue = {}

    for i = 0, 2 do
        local jitterX = (math.random() - 0.5) * 2.5
        local jitterY = (math.random() - 0.5) * 2.5

        local arcScale = 1 + i * 0.12
        local vx = (16 + math.random() * 3) * 0.5 * arcScale
        local vy = -(24 + math.random() * 4) * 0.5 * arcScale
        local size = 5 + i * 1.3
        local life = 1.35 + i * 0.08 + math.random() * 0.12

        local delay = i * 0.52 + math.random() * 0.16

        table.insert(p.sleepBubbleQueue, {
            timer = delay,
            x = headX + i * 5 + jitterX,
            y = headY - i * 6 + jitterY,
            vx = vx,
            vy = vy,
            size = size,
            life = life,
        })
    end
end

local function updateSleepBubbleQueue(dt)
    local queue = p.sleepBubbleQueue
    if not queue then return end

    for i = #queue, 1, -1 do
        local bubble = queue[i]
        bubble.timer = bubble.timer - dt

        if bubble.timer <= 0 then
            Particles.sleepBubble(
                bubble.x,
                bubble.y,
                bubble.vx,
                bubble.vy,
                bubble.size,
                bubble.life
            )

            queue[i] = queue[#queue]
            queue[#queue] = nil
        end
    end

    if #queue == 0 then
        p.sleepBubbleQueue = nil
    end
end

--------------------------------------------------------------
-- UPDATE
--------------------------------------------------------------

function Player.update(dt, Level)
    p.prevY = p.y

    ----------------------------------------------------------
    -- Death / respawn block
    ----------------------------------------------------------
    if p.dead then
        p.respawnTimer = math.max(p.respawnTimer - dt, 0)

        -- squash recovery while waiting
        p.contactBottom = approach(p.contactBottom, 0, dt, 8)
        p.contactTop    = approach(p.contactTop,    0, dt, 8)
        p.contactLeft   = approach(p.contactLeft,   0, dt, 8)
        p.contactRight  = approach(p.contactRight,  0, dt, 8)

        if p.respawnTimer <= 0 then
            p.x = p.spawnX
            p.y = p.spawnY
            p.vx, p.vy = 0, 0
            p.springVert, p.springVertVel = 0, 0
            p.springHorz, p.springHorzVel = 0, 0
            p.preJumpSquish = 0
            p.gathering = false
            p.gatherTime = 0
            p.jumpBufferTimer = 0
            p.coyoteTimer = 0
            p.wallCoyoteTimerLeft = 0
            p.wallCoyoteTimerRight = 0
            p.runDustTimer = 0
            p.contactBottom = 0
            p.contactTop = 0
            p.contactLeft = 0
            p.contactRight = 0
            p.onGround = false
            p.dead = false

            p.pushingCube = false
            p.pushingCubeDir = 0
            p.pushingCubeRef = nil
            p.pushingCubeGap = 0

            -- reset sleep state
            p.idleTimer = 0
            p.sleeping = false
            p.sleepingTransition = false
            p.sleepEyeT = 0
        end

        return p
    end

    local wasOnGround = p.onGround

    ----------------------------------------------------------
    -- Damping idle squash
    ----------------------------------------------------------
    local idleSquish = p.onGround and 0.08 or 0
    p.contactBottom = approach(p.contactBottom, idleSquish, dt, 10)
    p.contactTop    = approach(p.contactTop,    0, dt, 14)
    p.contactLeft   = approach(p.contactLeft,   0, dt, 14)
    p.contactRight  = approach(p.contactRight,  0, dt, 14)

    ----------------------------------------------------------
    -- Input
    ----------------------------------------------------------
    local move = 0
    if Input.isDown("a", "left", "gp_left") then move = move - 1 end
    if Input.isDown("d", "right", "gp_right") then move = move + 1 end

    local jumpDown     = Input.isJumpDown()
    local jumpReleased = Input.wasJumpReleased()

    ----------------------------------------------------------
    -- WAKE ON INPUT (sleep/wake logic)
    ----------------------------------------------------------
    Sleep.wakeOnInput(p, move, jumpDown, jumpReleased)

    ----------------------------------------------------------
    -- Jump buffer & coyote timers
    ----------------------------------------------------------
    if Input.consumeJump() then
        p.jumpBufferTimer = p.jumpBufferTime
    else
        p.jumpBufferTimer = math.max(p.jumpBufferTimer - dt, 0)
    end

    if p.onGround then
        p.coyoteTimer = p.coyoteTime
    else
        p.coyoteTimer = math.max(p.coyoteTimer - dt, 0)
    end

    p.wallCoyoteTimerLeft  = math.max(p.wallCoyoteTimerLeft  - dt, 0)
    p.wallCoyoteTimerRight = math.max(p.wallCoyoteTimerRight - dt, 0)

    ----------------------------------------------------------
    -- Horizontal movement
    ----------------------------------------------------------
    local targetSpeed = move * p.maxSpeed

    -- Handle cube pushing
    if p.pushingCube then
        targetSpeed = clamp(targetSpeed, -CUBE_PUSH_MAX, CUBE_PUSH_MAX)
        local diff = targetSpeed - p.vx
        p.vx = p.vx + diff * dt * 7.0
    else
        local accelerating = math.abs(targetSpeed) > 0
        local accel = accelerating
            and (p.onGround and p.acceleration or p.airAcceleration)
            or  (p.onGround and p.deceleration or p.airDeceleration)

        if accelerating then
            local dir = (targetSpeed > p.vx) and 1 or -1
            p.vx = p.vx + dir * accel * dt

            if (dir == 1 and p.vx > targetSpeed)
            or (dir == -1 and p.vx < targetSpeed) then
                p.vx = targetSpeed
            end

            local reversing = math.abs(p.vx) > 40 and
                              ((dir == 1 and p.lastDir == -1) or
                               (dir == -1 and p.lastDir == 1))

            local burstStart = (math.abs(p.vx) < 5 and math.abs(targetSpeed) > 200)

            if (reversing or burstStart) and p.onGround then
                Particles.puff(
                    p.x + p.w/2,
                    p.y + p.h,
                    (math.random()-0.5)*30,
                    5,
                    4, 0.25,
                    {1,1,1,0.9}
                )
            end

            p.lastDir = dir

            -- running dust
            if p.onGround then
                local speed = math.abs(p.vx)
                if speed > p.maxSpeed * 0.55 then
                    p.runDustTimer = (p.runDustTimer or 0) - dt
                    local interval = 0.12 - (speed / p.maxSpeed) * 0.04

                    if p.runDustTimer <= 0 then
                        p.runDustTimer = interval
                        Particles.puff(
                            p.x + p.w/2 + (math.random()-0.5)*8,
                            p.y + p.h + 2,
                            (math.random()*22 - 11),
                            -(10 + math.random()*18),
                            3.5, 0.28,
                            {1,1,1,0.85}
                        )
                    end
                else
                    p.runDustTimer = 0
                end
            end
        else
            if p.vx > 0 then p.vx = math.max(p.vx - accel*dt, 0)
            else            p.vx = math.min(p.vx + accel*dt, 0) end
        end
    end

    ----------------------------------------------------------
    -- Wall sliding
    ----------------------------------------------------------
    local touchingLeft  = p.wallCoyoteTimerLeft  > 0
    local touchingRight = p.wallCoyoteTimerRight > 0
    local touchingWall  = touchingLeft or touchingRight

    if touchingWall and not p.onGround and p.vy > 0 then
        p.vy = p.vy * WALL_SLIDE_FACTOR

        if math.random() < 0.12 then
            local dir = touchingLeft and -1 or 1
            Particles.wallDust(
                p.x + p.w/2 + dir*12,
                p.y + p.h/2 + math.random()*10,
                dir * -22,
                4 + math.random()*12,
                3.5, 0.32,
                {1,1,1,0.9}
            )
        end
    end

    ----------------------------------------------------------
    -- Jump logic (ground + wall + anticipation)
    ----------------------------------------------------------
    local doWall = false
    local wallDir = 0

    if p.jumpBufferTimer > 0 and not p.onGround then
        if p.wallCoyoteTimerLeft > 0 then
            doWall = true
            wallDir = 1
        elseif p.wallCoyoteTimerRight > 0 then
            doWall = true
            wallDir = -1
        end
    end

    if doWall then
        p.vx = WALL_JUMP_PUSH * wallDir
        p.vy = WALL_JUMP_UP
        p.jumpBufferTimer = 0

        p.springVertVel = p.springVertVel + 110
        p.springHorzVel = p.springHorzVel + (-wallDir * 120)

        p.preJumpSquish = -PRE_JUMP_SQUISH_SCALE

        Particles.puff(
            p.x + p.w/2 + (-wallDir)*10,
            p.y + p.h/2,
            -wallDir * 50,
            -40 + math.random()*60,
            5, 0.25,
            {1,1,1,1}
        )

        p.gathering  = false
        p.gatherTime = 0

    else
        local canGroundJump = p.onGround or p.coyoteTimer > 0

        if canGroundJump and jumpDown and not p.gathering then
            p.gathering = true
            p.gatherTime = 0
            p.preJumpSquish = 0
        end

        if p.gathering then
            if not p.onGround and p.coyoteTimer <= 0 then
                p.gathering = false
                p.gatherTime = 0
                p.preJumpSquish = 0
            else
                p.gatherTime = math.min(p.gatherTime + dt, p.gatherDuration)
                local t = clamp(p.gatherTime / p.gatherDuration, 0, 1)
                p.preJumpSquish = t * PRE_JUMP_SQUISH_SCALE

                if jumpReleased then
                    local stored = clamp(p.preJumpSquish, 0, PRE_JUMP_SQUISH_SCALE)

                    p.vy = p.jumpStrength
                    p.onGround = false
                    p.jumpBufferTimer = 0

                    p.springVertVel = p.springVertVel + 150 + stored * 150
                    p.preJumpSquish = -stored * 0.8

                    Particles.puff(
                        p.x + p.w/2,
                        p.y + p.h,
                        (math.random()-0.5)*60,
                        20 + math.random()*20,
                        6, 0.35,
                        {1,1,1,1}
                    )

                    p.gathering = false
                    p.gatherTime = 0
                end
            end
        end
    end

    ----------------------------------------------------------
    -- Jump squish decay
    ----------------------------------------------------------
    if not p.gathering then
        if p.preJumpSquish > 0 then
            p.preJumpSquish = math.max(p.preJumpSquish - dt * 12.0, 0)
        elseif p.preJumpSquish < 0 then
            p.preJumpSquish = math.min(p.preJumpSquish + dt * 10.0, 0)
        end
    end

    ----------------------------------------------------------
    -- Gravity
    ----------------------------------------------------------
    p.vy = p.vy + GRAVITY * dt
    p.vy = clamp(p.vy, -math.huge, MAX_FALL_SPEED)

    ----------------------------------------------------------
    -- Collision
    ----------------------------------------------------------
    p.onGround = false
    Collision.moveHorizontal(p, Level, p.vx * dt)
    Collision.moveVertical(p, Level, p.vy * dt)
    Collision.tryGroundSnap(p, Level)

    local justLanded = (not wasOnGround) and p.onGround
    if justLanded then
        for i=1,3 do
            Particles.puff(
                p.x + p.w/2 + (math.random()-0.5)*12,
                p.y + p.h + 1,
                (math.random()-0.5)*40,
                math.random()*20,
                4, 0.30,
                {1,1,1,1}
            )
        end
    end

    ----------------------------------------------------------
    -- Springs
    ----------------------------------------------------------
    do
        local s = p.springVert
        local v = p.springVertVel
        local f = -p.vertK*s - p.vertD*v
        v = v + f*dt
        s = s + v*dt
        p.springVert = clamp(s, -0.40, 0.40)
        p.springVertVel = v
    end

    do
        local s = p.springHorz
        local v = p.springHorzVel
        local f = -p.horzK*s - p.horzD*v
        v = v + f*dt
        s = s + v*dt
        p.springHorz = clamp(s, -0.40, 0.40)
        p.springHorzVel = v
    end

    ----------------------------------------------------------
    -- Eyes direction
    ----------------------------------------------------------
    local dx, dy = 0, 0
    if math.abs(p.vx) > 20 then dx = (p.vx > 0) and 1 or -1 end
    if math.abs(p.vy) > 50 then dy = (p.vy > 0) and 0.5 or -0.3 end

    local idleEyeX, idleEyeY = 0, 0
    if not p.sleeping and not p.sleepingTransition then
        idleEyeX, idleEyeY = Idle.getEyeOffset()
    end

    dx = clamp(dx + idleEyeX, -1, 1)
    dy = clamp(dy + idleEyeY, -1, 1)

    if p.sleeping or p.sleepingTransition then
        dx, dy = 0, 0
    end

    p.eyeDirX = approach(p.eyeDirX, dx, dt, 6)
    p.eyeDirY = approach(p.eyeDirY, dy, dt, 6)

    ----------------------------------------------------------
    -- CUBE collision push logic
    ----------------------------------------------------------
    p.pushingCube = false
    p.pushingCubeDir = 0
    p.pushingCubeRef = nil
    p.pushingCubeGap = 0
    for _, c in ipairs(Cube.list) do
        local px1, py1 = p.x, p.y
        local px2, py2 = p.x + p.w, p.y + p.h

        local cx1, cy1 = c.x, c.y
        local cx2, cy2 = c.x + c.w, c.y + c.h

        if px2 > cx1 and px1 < cx2 and py2 > cy1 and py1 < cy2 then
            local overlapX = math.min(px2, cx2) - math.max(px1, cx1)
            local overlapY = math.min(py2, cy2) - math.max(py1, cy1)

            if overlapX < overlapY then
                if (p.x + p.w / 2) < (c.x + c.w / 2) then
                    p.x = cx1 - p.w
                    p.vx = math.min(p.vx, 0)
                else
                    p.x = cx2
                    p.vx = math.max(p.vx, 0)
                end

                p.pushingCube = true
                p.pushingCubeDir = (p.x + p.w / 2) < (c.x + c.w / 2) and 1 or -1
                p.pushingCubeRef = c
                p.pushingCubeGap = 2.0
            else
                if (p.y + p.h / 2) < (c.y + c.h / 2) then
                    p.y = cy1 - p.h
                    p.onGround = true

                    p.contactBottom = math.max(p.contactBottom, 0.7)
                    p.springVertVel = p.springVertVel - 160
                else
                    p.y = cy2

                    p.contactTop = math.max(p.contactTop, 0.6)
                    p.springVertVel = p.springVertVel + 80
                end

                p.vy = 0
            end
        end
    end

    if p.pushingCube then
        local pushDir = p.pushingCubeDir

        if p.onGround then
            p.contactBottom = math.max(p.contactBottom, 0.16)
            p.springVertVel = p.springVertVel - 28 * dt

            if pushDir ~= 0 then
                if pushDir < 0 then
                    p.contactLeft = math.max(p.contactLeft, 0.18)
                else
                    p.contactRight = math.max(p.contactRight, 0.18)
                end

                p.springHorzVel = p.springHorzVel + pushDir * 28 * dt
            end
        end

        local c = p.pushingCubeRef
        if c then
            local gap = p.pushingCubeGap or 0

            if pushDir < 0 then
                local targetX = c.x + c.w + gap
                p.x = targetX
            elseif pushDir > 0 then
                local targetX = c.x - p.w - gap
                p.x = targetX
            end

            local followBlend = 0.65
            p.vx = p.vx * (1 - followBlend) + c.vx * followBlend
        end
    end

    local wasSleeping = p.sleeping

    ----------------------------------------------------------
    -- SLEEP SYSTEM (idle timer + transition)
    ----------------------------------------------------------
    Sleep.updateIdle(p, dt, move)

    ----------------------------------------------------------
    -- SLEEPY BLINK (Pixar-grade)
    ----------------------------------------------------------
    Sleep.updateBlink(p, dt)

    ----------------------------------------------------------
    -- ZZZ BUBBLES (soft, occasional trio)
    ----------------------------------------------------------
    if p.sleeping then
        if not wasSleeping then
            p.sleepBubbleTimer = 1.0 + math.random() * 0.8
        else
            p.sleepBubbleTimer = p.sleepBubbleTimer - dt
        end

        if p.sleepBubbleTimer <= 0 then
            queueSleepBubbles()
            p.sleepBubbleTimer = 2.6 + math.random() * 1.6
        end

        updateSleepBubbleQueue(dt)
    else
        p.sleepBubbleTimer = 0
        p.sleepBubbleQueue = nil
    end

    return p
end

--------------------------------------------------------------
-- DRAWING
--------------------------------------------------------------

local colors = {
    fill    = {236/255, 247/255, 255/255},
    outline = {0,0,0}
}

function Player.draw()
    local breathe = Idle.getScale()
    local r = p.radius * breathe

    if p.dead then return end

    local cx = p.x + p.w/2
    local cy = p.y + p.h - r - 4

    local vxNorm = clamp(p.vx / p.maxSpeed, -1, 1)
    local idleLean = p.sleeping and 0 or Idle.getLeanOffset()
    local lean = vxNorm * 0.10 + idleLean

    local cb = p.contactBottom
    local ct = p.contactTop
    local cl = p.contactLeft
    local cr = p.contactRight

    local sv = p.springVert
    local sh = p.springHorz

    cb = cb + clamp(-sv,0,0.60)
    ct = ct + (breathe - 1) * 1.2
    ct = ct + clamp( sv,0,0.45)
    cl = cl + clamp( sh,0,0.50)
    cr = cr + clamp(-sh,0,0.50)

	if p.sleeping then
		cb = cb + 0.18 -- sunk deeper into floor
	end

    local pre = p.preJumpSquish

    if p.sleeping then
        cb = cb + 0.04 -- slight extra squish into the floor while sleeping
    end

    local handX, handY = nil, nil
    if not p.sleeping and not p.sleepingTransition then
        handX, handY = Idle.getHandPose()
    end

    local baseEyeOffsetX = r*0.45
    local baseEyeOffsetY = -r*0.25
    local eyeRadius = r*0.28 * Blink.getEyeScale()

    local lx = p.eyeDirX * (r*0.22)
    local ly = p.eyeDirY * (r*0.22)

    local segments = 48
    local poly = {}

    love.graphics.push()
    love.graphics.translate(cx, cy)
    love.graphics.rotate(lean)

    for i = 0, segments do
        local angle = (i/segments)*math.pi*2
        local dx = math.cos(angle)
        local dy = math.sin(angle)
        local dist = r

        local bottomSquish = cb + pre

        if dy > 0 then dist = dist - bottomSquish*r*0.34*(dy*dy)
        else           dist = dist + bottomSquish*r*0.10*(dy*dy) end

        if dy < 0 then dist = dist - ct*r*0.32*(dy*dy)
        else           dist = dist + ct*r*0.10*(dy*dy) end

        if dx < 0 then dist = dist - cl*r*0.36*(dx*dx)
        else           dist = dist + cl*r*0.10*(dx*dx) end

        if dx > 0 then dist = dist - cr*r*0.36*(dx*dx)
        else           dist = dist + cr*r*0.10*(dx*dx) end

        poly[#poly+1] = dx*dist
        poly[#poly+1] = dy*dist
    end

    local bottom = -1e9
    for i = 2, #poly, 2 do
        bottom = math.max(bottom, poly[i])
    end
    local shift = r - bottom
    for i = 2, #poly, 2 do
        poly[i] = poly[i] + shift
    end

    local outlinePoly = {}
    local thick = p.outline

    for i = 1, #poly, 2 do
        local x = poly[i]
        local y = poly[i+1]
        local len = math.sqrt(x*x + y*y)
        if len < .0001 then len = .0001 end
        local nx = x/len
        local ny = y/len
        outlinePoly[#outlinePoly+1] = x + nx*thick
        outlinePoly[#outlinePoly+1] = y + ny*thick
    end

    love.graphics.setColor(colors.outline)
    love.graphics.polygon("fill", outlinePoly)

    love.graphics.setColor(colors.fill)
    love.graphics.polygon("fill", poly)

    if handX and handY then
        local hx = handX * r
        local hy = handY * r
        local tilt = -0.20 * (handX >= 0 and 1 or -1)

        love.graphics.push()
        love.graphics.translate(hx, hy)
        love.graphics.rotate(tilt)

        love.graphics.setColor(colors.fill)
        love.graphics.circle("fill", 0, 0, 6)

        love.graphics.setColor(colors.outline)
        love.graphics.setLineWidth(4)
        love.graphics.circle("line", 0, 0, 6)
        love.graphics.setLineWidth(1)

        love.graphics.pop()
    end

    love.graphics.setColor(0,0,0)
    local eyeOffsetX = baseEyeOffsetX
    local eyeOffsetY = baseEyeOffsetY + cb*r*0.10
    if p.sleeping then
        eyeOffsetY = eyeOffsetY + r*0.04 -- nudge eyes slightly lower when asleep
    end

    love.graphics.circle("fill", -eyeOffsetX+lx, eyeOffsetY+ly, eyeRadius)
    love.graphics.circle("fill",  eyeOffsetX+lx, eyeOffsetY+ly, eyeRadius)

    if eyeRadius < 0.5 then
        -- closed-eye lines (used automatically when Blink scale -> 0)
        love.graphics.setLineWidth(2)
        love.graphics.line(
            -eyeOffsetX+lx - r*0.20,
            eyeOffsetY+ly,
            -eyeOffsetX+lx + r*0.20,
            eyeOffsetY+ly
        )
        love.graphics.line(
            eyeOffsetX+lx - r*0.20,
            eyeOffsetY+ly,
            eyeOffsetX+lx + r*0.20,
            eyeOffsetY+ly
        )
    end

    love.graphics.pop()
end

--------------------------------------------------------------
-- API
--------------------------------------------------------------

function Player.get()
    return p
end

function Player.kill()
    if p.dead then return end

    p.dead = true
    p.respawnTimer = p.respawnDelay
    p.vx, p.vy = 0, 0
    p.gathering = false
    p.jumpBufferTimer = 0

    -- reset sleep on death
    p.idleTimer = 0
    p.sleeping  = false

    for i = 1, 8 do
        Particles.puff(
            p.x + p.w/2 + (math.random()-0.5)*10,
            p.y + p.h/2 + (math.random()-0.5)*10,
            (math.random()-0.5)*160,
            (math.random()-0.5)*120,
            5, 0.40,
            {1,1,1,1}
        )
    end
end

function Player.setSpawn(x, y)
    p.spawnX = x
    p.spawnY = y
    p.x = x
    p.y = y
    p.vx = 0
    p.vy = 0
    p.onGround = false
    p.sleeping = false
    p.contactBottom = 0
    p.contactTop    = 0
    p.contactLeft   = 0
    p.contactRight  = 0
end

return Player
