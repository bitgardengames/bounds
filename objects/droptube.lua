--------------------------------------------------------------
-- DROP TUBE — Clean lab-style rounded-top + bottom glass tube
-- Rebuilt from scratch to match Bounds' new visual direction.
--------------------------------------------------------------

local Theme = require("theme")

local DropTube = {
    list     = {},
    tileSize = 48,
}

--------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------
local OUTLINE      = 4
local CAP_HEIGHT   = 16
local RADIUS_CAP   = 6

-- Colors
local COLOR_TOP_CAP     = Theme.droptube.topcap
local COLOR_BOTTOM_CAP  = Theme.droptube.bottomcap
local COLOR_BOTTOM  = Theme.outline
local COLOR_GLASS   = Theme.droptube.glass
local COLOR_HL      = Theme.droptube.highlight
local OUTLINE_COLOR = Theme.outline or {0,0,0,1}

--------------------------------------------------------------
-- SPAWN / CLEAR
--------------------------------------------------------------
local function newInstance(tx, ty, opts)
    opts = opts or {}
    local tile = DropTube.tileSize

    return {
        id     = tostring(opts.id or string.format("droptube_%d", #DropTube.list + 1)),
        x      = tx * tile,
        y      = ty * tile,
        w      = tile,
        h      = tile * 2,
        t      = love.math.random() * 10,
        active = true,
    }
end

function DropTube.spawn(tx, ty, opts)
    local inst = newInstance(tx, ty, opts)
    table.insert(DropTube.list, inst)
end

function DropTube.dropPlayer(tube)
    -- tube.x, tube.y is the TOP of tube
    -- drop location = just below bottom cap
    local dropX = tube.x + tube.w/2 - 18   -- center player horizontally
    local dropY = tube.y

    local Player = require("player.player")
    Player.beginDrop(dropX, dropY)
end

function DropTube.clear()
    DropTube.list = {}
end

--------------------------------------------------------------
-- UPDATE — tiny idle wobble
--------------------------------------------------------------
function DropTube.update(dt)
    for _, tube in ipairs(DropTube.list) do
        tube.t = tube.t + dt
    end
end

--------------------------------------------------------------
-- HELPER: Outlined rounded rectangle
--------------------------------------------------------------
local function drawOutlinedRoundedRect(mode, x, y, w, h, rx, ry)
    -- OUTLINE
    love.graphics.setColor(OUTLINE_COLOR)
    love.graphics.rectangle("fill",
        x - OUTLINE,
        y - OUTLINE,
        w + OUTLINE * 2,
        h + OUTLINE * 2,
        rx, ry
    )

    -- FILL
    love.graphics.setColor(mode.color)
    love.graphics.rectangle("fill",
        x,
        y,
        w,
        h,
        rx, ry
    )
end

--------------------------------------------------------------
-- DRAW
--------------------------------------------------------------
function DropTube.draw()
    for _, tube in ipairs(DropTube.list) do
        if tube.active then
            local x  = tube.x
            local y  = tube.y
            local w  = tube.w
            local h  = tube.h

            --------------------------------------------------
            -- TOP CAP (rounded rectangle)
            --------------------------------------------------
            drawOutlinedRoundedRect(
                {color = COLOR_TOP_CAP},
                x,
                y + 2,
                w,
                CAP_HEIGHT,
                RADIUS_CAP,
                RADIUS_CAP
            )

            --------------------------------------------------
            -- GLASS BODY
            --------------------------------------------------
            local bodyY = y + CAP_HEIGHT + 2
            local bodyH = h - CAP_HEIGHT * 2  -- reduce to make space for bottom cap

            -- Glass fill (inset)
            love.graphics.setColor(COLOR_GLASS)
            love.graphics.rectangle("fill",
                x + 4,
                bodyY + 4,
                w - 8,
                bodyH
            )

            --------------------------------------------------
            -- SIDE OUTLINES (no radius, pure 4px lines)
            --------------------------------------------------
            love.graphics.setColor(OUTLINE_COLOR)

            -- left
            love.graphics.rectangle("fill",
                x,
                bodyY,
                4,
                bodyH
            )

            -- right
            love.graphics.rectangle("fill",
                x + w - 4,
                bodyY,
                4,
                bodyH
            )

            --------------------------------------------------
            -- GLASS HIGHLIGHT
            --------------------------------------------------
            love.graphics.setColor(COLOR_HL)
            love.graphics.rectangle(
                "fill",
                x + w * 0.15,
                bodyY + 6,
                w * 0.12,
                bodyH - 12,
                4, 4
            )

            --------------------------------------------------
            -- NEW: BOTTOM CAP (mirrors top cap)
            --------------------------------------------------
            local bottomY = y + h - CAP_HEIGHT

            drawOutlinedRoundedRect(
                {color = COLOR_BOTTOM_CAP},
                x,
                bottomY,
                w,
                CAP_HEIGHT,
                RADIUS_CAP,
                RADIUS_CAP
            )
        end
    end
end

return DropTube