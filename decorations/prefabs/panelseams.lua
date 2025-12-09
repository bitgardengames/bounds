return function(Decorations)

--------------------------------------------------------------
-- COLORS & CONSTANTS
--------------------------------------------------------------
local SEAM_COLOR   = {0, 0, 0, 0.28}
local TOKEN_COLOR  = {0, 0, 0, 0.26}
local LINE_WIDTH   = 4
local TOKEN_WIDTH  = 3

local MIN_W, MAX_W = 64, 160
local MIN_H, MAX_H = 48, 120

local GRID = 12   -- internal grid snapping

--------------------------------------------------------------
-- Utility helpers
--------------------------------------------------------------
local function snap(x)
    return math.floor(x / GRID + 0.5) * GRID
end

local function randSnap(min, max)
    return snap(math.random(min, max))
end

local function insetBox(p, inset)
    return {
        x = p.x + inset,
        y = p.y + inset,
        w = p.w - inset * 2,
        h = p.h - inset * 2,
    }
end

--------------------------------------------------------------
-- Base panel segmentation
--------------------------------------------------------------
local function generateBasePanels(inst)
    local panels = {}
    local x0, y0, W, H = inst.x, inst.y, inst.w, inst.h

    local cursorY = 0
    while cursorY < H do
        local rowH = math.random(MIN_H, MAX_H)
        if cursorY + rowH > H then rowH = H - cursorY end

        local cursorX = 0
        while cursorX < W do
            local colW = math.random(MIN_W, MAX_W)
            if cursorX + colW > W then colW = W - cursorX end

            panels[#panels+1] = {
                x = x0 + cursorX,
                y = y0 + cursorY,
                w = colW,
                h = rowH,
                tokens = {},
                archetype = nil,
            }

            cursorX = cursorX + colW
        end

        cursorY = cursorY + rowH
    end

    inst.panels = panels
end

--------------------------------------------------------------
-- Archetype generators
--------------------------------------------------------------

