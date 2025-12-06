--------------------------------------------------------------
-- CUBE MODULE — Pushable Weighted Puzzle Cube
-- Supports multiple cubes, gravity, tile collisions, pushing,
-- and real stable ground friction (no jitter).
--------------------------------------------------------------

local level = require("level")
local Particles = require("particles")
local Theme = require("theme")
local MovingPlatform = require("movingplatform")

local Cube = { list = {} }

--------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------

local CUBE_SIZE = 32
local GRAVITY = 1800
local MAX_FALL_SPEED = 900
local PUSH_ACCEL = 820     -- quicker blend toward top push speed
local CUBE_PUSH_MAX = 132  -- caps speed while being pushed
local PUSH_STICTION = 8    -- extra resistance before the cube budges
local FRICTION = 3.2
local PUSH_FRICTION_SCALE = 0.06

local OUTLINE = 4

local COLOR_FILL = Theme.cube.fill
local COLOR_OUTLINE = Theme.cube.outline
local RESTING_FOOT_OFFSET = 2
local PLATFORM_SINK = 2

--------------------------------------------------------------
-- SPAWN
--------------------------------------------------------------

function Cube.spawn(x, y, opts)
    opts = opts or {}

    table.insert(Cube.list, {
        id = tostring(opts.id or string.format("cube_%d", #Cube.list + 1)),
        x = x,
        y = y,
        w = CUBE_SIZE,
        h = CUBE_SIZE,
        vx = 0,
        vy = 0,
        grounded = false,
        weight = 1,
        visualOffset = 4,
        visualVelocity = 0,
        angle = 0,
        angularVelocity = 0,
        pushDustTimer = 0,
    })
end

function Cube.clear()
    Cube.list = {}
end

--------------------------------------------------------------
-- TILE COLLISION HELPERS
--------------------------------------------------------------

local function tileAtPixel(px, py, TILE, grid, width, height)
    local tx = math.floor(px / TILE) + 1
    local ty = math.floor(py / TILE) + 1

    if tx < 1 or ty < 1 or tx > width or ty > height then
        return false
    end

    local row = grid and grid[ty]
    return row and row[tx] == true
end

--------------------------------------------------------------
-- COLLISION RESOLUTION
--------------------------------------------------------------

local function resolveTileCollision(c, TILE, grid, width, height)
    local w, h = c.w, c.h

    c.grounded = false

    ----------------------------------------------------------
    -- VERTICAL COLLISION
    ----------------------------------------------------------
    if c.vy > 0 then
        -- falling downward, probe just BELOW the cube (adjusted for resting offset)
        local footY = c.y + h - RESTING_FOOT_OFFSET
        local hitL = tileAtPixel(c.x + 2,     footY + 1, TILE, grid, width, height)
        local hitR = tileAtPixel(c.x + w - 2, footY + 1, TILE, grid, width, height)

        if hitL or hitR then
            c.vy = 0
            c.grounded = true

            -- snap cube bottom to the top of the tile
            local tileY = math.floor(footY / TILE) * TILE
            c.y = tileY - h + RESTING_FOOT_OFFSET
        end

    elseif c.vy < 0 then
        -- upward movement
        local headY = c.y
        local hitL = tileAtPixel(c.x + 2,     headY, TILE, grid, width, height)
        local hitR = tileAtPixel(c.x + w - 2, headY, TILE, grid, width, height)

        if hitL or hitR then
            c.vy = 0
            c.y = math.floor(headY / TILE + 1) * TILE
        end
    end

    ----------------------------------------------------------
    -- SUPPORT PROBE (keeps cube grounded while resting)
    ----------------------------------------------------------
    if c.vy == 0 then
        local footY = c.y + h - RESTING_FOOT_OFFSET
        local hitL = tileAtPixel(c.x + 2,     footY + 1, TILE, grid, width, height)
        local hitR = tileAtPixel(c.x + w - 2, footY + 1, TILE, grid, width, height)

        if hitL or hitR then
            c.grounded = true
        end
    end

    ----------------------------------------------------------
    -- HORIZONTAL COLLISION
    ----------------------------------------------------------
    if c.vx > 0 then
        local rightX = c.x + w
        local hitT = tileAtPixel(rightX + 1, c.y + 2, TILE, grid, width, height)
        local hitB = tileAtPixel(rightX + 1, c.y + h - 2 - RESTING_FOOT_OFFSET, TILE, grid, width, height)

        if hitT or hitB then
            c.vx = 0
            c.x = math.floor(rightX / TILE) * TILE - w
        end

    elseif c.vx < 0 then
        local leftX = c.x
        local hitT = tileAtPixel(leftX, c.y + 2, TILE, grid, width, height)
        local hitB = tileAtPixel(leftX, c.y + h - 2 - RESTING_FOOT_OFFSET, TILE, grid, width, height)

        if hitT or hitB then
            c.vx = 0
            c.x = math.floor(leftX / TILE + 1) * TILE
        end
    end
end

local function resolvePlatformCollision(c)
    local margin = 1.6

    for _, platform in ipairs(MovingPlatform.list) do
        local cx1, cy1 = c.x, c.y
        local cx2, cy2 = c.x + c.w, c.y + c.h - RESTING_FOOT_OFFSET

        local px1, py1 = platform.x, platform.y
        local px2, py2 = platform.x + platform.w, platform.y + platform.h

        local overlapX = math.min(cx2, px2) - math.max(cx1, px1)
        local overlapY = math.min(cy2, py2) - math.max(cy1, py1)
        local alignedHorizontally = overlapX > -margin

        local prevY = c.prevY or c.y
        local prevFoot = (prevY + c.h - RESTING_FOOT_OFFSET)
        local fromAbove = prevFoot <= py1 + margin and c.vy >= 0
        local fromBelow = prevY >= py2 - margin and c.vy <= 0

        if overlapX > 0 and overlapY > 0 then
            if fromAbove or (overlapY <= overlapX and (c.y + c.h - RESTING_FOOT_OFFSET) <= py1 + overlapY) then
                c.y = py1 - c.h + PLATFORM_SINK + RESTING_FOOT_OFFSET
                c.vy = math.min(c.vy, platform.vy or 0)
                c.grounded = true
                c.x = c.x + (platform.dx or 0)
            elseif fromBelow then
                c.y = py2 - PLATFORM_SINK
                c.vy = math.max(c.vy, platform.vy or 0)
            elseif overlapX < overlapY then
                if (c.x + c.w / 2) < (platform.x + platform.w / 2) then
                    c.x = px1 - c.w
                    c.vx = math.min(c.vx, platform.vx or 0)
                else
                    c.x = px2
                    c.vx = math.max(c.vx, platform.vx or 0)
                end
            end
        elseif alignedHorizontally then
            local gap = py1 - cy2 + PLATFORM_SINK

            if gap >= -(margin + PLATFORM_SINK) and gap <= margin + 2 and c.vy >= 0 then
                c.y = py1 - c.h + PLATFORM_SINK + RESTING_FOOT_OFFSET
                c.vy = math.min(c.vy, platform.vy or 0)
                c.grounded = true
                c.x = c.x + (platform.dx or 0)
            elseif c.grounded and math.abs(gap) <= margin + 0.4 + PLATFORM_SINK then
                c.x = c.x + (platform.dx or 0)
            end
        end
    end
end

--------------------------------------------------------------
-- PUSHING
--------------------------------------------------------------

local function applyPush(c, player, dt)
    local px, py = player.x, player.y
    local pw, ph = player.w, player.h

    local verticalOverlap = (py + ph > c.y + 2 and py < c.y + c.h - 2)
    local horizontalTouch = (px + pw >= c.x - 6 and px <= c.x + c.w + 6)
    local touching = player.onGround and verticalOverlap and horizontalTouch

    if not touching then
        return false
    end

    -- Determine push direction
    local dir = 0
    local playerCenter = px + pw / 2
    local cubeCenter = c.x + c.w / 2

    if playerCenter < cubeCenter and px + pw <= c.x + c.w then
        dir = 1
    elseif playerCenter > cubeCenter and px >= c.x then
        dir = -1
    end

    if dir ~= 0 then
        local target = dir * CUBE_PUSH_MAX

        -- Start with a little "stiction" so the block feels hefty before moving
        local resistance = PUSH_STICTION
        if math.abs(c.vx) < resistance then
            c.vx = c.vx + dir * math.min(resistance, CUBE_PUSH_MAX) * dt * 1.2
        end

        local pushBlend = math.min(1, dt * (PUSH_ACCEL / 28))
        c.vx = c.vx + (target - c.vx) * pushBlend

        if math.abs(target - c.vx) < 2 then
            c.vx = target
        end

        if c.grounded and math.abs(c.vx) > 24 then
            c.pushDustTimer = (c.pushDustTimer or 0) - dt

            if c.pushDustTimer <= 0 then
                c.pushDustTimer = 0.22
                Particles.puff(
                    c.x + c.w/2 + dir * (c.w * 0.52),
                    c.y + c.h + 4,
                    dir * 8,
                    -10 + math.random()*12,
                    4.5, 0.32,
                    {1,1,1,0.82}
                )
            end
        else
            c.pushDustTimer = 0
        end
    end

    return true
end

--------------------------------------------------------------
-- FRICTION
--------------------------------------------------------------

local function applyFriction(c, dt, beingPushed)
    if not c.grounded then return end

    if math.abs(c.vx) < 1 then
        c.vx = 0
        return
    end

    local frictionForce = FRICTION * 1200
    if beingPushed then
        frictionForce = frictionForce * PUSH_FRICTION_SCALE
    end

    if c.vx > 0 then
        c.vx = c.vx - frictionForce * dt
        if c.vx < 0 then c.vx = 0 end
    else
        c.vx = c.vx + frictionForce * dt
        if c.vx > 0 then c.vx = 0 end
    end
end

--------------------------------------------------------------
-- VISUAL OFFSET (SOFT LANDING)
--------------------------------------------------------------

local function updateVisualOffset(c, dt, targetOffset)
    local stiffness = c.grounded and 42 or 28
    local damping = 10

    local offset = c.visualOffset or targetOffset
    local velocity = c.visualVelocity or 0

    local delta = targetOffset - offset
    velocity = velocity + delta * stiffness * dt
    velocity = velocity * math.max(0, 1 - damping * dt)

    offset = math.max(0, offset + velocity * dt)

    c.visualOffset = offset
    c.visualVelocity = velocity
end

--------------------------------------------------------------
-- VISUAL ANGLE (WOBBLE)
--------------------------------------------------------------

local function updateAngle(c, dt)
    local stiffness = c.grounded and 18 or 6
    local damping = c.grounded and 6 or 2.4

    c.angularVelocity = c.angularVelocity + (0 - c.angle) * stiffness * dt
    c.angularVelocity = c.angularVelocity * math.max(0, 1 - damping * dt)

    c.angle = c.angle + c.angularVelocity * dt
end

--------------------------------------------------------------
-- UPDATE
--------------------------------------------------------------

function Cube.update(dt, player)
    local tileSize = level.tileSize or 48
    local grid = level.solidGrid
    local width = level.width or 0
    local height = level.height or 0

    for _, c in ipairs(Cube.list) do
        local wasGrounded = c.grounded

        c.prevX, c.prevY = c.x, c.y

        ------------------------------------------------------
        -- GRAVITY
        ------------------------------------------------------
        if not c.grounded then
            c.vy = c.vy + GRAVITY * dt
            if c.vy > MAX_FALL_SPEED then
                c.vy = MAX_FALL_SPEED
            end
        end

        ------------------------------------------------------
        -- PUSH + FRICTION
        ------------------------------------------------------
        local pushing = applyPush(c, player, dt)
        applyFriction(c, dt, pushing)

        local targetOffset = c.grounded and 4 or 2
        local landingVy = c.vy

        ------------------------------------------------------
        -- APPLY MOTION
        ------------------------------------------------------
        c.x = c.x + c.vx * dt
        c.y = c.y + c.vy * dt

        ------------------------------------------------------
        -- COLLISIONS
        ------------------------------------------------------
        resolveTileCollision(c, tileSize, grid, width, height)
        resolvePlatformCollision(c)

        if wasGrounded and not c.grounded then
            local dir = c.vx >= 0 and 1 or -1
            c.angularVelocity = (c.angularVelocity or 0) + dir * 1.4
        end

        if not wasGrounded and c.grounded then
            local impactBoost = math.min(math.abs(landingVy) * 0.02, 12)
            c.visualVelocity = (c.visualVelocity or 0) + impactBoost

            local wobbleImpulse = math.min(math.abs(landingVy) * 0.0022, 1.8)
            local spinDir = c.vx ~= 0 and (c.vx > 0 and 1 or -1) or (math.random() < 0.5 and 1 or -1)
            c.angularVelocity = (c.angularVelocity or 0) * 0.35 + spinDir * wobbleImpulse
        end

        updateVisualOffset(c, dt, targetOffset)
        updateAngle(c, dt)
    end
end

--------------------------------------------------------------
-- DRAW
--------------------------------------------------------------

local visualOffset = 4
local circleInset = 4
local radius = 4

function Cube.draw()
    for _, c in ipairs(Cube.list) do
        local offset  = c.visualOffset or visualOffset
        local w       = c.w
        local h       = c.h
        local angle   = c.angle or 0
        local ox, oy  = 0, 0

        love.graphics.push()
        love.graphics.translate(c.x + w/2 + ox, c.y + h/2 - offset + oy)
        love.graphics.rotate(angle)

        ----------------------------------------------------------
        -- OUTLINE
        ----------------------------------------------------------
        love.graphics.setColor(COLOR_OUTLINE)
        love.graphics.rectangle(
            "fill",
            -w/2 - OUTLINE,
            -h/2 - OUTLINE,
            w + OUTLINE*2,
            h + OUTLINE*2,
            6, 6
        )

        ----------------------------------------------------------
        -- FILL
        ----------------------------------------------------------
        love.graphics.setColor(COLOR_FILL)
        love.graphics.rectangle(
            "fill",
            -w/2,
            -h/2,
            w,
            h,
            6, 6
        )

        ----------------------------------------------------------
        -- SEAM LINES
        ----------------------------------------------------------
        love.graphics.setColor(Theme.cube.seam)
        love.graphics.setLineWidth(4)

        -- Vertical seam (top → bottom)
        love.graphics.line(0, -h/2, 0, h/2)

        -- Horizontal seam (left → right)
        love.graphics.line(-w/2, 0, w/2, 0)

        ----------------------------------------------------------
        -- CENTER CIRCLE
        ----------------------------------------------------------

        -- OUTLINE
        love.graphics.setColor(Theme.outline)
        love.graphics.circle("fill", 0, 0, radius + circleInset)

        -- FILL
        love.graphics.setColor(Theme.cube.fill or Theme.solid)
        love.graphics.circle("fill", 0, 0, radius)

        love.graphics.pop()
    end
end

return Cube
