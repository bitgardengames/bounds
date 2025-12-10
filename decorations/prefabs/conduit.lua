local Theme = require("theme")
local S = Theme.decorations

local pipeFill = 16
local O = 4
local thick = pipeFill + O*2

return function(Decorations)
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

		love.graphics.setColor(S.conduit)
		love.graphics.setLineWidth(pipeFill)
		love.graphics.arc("line", "open",
			w, h,
			R,
			math.pi,
			math.pi*1.5
		)

		love.graphics.pop()
	end

	local function drawDoubleCurve(x, y, w, h, rotate)
		local S        = Decorations.style
		local pipeFill = 4
		local O        = 4

		------------------------------------------------------------------
		-- Correct geometry: two 4px pipes separated by 4px outline band.
		-- Both follow the tile-center → tile-center quarter-circle.
		------------------------------------------------------------------
		local offset  = 4        -- pipe centerline spacing from main radius
		local R_base  = 24       -- tileCenter → tileCenter radius

		local R_outer = R_base + offset
		local R_inner = R_base - offset

		------------------------------------------------------------------
		-- World-space origin of the arc
		-- (center of tile) + (radius, radius)
		------------------------------------------------------------------
		local tileCX = x + w/2
		local tileCY = y + h/2

		local originX = tileCX + R_base
		local originY = tileCY + R_base

		------------------------------------------------------------------
		-- Apply rotation around tile center ONLY
		------------------------------------------------------------------
		love.graphics.push()
		love.graphics.translate(tileCX, tileCY)
		love.graphics.rotate(rotate)
		love.graphics.translate(-tileCX, -tileCY)

		local angleStart = math.pi
		local angleEnd   = math.pi * 1.5

		------------------------------------------------------------------
		-- OUTER PIPE
		------------------------------------------------------------------
		love.graphics.setColor(S.outline)
		love.graphics.setLineWidth(pipeFill + O*2)
		love.graphics.arc("line", "open",
			originX, originY,
			R_outer,
			angleStart, angleEnd
		)

		love.graphics.setColor(S.conduit)
		love.graphics.setLineWidth(pipeFill)
		love.graphics.arc("line", "open",
			originX, originY,
			R_outer,
			angleStart, angleEnd
		)

		------------------------------------------------------------------
		-- INNER PIPE
		------------------------------------------------------------------
		love.graphics.setColor(S.outline)
		love.graphics.setLineWidth(pipeFill + O*2)
		love.graphics.arc("line", "open",
			originX, originY,
			R_inner,
			angleStart, angleEnd
		)

		love.graphics.setColor(S.conduit)
		love.graphics.setLineWidth(pipeFill)
		love.graphics.arc("line", "open",
			originX, originY,
			R_inner,
			angleStart, angleEnd
		)

		love.graphics.pop()
	end

    Decorations.register("conduit_h", {
        w = 1, h = 1,

        draw = function(x, y, w, h)
            local pipeFill = 4
            local O = 4

            local thick = pipeFill + O*2
            local cy = y + h/2 - thick/2

            love.graphics.setColor(S.outline)
            love.graphics.rectangle("fill", x, cy, w, thick)

            love.graphics.setColor(S.conduit)
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

            love.graphics.setColor(S.conduit)
            love.graphics.rectangle("fill",
                cx + O,
                y,
                pipeFill,
                h
            )
        end,
    })

	Decorations.register("conduit_indicator", {
		w = 1,
		h = 1,

		init = function(inst, entry)
			inst.data = inst.data or {}
			inst.data.id = entry.data and entry.data.id
			inst.data.active = false
			inst.data.t = 0
		end,

		update = function(inst, dt)
			local d = inst.data
			local target = d.active and 1 or 0    -- what we want to reach
			local speed = 8                       -- how “premium” the easing feels

			-- basic smooth approach
			d.t = d.t + (target - d.t) * speed * dt

			-- clamp for safety
			if d.t < 0 then d.t = 0 end
			if d.t > 1 then d.t = 1 end
		end,

		draw = function(x, y, w, h, inst)
			local active = inst and inst.data and inst.data.active

			local cx = x + w/2
			local cy = y + h/2

			local d = inst.data
			local ledR     = 4           -- FINAL LED radius
			local innerR   = ledR + 4    -- inner black outline radius
			local metalR   = innerR + 4  -- metal ring radius
			local outlineR = metalR + 4  -- outer black ring radius

			------------------------------------------------------------------
			-- OUTER BLACK OUTLINE (layer 1)
			------------------------------------------------------------------
			love.graphics.setColor(S.outline)
			love.graphics.circle("fill", cx, cy, outlineR)

			------------------------------------------------------------------
			-- METAL RING (layer 2)
			------------------------------------------------------------------
			love.graphics.setColor(S.conduit)
			love.graphics.circle("fill", cx, cy, metalR)

			------------------------------------------------------------------
			-- INNER BLACK OUTLINE (layer 3)
			------------------------------------------------------------------
			love.graphics.setColor(S.outline)
			love.graphics.circle("fill", cx, cy, innerR)

			------------------------------------------------------------------
			-- LED (layer 4)
			------------------------------------------------------------------
			-- PREMIUM COLOR FADE
			local k = d.t * d.t * (3 - 2 * d.t) -- smoothstep

			local r1,g1,b1 = S.conduitDisabled[1], S.conduitDisabled[2], S.conduitDisabled[3]
			local r2,g2,b2 = S.conduitEnabled[1],  S.conduitEnabled[2],  S.conduitEnabled[3]

			local R = r1 + (r2 - r1) * k
			local G = g1 + (g2 - g1) * k
			local B = b1 + (b2 - b1) * k

			love.graphics.setColor(R, G, B, 1)
			love.graphics.circle("fill", cx, cy, ledR)

			------------------------------------------------------------------
			-- Highlight dot
			------------------------------------------------------------------
			love.graphics.setColor(1, 1, 1, 0.25)
			love.graphics.circle("fill", cx + 1.5, cy - 1.5, 1.5)
		end,
	})

	Decorations.register("timer_display", {
		w = 1,
		h = 1,

		init = function(inst, entry)
			inst.data = {
				id  = entry.data and entry.data.id,
				dur = (entry.data and entry.data.dur) or 5,
				remaining = 0,
				active = false,
				progress = 0
			}
		end,

		update = function(inst, dt)
			local d = inst.data

			if d.active then
				d.remaining = d.remaining - dt
				if d.remaining <= 0 then
					d.remaining = 0
					d.active = false
				end
				d.progress = d.remaining / d.dur  -- full → empty
			else
				d.progress = 0
			end
		end,

		draw = function(x, y, w, h, inst)
			local d = inst.data
			local p = d.progress or 0

			local cx = x + w/2
			local cy = y + h/2

			------------------------------------------------------------
			-- HOUSING (same as conduit_indicator)
			------------------------------------------------------------
			local ledR     = 4
			local innerR   = ledR + 4
			local metalR   = innerR + 4
			local outlineR = metalR + 4

			love.graphics.setColor(S.outline)
			love.graphics.circle("fill", cx, cy, outlineR)

			love.graphics.setColor(S.conduit)
			love.graphics.circle("fill", cx, cy, metalR)

			love.graphics.setColor(S.outline)
			love.graphics.circle("fill", cx, cy, innerR)

			------------------------------------------------------------
			-- SEGMENTED CLOCKWISE DEPLETION (NO STENCIL, NO ARC BUGS)
			------------------------------------------------------------
			if p > 0 then
				love.graphics.setColor(S.timerColor)
				love.graphics.setLineWidth(3)

				local radius = metalR - 2   -- safe, outside cavity
				local segments = 64         -- smoothness
				local fullAngle = 2 * math.pi * p
				local startAngle = -math.pi/2  -- 12 o'clock

				for i = 0, segments do
					local a1 = startAngle - (i     / segments) * fullAngle
					local a2 = startAngle - ((i+1) / segments) * fullAngle

					love.graphics.line(
						cx + math.cos(a1) * radius,
						cy + math.sin(a1) * radius,
						cx + math.cos(a2) * radius,
						cy + math.sin(a2) * radius
					)
				end
			end
		end
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

			love.graphics.setColor(S.conduit)
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
			love.graphics.setColor(S.bracket)
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

			love.graphics.setColor(S.conduit)
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
			love.graphics.setColor(S.bracket)
			love.graphics.rectangle("fill",
				jx + O,
				jy + O,
				joinW - O*2,
				joinFill
			)
		end
	})

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

			local pipeFill = 4
			local O = 4

			----------------------------------------------------------
			-- SAME GEOMETRY AS conduit_v_double, but rotated:
			-- [outline][pipe][outline][pipe][outline]
			----------------------------------------------------------

			local totalH = O + pipeFill + O + pipeFill + O   -- 20px tall
			local startY = y + (h - totalH) / 2              -- vertically centered

			-- full width of tile for each pipe segment
			local thick = pipeFill + O*2                     -- 12px wide (horizontal)
			local cx = x                                     -- spans whole tile width

			----------------------------------------------------------
			-- TOP OUTLINE
			----------------------------------------------------------
			love.graphics.setColor(S.outline)
			love.graphics.rectangle("fill",
				x,
				startY,
				w,
				O
			)

			----------------------------------------------------------
			-- PIPE 1
			----------------------------------------------------------
			love.graphics.setColor(S.conduit)
			love.graphics.rectangle("fill",
				x,
				startY + O,
				w,
				pipeFill
			)

			----------------------------------------------------------
			-- MIDDLE OUTLINE
			----------------------------------------------------------
			love.graphics.setColor(S.outline)
			love.graphics.rectangle("fill",
				x,
				startY + O + pipeFill,
				w,
				O
			)

			----------------------------------------------------------
			-- PIPE 2
			----------------------------------------------------------
			love.graphics.setColor(S.conduit)
			love.graphics.rectangle("fill",
				x,
				startY + O + pipeFill + O,
				w,
				pipeFill
			)

			----------------------------------------------------------
			-- BOTTOM OUTER OUTLINE
			----------------------------------------------------------
			love.graphics.setColor(S.outline)
			love.graphics.rectangle("fill",
				x,
				startY + totalH - O,
				w,
				O
			)
		end,
	})

	Decorations.register("conduit_v_double", {
		w = 1, h = 1,

		draw = function(x, y, w, h)

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
			love.graphics.setColor(S.conduit)
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
			love.graphics.setColor(S.conduit)
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

			--------------------------------------------------------------
			-- BASE DOUBLE CONDUIT (same layout as conduit_h_double)
			--------------------------------------------------------------
			local totalH = O + pipeFill + O + pipeFill + O     -- 20px
			local startY = y + (h - totalH) / 2

			-- TOP OUTLINE
			love.graphics.setColor(S.outline)
			love.graphics.rectangle("fill", x, startY, w, O)

			-- PIPE 1
			love.graphics.setColor(S.conduit)
			love.graphics.rectangle("fill", x, startY + O, w, pipeFill)

			-- MID OUTLINE
			love.graphics.setColor(S.outline)
			love.graphics.rectangle("fill", x, startY + O + pipeFill, w, O)

			-- PIPE 2
			love.graphics.setColor(S.conduit)
			love.graphics.rectangle("fill",
				x,
				startY + O + pipeFill + O,
				w,
				pipeFill
			)

			-- BOTTOM OUTLINE
			love.graphics.setColor(S.outline)
			love.graphics.rectangle("fill", x, startY + totalH - O, w, O)

			--------------------------------------------------------------
			-- COUPLING BAND (centered, same dimensions as single join)
			--------------------------------------------------------------
			local thick = pipeFill + O*2                   -- 12px
			local joinW = 10                               -- outer width
			local joinFill = joinW - O*2                   -- 2px fill
			local joinH = totalH + 8                       -- 20 + 8 = 28px tall

			local jy = y + h/2 - joinH/2
			local jx = x + w/2 - joinW/2

			-- Outline band
			love.graphics.setColor(S.outline)
			love.graphics.rectangle("fill", jx, jy, joinW, joinH)

			-- Inner metal
			love.graphics.setColor(S.conduit)
			love.graphics.rectangle("fill",
				jx + O,
				jy + O,
				joinFill,
				joinH - O*2
			)
		end
	})

	Decorations.register("conduit_v_double_join", {
		w = 1, h = 1,

		draw = function(x, y, w, h)
			local S = Decorations.style
			local pipeFill = 4
			local O = 4

			--------------------------------------------------------------
			-- BASE DOUBLE VERTICAL CONDUIT (same as conduit_v_double)
			--------------------------------------------------------------
			local totalW = O + pipeFill + O + pipeFill + O      -- 20px
			local startX = x + (w - totalW) / 2

			-- LEFT OUTLINE
			love.graphics.setColor(S.outline)
			love.graphics.rectangle("fill", startX, y, O, h)

			-- PIPE 1
			love.graphics.setColor(S.conduit)
			love.graphics.rectangle("fill",
				startX + O,
				y,
				pipeFill,
				h
			)

			-- MID OUTLINE
			love.graphics.setColor(S.outline)
			love.graphics.rectangle("fill",
				startX + O + pipeFill,
				y,
				O,
				h
			)

			-- PIPE 2
			love.graphics.setColor(S.conduit)
			love.graphics.rectangle("fill",
				startX + O + pipeFill + O,
				y,
				pipeFill,
				h
			)

			-- RIGHT OUTLINE
			love.graphics.setColor(S.outline)
			love.graphics.rectangle("fill",
				startX + totalW - O,
				y,
				O,
				h
			)

			--------------------------------------------------------------
			-- COUPLING BAND (same logic as vertical single join)
			--------------------------------------------------------------
			local thick = pipeFill + O*2               -- 12px width
			local joinH = 10                           -- outer height
			local joinFill = joinH - O*2               -- 2px fill
			local joinW = totalW + 8                   -- 20 + 8 = 28px wide

			local jx = x + w/2 - joinW/2
			local jy = y + h/2 - joinH/2

			-- Outline band
			love.graphics.setColor(S.outline)
			love.graphics.rectangle("fill", jx, jy, joinW, joinH)

			-- Fill band
			love.graphics.setColor(S.conduit)
			love.graphics.rectangle("fill",
				jx + O,
				jy + O,
				joinW - O*2,
				joinFill
			)
		end
	})

	Decorations.register("conduit_curve_tr_double", {
		w = 1, h = 1,
		draw = function(x, y, w, h)
			drawDoubleCurve(x, y, w, h, 0)
		end
	})

	Decorations.register("conduit_curve_tl_double", {
		w = 1, h = 1,
		draw = function(x, y, w, h)
			drawDoubleCurve(x, y, w, h, math.pi * 0.5)
		end
	})

	Decorations.register("conduit_curve_bl_double", {
		w = 1, h = 1,
		draw = function(x, y, w, h)
			drawDoubleCurve(x, y, w, h, math.pi)
		end
	})

	Decorations.register("conduit_curve_br_double", {
		w = 1, h = 1,
		draw = function(x, y, w, h)
			drawDoubleCurve(x, y, w, h, math.pi * 1.5)
		end
	})
end