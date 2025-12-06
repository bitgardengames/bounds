--------------------------------------------------------------
-- LASER EMITTER — Stateful game object for Bounds
-- • Sci-fi housing with pillowy metal edges
-- • Directional barrel geometry (up/down/left/right)
-- • Beam with glow + line core
-- • Automatic raycast against Level.isSolidAt
--------------------------------------------------------------

local Level = require("level.level")
local Theme = require("theme")
local LaserReceiver = require("objects.laserreceiver")

local LaserEmitter = { list = {} }

--------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------
local TILE = 48
local OUTLINE = 4

local S = Theme.decorations

local BEAM_WIDTH = 4
local BEAM_COLOR = {1, 0.28, 0.28, 1}
local BEAM_GLOW  = {1, 0.15, 0.15, 0.25}

--------------------------------------------------------------
-- RAYCAST (pixel-based)
--------------------------------------------------------------
local function receiverMatchesDirection(receiver, dx, dy)
    if dx > 0 then return receiver.dir == "left" end
    if dx < 0 then return receiver.dir == "right" end
    if dy > 0 then return receiver.dir == "up" end
    if dy < 0 then return receiver.dir == "down" end
    return false
end

local function raycast(x, y, dx, dy)
    local step = 4
    local maxDist = 2500
    local dist = 0

    local px, py = x, y

    while dist < maxDist do
        px = x + dx * dist
        py = y + dy * dist

        -- stop when hitting a receiver face in the beam's path
        for _, receiver in ipairs(LaserReceiver.list) do
            if receiverMatchesDirection(receiver, dx, dy)
                and LaserReceiver.hitTest(receiver, px, py) then
                return px, py, true
            end
        end

        -- use Bounds' collision API
        if Level.isSolidAt(px, py) then
            return px, py, true
        end

        dist = dist + step
    end

    return px, py, false
end

--------------------------------------------------------------
-- INTERNAL DRAW HELPERS
--------------------------------------------------------------

local function drawEmitterBody(inst)
    local x, y = inst.x, inst.y
    local w, h = inst.w, inst.h

    ----------------------------------------------------------
    -- BACKPLATE (soft rounded rectangular frame)
    ----------------------------------------------------------
    love.graphics.setColor(S.outline)
    love.graphics.rectangle("fill", x+2, y+2, w-4, h-4, 6, 6)

    love.graphics.setColor(S.metal)
    love.graphics.rectangle("fill", x+6, y+6, w-12, h-12, 5, 5)

    ----------------------------------------------------------
    -- INNER CAVITY
    ----------------------------------------------------------
    local cavW = w - 28
    local cavH = h - 30
    local cavX = x + (w - cavW)/2
    local cavY = y + (h - cavH)/2

    love.graphics.setColor(S.dark)
    love.graphics.rectangle("fill", cavX, cavY, cavW, cavH, 4, 4)

    -- cavity rods
    love.graphics.setColor(S.outline)
    love.graphics.rectangle("fill", cavX + 4,     cavY + 2,       cavW - 8, 2, 1, 1)
    love.graphics.rectangle("fill", cavX + 4, cavY + cavH - 4, cavW - 8, 2, 1, 1)

    ----------------------------------------------------------
    -- BARREL (directional)
    ----------------------------------------------------------
    local dir = inst.dir

    local barrelW = 18
    local barrelH = 12
    local bx, by

    if dir == "right" then
        bx = x + w - barrelW - 4
        by = y + h/2 - barrelH/2
    elseif dir == "left" then
        bx = x + 4
        by = y + h/2 - barrelH/2
    elseif dir == "up" then
        bx = x + w/2 - barrelH/2
        by = y + 4
    elseif dir == "down" then
        bx = x + w/2 - barrelH/2
        by = y + h - barrelH - 4
    end

    -- Outline box
    love.graphics.setColor(S.outline)
    love.graphics.rectangle("fill",
        bx - 3, by - 3,
        barrelW + 6,
        barrelH + 6,
        3, 3
    )

    -- Fill
    love.graphics.setColor(S.metal)
    love.graphics.rectangle("fill",
        bx, by,
        barrelW,
        barrelH,
        3, 3
    )

    -- vents
    love.graphics.setColor(S.dark)
    love.graphics.rectangle("fill", bx+3, by+3, barrelW-12, 2, 2, 2)
    love.graphics.rectangle("fill", bx+3, by+7, barrelW-12, 2, 2, 2)

    ----------------------------------------------------------
    -- LENS + DIODE
    ----------------------------------------------------------
    local cx, cy

    if dir == "right" then
        cx = bx + barrelW - 2
        cy = by + barrelH/2
    elseif dir == "left" then
        cx = bx + 2
        cy = by + barrelH/2
    elseif dir == "up" then
        cx = bx + barrelW/2
        cy = by + 2
    elseif dir == "down" then
        cx = bx + barrelW/2
        cy = by + barrelH - 2
    end

    -- glow soft halo
    love.graphics.setColor(1, 0.1, 0.1, 0.22)
    love.graphics.circle("fill", cx, cy, 10)

    -- outer dark lens ring
    love.graphics.setColor(S.dark)
    love.graphics.circle("fill", cx, cy, 6)

    -- diode core
    love.graphics.setColor(1, 0.32, 0.32, 1)
    love.graphics.circle("fill", cx, cy, 4)

    -- highlight
    love.graphics.setColor(1, 0.6, 0.6, 1)
    love.graphics.circle("fill", cx+1.5, cy-1.5, 1.3)
