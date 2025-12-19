--------------------------------------------------------------
-- LASER EMITTER — Stateful power-emitting system
-- • .active = powered on/off (single source of truth)
-- • Barrel physically extends when active
-- • Emits beam only when active
-- • Beam blocks on cubes, consumes on receivers
-- • Emits connection / disconnection events
--------------------------------------------------------------

local Level         = require("level.level")
local Theme         = require("theme")
local LaserReceiver = require("objects.laserreceiver")
local Cube          = require("objects.cube")
local Events        = require("systems.events")

local LaserEmitter = { list = {} }

--------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------
local TILE    = 48
local OUTLINE = 4

local S = Theme.decorations

local BEAM_WIDTH = 4
local BEAM_COLOR = {1, 0.28, 0.28, 1}
local BEAM_GLOW  = {1, 0.15, 0.15, 0.25}

local BARREL_EXTEND_PX = 6
local EXTEND_SPEED    = 8

--------------------------------------------------------------
-- RAYCAST HELPERS
--------------------------------------------------------------
local function cubeHitTest(cube, px, py)
    return px >= cube.x
       and px <= cube.x + cube.w
       and py >= cube.y
       and py <= cube.y + cube.h
end

local function receiverMatchesDirection(receiver, dx, dy)
    if dx > 0 then return receiver.dir == "right" end
    if dx < 0 then return receiver.dir == "left" end
    if dy > 0 then return receiver.dir == "down" end
    if dy < 0 then return receiver.dir == "up" end
    return false
end

--------------------------------------------------------------
-- RAYCAST
--------------------------------------------------------------
local function raycast(x, y, dx, dy)
    local step    = 4
    local maxDist = 2500
    local dist    = 0

    local px, py = x, y

    while dist < maxDist do
        px = x + dx * dist
        py = y + dy * dist

        for _, cube in ipairs(Cube.list) do
            if cubeHitTest(cube, px, py) then
                local hitX, hitY = px, py

                if dx > 0 then hitX = cube.x
                elseif dx < 0 then hitX = cube.x + cube.w
                elseif dy > 0 then hitY = cube.y
                elseif dy < 0 then hitY = cube.y + cube.h end

                return hitX, hitY, "cube"
            end
        end

        for _, receiver in ipairs(LaserReceiver.list) do
            if receiverMatchesDirection(receiver, dx, dy)
               and LaserReceiver.hitTest(receiver, px, py) then
                return receiver.x + receiver.w * 0.5,
                       receiver.y + receiver.h * 0.5,
                       "receiver",
                       receiver.id
            end
        end

        if Level.isSolidAt(px, py) then
            return px, py, "solid"
        end

        dist = dist + step
    end

    return px, py, nil
end

--------------------------------------------------------------
-- BEAM ORIGIN
--------------------------------------------------------------
local function getBeamOrigin(inst)
    if inst.dir == "right" then
        return inst.x + inst.w - 6, inst.y + inst.h * 0.5
    elseif inst.dir == "left" then
        return inst.x + 6, inst.y + inst.h * 0.5
    elseif inst.dir == "up" then
        return inst.x + inst.w * 0.5, inst.y + 6
    elseif inst.dir == "down" then
        return inst.x + inst.w * 0.5, inst.y + inst.h - 6
    end
end

