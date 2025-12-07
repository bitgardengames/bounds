--------------------------------------------------------------
-- Liquids.lua — Final stable version with ripple polygon fill
-- + matching top-edge outline (no artifacts)
--------------------------------------------------------------

local Liquids = {}

Liquids.tileSize = 48
Liquids.blobs    = {}

Liquids.fillColor    = {0.20, 0.45, 0.70, 0.60}
Liquids.outlineColor = {0.07, 0.12, 0.18, 1.0}
Liquids.outlineWidth = 4

--------------------------------------------------------------
-- Grid helpers
--------------------------------------------------------------

local function newGrid(w, h, val)
    local g = {}
    for y=1,h do
        g[y]={}
        for x=1,w do g[y][x]=val end
    end
    return g
end

local function buildTilesFromRects(layer, width, height)
    local tiles = newGrid(width, height, false)
    for _, r in ipairs(layer.rects or {}) do
        for ty = r.y, r.y + r.h - 1 do
            if ty>=1 and ty<=height then
                for tx = r.x, r.x + r.w - 1 do
                    if tx>=1 and tx<=width then
                        tiles[ty][tx] = true
                    end
                end
            end
        end
    end
    return tiles
end

local function buildBlobsFromTiles(tiles, width, height, T)
    local visited = newGrid(width, height, false)
    local blobs = {}
    
    local dirs = {{1,0},{-1,0},{0,1},{0,-1}}
    
    for ty=1,height do
        for tx=1,width do
            if tiles[ty][tx] and not visited[ty][tx] then
                local queue = {{tx,ty}}
                visited[ty][tx] = true
                local qi = 1
                
                local cells = {}
                local minX,maxX = tx,tx
                local minY,maxY = ty,ty
                
                while qi <= #queue do
                    local cx,cy = queue[qi][1], queue[qi][2]
                    qi = qi + 1
                    cells[#cells+1] = {cx,cy}
                    
                    minX = math.min(minX,cx)
                    maxX = math.max(maxX,cx)
                    minY = math.min(minY,cy)
                    maxY = math.max(maxY,cy)
                    
                    for _,d in ipairs(dirs) do
                        local nx,ny = cx+d[1], cy+d[2]
                        if nx>=1 and nx<=width and ny>=1 and ny<=height then
                            if tiles[ny][nx] and not visited[ny][nx] then
                                visited[ny][nx] = true
                                table.insert(queue,{nx,ny})
                            end
                        end
                    end
                end
                
                blobs[#blobs+1] = {
                    x = (minX-1)*T,
                    y = (minY-1)*T,
                    w = (maxX-minX+1)*T,
                    h = (maxY-minY+1)*T
                }
            end
        end
    end
    
    return blobs
end


--------------------------------------------------------------
-- Ripple surface setup
--------------------------------------------------------------

local function initSurface(blob)
    local w = blob.w
    local N = math.floor(w / 8 + 0.5)
    N = math.max(32, math.min(256, N))

    local surf = {
        N = N,
        y = {},
        v = {},
        tension = 0.025,
        damping = 0.020,
        spread  = 0.22,
        maxAmp  = 12
    }

    for i=1,N do
        surf.y[i] = 0
        surf.v[i] = 0
    end

    blob.surface = surf
end

local function updateSurface(s, dt)
    local N = s.N
    local y = s.y
    local v = s.v
    local t = s.tension
    local d = s.damping
    local sp= s.spread
    local m = s.maxAmp

    for i=1,N do
        local yi,vi = y[i],v[i]
        vi = vi - yi*t
        yi = yi + vi*dt
        vi = vi * (1 - d * dt * 60)
        y[i] = math.max(-m, math.min(m, yi))
        v[i] = vi
    end

    local L,R = {},{}
    for i=1,N do L[i]=0; R[i]=0 end

    for i=1,N do
        if i>1 then
            local dd = sp*(y[i] - y[i-1])
            L[i-1] = L[i-1] + dd
        end
        if i<N then
            local dd = sp*(y[i] - y[i+1])
            R[i+1] = R[i+1] + dd
        end
    end

    for i=1,N do
        local dd = L[i] + R[i]
        y[i] = y[i] + dd
        v[i] = v[i] + dd
    end
end


--------------------------------------------------------------
-- Public API
--------------------------------------------------------------

function Liquids.load(layer, width, height, T)
    Liquids.tileSize = T or 48
    Liquids.blobs = {}

    if not layer then return end

    local tiles = buildTilesFromRects(layer, width, height)
    local blobs = buildBlobsFromTiles(tiles, width, height, Liquids.tileSize)

    for _,b in ipairs(blobs) do
        initSurface(b)
    end

    Liquids.blobs = blobs
end

function Liquids.update(dt)
    for _,b in ipairs(Liquids.blobs) do
        updateSurface(b.surface, dt)
    end
end

function Liquids.ripple(px, py, strength)
    for _, b in ipairs(Liquids.blobs) do
        if px>=b.x and px<=b.x+b.w and py>=b.y and py<=b.y+b.h then
            local s=b.surface
            local idx=math.floor(((px-b.x)/b.w)*(s.N-1)+1.5)
            idx=math.max(1,math.min(s.N,idx))
            s.v[idx]=(s.v[idx] or 0)+(strength or 40)
            return
        end
    end
end


--------------------------------------------------------------
-- FINAL: Draw (fill polygon + real top outline)
--------------------------------------------------------------

function Liquids.draw()
    for _,blob in ipairs(Liquids.blobs) do
        local x,y,w,h = blob.x,blob.y,blob.w,blob.h
        local s=blob.surface
        local N=s.N
        local step=w/(N-1)

        ------------------------------------------------------
        -- Build full polygon
        ------------------------------------------------------
        local poly={}

        -- Top edge (wave shape)
        for i=1,N do
            local px = x + (i-1)*step
            local py = y + s.y[i]
            poly[#poly+1]=px
            poly[#poly+1]=py
        end

        -- Bottom edge (flat)
        poly[#poly+1]=x+w
        poly[#poly+1]=y+h
        poly[#poly+1]=x
        poly[#poly+1]=y+h

        ------------------------------------------------------
        -- Draw fill
        ------------------------------------------------------
        love.graphics.setColor(Liquids.fillColor)
        love.graphics.polygon("fill", poly)

        ------------------------------------------------------
        -- Draw top outline (exact same vertices)
        ------------------------------------------------------
        love.graphics.setColor(Liquids.outlineColor)
        love.graphics.setLineWidth(Liquids.outlineWidth)

        local px = x
        local py = y + s.y[1]

        for i=2,N do
            local nx = x + (i-1)*step
            local ny = y + s.y[i]
            love.graphics.line(px,py,nx,ny)
            px,py = nx,ny
        end
    end
end


return Liquids