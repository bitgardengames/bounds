--------------------------------------------------------------
-- PLAYER MODULE (movement, collisions, deformation, drawing)
--------------------------------------------------------------

local Particles = require("particles")
local Blink     = require("blink")
local Idle      = require("idle")
local Input     = require("input")

local Player = {}

--------------------------------------------------------------
-- CONSTANTS
--------------------------------------------------------------

local GRAVITY        = 1350
local MAX_FALL_SPEED = 950
local WALL_SLIDE_FACTOR = 0.45
local WALL_JUMP_PUSH    = 260
local WALL_JUMP_UP      = -480

--------------------------------------------------------------
-- PLAYER DATA
--------------------------------------------------------------

local p = {
    x = 64,
    y = 128,

    spawnX = 64,
    spawnY = 128,

    w = 24,
    h = 24,

    radius  = 12,
    outline = 4,

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
}

--------------------------------------------------------------
-- INIT
--------------------------------------------------------------

function Player.init()
    p.x = 32 * 2
    p.y = 32 * 4
    p.spawnX = p.x
    p.spawnY = p.y
end

--------------------------------------------------------------
-- COLLISION HELPERS
--------------------------------------------------------------

local function tileAt(Level, tx, ty)
    return Level.tileAt(tx, ty)
end

--------------------------------------------------------------
-- GROUND SNAP
--------------------------------------------------------------

local function tryGroundSnap(Level)
    local TILE = Level.tileSize or 32

    if p.vy < 0 or p.onGround then return end

    local epsilon = 2
    local footY   = p.y + p.h
    local below   = math.floor(footY / TILE) + 1

    local lx = math.floor((p.x + 1)       / TILE) + 1
    local rx = math.floor((p.x + p.w - 2) / TILE) + 1

    for tx = lx, rx do
        if tileAt(Level, tx, below) == "#" then
            local snapY = (below - 1) * TILE - p.h
            if footY - snapY <= epsilon then
                p.y = snapY
                p.vy = 0
                p.onGround = true
                p.contactBottom = math.max(p.contactBottom, 0.5)
                return
            end
        end
    end
end

--------------------------------------------------------------
-- HORIZONTAL COLLISION
--------------------------------------------------------------

local function moveHorizontal(Level, amount)
    if amount == 0 then return false end
    local TILE = Level.tileSize or 32
    local collided = false

    local topTile    = math.floor(p.y / TILE) + 1
    local bottomTile = math.floor((p.y + p.h - 1) / TILE) + 1

    if amount > 0 then
        -- moving right
        local rightEdge = p.x + p.w
        local startTile = math.floor((rightEdge - 1) / TILE) + 1
        local endTile   = math.floor((rightEdge + amount - 1) / TILE) + 1
        local targetX   = p.x + amount

        for tx = startTile + 1, endTile do
            for ty = topTile, bottomTile do
                if tileAt(Level, tx, ty) == "#" then
                    collided = true
                    targetX = (tx - 1) * TILE - p.w
                    break
                end
            end
        end

        p.x = targetX

    else
        -- moving left
        local leftEdge = p.x
        local startTile = math.floor(leftEdge / TILE) + 1
        local endTile   = math.floor((leftEdge + amount) / TILE) + 1
        local targetX   = p.x + amount

        for tx = startTile - 1, endTile, -1 do
            for ty = topTile, bottomTile do
                if tileAt(Level, tx, ty) == "#" then
                    collided = true
                    targetX = tx * TILE
                    break
                end
            end
        end

        p.x = targetX
    end

    if collided then
        p.vx = 0
        if amount > 0 then
            p.contactRight = math.max(p.contactRight, 0.6)
            p.springHorzVel = p.springHorzVel - 60
            p.wallCoyoteTimerRight = p.wallCoyoteTime
        else
            p.contactLeft = math.max(p.contactLeft, 0.6)
            p.springHorzVel = p.springHorzVel + 60
            p.wallCoyoteTimerLeft = p.wallCoyoteTime
        end
    end

    return collided
end

--------------------------------------------------------------
-- VERTICAL COLLISION
--------------------------------------------------------------

