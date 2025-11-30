----------------------------------------------------------
-- Collectible Orbs / Diamonds
----------------------------------------------------------

local Particles = require("particles")

local Collectible = {
    list = {},
}

----------------------------------------------------------
-- API: Collectible.spawn(x, y)
----------------------------------------------------------
function Collectible.spawn(x, y)
    table.insert(Collectible.list, {
        x = x,
        y = y,
        r = 10,              -- was 10, slightly bigger now
        picked = false,
        t = 0,
        pop = 0,
        burstT = 0,
    })
end

----------------------------------------------------------
-- UPDATE
----------------------------------------------------------
function Collectible.update(dt, player)
    for i = #Collectible.list, 1, -1 do
        local c = Collectible.list[i]

        c.t = c.t + dt

        if not c.picked then
            -- bobbing amplitude & shine offset
            c.bob = math.sin(c.t * 3) * 2
            c.shine = (math.sin(c.t * 4) * 0.5 + 0.5)

            -- Pickup check (simple circle check)
            local cx = c.x
            local cy = c.y + c.bob
            local px = player.x + player.w/2
            local py = player.y + player.h/2

            local dist = ((cx - px)^2 + (cy - py)^2)^0.5
            if dist < c.r + player.radius then
                c.picked = true
                c.pop = 1.0
                c.burstT = 0

                -- pickup puff burst
                for k=1,6 do
                    Particles.puff(
                        cx + (math.random()-0.5)*4,
                        cy + (math.random()-0.5)*4,
                        (math.random()-0.5)*80,
                        -(20 + math.random()*40),
                        4, 0.3,
                        {1,1,1,1}
                    )
                end

                -- diamond shards that match the collectible look
                for k=1,12 do
                    local angle = math.random() * math.pi * 2
                    local speed = 80 + math.random()*90
                    Particles.shard(
                        cx,
                        cy,
                        math.cos(angle) * speed,
                        math.sin(angle) * speed,
                        5 + math.random()*3,
                        0.45 + math.random()*0.25,
                        {1, 1, 1, 1}
                    )
                end
            end
        else
            -- pickup pop shrinking
            c.pop = c.pop - dt * 3
            c.burstT = c.burstT + dt
            if c.pop <= 0 then
                table.remove(Collectible.list, i)
            end
        end
    end
end

----------------------------------------------------------
-- DRAW
----------------------------------------------------------
function Collectible.draw()
    for _, c in ipairs(Collectible.list) do
        local scale    = 1 + (c.shine or 0) * 0.18
        local popScale = c.picked and (0.7 + c.pop * 0.4) or 1
        local wobble   = math.sin((c.t or 0) * 2.6) * 0.09

        local baseR = c.r or 12                 -- slightly larger base
        local r     = baseR * scale * popScale
        local bobY  = c.bob or 0

        local cx = c.x
        local cy = c.y + bobY

        -- side length of the square that we rotate into a diamond
        local side         = r * 1.5
        local outline      = 4.25               -- 3px outline after rotation
        local cornerRadius = side * 0.15        -- roundness factor

        love.graphics.push()
        love.graphics.translate(cx, cy)
        love.graphics.rotate(math.pi / 4 + wobble + (c.picked and (1 - math.max(c.pop, 0)) * 0.4 or 0))

        -- OUTLINE (black, slightly larger rounded rectangle)
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle(
            "fill",
            -side/2 - outline,
            -side/2 - outline,
            side + outline*2,
            side + outline*2,
            cornerRadius + outline,
            cornerRadius + outline
        )

        -- FILL (white, slightly smaller rounded rectangle)
        love.graphics.setColor(1, 1, 1, 0.98)
        love.graphics.rectangle(
            "fill",
            -side/2,
            -side/2,
            side,
            side,
            cornerRadius,
            cornerRadius
        )

        -- SHINE (small circle toward the “top” of the diamond)
        love.graphics.setColor(1, 1, 1, 0.75)
        love.graphics.circle("fill", 0, -side * 0.25, r * 0.25)

        love.graphics.pop()

        if c.picked then
            -- expanding ring flash for extra juice
            local ringT = 1 - math.max(c.pop, 0)
            local ringAlpha = math.max(0, c.pop)
            love.graphics.setColor(1, 0.92, 0.7, ringAlpha * 0.9)
            love.graphics.setLineWidth(3)
            love.graphics.circle(
                "line",
                cx,
                cy,
                baseR * (1.2 + ringT * 1.8)
            )
        end
    end
end

return Collectible
