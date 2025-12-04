return function(Decorations)
    Decorations.register("vent", {
        w = 1,
        h = 1,

        draw = function(x, y, w, h)
            local S = Decorations.style

            love.graphics.setColor(S.background)
            love.graphics.rectangle("fill", x+2, y+2, w-4, h-4)

            love.graphics.setColor(S.metal)
            love.graphics.rectangle("fill", x + 2, y + 2, w - 4, h - 4)

            love.graphics.setColor(S.dark)

            local slatCount = 4
            local spacing = h / (slatCount + 1)

            for i = 1, slatCount do
                local sy = y + spacing * i - 2
                love.graphics.rectangle("fill", x + 6, sy, w - 12, 4, 2, 2)
            end
        end,
    })

    Decorations.register("vent_round", {
        w = 1,
        h = 1,

        draw = function(x, y, w, h)
            local S  = Decorations.style
            local cx = x + w/2
            local cy = y + h/2
            local r  = w * 0.42

            love.graphics.setColor(S.outline)
            love.graphics.circle("fill", cx, cy, r + 4)

            love.graphics.setColor(S.metal)
            love.graphics.circle("fill", cx, cy, r)

            love.graphics.setColor(S.dark)
            love.graphics.circle("fill", cx, cy, r - 4)

            local slatCount = 3
            local gap = r * 0.32 + 2

            for i = 1, slatCount do
                local offset = (i - math.ceil(slatCount/2)) * gap
                local sy = cy + offset

                love.graphics.setColor(S.metal)
                love.graphics.rectangle(
                    "fill",
                    cx - (r - 2),
                    sy - 2,
                    (r - 2) * 2,
                    4,
                    2, 2
                )
            end
        end,
    })
end
