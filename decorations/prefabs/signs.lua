local Theme = require("theme")
local Events = require("systems.events")
local S = Theme.decorations

--[[
• Arrows
• Numbered zones (A1, A2, B3…)
• Fluid line labels (H₂O, COOLANT 4B, WASTE LINE)
• Fan warning sign (blade icon)
• Pipe pressure warning
• Lift / elevator icon
• Laser alignment marks
• “This sign is intentionally blank.”
• “Please ignore this sign.”
• “If confused, continue being confused.”
• “Sign under maintenance (sign may not function properly).”
• “Reserved for future content.”
• “No unauthorized gravity adjustments.”
• “Do not approach suspiciously wiggly vents.”

Creepy lumo drawing?

Random character darkening — (one letter flickers)
--]]

return function(Decorations)
	Decorations.register("sign", {
		w = 2,
		h = 1,

		---------------------------------------------------------
		-- INIT
		---------------------------------------------------------
		init = function(inst)
			inst.data.text = inst.data.text or ""
			inst.data.font = love.graphics.newFont("fonts/Nunito-Bold.ttf", 24)

			-----------------------------------------------------
			-- POWER / BOOT STATE
			-----------------------------------------------------
			inst.powered = false
			inst.booting = false

			inst.onlinePhase = 0
			inst.onlineTime  = 0

			inst.onlineDuration = {
				point = 0.10,
				horiz = 0.20,
				vert  = 0.20,
				beat  = 0.60,
			}

			-----------------------------------------------------
			-- TEXT STATE
			-----------------------------------------------------
			inst.textState = "idle"
			inst.textTimer = 0
			inst.textAlpha = 0

			-----------------------------------------------------
			-- GLITCH STATE (POST-ONLINE)
			-----------------------------------------------------
			inst.glitchCooldown = love.math.random(18, 28)
			inst.glitchActive   = false
			inst.glitchTime     = 0
			inst.glitchIndex    = nil

			-----------------------------------------------------
			-- EVENT HOOK
			-----------------------------------------------------
			Events.on("first_landing", function()
				if inst.powered then return end
				inst.powered     = true
				inst.booting     = true
				inst.onlinePhase = 1
				inst.onlineTime  = 0
			end)
		end,

		---------------------------------------------------------
		-- UPDATE
		---------------------------------------------------------
		update = function(inst, dt)
			if not inst.powered then return end

			inst.onlineTime = inst.onlineTime + dt
			local t = inst.onlineTime
			local d = inst.onlineDuration

			-----------------------------------------------------
			-- BOOT SEQUENCE
			-----------------------------------------------------
			if inst.onlinePhase == 1 and t >= d.point then
				inst.onlinePhase, inst.onlineTime = 2, 0

			elseif inst.onlinePhase == 2 and t >= d.horiz then
				inst.onlinePhase, inst.onlineTime = 3, 0

			elseif inst.onlinePhase == 3 and t >= d.vert then
				inst.onlinePhase, inst.onlineTime = 4, 0

			elseif inst.onlinePhase == 4 and t >= d.beat then
				inst.onlinePhase = 5
				inst.textState  = "flicker"
				inst.textTimer  = 0
			end

			-----------------------------------------------------
			-- TEXT APPEAR
			-----------------------------------------------------
			if inst.onlinePhase == 5 then
				inst.textTimer = inst.textTimer + dt

				if inst.textState == "flicker" then
					if inst.textTimer < 0.32 then
						local lev = {0, 0.3, 0.7, 1}
						inst.textAlpha = lev[love.math.random(#lev)]
					else
						inst.textState = "fade"
						inst.textTimer = 0
						inst.textAlpha = 0
					end

				elseif inst.textState == "fade" then
					local k = math.min(inst.textTimer / 0.4, 1)
					inst.textAlpha = k
					if k >= 1 then
						inst.textState = "done"
					end
				end
			end

			-----------------------------------------------------
			-- RARE CHARACTER GLITCH
			-----------------------------------------------------
			if inst.textState == "done" then
				inst.glitchCooldown = inst.glitchCooldown - dt

				if not inst.glitchActive and inst.glitchCooldown <= 0 then
					inst.glitchActive = true
					inst.glitchTime   = 0
					inst.glitchIndex  = love.math.random(1, #inst.data.text)
				end

				if inst.glitchActive then
					inst.glitchTime = inst.glitchTime + dt
					if inst.glitchTime > 0.06 then
						inst.glitchActive   = false
						inst.glitchIndex    = nil
						inst.glitchCooldown = love.math.random(18, 28)
					end
				end
			end
		end,

		---------------------------------------------------------
		-- DRAW
		---------------------------------------------------------
		draw = function(x, y, w, h, inst)
			local inset   = 4
			local outline = 4
			local radius  = 6

			local boxW = w - inset * 2
			local boxH = h - inset * 2
			local boxX = x + inset
			local boxY = y + inset

			-----------------------------------------------------
			-- FRAME
			-----------------------------------------------------
			love.graphics.setColor(S.outline)
			love.graphics.rectangle(
				"fill",
				boxX - outline, boxY - outline,
				boxW + outline * 2, boxH + outline * 2,
				radius + outline, radius + outline
			)

			love.graphics.setColor(S.signFill)
			love.graphics.rectangle("fill", boxX, boxY, boxW, boxH, radius, radius)

			if inst.onlinePhase < 5 then return end

			-----------------------------------------------------
			-- TEXT
			-----------------------------------------------------
			local font = inst.data.font
			love.graphics.setFont(font)

			local text = inst.data.text
			local tw   = font:getWidth(text)
			local th   = font:getHeight()

			local tx = boxX + (boxW - tw) / 2
			local ty = boxY + (boxH - th) / 2

			-----------------------------------------------------
			-- BACKPLATE GLOW
			-----------------------------------------------------
			love.graphics.setColor(1,1,1,inst.textAlpha * 0.08)
			love.graphics.rectangle("fill", tx-6, ty-4, tw+12, th+8, 6, 6)

			-----------------------------------------------------
			-- CHARACTER-BY-CHARACTER DRAW
			-----------------------------------------------------
			local cx = tx

			for i = 1, #text do
				local ch = text:sub(i, i)
				local wch = font:getWidth(ch)

				local alpha = inst.textAlpha
				local ox, oy = 0, 0

				if inst.glitchActive and inst.glitchIndex == i then
					alpha = alpha * 0.45
					ox = love.math.random(-1,1)
					oy = love.math.random(-1,1)

					if love.math.random() < 0.35 then
						ch = ({ "#", "_", " " })[love.math.random(3)]
					end
				end

				love.graphics.setColor(
					S.signText[1],
					S.signText[2],
					S.signText[3],
					alpha
				)

				love.graphics.print(ch, cx + ox, ty + oy)
				cx = cx + wch
			end
		end
	})
	
	Decorations.register("hazard_triangle", {
		w = 2,
		h = 2,

		draw = function(x, y, w, h)
			local cx = x + w / 2
			local cy = y + h / 2

			local outline = 6   -- a bit thicker → softer perceived corners
			local padding = 10

			-- Triangle points
			local topX,  topY  = cx,               y + padding
			local leftX, leftY = x + padding,      y + h - padding
			local rightX,rightY= x + w - padding,  y + h - padding

			------------------------------------------------------
			-- OUTLINE (valid line join)
			------------------------------------------------------
			love.graphics.setColor(0, 0, 0, 1)
			love.graphics.setLineWidth(outline)
			love.graphics.setLineJoin("bevel")
			love.graphics.polygon("line",
				topX,  topY,
				leftX, leftY,
				rightX,rightY
			)

			------------------------------------------------------
			-- FILL (smaller, so outline visually rounds corners)
			------------------------------------------------------
			local inset = 3
			love.graphics.setColor(0.87, 0.82, 0.53)

			love.graphics.polygon("fill",
				topX,                  topY + inset,
				leftX  + inset * 0.8, leftY - inset,
				rightX - inset * 0.8, rightY - inset
			)
		end
	})

	Decorations.register("hazard_electric", {
		w = 2,
		h = 2,

		draw = function(x, y, w, h)
			local cx = x + w / 2
			local cy = y + h / 2

			local outline = 6
			local padding = 10

			local topX,  topY  = cx,               y + padding
			local leftX, leftY = x + padding,      y + h - padding
			local rightX,rightY= x + w - padding,  y + h - padding

			------------------------------------------------------
			-- OUTLINE
			------------------------------------------------------
			love.graphics.setColor(0, 0, 0, 1)
			love.graphics.setLineWidth(outline)
			love.graphics.setLineJoin("bevel")
			love.graphics.polygon("line",
				topX,  topY,
				leftX, leftY,
				rightX,rightY
			)

			------------------------------------------------------
			-- FILL
			------------------------------------------------------
			local inset = 3
			love.graphics.setColor(0.87, 0.82, 0.53)
			love.graphics.polygon("fill",
				topX,                  topY + inset,
				leftX  + inset * 0.8, leftY - inset,
				rightX - inset * 0.8, rightY - inset
			)

			------------------------------------------------------
			-- LIGHTNING BOLT ICON
			------------------------------------------------------
			love.graphics.setColor(0, 0, 0, 1)

			local bolt = {
				cx - 4, cy - 12,
				cx - 1, cy - 3,
				cx - 8, cy - 3,
				cx + 1, cy + 12,
				cx - 1, cy + 4,
				cx + 8, cy + 4,
			}

			love.graphics.polygon("fill", bolt)
		end
	})

	Decorations.register("scribble_lumo", {
        w = 1,
        h = 1,

        init = function(inst, entry)
            local ts = inst.config.tileSize or 48
            inst.w = (entry.w or 1) * ts
            inst.h = (entry.h or 1) * ts

            ------------------------------------------------------
            -- CHALK DRAW PARAMETERS (much smoother & calmer)
            ------------------------------------------------------
            inst.radius      = math.min(inst.w, inst.h) * 0.34
            inst.segments    = 40            -- fewer segments for stability
            inst.jitter      = 0.8          -- small, subtle variation
            inst.linePasses  = 1             -- single clean outline
            inst.eyeScale    = 0.17
            inst.eyeOffsetX  = inst.radius * 0.40
            inst.eyeOffsetY  = -inst.radius * 0.18
            inst.angleOffset = 0             -- no rotation for maximum calm

            ------------------------------------------------------
            -- Precompute one stable outline
            ------------------------------------------------------
            inst.stroke = {}
            for i = 1, inst.segments do
                local t = (i / inst.segments) * math.pi * 2
                local r = inst.radius +
                    (love.math.random() * inst.jitter - inst.jitter * 0.5)

                inst.stroke[#inst.stroke+1] = {
                    math.cos(t) * r,
                    math.sin(t) * r,
                }
            end
        end,

        draw = function(x, y, w, h, inst)
            local cx = x + w * 0.5
            local cy = y + h * 0.5

            love.graphics.push()
            love.graphics.translate(cx, cy)

            ------------------------------------------------------
            -- CHALK OUTLINE (cleaner)
            ------------------------------------------------------
            love.graphics.setColor(1, 1, 1, 0.82)
            love.graphics.setLineWidth(3)

            local pts = inst.stroke
            for i = 1, #pts - 1 do
                local p1 = pts[i]
                local p2 = pts[i+1]
                love.graphics.line(p1[1], p1[2], p2[1], p2[2])
            end
            -- close loop
            love.graphics.line(pts[#pts][1], pts[#pts][2], pts[1][1], pts[1][2])

            ------------------------------------------------------
            -- EYES (chalk circles, but refined)
            ------------------------------------------------------
            local er = inst.radius * inst.eyeScale
            local function drawEye(ex, ey)
                love.graphics.setColor(1, 1, 1, 0.88)
                love.graphics.circle("line", ex, ey, er)
            end

            drawEye(-inst.eyeOffsetX, inst.eyeOffsetY)
            drawEye( inst.eyeOffsetX, inst.eyeOffsetY)

            love.graphics.pop()
        end,
    })
end