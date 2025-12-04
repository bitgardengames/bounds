return function(Decorations)
    Decorations.register("light", {
        w = 0.5,
        h = 0.5,

        draw = function(x, y, w, h)
            local cx = x + w/2
            local cy = y + h/2
            local r = w * 0.4

            love.graphics.setColor(0,0,0)
            love.graphics.circle("fill", cx, cy, r+3)

            local t = love.timer.getTime()
            local pulse = (math.sin(t*4)+1)*0.5 * 0.15

            love.graphics.setColor(1,1,0.85, 0.85 + pulse)
            love.graphics.circle("fill", cx, cy, r)
        end,
    })
end
