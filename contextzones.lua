-- contextzones.lua
local ContextZones = {
    zones = {},
    active = nil,
}

local DEBUG_CONTEXT = false   -- toggle visibility
local debugFont = love.graphics.newFont(12)

-- TILE SIZE is injected at chamber load time
ContextZones.tileSize = 48

--------------------------------------------------------------
-- Add zone using tile coordinates
-- tx, ty = tile position
-- w, h  = tile span
--------------------------------------------------------------
function ContextZones.add(name, tx, ty, wTiles, hTiles, effects)
    local T = ContextZones.tileSize

    table.insert(ContextZones.zones, {
        name = name,
        x = tx * T,
        y = ty * T,
        w = wTiles * T,
        h = hTiles * T,
        effects = effects or {}
    })
end

function ContextZones.clear()
    ContextZones.zones = {}
    ContextZones.active = nil
end

local function inside(px, py, z)
    return px >= z.x and px <= z.x + z.w
       and py >= z.y and py <= z.y + z.h
end

function ContextZones.update(player)
    local px = player.x + player.w/2
    local py = player.y + player.h/2

    ContextZones.active = nil
    for _, z in ipairs(ContextZones.zones) do
        if inside(px, py, z) then
            ContextZones.active = z
            break
        end
    end
end

--------------------------------------------------------------
-- Debug drawing
--------------------------------------------------------------
function ContextZones.draw()
    if not DEBUG_CONTEXT then return end
    love.graphics.setLineWidth(2)

    local oldFont = love.graphics.getFont()
    love.graphics.setFont(debugFont)

    for _, z in ipairs(ContextZones.zones) do
        -- fill
        love.graphics.setColor(1.0, 0.7, 0.3, 0.30)
        love.graphics.rectangle("fill", z.x, z.y, z.w, z.h)

        -- outline
        love.graphics.setColor(1.0, 0.7, 0.3, 0.75)
        love.graphics.rectangle("line", z.x, z.y, z.w, z.h)

        -- label
        local label = z.name or "zone"
        local fw = love.graphics.getFont():getWidth(label)
        local fh = love.graphics.getFont():getHeight()

        local px = z.x + 4
        local py = z.y + 4

        love.graphics.setColor(0,0,0,0.5)
        love.graphics.rectangle("fill", px-2, py-2, fw+4, fh+4, 3, 3)

        love.graphics.setColor(1.0, 0.8, 0.4, 1.0)
        love.graphics.print(label, px, py)
    end

    -- active highlight
    if ContextZones.active then
        local z = ContextZones.active
        love.graphics.setColor(1.0, 0.5, 0.1, 0.75)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", z.x, z.y, z.w, z.h)
    end

    love.graphics.setFont(oldFont)
end

return ContextZones