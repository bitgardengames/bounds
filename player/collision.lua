local Particles = require("particles")

local Collision = {}

local PLATFORM_OFFSET = 0

local function tileAt(Level, tx, ty)
    local grid = Level.solidGrid
    if not grid then return false end

    if tx < 1 or ty < 1 or tx > Level.width or ty > Level.height then
        return false
    end

    local row = grid[ty]
    return row and row[tx] == true
end

function Collision.tryGroundSnap(p, Level)
    local TILE = Level.tileSize or 48

    if p.vy < 0 or p.onGround then return end

    local epsilon = 2
    local footY   = p.y + p.h
    local below   = math.floor(footY / TILE) + 1

    local lx = math.floor((p.x + 1)       / TILE) + 1
    local rx = math.floor((p.x + p.w - 2) / TILE) + 1

    for tx = lx, rx do
        if tileAt(Level, tx, below) then
            local snapY = (below - 1) * TILE - p.h - PLATFORM_OFFSET
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

function Collision.moveHorizontal(p, Level, amount)
    if amount == 0 then return false end
    local TILE = Level.tileSize or 48
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
                if tileAt(Level, tx, ty) then
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
                if tileAt(Level, tx, ty) then
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

function Collision.moveVertical(p, Level, amount)
    if amount == 0 then return false end
    local TILE = Level.tileSize or 48
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
                if tileAt(Level, tx, ty) then
                    collided = true
                    targetY = (ty - 1) * TILE - p.h - PLATFORM_OFFSET
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
                if tileAt(Level, tx, ty) then
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
                (math.random()*TILE - TILE/2)*1.4,
                35 + math.random()*25,
                4, 0.28,
                {1,1,1,0.9}
            )
        end
    end

    return collided
end

return Collision
