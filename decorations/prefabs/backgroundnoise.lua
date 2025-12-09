return function(Decorations)

------------------------------------------------------------
-- CONFIG
------------------------------------------------------------
local NoiseColor = {0, 0, 0, 0}   -- subtle alpha
local POINT_SIZE = 4               -- visible but gentle
local DENSITY_TILE_FACTOR = 2200     -- lower = denser noise

------------------------------------------------------------
-- Generate procedural noise points
------------------------------------------------------------
local function generateNoise(inst)
    local area = inst.w * inst.h
    local count = math.floor(area / DENSITY_TILE_FACTOR)
    count = math.max(count, 30)

    local pts = {}

    for i = 1, count do
        local ox = math.random() * inst.w
        local oy = math.random() * inst.h

        local r = math.random()

        if r < 0.4 then
            ------------------------------------------------
            -- DOT
            ------------------------------------------------
            pts[#pts+1] = {
                kind = "dot",
                ox = ox,
                oy = oy,
            }

        elseif r < 0.7 then
            ------------------------------------------------
            -- HORIZONTAL DASH
            ------------------------------------------------
            local len = math.random(2, 6)
            pts[#pts+1] = {
                kind = "dash",
                ox1 = ox - len,
                oy1 = oy,
                ox2 = ox + len,
                oy2 = oy,
            }

        else
            ------------------------------------------------
            -- VERTICAL DASH
            ------------------------------------------------
            local len = math.random(2, 6)
            pts[#pts+1] = {
                kind = "dash",
                ox1 = ox,
                oy1 = oy - len,
                ox2 = ox,
                oy2 = oy + len,
            }
        end
    end

    inst.noise = pts
end
------------------------------------------------------------
-- Prefab
------------------------------------------------------------
local prefab = {
    -- NOTE: w/h from chamber entry override these.
    w = 1,
    h = 1,

    init = function(inst, entry)
        ----------------------------------------------------
        -- Correct tile-region sizing:
        -- entry.w and entry.h are tile counts.
        ----------------------------------------------------
        local ts = inst.config.tileSize or 48

        if entry.w then inst.w = entry.w * ts end
        if entry.h then inst.h = entry.h * ts end

        generateNoise(inst)
    end,

    draw = function(x, y, w, h, inst)
        if not inst.noise then return end

        love.graphics.setColor(NoiseColor)
        love.graphics.setLineWidth(4)
        love.graphics.setPointSize(POINT_SIZE)

        for _, n in ipairs(inst.noise) do
            if n.kind == "dot" then
                love.graphics.points(x + n.ox, y + n.oy)

            else -- dash
                love.graphics.line(
                    x + n.ox1, y + n.oy1,
                    x + n.ox2, y + n.oy2
                )
            end
        end
    end,
}

Decorations.register("backgroundnoise", prefab)

end