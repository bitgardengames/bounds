local TAU = math.pi * 2

local Idle = {
    -- normalized [0,1) accumulator for the breathing loop
    t = 0,
    breatheAmp = 0.03,     -- ±3% scale when awake/idle
    breatheAmpSleep = 0.05, -- ±5% scale while sleeping for a cozier rise/fall
    breatheAmpCurrent = 0.03,
    breatheSpeed = 1.0,    -- Hz
    sleepBreatheSpeed = 0.55,
    effectTimer = 0,
    timeToNext = 0,
    activeEffect = nil,
    sleepTimer = 0,
}

local function clamp(v, mn, mx)
    return (v < mn and mn) or (v > mx and mx) or v
end

local function nextDelay()
    return 6 + math.random() * 6
end

Idle.timeToNext = nextDelay()

local function startEffect(kind, params)
    Idle.activeEffect = {
        kind = kind,
        duration = params.duration,
        dir = params.dir or 1,
        cycles = params.cycles,
    }
    Idle.effectTimer = 0
end

function Idle.update(dt, isIdle, isSleeping)
    local targetAmp = isSleeping and Idle.breatheAmpSleep or Idle.breatheAmp
    Idle.breatheAmpCurrent = Idle.breatheAmpCurrent + (targetAmp - Idle.breatheAmpCurrent) * math.min(dt * 6, 1)

    local breatheRate
    if isSleeping then
        breatheRate = Idle.sleepBreatheSpeed
    else
        breatheRate = Idle.breatheSpeed * (isIdle and 1 or 0.25)
    end
    Idle.t = (Idle.t + dt * breatheRate) % 1

    if isSleeping then
        Idle.sleepTimer = Idle.sleepTimer + dt
    else
        Idle.sleepTimer = 0
    end

    if isIdle then

        if Idle.activeEffect then
            Idle.effectTimer = Idle.effectTimer + dt
            if Idle.effectTimer >= Idle.activeEffect.duration then
                Idle.activeEffect = nil
                Idle.timeToNext = nextDelay()
            end
        else
            Idle.timeToNext = Idle.timeToNext - dt
            if Idle.timeToNext <= 0 then
                local roll = math.random()
                if roll < 0.20 then
                    startEffect("glance", { duration = 0.9, dir = -1 })
                elseif roll < 0.40 then
                    startEffect("glance", { duration = 0.9, dir = 1 })
                elseif roll < 0.58 then
                    local dir = (math.random() < 0.5) and -1 or 1
                    startEffect("peek", { duration = 1.1, dir = dir })
                elseif roll < 0.72 then
                    local dir = (math.random() < 0.5) and -1 or 1
                    startEffect("lean", { duration = 1.4, dir = dir })
                elseif roll < 0.86 then
                    local dir = (math.random() < 0.5) and -1 or 1
                    startEffect("wiggle", { duration = 1.2, dir = dir, cycles = 2.5 })
                elseif roll < 0.94 then
                    startEffect("rock", { duration = 1.5, cycles = 2.4 })
                else
                    local dir = (math.random() < 0.5) and -1 or 1
                    startEffect("look_up", { duration = 1.0, dir = dir })
                end
            end
        end
    else
        -- very slow drift while not idle
        Idle.activeEffect = nil
        Idle.effectTimer = 0
        Idle.timeToNext = nextDelay()
    end
end

-- returns scale multiplier (1.0 = neutral)
function Idle.getScale()
    return 1 + math.sin(Idle.t * TAU) * Idle.breatheAmpCurrent
end

function Idle.getEyeOffset()
    local effect = Idle.activeEffect
    if not effect then return 0, 0 end

    local progress = clamp(Idle.effectTimer / effect.duration, 0, 1)
    if effect.kind == "glance" then
        local magnitude = math.sin(progress * math.pi) * 0.85
        return magnitude * effect.dir, 0
    elseif effect.kind == "peek" then
        local magnitude = math.sin(progress * math.pi)
        return magnitude * effect.dir * 0.55, -magnitude * 0.45
    elseif effect.kind == "lean" then
        local magnitude = math.sin(progress * math.pi) * 0.35
        return magnitude * effect.dir * 0.35, -magnitude * 0.15
    elseif effect.kind == "wiggle" then
        local envelope = math.sin(progress * math.pi)
        local oscillation = math.sin(progress * math.pi * (effect.cycles or 2.5))
        return oscillation * effect.dir * envelope * 0.55, math.sin(progress * math.pi * 1.3) * envelope * 0.25
    elseif effect.kind == "rock" then
        local envelope = math.sin(progress * math.pi)
        local oscillation = math.sin(progress * math.pi * (effect.cycles or 2.2))
        return oscillation * envelope * 0.65, math.sin(progress * math.pi * 1.5) * envelope * 0.12
    elseif effect.kind == "look_up" then
        local magnitude = math.sin(progress * math.pi)
        return magnitude * effect.dir * 0.30, -magnitude * 0.55
    end

    return 0, 0
end

function Idle.getLeanOffset()
    local effect = Idle.activeEffect
    if not effect then return 0 end

    local progress = clamp(Idle.effectTimer / effect.duration, 0, 1)
    if effect.kind == "lean" then
        local magnitude = math.sin(progress * math.pi) * 0.12
        return magnitude * effect.dir
    elseif effect.kind == "peek" then
        local magnitude = math.sin(progress * math.pi) * 0.08
        return magnitude * effect.dir
    elseif effect.kind == "wiggle" then
        local envelope = math.sin(progress * math.pi)
        local oscillation = math.sin(progress * math.pi * (effect.cycles or 2.5))
        return oscillation * envelope * effect.dir * 0.10
    elseif effect.kind == "rock" then
        local envelope = math.sin(progress * math.pi)
        local oscillation = math.sin(progress * math.pi * (effect.cycles or 2.2))
        return oscillation * envelope * 0.09
    elseif effect.kind == "look_up" then
        local magnitude = math.sin(progress * math.pi) * 0.05
        return -magnitude * 0.8
    end

    return 0
end

-- Returns normalized offsets (relative to the player's radius) for a sleepy bubble
-- plus an opacity scalar. Returns nil when not sleeping.
function Idle.getSleepBubble()
    if Idle.sleepTimer <= 0 then return nil end

    local cycle = 2.6
    local phase = (Idle.sleepTimer % cycle) / cycle
    local grow = math.sin(phase * math.pi)
    local rise = math.sin(phase * math.pi) * 0.22

    local offsetX = -0.52
    local offsetY = -0.02 - rise
    local radius  = 0.13 + grow * 0.08
    local opacity = 0.65 + (1 - phase) * 0.25

    return offsetX, offsetY, radius, opacity
end

return Idle
