--------------------------------------------------------------
-- PARTICLE SYSTEM MODULE
-- Cute circular puffs for jumps / landings / wall slides, etc.
--------------------------------------------------------------

local particles = {}

local Particles = {}

--------------------------------------------------------------
-- Simple API
-- Particles.spawn(x, y, vx, vy, radius, lifetime, color)
-- Particles.update(dt)
-- Particles.draw()
--------------------------------------------------------------

function Particles.spawn(x, y, vx, vy, radius, life, color)
    table.insert(particles, {
        x = x,
        y = y,
        vx = vx or 0,
        vy = vy or 0,
        r  = radius or 4,
        life    = life or 0.4,
        maxLife = life or 0.4,
        color   = color or {1, 1, 1, 1},
        gravity = 400,        -- small downward pull
    })
end

-- FLOATY PUFF (no gravity, soft easing)
function Particles.puff(x, y, vx, vy, radius, life, color)
    color = color or {1,1,1,1}

    table.insert(particles, {
        x = x,
        y = y,
        vx = vx or 0,
        vy = vy or 0,
        r  = radius or 4,
        life    = life or 0.4,
        maxLife = life or 0.4,
        color   = color,
        gravity = 0,
    })
end

-- BRIGHT SPARKLE (no gravity, quick fade)
function Particles.sparkle(x, y, vx, vy, radius, life, color)
    color = color or {1, 0.9, 0.5, 1}

    table.insert(particles, {
        x = x,
        y = y,
        vx = vx or 0,
        vy = vy or 0,
        r  = radius or 2.5,
        life    = life or 0.25,
        maxLife = life or 0.25,
        color   = color,
        gravity = 0,
        softFade = true,
    })
end

-- WALL SLIDE SOFT DUST (slight downward drift, soft fade)
function Particles.wallDust(x, y, vx, vy, radius, life, color)
    color = color or {1,1,1,1}

    table.insert(particles, {
        x = x,
        y = y,
        vx = vx or 0,
        vy = vy or 0,
        r  = radius or 3,
        life    = life or 0.25,
        maxLife = life or 0.25,
        color   = color,
        gravity = 40,     -- MUCH lighter than 400
        softFade = true,  -- <--- flag for soft easing
    })
end

function Particles.update(dt)
    for i = #particles, 1, -1 do
        local p = particles[i]

        -- movement
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vy = p.vy + p.gravity * dt

        -- fade
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(particles, i)
        end
    end
end

function Particles.draw()
    for _, p in ipairs(particles) do
        local t = p.life / p.maxLife
        local alpha = p.softFade and (t * t) or t   -- cubic ease-out fade
        local size = p.softFade and (p.r * (0.4 + 0.6 * t)) or (p.r * t)
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], (p.color[4] or 1) * alpha)
        love.graphics.circle("fill", p.x, p.y, size)
    end
end

return Particles