end

--------------------------------------------------------------
-- SPAWN
--------------------------------------------------------------
function LaserEmitter.spawn(tx, ty, dir)
    TILE = Level.tileSize or TILE
    local px = tx * TILE
    local py = ty * TILE

    local inst = {
        x = px,
        y = py,
        w = TILE,
        h = TILE,
        dir = dir or "right",

        active = true,
        hitX = px,
        hitY = py,
    }

    table.insert(LaserEmitter.list, inst)
    return inst
end

--------------------------------------------------------------
-- UPDATE
--------------------------------------------------------------
function LaserEmitter.update(dt)
    for _, inst in ipairs(LaserEmitter.list) do
        if not inst.active then
            goto continue
        end

        local dx, dy = 1, 0
        if inst.dir == "left"  then dx, dy = -1,  0 end
        if inst.dir == "up"    then dx, dy =  0, -1 end
        if inst.dir == "down"  then dx, dy =  0,  1 end

        ------------------------------------------------------
        -- beam origin based on direction
        ------------------------------------------------------
        local ox, oy

        if inst.dir == "right" then
            ox = inst.x + inst.w - 6
            oy = inst.y + inst.h/2
        elseif inst.dir == "left" then
            ox = inst.x + 6
            oy = inst.y + inst.h/2
        elseif inst.dir == "up" then
            ox = inst.x + inst.w/2
            oy = inst.y + 6
        elseif inst.dir == "down" then
            ox = inst.x + inst.w/2
            oy = inst.y + inst.h - 6
        end

        inst.hitX, inst.hitY = raycast(ox, oy, dx, dy)

        ::continue::
    end
end

--------------------------------------------------------------
-- DRAW
--------------------------------------------------------------
function LaserEmitter.draw()
    for _, inst in ipairs(LaserEmitter.list) do
        if inst.active then
            --------------------------------------------------
            -- BEAM FIRST (under emitter body)
            --------------------------------------------------
            love.graphics.setColor(BEAM_GLOW)
            love.graphics.setLineWidth(BEAM_WIDTH * 3)
            love.graphics.line(
                inst.hitX, inst.hitY,
                inst.hitX - (inst.hitX - inst.x), -- dummy reversed line
                inst.hitY
            )

            -- But fix: real proper beam start
            local sx, sy
            if inst.dir == "right" then
                sx = inst.x + inst.w - 6
                sy = inst.y + inst.h/2
            elseif inst.dir == "left" then
                sx = inst.x + 6
                sy = inst.y + inst.h/2
            elseif inst.dir == "up" then
                sx = inst.x + inst.w/2
                sy = inst.y + 6
            elseif inst.dir == "down" then
                sx = inst.x + inst.w/2
                sy = inst.y + inst.h - 6
            end

            -- glow
            love.graphics.setColor(BEAM_GLOW)
            love.graphics.setLineWidth(BEAM_WIDTH * 3)
            love.graphics.line(sx, sy, inst.hitX, inst.hitY)

            -- core
            love.graphics.setColor(BEAM_COLOR)
            love.graphics.setLineWidth(BEAM_WIDTH)
            love.graphics.line(sx, sy, inst.hitX, inst.hitY)
        end

        ------------------------------------------------------
        -- BODY OVERLAY
        ------------------------------------------------------
        drawEmitterBody(inst)
    end
end

--------------------------------------------------------------
-- CLEAR
--------------------------------------------------------------
function LaserEmitter.clear()
    for i = #LaserEmitter.list, 1, -1 do
        LaserEmitter.list[i] = nil
    end
end

return LaserEmitter
