return function(Decorations)
    local Particles = Decorations.Particles

    local function emitSteamBurst(x, y)
        local count = 3 + math.random(2)

        for _ = 1, count do
            local drift  = (love.math.random() - 0.5) * 10
            local upward = -32 - love.math.random() * 26
            local r = 3.5 + love.math.random() * 2.0
            local life  = 0.34 + love.math.random() * 0.18
            local alpha = 0.10 + love.math.random() * 0.08

            Particles.steam(
                x + (love.math.random()-0.5)*2,
                y + (love.math.random()-0.5)*2,
                drift * 0.25,
                upward,
                r,
                life,
                {1,1,1,alpha}
            )
        end
    end

    Decorations.register("pipe_big_steamvent_burst", {
        w = 1, h = 1,

        init = function(inst, entry)
            inst.data.active = not (entry and entry.active == false)
            inst.data.timer = 0
            inst.data.nextPuff = 0.8 + love.math.random() * 1.8
        end,

        update = function(inst, dt)
            local d = inst.data
            if d.active == false then
                return
            end

            d.timer = d.timer + dt

            if d.timer >= d.nextPuff then
                d.timer = 0
                d.nextPuff = 0.8 + love.math.random() * 1.8

                local cx = inst.x + inst.w * 0.5
                local cy = inst.y + inst.h * 0.5

                emitSteamBurst(cx, cy)
            end
        end,

        draw = function(x, y, w, h)
            local S = Decorations.style

            local pipeFill = 16
            local O = 4
            local thick = pipeFill + O*2
            local cy = y + h/2 - thick/2

            love.graphics.setColor(S.outline)
            love.graphics.rectangle("fill", x, cy, w, thick)

            love.graphics.setColor(S.metal)
            love.graphics.rectangle("fill", x, cy + O, w, pipeFill)

            local ventW = w * 0.80
            local ventH = 28
            local vx = x + w/2 - ventW/2
            local vy = cy + thick/2 - ventH/2
            local r = 6

            love.graphics.setColor(S.outline)
            love.graphics.rectangle("fill", vx - 4, vy - 4,
                ventW + 8, ventH + 8, r + 3, r + 3)

            love.graphics.setColor(S.metal)
            love.graphics.rectangle("fill", vx, vy,
                ventW, ventH, r, r)

            love.graphics.setColor(S.dark)
            local slats = 3
            local slatH = 4

            local totalSlatHeight = slats * slatH
            local remaining = ventH - totalSlatHeight
            local gap = remaining / (slats + 1)

            for i = 1, slats do
                local sy = vy + gap*i + slatH*(i-1)

                love.graphics.rectangle("fill",
                    vx + 4, sy,
                    ventW - 8, slatH,
                    2, 2
                )
            end
        end,
    })
end
