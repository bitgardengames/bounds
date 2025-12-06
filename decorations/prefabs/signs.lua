local Theme = require("theme")
local S = Theme.decorations

return function(Decorations)
    Decorations.register("sign", {
        w = 2,   -- now explicitly 2 tiles wide
        h = 1,   -- explicitly 1 tile tall

        init = function(inst)
            inst.data.text = inst.data.text or ""
            inst.data.font = love.graphics.newFont("fonts/Nunito-Bold.ttf", 24)
        end,

        draw = function(x, y, w, h, inst)
            local text = inst.data.text or "SIGN"
            local font = inst.data.font
            love.graphics.setFont(font)

            ----------------------------------------------------------
            -- CONSTANT SIGN GEOMETRY
            ----------------------------------------------------------
            local inset = 4         -- shrink 8px on all sides
            local outline = 4
            local radius = 6

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
            love.graphics.setColor(S.signText)
            love.graphics.print(text, textX, textY)
        end
    })

	Decorations.register("hazard_triangle", {
		w = 1,
		h = 1,

		draw = function(x, y, w, h)
			local outline = 4
			local radius  = 10

			local cx = x + w/2
			local cy = y + h/2

			-- Triangle points
			local top    = {cx, y + 8}
			local left   = {x + 8, y + h - 8}
			local right  = {x + w - 8, y + h - 8}

			----------------------------------------------------------
			-- OUTLINE
			----------------------------------------------------------
			love.graphics.setColor(0,0,0,1)
			love.graphics.setLineWidth(outline)
			love.graphics.setLineJoin("bevel") -- rounded-ish on triangles
			love.graphics.polygon("fill",
				top[1], top[2],
				left[1], left[2],
				right[1], right[2]
			)

			----------------------------------------------------------
			-- FILL
			----------------------------------------------------------
			love.graphics.setColor(0.87, 0.82, 0.53)
			love.graphics.polygon("fill",
				top[1],     top[2]     + outline,
				left[1] + outline*0.6, left[2] - outline,
				right[1]- outline*0.6, right[2] - outline
			)
		end
	})

	Decorations.register("hazard_electric", {
		w = 1,
		h = 1,

		draw = function(x, y, w, h)
			local outline = 4

			local cx = x + w/2
			local cy = y + h/2

			----------------------------------------------------------
			-- BACKING TRIANGLE (same as hazard_triangle)
			----------------------------------------------------------
			local top    = {cx, y + 8}
			local left   = {x + 8, y + h - 8}
			local right  = {x + w - 8, y + h - 8}

			-- outline
			love.graphics.setColor(0,0,0,1)
			love.graphics.polygon("fill",
				top[1], top[2],
				left[1], left[2],
				right[1], right[2]
			)

			-- fill
			love.graphics.setColor(0.87, 0.82, 0.53)
			love.graphics.polygon("fill",
				top[1], top[2] + outline,
				left[1] + outline*0.6, left[2] - outline,
				right[1] - outline*0.6, right[2] - outline
			)

			----------------------------------------------------------
			-- ROUNDED BOLT ICON
			----------------------------------------------------------
			love.graphics.setColor(0,0,0,1)

			-- bolt path (rounded zig-zag)
			local bolt = {
				cx - 6, cy - 10,
				cx - 2, cy - 2,
				cx - 10, cy - 2,
				cx + 2, cy + 10,
				cx - 2, cy + 2,
				cx + 10, cy + 2
			}

			love.graphics.setLineWidth(outline)
			love.graphics.setLineJoin("bevel")
			love.graphics.line(bolt)
		end
	})
end