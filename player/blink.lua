----------------------------------------------------------
-- Blink module
-- Handles automatic blinking with easing
----------------------------------------------------------

local Blink = {
    timer = 0,
    intervalMin = 2.4,
    intervalMax = 5.0,
    duration     = 0.12, -- full blink cycle
    progress     = 0,    -- 0 = open, 1 = fully closed
    closing      = true, -- state inside the blink
}

-- Randomize next blink
local function resetBlinkTimer(self)
    self.timer = math.random() * (self.intervalMax - self.intervalMin) + self.intervalMin
end

function Blink.init()
    resetBlinkTimer(Blink)
end

function Blink.update(dt)
    local self = Blink

    -- waiting for next blink
    if self.timer > 0 then
        self.timer = self.timer - dt
        if self.timer <= 0 then
            -- start blink
            self.progress = 0
            self.closing = true
        end
        return
    end

    -- active blink
    local speed = dt / self.duration

    if self.closing then
        self.progress = self.progress + speed * 2
        if self.progress >= 1 then
            self.progress = 1
            self.closing = false
        end
    else
        self.progress = self.progress - speed * 2
        if self.progress <= 0 then
            self.progress = 0
            resetBlinkTimer(self)
        end
    end
end

-- returns scale multiplier for eye radius, 1 = normal, 0 = fully closed
function Blink.getEyeScale()
    return 1 - Blink.progress
end

return Blink