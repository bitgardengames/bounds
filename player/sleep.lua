local Blink = require("blink")

local Sleep = {}

local SLEEP_THRESHOLD = 20.0

local function ease(t)
    return t * t * (3 - 2 * t)
end

function Sleep.wakeOnInput(p, move, jumpDown, jumpReleased)
    if not (p.sleeping or p.sleepingTransition) then return end

    if move ~= 0 or jumpDown or jumpReleased then
        p.sleeping = false
        p.sleepingTransition = false
        p.idleTimer = 0
        p.sleepEyeT = 0

        Blink.progress = 0
        Blink.closing  = false
        Blink.timer    = 2.5
    end
end

function Sleep.updateIdle(p, dt, move)
    local isIdle =
        p.onGround and
        math.abs(p.vx) < 5 and
        math.abs(p.vy) < 5 and
        move == 0

    if isIdle then
        p.idleTimer = p.idleTimer + dt

        if not p.sleeping
        and not p.sleepingTransition
        and p.idleTimer >= SLEEP_THRESHOLD then

            p.sleepingTransition = true
            p.sleepEyeT = 0
            Blink.timer = 9999
            Blink.closing = false
        end
    else
        p.idleTimer = 0
        if p.sleeping or p.sleepingTransition then
            p.sleeping = false
            p.sleepingTransition = false
            p.sleepEyeT = 0
            Blink.progress = 0
            Blink.timer = 2.5
        end
    end
end

function Sleep.updateBlink(p, dt)
    if p.sleepingTransition then
        p.sleepEyeT = p.sleepEyeT + dt / 0.9
        if p.sleepEyeT >= 1 then
            p.sleepEyeT = 1
            p.sleepingTransition = false
            p.sleeping = true
        end

        local t = p.sleepEyeT

        -- 1) Half-blink
        if t < 0.30 then
            local k = ease(t / 0.30)
            Blink.progress = k * 0.50

        -- 2) Full blink
        elseif t < 0.60 then
            local k = ease((t - 0.30) / 0.30)
            Blink.progress = 0.50 + k * 0.50

        -- 3) Final sealed
        else
            local k = ease((t - 0.60) / 0.40)
            Blink.progress = 1 - k * 0.0
        end

        Blink.closing = false
        Blink.timer   = 9999
    end

    if p.sleeping then
        Blink.progress = 1
        Blink.closing = false
        Blink.timer = 9999
    end
end

return Sleep
