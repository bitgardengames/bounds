local Theme = require("theme")
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

            ---------------------------------------------------------
            -- SCREEN BOOT STATE
            ---------------------------------------------------------
            inst.onlineTime   = 0
            inst.onlinePhase  = 0      -- 0=off → 1=point → 2=horiz → 3=vert → 4=online → 5=text
            inst.onlineDelay  = 2.2      -- wait before powering on

            inst.onlineDuration = {
                point = 0.10,
                horiz = 0.20,
                vert  = 0.20,
                beat  = 0.60,  -- cinematic pause before text flicker
            }

            ---------------------------------------------------------
            -- TEXT FLICKER-IN
            ---------------------------------------------------------
            inst.textState = "idle"
            inst.textTimer = 0
            inst.textAlpha = 0

            ---------------------------------------------------------
            -- OCCASIONAL TEXT GLITCH (rare, subtle)
            ---------------------------------------------------------
            inst.glitchTimer = love.math.random(20, 30)
            inst.glitchState = "idle"
            inst.glitchTime  = 0
        end,

        ---------------------------------------------------------
        -- UPDATE
        ---------------------------------------------------------
        update = function(inst, dt)
            inst.onlineTime = inst.onlineTime + dt
            local t = inst.onlineTime
            local d = inst.onlineDuration

            -----------------------------------------------------
            -- PHASE 0 – WAIT BEFORE BOOT STARTS
            -----------------------------------------------------
            if inst.onlinePhase == 0 then
                if t >= inst.onlineDelay then
                    inst.onlinePhase = 1
                    inst.onlineTime = 0
                end
                return
            end

            -----------------------------------------------------
            -- PHASE 1 – POINT
            -----------------------------------------------------
            if inst.onlinePhase == 1 then
                if t >= d.point then
                    inst.onlinePhase = 2
                    inst.onlineTime = 0
                end

            -----------------------------------------------------
            -- PHASE 2 – HORIZONTAL EXPANSION
            -----------------------------------------------------
            elseif inst.onlinePhase == 2 then
                if t >= d.horiz then
                    inst.onlinePhase = 3
                    inst.onlineTime = 0
                end

            -----------------------------------------------------
            -- PHASE 3 – VERTICAL EXPANSION
            -----------------------------------------------------
            elseif inst.onlinePhase == 3 then
                if t >= d.vert then
                    inst.onlinePhase = 4
                    inst.onlineTime = 0
                end

            -----------------------------------------------------
            -- PHASE 4 – SCREEN IS FULLY ONLINE (pause before text)
            -----------------------------------------------------
            elseif inst.onlinePhase == 4 then
                if t >= d.beat then
                    inst.onlinePhase = 5
                    inst.textState = "flicker"
                    inst.textTimer = 0
                end

            -----------------------------------------------------
            -- PHASE 5 – TEXT APPEAR ANIMATION
            -----------------------------------------------------
            elseif inst.onlinePhase == 5 then
                inst.textTimer = inst.textTimer + dt

                if inst.textState == "flicker" then
                    local dur = 0.32
                    if inst.textTimer < dur then
                        local lev = {0, 0.3, 0.7, 1.0}
                        inst.textAlpha = lev[love.math.random(1, #lev)]
                    else
                        inst.textState = "fade"
                        inst.textTimer = 0
                        inst.textAlpha = 0
                    end

                elseif inst.textState == "fade" then
                    local dur = 0.40
                    local k = math.min(inst.textTimer / dur, 1)
                    inst.textAlpha = k

                    if k >= 1 then
                        inst.textState = "done"
                    end
                end

                -----------------------------------------------------
                -- RARE TEXT GLITCH (only once text is fully stable)
                -----------------------------------------------------
                if inst.textState == "done" then
                    inst.glitchTimer = inst.glitchTimer - dt

                    if inst.glitchState == "idle" and inst.glitchTimer <= 0 then
                        inst.glitchState = "glitch"
                        inst.glitchTime  = 0
                        inst.glitchTimer = love.math.random(20, 30)
                    end

                    if inst.glitchState == "glitch" then
                        inst.glitchTime = inst.glitchTime + dt
                        if inst.glitchTime >= 0.06 then
                            inst.glitchState = "idle"
                        end
                    end
                end
            end
        end,

        ---------------------------------------------------------
        -- DRAW
        ---------------------------------------------------------
        draw = function(x, y, w, h, inst)
            local font = inst.data.font
            local text = inst.data.text
            love.graphics.setFont(font)

            local inset   = 4
            local outline = 4
            local radius  = 6

            local boxW = w - inset * 2
            local boxH = h - inset * 2
            local boxX = x + inset
            local boxY = y + inset

            ---------------------------------------------------------
            -- OUTLINE
            ---------------------------------------------------------
            love.graphics.setColor(S.outline)
            love.graphics.rectangle(
                "fill",
                boxX - outline, boxY - outline,
                boxW + outline * 2, boxH + outline * 2,
                radius + outline, radius + outline
            )

            ---------------------------------------------------------
            -- SCREEN FILL (BOOT SEQUENCE)
            ---------------------------------------------------------
            local p = inst.onlinePhase
            local t = inst.onlineTime
            local d = inst.onlineDuration

            if p == 0 then
                return
            end

            -- PHASE 1 — POINT → THIN LINE
            if p == 1 then
                local k = math.min(1, t/d.point)
                local lw = 6 * k
                local lh = 2 * k
                local lx = boxX + (boxW - lw)*0.5
                local ly = boxY + (boxH - lh)*0.5
                love.graphics.setColor(S.signFill)
                love.graphics.rectangle("fill", lx, ly, lw, lh)

            -- PHASE 2 — HORIZONTAL EXPANSION
            elseif p == 2 then
                local k = math.min(1, t/d.horiz)
                local lw = 6 + (boxW - 6)*k
                local lh = 2
                local lx = boxX + (boxW - lw)*0.5
                local ly = boxY + (boxH - lh)*0.5
                love.graphics.setColor(S.signFill)
                love.graphics.rectangle("fill", lx, ly, lw, lh)

            -- PHASE 3 — VERTICAL EXPANSION
            elseif p == 3 then
                local k = math.min(1, t/d.vert)
                local lh = 2 + (boxH - 2)*k
                local ly = boxY + (boxH - lh)*0.5
                love.graphics.setColor(S.signFill)
                love.graphics.rectangle("fill", boxX, ly, boxW, lh)

            -- PHASE 4 / 5 — FULLY ONLINE
            elseif p >= 4 then
                love.graphics.setColor(S.signFill)
                love.graphics.rectangle("fill", boxX, boxY, boxW, boxH)
            end

            ---------------------------------------------------------
            -- TEXT (PHASE 5 ONLY)
            ---------------------------------------------------------
            if p < 5 then return end

            local tw = font:getWidth(text)
            local th = font:getHeight()
            local tx = boxX + (boxW - tw)*0.5
            local ty = boxY + (boxH - th)*0.5

            ---------------------------------------------------------
            -- TEXT GLITCH OFFSET
            ---------------------------------------------------------
            local gx, gy = tx, ty
            local galpha = inst.textAlpha

            if inst.glitchState == "glitch" then
                gx = gx + love.math.random(-1, 1)
                gy = gy + love.math.random(-1, 1)
                galpha = galpha * (0.6 + love.math.random() * 0.4)
            end

            ---------------------------------------------------------
            -- TEXT GLOW
            ---------------------------------------------------------
            if galpha > 0 then
                love.graphics.setColor(1,1,1,galpha * 0.08)
                love.graphics.rectangle("fill",
                    gx - 6, gy - 4, tw + 12, th + 8,
                    6, 6
                )
            end

            ---------------------------------------------------------
            -- DRAW TEXT
            ---------------------------------------------------------
            love.graphics.setColor(
                S.signText[1], S.signText[2], S.signText[3],
                galpha
            )
            love.graphics.print(text, gx, gy)
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