local function moveVertical(Level, amount)
    if amount == 0 then return false end
    local TILE = Level.tileSize or 32
    local collided = false

    local lx = math.floor(p.x / TILE) + 1
    local rx = math.floor((p.x + p.w - 1) / TILE) + 1

    if amount > 0 then
        ------------------------------------------------------
        -- Moving down
        ------------------------------------------------------
        local bottomEdge = p.y + p.h
        local startTile  = math.floor(bottomEdge / TILE) + 1
        local endTile    = math.floor((bottomEdge + amount) / TILE) + 1
        local targetY    = p.y + amount

        for ty = startTile, endTile do
            for tx = lx, rx do
                if tileAt(Level, tx, ty) == "#" then
                    collided = true
                    targetY = (ty - 1) * TILE - p.h
                    break
                end
            end
        end

        p.y = targetY

        if collided then
            p.vy = 0
            p.onGround = true

            p.contactBottom = math.max(p.contactBottom, 0.7)
            p.springVertVel = p.springVertVel - 160
        end

    else
        ------------------------------------------------------
        -- Moving up
        ------------------------------------------------------
        local topEdge  = p.y
        local startTile = math.floor(topEdge / TILE) + 1
        local endTile   = math.floor((topEdge + amount) / TILE) + 1
        local targetY   = p.y + amount

        for ty = startTile, endTile, -1 do
            for tx = lx, rx do
                if tileAt(Level, tx, ty) == "#" then
                    collided = true
                    targetY = ty * TILE
                    break
                end
            end
        end

        p.y = targetY

        if collided then
            p.vy = 0
            p.contactTop = math.max(p.contactTop, 0.6)
            p.springVertVel = p.springVertVel + 80

            Particles.puff(
                p.x + p.w/2 + (math.random()-0.5)*4,
                p.y - 2,
                (math.random()*32 - 16)*1.4,
                35 + math.random()*25,
                4, 0.28,
                {1,1,1,0.9}
            )
        end
    end

    return collided
end

--------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------

local function clamp(v, mn, mx)
    return (v < mn and mn) or (v > mx and mx) or v
end

local function approach(a, b, dt, speed)
    if a < b then return math.min(a + speed * dt, b)
    else          return math.max(a - speed * dt, b)
    end
end

--------------------------------------------------------------
-- UPDATE
--------------------------------------------------------------

