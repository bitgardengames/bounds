--------------------------------------------------------------
-- SAW BLADE HAZARDS — Noodl-accurate sunken tracks (FINAL+mount)
-- Supports horizontal (floor / ceiling) and vertical (left / right)
--------------------------------------------------------------

local Saw = { list = {} }

local Particles = require("particles")

--------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------

local BASE_RADIUS = 16
local TEETH       = 9
local INNER_RATIO = 0.80
local SPIN_SPEED  = 5
local MOVE_SPEED  = 110
local OUTLINE     = 3

-- depth illusion essentials
local TRACK_THICKNESS  = 10
local TRACK_CAP_RADIUS = TRACK_THICKNESS * 0.5

local TRACK_LENGTH   = 160
local TRAVEL_PADDING = 18

-- Key colors (currently all black to match Bounds palette)
local COLOR_BACK      = {0, 0, 0}   -- trench interior
local COLOR_FILL      = {0, 0, 0}   -- (reserved for future front fill)
local COLOR_RIM       = {0, 0, 0}   -- (reserved for front rim wall)
local COLOR_RIM_LIGHT = {0, 0, 0}   -- (reserved for lip highlight)

--------------------------------------------------------------
-- SPAWN
--------------------------------------------------------------

-- opts:
--   dir   = "horizontal" | "vertical"
--   mount =
--      if dir == "horizontal": "bottom" (floor, blade up) or "top" (ceiling, blade down)
--      if dir == "vertical"  : "left" (track on left wall, blade right)
--                             or "right" (track on right wall, blade left)
--   length, speed, r, angle, sineAmp, sineFreq as before
function Saw.spawn(x, y, opts)
    opts = opts or {}

    local dir = opts.dir or "horizontal"

    local mount
    if dir == "horizontal" then
        mount = opts.mount or "bottom"
    else
        mount = opts.mount or "left"
    end

    table.insert(Saw.list, {
        anchorX = x,
        anchorY = y,

        -- current world-space center of the blade
        x = x,
        y = y,

        -- visuals
        r     = opts.r     or BASE_RADIUS,
        angle = opts.angle or 0,

        -- track motion
        dir         = dir,
        mount       = mount,
        trackLength = opts.length or TRACK_LENGTH,

        progress  = 0,
        direction = 1,
        speed     = opts.speed or 1,

        -- optional sinusoidal wobble (unused for now but kept)
        sineAmp  = opts.sineAmp  or 0,
        sineFreq = opts.sineFreq or 0,

        -- misc
        t    = 0,
        dead = false,
    })
end

--------------------------------------------------------------
-- COLLISION
--------------------------------------------------------------

local function hitPlayer(saw, player)
    local px = player.x + player.w * 0.5
    local py = player.y + player.h * 0.5

    local dx = saw.x - px
    local dy = saw.y - py
    local dist2 = dx*dx + dy*dy
    local r = saw.r + (player.radius or 0)

    return dist2 < r * r
end

--------------------------------------------------------------
-- UPDATE
--------------------------------------------------------------

function Saw.update(dt, player)
    for i = #Saw.list, 1, -1 do
        local s = Saw.list[i]

        s.t     = s.t + dt
        s.angle = s.angle + SPIN_SPEED * dt

        -- optional sine offset for fun future patterns
        local wobble = 0
        if s.sineAmp ~= 0 and s.sineFreq ~= 0 then
            wobble = math.sin(s.t * s.sineFreq) * s.sineAmp
        end

        if s.dir == "horizontal" or s.dir == "vertical" then
            local travel = math.max(0, (s.trackLength * 0.5) - TRAVEL_PADDING)
            local delta  = MOVE_SPEED * s.speed * dt * s.direction

            s.progress = s.progress + delta
            if s.progress > travel then
                s.progress  = travel
                s.direction = -1
            elseif s.progress < -travel then
                s.progress  = -travel
                s.direction = 1
            end

            if s.dir == "horizontal" then
                -- moves along X, anchored on Y
                s.x = s.anchorX + s.progress
                s.y = s.anchorY + wobble
            else
                -- moves along Y, anchored on X
                s.x = s.anchorX + wobble
                s.y = s.anchorY + s.progress
            end
        end

        if hitPlayer(s, player) then
            -- TODO: hook into your death handler
            print("PLAYER HIT BY SAW")
        end

        if s.dead then
            table.remove(Saw.list, i)
        end
    end
end

--------------------------------------------------------------
-- SAW GEOMETRY
--------------------------------------------------------------

