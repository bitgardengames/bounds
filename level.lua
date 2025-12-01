--------------------------------------------------------------
--  NEW LEVEL MODULE — table-driven tilemap → canvas blobs
--  FIXED MARGIN ALIGNMENT VERSION
--------------------------------------------------------------

local Level = {}

--------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------

Level.colors = {
    background = {82/255, 101/255, 114/255},
    solid = {164/255, 171/255, 172/255},
	grid = {68/255, 83/255, 97/255}
}

local OUTLINE_WIDTH   = 4
local SHADOW_OFFSET_X = 3
local SHADOW_OFFSET_Y = 3
local TILE_CORNER_R   = 6

--------------------------------------------------------------
-- INTERNAL STATE
--------------------------------------------------------------

Level.tileSize    = 48
Level.width       = 0
Level.height      = 0
Level.layers      = {}
Level.solidLayer  = nil
Level.solidGrid   = nil
Level.solidBlobs  = {} -- { canvas, x, y, w, h, margin }

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
-- BUILD TILES FROM RECT TABLES
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
-- GROUP CONNECTED TILES INTO BLOBS
--------------------------------------------------------------

local function buildSolidBlobs()
    local tiles = Level.solidGrid
    local w     = Level.width
    local h     = Level.height
    local ts    = Level.tileSize

    local visited = newGrid(w, h, false)
    local blobs   = {}

    local dirs = {
        { 1,  0}, {-1, 0},
        { 0,  1}, { 0,-1},
    }

    for ty = 1, h do
        for tx = 1, w do
            if tiles[ty][tx] and not visited[ty][tx] then

                ------------------------------------------------------
                -- FLOOD-FILL THIS PLATFORM BLOB
                ------------------------------------------------------
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
                        if nx>=1 and nx<=w and ny>=1 and ny<=h then
                            if tiles[ny][nx] and not visited[ny][nx] then
                                visited[ny][nx] = true
                                queue[#queue+1] = {nx, ny}
                            end
                        end
                    end
                end

                ------------------------------------------------------
                -- CREATE CANVAS **WITH NO PADDING**
                ------------------------------------------------------
                local blobW = (maxX - minX + 1) * ts
                local blobH = (maxY - minY + 1) * ts

                -- ✔ EXACT TILE SPACE — no extra margins
                local canvas = love.graphics.newCanvas(blobW, blobH)

                love.graphics.push()
                love.graphics.setCanvas(canvas)
                love.graphics.clear(0,0,0,0)

                love.graphics.setColor(1,1,1,1)
                love.graphics.setBlendMode("alpha", "premultiplied")

                ------------------------------------------------------
                -- DRAW TILE FILL AT EXACT (0,0)-BASED POSITIONS
                ------------------------------------------------------
                for _, c in ipairs(cells) do
                    local cx, cy = c[1], c[2]
                    local px = (cx - minX) * ts
                    local py = (cy - minY) * ts

                    love.graphics.rectangle("fill", px, py, ts, ts)
                end

                love.graphics.setBlendMode("alpha")
                love.graphics.setCanvas()
                love.graphics.pop()

                ------------------------------------------------------
                -- STORE BLOB
                ------------------------------------------------------
                table.insert(blobs, {
                    canvas = canvas,
                    x      = (minX - 1) * ts,   -- perfect world alignment
                    y      = (minY - 1) * ts,
                    w      = blobW,
                    h      = blobH,
                    margin = 0,                 -- ✔ no padding anymore
                })
            end
        end
    end

    Level.solidBlobs = blobs
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

function Level.tileAt(tx, ty)
    return Level.isSolidTile(tx, ty) and "#" or "."
end

function Level.isSolidWorld(x, y)
    local ts = Level.tileSize
    local tx = math.floor(x / ts) + 1
    local ty = math.floor(y / ts) + 1
    return Level.isSolidTile(tx, ty)
end

--------------------------------------------------------------
-- LOAD
--------------------------------------------------------------

function Level.load(data)
    Level.tileSize = data.tileSize or 32
    Level.width    = data.width
    Level.height   = data.height
    Level.layers   = {}

    Level.solidLayer = nil
    Level.solidGrid  = nil
    Level.solidBlobs = {}

    for _, src in ipairs(data.layers or {}) do
        local layer = {
            name  = src.name or "Layer",
            kind  = src.kind or "rectlayer",
            solid = src.solid or false,
            rects = src.rects or {},
        }

        layer.tiles = buildTilesFromRects(layer, Level.width, Level.height)
        table.insert(Level.layers, layer)

        if layer.solid then
            Level.solidLayer = layer
            Level.solidGrid  = layer.tiles
        end
    end

    assert(Level.solidGrid, "No solid layer configured in leveldata")

    buildSolidBlobs()
end

--------------------------------------------------------------
-- DRAW
--------------------------------------------------------------

function Level.draw(camX, camY)
    camX = camX or 0
    camY = camY or 0

    love.graphics.push()
    love.graphics.translate(-camX, -camY)

    ----------------------------------------------------------
    -- GRID
    ----------------------------------------------------------
    local ts = Level.tileSize
    local gw = Level.width  * ts
    local gh = Level.height * ts

    love.graphics.setColor(Level.colors.grid)

    -- vertical lines
    for x = 0, gw, ts do
        love.graphics.rectangle("fill", x - 2, 0, 4, gh)
    end

    -- horizontal lines
    for y = 0, gh, ts do
        love.graphics.rectangle("fill", 0, y - 2, gw, 4)
    end


    ----------------------------------------------------------
    -- PLATFORM BLOBS
    ----------------------------------------------------------
    local solid = Level.colors.solid
    local r = OUTLINE_WIDTH

    for _, blob in ipairs(Level.solidBlobs) do
        local cv = blob.canvas
        local x  = blob.x         -- now EXACT tile alignment
        local y  = blob.y

        ------------------------------------------------------
        -- SHADOW (draw first)
        ------------------------------------------------------
        --love.graphics.setColor(0, 0, 0, 0.30)
        --love.graphics.draw(cv, x + SHADOW_OFFSET_X, y + SHADOW_OFFSET_Y)

        ------------------------------------------------------
        -- OUTLINE (8-directional copies)
        ------------------------------------------------------
        love.graphics.setColor(0,0,0,1)

        local offs = {
            {-r, 0}, {r, 0},
            {0, -r}, {0, r},
            {-r,-r}, {-r, r},
            { r,-r}, { r, r},
        }

        for _, o in ipairs(offs) do
            love.graphics.draw(cv, x + o[1], y + o[2])
        end

        ------------------------------------------------------
        -- FILL (actual platform)
        ------------------------------------------------------
        love.graphics.setColor(solid)
        love.graphics.draw(cv, x, y)
    end

    love.graphics.pop()
end

return Level