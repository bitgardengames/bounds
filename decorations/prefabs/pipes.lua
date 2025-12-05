local Theme = require("theme")
local S = Theme.decorations

local pipeFill = 16
local O = 4
local thick = pipeFill + O*2

return function(Decorations)
    Decorations.register("conduit_h", {
        w = 1, h = 1,

        draw = function(x, y, w, h)
            local pipeFill = 4
            local O = 4

            local thick = pipeFill + O*2
            local cy = y + h/2 - thick/2

            love.graphics.setColor(S.outline)
            love.graphics.rectangle("fill", x, cy, w, thick)

            love.graphics.setColor(S.pipe)
            love.graphics.rectangle("fill",
                x,
                cy + O,
                w,
                pipeFill
            )
        end,
    })

    Decorations.register("conduit_v", {
        w = 1, h = 1,

        draw = function(x, y, w, h)
            local pipeFill = 4
            local O = 4

            local thick = pipeFill + O*2
            local cx = x + w/2 - thick/2

            love.graphics.setColor(S.outline)
            love.graphics.rectangle("fill", cx, y, thick, h)

            love.graphics.setColor(S.pipe)
            love.graphics.rectangle("fill",
                cx + O,
                y,
                pipeFill,
                h
            )
        end,
    })

    Decorations.register("conduit_junctionbox", {
        w = 1,
        h = 1,

        init = function(inst)
            inst.data.active = false
        end,

        draw = function(x, y, w, h, inst)
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

            love.graphics.setColor(S.pipe)
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

	Decorations.register("conduit_h_join", {
		w = 1, h = 1,

		draw = function(x, y, w, h)
			local pipeFill = 4
			local O = 4

			local thick = pipeFill + O*2        -- 12px total conduit height
			local cy = y + h/2 - thick/2        -- center Y

			----------------------------------------------------------------
			-- BASE CONDUIT (same as conduit_h)
			----------------------------------------------------------------
			love.graphics.setColor(S.outline)
			love.graphics.rectangle("fill", x, cy, w, thick)

			love.graphics.setColor(S.pipe)
			love.graphics.rectangle("fill",
				x,
				cy + O,
				w,
				pipeFill
			)

			----------------------------------------------------------------
			-- COUPLING BAND (4px larger just like big pipes)
			----------------------------------------------------------------

			-- Outer coupling size
			local joinW = 10                 -- Outer width of the coupling
			local joinFill = joinW - O*2     -- Inner metal fill (2px)

			local joinH = thick + 8          -- 12 + 8 = 20px tall coupling
			local jy = y + h/2 - joinH/2     -- vertically centered
			local jx = x + w/2 - joinW/2     -- horizontally centered

			-- Outline
			love.graphics.setColor(S.outline)
			love.graphics.rectangle("fill",
				jx,
				jy,
				joinW,
				joinH
			)

			-- Inner metal fill
			love.graphics.setColor(S.pipe)
			love.graphics.rectangle("fill",
				jx + O,
				jy + O,
				joinFill,
				joinH - O*2
			)
		end
	})

	Decorations.register("conduit_v_join", {
		w = 1, h = 1,

		draw = function(x, y, w, h)
			local pipeFill = 4
			local O = 4

			local thick = pipeFill + O*2        -- 12px total conduit width
			local cx = x + w/2 - thick/2        -- center X

			----------------------------------------------------------------
			-- BASE CONDUIT (same as conduit_v)
			----------------------------------------------------------------
			love.graphics.setColor(S.outline)
			love.graphics.rectangle("fill",
				cx,
				y,
				thick,
				h
			)

			love.graphics.setColor(S.pipe)
			love.graphics.rectangle("fill",
				cx + O,
				y,
				pipeFill,
				h
			)

			----------------------------------------------------------------
			-- COUPLING BAND (oversized by 4px each side)
			----------------------------------------------------------------

			local joinH = 10                    -- outer coupling height
			local joinFill = joinH - O*2        -- inner fill (2px)

			local joinW = thick + 8             -- 12 + 8 = 20px wide
			local jx = x + w/2 - joinW/2        -- centered horizontally
			local jy = y + h/2 - joinH/2        -- centered vertically

			-- Outline block
			love.graphics.setColor(S.outline)
			love.graphics.rectangle("fill",
				jx,
				jy,
				joinW,
				joinH
			)

			-- Inner fill
			love.graphics.setColor(S.pipe)
			love.graphics.rectangle("fill",
				jx + O,
				jy + O,
				joinW - O*2,
				joinFill
			)
		end
	})

    local function drawPipeCurve(x, y, w, h, rotate)
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

        love.graphics.setColor(S.pipe)
        love.graphics.setLineWidth(pipeFill)
        love.graphics.arc("line", "open",
            w, h,
            R,
            math.pi,
            math.pi*1.5
        )

        love.graphics.pop()
    end

    Decorations.register("conduit_curve_tr", {
        w = 1, h = 1,
        draw = function(x,y,w,h)
            drawPipeCurve(x,y,w,h, 0)
        end,
    })

    Decorations.register("conduit_curve_tl", {
        w = 1, h = 1,
        draw = function(x,y,w,h)
            drawPipeCurve(x,y,w,h, math.pi*0.5)
        end,
    })

    Decorations.register("conduit_curve_bl", {
        w = 1, h = 1,
        draw = function(x,y,w,h)
            drawPipeCurve(x,y,w,h, math.pi)
        end,
    })

    Decorations.register("conduit_curve_br", {
        w = 1, h = 1,
        draw = function(x,y,w,h)
            drawPipeCurve(x,y,w,h, math.pi*1.5)
        end,
    })

    Decorations.register("pipe_big_h", {
        w = 1, h = 1,

        draw = function(x, y, w, h)

            local pipeFill = 16
            local O = 4
            local thick = pipeFill + O*2
            local cy = y + h/2 - thick/2

            love.graphics.setColor(S.outline)
            love.graphics.rectangle("fill", x, cy, w, thick)

            love.graphics.setColor(S.pipe)
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

            local pipeFill = 16
            local O = 4
            local thick = pipeFill + O*2
            local cx = x + w/2 - thick/2

            love.graphics.setColor(S.outline)
            love.graphics.rectangle("fill", cx, y, thick, h)

            love.graphics.setColor(S.pipe)
            love.graphics.rectangle("fill",
                cx + O,
                y,
                pipeFill,
                h
            )
        end,
    })

    local function drawBigPipeCurve(x, y, w, h, rotate)

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

        love.graphics.setColor(S.pipe)
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

	Decorations.register("pipe_big_t_left", {
		w = 1, h = 1,

		draw = function(x, y, w, h)
			local pipeFill = 16
			local O = 4
			local thick = pipeFill + O*2
			local cy = y + h/2 - thick/2
			local cx = x + w/2 - thick/2

			------------------------------------------------------------------
			-- OUTLINE LAYER
			------------------------------------------------------------------
			love.graphics.setColor(S.outline)

			-- Full vertical pipe (same as cross)
			love.graphics.rectangle("fill", cx, y, thick, h)

			-- Half horizontal pipe (LEFT → CENTER only)
			love.graphics.rectangle("fill", x, cy, w/2, thick)

			------------------------------------------------------------------
			-- FILL LAYER
			------------------------------------------------------------------
			love.graphics.setColor(S.pipe)

			-- Vertical fill (same as cross)
			love.graphics.rectangle("fill", cx + O, y, pipeFill, h)

			-- Horizontal fill (LEFT HALF ONLY)
			love.graphics.rectangle("fill", x, cy + O, w/2, pipeFill)
		end
	})

	Decorations.register("pipe_big_t_right", {
		w = 1, h = 1,

		draw = function(x, y, w, h)

			local pipeFill = 16
			local O = 4
			local thick = pipeFill + O*2

			local cy = y + h/2 - thick/2
			local cx = x + w/2 - thick/2

			-----------------------------------------
			-- OUTLINE
			-----------------------------------------
			love.graphics.setColor(S.outline)

			-- Full vertical trunk
			love.graphics.rectangle("fill",
				cx, y,
				thick, h
			)

			-- HALF horizontal pipe (CENTER → RIGHT)
			love.graphics.rectangle("fill",
				x + w/2,   -- start halfway across
				cy,
				w/2,       -- half width
				thick
			)

			-----------------------------------------
			-- FILL
			-----------------------------------------
			love.graphics.setColor(S.pipe)

			-- Vertical fill
			love.graphics.rectangle("fill",
				cx + O, y,
				pipeFill, h
			)

			-- Horizontal fill (right side only)
			love.graphics.rectangle("fill",
				x + w/2,
				cy + O,
				w/2,
				pipeFill
			)
		end
	})

	Decorations.register("pipe_big_t_up", {
		w = 1, h = 1,

		draw = function(x, y, w, h)

			local pipeFill = 16
			local O = 4
			local thick = pipeFill + O*2

			local cy = y + h/2 - thick/2
			local cx = x + w/2 - thick/2

			-----------------------------------------
			-- OUTLINE
			-----------------------------------------
			love.graphics.setColor(S.outline)

			-- Full horizontal trunk
			love.graphics.rectangle("fill",
				x, cy,
				w, thick
			)

			-- HALF vertical pipe (TOP → CENTER)
			love.graphics.rectangle("fill",
				cx,
				y,
				thick,
				h/2
			)

			-----------------------------------------
			-- FILL
			-----------------------------------------
			love.graphics.setColor(S.pipe)

			-- Horizontal fill
			love.graphics.rectangle("fill",
				x,
				cy + O,
				w,
				pipeFill
			)

			-- Vertical fill (top half only)
			love.graphics.rectangle("fill",
				cx + O,
				y,
				pipeFill,
				h/2
			)
		end
	})

	Decorations.register("pipe_big_t_down", {
		w = 1, h = 1,

		draw = function(x, y, w, h)

			local pipeFill = 16
			local O = 4
			local thick = pipeFill + O*2

			local cy = y + h/2 - thick/2
			local cx = x + w/2 - thick/2

			-----------------------------------------
			-- OUTLINE
			-----------------------------------------
			love.graphics.setColor(S.outline)

			-- Full horizontal trunk
			love.graphics.rectangle("fill",
				x, cy,
				w, thick
			)

			-- HALF vertical pipe (CENTER → BOTTOM)
			love.graphics.rectangle("fill",
				cx,
				y + h/2,
				thick,
				h/2
			)

			-----------------------------------------
			-- FILL
			-----------------------------------------
			love.graphics.setColor(S.pipe)

			-- Horizontal fill
			love.graphics.rectangle("fill",
				x,
				cy + O,
				w,
				pipeFill
			)

			-- Vertical fill (bottom half only)
			love.graphics.rectangle("fill",
				cx + O,
				y + h/2,
				pipeFill,
				h/2
			)
		end
	})

	Decorations.register("pipe_big_cross", {
		w = 1, h = 1,

		draw = function(x, y, w, h)

			local pipeFill = 16
			local O = 4
			local thick = pipeFill + O*2

			local cy = y + h/2 - thick/2
			local cx = x + w/2 - thick/2

			love.graphics.setColor(S.outline)
			love.graphics.rectangle("fill", x, cy, w, thick)
			love.graphics.rectangle("fill", cx, y, thick, h)

			love.graphics.setColor(S.pipe)
			love.graphics.rectangle("fill", x, cy + O, w, pipeFill)
			love.graphics.rectangle("fill", cx + O, y, pipeFill, h)
		end
	})

	Decorations.register("pipe_big_h_join", {
		w = 1, h = 1,

		draw = function(x, y, w, h)

			-- PIPE CONSTANTS
			local pipeFill = 16
			local O = 4
			local thick = pipeFill + O*2       -- 24px total pipe height
			local cy = y + h/2 - thick/2       -- pipe vertical center

			----------------------------------------------------------
			-- BASE PIPE (same as pipe_big_h)
			----------------------------------------------------------
			love.graphics.setColor(S.outline)
			love.graphics.rectangle("fill", x, cy, w, thick)

			love.graphics.setColor(S.pipe)
			love.graphics.rectangle("fill",
				x,
				cy + O,
				w,
				pipeFill
			)

			----------------------------------------------------------
			-- JOIN COLLAR / COUPLING (now 4px larger on both sides)
			----------------------------------------------------------

			-- Horizontal width of coupling band
			local joinW = 12                       -- OUTER width
			local joinFill = joinW - O*2           -- INNER width (4px)

			-- NEW: Coupling height (4px above + 4px below pipe)
			local joinH = thick + 8                -- 24 + 8 = 32px

			-- NEW: Vertical anchor of coupling
			local jy = y + h/2 - joinH/2           -- centered on tile

			-- X-position stays centered horizontally
			local jx = x + w/2 - joinW/2

			----------------------------------------------------------
			-- OUTLINE BAND (slightly oversized coupling)
			----------------------------------------------------------
			love.graphics.setColor(S.outline)
			love.graphics.rectangle("fill",
				jx,
				jy,
				joinW,
				joinH
			)

			----------------------------------------------------------
			-- INNER METAL FILL (also oversized)
			----------------------------------------------------------
			love.graphics.setColor(S.pipe)
			love.graphics.rectangle("fill",
				jx + O,
				jy + O,
				joinFill,
				joinH - O*2
			)
		end
	})

	Decorations.register("pipe_big_v_join", {
		w = 1, h = 1,

		draw = function(x, y, w, h)

			-- PIPE CONSTANTS
			local pipeFill = 16
			local O = 4
			local thick = pipeFill + O*2       -- 24px total pipe width
			local cx = x + w/2 - thick/2       -- pipe horizontal center

			----------------------------------------------------------
			-- BASE PIPE (same as pipe_big_v)
			----------------------------------------------------------
			love.graphics.setColor(S.outline)
			love.graphics.rectangle("fill",
				cx,
				y,
				thick,
				h
			)

			love.graphics.setColor(S.pipe)
			love.graphics.rectangle("fill",
				cx + O,
				y,
				pipeFill,
				h
			)

			----------------------------------------------------------
			-- JOIN COLLAR / COUPLING (4px bigger on left & right)
			----------------------------------------------------------

			-- Vertical height of coupling band
			local joinH = 12                       -- OUTER height (same idea as joinW in horizontal)
			local joinFill = joinH - O*2           -- INNER fill height (4px)

			-- NEW: Coupling width (4px + 4px larger than pipe)
			local joinW = thick + 8                -- 24 + 8 = 32px

			-- NEW: Horizontal anchor of coupling (centered)
			local jx = x + w/2 - joinW/2

			-- Vertical anchor (centered on tile)
			local jy = y + h/2 - joinH/2

			----------------------------------------------------------
			-- OUTLINE BAND (oversized coupling)
			----------------------------------------------------------
			love.graphics.setColor(S.outline)
			love.graphics.rectangle("fill",
				jx,
				jy,
				joinW,
				joinH
			)

			----------------------------------------------------------
			-- INNER METAL FILL
			----------------------------------------------------------
			love.graphics.setColor(S.pipe)
			love.graphics.rectangle("fill",
				jx + O,
				jy + O,
				joinW - O*2,
				joinFill
			)
		end
	})
end
