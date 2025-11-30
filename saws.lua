--------------------------------------------------------------
-- SAW BLADE HAZARDS — Bounds Version (FINAL)
-- Horizontal + Vertical mounts with perfect wall alignment
--------------------------------------------------------------

local Saw = { list = {} }
local Player = require("player")

--------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------

local BASE_RADIUS = 16
local TEETH       = 9
local INNER_RATIO = 0.80
local SPIN_SPEED  = 6
local MOVE_SPEED  = 60
local OUTLINE     = 3

local TRACK_THICKNESS   = 10
local TRACK_CAP_RADIUS  = TRACK_THICKNESS * 0.5
local TRACK_LENGTH      = 160
local TRAVEL_PADDING    = 18

-- Colors
local COLOR_BACK      = {0, 0, 0}
local COLOR_FILL      = {0, 0, 0}
local COLOR_RIM       = {0, 0, 0}
local COLOR_RIM_LIGHT = {0, 0, 0}

--------------------------------------------------------------
-- SPAWN
--------------------------------------------------------------

function Saw.spawn(x, y, opts)
    opts = opts or {}
    local dir = opts.dir or "horizontal"
    local mount = opts.mount or (dir == "horizontal" and "bottom" or "left")

    table.insert(Saw.list, {
        anchorX = x,
        anchorY = y,

        x = x,
        y = y,

        r        = opts.r     or BASE_RADIUS,
        angle    = opts.angle or 0,
        dir      = dir,
        mount    = mount,
        trackLength = opts.length or TRACK_LENGTH,

        progress  = 0,
        direction = 1,
        speed     = opts.speed or 1,

        sineAmp  = opts.sineAmp  or 0,
        sineFreq = opts.sineFreq or 0,

        t    = 0,
        dead = false,
    })
end

--------------------------------------------------------------
-- COLLISION
--------------------------------------------------------------

local function hitPlayer(s, player)
    local px = player.x + player.w * 0.5
    local py = player.y + player.h * 0.5
    local dx = s.x - px
    local dy = s.y - py
    local dist2 = dx*dx + dy*dy
    local r = s.r + (player.radius or 0)
    return dist2 < r*r
end

--------------------------------------------------------------
-- UPDATE (now includes fixed vertical flush mounts)
--------------------------------------------------------------
function Saw.update(dt, player)
    for i = #Saw.list, 1, -1 do
        local s = Saw.list[i]

        ------------------------------------------------------
        -- Spin animation
        ------------------------------------------------------
        s.t     = s.t + dt
        s.angle = s.angle + SPIN_SPEED * dt

        ------------------------------------------------------
        -- Optional wobble motion
        ------------------------------------------------------
        local wobble = 0
        if s.sineAmp ~= 0 and s.sineFreq ~= 0 then
            wobble = math.sin(s.t * s.sineFreq) * s.sineAmp
        end

        ------------------------------------------------------
        -- Calculate travel bounds
        ------------------------------------------------------
        local travel = (s.trackLength * 0.5) - TRAVEL_PADDING
        if travel < 0 then travel = 0 end

        ------------------------------------------------------
        -- Advance motion along the track
        ------------------------------------------------------
        s.progress = s.progress + MOVE_SPEED * s.speed * dt * s.direction

        if s.progress > travel then
            s.progress  = travel
            s.direction = -1
        elseif s.progress < -travel then
            s.progress  = -travel
            s.direction = 1
        end

        ------------------------------------------------------
        -- POSITIONING (horizontal & vertical symmetric)
        ------------------------------------------------------
        if s.dir == "horizontal" then
            -- Track axis: X changes, Y fixed
            s.x = s.anchorX + s.progress
            s.y = s.anchorY + wobble

        else
            -- Vertical is exactly the rotated version of horizontal
            -- Track axis: Y changes, X fixed
            s.x = s.anchorX
            s.y = s.anchorY + s.progress + wobble
        end

        ------------------------------------------------------
        -- Player collision
        ------------------------------------------------------
        if not player.dead and hitPlayer(s, player) then
            Player.kill()
        end

        ------------------------------------------------------
        -- Removal
        ------------------------------------------------------
        if s.dead then
            table.remove(Saw.list, i)
        end
    end
end

--------------------------------------------------------------
-- SAW TEETH GEOMETRY
--------------------------------------------------------------

