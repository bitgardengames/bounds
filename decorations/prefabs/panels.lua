local Theme = require("theme")
local S = Theme.decorations

return function(Decorations)
    Decorations.register("panel", {
        w = 1.5,
        h = 1,

        draw = function(x, y, w, h)
            love.graphics.setColor(S.background)
            love.graphics.rectangle("fill", x-4, y-4, w+8, h+8, 6, 6)

            love.graphics.setColor(S.panel)
            love.graphics.rectangle("fill", x, y, w, h, 4, 4)

            love.graphics.setColor(0, 0, 0, 0.16)
            for sy = y + 6, y + h - 6, 8 do
                love.graphics.rectangle("fill", x + 6, sy, w - 12, 3, 2, 2)
            end
        end,
    })

    Decorations.register("panel_tall", {
        w = 1,
        h = 2,

        draw = function(x, y, w, h)
            love.graphics.setColor(S.background)
            love.graphics.rectangle("fill", x + 2, y + 2, w - 4, h - 4)
        end,
    })

    Decorations.register("drop_tube", {
        w = 1,
        h = 2,

        init = function(inst)
            inst.data.phase = 0
        end,

        update = function(inst, dt)
            inst.data.phase = inst.data.phase + dt
        end,

        draw = function(x, y, w, h, inst)
            local t = inst.data.phase

            -- Outer housing
            love.graphics.setColor(S.outline)
            love.graphics.rectangle("fill", x, y, w, h, 8, 8)

            -- Interior cavity
            love.graphics.setColor(S.dark)
            love.graphics.rectangle("fill", x+4, y+4, w-8, h-8, 6, 6)

            -- Glass tube window
            local gx = x + 4
            local gy = y + 4
            local gw = w - 8
            local gh = h - 8

            love.graphics.setColor(0.85,0.9,1,0.18)
            love.graphics.rectangle("fill", gx, gy, gw, gh, 6, 6)

            -- Slight moving refraction stripe
            local stripeY = gy + (math.sin(t*1.5)*0.5+0.5)*(gh-12)
            love.graphics.setColor(1,1,1,0.10)
            love.graphics.rectangle("fill", gx+2, stripeY, gw-4, 8, 4, 4)
        end,
    })

    Decorations.register("wall_gears", {
        w = 2,
        h = 2,

        init = function(inst)
            inst.data.angleA = 0
            inst.data.angleB = 0
            inst.data.speedA = 0.30      -- slow continuous spin
            inst.data.speedB = -0.22     -- counterspin

            inst.data.clunk = inst.data.clunk or false
            inst.data.clunkTimer = 0
        end,

        update = function(inst, dt)
            local d = inst.data

            if d.clunk then
                d.clunkTimer = d.clunkTimer - dt
                if d.clunkTimer <= 0 then
                    d.clunkTimer = 2 + math.random()*3   -- random clunk
                    d.speedA = 0.10
                    d.speedB = -0.08
                end
            end

            d.angleA = (d.angleA + dt * d.speedA) % (math.pi*2)
            d.angleB = (d.angleB + dt * d.speedB) % (math.pi*2)
        end,

        draw = function(x, y, w, h, inst)
            local d = inst.data
            local cavity = 8
            local boxX = x + cavity
            local boxY = y + cavity
            local boxW = w - cavity*2
            local boxH = h - cavity*2

            -- Outer frame
            love.graphics.setColor(S.outline)
            love.graphics.rectangle("fill", x, y, w, h, 6, 6)

            -- Inner dark cavity
            love.graphics.setColor(S.dark)
            love.graphics.rectangle("fill", boxX, boxY, boxW, boxH, 6, 6)

            local cx1 = boxX + boxW*0.35
            local cy1 = boxY + boxH*0.55
            local cx2 = boxX + boxW*0.65
            local cy2 = boxY + boxH*0.40

            local r1 = math.min(boxW, boxH) * 0.28
            local r2 = math.min(boxW, boxH) * 0.20

            -- Gear drawing helper
            local function drawGear(cx, cy, r, teeth, ang)
                love.graphics.push()
                love.graphics.translate(cx, cy)
                love.graphics.rotate(ang)

                love.graphics.setColor(S.metal)
                for i = 1, teeth do
                    love.graphics.rotate((math.pi*2)/teeth)
                    love.graphics.rectangle("fill", r-6, -4, 10, 8, 3, 3)
                end

                -- center hub
                love.graphics.setColor(S.outline)
                love.graphics.circle("fill", 0, 0, r*0.42)
                love.graphics.setColor(S.metal)
                love.graphics.circle("fill", 0, 0, r*0.28)

                love.graphics.pop()
            end

            drawGear(cx1, cy1, r1, 12, d.angleA)
            drawGear(cx2, cy2, r2, 10, d.angleB)
        end,
    })
end
