return function(Decorations)
        Decorations.register("fan", {
                w = 1,
                h = 1,

                init = function(inst, entry)
                        local d = inst.data or {}
                        d.active = not (entry and entry.active == false)

                        if not d.active then
                                d.angle = d.angle or (love.math.random() * math.pi * 2)
                        end

                        inst.data = d
                end,

                draw = function(x, y, w, h, inst)
                        local S = Decorations.style
                        local d = inst.data or {}

                        -- Center of the tile in pixel coords
                        local cx = x + w/2
                        local cy = y + h/2

                        -- Fan radius
                        local r = w * 0.42

                        -- Spin animation (same as before)
                        local t = love.timer.getTime()
                        local angle = (d.active ~= false) and (t * 1.8) or (d.angle or 0)

			----------------------------------------------------------
			-- OUTER OUTLINE RING
			----------------------------------------------------------
			love.graphics.setColor(S.outline)
			love.graphics.circle("fill", cx, cy, r + 4)

			----------------------------------------------------------
			-- DARK CAVITY BACKDROP
			----------------------------------------------------------
			love.graphics.setColor(S.dark)
			love.graphics.circle("fill", cx, cy, r)

			----------------------------------------------------------
			-- BLADES
			----------------------------------------------------------
			love.graphics.push()
			love.graphics.translate(cx, cy)
			love.graphics.rotate(angle)

			love.graphics.setColor(S.metal)

			local bladeCount = 4
			local bladeW     = 6
			local bladeL     = r - 3

			for _ = 1, bladeCount do
				love.graphics.rotate(math.pi * 0.5)
				love.graphics.rectangle(
					"fill",
					-bladeW/2,
					-bladeL,
					bladeW,
					bladeL,
					4, 4
				)
			end

			love.graphics.pop()

			----------------------------------------------------------
			-- CENTER HUB (NEW — matches fan_large and fan_3 style)
			----------------------------------------------------------
			-- Outer dark hub
			love.graphics.setColor(S.dark)
			love.graphics.circle("fill", cx, cy, 6)

			-- Inner metal cap
			love.graphics.setColor(S.metal)
			love.graphics.circle("fill", cx, cy, 2)
		end,
	})

    Decorations.register("fan_large", {
        w = 2,
        h = 2,

        init = function(inst, entry)
            local d = inst.data or {}
            d.active = not (entry and entry.active == false)

            if d.active then
                d.fanSpeed = d.fanSpeed or 1.0
                d.targetSpeed = d.targetSpeed or 1.0
                d.state = d.state or "normal"
                d.stateTimer = d.stateTimer or 0
                d.nextEvent = d.nextEvent or (love.math.random(20, 30) + love.math.random())
                d.angle = d.angle or 0
            else
                d.fanSpeed = 0
                d.targetSpeed = 0
                d.state = "static"
                d.stateTimer = 0
                d.nextEvent = 0
                d.angle = d.angle or (love.math.random() * math.pi * 2)
            end

            inst.data = d
        end,

        update = function(inst, dt)
            local d = inst.data

            if d.active == false then
                return
            end

            if d.state == "normal" then
                d.targetSpeed = 1.0
                d.nextEvent = d.nextEvent - dt
                if d.nextEvent <= 0 then
                    d.state = "wind_down"
                    d.stateTimer = 0
                end

            elseif d.state == "wind_down" then
                d.targetSpeed = 0.0
                if d.fanSpeed <= 0.10 then
                    d.state = "pause"
                    d.stateTimer = 0
                    d.pauseDuration = 16 + love.math.random() * 2.4
                end

            elseif d.state == "pause" then
                d.stateTimer = d.stateTimer + dt
                d.targetSpeed = 0.0
                if d.stateTimer >= d.pauseDuration then
                    d.state = "spin_up"
                    d.stateTimer = 0
                end

            elseif d.state == "spin_up" then
                d.targetSpeed = 1.0
                if d.fanSpeed >= 0.995 then
                    d.state = "normal"
                    d.nextEvent = love.math.random(10, 28)
                end
            end

            local accelRate = 1.25
            local brakeRate = 0.45
            local rate = (d.targetSpeed > d.fanSpeed) and accelRate or brakeRate

            d.fanSpeed = d.fanSpeed + (d.targetSpeed - d.fanSpeed) * (1 - math.exp(-rate * dt))

            if d.fanSpeed < 0 then d.fanSpeed = 0 end
            if d.fanSpeed > 1 then d.fanSpeed = 1 end

            d.angle = (d.angle or 0) + dt * (1.8 * d.fanSpeed)

            if d.angle > math.pi * 2 then
                d.angle = d.angle - math.pi * 2
            end
        end,

        draw = function(x, y, w, h, inst)
            local S  = Decorations.style
            local cx = x + w/2
            local cy = y + h/2
            local d  = inst.data

            local inset = 8
            local hx = x + inset
            local hy = y + inset
            local hw = w - inset * 2
            local hh = h - inset * 2

            local housingRadius = 10

            love.graphics.setColor(S.outline)
            love.graphics.rectangle(
                "fill",
                hx - 4, hy - 4,
                hw + 8, hh + 8,
                housingRadius + 6, housingRadius + 6
            )

            love.graphics.setColor(S.metal)
            love.graphics.rectangle(
                "fill",
                hx, hy,
                hw, hh,
                housingRadius, housingRadius
            )

            love.graphics.setColor(S.dark)
            local boltR = 3

            local bx1 = hx + 10
            local bx2 = hx + hw - 10
            local by1 = hy + 10
            local by2 = hy + hh - 10

            love.graphics.circle("fill", bx1, by1, boltR)
            love.graphics.circle("fill", bx2, by1, boltR)
            love.graphics.circle("fill", bx1, by2, boltR)
            love.graphics.circle("fill", bx2, by2, boltR)

            local cavityOuterR = hw * 0.42

            love.graphics.setColor(S.outline)
            love.graphics.setLineWidth(4)
            love.graphics.circle("line", cx, cy, cavityOuterR)

            local cavityInnerR = cavityOuterR - 2
            love.graphics.setColor(S.dark)
            love.graphics.circle("fill", cx, cy, cavityInnerR)

            local angle = d.angle or 0

            love.graphics.push()
            love.graphics.translate(cx, cy)
            love.graphics.rotate(angle)

            local bladeW = 8
            local bladeL = cavityInnerR - 4

            love.graphics.setColor(S.metal)
            for _ = 1, 4 do
                love.graphics.rotate(math.pi * 0.5)
                love.graphics.rectangle(
                    "fill",
                    -bladeW/2,
                    -bladeL,
                    bladeW,
                    bladeL,
                    4, 4
                )
            end

            love.graphics.pop()

            love.graphics.setColor(S.dark)
            love.graphics.circle("fill", cx, cy, 8)

            love.graphics.setColor(S.metal)
            love.graphics.circle("fill", cx, cy, 4)
        end,
    })

	Decorations.register("fan_3", {
		w = 3,
		h = 3,

                init = function(inst, entry)
                        local d = inst.data or {}
                        d.active = not (entry and entry.active == false)

                        d.angle = d.angle or ((d.active ~= false) and 0 or (love.math.random() * math.pi * 2))
                        d.speed = d.speed or ((d.active ~= false) and 0.30 or 0)

                        inst.data = d
                end,

                update = function(inst, dt)
                        local d = inst.data

                        if d.active == false then
                                return
                        end

                        d.angle = (d.angle + dt * d.speed) % (math.pi * 2)
                end,

		draw = function(x, y, w, h, inst)
			local S = Decorations.style
			local d = inst.data

			----------------------------------------------------------
			-- PIXEL DIMENSIONS (Decorations already converted tiles)
			----------------------------------------------------------
			local cx = x + w/2
			local cy = y + h/2
			local radius = math.min(w, h) * 0.48 -- main scale reference

			----------------------------------------------------------
			-- RING RADII
			----------------------------------------------------------
			local outerR  = radius                         -- outline ring
			local innerR  = outerR - 4                     -- 4px housing thickness
			local ringR   = innerR - 4                     -- secondary ring (outline)
			local cavityR = ringR - 12                     -- bigger dark cavity (+14px diameter total)

			----------------------------------------------------------
			-- OUTER OUTLINE RING
			----------------------------------------------------------
			love.graphics.setColor(S.outline)
			love.graphics.circle("fill", cx, cy, outerR)

			----------------------------------------------------------
			-- METAL INNER HOUSING
			----------------------------------------------------------
			love.graphics.setColor(S.metal)
			love.graphics.circle("fill", cx, cy, innerR)

			----------------------------------------------------------
			-- INNER OUTLINE RING
			----------------------------------------------------------
			love.graphics.setColor(S.outline)
			love.graphics.circle("fill", cx, cy, ringR)

			----------------------------------------------------------
			-- DARK CAVITY (expanded)
			----------------------------------------------------------
			love.graphics.setColor(S.dark)
			love.graphics.circle("fill", cx, cy, cavityR)

			----------------------------------------------------------
			-- BLADES (simple, bold, large)
			----------------------------------------------------------
			love.graphics.push()
			love.graphics.translate(cx, cy)
			love.graphics.rotate(d.angle)

			love.graphics.setColor(S.metal)

			local bladeCount  = 3
			local bladeLength = cavityR * 0.92   -- larger to match bigger cavity
			local bladeWidth  = cavityR * 0.34   -- slightly wider blade
			local cornerR     = 10

			for i = 1, bladeCount do
				love.graphics.rotate((math.pi * 2) / bladeCount)

				love.graphics.rectangle(
					"fill",
					-bladeWidth/2,
					-bladeLength,
					bladeWidth,
					bladeLength,
					cornerR, cornerR
				)
			end

			love.graphics.pop()

			----------------------------------------------------------
			-- CENTER CAP
			----------------------------------------------------------
			love.graphics.setColor(S.dark)
			love.graphics.circle("fill", cx, cy, 14)

			love.graphics.setColor(S.metal)
			love.graphics.circle("fill", cx, cy, 8)
		end,
	})
end