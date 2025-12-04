return function(Decorations)
    Decorations.register("pipe_h", {
        w = 1, h = 1,

        draw = function(x, y, w, h)
            local S = Decorations.style
            local pipeFill = 4
            local O = 4

            local thick = pipeFill + O*2
            local cy = y + h/2 - thick/2

            love.graphics.setColor(S.outline)
            love.graphics.rectangle("fill", x, cy, w, thick)

            love.graphics.setColor(S.metal)
            love.graphics.rectangle("fill",
                x,
                cy + O,
                w,
                pipeFill
            )
        end,
    })

    Decorations.register("pipe_v", {
        w = 1, h = 1,

        draw = function(x, y, w, h)
            local S = Decorations.style
            local pipeFill = 4
            local O = 4

            local thick = pipeFill + O*2
            local cx = x + w/2 - thick/2

            love.graphics.setColor(S.outline)
            love.graphics.rectangle("fill", cx, y, thick, h)

            love.graphics.setColor(S.metal)
            love.graphics.rectangle("fill",
                cx + O,
                y,
                pipeFill,
                h
            )
        end,
    })

    Decorations.register("pipe_junctionbox", {
        w = 1,
        h = 1,

        init = function(inst)
            inst.data.active = false
        end,

        draw = function(x, y, w, h, inst)
            local S = Decorations.style
            local active = inst and inst.data and inst.data.active

            local O = 4
            local boxH = 32
            local boxY = y + h/2 - boxH/2
            local radius = 8

            love.graphics.setColor(S.outline)
            love.graphics.rectangle(
                "fill",
                x,
                boxY,
                w,
                boxH,
                radius, radius
            )

            love.graphics.setColor(S.metal)
            love.graphics.rectangle(
                "fill",
                x + O,
                boxY + O,
                w - O*2,
                boxH - O*2,
                radius - 4, radius - 4
            )

            local lightW = 20
            local lightH = 6
            local lightX = x + w/2 - lightW/2
            local lightY = boxY + boxH/2 - lightH/2

            love.graphics.setColor(S.outline)
            love.graphics.rectangle(
                "fill",
                lightX - 4,
                lightY - 4,
                lightW + 8,
                lightH + 8,
                3, 3
            )

            if active then
                love.graphics.setColor(0.45, 1.0, 0.45, 0.95)
            else
                love.graphics.setColor(1.0, 0.35, 0.35, 0.95)
            end
            love.graphics.rectangle(
                "fill",
                lightX,
                lightY,
                lightW,
                lightH,
                3, 3
            )
        end,
    })

    local function drawPipeCurve(x, y, w, h, rotate)
        local S = Decorations.style
        local pipeFill = 4
        local O = 4
        local thick = pipeFill + O*2
        local R = w/2

        love.graphics.push()
        love.graphics.translate(x + w/2, y + h/2)
        love.graphics.rotate(rotate)
        love.graphics.translate(-w/2, -h/2)

        love.graphics.setColor(S.outline)
        love.graphics.setLineWidth(thick)
        love.graphics.arc("line", "open",
            w, h,
            R,
            math.pi,
            math.pi*1.5
        )

        love.graphics.setColor(S.metal)
        love.graphics.setLineWidth(pipeFill)
        love.graphics.arc("line", "open",
            w, h,
            R,
            math.pi,
            math.pi*1.5
        )

        love.graphics.pop()
    end

    Decorations.register("pipe_curve_tr", {
        w = 1, h = 1,
        draw = function(x,y,w,h)
            drawPipeCurve(x,y,w,h, 0)
        end,
    })

    Decorations.register("pipe_curve_tl", {
        w = 1, h = 1,
        draw = function(x,y,w,h)
            drawPipeCurve(x,y,w,h, math.pi*0.5)
        end,
    })

    Decorations.register("pipe_curve_bl", {
        w = 1, h = 1,
        draw = function(x,y,w,h)
            drawPipeCurve(x,y,w,h, math.pi)
        end,
    })

    Decorations.register("pipe_curve_br", {
        w = 1, h = 1,
        draw = function(x,y,w,h)
            drawPipeCurve(x,y,w,h, math.pi*1.5)
        end,
    })

    Decorations.register("pipe_big_h", {
        w = 1, h = 1,

        draw = function(x, y, w, h)
            local S = Decorations.style

            local pipeFill = 16
            local O = 4
            local thick = pipeFill + O*2
            local cy = y + h/2 - thick/2

            love.graphics.setColor(S.outline)
            love.graphics.rectangle("fill", x, cy, w, thick)

            love.graphics.setColor(S.metal)
            love.graphics.rectangle("fill",
                x,
                cy + O,
                w,
                pipeFill
            )
        end,
    })

    Decorations.register("pipe_big_v", {
        w = 1, h = 1,

        draw = function(x, y, w, h)
            local S = Decorations.style

            local pipeFill = 16
            local O = 4
            local thick = pipeFill + O*2
            local cx = x + w/2 - thick/2

            love.graphics.setColor(S.outline)
            love.graphics.rectangle("fill", cx, y, thick, h)

            love.graphics.setColor(S.metal)
            love.graphics.rectangle("fill",
                cx + O,
                y,
                pipeFill,
                h
            )
        end,
    })

    local function drawBigPipeCurve(x, y, w, h, rotate)
        local S = Decorations.style

        local pipeFill = 16
        local O = 4
        local thick = pipeFill + O*2
        local R = w/2

        love.graphics.push()
        love.graphics.translate(x + w/2, y + h/2)
        love.graphics.rotate(rotate)
        love.graphics.translate(-w/2, -h/2)

        love.graphics.setColor(S.outline)
        love.graphics.setLineWidth(thick)
        love.graphics.arc("line", "open",
            w, h,
            R,
            math.pi,
            math.pi * 1.5
        )

        love.graphics.setColor(S.metal)
        love.graphics.setLineWidth(pipeFill)
        love.graphics.arc("line", "open",
            w, h,
            R,
            math.pi,
            math.pi * 1.5
        )

        love.graphics.pop()
    end

    Decorations.register("pipe_big_curve_tr", {
        w = 1, h = 1,
        draw = function(x,y,w,h)
            drawBigPipeCurve(x,y,w,h, 0)
        end,
    })

    Decorations.register("pipe_big_curve_tl", {
        w = 1, h = 1,
        draw = function(x,y,w,h)
            drawBigPipeCurve(x,y,w,h, math.pi * 0.5)
        end,
    })

    Decorations.register("pipe_big_curve_bl", {
        w = 1, h = 1,
        draw = function(x,y,w,h)
            drawBigPipeCurve(x,y,w,h, math.pi)
        end,
    })

    Decorations.register("pipe_big_curve_br", {
        w = 1, h = 1,
        draw = function(x,y,w,h)
            drawBigPipeCurve(x,y,w,h, math.pi * 1.5)
        end,
    })

	local pipeFill = 16
	local O = 4
	local thick = pipeFill + O*2   -- 24px

	Decorations.register("pipe_big_t_up", {
		w = 1, h = 1,

		draw = function(x, y, w, h)
			local S = Decorations.style

			local pipeFill = 16
			local O = 4
			local thick = pipeFill + O*2

			local cx = x + w/2 - thick/2         -- vertical trunk (centered)
			local cy = y + h/2 - thick/2         -- horizontal branch (centered)

			-- OUTLINE — vertical trunk
			love.graphics.setColor(S.outline)
			love.graphics.rectangle("fill", cx, y, thick, h)

			-- OUTLINE — horizontal branch
			love.graphics.rectangle("fill", x, cy, w, thick)

			-- FILL — vertical trunk interior
			love.graphics.setColor(S.metal)
			love.graphics.rectangle("fill",
				cx + O,
				y,
				pipeFill,
				h
			)

			-- FILL — horizontal branch interior
			love.graphics.rectangle("fill",
				x,
				cy + O,
				w,
				pipeFill
			)
		end
	})

	Decorations.register("pipe_big_t_down", {
		w = 1, h = 1,

		draw = function(x, y, w, h)
			local S = Decorations.style

			local pipeFill = 16
			local O = 4
			local thick = pipeFill + O*2

			local cx = x + w/2 - thick/2
			local cy = y + h/2 - thick/2

			-- Same geometry as T_up (symmetrical)
			love.graphics.setColor(S.outline)
			love.graphics.rectangle("fill", cx, y, thick, h)
			love.graphics.rectangle("fill", x, cy, w, thick)

			love.graphics.setColor(S.metal)
			love.graphics.rectangle("fill",
				cx + O, y,
				pipeFill, h
			)

			love.graphics.rectangle("fill",
				x, cy + O,
				w, pipeFill
			)
		end
	})

	Decorations.register("pipe_big_t_right", {
		w = 1, h = 1,

		draw = function(x, y, w, h)
			local S = Decorations.style

			local pipeFill = 16
			local O = 4
			local thick = pipeFill + O*2

			local cy = y + h/2 - thick/2     -- horizontal pipe center
			local cx = x + w/2 - thick/2     -- vertical pipe center

			love.graphics.setColor(S.outline)
			-- horizontal trunk
			love.graphics.rectangle("fill", x, cy, w, thick)
			-- vertical branch
			love.graphics.rectangle("fill", cx, y, thick, h)

			love.graphics.setColor(S.metal)
			-- horizontal interior
			love.graphics.rectangle("fill", x, cy + O, w, pipeFill)
			-- vertical interior
			love.graphics.rectangle("fill", cx + O, y, pipeFill, h)
		end
	})

	Decorations.register("pipe_big_t_left", {
		w = 1, h = 1,

		draw = function(x, y, w, h)
			local S = Decorations.style

			local pipeFill = 16
			local O = 4
			local thick = pipeFill + O*2

			local cy = y + h/2 - thick/2
			local cx = x + w/2 - thick/2

			love.graphics.setColor(S.outline)
			love.graphics.rectangle("fill", x, cy, w, thick)
			love.graphics.rectangle("fill", cx, y, thick, h)

			love.graphics.setColor(S.metal)
			love.graphics.rectangle("fill", x, cy + O, w, pipeFill)
			love.graphics.rectangle("fill", cx + O, y, pipeFill, h)
		end
	})
end
