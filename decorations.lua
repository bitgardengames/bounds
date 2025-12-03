-- decorations.lua (Clean Prefab-Based Version)
--------------------------------------------------------------
-- Purpose: Provide a clean, extensible decoration system with:
--  • Tile-based placement (tx, ty)
--  • Prefabs with consistent styling
--  • Automatic world-space conversion
--  • Simple registration API
--------------------------------------------------------------

local Decorations = {}

--------------------------------------------------------------
-- INTERNAL REGISTRY + ACTIVE LIST
--------------------------------------------------------------

local registry = {}       -- prefabs (definitions)
local list = {}           -- spawned decorations (instances)

Decorations.list = list   -- expose if needed

--------------------------------------------------------------
-- SHARED STYLE (Portal-ish metal aesthetic)
--------------------------------------------------------------

Decorations.style = {
    dark = {0.1, 0.1, 0.1, 1},
    outline = {68/255, 83/255, 97/255, 1},
    panel = {0.90, 0.90, 0.93, 1},
    background = {82/255, 101/255, 114/255, 1},
    metal = {82/255, 101/255, 114/255, 1},
    grill = {72/255, 91/255, 104/255, 1},
    fanFill = {0.88, 0.88, 0.92, 1},
}

--------------------------------------------------------------
-- PREFAB REGISTRATION
--------------------------------------------------------------

function Decorations.register(name, prefab)
    assert(prefab.draw, "Prefab '" .. name .. "' must include a draw function.")
    registry[name] = prefab
end

--------------------------------------------------------------
-- SPAWN FROM LEVELDATA (tile → world)
--------------------------------------------------------------

function Decorations.spawn(entry, tileSize)
    local prefab = registry[entry.type]
    if not prefab then
        print("Warning: unknown decoration type '" .. tostring(entry.type) .. "'")
        return
    end

    tileSize = tileSize or 48

    -- prefab declares its tile footprint
    local wTiles = prefab.w or 1
    local hTiles = prefab.h or 1

	local inst = {
		type = entry.type,
		x = entry.tx * tileSize,
		y = entry.ty * tileSize,
		w = wTiles * tileSize,
		h = hTiles * tileSize,
		data = {} -- <--- per-instance data table
	}

	-- Allow prefab to initialize instance data once
	if prefab.init then
		prefab.init(inst)
	end

	table.insert(list, inst)
end

--------------------------------------------------------------
-- BULK SPAWN FROM LEVELDATA LAYER
--------------------------------------------------------------

function Decorations.spawnLayer(layer, tileSize)
    for _, obj in ipairs(layer.objects or {}) do
        Decorations.spawn(obj, tileSize)
    end
end

--------------------------------------------------------------
-- DRAW LOOP
--------------------------------------------------------------

function Decorations.draw()
    for _, d in ipairs(list) do
        local prefab = registry[d.type]
        if prefab then
            prefab.draw(d.x, d.y, d.w, d.h, d)
        end
    end
end

--------------------------------------------------------------
-- PREFABS BELOW
--------------------------------------------------------------
-- All sizes measured in *tiles*, not pixels.
-- draw(x, y, w, h) receives world-space values in pixels.
--------------------------------------------------------------

--------------------------------------------------------------
-- PANEL (simple inset wall panel)
--------------------------------------------------------------

Decorations.register("panel", {
    w = 1.5,   -- tiles
    h = 1,

    draw = function(x, y, w, h)
        local S = Decorations.style

        -- Outline
        love.graphics.setColor(S.background)
        love.graphics.rectangle("fill", x-4, y-4, w+8, h+8, 6, 6)

        -- Fill
        love.graphics.setColor(S.panel)
        love.graphics.rectangle("fill", x, y, w, h, 4, 4)

        -- Subtle horizontal ribs
        love.graphics.setColor(0, 0, 0, 0.16)
        for sy = y + 6, y + h - 6, 8 do
            love.graphics.rectangle("fill", x + 6, sy, w - 12, 3, 2, 2)
        end
    end
})

