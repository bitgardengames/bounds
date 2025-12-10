------------------------------------------------------------
-- Rounded-top Bounds Door
-- • Perfect semicircle top (radius = doorWidth/2)
-- • Clean 4px arch outline matching world construction
-- • Sliding door panels unchanged
------------------------------------------------------------

local Theme = require("theme")

local Door = {
    x = 0, y = 0,
    w = 72,
    h = 92,
    open = false,
    t = 0,
    speed = 6,
    id = "door",
}

------------------------------------------------------------
-- CONSTANTS
------------------------------------------------------------
local OUTLINE     = 4     -- global outline thickness
local FRAME       = 4     -- side frame thickness
local PANEL_INSET = 4
local SEAM_HALF   = 2

local COLOR_FRAME = Theme.door.frame
local COLOR_DOOR  = Theme.door.doorFill
local COLOR_LOCKED = Theme.door.locked
local COLOR_UNLOCKED = Theme.door.unlocked
local COLOR_OUTLINE = Theme.outline

------------------------------------------------------------
-- EASING
------------------------------------------------------------
local function ease(t)
    return t * t * (3 - 2 * t)
end

------------------------------------------------------------
-- SPAWN
------------------------------------------------------------
function Door.spawn(tx, ty, tile, opts)
    opts = opts or {}

    Door.id = tostring(opts.id or "door")
    Door.w = tile * 1.5
    Door.x = tx * tile - (Door.w - tile) * 0.5

    Door.h = tile * 2 - 6
    Door.y = ty * tile + 4

    Door.t = 0
    Door.open = false
end

------------------------------------------------------------
-- STATE
------------------------------------------------------------
function Door.setOpen(b) Door.open = b end
function Door.openDoor()  Door.setOpen(true) end
function Door.closeDoor() Door.setOpen(false) end

------------------------------------------------------------
-- UPDATE
------------------------------------------------------------
function Door.update(dt)
    local target = Door.open and 1 or 0
    Door.t = Door.t + (target - Door.t) * Door.speed * dt
end

------------------------------------------------------------
-- PERFECT SEMICIRCLE + RECT COMBINATION
------------------------------------------------------------
local function drawRoundedCap(x, y, w, h, inset, color)
    -- inset shrinks the boundary to create layered outlines
    local ox = inset
    local oy = inset
    local rw = w - inset * 2
    local rh = h - inset * 2

    -- Perfect semicircle radius = half the width
    local R  = rw / 2
    local cx = x + w / 2

    -- bottom of arch shape
    local arcBottom = y + oy + R

    love.graphics.setColor(color)

    ------------------------------------------------------------
    -- TOP SEMICIRCLE
    ------------------------------------------------------------
    love.graphics.arc(
        "fill",
        cx, arcBottom,
        R,
        math.pi, math.pi * 2
    )

    ------------------------------------------------------------
    -- RECT BELOW THE ARCH
    ------------------------------------------------------------
    local rectY = arcBottom
    local rectH = (y + h - inset) - rectY

    if rectH > 0 then
        love.graphics.rectangle(
            "fill",
            x + ox,
            rectY,
            rw,
            rectH
        )
    end
end

----------------------------------------------------------------
-- INNER OUTLINE FILL (shadow layer + arch)
----------------------------------------------------------------
local function drawInnerOutline(x, y, w, h)
    local inset = 4   -- inner rim inset (visual black rim)

    local arcRadius = (w * 0.5) - inset
    local arcCX = x + w * 0.5
    local arcCY = y + arcRadius + 4   -- same vertical anchor as stencil

    love.graphics.setColor(0,0,0,1)

    ------------------------------------------------------------
    -- TOP ARCH (matches stencil geometry)
    ------------------------------------------------------------
    love.graphics.arc(
        "fill",
        arcCX,
        arcCY,
        arcRadius,
        math.pi, math.pi * 2
    )

    ------------------------------------------------------------
    -- BODY BELOW ARCH (matches stencil start)
    ------------------------------------------------------------
    local rectY = arcCY
    local rectH = (y + h) - rectY

    love.graphics.rectangle(
        "fill",
        x + inset,
        rectY,
        w - inset * 2,
        rectH
    )
end

----------------------------------------------------------------
-- STENCIL SHAPE — slightly inset from the inner black outline
-- Ensures the entire black rim stays visible.
----------------------------------------------------------------
local function drawStencilShape(x, y, w, h)
    -- MUST MATCH inner-outline inset exactly
    local inset = 8

    local arcRadius = (w * 0.5) - inset
    local arcCX = x + w * 0.5
    local arcCY = y + arcRadius + 8

    -- top semicircle
    love.graphics.arc(
        "fill",
        arcCX,
        arcCY,
        arcRadius,
        math.pi, math.pi * 2
    )

    -- rect below arch
    local rectY = arcCY
    local rectH = (y + h) - rectY

    love.graphics.rectangle(
        "fill",
        x + inset,
        rectY,
        w - inset * 2,
        rectH
    )
end

