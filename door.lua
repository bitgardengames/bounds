-- door.lua
------------------------------------------------------------
-- Bounds Door (premium sliding version)
-- • Doors meet perfectly at center
-- • Eased animation (cubic)
-- • Optional settle bounce
-- • Clean math, no offsets spaghetti
------------------------------------------------------------

local Door = {
    x = 0, y = 0,
    w = 48,
    h = 90,
    open = false,
    t = 0,
    speed = 4.0,
}

------------------------------------------------------------
-- EASING
------------------------------------------------------------
local function easeInOutCubic(x)
    return x < 0.5 and 4*x*x*x or 1 - (-2*x + 2)^3 / 2
end

-- small settle bounce near end of closing
local function easeWithSettle(t)
    -- Normal open: 0→1, closed: 1→0
    local base = easeInOutCubic(t)

    if not Door.open then
        -- settling bounce on close
        local overshoot = math.sin(t * math.pi) * 0.03 -- tiny wobble
        base = base + overshoot
    end

    return math.max(0, math.min(base, 1))
end

------------------------------------------------------------
-- SPAWN
------------------------------------------------------------
function Door.spawn(tx, ty, tile)
    Door.x = tx * tile
    Door.y = ty * tile
    Door.w = tile
    Door.h = tile * 2 - 6  -- 90px
    Door.t = 0
    Door.open = false
end

------------------------------------------------------------
-- STATE
------------------------------------------------------------
function Door.setOpen(state)
    Door.open = state
end

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
    local x, y, w, h = Door.x, Door.y, Door.w, Door.h
    local rawT = math.max(0, math.min(Door.t, 1))
    local t = easeWithSettle(rawT)

    --------------------------------------------------------
    -- CONSTANTS
    --------------------------------------------------------
    local OUTLINE = 4
    local FRAME   = 4
    local centerW = 4        -- center post width
    local frameColor = {68/255, 83/255, 97/255, 1}
    local panelColor = {0.80, 0.84, 0.86, 1}

    --------------------------------------------------------
    -- OUTER OUTLINE BOX
    --------------------------------------------------------
    love.graphics.setColor(0,0,0,1)
    love.graphics.rectangle(
        "fill",
        x - OUTLINE, 
        y - OUTLINE,
        w + OUTLINE*2,
        h + OUTLINE*2
    )

    --------------------------------------------------------
    -- INNER CAVITY (background)
    --------------------------------------------------------
    love.graphics.setColor(0,0,0,1)
    love.graphics.rectangle("fill", x, y, w, h)

    --------------------------------------------------------
    -- DOOR FRAME (left, right, top)
    --------------------------------------------------------
    love.graphics.setColor(frameColor)

    -- top
    love.graphics.rectangle("fill", x, y, w, FRAME)

    -- left
    love.graphics.rectangle("fill", x, y, FRAME, h)

    -- right
    love.graphics.rectangle("fill", x + w - FRAME, y, FRAME, h)

    --------------------------------------------------------
    -- CENTER COLUMN (static)
    --------------------------------------------------------
    local cx = x + w/2 - centerW/2
    love.graphics.setColor(0,0,0,1)
    love.graphics.rectangle("fill", cx, y + FRAME, centerW, h - FRAME)

    --------------------------------------------------------
    -- PANELS (slide behind center post)
    --------------------------------------------------------
    local innerW = w - FRAME*2
    local maxSlide = (innerW - centerW) * 0.5

    -- amount doors retract
    local slide = maxSlide * t

    --------------------------------------------------------
    -- LEFT PANEL
    --------------------------------------------------------
    love.graphics.setColor(0,0,0,1) -- outline
    love.graphics.rectangle("fill",
        x + FRAME - 2,
        y + FRAME - 2,
        maxSlide - slide + 4,
        h - FRAME + 4
    )

    love.graphics.setColor(panelColor)
    love.graphics.rectangle("fill",
        x + FRAME,
        y + FRAME,
        maxSlide - slide,
        h - FRAME
    )

    --------------------------------------------------------
    -- RIGHT PANEL
    --------------------------------------------------------
    love.graphics.setColor(0,0,0,1)
    love.graphics.rectangle("fill",
        cx + centerW - 2 + slide,
        y + FRAME - 2,
        maxSlide - slide + 4,
        h - FRAME + 4
    )

    love.graphics.setColor(panelColor)
    love.graphics.rectangle("fill",
        cx + centerW + slide,
        y + FRAME,
        maxSlide - slide,
        h - FRAME
    )
end

return Door