Decorations.register("panel_tall", {
    w = 1,   -- tiles wide
    h = 2,   -- TALL PANEL

    draw = function(x, y, w, h)
        local S = Decorations.style

        -- FILL
        love.graphics.setColor(S.background)
        love.graphics.rectangle("fill", x + 2, y + 2, w - 4, h - 4)
    end
})

--------------------------------------------------------------
-- VENT (metal grill)
--------------------------------------------------------------

Decorations.register("vent", {
    w = 1,  -- now 48×48 tile
    h = 1,

    draw = function(x, y, w, h)
        local S = Decorations.style

        ------------------------------------------------------
        -- OUTER FRAME
        ------------------------------------------------------
        love.graphics.setColor(S.background)
        love.graphics.rectangle("fill", x+2, y+2, w-4, h-4)

        ------------------------------------------------------
        -- METAL PLATE
        ------------------------------------------------------
        love.graphics.setColor(S.metal)
        love.graphics.rectangle("fill", x + 2, y + 2, w - 4, h - 4)

        ------------------------------------------------------
        -- GRILL SLATS — spaced nicely for full 48px height
        ------------------------------------------------------
        love.graphics.setColor(S.dark)

        -- 6–7 slats looks best visually
        local slatCount = 4
        local spacing = h / (slatCount + 1)

        for i = 1, slatCount do
            local sy = y + spacing * i - 2
            love.graphics.rectangle("fill", x + 6, sy, w - 12, 4, 2, 2)
        end
    end
})

--------------------------------------------------------------
-- FAN (rotating blades)
--------------------------------------------------------------

Decorations.register("fan", {
    w = 1,
    h = 1,

    draw = function(x, y, w, h)
        local S = Decorations.style
        local cx = x + w/2
        local cy = y + h/2
        local r = w * 0.42

        local t = love.timer.getTime()
        local angle = t * 1.8

        -- Housing outline
        love.graphics.setColor(S.outline)
        love.graphics.circle("fill", cx, cy, r + 4)

        -- Housing fill
        love.graphics.setColor(S.dark)
        love.graphics.circle("fill", cx, cy, r)

        -- Blades
        love.graphics.setColor(S.metal)
        love.graphics.push()
        love.graphics.translate(cx, cy)
        love.graphics.rotate(angle)

        for i = 1, 4 do
            love.graphics.rotate(math.pi * 0.5)
            love.graphics.rectangle("fill", -4, -r + 4, 8, r - 8, 4, 4)
        end

        love.graphics.pop()
    end
})

--------------------------------------------------------------
-- LARGE FAN (2×2 tiles, rounded housing)
--------------------------------------------------------------

Decorations.register("fan_large", {
    w = 2,
    h = 2,

    draw = function(x, y, w, h)
        local S = Decorations.style
        local cx = x + w/2
        local cy = y + h/2

        ------------------------------------------------------
        -- Smaller housing footprint (inset from 2×2 tile space)
        ------------------------------------------------------
        local inset = 8     -- shrink housing by 8px on all sides
        local hx = x + inset
        local hy = y + inset
        local hw = w - inset * 2
        local hh = h - inset * 2

        local t     = love.timer.getTime()
        local angle = t * 1.8  -- soothing background rotation

        ------------------------------------------------------
        -- OUTER HOUSING (rounded square)
        ------------------------------------------------------
        local housingRadius = 10

        -- outline
        love.graphics.setColor(S.outline)
        love.graphics.rectangle("fill",
            hx - 4, hy - 4,
            hw + 8, hh + 8,
            housingRadius + 6, housingRadius + 6
        )

        -- fill
        love.graphics.setColor(S.metal)
        love.graphics.rectangle("fill",
            hx, hy,
            hw, hh,
            housingRadius, housingRadius
        )

        ------------------------------------------------------
        -- CORNER BOLTS
        ------------------------------------------------------
        love.graphics.setColor(S.dark)
        local boltR = 3

        local bx1 = hx + 10
        local bx2 = hx + hw - 10
        local by1 = hy + 10
        local by2 = hy + hh - 10

        love.graphics.circle("fill", bx1, by1, boltR)
        love.graphics.circle("fill", bx2, by1, boltR)
        love.graphics.circle("fill", bx1, by2, boltR)
        love.graphics.circle("fill", bx2, by2, boltR)

        ------------------------------------------------------
        -- FAN CAVITY: OUTER RING + INNER FILL
        ------------------------------------------------------
        -- Outer radius: where the outline ring lives
        local cavityOuterR = hw * 0.42

        -- 4px ring on the inside edge
        love.graphics.setColor(S.outline)
        love.graphics.setLineWidth(4)
        love.graphics.circle("line", cx, cy, cavityOuterR)

        -- Inner dark fill, shrunk so ring remains visible
        local cavityInnerR = cavityOuterR - 2

        love.graphics.setColor(S.dark)
        love.graphics.circle("fill", cx, cy, cavityInnerR)

        ------------------------------------------------------
        -- BLADES (fit within inner cavity)
        ------------------------------------------------------
        love.graphics.push()
        love.graphics.translate(cx, cy)
        love.graphics.rotate(angle)

        local bladeW  = 8
        local bladeL  = cavityInnerR - 4

        love.graphics.setColor(S.metal)
        for i = 1, 4 do
            love.graphics.rotate(math.pi * 0.5)
            love.graphics.rectangle(
                "fill",
                -bladeW/2,
                -bladeL,
                bladeW,
                bladeL,
                4, 4
            )
        end

        love.graphics.pop()

		------------------------------------------------------
		-- CENTER HUB (8px, S.dark)
		------------------------------------------------------
		love.graphics.setColor(S.dark)
		love.graphics.circle("fill", cx, cy, 8)

		------------------------------------------------------
		-- CENTER CAP (4px, S.metal)
		------------------------------------------------------
		love.graphics.setColor(S.metal)
		love.graphics.circle("fill", cx, cy, 4)
    end
})

