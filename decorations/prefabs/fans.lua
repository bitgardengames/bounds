return function(Decorations)
    Decorations.register("fan", {
        w = 1,
        h = 1,

        draw = function(x, y, w, h)
            local S = Decorations.style
            local cx = x + w/2
            local cy = y + h/2
            local r = w * 0.42

            local t = love.timer.getTime()
            local angle = t * 1.8

            love.graphics.setColor(S.outline)
            love.graphics.circle("fill", cx, cy, r + 4)

            love.graphics.setColor(S.dark)
            love.graphics.circle("fill", cx, cy, r)

            love.graphics.setColor(S.metal)
            love.graphics.push()
            love.graphics.translate(cx, cy)
            love.graphics.rotate(angle)

            for _ = 1, 4 do
                love.graphics.rotate(math.pi * 0.5)
                love.graphics.rectangle("fill", -4, -r + 4, 8, r - 8, 4, 4)
            end

            love.graphics.pop()
        end,
    })

    Decorations.register("fan_large", {
        w = 2,
        h = 2,

        init = function(inst)
            inst.data = {
                fanSpeed = 1.0,
                targetSpeed = 1.0,
                state = "normal",
                stateTimer = 0,
                nextEvent = love.math.random(20, 30) + love.math.random(),
            }
        end,

        update = function(inst, dt)
            local d = inst.data

            if d.state == "normal" then
                d.targetSpeed = 1.0
                d.nextEvent = d.nextEvent - dt
                if d.nextEvent <= 0 then
                    d.state = "wind_down"
                    d.stateTimer = 0
                end

            elseif d.state == "wind_down" then
                d.targetSpeed = 0.0
                if d.fanSpeed <= 0.10 then
                    d.state = "pause"
                    d.stateTimer = 0
                    d.pauseDuration = 10 + love.math.random() * 2.4
                end

            elseif d.state == "pause" then
                d.stateTimer = d.stateTimer + dt
                d.targetSpeed = 0.0
                if d.stateTimer >= d.pauseDuration then
                    d.state = "spin_up"
                    d.stateTimer = 0
                end

            elseif d.state == "spin_up" then
                d.targetSpeed = 1.0
                if d.fanSpeed >= 0.995 then
                    d.state = "normal"
                    d.nextEvent = love.math.random(10, 28)
                end
            end

            local accelRate = 1.25
            local brakeRate = 0.45
            local rate = (d.targetSpeed > d.fanSpeed) and accelRate or brakeRate

            d.fanSpeed = d.fanSpeed + (d.targetSpeed - d.fanSpeed) * (1 - math.exp(-rate * dt))

            if d.fanSpeed < 0 then d.fanSpeed = 0 end
            if d.fanSpeed > 1 then d.fanSpeed = 1 end

            d.angle = (d.angle or 0) + dt * (1.8 * d.fanSpeed)

            if d.angle > math.pi * 2 then
                d.angle = d.angle - math.pi * 2
            end
        end,

        draw = function(x, y, w, h, inst)
            local S  = Decorations.style
            local cx = x + w/2
            local cy = y + h/2
            local d  = inst.data

            local inset = 8
            local hx = x + inset
            local hy = y + inset
            local hw = w - inset * 2
            local hh = h - inset * 2

            local housingRadius = 10

            love.graphics.setColor(S.outline)
            love.graphics.rectangle(
                "fill",
                hx - 4, hy - 4,
                hw + 8, hh + 8,
                housingRadius + 6, housingRadius + 6
            )

            love.graphics.setColor(S.metal)
            love.graphics.rectangle(
                "fill",
                hx, hy,
                hw, hh,
                housingRadius, housingRadius
            )

            love.graphics.setColor(S.dark)
            local boltR = 3

            local bx1 = hx + 10
            local bx2 = hx + hw - 10
            local by1 = hy + 10
            local by2 = hy + hh - 10

            love.graphics.circle("fill", bx1, by1, boltR)
            love.graphics.circle("fill", bx2, by1, boltR)
            love.graphics.circle("fill", bx1, by2, boltR)
            love.graphics.circle("fill", bx2, by2, boltR)

            local cavityOuterR = hw * 0.42

            love.graphics.setColor(S.outline)
            love.graphics.setLineWidth(4)
            love.graphics.circle("line", cx, cy, cavityOuterR)

            local cavityInnerR = cavityOuterR - 2
            love.graphics.setColor(S.dark)
            love.graphics.circle("fill", cx, cy, cavityInnerR)

            local angle = d.angle or 0

            love.graphics.push()
            love.graphics.translate(cx, cy)
            love.graphics.rotate(angle)

            local bladeW = 8
            local bladeL = cavityInnerR - 4

            love.graphics.setColor(S.metal)
            for _ = 1, 4 do
                love.graphics.rotate(math.pi * 0.5)
                love.graphics.rectangle(
                    "fill",
                    -bladeW/2,
                    -bladeL,
                    bladeW,
                    bladeL,
                    4, 4
                )
            end

            love.graphics.pop()

            love.graphics.setColor(S.dark)
            love.graphics.circle("fill", cx, cy, 8)

            love.graphics.setColor(S.metal)
            love.graphics.circle("fill", cx, cy, 4)
        end,
    })
end
