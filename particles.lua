--------------------------------------------------------------
-- PARTICLE SYSTEM MODULE
-- Cute circular puffs for jumps / landings / wall slides, etc.
--------------------------------------------------------------

local particles = {}

local Particles = {}

local function smoothstep(t)
    return t * t * (3 - 2 * t)
end

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
        gravity = 400,
    })
end
-- From original file:

--------------------------------------------------------------
-- FLOATY PUFF (no gravity, soft easing)
--------------------------------------------------------------
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
        softFade = true,
    })
end
-- From original file:

--------------------------------------------------------------
-- BRIGHT SPARKLE (no gravity, quick fade)
--------------------------------------------------------------
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
-- From original file:

--------------------------------------------------------------
-- DIAMOND SHARD (soft fade, gravity, spinning)
--------------------------------------------------------------
function Particles.shard(x, y, vx, vy, size, life, color)
    color = color or {1, 1, 1, 1}

    table.insert(particles, {
        x = x, y = y,
        vx = vx or 0,
        vy = vy or 0,
        r  = size or 5,
        life = life or 0.45,
        maxLife = life or 0.45,
        color = color,
        gravity = 70,
        softFade = true,
        shape = "diamond",
        rotation = math.random() * math.pi * 2,
        spin = (math.random() - 0.5) * 6,
    })
end
-- From original file:

--------------------------------------------------------------
-- WALL SLIDE DUST (soft fade, light downward gravity)
--------------------------------------------------------------
function Particles.wallDust(x, y, vx, vy, radius, life, color)
    color = color or {1,1,1,1}

    table.insert(particles, {
        x = x, y = y,
        vx = vx or 0,
        vy = vy or 0,
        r  = radius or 3,
        life = life or 0.25,
        maxLife = life or 0.25,
        color = color,
        gravity = 40,
        softFade = true,
    })
end
-- From original file:

--------------------------------------------------------------
-- NEW: STEAM PARTICLE TYPE (billows, grows, soft fade)
--------------------------------------------------------------
function Particles.steam(x, y, vx, vy, radius, life, color)
    color = color or {1,1,1,0.20}

    table.insert(particles, {
        x = x, y = y,
        vx = vx or 0,
        vy = vy or 0,
        r  = radius or 6,
        life    = life or 0.9,
        maxLife = life or 0.9,
        color   = color,
        gravity = 0,
        steam   = true,   -- <--- important flag
    })
end

--------------------------------------------------------------
-- SLEEP BUBBLES (soft grow + fade, gentle drift)
--------------------------------------------------------------
function Particles.sleepBubble(x, y, vx, vy, radius, life, color)
    color = color or {0.85, 0.95, 1.0, 1}

    table.insert(particles, {
        x = x, y = y,
        vx = vx or 18,
        vy = vy or -28,
        r  = radius or 5.5,
        life    = life or 1.45,
        maxLife = life or 1.45,
        color   = color,
        gravity = -20,
        sleepBubble = true,
    })
end

--------------------------------------------------------------
-- UPDATE
--------------------------------------------------------------
function Particles.update(dt)
    for i = #particles, 1, -1 do
        local p = particles[i]

        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vy = p.vy + p.gravity * dt

        if p.rotation then
            p.rotation = p.rotation + (p.spin or 0) * dt
        end

        p.life = p.life - dt
        if p.life <= 0 then
            particles[i] = particles[#particles]
            particles[#particles] = nil
        end
    end
end
-- From original file:

--------------------------------------------------------------
-- DRAW
--------------------------------------------------------------
function Particles.draw()
    for _, p in ipairs(particles) do
        local t = p.life / p.maxLife

        ----------------------------------------------------------
        -- SPECIAL STEAM LOGIC (the big fix!)
        ----------------------------------------------------------
        if p.steam then
            -- steam grows as it fades
            local alpha = t ^ 1.4
            local size  = p.r * (1.0 + (1 - t) * 1.4)

            love.graphics.setColor(
                p.color[1], p.color[2], p.color[3],
                (p.color[4] or 1) * alpha
            )

            love.graphics.circle("fill", p.x, p.y, size)
        elseif p.sleepBubble then
            local progress = math.min(1, math.max(0, 1 - t))

            local grow = smoothstep(math.min(progress / 0.18, 1))
            local fadeOutStart = 0.68
            local fade
            if progress < fadeOutStart then
                fade = smoothstep(progress / fadeOutStart)
            else
                fade = 1 - smoothstep((progress - fadeOutStart) / (1 - fadeOutStart))
            end

            local shrinkStart = 0.72
            local shrink = 1
            if progress > shrinkStart then
                shrink = 1 - smoothstep((progress - shrinkStart) / (1 - shrinkStart))
            end

            local size = p.r * grow * shrink

            love.graphics.setColor(
                p.color[1], p.color[2], p.color[3],
                (p.color[4] or 1) * fade
            )

            love.graphics.circle("fill", p.x, p.y, size)
        else
            ------------------------------------------------------
            -- ORIGINAL SYSTEM (unchanged)
            ------------------------------------------------------
            local alpha = p.softFade and (t * t) or t
            local size  = p.softFade and (p.r * (0.4 + 0.6 * t))
                                          or (p.r * t)

            love.graphics.setColor(
                p.color[1], p.color[2], p.color[3],
                (p.color[4] or 1) * alpha
            )

            if p.shape == "diamond" then
                love.graphics.push()
                love.graphics.translate(p.x, p.y)
                love.graphics.rotate((p.rotation or 0) + math.pi/4)
                local side = size * 1.6
                local radius = side * 0.22
                love.graphics.rectangle("fill",
                    -side/2, -side/2, side, side, radius, radius)
                love.graphics.pop()
            else
                love.graphics.circle("fill", p.x, p.y, size)
            end
        end
    end
end

return Particles