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
end
