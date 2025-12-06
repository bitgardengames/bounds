--------------------------------------------------------------
-- LASER RECEIVER — A stateful object similar to pressure plates
-- • Detects when a laser beam hits it
-- • Maintains active/inactive state
-- • Can trigger doors / platforms by target ID
--------------------------------------------------------------

local Theme = require("theme")
local S = Theme.decorations

local LaserReceiver = {
    list = {},
    stateById = {}   -- maps target IDs → active bool
}

--------------------------------------------------------------
-- SPAWN
--------------------------------------------------------------
function LaserReceiver.spawn(tx, ty, dir, id)
    local ts = 48

    local inst = {
        x = tx * ts,
        y = ty * ts,
        w = ts,
        h = ts,

        dir = dir or "left",  -- must match direction beam enters from
        id  = id or ("receiver_" .. (#LaserReceiver.list + 1)),

        active   = false,
        wasActive = false,
    }

    table.insert(LaserReceiver.list, inst)
    LaserReceiver.stateById[inst.id] = false

    return inst
end

--------------------------------------------------------------
-- CLEAR
--------------------------------------------------------------
function LaserReceiver.clear()
    LaserReceiver.list = {}
    LaserReceiver.stateById = {}
end

--------------------------------------------------------------
-- SET ACTIVE STATE
--------------------------------------------------------------
function LaserReceiver.setState(id, newState)
    LaserReceiver.stateById[id] = newState
end

function LaserReceiver.getState(id)
    return LaserReceiver.stateById[id] == true
end

function LaserReceiver.isActive(id)
    return LaserReceiver.stateById[id] == true
end

--------------------------------------------------------------
-- HIT TEST — does the beam intersect the receiver face?
--------------------------------------------------------------
local function hitTest(inst, lx, ly)
    -- lx,ly = laser hit pixel from emitter
    -- Each receiver checks if lx,ly enters its "sensor zone"

    local x, y, w, h = inst.x, inst.y, inst.w, inst.h
    local pad = 6  -- tighten bounds slightly

    -- Define face rectangle based on direction
    if inst.dir == "left" then
        local fx1 = x
        local fx2 = x + pad
        return lx >= fx1 and lx <= fx2 and ly >= y and ly <= y+h

    elseif inst.dir == "right" then
        local fx1 = x + w - pad
        local fx2 = x + w
        return lx >= fx1 and lx <= fx2 and ly >= y and ly <= y+h

    elseif inst.dir == "up" then
        local fy1 = y
        local fy2 = y + pad
        return ly >= fy1 and ly <= fy2 and lx >= x and lx <= x+w

    elseif inst.dir == "down" then
        local fy1 = y + h - pad
        local fy2 = y + h
        return ly >= fy1 and ly <= fy2 and lx >= x and lx <= x+w
    end

    return false
end

--------------------------------------------------------------
-- UPDATE — Called AFTER LaserEmitter.update()
--------------------------------------------------------------
function LaserReceiver.update(dt, emitters)
    -- Reset all receivers to inactive before checking hits
    for _, inst in ipairs(LaserReceiver.list) do
        inst.wasActive = inst.active
        inst.active = false -- will re-enable if beam hits
    end

    -- For each emitter, check whether its beam hit a receiver face
    for _, em in ipairs(emitters) do
        if em.active then
            for _, inst in ipairs(LaserReceiver.list) do
                if hitTest(inst, em.hitX, em.hitY) then
                    inst.active = true
                end
            end
        end
    end

    -- Update global state map
    for _, inst in ipairs(LaserReceiver.list) do
        LaserReceiver.stateById[inst.id] = inst.active
    end
end

--------------------------------------------------------------
-- DRAW — housing + status diode
--------------------------------------------------------------
function LaserReceiver.draw()
    for _, inst in ipairs(LaserReceiver.list) do
        local x, y, w, h = inst.x, inst.y, inst.w, inst.h

        ------------------------------------------------------
        -- HOUSING
        ------------------------------------------------------
        love.graphics.setColor(S.outline)
        love.graphics.rectangle("fill", x+2, y+2, w-4, h-4, 6, 6)

        love.graphics.setColor(S.metal)
        love.graphics.rectangle("fill", x+6, y+6, w-12, h-12, 5, 5)

        ------------------------------------------------------
        -- SENSOR CAVITY
        ------------------------------------------------------
        local cavW = w - 26
        local cavH = h - 30
        local cavX = x + (w - cavW)/2
        local cavY = y + (h - cavH)/2

        love.graphics.setColor(S.dark)
        love.graphics.rectangle("fill", cavX, cavY, cavW, cavH, 4, 4)

        ------------------------------------------------------
        -- STATUS DIODE
        ------------------------------------------------------
        -- Position diode on the sensor face, centered
        local dx, dy = cavX + cavW/2, cavY + cavH/2

        if inst.active then
            love.graphics.setColor(0.35, 1.0, 0.35, 1) -- green
        else
            love.graphics.setColor(1.0, 0.25, 0.25, 1) -- red
        end

        love.graphics.circle("fill", dx, dy, 6)

        -- highlight
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.circle("fill", dx+1.5, dy-1.5, 1.4)
    end
end

return LaserReceiver