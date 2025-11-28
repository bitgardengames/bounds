local Idle = {
    t = 0,
    breatheAmp = 0.03,   -- ±3% scale
    breatheSpeed = 1.0,  -- Hz
}

function Idle.update(dt, isIdle)
    if isIdle then
        Idle.t = Idle.t + dt
    else
        -- very slow drift while not idle
        Idle.t = Idle.t + dt * 0.25
    end
end

-- returns scale multiplier (1.0 = neutral)
function Idle.getScale()
    return 1 + math.sin(Idle.t * Idle.breatheSpeed * math.pi * 2) * Idle.breatheAmp
end

return Idle