local function buildSawPoints(radius, teeth)
    local pts = {}
    local outerR = radius
    local innerR = radius * INNER_RATIO
    local step   = (math.pi * 2) / teeth

    for i = 0, teeth - 1 do
        local aO = i * step
        local aI = aO + step * 0.5

        -- outer tip
        pts[#pts+1] = math.cos(aO) * outerR
        pts[#pts+1] = math.sin(aO) * outerR

        -- inner notch
        pts[#pts+1] = math.cos(aI) * innerR
        pts[#pts+1] = math.sin(aI) * innerR
    end

    return pts
end

--------------------------------------------------------------
-- TRACK SHAPE
--------------------------------------------------------------

local function getCapsule(s)
    local half = s.trackLength * 0.5

    if s.dir == "horizontal" then
        -- track runs left/right, centred on anchorY
        return
            s.anchorX - half,
            s.anchorY - TRACK_THICKNESS * 0.5,
            s.anchorX + half,
            s.anchorY + TRACK_THICKNESS * 0.5,
            true
    else
        -- track runs up/down, centred on anchorX
        return
            s.anchorX - TRACK_THICKNESS * 0.5,
            s.anchorY - half,
            s.anchorX + TRACK_THICKNESS * 0.5,
            s.anchorY + half,
            false
    end
end

--------------------------------------------------------------
-- CORE DRAW HELPERS
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
        -- rotate a rect to get a vertical capsule with rounded ends
        love.graphics.push()
        love.graphics.translate(x1, y1)
        love.graphics.rotate(math.pi * 0.5)
        love.graphics.rectangle(
            "fill",
            0, 0,
            (y2 - y1), TRACK_THICKNESS,
            TRACK_CAP_RADIUS, TRACK_CAP_RADIUS
        )
        love.graphics.pop()
    end
end

-- Half-rect stencil that hides the "back" half of the blade.
-- Which side is hidden depends on mount:
--   horizontal "bottom": hide BELOW track centre (blade sticks UP)
--   horizontal "top"   : hide ABOVE track centre (blade sticks DOWN)
--   vertical   "left"  : hide LEFT of track centre  (blade sticks RIGHT)
--   vertical   "right" : hide RIGHT of track centre (blade sticks LEFT)
local function stencilHalfRect(s)
    local half  = s.trackLength * 0.5
    local depth = s.r * 1.7  -- how deep the saw sinks

    if s.dir == "horizontal" then
        if s.mount == "top" then
            -- hide everything ABOVE the track centre
            love.graphics.rectangle(
                "fill",
                s.anchorX - half,
                s.anchorY - depth,
                s.trackLength,
                depth
            )
        else
            -- default "bottom" behaviour: hide everything BELOW
            love.graphics.rectangle(
                "fill",
                s.anchorX - half,
                s.anchorY,
                s.trackLength,
                depth
            )
        end
    else
        if s.mount == "left" then
            -- track on left wall, blade visible on RIGHT → hide LEFT
            love.graphics.rectangle(
                "fill",
                s.anchorX - depth,
                s.anchorY - half,
                depth,
                s.trackLength
            )
        else
            -- default "right" behaviour: hide everything RIGHT
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
        --------------------------------------------------
        -- Prepare blade geometry (rotated teeth)
        --------------------------------------------------
        local raw = buildSawPoints(s.r, TEETH)
        local rot = {}
        local c   = math.cos(s.angle)
        local sn  = math.sin(s.angle)

        for i = 1, #raw, 2 do
            local x0 = raw[i]
            local y0 = raw[i+1]
            rot[#rot+1] = x0 * c - y0 * sn
            rot[#rot+1] = x0 * sn + y0 * c
        end

        local tris = love.math.triangulate(rot)

        --------------------------------------------------
        -- Track capsule (back wall only for now)
        --------------------------------------------------
        local x1, y1, x2, y2, horiz = getCapsule(s)

        -- back trench
        drawCapsule(x1, y1, x2, y2, horiz, COLOR_BACK)

        --------------------------------------------------
        -- Stencil to hide "back" half of blade
        --------------------------------------------------
        love.graphics.stencil(function()
            stencilHalfRect(s)
        end, "replace", 1)

        -- We want to draw the blade only where stencil == 0 (front half)
        love.graphics.setStencilTest("equal", 0)

        love.graphics.push()
        love.graphics.translate(s.x, s.y)

        -- main metal fill
        love.graphics.setColor(0.85, 0.80, 0.75, 1)
        for _, t in ipairs(tris) do
            love.graphics.polygon("fill", t)
        end

        -- soft inner sheen
        love.graphics.setColor(1, 1, 1, 0.10)
        love.graphics.circle("fill", 0, 0, s.r * 0.55)

        -- thick outline + hub
        love.graphics.setColor(0, 0, 0)
        love.graphics.setLineWidth(OUTLINE)
        love.graphics.polygon("line", rot)
        love.graphics.circle("fill", 0, 0, s.r * 0.33)

        love.graphics.pop()

        love.graphics.setStencilTest()
    end
end

return Saw