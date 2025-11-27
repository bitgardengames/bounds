local TILE_SIZE = 32
local LEVEL_WIDTH = 24
local LEVEL_HEIGHT = 12

local levelLayout = {
    "........................",
    "........................",
    "........................",
    "..............##........",
    "........................",
    "...###............###...",
    "........................",
    "..#.....................",
    "..#.......###...........",
    "..#####............###..",
    "........................",
    "########################"
}

local player = {
    x = TILE_SIZE * 2,
    y = TILE_SIZE * 7,
    w = 24,
    h = 24,
    radius = 12,
    outline = 3,
    vx = 0,
    vy = 0,
    speed = 260,
    jumpStrength = -460,
    onGround = false
}

local colors = {
    background = {22 / 255, 24 / 255, 33 / 255},
    solid = {68 / 255, 161 / 255, 202 / 255},
    playerFill = {236 / 255, 247 / 255, 255 / 255},
    playerOutline = {24 / 255, 72 / 255, 130 / 255},
    grid = {1, 1, 1, 0.08}
}

local input = {
    jumpQueued = false
}

local function tileAt(tx, ty)
    if tx < 0 or ty < 0 or tx >= LEVEL_WIDTH or ty >= LEVEL_HEIGHT then
        return '#'
    end
    local row = levelLayout[ty + 1]
    return row:sub(tx + 1, tx + 1)
end

local function rectCollides(x, y, w, h)
    local left = math.floor(x / TILE_SIZE)
    local right = math.floor((x + w - 1) / TILE_SIZE)
    local top = math.floor(y / TILE_SIZE)
    local bottom = math.floor((y + h - 1) / TILE_SIZE)

    for ty = top, bottom do
        for tx = left, right do
            if tileAt(tx, ty) == '#' then
                return true, tx, ty
            end
        end
    end
    return false
end

local function moveAxis(dx, dy)
    local collided = false
    if dx ~= 0 then
        player.x = player.x + dx
        local hit, tx = rectCollides(player.x, player.y, player.w, player.h)
        if hit then
            collided = true
            if dx > 0 then
                player.x = tx * TILE_SIZE - player.w
            else
                player.x = (tx + 1) * TILE_SIZE
            end
            player.vx = 0
        end
    end

    if dy ~= 0 then
        player.y = player.y + dy
        local hit, _, ty = rectCollides(player.x, player.y, player.w, player.h)
        if hit then
            collided = true
            if dy > 0 then
                player.y = ty * TILE_SIZE - player.h
                player.onGround = true
            else
                player.y = (ty + 1) * TILE_SIZE
            end
            player.vy = 0
        end
    end

    return collided
end

local function drawGrid()
    love.graphics.setColor(colors.grid)
    for x = 0, LEVEL_WIDTH * TILE_SIZE, TILE_SIZE do
        love.graphics.line(x, 0, x, LEVEL_HEIGHT * TILE_SIZE)
    end
    for y = 0, LEVEL_HEIGHT * TILE_SIZE, TILE_SIZE do
        love.graphics.line(0, y, LEVEL_WIDTH * TILE_SIZE, y)
    end
end

local function drawLevel()
    love.graphics.setColor(colors.solid)
    for row = 1, LEVEL_HEIGHT do
        for col = 1, LEVEL_WIDTH do
            if levelLayout[row]:sub(col, col) == '#' then
                love.graphics.rectangle(
                    'fill',
                    (col - 1) * TILE_SIZE,
                    (row - 1) * TILE_SIZE,
                    TILE_SIZE,
                    TILE_SIZE
                )
            end
        end
    end
end

function love.load()
    love.graphics.setBackgroundColor(colors.background)
    love.graphics.setLineWidth(player.outline)
end

function love.update(dt)
    local move = 0
    if love.keyboard.isDown('a') or love.keyboard.isDown('left') then
        move = move - 1
    end
    if love.keyboard.isDown('d') or love.keyboard.isDown('right') then
        move = move + 1
    end

    player.vx = move * player.speed
    player.vy = player.vy + 900 * dt

    if input.jumpQueued and player.onGround then
        player.vy = player.jumpStrength
        player.onGround = false
    end
    input.jumpQueued = false

    player.onGround = false

    moveAxis(player.vx * dt, 0)
    moveAxis(0, player.vy * dt)
end

function love.keypressed(key)
    if key == 'space' or key == 'w' or key == 'up' then
        input.jumpQueued = true
    end
end

function love.draw()
    drawGrid()
    drawLevel()

    local cx = player.x + player.w / 2
    local cy = player.y + player.h / 2

    love.graphics.setColor(colors.playerOutline)
    love.graphics.circle('line', cx, cy, player.radius)
    love.graphics.setColor(colors.playerFill)
    love.graphics.circle('fill', cx, cy, player.radius - player.outline / 2)

    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.print("Move: A/D or Arrows", 12, 12)
    love.graphics.print("Jump: Space/W/Up", 12, 30)
end

