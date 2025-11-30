--------------------------------------------------------------
-- SAW BLADE HAZARDS — Noodl-style exact geometry
--------------------------------------------------------------

local Saw = { list = {} }

local Particles = require("particles")

--------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------

local BASE_RADIUS     = 16          -- same as SawActor default
local TEETH           = 9
local INNER_RATIO     = 0.80
local SPIN_SPEED      = 5
local MOVE_SPEED      = 110
local OUTLINE         = 3           -- stroke thickness
local SHADOW_OFFSET   = 3
local HIGHLIGHT_ALPHA = 0.12
local TRACK_LENGTH    = 160
local TRAVEL_PADDING  = 6
local TRACK_THICKNESS = 14

--------------------------------------------------------------
-- SPAWN
--------------------------------------------------------------
function Saw.spawn(x, y, opts)
    opts = opts or {}

    local dir = opts.dir
    local length = opts.length or TRACK_LENGTH

    table.insert(Saw.list, {
        anchorX = x,
        anchorY = y,
        x = x,
        y = y,
        r = opts.r or BASE_RADIUS,
        angle = opts.angle or 0,

        dir = dir,
        trackLength = length,
        progress = 0,
        direction = opts.direction or 1,
        speed = opts.speed or 1,

        vx = opts.vx or 0,
        vy = opts.vy or MOVE_SPEED,

        sineAmp  = opts.sineAmp  or 0,
        sineFreq = opts.sineFreq or 0,

        t = 0,
        dead = false,
    })
end

--------------------------------------------------------------
-- COLLISION
--------------------------------------------------------------
local function hitPlayer(saw, player)
    local px = player.x + player.w/2
    local py = player.y + player.h/2
    local dx = saw.x - px
    local dy = saw.y - py
    local dist = dx*dx + dy*dy
    local r = saw.r + player.radius
    return dist < r*r
end

--------------------------------------------------------------
-- UPDATE
--------------------------------------------------------------
function Saw.update(dt, player, Level)
    for i = #Saw.list, 1, -1 do
        local s = Saw.list[i]

        s.t     = s.t + dt
        s.angle = s.angle + SPIN_SPEED * dt

        local offset = (s.sineAmp ~= 0) and (math.sin(s.t * s.sineFreq) * s.sineAmp) or 0

        if s.dir == "horizontal" or s.dir == "vertical" then
            local travel = math.max(0, (s.trackLength * 0.5) - TRAVEL_PADDING)
            local delta = MOVE_SPEED * s.speed * dt * s.direction

            s.progress = s.progress + delta
            if s.progress > travel then
                s.progress = travel
                s.direction = -1
            elseif s.progress < -travel then
                s.progress = -travel
                s.direction = 1
            end

            if s.dir == "horizontal" then
                s.x = s.anchorX + s.progress
                s.y = s.anchorY + offset
            else
                s.x = s.anchorX + offset
                s.y = s.anchorY + s.progress
            end
        else
            s.x = s.x + s.vx * dt
            s.y = s.y + s.vy * dt + offset * dt

            local TILE = Level.TILE_SIZE
            local tx   = math.floor(s.x / TILE)
            local ty   = math.floor(s.y / TILE)

            if Level.tileAt(tx, ty) == "#" then
                s.vx = -s.vx
                s.vy = -s.vy

                for n = 1, 3 do
                    Particles.puff(
                        s.x + (math.random()-0.5)*6,
                        s.y + (math.random()-0.5)*6,
                        (math.random()-0.5)*70,
                        (math.random()-0.5)*70,
                        5, 0.25,
                        {1,1,1,0.9}
                    )
                end
            end
        end

        if hitPlayer(s, player) then
            print("PLAYER HIT BY SAW!")
        end

        if s.dead then
            table.remove(Saw.list, i)
        end
    end
end

