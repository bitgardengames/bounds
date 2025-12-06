local Theme = require("theme")
local S = Theme.decorations

return function(Decorations)
    Decorations.register("platform_track_h", {
        w = 1, h = 1,

        draw = function(x, y, w, h)
            local fill = 4
            local outline = 4

            local thick = fill + outline*2
            local cy = y + h/2 - thick/2

            love.graphics.setColor(S.outline)
            love.graphics.rectangle("fill", x, cy, w, thick)

            love.graphics.setColor(S.metal)
            love.graphics.rectangle("fill",
                x,
                cy + outline,
                w,
                fill
            )
        end,
    })

    Decorations.register("platform_track_v", {
        w = 1, h = 1,

        draw = function(x, y, w, h)
            local fill = 4
            local outline = 4

            local thick = fill + outline*2
            local cx = x + w/2 - thick/2

            love.graphics.setColor(S.outline)
            love.graphics.rectangle("fill", cx, y, thick, h)

            love.graphics.setColor(S.metal)
            love.graphics.rectangle("fill",
                cx + outline,
                y,
                fill,
                h
            )
        end,
    })

	Decorations.register("platform_track_left", {
		w = 1, h = 1,

		draw = function(x, y, w, h)
			local fill    = 4
			local outline = 4
			local thick   = fill + outline * 2   -- 12px tall

			-- Match vertical placement of platform_track_h
			local cy      = y + h/2 - thick/2
			local midY    = cy + thick/2

			-- Right half width
			local capW    = w / 2

			-- ORIGINAL tile-center boundary
			local cxLeft  = x + w/2

			-- NEW: extend 4px left
			local extend  = 4
			local rectX   = cxLeft - extend
			local rectW   = capW + extend

			-- Updated circle center
			local circleCX = cxLeft - extend

			-------------------------------------------------
			-- OUTLINE
			-------------------------------------------------
			love.graphics.setColor(S.outline)

			-- Rect body (extended 4px left)
			love.graphics.rectangle(
				"fill",
				rectX,
				cy,
				rectW,
				thick
			)

			-- Rounded left cap
			local outlineRadius = thick / 2
			love.graphics.circle(
				"fill",
				circleCX,
				midY,
				outlineRadius
			)

			-------------------------------------------------
			-- INNER METAL
			-------------------------------------------------
			love.graphics.setColor(S.metal)

			local innerH     = fill
			local innerY     = cy + outline
			local innerMidY  = innerY + innerH / 2
			local innerRectX = rectX
			local innerRectW = rectW
			local innerR     = innerH / 2

			-- Inner rect
			love.graphics.rectangle(
				"fill",
				innerRectX,
				innerY,
				innerRectW,
				innerH
			)

			-- Rounded inner cap
			love.graphics.circle(
				"fill",
				circleCX,
				innerMidY,
				innerR
			)
		end,
	})

	Decorations.register("platform_track_right", {
		w = 1, h = 1,

		draw = function(x, y, w, h)
			local fill    = 4
			local outline = 4
			local thick   = fill + outline * 2   -- 12px tall
			local extend  = 4                    -- matches left-side extension

			-- Match vertical placement of platform_track_h
			local cy      = y + h/2 - thick/2
			local midY    = cy + thick/2

			-- Left half width
			local capW    = w / 2

			-- Tile center
			local cxRight = x + w/2

			-- MIRRORED from platform_track_left:
			-- Extend 4px *to the right*
			local rectX   = x                    -- cap sits on left half of tile
			local rectW   = capW + extend

			-- Circle center is moved 4px *to the right*
			local circleCX = cxRight + extend

			-------------------------------------------------
			-- OUTLINE
			-------------------------------------------------
			love.graphics.setColor(S.outline)

			-- Flat-left rectangle body (center → left), extended 4px right
			love.graphics.rectangle(
				"fill",
				rectX,
				cy,
				rectW,
				thick
			)

			-- Rounded right cap (mirrors left end cap logic)
			local outlineRadius = thick / 2
			love.graphics.circle(
				"fill",
				circleCX,
				midY,
				outlineRadius
			)

			-------------------------------------------------
			-- INNER METAL
			-------------------------------------------------
			love.graphics.setColor(S.metal)

			local innerH     = fill
			local innerY     = cy + outline
			local innerMidY  = innerY + innerH / 2

			local innerRectX = rectX
			local innerRectW = rectW
			local innerR     = innerH / 2

			-- Inner rect (mirror)
			love.graphics.rectangle(
				"fill",
				innerRectX,
				innerY,
				innerRectW,
				innerH
			)

			-- Inner rounded right cap
			love.graphics.circle(
				"fill",
				circleCX,
				innerMidY,
				innerR
			)
		end,
	})
	
Decorations.register("platform_track_top", {
    w = 1, h = 1,

    draw = function(x, y, w, h)
        local fill    = 4
        local outline = 4
        local thick   = fill + outline * 2   -- 12px tall
        local extend  = 4                    -- match left-side 4px extension

        -------------------------------------------------
        -- MATCH platform_track_left LOGIC, but rotated
        -------------------------------------------------

        -- Horizontal center line
        local midX = x + w/2

        -- Track occupies the TOP HALF of the tile (mirroring left)
        local capH   = h / 2     -- half-tile region
        local cy     = y + (h/2 - thick/2)   -- vertical alignment to match consistency
        local midY   = cy + thick/2

        -- Top boundary (tile center)
        local cyTop  = y + h/2

        -- EXTEND upward by 4px (mirror of “extend left”)
        local rectY  = cyTop - extend - thick
        local rectH  = capH + extend

        -- Circle center (rounded cap) moved upward by 4px
        local circleCY = cyTop - extend

        -------------------------------------------------
        -- OUTLINE
        -------------------------------------------------
        love.graphics.setColor(S.outline)

        -- Rectangle body (extended upward)
        love.graphics.rectangle(
            "fill",
            x + (w/2 - thick/2),  -- horizontally centered body
            rectY,
            thick,
            rectH
        )

        -- Rounded top cap
        local outlineRadius = thick / 2
        love.graphics.circle(
            "fill",
            midX,
            circleCY,
            outlineRadius
        )

        -------------------------------------------------
        -- INNER METAL
        -------------------------------------------------
        love.graphics.setColor(S.metal)

        local innerH    = fill
        local innerY    = rectY + outline
        local innerMidY = innerY + innerH / 2

        local innerRectX = x + (w/2 - (fill)/2)
        local innerRectW = fill

        -- Inner rect
        love.graphics.rectangle(
            "fill",
            innerRectX,
            innerY,
            innerRectW,
            innerH
        )

        -- Rounded inner top cap
        local innerR = innerH / 2
        love.graphics.circle(
            "fill",
            midX,
            innerMidY - (outline - 1),
            innerR
        )
    end,
})

end