function Player.update(dt, Level)
    if p.dead then
        p.respawnTimer = math.max(p.respawnTimer - dt, 0)

        -- allow squash to recover while waiting to respawn
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
        end

        return p
    end

    local wasOnGround = p.onGround

    -- contact smoothing
    local idleSquish = p.onGround and 0.08 or 0
    p.contactBottom = approach(p.contactBottom, idleSquish, dt, 10)
    p.contactTop    = approach(p.contactTop,    0, dt, 14)
    p.contactLeft   = approach(p.contactLeft,   0, dt, 14)
    p.contactRight  = approach(p.contactRight,  0, dt, 14)

    ----------------------------------------------------------
    -- INPUT  (UPDATED FOR GAMEPAD)
    ----------------------------------------------------------
    local move = 0

    -- keyboard + gamepad mapped together
    if Input.isDown("a", "left", "gp_left") then
        move = move - 1
    end
    if Input.isDown("d", "right", "gp_right") then
        move = move + 1
    end

    local jumpDown     = Input.isJumpDown()
    local jumpReleased = Input.wasJumpReleased()

    ----------------------------------------------------------
    -- JUMP BUFFER + COYOTE
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
    -- HORIZONTAL MOVEMENT
    ----------------------------------------------------------
    local targetSpeed = move * p.maxSpeed
    local accelerating = math.abs(targetSpeed) > 0

    local accel =
        accelerating
        and (p.onGround and p.acceleration or p.airAcceleration)
        or  (p.onGround and p.deceleration or p.airDeceleration)

    if accelerating then
        local dir = (targetSpeed > p.vx) and 1 or -1
        p.vx = p.vx + dir * accel * dt

        if (dir == 1 and p.vx > targetSpeed)
        or  (dir == -1 and p.vx < targetSpeed)
        then
            p.vx = targetSpeed
        end

        ------------------------------------------------------
        -- dust feedback
        ------------------------------------------------------
        local reversing =
            math.abs(p.vx) > 40 and
            ((dir == 1 and p.lastDir == -1) or (dir == -1 and p.lastDir == 1))

        local burstStart =
            (math.abs(p.vx) < 5 and math.abs(targetSpeed) > 200)

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

        -- running dust trail
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
        -- deceleration
        if p.vx > 0 then
            p.vx = math.max(p.vx - accel*dt, 0)
        elseif p.vx < 0 then
            p.vx = math.min(p.vx + accel*dt, 0)
        end
    end

    ----------------------------------------------------------
    -- WALL SLIDING
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
    -- JUMPING (ground, wall, anticipation)
    ----------------------------------------------------------
    local doWall = false
    local wallDir = 0

    -- wall jump check
    if p.jumpBufferTimer > 0 then
        if not p.onGround then
            if p.wallCoyoteTimerLeft > 0 then
                doWall = true
                wallDir = 1
            elseif p.wallCoyoteTimerRight > 0 then
                doWall = true
                wallDir = -1
            end
        end
    end

    if doWall then
        -- WALL JUMP
        p.vx = WALL_JUMP_PUSH * wallDir
        p.vy = WALL_JUMP_UP
        p.jumpBufferTimer = 0

        p.springVertVel = p.springVertVel + 110
        p.springHorzVel = p.springHorzVel + (-wallDir * 120)

        p.preJumpSquish = -0.6

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
        -- Ground / coyote jump anticipation
        local canGroundJump = p.onGround or p.coyoteTimer > 0

        if canGroundJump and jumpDown and not p.gathering then
            p.gathering     = true
            p.gatherTime    = 0
            p.preJumpSquish = 0
        end

        if p.gathering then
            -- cancel if lost ground/coyote
            if not p.onGround and p.coyoteTimer <= 0 then
                p.gathering      = false
                p.gatherTime     = 0
                p.preJumpSquish  = 0
            else
                -- build squish while button is held
                p.gatherTime = math.min(p.gatherTime + dt, p.gatherDuration)
                local t = clamp(p.gatherTime / p.gatherDuration, 0, 1)
                p.preJumpSquish = t

                if jumpReleased then
                    -- JUMP!
                    local stored = clamp(p.preJumpSquish, 0, 1)

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

                    p.gathering  = false
                    p.gatherTime = 0
                end
            end
        end
    end

    ----------------------------------------------------------
    -- JUMP SQUISH DECAY
    ----------------------------------------------------------
    if not p.gathering then
        if p.preJumpSquish > 0 then
            p.preJumpSquish = math.max(p.preJumpSquish - dt * 12.0, 0)
        elseif p.preJumpSquish < 0 then
            p.preJumpSquish = math.min(p.preJumpSquish + dt * 10.0, 0)
        end
    end

    ----------------------------------------------------------
    -- GRAVITY
    ----------------------------------------------------------
    p.vy = p.vy + GRAVITY * dt
    p.vy = clamp(p.vy, -math.huge, MAX_FALL_SPEED)

    ----------------------------------------------------------
    -- COLLISION
    ----------------------------------------------------------
    p.onGround = false
    moveHorizontal(Level, p.vx * dt)
    moveVertical(Level, p.vy * dt)
    tryGroundSnap(Level)

    local justLanded = (not wasOnGround) and p.onGround
    if justLanded then
        for i=1,3 do
            Particles.puff(
                p.x + p.w/2 + (math.random()-0.5)*12,
                p.y + p.h + 2,
                (math.random()-0.5)*40,
                math.random()*20,
                4, 0.30,
                {1,1,1,1}
            )
        end
    end

    ----------------------------------------------------------
    -- SPRINGS
    ----------------------------------------------------------
    -- vertical
    do
        local s = p.springVert
        local v = p.springVertVel
        local f = -p.vertK*s - p.vertD*v
        v = v + f*dt
        s = s + v*dt
        p.springVert = clamp(s, -0.40, 0.40)
        p.springVertVel = v
    end

    -- horizontal
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
    -- EYES
    ----------------------------------------------------------
    local dx, dy = 0, 0
    if math.abs(p.vx) > 20 then dx = (p.vx > 0) and 1 or -1 end
    if math.abs(p.vy) > 50 then dy = (p.vy > 0) and 0.5 or -0.3 end

    p.eyeDirX = approach(p.eyeDirX, dx, dt, 6)
    p.eyeDirY = approach(p.eyeDirY, dy, dt, 6)

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
    local lean = vxNorm * 0.10

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

    local pre = p.preJumpSquish
    local preSide = math.min(math.max(pre, 0) * 0.6, 0.3)

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

        local bottomSquish = cb + pre * 0.35
        local sideSquish   = preSide

        if dy > 0 then dist = dist - bottomSquish*r*0.34*(dy*dy)
        else           dist = dist + bottomSquish*r*0.10*(dy*dy) end

        if dy < 0 then dist = dist - ct*r*0.32*(dy*dy)
        else           dist = dist + ct*r*0.10*(dy*dy) end

        if dx < 0 then dist = dist - (cl - sideSquish)*r*0.36*(dx*dx)
        else           dist = dist + (cl + sideSquish)*r*0.10*(dx*dx) end

        if dx > 0 then dist = dist - (cr - sideSquish)*r*0.36*(dx*dx)
        else           dist = dist + (cr + sideSquish)*r*0.10*(dx*dx) end

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

    love.graphics.setColor(0,0,0)
    local eyeOffsetX = baseEyeOffsetX
    local eyeOffsetY = baseEyeOffsetY + cb*r*0.10

    love.graphics.circle("fill", -eyeOffsetX+lx, eyeOffsetY+ly, eyeRadius)
    love.graphics.circle("fill",  eyeOffsetX+lx, eyeOffsetY+ly, eyeRadius)

    if eyeRadius < 0.5 then
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
end

return Player