------------------------------------------------------------
-- DRAW
------------------------------------------------------------
function Door.draw()
    local x, y = Door.x, Door.y
    local w, h = Door.w, Door.h
    local e = ease(math.max(0, math.min(Door.t, 1)))

    ------------------------------------------------------------
    -- 1. FRAME & ARCH (same visuals as before)
    ------------------------------------------------------------
    -- Outer black outline (full semicircle + body)
    drawRoundedCap(
        x - OUTLINE,
        y - OUTLINE,
        w + OUTLINE * 2,
        h + OUTLINE * 2,
        0,
        {0, 0, 0, 1}
    )

    -- Frame fill (4px inset)
    drawRoundedCap(
        x - OUTLINE,
        y - OUTLINE,
        w + OUTLINE * 2,
        h + OUTLINE * 2,
        OUTLINE,
        COLOR_FRAME
    )

    -- Inner shadow / rim shape (your recessed outline)
    drawInnerOutline(x, y, w, h)

	------------------------------------------------------------
	-- DOOR STATUS LIGHT STRIP (premium eased brightness)
	------------------------------------------------------------
	do
		local stripW = w - 8
		local stripH = 6
		local cx = x + w * 0.5
		local topY = y - 16

		local sx = cx - stripW * 0.5
		local sy = topY

		--------------------------------------------------------
		-- Outline (rounded capsule)
		--------------------------------------------------------
		love.graphics.setColor(COLOR_OUTLINE)
		love.graphics.rectangle(
			"fill",
			sx - 4, sy - 4,
			stripW + 8, stripH + 8,
			6, 6
		)

		--------------------------------------------------------
		-- PREMIUM FADE:
		-- Instead of binary on/off, we modulate opacity AND
		-- brightness using the door interpolation value (e)
		--------------------------------------------------------

		-- Full bright = unlocked color
		local r, g, b = COLOR_UNLOCKED[1], COLOR_UNLOCKED[2], COLOR_UNLOCKED[3]

		-- Fade strength uses ease(e) so it "blooms" in naturally
		local k = e * e * (3 - 2 * e)  -- smoothstep again

		-- Optional: dark tint when closed (locked color)
		local lr, lg, lb = COLOR_LOCKED[1], COLOR_LOCKED[2], COLOR_LOCKED[3]

		-- Blend locked → unlocked by premium easing
		local R = lr + (r - lr) * k
		local G = lg + (g - lg) * k
		local B = lb + (b - lb) * k

		--------------------------------------------------------
		-- Light fill with easing blend
		--------------------------------------------------------
		love.graphics.setColor(R, G, B, 1)
		love.graphics.rectangle(
			"fill",
			sx, sy,
			stripW, stripH,
			6, 6
		)
	end

    ------------------------------------------------------------
    -- 2. PANEL GEOMETRY (compute BEFORE stencil / early-out cleanly)
    ------------------------------------------------------------
    local panelTop     = y + FRAME + PANEL_INSET
    local panelHeight  = h - FRAME - PANEL_INSET

    local innerLeft    = x + FRAME + PANEL_INSET
    local innerRight   = x + w - FRAME - PANEL_INSET
    local innerWidth   = innerRight - innerLeft

    local maxPanelWidth = innerWidth * 0.5 - SEAM_HALF
    local panelWidth = maxPanelWidth * (1 - e)

    -- If fully open: no panels, no stencil, nothing else to do
    if panelWidth <= 0.5 then
        return
    end

    ------------------------------------------------------------
    -- 3. STENCIL: clip ONLY the panels to the doorway shape
    ------------------------------------------------------------
	love.graphics.stencil(function()
		-- Use the exact same geometry as the visual inner outline
		-- but WITHOUT drawing it normally.
		drawStencilShape(x, y, w, h)
	end, "replace", 1)

	-- Only draw where stencil > 0 (inside the inner outline)
	love.graphics.setStencilTest("greater", 0)

    ------------------------------------------------------------
    -- 4. DOOR PANELS (same visuals, now properly clipped)
    ------------------------------------------------------------

    -- LEFT PANEL
    do
        local fillX = innerLeft
        local fillW = panelWidth

        -- Outline
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle("fill",
            fillX - OUTLINE,
            panelTop - OUTLINE,
            fillW + OUTLINE,
            panelHeight + OUTLINE * 2
        )

        -- Fill
        love.graphics.setColor(COLOR_DOOR)
        love.graphics.rectangle("fill",
            fillX,
            panelTop,
            fillW,
            panelHeight
        )
    end

    -- RIGHT PANEL
    do
        local fillW = panelWidth
        local fillX = innerRight - fillW

        -- Outline
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle("fill",
            fillX,
            panelTop - OUTLINE,
            fillW + OUTLINE,
            panelHeight + OUTLINE * 2
        )

        -- Fill
        love.graphics.setColor(COLOR_DOOR)
        love.graphics.rectangle("fill",
            fillX,
            panelTop,
            fillW,
            panelHeight
        )
    end

    ------------------------------------------------------------
    -- 5. TURN STENCIL OFF SO THE REST OF THE WORLD IS NORMAL
    ------------------------------------------------------------
    love.graphics.setStencilTest()
end

return Door