--------------------------------------------------------------
-- CUBE MODULE — Pushable Weighted Puzzle Cube
-- Supports multiple cubes, gravity, tile collisions, pushing,
-- and real stable ground friction (no jitter).
--------------------------------------------------------------

local level = require("level")
local Particles = require("particles")

local Cube = { list = {} }

--------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------

local CUBE_SIZE = 32
local GRAVITY = 1800
local MAX_FALL_SPEED = 900
local PUSH_ACCEL = 720     -- smoother acceleration, feels weighty
local CUBE_PUSH_MAX = 155  -- caps speed while being pushed
local PUSH_STICTION = 28   -- extra resistance before the cube budges
local FRICTION = 8
local PUSH_FRICTION_SCALE = 0.45

local OUTLINE = 4
local COLOR_FILL = {0.92, 0.92, 0.95}
local COLOR_OUTLINE = {0,0,0}

--------------------------------------------------------------
-- SPAWN
--------------------------------------------------------------

function Cube.spawn(x, y)
    table.insert(Cube.list, {
        x = x,
        y = y,
        w = CUBE_SIZE,
        h = CUBE_SIZE,
        vx = 0,
        vy = 0,
        grounded = false,
        weight = 1,
        visualOffset = 4,
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
        -- falling downward, probe just BELOW the cube
        local footY = c.y + h
        local hitL = tileAtPixel(c.x + 2,     footY + 1, TILE, grid, width, height)
        local hitR = tileAtPixel(c.x + w - 2, footY + 1, TILE, grid, width, height)

        if hitL or hitR then
            c.vy = 0
            c.grounded = true

            -- snap cube bottom to the top of the tile
            local tileY = math.floor(footY / TILE) * TILE
            c.y = tileY - h
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
        local footY = c.y + h
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
        local hitB = tileAtPixel(rightX + 1, c.y + h - 2, TILE, grid, width, height)

        if hitT or hitB then
            c.vx = 0
            c.x = math.floor(rightX / TILE) * TILE - w
        end

    elseif c.vx < 0 then
        local leftX = c.x
        local hitT = tileAtPixel(leftX, c.y + 2, TILE, grid, width, height)
        local hitB = tileAtPixel(leftX, c.y + h - 2, TILE, grid, width, height)

        if hitT or hitB then
            c.vx = 0
            c.x = math.floor(leftX / TILE + 1) * TILE
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
            c.vx = c.vx + dir * math.min(resistance, CUBE_PUSH_MAX) * dt
        end

        c.vx = c.vx + (target - c.vx) * dt * (PUSH_ACCEL / 45)

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
-- UPDATE
--------------------------------------------------------------

function Cube.update(dt, player)
    local tileSize = level.tileSize or 48
    local grid = level.solidGrid
    local width = level.width or 0
    local height = level.height or 0

    for _, c in ipairs(Cube.list) do

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
        c.visualOffset = c.visualOffset + (targetOffset - c.visualOffset) * dt * 10

        ------------------------------------------------------
        -- APPLY MOTION
        ------------------------------------------------------
        c.x = c.x + c.vx * dt
        c.y = c.y + c.vy * dt

        ------------------------------------------------------
        -- COLLISIONS
        ------------------------------------------------------
        resolveTileCollision(c, tileSize, grid, width, height)
    end
end

--------------------------------------------------------------
-- DRAW
--------------------------------------------------------------

local visualOffset = 4

function Cube.draw()
    for _, c in ipairs(Cube.list) do
        local offset = c.visualOffset or visualOffset
        local w = c.w
        local h = c.h
        local ox = 0
        local oy = 0

        -- Outline
        love.graphics.setColor(COLOR_OUTLINE)
        love.graphics.rectangle(
            "fill",
            c.x - OUTLINE + ox,
            c.y - OUTLINE - offset + oy,
            w + OUTLINE*2,
            h + OUTLINE*2,
            6,6
        )

        -- Fill
        love.graphics.setColor(COLOR_FILL)
        love.graphics.rectangle(
            "fill",
            c.x + ox,
            c.y - offset + oy,
            w,
            h,
            6,6
        )
    end
end

return Cube