--------------------------------------------------------------
-- SPAWN
--------------------------------------------------------------
function LaserEmitter.spawn(tx, ty, dir, id, opts)
    opts = opts or {}

    TILE = Level.tileSize or TILE
    local px = tx * TILE
    local py = ty * TILE

    local inst = {
        x = px, y = py,
        w = TILE, h = TILE,
		id = id or "emitter_" .. (#LaserEmitter.list + 1),
        dir = dir or "right",

        active   = opts.active ~= false,
        lastHit  = nil,

        extendT     = (opts.active ~= false) and 1 or 0,
        extendSpeed = EXTEND_SPEED,

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
        local target = inst.active and 1 or 0
        inst.extendT = inst.extendT + (target - inst.extendT) * dt * inst.extendSpeed

        if not inst.active then
            if inst.lastHit then
                Events.emit("laser_disconnected", {
                    receiver = inst.lastHit,
                    emitter  = inst.id
                })
            end
            inst.lastHit = nil
            goto continue
        end

        local dx, dy = 1, 0
        if inst.dir == "left"  then dx = -1 end
        if inst.dir == "up"    then dy = -1; dx = 0 end
        if inst.dir == "down"  then dy =  1; dx = 0 end

        local ox, oy = getBeamOrigin(inst)
        inst.hitX, inst.hitY, inst.hitKind, inst.hitReceiverId =
            raycast(ox, oy, dx, dy)

        local prevHit = inst.lastHit
        inst.lastHit = (inst.hitKind == "receiver") and inst.hitReceiverId or nil

        if prevHit ~= inst.lastHit then
            if prevHit then
                Events.emit("laser_disconnected", {
                    receiver = prevHit,
                    emitter  = inst.id
                })
            end
            if inst.lastHit then
                Events.emit("laser_connected", {
                    receiver = inst.lastHit,
                    emitter  = inst.id
                })
            end
        end

        ::continue::
    end
end

--------------------------------------------------------------
-- DRAW: EMITTER BODY ONLY
--------------------------------------------------------------
local function drawEmitterBody(inst)
    local x, y, w, h = inst.x, inst.y, inst.w, inst.h

    ----------------------------------------------------------
    -- BACKPLATE
    ----------------------------------------------------------
    love.graphics.setColor(S.outline)
    love.graphics.rectangle("fill", x+2, y+2, w-4, h-4, 6, 6)

    love.graphics.setColor(S.metal)
    love.graphics.rectangle("fill", x+6, y+6, w-12, h-12, 5, 5)

    ----------------------------------------------------------
    -- CAVITY
    ----------------------------------------------------------
    local cavW, cavH = w - 28, h - 30
    local cavX = x + (w - cavW) / 2
    local cavY = y + (h - cavH) / 2

    love.graphics.setColor(S.dark)
    love.graphics.rectangle("fill", cavX, cavY, cavW, cavH, 4, 4)

    ----------------------------------------------------------
    -- BARREL (CENTERED IDLE → EXTENDS OUTWARD)
    ----------------------------------------------------------
    local baseLen = 10
    local extend  = BARREL_EXTEND_PX * inst.extendT
    local barrelLen = baseLen + extend
    local barrelThick = 12

    local bx, by, bw, bh

    if inst.dir == "right" then
        bw = barrelLen
        bh = barrelThick

        -- anchor barrel INSIDE housing
        local baseX = x + w * 0.5
        bx = baseX
        by = y + h/2 - bh/2

    elseif inst.dir == "left" then
        bw = barrelLen
        bh = barrelThick

        local baseX = x + w * 0.5
        bx = baseX - bw
        by = y + h/2 - bh/2

    elseif inst.dir == "up" then
        bw = barrelThick
        bh = barrelLen

        local baseY = y + h * 0.5
        bx = x + w/2 - bw/2
        by = baseY - bh

    elseif inst.dir == "down" then
        bw = barrelThick
        bh = barrelLen

        local baseY = y + h * 0.5
        bx = x + w/2 - bw/2
        by = baseY
    end

    love.graphics.setColor(S.outline)
    love.graphics.rectangle("fill", bx-3, by-3, bw+6, bh+6, 3, 3)

    love.graphics.setColor(S.metal)
    love.graphics.rectangle("fill", bx, by, bw, bh, 3, 3)

	----------------------------------------------------------
	-- LENS
	----------------------------------------------------------
	local t = inst.extendT
	local cx, cy

	if inst.dir == "right" then
		cx = bx + bw
		cy = by + bh * 0.5
	elseif inst.dir == "left" then
		cx = bx
		cy = by + bh * 0.5
	elseif inst.dir == "up" then
		cx = bx + bw * 0.5
		cy = by
	elseif inst.dir == "down" then
		cx = bx + bw * 0.5
		cy = by + bh
	end

	if t < 0.05 then
		-- inactive: black aperture, same size as lens opening
		love.graphics.setColor(0, 0, 0, 0.85)
		love.graphics.circle("fill", cx, cy, 6)
	else
		love.graphics.setColor(1, 0.1, 0.1, 0.22 * t)
		love.graphics.circle("fill", cx, cy, 10)

		love.graphics.setColor(S.dark)
		love.graphics.circle("fill", cx, cy, 6)

		love.graphics.setColor(1, 0.32, 0.32, t)
		love.graphics.circle("fill", cx, cy, 4)
	end
end

--------------------------------------------------------------
-- DRAW PUBLIC
--------------------------------------------------------------
function LaserEmitter.drawBodies()
    for _, inst in ipairs(LaserEmitter.list) do
        drawEmitterBody(inst)
    end
end

function LaserEmitter.drawBeams()
    for _, inst in ipairs(LaserEmitter.list) do
        if inst.active then
            local sx, sy = getBeamOrigin(inst)

            love.graphics.setColor(BEAM_GLOW)
            love.graphics.setLineWidth(BEAM_WIDTH * 3)
            love.graphics.line(sx, sy, inst.hitX, inst.hitY)

            love.graphics.setColor(BEAM_COLOR)
            love.graphics.setLineWidth(BEAM_WIDTH)
            love.graphics.line(sx, sy, inst.hitX, inst.hitY)
        end
    end
end

--------------------------------------------------------------
-- CLEAR
--------------------------------------------------------------
function LaserEmitter.clear()
    LaserEmitter.list = {}
end

return LaserEmitter