--------------------------------------------------------------
-- BUILD NOODL-STYLE TOOTH GEOMETRY
-- (ported 1:1 from SawActor:drawRaw)  :contentReference[oaicite:6]{index=6}
--------------------------------------------------------------
local function buildSawPoints(radius, teeth)
    local pts = {}
    local outerR = radius
    local innerR = radius * INNER_RATIO
    local step = (math.pi * 2) / teeth

    for i = 0, teeth - 1 do
        local aOuter = i * step
        local aInner = aOuter + step * 0.5

        pts[#pts+1] = math.cos(aOuter) * outerR
        pts[#pts+1] = math.sin(aOuter) * outerR

        pts[#pts+1] = math.cos(aInner) * innerR
        pts[#pts+1] = math.sin(aInner) * innerR
    end

    return pts
end

local function getTrackRect(s)
    if s.dir == "horizontal" then
        local width = s.trackLength + s.r * 2
        return s.anchorX - s.trackLength * 0.5 - s.r, s.anchorY - TRACK_THICKNESS * 0.5, width, TRACK_THICKNESS
    elseif s.dir == "vertical" then
        local height = s.trackLength + s.r * 2
        return s.anchorX - TRACK_THICKNESS * 0.5, s.anchorY - s.trackLength * 0.5 - s.r, TRACK_THICKNESS, height
    end
end

--------------------------------------------------------------
-- DRAW
--------------------------------------------------------------
function Saw.draw()
    for _, s in ipairs(Saw.list) do
        ------------------------------------------------------
        -- Build geometry
        ------------------------------------------------------
        local pts = buildSawPoints(s.r, TEETH)

        -- rotate points (same as SawActor)  :contentReference[oaicite:7]{index=7}
        local rotPts = {}
        local c = math.cos(s.angle)
        local sn = math.sin(s.angle)

        for i = 1, #pts, 2 do
            local x0 = pts[i]
            local y0 = pts[i+1]
            rotPts[#rotPts+1] = x0 * c - y0 * sn
            rotPts[#rotPts+1] = x0 * sn + y0 * c
        end

        -- triangulate
        local tris = love.math.triangulate(rotPts)

        local tx, ty, tw, th = getTrackRect(s)
        if tx then
            --------------------------------------------------
            -- Track slot visuals
            --------------------------------------------------
            love.graphics.setColor(0.08, 0.08, 0.12, 1)
            love.graphics.rectangle("fill", tx, ty, tw, th)
            love.graphics.setColor(0, 0, 0, 0.45)
            love.graphics.rectangle("line", tx, ty, tw, th)
            love.graphics.setColor(1, 1, 1, 0.08)
            love.graphics.line(tx, ty + 1, tx + tw, ty + 1)

            love.graphics.stencil(function()
                love.graphics.rectangle("fill", tx, ty, tw, th)
            end, "replace", 1)
            love.graphics.setStencilTest("equal", 1)
        end

        ------------------------------------------------------
        -- Shadow
        ------------------------------------------------------
        love.graphics.push()
        love.graphics.translate(s.x + SHADOW_OFFSET, s.y + SHADOW_OFFSET)
        love.graphics.setColor(0,0,0,0.35)
        for _, tri in ipairs(tris) do
            love.graphics.polygon("fill", tri)
        end
        love.graphics.pop()

        ------------------------------------------------------
        -- Blade fill
        ------------------------------------------------------
        love.graphics.push()
        love.graphics.translate(s.x, s.y)
        love.graphics.setColor(0.85, 0.80, 0.75, 1)   -- Noodl blade color

        for _, tri in ipairs(tris) do
            love.graphics.polygon("fill", tri)
        end

        ------------------------------------------------------
        -- Highlight
        ------------------------------------------------------
        love.graphics.setColor(1,1,1,HIGHLIGHT_ALPHA)
        love.graphics.circle("fill", 0, 0, s.r * 0.55)

        ------------------------------------------------------
        -- Outline
        ------------------------------------------------------
        love.graphics.setColor(0,0,0,1)
        love.graphics.setLineWidth(OUTLINE)
        love.graphics.polygon("line", rotPts)

        ------------------------------------------------------
        -- Hub (center hole)
        ------------------------------------------------------
        love.graphics.setColor(0,0,0,1)
        love.graphics.circle("fill", 0, 0, s.r * 0.33)

        love.graphics.pop()

        if tx then
            love.graphics.setStencilTest()
        end
    end
end

return Saw
