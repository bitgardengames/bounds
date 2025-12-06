local Theme = require("theme")
local S = Theme.decorations

local pipeFill = 16
local O = 4
local thick = pipeFill + O*2

return function(Decorations)
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

    Decorations.register("pipe_pump", {
        w = 2,
        h = 1,

        init = function(inst)
            inst.data.t = 0
        end,

        update = function(inst, dt)
            inst.data.t = inst.data.t + dt
        end,

        draw = function(x, y, w, h, inst)
            local t = inst.data.t

            -- Frame
            love.graphics.setColor(S.outline)
            love.graphics.rectangle("fill", x, y, w, h, 6, 6)

            love.graphics.setColor(S.metal)
            love.graphics.rectangle("fill", x+4, y+4, w-8, h-8, 5, 5)

            -- Pistons
            local cx1 = x + w*0.33
            local cx2 = x + w*0.66
            local cy  = y + h*0.50

            local amp = 6
            local p1 = math.sin(t*3)      * amp
            local p2 = math.sin(t*3+math.pi) * amp

            love.graphics.setColor(S.pipe)
            love.graphics.circle("fill", cx1, cy + p1, 10)
            love.graphics.circle("fill", cx2, cy + p2, 10)

            -- Caps
            love.graphics.setColor(S.outline)
            love.graphics.circle("line", cx1, cy + p1, 10)
            love.graphics.circle("line", cx2, cy + p2, 10)
        end,
    })

    Decorations.register("pipe_cap", {
        w = 1,
        h = 1,

        draw = function(x, y, w, h)
            -- original base radius (fit within 48×48)
            local baseR = w * 0.45        -- ≈ 21.6px

            -- new reduced radius (subtract 7px)
            local r = baseR - 10

            local cx = x + w/2
            local cy = y + h/2

            -- Outer ring (outline)
            love.graphics.setColor(S.outline)
            love.graphics.circle("fill", cx, cy, r + 4)

            -- Pipe fill
            love.graphics.setColor(S.pipe)
            love.graphics.circle("fill", cx, cy, r)

            -- Bolt ring (auto adjusted inward)
            love.graphics.setColor(S.dark)
            local bolts = 6
            for i = 1, bolts do
                local ang = (i / bolts) * math.pi * 2
                local bx = cx + math.cos(ang) * (r - 4)
                local by = cy + math.sin(ang) * (r - 4)
                love.graphics.circle("fill", bx, by, 2.3)
            end
        end
    })
end