--------------------------------------------------------------
-- CUBE MODULE — Pushable Weighted Puzzle Cube
-- Supports multiple cubes, gravity, tile collisions, pushing,
-- and real stable ground friction (no jitter).
--------------------------------------------------------------

local level = require("level")

local Cube = { list = {} }

--------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------

local CUBE_SIZE = 32
local GRAVITY = 1800
local MAX_FALL_SPEED = 900
local PUSH_ACCEL = 900     -- smoother acceleration
local CUBE_PUSH_MAX = 155  -- caps speed while being pushed
local FRICTION = 8

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
    })
end

function Cube.clear()
    Cube.list = {}
end

--------------------------------------------------------------
-- TILE COLLISION HELPERS
--------------------------------------------------------------

local function tileAtPixel(px, py)
    local TILE = level.tileSize or 48
    local tx = math.floor(px / TILE) + 1
    local ty = math.floor(py / TILE) + 1
    return level.tileAt(tx, ty) == "#"
end

--------------------------------------------------------------
-- COLLISION RESOLUTION
--------------------------------------------------------------

local function resolveTileCollision(c)
    local x, y, w, h = c.x, c.y, c.w, c.h
    local TILE = level.tileSize or 48

    c.grounded = false

    ----------------------------------------------------------
    -- VERTICAL COLLISION
    ----------------------------------------------------------
    if c.vy > 0 then
        -- falling downward, probe just BELOW the cube
        local footY = y + h
        local hitL = tileAtPixel(x + 2,     footY + 1)
        local hitR = tileAtPixel(x + w - 2, footY + 1)

        if hitL or hitR then
            c.vy = 0
            c.grounded = true

            -- snap cube bottom to the top of the tile
            local tileY = math.floor(footY / TILE) * TILE
            c.y = tileY - h
        end

    elseif c.vy < 0 then
        -- upward movement
        local headY = y
        local hitL = tileAtPixel(x + 2,     headY)
        local hitR = tileAtPixel(x + w - 2, headY)

        if hitL or hitR then
            c.vy = 0
            c.y = math.floor(headY / TILE + 1) * TILE
        end
    end

    ----------------------------------------------------------
    -- HORIZONTAL COLLISION
    ----------------------------------------------------------
    if c.vx > 0 then
        local rightX = x + w
        local hitT = tileAtPixel(rightX + 1, y + 2)
        local hitB = tileAtPixel(rightX + 1, y + h - 2)

        if hitT or hitB then
            c.vx = 0
            c.x = math.floor(rightX / TILE) * TILE - w
        end

    elseif c.vx < 0 then
        local leftX = x
        local hitT = tileAtPixel(leftX, y + 2)
        local hitB = tileAtPixel(leftX, y + h - 2)

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

	local verticalOverlap = player.onGround and (py + ph > c.y + 4 and py < c.y + c.h - 4)
	local touching = verticalOverlap and ((px + pw >= c.x - 12 and px + pw <= c.x + 4) or (px >= c.x + c.w - 4 and px <= c.x + c.w + 12))

    if not touching then
        return false
    end

    -- Determine push direction
    local dir = 0
    if px + pw < c.x then  -- player left of cube
        dir = 1
    elseif px > c.x + c.w then -- player right of cube
        dir = -1
    end

    if dir ~= 0 then
        local target = dir * CUBE_PUSH_MAX
        c.vx = c.vx + (target - c.vx) * dt * 16
    end

    return true
end

--------------------------------------------------------------
-- FRICTION
--------------------------------------------------------------

local function applyFriction(c, dt, beingPushed)
    if not c.grounded then return end
    if beingPushed then return end

    if math.abs(c.vx) < 1 then
        c.vx = 0
        return
    end

    local frictionForce = FRICTION * 1200

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

        ------------------------------------------------------
        -- APPLY MOTION
        ------------------------------------------------------
        c.x = c.x + c.vx * dt
        c.y = c.y + c.vy * dt

        ------------------------------------------------------
        -- COLLISIONS
        ------------------------------------------------------
        resolveTileCollision(c)
    end
end

--------------------------------------------------------------
-- DRAW
--------------------------------------------------------------

function Cube.draw()
    for _, c in ipairs(Cube.list) do
        -- Outline
        love.graphics.setColor(COLOR_OUTLINE)
        love.graphics.rectangle(
            "fill",
            c.x - OUTLINE,
            c.y - OUTLINE,
            c.w + OUTLINE*2,
            c.h + OUTLINE*2,
            6,6
        )

        -- Fill
        love.graphics.setColor(COLOR_FILL)
        love.graphics.rectangle(
            "fill",
            c.x,
            c.y,
            c.w,
            c.h,
            6,6
        )

        -- Highlight
        love.graphics.setColor(1,1,1,0.14)
        love.graphics.rectangle(
            "fill",
            c.x + 6,
            c.y + 4,
            c.w - 12,
            c.h * 0.3,
            6,6
        )
    end
end

return Cube