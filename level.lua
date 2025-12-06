--------------------------------------------------------------
--  LEVEL MODULE — supports separate FRAME + SOLIDS layers
--  FRAME = outer chamber walls (dark)
--  SOLIDS = gameplay platforms (light, inset visually)
--------------------------------------------------------------

local Theme = require("theme")
local Decorations = require("decorations")

local Level = {}

--------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------

Level.colors = Theme.level

local OUTLINE_WIDTH   = 4
local TILE_CORNER_R   = 6

--------------------------------------------------------------
-- INTERNAL STATE
--------------------------------------------------------------

Level.tileSize    = 48
Level.width       = 0
Level.height      = 0

Level.layers      = {}
Level.frameLayer  = nil
Level.solidLayer  = nil

Level.solidGrid   = nil     -- Combined tile grid (Frame + Solids)
Level.frameBlobs  = {}
Level.solidBlobs  = {}
Level.gridCanvas  = nil
Level.gridCanvas  = nil
Level.decorCanvas = nil   -- <-- NEW

local OUTLINE_OFFSETS = {
    {-OUTLINE_WIDTH, 0}, {OUTLINE_WIDTH, 0},
    {0, -OUTLINE_WIDTH}, {0, OUTLINE_WIDTH},
    {-OUTLINE_WIDTH, -OUTLINE_WIDTH}, {-OUTLINE_WIDTH, OUTLINE_WIDTH},
    { OUTLINE_WIDTH, -OUTLINE_WIDTH}, { OUTLINE_WIDTH, OUTLINE_WIDTH},
}

--------------------------------------------------------------
-- UTILS
--------------------------------------------------------------

local function newGrid(w, h, value)
    local g = {}
    for y = 1, h do
        g[y] = {}
        for x = 1, w do
            g[y][x] = value
        end
    end
    return g
end

--------------------------------------------------------------
-- TILEMAP BUILDING
--------------------------------------------------------------

local function buildTilesFromRects(layer, width, height)
    local tiles = newGrid(width, height, false)
    for _, r in ipairs(layer.rects or {}) do
        local x1 = r.x
        local y1 = r.y
        local x2 = r.x + r.w - 1
        local y2 = r.y + r.h - 1

        for ty = y1, y2 do
            if ty >= 1 and ty <= height then
                for tx = x1, x2 do
                    if tx >= 1 and tx <= width then
                        tiles[ty][tx] = true
                    end
                end
            end
        end
    end
    return tiles
end

--------------------------------------------------------------
-- GRID VISUALIZATION CANVAS
--------------------------------------------------------------

local function buildGridCanvas(width, height, tileSize)
    local gw = width * tileSize
    local gh = height * tileSize
    local canvas = love.graphics.newCanvas(gw, gh)

    love.graphics.push()
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 0)

    love.graphics.setColor(Level.colors.grid)

    for x = 0, gw, tileSize do
        love.graphics.rectangle("fill", x - 2, 0, 4, gh)
    end

    for y = 0, gh, tileSize do
        love.graphics.rectangle("fill", 0, y - 2, gw, 4)
    end

    love.graphics.setCanvas()
    love.graphics.pop()

    return canvas
end

--------------------------------------------------------------
-- BLOB BUILDER
--------------------------------------------------------------