local function genAccessPanel(p)
    -- hatch rectangle
    local inner = insetBox(p, 12)
    local hatchW = snap(inner.w * 0.6)
    local hatchH = snap(inner.h * 0.4)
    local hx = snap(inner.x + inner.w * 0.2)
    local hy = snap(inner.y + inner.h * 0.3)

    p.tokens[#p.tokens+1] = { kind="hatch", x=hx, y=hy, w=hatchW, h=hatchH }

    -- bolts in corners
    local boltR = 4
    local function bolt(x,y)
        p.tokens[#p.tokens+1] = { kind="dot", x=x, y=y, r=boltR }
    end

    bolt(hx, hy)
    bolt(hx + hatchW, hy)
    bolt(hx, hy + hatchH)
    bolt(hx + hatchW, hy + hatchH)
end

local function genUtilityCluster(p)
    local inner = insetBox(p, 14)

    local num = math.random(2, 3)
    local boxW = snap(inner.w * 0.25)
    local boxH = snap(inner.h * 0.22)
    local startY = inner.y + GRID

    for i = 1, num do
        local y = snap(startY + (i-1)*(boxH + GRID))
        if y + boxH <= inner.y + inner.h then
            p.tokens[#p.tokens+1] = { kind="rect", x=inner.x, y=y, w=boxW, h=boxH }
        end
    end
end

local function genMultiBus(p)
    local inset = insetBox(p, 10)
    local y1 = snap(inset.y + inset.h * 0.35)
    local y2 = snap(inset.y + inset.h * 0.55)
    local x1 = inset.x + 6
    local x2 = inset.x + inset.w - 6

    p.tokens[#p.tokens+1] = { kind="bus", x1=x1, y=y1, x2=x2 }
    p.tokens[#p.tokens+1] = { kind="bus", x1=x1, y=y2, x2=x2 }

    -- add connection nodes
    p.tokens[#p.tokens+1] = { kind="dot", x=x1, y=y1, r=4 }
    p.tokens[#p.tokens+1] = { kind="dot", x=x2, y=y2, r=4 }
end

local function genDiagnostics(p)
    local inner = insetBox(p, 14)
    local cols = math.random(3,4)
    local rows = math.random(2,3)
    local spacingX = snap(inner.w / (cols + 1))
    local spacingY = snap(inner.h / (rows + 1))

    for iy = 1, rows do
        for ix = 1, cols do
            local x = snap(inner.x + ix*spacingX)
            local y = snap(inner.y + iy*spacingY)
            p.tokens[#p.tokens+1] = { kind="dot", x=x, y=y, r=3 }
        end
    end
end

local function genMounts(p)
    -- four corners
    local inset = 12
    local function m(x,y)
        p.tokens[#p.tokens+1] = { kind="mount", x=x, y=y }
    end

    m(p.x + inset,          p.y + inset)
    m(p.x + p.w - inset-8,  p.y + inset)
    m(p.x + inset,          p.y + p.h - inset-8)
    m(p.x + p.w - inset-8,  p.y + p.h - inset-8)
end

local function genCircuitBlock(p)
    local inner = insetBox(p, 16)
    local block = {
        kind="rect",
        x = snap(inner.x + inner.w * 0.25),
        y = snap(inner.y + inner.h * 0.25),
        w = snap(inner.w * 0.5),
        h = snap(inner.h * 0.35),
    }
    p.tokens[#p.tokens+1] = block

    -- small side nodes
    p.tokens[#p.tokens+1] = { kind="dot", x=block.x - 6, y=block.y + block.h/2, r=4 }
    p.tokens[#p.tokens+1] = { kind="dot", x=block.x + block.w + 6, y=block.y + block.h/2, r=4 }
end

--------------------------------------------------------------
-- Assign archetypes with weighted randomness
--------------------------------------------------------------
local function assignLayouts(inst)
    for _, p in ipairs(inst.panels) do
        local r = math.random()

        if r < 0.22 then
            p.archetype = "access"
            genAccessPanel(p)

        elseif r < 0.40 then
            p.archetype = "utility"
            genUtilityCluster(p)

        elseif r < 0.58 then
            p.archetype = "bus"
            genMultiBus(p)

        elseif r < 0.75 then
            p.archetype = "diagnostic"
            genDiagnostics(p)

        elseif r < 0.88 then
            p.archetype = "mounts"
            genMounts(p)

        else
            p.archetype = "circuit"
            genCircuitBlock(p)
        end
    end
end

--------------------------------------------------------------
-- Rendering
--------------------------------------------------------------
local function drawPanels(inst)
    love.graphics.setLineWidth(LINE_WIDTH)
    love.graphics.setColor(SEAM_COLOR)

    for _, p in ipairs(inst.panels) do
        -- seam rectangle
        love.graphics.rectangle("line", p.x, p.y, p.w, p.h)

        -- tokens
        love.graphics.setLineWidth(TOKEN_WIDTH)
        love.graphics.setColor(TOKEN_COLOR)

        for _, t in ipairs(p.tokens) do
            if t.kind == "rect" then
                love.graphics.rectangle("line", t.x, t.y, t.w, t.h)

            elseif t.kind == "hatch" then
                love.graphics.rectangle("line", t.x, t.y, t.w, t.h)

            elseif t.kind == "dot" then
                love.graphics.circle("fill", t.x, t.y, t.r)

            elseif t.kind == "bus" then
                love.graphics.line(t.x1, t.y, t.x2, t.y)

            elseif t.kind == "mount" then
                love.graphics.rectangle("fill", t.x, t.y, 8, 8)
            end
        end
    end
end

--------------------------------------------------------------
-- Prefab
--------------------------------------------------------------
local prefab = {
    init = function(inst, entry)
        local ts = inst.config.tileSize or 48
        if entry.w then inst.w = entry.w * ts end
        if entry.h then inst.h = entry.h * ts end

        generateBasePanels(inst)
        assignLayouts(inst)
    end,

    draw = function(x,y,w,h,inst)
        drawPanels(inst)
    end
}

Decorations.register("panelseams", prefab)

end