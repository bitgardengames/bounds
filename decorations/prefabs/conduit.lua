local pipeFill = 16
local O = 4
local thick = pipeFill + O*2

return function(Decorations)
    Decorations.register("conduit_h", {
        w = 1, h = 1,

        draw = function(x, y, w, h)
            local S = Decorations.style
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
            local S = Decorations.style
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
			local S = Decorations.style
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
			local S = Decorations.style
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

	Decorations.register("conduit_h_double", {
		w = 1, h = 1,

		draw = function(x, y, w, h)
			local S = Decorations.style

			local pipeFill = 4
			local O = 4

			-- Total width of two pipes + 3 outlines
			local totalW = O + pipeFill + O + pipeFill + O   -- 20px
			local startX = x + (w - totalW) / 2              -- center horizontally

			-- Vertical alignment same as single conduit
			local thick = pipeFill + O*2                     -- 12px tall pipe band
			local cy = y + h/2 - thick/2

			--------------------------------------------------------------
			-- LEFT OUTLINE
			--------------------------------------------------------------
			love.graphics.setColor(S.outline)
			love.graphics.rectangle("fill",
				startX,
				cy,
				O,
				thick
			)

			--------------------------------------------------------------
			-- PIPE 1 (left)
			--------------------------------------------------------------
			love.graphics.setColor(S.pipe)
			love.graphics.rectangle("fill",
				startX + O,
				cy + O,
				pipeFill,
				pipeFill
			)

			--------------------------------------------------------------
			-- MIDDLE OUTLINE (shared divider)
			--------------------------------------------------------------
			love.graphics.setColor(S.outline)
			love.graphics.rectangle("fill",
				startX + O + pipeFill,
				cy,
				O,
				thick
			)

			--------------------------------------------------------------
			-- PIPE 2 (right)
			--------------------------------------------------------------
			love.graphics.setColor(S.pipe)
			love.graphics.rectangle("fill",
				startX + O + pipeFill + O,
				cy + O,
				pipeFill,
				pipeFill
			)

			--------------------------------------------------------------
			-- RIGHT OUTLINE
			--------------------------------------------------------------
			love.graphics.setColor(S.outline)
			love.graphics.rectangle("fill",
				startX + O + pipeFill + O + pipeFill,
				cy,
				O,
				thick
			)
		end,
	})

	Decorations.register("conduit_v_double", {
		w = 1, h = 1,

		draw = function(x, y, w, h)
			local S = Decorations.style

			local pipeFill = 4
			local O = 4

			local totalW = O + pipeFill + O + pipeFill + O   -- 20px wide
			local startX = x + (w - totalW) / 2

			local thick = pipeFill + O*2                     -- 12px tall (vertical is long)
			local cy = y                                     -- vertical pipe spans full tile

			--------------------------------------------------------------
			-- LEFT OUTLINE
			--------------------------------------------------------------
			love.graphics.setColor(S.outline)
			love.graphics.rectangle("fill",
				startX,
				y,
				O,
				h
			)

			--------------------------------------------------------------
			-- PIPE 1
			--------------------------------------------------------------
			love.graphics.setColor(S.pipe)
			love.graphics.rectangle("fill",
				startX + O,
				y,
				pipeFill,
				h
			)

			--------------------------------------------------------------
			-- MIDDLE OUTLINE
			--------------------------------------------------------------
			love.graphics.setColor(S.outline)
			love.graphics.rectangle("fill",
				startX + O + pipeFill,
				y,
				O,
				h
			)

			--------------------------------------------------------------
			-- PIPE 2
			--------------------------------------------------------------
			love.graphics.setColor(S.pipe)
			love.graphics.rectangle("fill",
				startX + O + pipeFill + O,
				y,
				pipeFill,
				h
			)

			--------------------------------------------------------------
			-- RIGHT OUTLINE
			--------------------------------------------------------------
			love.graphics.setColor(S.outline)
			love.graphics.rectangle("fill",
				startX + O + pipeFill + O + pipeFill,
				y,
				O,
				h
			)
		end,
	})

	Decorations.register("conduit_h_double_join", {
		w = 1, h = 1,

		draw = function(x, y, w, h)
			local S = Decorations.style

			local pipeFill = 4
			local O = 4

			------------------------------------------------------
			-- DOUBLE PIPE GEOMETRY (same as conduit_h_double)
			------------------------------------------------------
			local totalW = O + pipeFill + O + pipeFill + O      -- 20px total
			local startX = x + (w - totalW) / 2

			local thick = pipeFill + O*2                         -- 12px tall pipe band
			local cy = y + h/2 - thick/2

			-- LEFT OUTLINE
			love.graphics.setColor(S.outline)
			love.graphics.rectangle("fill", startX, cy, O, thick)

			-- LEFT PIPE
			love.graphics.setColor(S.pipe)
			love.graphics.rectangle("fill",
				startX + O,
				cy + O,
				pipeFill,
				pipeFill
			)

			-- MIDDLE OUTLINE
			love.graphics.setColor(S.outline)
			love.graphics.rectangle("fill",
				startX + O + pipeFill,
				cy,
				O,
				thick
			)

			-- RIGHT PIPE
			love.graphics.setColor(S.pipe)
			love.graphics.rectangle("fill",
				startX + O + pipeFill + O,
				cy + O,
				pipeFill,
				pipeFill
			)

			-- RIGHT OUTLINE
			love.graphics.setColor(S.outline)
			love.graphics.rectangle("fill",
				startX + totalW - O,
				cy,
				O,
				thick
			)

			------------------------------------------------------
			-- COUPLING BAND (centered horizontally)
			------------------------------------------------------
			local joinW   = 14         -- wider band to cover both pipes
			local joinFill = joinW - O*2
			local joinH   = thick + 8  -- taller than pipe band
			local jx = x + w/2 - joinW/2
			local jy = y + h/2 - joinH/2

			-- outer outline band
			love.graphics.setColor(S.outline)
			love.graphics.rectangle("fill",
				jx, jy,
				joinW, joinH
			)

			-- inner metal fill
			love.graphics.setColor(S.pipe)
			love.graphics.rectangle("fill",
				jx + O,
				jy + O,
				joinFill,
				joinH - O*2
			)
		end
	})
end