local function buildBlobsFromTiles(tiles, width, height, tileSize)
    local visited = newGrid(width, height, false)
    local blobs   = {}

    local dirs = {
        { 1,  0}, {-1, 0},
        { 0,  1}, { 0,-1},
    }

    for ty = 1, height do
        for tx = 1, width do
            if tiles[ty][tx] and not visited[ty][tx] then

                local queue = { {tx, ty} }
                local qi = 1
                visited[ty][tx] = true

                local cells = {}
                local minX, maxX = tx, tx
                local minY, maxY = ty, ty

                while qi <= #queue do
                    local cx, cy = queue[qi][1], queue[qi][2]
                    qi = qi + 1
                    table.insert(cells, {cx, cy})

                    if cx < minX then minX = cx end
                    if cx > maxX then maxX = cx end
                    if cy < minY then minY = cy end
                    if cy > maxY then maxY = cy end

                    for _, d in ipairs(dirs) do
                        local nx, ny = cx + d[1], cy + d[2]
                        if nx>=1 and nx<=width and ny>=1 and ny<=height then
                            if tiles[ny][nx] and not visited[ny][nx] then
                                visited[ny][nx] = true
                                queue[#queue+1] = {nx, ny}
                            end
                        end
                    end
                end

                local blobW = (maxX - minX + 1) * tileSize
                local blobH = (maxY - minY + 1) * tileSize

                local canvas = love.graphics.newCanvas(blobW, blobH)
                love.graphics.push()
                love.graphics.setCanvas(canvas)
                love.graphics.clear(0,0,0,0)
                love.graphics.setColor(1,1,1,1)
                love.graphics.setBlendMode("alpha", "premultiplied")

                for _, c in ipairs(cells) do
                    local px = (c[1] - minX) * tileSize
                    local py = (c[2] - minY) * tileSize
                    love.graphics.rectangle("fill", px, py, tileSize, tileSize)
                end

                love.graphics.setBlendMode("alpha")
                love.graphics.setCanvas()
                love.graphics.pop()

                table.insert(blobs, {
                    canvas = canvas,
                    x      = (minX - 1) * tileSize,
                    y      = (minY - 1) * tileSize,
                    w      = blobW,
                    h      = blobH,
                })
            end
        end
    end

    return blobs
end

--------------------------------------------------------------
-- PUBLIC TILE QUERIES
--------------------------------------------------------------

function Level.isSolidTile(tx, ty)
    if tx < 1 or ty < 1 or tx > Level.width or ty > Level.height then
        return false
    end
    return Level.solidGrid[ty][tx] == true
end

--------------------------------------------------------------
-- PIXEL COLLISION QUERY (needed for laser raycast)
--------------------------------------------------------------
function Level.isSolidAt(px, py)
    -- convert pixel > tile
    local ts = Level.tileSize
    local tx = math.floor(px / ts) + 1
    local ty = math.floor(py / ts) + 1

    return Level.isSolidTile(tx, ty)
end

--------------------------------------------------------------
-- LOAD
--------------------------------------------------------------

function Level.load(data)
    Level.tileSize = data.tileSize or 48
    Level.width    = data.width
    Level.height   = data.height
    Level.layers   = {}

    Level.solidLayer = nil
    Level.frameLayer = nil

    Level.solidGrid  = newGrid(Level.width, Level.height, false)
    Level.solidBlobs = {}
    Level.frameBlobs = {}

    for _, src in ipairs(data.layers or {}) do
        local layer = {
            name  = src.name or "Layer",
            kind  = src.kind or "rectlayer",
            solid = src.solid or false,
            frame = src.frame or false,
            rects = src.rects or {},
        }

        layer.tiles = buildTilesFromRects(layer, Level.width, Level.height)
        table.insert(Level.layers, layer)

        if layer.solid and layer.frame then
            Level.frameLayer = layer
        elseif layer.solid then
            Level.solidLayer = layer
        end
    end

    assert(Level.solidLayer, "No Solids layer in leveldata")

    for y = 1, Level.height do
        for x = 1, Level.width do
            if Level.solidLayer.tiles[y][x] then Level.solidGrid[y][x] = true end
            if Level.frameLayer and Level.frameLayer.tiles[y][x] then
                Level.solidGrid[y][x] = true
            end
        end
    end

    Level.solidBlobs = buildBlobsFromTiles(
        Level.solidLayer.tiles, Level.width, Level.height, Level.tileSize
    )

    if Level.frameLayer then
        Level.frameBlobs = buildBlobsFromTiles(
            Level.frameLayer.tiles, Level.width, Level.height, Level.tileSize
        )
    end

    Level.gridCanvas = buildGridCanvas(Level.width, Level.height, Level.tileSize)

    -- Decorations canvas (same size as play area)
    local gw = Level.width  * Level.tileSize
    local gh = Level.height * Level.tileSize
    Level.decorCanvas = love.graphics.newCanvas(gw, gh, {msaa = 8})
end

--------------------------------------------------------------
-- DRAW HELPERS
--------------------------------------------------------------

local function drawBlobs(blobs, color, inset)
    inset = inset or 0 -- per-layer inset

    for _, blob in ipairs(blobs) do
        local cv = blob.canvas
        local x  = blob.x
        local y  = blob.y
        local w  = blob.w
        local h  = blob.h

        ------------------------------------------------------
        -- OUTLINE
        ------------------------------------------------------
        local ox = x + inset
        local oy = y + inset
        local sx = (w - inset * 2) / w
        local sy = (h - inset * 2) / h

        love.graphics.setColor(Theme.outline)
        for _, o in ipairs(OUTLINE_OFFSETS) do
            love.graphics.draw(cv, ox + o[1], oy + o[2], 0, sx, sy)
        end

        ------------------------------------------------------
        -- FILL
        ------------------------------------------------------
        love.graphics.setColor(color)
        love.graphics.draw(cv, ox, oy, 0, sx, sy)
    end
end

--------------------------------------------------------------
-- DRAW
--------------------------------------------------------------

function Level.draw(camX, camY)
    camX = camX or 0
    camY = camY or 0

    love.graphics.push()
    love.graphics.translate(-camX, -camY)

	-- OUTER FRAME BACKDROP (exactly 4px outward)
	do
		local ts = Level.tileSize
		local w  = Level.width  * ts
		local h  = Level.height * ts

		love.graphics.setColor(Level.colors.outer)

		-- Expand by 4px on all sides
		local pad = 4
		love.graphics.rectangle(
			"fill",
			-pad,
			-pad,
			w + pad*2,
			h + pad*2
		)
	end

	-- INNER PLAY AREA BACKDROP (reduced & shifted)
	do
		local ts = Level.tileSize

		-- shrink by 2 tiles horizontally + 2 tiles vertically
		local w = Level.width  * ts - ts * 2   -- minus 2 tiles width
		local h = Level.height * ts - ts * 2   -- minus 2 tiles height

		-- move right 1 tile, down 1 tile
		local ox = ts * 1
		local oy = ts * 1

		love.graphics.setColor(Level.colors.background)
		love.graphics.rectangle(
			"fill",
			ox,
			oy,
			w,
			h
		)
	end

    if Level.gridCanvas then
        love.graphics.setColor(Level.colors.grid)
        love.graphics.draw(Level.gridCanvas, 0, 0)
    end

    ----------------------------------------------------------------
    -- DECORATIONS + SIMPLE SHADOW
    ----------------------------------------------------------------
    if Level.decorCanvas then
        -- 1) Render decorations into their own canvas
        love.graphics.setCanvas(Level.decorCanvas)
        love.graphics.clear(0, 0, 0, 0)

        -- NOTE: we don't touch transforms; Level.draw already applied
        -- the camera translate before this call.
        Decorations.draw()

        love.graphics.setCanvas()

        -- 2) Draw shadow (offset, tinted)
        love.graphics.setColor(0, 0, 0, 0.18)  -- shadow opacity
        local shadowOffsetX = 4
        local shadowOffsetY = 6
        love.graphics.draw(Level.decorCanvas, shadowOffsetX, shadowOffsetY)

        -- 3) Draw actual decorations
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(Level.decorCanvas, 0, 0)
    else
        -- Fallback: no canvas available, just draw normally
        Decorations.draw()
    end

    -- SOLIDS (inset by 2px per side)
    drawBlobs(Level.solidBlobs, Level.colors.solid, 2)

	-- INNER BLACK OUTLINE (aligned to inner play-area backdrop)
	do
		local ts = Level.tileSize

		-- same values used for the play-area backdrop
		local w = Level.width  * ts - ts * 2
		local h = Level.height * ts - ts * 2
		local ox = ts * 1
		local oy = ts * 1

                love.graphics.setColor(Theme.outline)
		love.graphics.setLineWidth(4)

		-- outline *inside* the inner play area
		love.graphics.rectangle("line", ox, oy, w, h)
	end

    love.graphics.pop()
end

return Level