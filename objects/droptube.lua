--------------------------------------------------------------
-- DROP TUBE — Clean lab-style rounded-top + bottom glass tube
-- Rebuilt from scratch to match Bounds' new visual direction.
--------------------------------------------------------------

local Theme = require("theme")
local Player
local Cube
local p

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
    local dropX = tube.x + tube.w/2 - 16   -- center player horizontally
    local dropY = tube.y - tube.w/2

	local Player = require("player.player")
    Player.beginDrop(dropX, dropY)
end

function DropTube.dropCube(tube, cube)
    local dropX = tube.x + tube.w/2 - cube.w/2
    local dropY = tube.y - (DropTube.tileSize * 0.5)

    cube.x = dropX
    cube.y = dropY
    cube.vx = 0
    cube.vy = 0

    cube.arriving = true
    cube.arrivalTimer = 0
    cube.arrivalDelay = 0.25 -- optional animation window
end

function DropTube.clear()
    DropTube.list = {}
end

--------------------------------------------------------------
-- HELPER: Outlined rounded rectangle
--------------------------------------------------------------
local function drawOutlinedRoundedRect(color, x, y, w, h, rx, ry)
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
    love.graphics.setColor(color)
    love.graphics.rectangle("fill",
        x,
        y,
        w,
        h,
        rx, ry
    )
end

--------------------------------------------------------------
-- CENTRALIZED RESPAWN HANDLING
--------------------------------------------------------------
local function handlePlayerRespawn()
    if p.pendingTubeRespawn then
        p.pendingTubeRespawn = false

        -- Force player completely offscreen before drop
        p.x = -9999
        p.y = -9999
        p.vx = 0
        p.vy = 0

        -- Choose spawn tube (first tube for now)
        local tube = DropTube.list[1]
        if tube then
            -- Use same arrival animation as chamber load
            DropTube.dropPlayer(tube)
        end
    end
end

local function handleCubeRespawn()
    for _, c in ipairs(Cube.list) do
        if c.pendingTubeRespawn then
            c.pendingTubeRespawn = false

            c.x = -9999
            c.y = -9999
            c.vx = 0
            c.vy = 0

            local tube = DropTube.list[1]
            if tube then DropTube.dropCube(tube, c) end
        end
    end
end

function DropTube.update(dt)
	if not Player then return end
	handlePlayerRespawn()

    -- CUBES RESPAWN
	if not Cube or #Cube.list == 0 then return end
	handleCubeRespawn()
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
			-- TOP MASK to hide player/cube before drop
			--------------------------------------------------
			local maskH = 48        -- height of the mask strip
			local maskY = y - maskH - 2

			love.graphics.setColor(Theme.level.outer)
			love.graphics.rectangle("fill", x - 4, maskY, w + 8, maskH)

            --------------------------------------------------
            -- TOP CAP (rounded rectangle)
            --------------------------------------------------
            drawOutlinedRoundedRect(
                COLOR_TOP_CAP,
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
                x + 8,
                bodyY + 8,
                6,
                bodyH - 18,
                4, 4
            )

            --------------------------------------------------
            -- NEW: BOTTOM CAP (mirrors top cap)
            --------------------------------------------------
            local bottomY = y + h - CAP_HEIGHT

            drawOutlinedRoundedRect(
                COLOR_BOTTOM_CAP,
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

--------------------------------------------------------------
-- LOAD
--------------------------------------------------------------
function DropTube.load()
	Player = require("player.player")
	Cube = require("objects.cube")
	p = Player.get()
end

return DropTube