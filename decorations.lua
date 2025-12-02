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
        local angle = t * 3.0

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

Decorations.register("conveyor_window", {
    w = 1,
    h = 0.5,  -- half-tile tall

    init = function(inst)
        inst.data.offset = 0
    end,

    update = function(inst, dt)
        inst.data.offset = (inst.data.offset + dt * 20) % 48
    end,

    draw = function(x, y, w, h, inst)
        local S = Decorations.style

        -- frame
        love.graphics.setColor(0,0,0,1)
        love.graphics.rectangle("fill", x-4, y-4, w+8, h+8, 6, 6)

        love.graphics.setColor(S.grill)
        love.graphics.rectangle("fill", x, y, w, h, 4, 4)



        -- moving “belt” behind the slit
        local ox = inst.data.offset
        love.graphics.setColor(S.dark)

        for i = -48, w+48, 24 do
            love.graphics.rectangle("fill", x + i + ox, y+4, 16, h-8, 3, 3)
        end
    end
})

Decorations.register("diag_panel", {
    w = 1,
    h = 1,

    init = function(inst)
        inst.data.time = math.random() * 10
    end,

    update = function(inst, dt)
        inst.data.time = inst.data.time + dt
    end,

    draw = function(x, y, w, h, inst)
        local S = Decorations.style
        local t = inst.data.time

        -- frame
        love.graphics.setColor(0,0,0,1)
        love.graphics.rectangle("fill", x-4, y-4, w+8, h+8, 8, 8)

        love.graphics.setColor(S.grill)
        love.graphics.rectangle("fill", x, y, w, h, 6, 6)

        ------------------------------------------------------
        -- pulsing dots
        ------------------------------------------------------
        for i = 0,2 do
            local pulse = (math.sin(t * 3 + i*0.8) + 1) * 0.5
            love.graphics.setColor(0.3 + pulse*0.7, 0.3, 1, 1)
            love.graphics.circle("fill", x + 10, y + 10 + i*12, 3)
        end

        ------------------------------------------------------
        -- tiny “graph line”
        ------------------------------------------------------
        love.graphics.setColor(S.dark)
        local gx = x + 24
        local gy = y + h - 10

        love.graphics.line(
            gx - 10, gy - math.sin(t*2)*6,
            gx,      gy - math.sin(t*3)*3,
            gx + 10, gy - math.sin(t*1.4)*8
        )
    end
})

Decorations.register("cable_bundle", {
    w = 1,
    h = 1,

    init = function(inst)
        inst.data.time = math.random() * 10
    end,

    update = function(inst, dt)
        inst.data.time = inst.data.time + dt
    end,

    draw = function(x, y, w, h, inst)
        local S = Decorations.style
        local t = inst.data.time
        local sway = math.sin(t * 1.8) * 2  -- subtle left/right

        -- vertical base plate
        love.graphics.setColor(0,0,0,1)
        love.graphics.rectangle("fill", x-4, y-4, 12, 24+8, 4, 4)

        love.graphics.setColor(S.dark)
        love.graphics.rectangle("fill", x, y, 8, 24, 3, 3)

        ------------------------------------------------------
        -- dangling cables (3)
        ------------------------------------------------------
        local baseX = x + 4 + sway

        for i = 0,2 do
            love.graphics.setColor(S.grill)
            love.graphics.rectangle(
                "fill",
                baseX + i*4,
                y + 24,
                3,          -- cable width
                h - 24,     -- cable length
                2,2
            )
        end
    end
})

Decorations.register("pipe_liquid", {
    w = 1,
    h = 1,
    init = function(inst)
        inst.data.t = math.random()*10
    end,

    update = function(inst, dt)
        inst.data.t = inst.data.t + dt
    end,

    draw = function(x, y, w, h, inst)
        local S = Decorations.style
        local t = inst.data.t

        ------------------------------------------------------
        -- Pipe outline
        ------------------------------------------------------
        love.graphics.setColor(0,0,0,1)
        love.graphics.rectangle("fill",
            x - 4, y - 4,
            w + 8, h + 8,
            8, 8
        )

        ------------------------------------------------------
        -- Pipe body
        ------------------------------------------------------
        love.graphics.setColor(S.grill)
        love.graphics.rectangle("fill", x, y, w, h, 6, 6)

        ------------------------------------------------------
        -- Liquid Fill (animated scroll)
        ------------------------------------------------------
        local flow = (t * 40) % (w + h)  -- scroll amount
        local liquidColor = {0.3, 0.8, 1.0, 0.8}

        love.graphics.setColor(liquidColor)

        if h <= w * 0.8 then
            -- Horizontal pipe
            -- Repeating rounded segments to look like moving flow
            for i = -w, w do
                local lx = x + (i * 12 + flow)
                love.graphics.rectangle("fill",
                    lx, y + 6,
                    8, h - 12,
                    3, 3
                )
            end
        else
            -- Vertical pipe
            for i = -h, h do
                local ly = y + (i * 12 + flow)
                love.graphics.rectangle("fill",
                    x + 6, ly,
                    w - 12, 8,
                    3, 3
                )
            end
        end
    end
})

Decorations.register("pipe_large", {
    w = 1,
    h = 1,
    draw = function(x, y, w, h)
        local S = Decorations.style

        love.graphics.setColor(0,0,0,1)
        love.graphics.rectangle("fill",
            x - 4, y - 4,
            w + 8, h + 8,
            10, 10
        )

        love.graphics.setColor(S.dark)
        love.graphics.rectangle("fill", x, y, w, h, 8, 8)

        -- inner line for aesthetic tech strip
        love.graphics.setColor(S.grill)
        love.graphics.rectangle("fill",
            x + w/2 - 2,
            y + 4,
            4, h - 8,
            3, 3
        )
    end
})

Decorations.register("pipe_pulse", {
    w = 1, h = 1,
    init = function(inst) inst.data.t = 0 end,
    update = function(inst, dt) inst.data.t = inst.data.t + dt end,

    draw = function(x, y, w, h, inst)
        local S = Decorations.style
        local t = inst.data.t

        love.graphics.setColor(0,0,0,1)
        love.graphics.rectangle("fill",
            x-4, y-4, w+8, h+8,
            8,8
        )

        love.graphics.setColor(S.grill)
        love.graphics.rectangle("fill", x, y, w, h, 6,6)

        -- glowing pulse
        local pulseX = x + (math.sin(t*2)+1)*0.5*(w-12) + 6

        love.graphics.setColor(0.5, 0.9, 1, 0.9)
        love.graphics.rectangle("fill",
            pulseX, y+6,
            6, h-12,
            3,3
        )
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