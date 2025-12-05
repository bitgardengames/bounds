-- door.lua
------------------------------------------------------------
-- Bounds Door (1.5 tiles wide, ~2 tiles tall)
-- • Double sliding panels meet with a perfect 4px seam
-- • Panels retract outward when opening
-- • Premium eased animation (Hermite smoothstep)
-- • Panel inset clean + consistent outlines
------------------------------------------------------------

local Theme = require("theme")

local Door = {
    x = 0, y = 0,
    w = 72,
    h = 92,
    open = false,
    t = 0,
    speed = 6,
}

------------------------------------------------------------
-- CONSTANTS
------------------------------------------------------------
local OUTLINE     = 4
local FRAME       = 4
local PANEL_INSET = 4
local SEAM_HALF   = 2      -- <-- NEW: each panel stops 2px from center

local COLOR_FRAME = Theme.door.frame
local COLOR_DOOR = Theme.door.doorFill

------------------------------------------------------------
-- EASING
------------------------------------------------------------
local function ease(t)
    return t * t * (3 - 2 * t)
end

------------------------------------------------------------
-- SPAWN
------------------------------------------------------------
function Door.spawn(tx, ty, tile)
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
-- DRAW
------------------------------------------------------------
function Door.draw()
    local x, y   = Door.x, Door.y
    local w, h   = Door.w, Door.h
    local e      = ease(math.max(0, math.min(Door.t, 1)))

    --------------------------------------------------------
    -- 1. OUTER OUTLINE
    --------------------------------------------------------
    love.graphics.setColor(0,0,0,1)
    love.graphics.rectangle("fill",
        x - OUTLINE, y - OUTLINE,
        w + OUTLINE*2, h + OUTLINE*2
    )

    --------------------------------------------------------
    -- 2. CAVITY
    --------------------------------------------------------
    love.graphics.setColor(0,0,0,1)
    love.graphics.rectangle("fill", x, y, w, h)

    --------------------------------------------------------
    -- 3. FRAME
    --------------------------------------------------------
    love.graphics.setColor(COLOR_FRAME)

    -- top
    love.graphics.rectangle("fill", x, y, w, FRAME)

    -- left
    love.graphics.rectangle("fill",
        x,
        y + FRAME,
        FRAME,
        h - FRAME
    )

    -- right
    love.graphics.rectangle("fill",
        x + w - FRAME,
        y + FRAME,
        FRAME,
        h - FRAME
    )

    --------------------------------------------------------
    -- 4. PANEL GEOMETRY
    --------------------------------------------------------
    local panelTop     = y + FRAME + PANEL_INSET
    local panelHeight  = h - FRAME - PANEL_INSET

    local innerLeft    = x + FRAME + PANEL_INSET
    local innerRight   = x + w - FRAME - PANEL_INSET
    local innerWidth   = innerRight - innerLeft

    -- maximum closed width per panel
    local maxPanelWidth = innerWidth * 0.5 - SEAM_HALF   -- <-- NEW

    -- eased width (retract outward when opening)
    local panelWidth = maxPanelWidth * (1 - e)

    if panelWidth <= 0.5 then return end

    local cx = (innerLeft + innerRight) * 0.5

    --------------------------------------------------------
    -- LEFT PANEL
    --------------------------------------------------------
    do
        local fillX = innerLeft
        local fillW = panelWidth

        -- OUTLINE (extends outward)
        love.graphics.setColor(0,0,0,1)
        love.graphics.rectangle("fill",
            fillX - OUTLINE,
            panelTop - OUTLINE,
            fillW + OUTLINE,
            panelHeight + OUTLINE*2
        )

        -- FILL
        love.graphics.setColor(COLOR_DOOR)
        love.graphics.rectangle("fill",
            fillX,
            panelTop,
            fillW,
            panelHeight
        )
    end

    --------------------------------------------------------
    -- RIGHT PANEL
    --------------------------------------------------------
    do
        local fillW = panelWidth
        local fillX = innerRight - fillW

        -- OUTLINE (extends outward)
        love.graphics.setColor(0,0,0,1)
        love.graphics.rectangle("fill",
            fillX,
            panelTop - OUTLINE,
            fillW + OUTLINE,
            panelHeight + OUTLINE*2
        )

        -- FILL
        love.graphics.setColor(COLOR_DOOR)
        love.graphics.rectangle("fill",
            fillX,
            panelTop,
            fillW,
            panelHeight
        )
    end
end

return Door