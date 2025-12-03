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
    outline = {45/255, 66/255, 86/255, 1},
    panel = {0.90, 0.90, 0.93, 1},
    --background = {82/255, 101/255, 114/255, 1},
    background = {69/255, 89/255, 105/255},
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

function Decorations.clear()
    for i = #list, 1, -1 do
        list[i] = nil
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
-- LARGE FAN (2×2 tiles, premium wind-down/spin-up)
--------------------------------------------------------------

Decorations.register("fan_large", {
    w = 2,
    h = 2,

	init = function(inst)
        inst.data = {
            fanSpeed = 1.0,
            targetSpeed = 1.0,
            state = "normal",
            stateTimer = 0,
            nextEvent = love.math.random(20, 30) + love.math.random()
        }
    end,

	update = function(inst, dt)
		local d = inst.data

		------------------------------------------------------
		-- STATE MACHINE (unchanged)
		------------------------------------------------------
		if d.state == "normal" then
			d.targetSpeed = 1.0
			d.nextEvent = d.nextEvent - dt
			if d.nextEvent <= 0 then
				d.state = "wind_down"
				d.stateTimer = 0
			end

		elseif d.state == "wind_down" then
			d.targetSpeed = 0.0
			if d.fanSpeed <= 0.10 then
				d.state = "pause"
				d.stateTimer = 0
				d.pauseDuration = 10 + love.math.random() * 2.4
			end

		elseif d.state == "pause" then
			d.stateTimer = d.stateTimer + dt
			d.targetSpeed = 0.0
			if d.stateTimer >= d.pauseDuration then
				d.state = "spin_up"
				d.stateTimer = 0
			end

		elseif d.state == "spin_up" then
			d.targetSpeed = 1.0
			if d.fanSpeed >= 0.995 then
				d.state = "normal"
				d.nextEvent = love.math.random(10, 28)
			end
		end

		------------------------------------------------------
		-- FIXED SPEED SMOOTHING (no zipping, no reversal)
		------------------------------------------------------
		local accelRate = 1.25     -- gentle speed-up
		local brakeRate = 0.45     -- heavy slow-down
		local rate = (d.targetSpeed > d.fanSpeed) and accelRate or brakeRate

		-- exponential smoothing (critically damped)
		d.fanSpeed = d.fanSpeed + (d.targetSpeed - d.fanSpeed) * (1 - math.exp(-rate * dt))

		-- clamp extremes
		if d.fanSpeed < 0 then d.fanSpeed = 0 end
		if d.fanSpeed > 1 then d.fanSpeed = 1 end

		------------------------------------------------------
		-- FIXED ROTATION (NEVER reverses direction)
		------------------------------------------------------
		d.angle = (d.angle or 0) + dt * (1.8 * d.fanSpeed)

		-- keep angle bounded
		if d.angle > math.pi * 2 then
			d.angle = d.angle - math.pi * 2
		end
	end,

    draw = function(x, y, w, h, inst)
        local S  = Decorations.style
        local cx = x + w/2
        local cy = y + h/2
        local d  = inst.data

        ------------------------------------------------------
        -- HOUSING (inset for cleaner proportions)
        ------------------------------------------------------
        local inset = 8
        local hx = x + inset
        local hy = y + inset
        local hw = w - inset * 2
        local hh = h - inset * 2

        local housingRadius = 10

        -- Outline
        love.graphics.setColor(S.outline)
        love.graphics.rectangle(
            "fill",
            hx - 4, hy - 4,
            hw + 8, hh + 8,
            housingRadius + 6, housingRadius + 6
        )

        -- Fill
        love.graphics.setColor(S.metal)
        love.graphics.rectangle(
            "fill",
            hx, hy,
            hw, hh,
            housingRadius, housingRadius
        )

        ------------------------------------------------------
        -- BOLTS
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
        -- FAN CAVITY OUTER RING + INNER FILL
        ------------------------------------------------------
        local cavityOuterR = hw * 0.42

        -- Outline ring
        love.graphics.setColor(S.outline)
        love.graphics.setLineWidth(4)
        love.graphics.circle("line", cx, cy, cavityOuterR)

        -- Inner cavity
        local cavityInnerR = cavityOuterR - 2
        love.graphics.setColor(S.dark)
        love.graphics.circle("fill", cx, cy, cavityInnerR)

        ------------------------------------------------------
        -- ROTATION
        ------------------------------------------------------
		local angle = d.angle or 0

        ------------------------------------------------------
        -- BLADES
        ------------------------------------------------------
        love.graphics.push()
        love.graphics.translate(cx, cy)
        love.graphics.rotate(angle)

        local bladeW = 8
        local bladeL = cavityInnerR - 4

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
        -- CENTER HUB + CAP
        ------------------------------------------------------
        love.graphics.setColor(S.dark)
        love.graphics.circle("fill", cx, cy, 8)

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
-- PIPE: HORIZONTAL
--------------------------------------------------------------
Decorations.register("pipe_h", {
    w = 1, h = 1,

    draw = function(x, y, w, h)
        local S = Decorations.style
        local pipeFill = 4
        local O = 4

        local thick = pipeFill + O*2   -- total pipe thickness (12px)
        local cy = y + h/2 - thick/2

        -- Outline
        love.graphics.setColor(S.outline)
        love.graphics.rectangle("fill", x, cy, w, thick)

        -- Fill
        love.graphics.setColor(S.metal)
        love.graphics.rectangle("fill",
            x + 0,
            cy + O,
            w,
            pipeFill
        )
    end
})

--------------------------------------------------------------
-- PIPE: VERTICAL
--------------------------------------------------------------
Decorations.register("pipe_v", {
    w = 1, h = 1,

    draw = function(x, y, w, h)
        local S = Decorations.style
        local pipeFill = 4
        local O = 4

        local thick = pipeFill + O*2
        local cx = x + w/2 - thick/2

        -- Outline
        love.graphics.setColor(S.outline)
        love.graphics.rectangle("fill", cx, y, thick, h)

        -- Fill
        love.graphics.setColor(S.metal)
        love.graphics.rectangle("fill",
            cx + O,
            y + 0,
            pipeFill,
            h
        )
    end
})

--------------------------------------------------------------
-- PIPE: JUNCTION BOX
--------------------------------------------------------------
Decorations.register("pipe_junctionbox", {
    w = 1,
    h = 1,

    draw = function(x, y, w, h)
        local S = Decorations.style

        local O = 4         -- outline thickness (same as pipes)
        local boxH = h/2    -- 24px tall if tile is 48px
        local boxY = y + h/2 - boxH/2
        local radius = 8

        ----------------------------------------------------------
        -- OUTLINE (outer box)
        ----------------------------------------------------------
        love.graphics.setColor(S.outline)
        love.graphics.rectangle(
            "fill",
            x,
            boxY,
            w,
            boxH,
            radius, radius
        )

        ----------------------------------------------------------
        -- INNER FILL
        ----------------------------------------------------------
        love.graphics.setColor(S.metal)
        love.graphics.rectangle(
            "fill",
            x + O,
            boxY + O,
            w - O*2,
            boxH - O*2,
            radius - 4, radius - 4
        )

        ----------------------------------------------------------
        -- CENTER LIGHT (wider, centered, outlined)
        ----------------------------------------------------------
        local lightW = 20     -- wider than before
        local lightH = 8
        local lightX = x + w/2 - lightW/2
        local lightY = boxY + boxH/2 - lightH/2

        -- LIGHT OUTLINE
        love.graphics.setColor(S.outline)
        love.graphics.rectangle(
            "fill",
            lightX - 2,
            lightY - 2,
            lightW + 4,
            lightH + 4,
            3, 3
        )

        -- LIGHT FILL (inactive default)
        love.graphics.setColor(1.0, 0.35, 0.35, 0.95)
        love.graphics.rectangle(
            "fill",
            lightX,
            lightY,
            lightW,
            lightH,
            3, 3
        )

        --[[ SOFT GLOW
        love.graphics.setColor(1.0, 0.35, 0.35, 0.22)
        love.graphics.rectangle(
            "fill",
            lightX - 4,
            lightY - 4,
            lightW + 8,
            lightH + 8,
            4, 4
        )]]
    end
})

--------------------------------------------------------------
-- INTERNAL: Draw a rounded 90° pipe corner
--------------------------------------------------------------
local function drawPipeCurve(x, y, w, h, rotate)
    local S = Decorations.style
    local pipeFill = 4
    local O = 4
    local thick = pipeFill + O*2

    -- The curve radius = half tile
    local R = w/2

    love.graphics.push()
    love.graphics.translate(x + w/2, y + h/2)  -- center tile
    love.graphics.rotate(rotate)
    love.graphics.translate(-w/2, -h/2)

    ----------------------------------------------------------
    -- OUTLINE ARC
    ----------------------------------------------------------
    love.graphics.setColor(S.outline)
    love.graphics.setLineWidth(thick)
    love.graphics.arc("line", "open",
        w, h,            -- arc center
        R,               -- radius
        math.pi,         -- start angle
        math.pi*1.5      -- end angle
    )

    ----------------------------------------------------------
    -- FILL ARC
    ----------------------------------------------------------
    love.graphics.setColor(S.metal)
    love.graphics.setLineWidth(pipeFill)
    love.graphics.arc("line", "open",
        w, h,
        R,
        math.pi,
        math.pi*1.5
    )

    love.graphics.pop()
end

--------------------------------------------------------------
-- PIPE CURVE PIECES (rounded corners)
--------------------------------------------------------------
Decorations.register("pipe_curve_tr", {
    w = 1, h = 1,
    draw = function(x,y,w,h)
        drawPipeCurve(x,y,w,h, 0)
    end
})

Decorations.register("pipe_curve_tl", {
    w = 1, h = 1,
    draw = function(x,y,w,h)
        drawPipeCurve(x,y,w,h, math.pi*0.5)
    end
})

Decorations.register("pipe_curve_bl", {
    w = 1, h = 1,
    draw = function(x,y,w,h)
        drawPipeCurve(x,y,w,h, math.pi)
    end
})

Decorations.register("pipe_curve_br", {
    w = 1, h = 1,
    draw = function(x,y,w,h)
        drawPipeCurve(x,y,w,h, math.pi*1.5)
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