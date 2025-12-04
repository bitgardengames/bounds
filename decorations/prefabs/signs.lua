return function(Decorations)
    Decorations.register("sign", {
        w = 2,   -- now explicitly 2 tiles wide
        h = 1,   -- explicitly 1 tile tall

        init = function(inst)
            inst.data.text = inst.data.text or ""
            inst.data.font = love.graphics.newFont("fonts/Nunito-Bold.ttf", 22)
        end,

        draw = function(x, y, w, h, inst)
            local S = Decorations.style
            local text = inst.data.text or "SIGN"
            local font = inst.data.font
            love.graphics.setFont(font)

            ----------------------------------------------------------
            -- CONSTANT SIGN GEOMETRY
            ----------------------------------------------------------
            local inset = 8         -- shrink 8px on all sides
            local outline = 4
            local radius = 8

            -- Final box size after inset
            local boxW = w - inset * 2
            local boxH = h - inset * 2

            -- Final box position
            local boxX = x + inset
            local boxY = y + inset

            ----------------------------------------------------------
            -- TEXT MEASUREMENT (centered inside fixed box)
            ----------------------------------------------------------
            local tw = font:getWidth(text)
            local th = font:getHeight()

            local textX = boxX + (boxW - tw) * 0.5
            local textY = boxY + (boxH - th) * 0.5

            ----------------------------------------------------------
            -- DRAW: OUTLINE
            ----------------------------------------------------------
            love.graphics.setColor(S.dark)
            love.graphics.rectangle(
                "fill",
                boxX - outline,
                boxY - outline,
                boxW + outline * 2,
                boxH + outline * 2,
                radius + outline,
                radius + outline
            )

            ----------------------------------------------------------
            -- DRAW: PANEL FILL
            ----------------------------------------------------------
            love.graphics.setColor(S.panel)
            love.graphics.rectangle(
                "fill",
                boxX,
                boxY,
                boxW,
                boxH,
                radius, radius
            )

            ----------------------------------------------------------
            -- DRAW: TEXT
            ----------------------------------------------------------
            love.graphics.setColor(S.dark)
            love.graphics.print(text, textX, textY)
        end
    })
end