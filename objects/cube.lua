--------------------------------------------------------------
-- CUBE MODULE — Pushable Weighted Puzzle Cube
--------------------------------------------------------------

local Level          = require("level.level")
local Theme          = require("theme")
local MovingPlatform = require("objects.movingplatform")
local Liquids        = require("systems.liquids")
local DropTube       = require("objects.droptube")
local Particles      = require("systems.particles")
local Events         = require("systems.events")

local Cube = { list = {} }

--------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------

local CUBE_SIZE      = 32
local GRAVITY        = 1800
local MAX_FALL_SPEED = 900

local PUSH_ACCEL     = 900
local MAX_PUSH_SPEED = 160
local FRICTION       = 3.2
local PUSH_FRICTION_SCALE = 0.06

local FOOT_INSET        = 2
local PLATFORM_MARGIN   = 1.6
local PLATFORM_SINK     = 1
local REST_FOOT_OFFSET  = -2

local LANDING_DAMP_VX = 0.35
local LANDING_MIN_VY  = 40

--------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------

local function sign(x)
    if x > 0 then return 1 end
    if x < 0 then return -1 end
    return 0
end

--------------------------------------------------------------
-- SPAWN / CLEAR
--------------------------------------------------------------

function Cube.spawn(x, y, opts)
    opts = opts or {}

    table.insert(Cube.list, {
        id = tostring(opts.id or ("cube_" .. (#Cube.list + 1))),
        x = x, y = y,
        w = CUBE_SIZE, h = CUBE_SIZE,

        vx = 0, vy = 0,

        grounded = false,
        groundedPlatform = nil,

        arriving = false,
        arrivalTimer = 0,
        arrivalDelay = 0.25,

        prevY = y,
    })
end

function Cube.clear()
    Cube.list = {}
end

--------------------------------------------------------------
-- TILE COLLISION
--------------------------------------------------------------

local function tileAtPixel(px, py, TILE, grid, w, h)
    local tx = math.floor(px / TILE) + 1
    local ty = math.floor(py / TILE) + 1
    if tx < 1 or ty < 1 or tx > w or ty > h then return false end
    local row = grid and grid[ty]
    return row and row[tx] == true
end

local function resolveTileCollision(c, TILE, grid, w, h)
    c.grounded = false -- do NOT clear groundedPlatform here

    -- Vertical
    if c.vy > 0 then
        local footY = c.y + c.h - REST_FOOT_OFFSET
        if tileAtPixel(c.x + FOOT_INSET, footY + 1, TILE, grid, w, h)
        or tileAtPixel(c.x + c.w - FOOT_INSET, footY + 1, TILE, grid, w, h) then
            c.vy = 0
            c.grounded = true
            c.groundedPlatform = nil
            c.y = math.floor(footY / TILE) * TILE - c.h + REST_FOOT_OFFSET
        end
    elseif c.vy < 0 then
        local headY = c.y
        if tileAtPixel(c.x + FOOT_INSET, headY, TILE, grid, w, h)
        or tileAtPixel(c.x + c.w - FOOT_INSET, headY, TILE, grid, w, h) then
            c.vy = 0
            c.y = math.floor(headY / TILE + 1) * TILE
        end
    end

    -- Support probe
    if not c.grounded and c.vy == 0 then
        local footY = c.y + c.h - REST_FOOT_OFFSET
        if tileAtPixel(c.x + FOOT_INSET, footY + 1, TILE, grid, w, h)
        or tileAtPixel(c.x + c.w - FOOT_INSET, footY + 1, TILE, grid, w, h) then
            c.grounded = true
            c.groundedPlatform = nil
        end
    end

    -- Horizontal
    if c.vx > 0 then
        local rx = c.x + c.w
        if tileAtPixel(rx + 1, c.y + FOOT_INSET, TILE, grid, w, h)
        or tileAtPixel(rx + 1, c.y + c.h - FOOT_INSET, TILE, grid, w, h) then
            c.vx = 0
            c.x = math.floor(rx / TILE) * TILE - c.w
        end
    elseif c.vx < 0 then
        local lx = c.x
        if tileAtPixel(lx, c.y + FOOT_INSET, TILE, grid, w, h)
        or tileAtPixel(lx, c.y + c.h - FOOT_INSET, TILE, grid, w, h) then
            c.vx = 0
            c.x = math.floor(lx / TILE + 1) * TILE
        end
    end
end

--------------------------------------------------------------
-- PLATFORM COLLISION (ROBUST & CONTINUOUS)
--------------------------------------------------------------

local function resolvePlatformCollision(c)
    for _, p in ipairs(MovingPlatform.list) do
        local cx1, cx2 = c.x, c.x + c.w
        local px1, px2 = p.x, p.x + p.w
        local overlapX = math.min(cx2, px2) - math.max(cx1, px1)
        if overlapX <= 0 then goto next end

        local topY  = p.y - 6
        local footY = c.y + c.h - REST_FOOT_OFFSET
        local gap   = topY - footY

        local supported =
            (gap >= -PLATFORM_MARGIN and gap <= PLATFORM_MARGIN + 2)
            or c.groundedPlatform == p

        if supported then
            c.y = topY - c.h + PLATFORM_SINK + REST_FOOT_OFFSET
            c.vy = p.vy or 0
            c.grounded = true
            c.groundedPlatform = p
            return
        end

        ::next::
    end
end

--------------------------------------------------------------
-- FRICTION
--------------------------------------------------------------

local function applyFriction(c, dt, beingPushed)
    if not c.grounded then return end
    if math.abs(c.vx) < 1 then c.vx = 0 return end

    local force = FRICTION * 1200
    if beingPushed then
        force = force * PUSH_FRICTION_SCALE
    end

    local dv = force * dt
    if dv >= math.abs(c.vx) then
        c.vx = 0
    else
        c.vx = c.vx - sign(c.vx) * dv
    end
end

--------------------------------------------------------------
-- WATER CHECK
--------------------------------------------------------------

local function isFullySubmerged(c)
    local cx = c.x + c.w * 0.5
    return Liquids.isPointInWater(cx, c.y + 2)
       and Liquids.isPointInWater(cx, c.y + c.h - 2)
end

--------------------------------------------------------------
-- UPDATE
--------------------------------------------------------------

function Cube.update(dt, player)
    local TILE   = Level.tileSize or 48
    local grid   = Level.solidGrid
    local width  = Level.width or 0
    local height = Level.height or 0

    for _, c in ipairs(Cube.list) do
        c.prevY = c.y
        local wasGrounded = c.grounded

        --------------------------------------------------
        -- ARRIVAL
        --------------------------------------------------
        if c.arriving then
            c.arrivalTimer = c.arrivalTimer + dt
            if c.arrivalTimer < c.arrivalDelay then
                goto continue
            end
            c.arriving = false
        end

        --------------------------------------------------
        -- Gravity
        --------------------------------------------------
        if not c.grounded then
            c.vy = math.min(c.vy + GRAVITY * dt, MAX_FALL_SPEED)
        end

        --------------------------------------------------
        -- Pushing
        --------------------------------------------------
        local beingPushed =
            player
            and player.pushingCube
            and player.pushingCubeRef == c
            and player.onGround

        if beingPushed then
            c.vx = c.vx + player.pushingCubeDir * PUSH_ACCEL * dt
            c.vx = math.max(-MAX_PUSH_SPEED, math.min(MAX_PUSH_SPEED, c.vx))
        end

        applyFriction(c, dt, beingPushed)

        --------------------------------------------------
        -- Integrate
        --------------------------------------------------
        c.x = c.x + c.vx * dt
        c.y = c.y + c.vy * dt

        --------------------------------------------------
        -- Collisions
        --------------------------------------------------
        resolveTileCollision(c, TILE, grid, width, height)
        resolvePlatformCollision(c)

        if not c.grounded then
            c.groundedPlatform = nil
        end

        if c.grounded and c.groundedPlatform then
            c.x = c.x + (c.groundedPlatform.dx or 0)
        end

        --------------------------------------------------
        -- Landing damping
        --------------------------------------------------
        if not wasGrounded and c.grounded then
            if math.abs(c.vy) < LANDING_MIN_VY then
                c.vy = 0
            end
            c.vx = c.vx * LANDING_DAMP_VX
        end

        --------------------------------------------------
        -- WATER → DROPTUBE
        --------------------------------------------------
        if isFullySubmerged(c) then
            Events.emit("cube_drowned", { id = c.id, x = c.x, y = c.y })

            for i = 1, 8 do
                Particles.puff(
                    c.x + c.w/2 + math.random(-8,8),
                    c.y + c.h/2 + math.random(-6,6),
                    (math.random()-0.5)*60,
                    -40 - math.random()*40,
                    4.5, 0.45,
                    {0.7, 0.9, 1.0, 0.9}
                )
            end

            local tube = DropTube.list[1]
            if tube then
                DropTube.dropCube(tube, c)
            end
        end

        ::continue::
    end
end

--------------------------------------------------------------
-- DRAW
--------------------------------------------------------------

function Cube.draw()
    for _, c in ipairs(Cube.list) do
        love.graphics.push()
        love.graphics.translate(c.x + c.w/2, c.y + c.h/2)

        love.graphics.setColor(Theme.cube.outline)
        love.graphics.rectangle("fill",
            -c.w/2 - 4, -c.h/2 - 4,
            c.w + 8, c.h + 8,
            6, 6
        )

        love.graphics.setColor(Theme.cube.fill)
        love.graphics.rectangle("fill",
            -c.w/2, -c.h/2,
            c.w, c.h,
            6, 6
        )

        love.graphics.setColor(Theme.cube.outline)
        love.graphics.circle("fill", 0, 0, 8)
        love.graphics.setColor(Theme.cube.centerFill)
        love.graphics.circle("fill", 0, 0, 4)

        love.graphics.pop()
    end
end

return Cube