--------------------------------------------------------------
-- LIGHT (simple round lamp)
--------------------------------------------------------------

Decorations.register("light", {
    w = 0.5,
    h = 0.5,

    draw = function(x, y, w, h)
        local cx = x + w/2
        local cy = y + h/2
        local r = w * 0.4

        -- Light housing
        love.graphics.setColor(0,0,0)
        love.graphics.circle("fill", cx, cy, r+3)

        -- Glow
        local t = love.timer.getTime()
        local pulse = (math.sin(t*4)+1)*0.5 * 0.15

        love.graphics.setColor(1,1,0.85, 0.85 + pulse)
        love.graphics.circle("fill", cx, cy, r)
    end
})

--------------------------------------------------------------
-- ROUND VENT (static porthole with horizontal slats)
--------------------------------------------------------------

Decorations.register("vent_round", {
    w = 1,
    h = 1,

    draw = function(x, y, w, h)
        local S  = Decorations.style
        local cx = x + w/2
        local cy = y + h/2
        local r  = w * 0.42    -- vent housing radius

        ------------------------------------------------------
        -- OUTER OUTLINE
        ------------------------------------------------------
        love.graphics.setColor(S.outline)
        love.graphics.circle("fill", cx, cy, r + 4)

        ------------------------------------------------------
        -- METAL HOUSING
        ------------------------------------------------------
        love.graphics.setColor(S.metal)
        love.graphics.circle("fill", cx, cy, r)

        ------------------------------------------------------
        -- INNER FACE
        ------------------------------------------------------
        love.graphics.setColor(S.dark)
        love.graphics.circle("fill", cx, cy, r - 4)

        ------------------------------------------------------
        -- SLATS (perfectly centered, symmetric)
        ------------------------------------------------------

        local slatCount = 3
        local gap = r * 0.32 + 2

        for i = 1, slatCount do
            -- offset: {-gap, 0, +gap}
            local offset = (i - math.ceil(slatCount/2)) * gap
            local sy = cy + offset

            -- actual slat plate
            love.graphics.setColor(S.metal)
            love.graphics.rectangle(
                "fill",
                cx - (r - 2),
                sy - 2,
                (r - 2) * 2,
                4,
                2, 2
            )
        end
    end
})

--------------------------------------------------------------
-- END PREFABS
--------------------------------------------------------------

function Decorations.update(dt)
    for _, inst in ipairs(list) do
        local prefab = registry[inst.type]
        if prefab and prefab.update then
            prefab.update(inst, dt)
        end
    end
end


return Decorations