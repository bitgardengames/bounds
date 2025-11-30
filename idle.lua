local Idle = {
    t = 0,
    breatheAmp = 0.03,   -- ±3% scale
    breatheSpeed = 1.0,  -- Hz
    effectTimer = 0,
    timeToNext = 0,
    activeEffect = nil,
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

function Idle.update(dt, isIdle)
    if isIdle then
        Idle.t = Idle.t + dt

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
                if roll < 0.24 then
                    startEffect("glance", { duration = 0.9, dir = -1 })
                elseif roll < 0.48 then
                    startEffect("glance", { duration = 0.9, dir = 1 })
                elseif roll < 0.66 then
                    local dir = (math.random() < 0.5) and -1 or 1
                    startEffect("peek", { duration = 1.1, dir = dir })
                elseif roll < 0.82 then
                    local dir = (math.random() < 0.5) and -1 or 1
                    startEffect("lean", { duration = 1.4, dir = dir })
                else
                    local dir = (math.random() < 0.5) and -1 or 1
                    startEffect("wiggle", { duration = 1.2, dir = dir, cycles = 2.5 })
                end
            end
        end
    else
        -- very slow drift while not idle
        Idle.t = Idle.t + dt * 0.25

        Idle.activeEffect = nil
        Idle.effectTimer = 0
        Idle.timeToNext = nextDelay()
    end
end

-- returns scale multiplier (1.0 = neutral)
function Idle.getScale()
    return 1 + math.sin(Idle.t * Idle.breatheSpeed * math.pi * 2) * Idle.breatheAmp
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
    end

    return 0
end

return Idle