local function buildSawPoints(radius, teeth)
    local pts = {}
    local outerR = radius
    local innerR = radius * INNER_RATIO
    local step = (math.pi*2) / teeth

    for i = 0, teeth-1 do
        local aO = i * step
        local aI = aO + step * 0.5

        pts[#pts+1] = math.cos(aO)*outerR
        pts[#pts+1] = math.sin(aO)*outerR

        pts[#pts+1] = math.cos(aI)*innerR
        pts[#pts+1] = math.sin(aI)*innerR
    end

    return pts
end

--------------------------------------------------------------
-- TRACK CAPSULE (now respects WALL_PAD for vertical)
--------------------------------------------------------------

local function getCapsule(s)
    local half = s.trackLength * 0.5

    if s.dir == "horizontal" then
        return s.anchorX - half, s.anchorY - TRACK_THICKNESS * 0.5, s.anchorX + half, s.anchorY + TRACK_THICKNESS * 0.5, true
	else
		return s.anchorX - TRACK_THICKNESS * 0.5, s.anchorY - half, s.anchorX + TRACK_THICKNESS * 0.5, s.anchorY + half, false
	end
end

--------------------------------------------------------------
-- DRAW CAPSULE
--------------------------------------------------------------

local function drawCapsule(x1, y1, x2, y2, horiz, color)
    love.graphics.setColor(color)

    if horiz then
        love.graphics.rectangle(
            "fill",
            x1, y1,
            x2 - x1, TRACK_THICKNESS,
            TRACK_CAP_RADIUS, TRACK_CAP_RADIUS
        )
    else
        -- draw a vertical rounded capsule directly, centered between x1/x2
        love.graphics.rectangle(
            "fill",
            x1, y1,
            TRACK_THICKNESS, y2 - y1,
            TRACK_CAP_RADIUS, TRACK_CAP_RADIUS
        )
    end
end

--------------------------------------------------------------
-- STENCIL — FIXED FOR FLUSH VERTICAL MOUNT
--------------------------------------------------------------

local function stencilHalfRect(s)
    local half  = s.trackLength * 0.5
    local depth = s.r * 1.7

    if s.dir == "horizontal" then
		if s.mount == "top" then
			love.graphics.rectangle(
				"fill",
				s.anchorX - half,
				s.anchorY - depth,    -- extend UP
				s.trackLength,
				depth
			)
		else
			love.graphics.rectangle(
				"fill",
				s.anchorX - half,
				s.anchorY,            -- start at track centerline
				s.trackLength,
				depth
			)
		end
	else
		local half  = s.trackLength * 0.5
		local depth = s.r * 1.7

		if s.mount == "left" then
			-- hide left side from centerline
			love.graphics.rectangle(
				"fill",
				s.anchorX - depth,
				s.anchorY - half,
				depth,
				s.trackLength
			)
		else
			-- hide right side from centerline
			love.graphics.rectangle(
				"fill",
				s.anchorX,
				s.anchorY - half,
				depth,
				s.trackLength
			)
		end
	end
end

--------------------------------------------------------------
-- DRAW
--------------------------------------------------------------

function Saw.draw()
    for _, s in ipairs(Saw.list) do
        local raw = buildSawPoints(s.r, TEETH)
        local rot = {}

        local c = math.cos(s.angle)
        local sn = math.sin(s.angle)

        for i = 1, #raw, 2 do
            local x0 = raw[i]
            local y0 = raw[i+1]
            rot[#rot+1] = x0*c - y0*sn
            rot[#rot+1] = x0*sn + y0*c
        end

        local tris = love.math.triangulate(rot)

        ------------------------------------------------------
        -- TRACK BACK TRENCH
        ------------------------------------------------------
        local x1, y1, x2, y2, horiz = getCapsule(s)
        drawCapsule(x1, y1, x2, y2, horiz, COLOR_BACK)

        ------------------------------------------------------
        -- STENCIL: hide back half
        ------------------------------------------------------
        love.graphics.stencil(function()
            stencilHalfRect(s)
        end, "replace", 1)

        love.graphics.setStencilTest("equal", 0)

        ------------------------------------------------------
        -- BLADE
        ------------------------------------------------------
        love.graphics.push()
        love.graphics.translate(s.x, s.y)

        love.graphics.setColor(0.85, 0.80, 0.75, 1)
        for _, t in ipairs(tris) do
            love.graphics.polygon("fill", t)
        end

        love.graphics.setColor(1,1,1,0.10)
        love.graphics.circle("fill", 0, 0, s.r * 0.55)

        love.graphics.setColor(0,0,0)
        love.graphics.setLineWidth(OUTLINE)
        love.graphics.polygon("line", rot)
        love.graphics.circle("fill", 0, 0, s.r * 0.33)

        love.graphics.pop()
        love.graphics.setStencilTest()
    end
end

return Saw