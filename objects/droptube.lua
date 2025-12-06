--------------------------------------------------------------
-- DROP TUBE — Ceiling-mounted pipe inspired by classic warp tubes
--------------------------------------------------------------

local Theme = require("theme")

local DropTube = {
    list     = {},
    tileSize = 48,
}

--------------------------------------------------------------
-- SPAWN / CLEAR
--------------------------------------------------------------

local function newInstance(tx, ty, opts)
    opts = opts or {}
    local tile = DropTube.tileSize
    local segments = math.max(1, opts.segments or opts.length or 2)

    return {
        id     = tostring(opts.id or string.format("droptube_%d", #DropTube.list + 1)),
        x      = tx * tile,
        y      = ty * tile,
        w      = tile,
        h      = segments * tile,
        t      = love.math.random() * 10,
        active = true,
    }
end

function DropTube.spawn(tx, ty, opts)
    local inst = newInstance(tx, ty, opts)
    table.insert(DropTube.list, inst)
end

function DropTube.clear()
    DropTube.list = {}
end

--------------------------------------------------------------
-- UPDATE
--------------------------------------------------------------

function DropTube.update(dt)
    for _, tube in ipairs(DropTube.list) do
        tube.t = tube.t + dt
    end
end

--------------------------------------------------------------
-- DRAW HELPERS
--------------------------------------------------------------

local OUTLINE = 4
local S = Theme.decorations
local OUTLINE_COLOR = Theme.outline

local function drawBody(tube, offsetY)
    local tile = DropTube.tileSize
    local tubeW = tile * 0.72
    local lipH = math.max(tile * 0.32, math.min(tile * 0.48, tube.h * 0.45))
    local bodyH = math.max(tile * 0.6, tube.h - lipH)

    local x = tube.x
    local y = tube.y + offsetY

    local bodyX = x + (tile - tubeW) * 0.5
    local bodyY = y

    love.graphics.setColor(OUTLINE_COLOR)
    love.graphics.rectangle("fill", bodyX - OUTLINE, bodyY, tubeW + OUTLINE * 2, bodyH, 10, 10)

    love.graphics.setColor(S.pipe)
    love.graphics.rectangle("fill", bodyX, bodyY + 2, tubeW, bodyH - 2, 8, 8)

    -- darker banding
    love.graphics.setColor(S.dark)
    love.graphics.rectangle("fill", bodyX + 6, bodyY + bodyH * 0.25, tubeW - 12, 6, 3, 3)
    love.graphics.rectangle("fill", bodyX + 6, bodyY + bodyH * 0.60, tubeW - 12, 6, 3, 3)

    -- highlight stripe
    love.graphics.setColor(1, 1, 1, 0.12)
    love.graphics.rectangle("fill", bodyX + 6, bodyY + 10, 6, bodyH - 20, 3, 3)

    return lipH, bodyX, bodyY + bodyH, tubeW
end

local function drawLip(tube, lipH, bodyX, lipTopY, bodyW)
    local tile = DropTube.tileSize
    local lipW = math.min(tile * 1.25, bodyW + tile * 0.32)
    local lipX = tube.x + (tile - lipW) * 0.5

    love.graphics.setColor(OUTLINE_COLOR)
    love.graphics.rectangle("fill", lipX - OUTLINE, lipTopY, lipW + OUTLINE * 2, lipH + OUTLINE, 12, 12)

    love.graphics.setColor(S.pipe)
    love.graphics.rectangle("fill", lipX, lipTopY + 2, lipW, lipH, 10, 10)

    -- lip shading
    love.graphics.setColor(S.dark)
    love.graphics.rectangle("fill", lipX + 4, lipTopY + lipH * 0.35, lipW - 8, lipH * 0.25, 6, 6)

    -- inner cavity
    local gap = 10
    love.graphics.setColor(0, 0, 0, 0.82)
    love.graphics.rectangle("fill", lipX + gap, lipTopY + lipH - 16, lipW - gap * 2, 12, 6, 6)
end

local function drawCeilingMount(tube, offsetY)
    local tile = DropTube.tileSize
    local mountW = tile * 0.5
    local mountH = tile * 0.16
    local mountX = tube.x + (tile - mountW) * 0.5
    local mountY = tube.y + offsetY - mountH

    love.graphics.setColor(OUTLINE_COLOR)
    love.graphics.rectangle("fill", mountX - OUTLINE, mountY - 1, mountW + OUTLINE * 2, mountH + OUTLINE, 6, 6)

    love.graphics.setColor(S.pipe)
    love.graphics.rectangle("fill", mountX, mountY + 1, mountW, mountH - 2, 4, 4)
end

--------------------------------------------------------------
-- DRAW
--------------------------------------------------------------

function DropTube.draw()
    for _, tube in ipairs(DropTube.list) do
        if tube.active then
            local wobble = math.sin(tube.t * 1.25) * 1.5

            local lipH, bodyX, lipTopY, bodyW = drawBody(tube, wobble)
            drawLip(tube, lipH, bodyX, lipTopY, bodyW)
            drawCeilingMount(tube, wobble)
        end
    end
end

return DropTube
