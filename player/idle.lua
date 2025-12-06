local ContextZones = require("contextzones")

local TAU = math.pi * 2

local Idle = {
    -- normalized [0,1) accumulator for the breathing loop
    t = 0,
    breatheAmp = 0.03,   -- ±3% scale
    breatheSpeed = 1.0,  -- Hz
    effectTimer = 0,
    timeToNext = 0,
    activeEffect = nil,
}

Idle.baseWeights = {
    glance      = 0.20,
    glance2     = 0.20,
    peek        = 0.18,
    lean        = 0.14,
    wiggle      = 0.14,
    rock        = 0.08,
    scratch     = 0.03,
    look_up     = 0.03,
}

local function clamp(v, mn, mx)
    return (v < mn and mn) or (v > mx and mx) or v
end

local function nextDelay()
    return 6 + math.random() * 6
end

local function weightedPick(weights)
    local total = 0
    for _, w in pairs(weights) do total = total + w end
    local r = math.random() * total
    local acc = 0

    for name, w in pairs(weights) do
        acc = acc + w
        if r <= acc then
            return name
        end
    end

    return nil
end

local function buildWeightedTable()
    local w = {}

    -- start with base weights
    for name, v in pairs(Idle.baseWeights) do
        w[name] = v
    end

    -- apply active zone bias
    local z = ContextZones.active
    if z and z.effects then
        for name, boost in pairs(z.effects) do
            if w[name] then
                w[name] = w[name] + boost   -- simple additive bias
            end
        end
    end

    return w
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
    local breatheRate = Idle.breatheSpeed * (isIdle and 1 or 0.25)
    Idle.t = (Idle.t + dt * breatheRate) % 1

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

				-- Build weighted table with context bias
				local weights = buildWeightedTable()
				local chosen = weightedPick(weights)
				local dir = (math.random() < 0.5) and -1 or 1

				if chosen == "glance" then
					startEffect("glance", { duration = 0.9, dir = -1 })

				elseif chosen == "glance2" then
					startEffect("glance", { duration = 0.9, dir = 1 })

				elseif chosen == "peek" then
					startEffect("peek", { duration = 1.1, dir = dir })

				elseif chosen == "lean" then
					startEffect("lean", { duration = 1.4, dir = dir })

				elseif chosen == "wiggle" then
					startEffect("wiggle", { duration = 1.2, dir = dir, cycles = 2.5 })

				elseif chosen == "rock" then
					startEffect("rock", { duration = 1.5, cycles = 2.4 })

				elseif chosen == "scratch" then
					startEffect("scratch", { duration = 1.1, dir = dir })

				elseif chosen == "look_up" then
					startEffect("look_up", { duration = 1.0, dir = dir })
				end

				Idle.timeToNext = nextDelay()
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
    return 1 + math.sin(Idle.t * TAU) * Idle.breatheAmp
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

function Idle.getHandPose()
    local effect = Idle.activeEffect
    if not effect or effect.kind ~= "scratch" then return nil end

    local progress = clamp(Idle.effectTimer / effect.duration, 0, 1)

    local phase1, phase2, phase3, phase4 = 0.20, 0.22, 0.30, 0.28
    local t, x, y = 0, 0, 0

    if progress < phase1 then
        t = progress / phase1
        x = 0.95 - t * 0.33
        y = 0.18 - t * 0.04
    elseif progress < phase1 + phase2 then
        t = (progress - phase1) / phase2
        x = 0.62 - t * 0.20
        y = 0.14 - t * 0.32
    elseif progress < phase1 + phase2 + phase3 then
        t = (progress - phase1 - phase2) / phase3
        local scratch = math.sin(t * math.pi * 4) * 0.06
        local tap = math.sin(t * math.pi * 2.6 + math.pi/4) * 0.03
        x = 0.42 + scratch
        y = -0.18 + tap
    else
        t = (progress - phase1 - phase2 - phase3) / phase4
        x = 0.42 + t * 0.55
        y = -0.18 + t * 0.40
    end

    return x * effect.dir, y
end

return Idle
