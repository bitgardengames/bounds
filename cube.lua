--------------------------------------------------------------
-- CUBE MODULE — Pushable Weighted Puzzle Cube
-- Supports multiple cubes, gravity, tile collisions, pushing
--------------------------------------------------------------

local level = require("level")

local Cube = { list = {} }

--------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------

local CUBE_SIZE = 32
local GRAVITY = 1800
local MAX_FALL_SPEED = 900
local PUSH_ACCEL = 2000
local FRICTION = 8
local BOUNCE = 0 -- (keep 0 for now)

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
        weight = 1, -- can be used by plates
    })
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

local function resolveTileCollision(c)
    local x, y, w, h = c.x, c.y, c.w, c.h

    c.grounded = false

    ----------------------------------------------------------
    -- VERTICAL COLLISION
    ----------------------------------------------------------
    if c.vy > 0 then -- falling
        if tileAtPixel(x + 2, y + h) or tileAtPixel(x + w - 2, y + h) then
            c.vy = 0
            c.grounded = true
            c.y = math.floor((y + h) / level.tileSize) * level.tileSize - h
        end
    elseif c.vy < 0 then -- upward
        if tileAtPixel(x + 2, y) or tileAtPixel(x + w - 2, y) then
            c.vy = 0
            c.y = math.floor(y / level.tileSize + 1) * level.tileSize
        end
    end

    ----------------------------------------------------------
    -- HORIZONTAL COLLISION
    ----------------------------------------------------------
    if c.vx > 0 then
        if tileAtPixel(x + w, y + 2) or tileAtPixel(x + w, y + h - 2) then
            c.vx = 0
            c.x = math.floor((x + w) / level.tileSize) * level.tileSize - w
        end
    elseif c.vx < 0 then
        if tileAtPixel(x, y + 2) or tileAtPixel(x, y + h - 2) then
            c.vx = 0
            c.x = math.floor(x / level.tileSize + 1) * level.tileSize
        end
    end
end

--------------------------------------------------------------
-- PUSH LOGIC (player shoves cube)
--------------------------------------------------------------

local function applyPush(c, player)
    local px, py = player.x, player.y
    local pw, ph = player.w, player.h

    local touching =
        py + ph > c.y and py < c.y + c.h and
        ((px + pw <= c.x and px + pw >= c.x - 6) or
         (px >= c.x + c.w and px <= c.x + c.w + 6))

    if not touching then
        -- cube slows down naturally
        c.vx = c.vx * 0.92
        return
    end

    -- Determine push direction
    if px + pw < c.x then
        -- push right
        c.vx = c.vx + PUSH_ACCEL * love.timer.getDelta()
    elseif px > c.x + c.w then
        -- push left
        c.vx = c.vx - PUSH_ACCEL * love.timer.getDelta()
    end

    -- clamp speed
    if c.vx > 200 then c.vx = 200 end
    if c.vx < -200 then c.vx = -200 end
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
        -- PUSH INTERACTION
        ------------------------------------------------------
        applyPush(c, player)

        ------------------------------------------------------
        -- INTEGRATE MOTION
        ------------------------------------------------------
        c.x = c.x + c.vx * dt
        c.y = c.y + c.vy * dt

        ------------------------------------------------------
        -- COLLISION WITH WORLD
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

        -- subtle highlight
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