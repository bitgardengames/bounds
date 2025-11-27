local TILE_SIZE = 32
local LEVEL_WIDTH = 24
local LEVEL_HEIGHT = 12
local GRAVITY = 900
local MAX_FALL_SPEED = 950

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
    y = TILE_SIZE * 4,
    w = 24,
    h = 24,
    radius = 12,
    outline = 3,
    vx = 0,
    vy = 0,
    maxSpeed = 320,
    acceleration = 2200,
    deceleration = 2600,
    airAcceleration = 1400,
    airDeceleration = 1200,
    jumpStrength = -520,
    onGround = false,
    coyoteTime = 0.12,
    coyoteTimer = 0,
    jumpBufferTime = 0.12,
    jumpBufferTimer = 0
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

local function clamp(value, min, max)
    if value < min then
        return min
    elseif value > max then
        return max
    end
    return value
end

local function tileAt(tx, ty)
    if tx < 0 or ty < 0 or tx >= LEVEL_WIDTH or ty >= LEVEL_HEIGHT then
        return '#'
    end
    local row = levelLayout[ty + 1]
    return row:sub(tx + 1, tx + 1)
end

local function tryGroundSnap()
    if player.vy < 0 or player.onGround then
        return
    end

    local epsilon = 2
    local footY = player.y + player.h
    local belowTile = math.floor(footY / TILE_SIZE)
    local leftTile = math.floor((player.x + 1) / TILE_SIZE)
    local rightTile = math.floor((player.x + player.w - 2) / TILE_SIZE)

    for tx = leftTile, rightTile do
        if tileAt(tx, belowTile) == '#' then
            local snapY = belowTile * TILE_SIZE - player.h
            if footY - snapY <= epsilon then
                player.y = snapY
                player.vy = 0
                player.onGround = true
                return
            end
        end
    end
end

local function moveHorizontal(amount)
    if amount == 0 then
        return false
    end

    local collided = false
    local topTile = math.floor(player.y / TILE_SIZE)
    local bottomTile = math.floor((player.y + player.h - 1) / TILE_SIZE)

    if amount > 0 then
        local rightEdge = player.x + player.w
        local startTile = math.floor((rightEdge - 1) / TILE_SIZE)
        local endTile = math.floor((rightEdge + amount - 1) / TILE_SIZE)
        local targetX = player.x + amount

        for tx = startTile + 1, endTile do
            for ty = topTile, bottomTile do
                if tileAt(tx, ty) == '#' then
                    collided = true
                    local stopX = tx * TILE_SIZE - player.w
                    if stopX < targetX then
                        targetX = stopX
                    end
                    break
                end
            end
        end

        player.x = targetX
    else
        local leftEdge = player.x
        local startTile = math.floor(leftEdge / TILE_SIZE)
        local endTile = math.floor((leftEdge + amount) / TILE_SIZE)
        local targetX = player.x + amount

        for tx = startTile - 1, endTile, -1 do
            for ty = topTile, bottomTile do
                if tileAt(tx, ty) == '#' then
                    collided = true
                    local stopX = (tx + 1) * TILE_SIZE
                    if stopX > targetX then
                        targetX = stopX
                    end
                    break
                end
            end
        end

        player.x = targetX
    end

    if collided then
        player.vx = 0
    end

    return collided
end

local function moveVertical(amount)
    if amount == 0 then
        return false
    end

    local collided = false
    local leftTile = math.floor(player.x / TILE_SIZE)
    local rightTile = math.floor((player.x + player.w - 1) / TILE_SIZE)

    if amount > 0 then
        local bottomEdge = player.y + player.h
        local startTile = math.floor(bottomEdge / TILE_SIZE)
        local endTile = math.floor((bottomEdge + amount) / TILE_SIZE)
        local targetY = player.y + amount

        for ty = startTile, endTile do
            for tx = leftTile, rightTile do
                if tileAt(tx, ty) == '#' then
                    collided = true
                    local stopY = ty * TILE_SIZE - player.h
                    if stopY < targetY then
                        targetY = stopY
                    end
                    break
                end
            end
        end

        player.y = targetY

        if collided then
            player.vy = 0
            player.onGround = true
        end
    else
        local topEdge = player.y
        local startTile = math.floor(topEdge / TILE_SIZE)
        local endTile = math.floor((topEdge + amount) / TILE_SIZE)
        local targetY = player.y + amount

        for ty = startTile, endTile, -1 do
            for tx = leftTile, rightTile do
                if tileAt(tx, ty) == '#' then
                    collided = true
                    local stopY = (ty + 1) * TILE_SIZE
                    if stopY > targetY then
                        targetY = stopY
                    end
                    break
                end
            end
        end

        player.y = targetY

        if collided then
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

    if input.jumpQueued then
        player.jumpBufferTimer = player.jumpBufferTime
        input.jumpQueued = false
    else
        player.jumpBufferTimer = math.max(player.jumpBufferTimer - dt, 0)
    end

    if player.onGround then
        player.coyoteTimer = player.coyoteTime
    else
        player.coyoteTimer = math.max(player.coyoteTimer - dt, 0)
    end

    local targetSpeed = move * player.maxSpeed
    local accelerating = math.abs(targetSpeed) > 0
    local accel = accelerating and (player.onGround and player.acceleration or player.airAcceleration)
        or (player.onGround and player.deceleration or player.airDeceleration)

    if accelerating then
        local direction = targetSpeed > player.vx and 1 or -1
        player.vx = player.vx + direction * accel * dt
        if (direction == 1 and player.vx > targetSpeed) or (direction == -1 and player.vx < targetSpeed) then
            player.vx = targetSpeed
        end
    else
        if player.vx > 0 then
            player.vx = math.max(player.vx - accel * dt, 0)
        elseif player.vx < 0 then
            player.vx = math.min(player.vx + accel * dt, 0)
        end
    end

    local canJump = player.jumpBufferTimer > 0 and (player.onGround or player.coyoteTimer > 0)
    if canJump then
        player.vy = player.jumpStrength
        player.onGround = false
        player.jumpBufferTimer = 0
    end

    player.vy = player.vy + GRAVITY * dt
    player.vy = clamp(player.vy, -math.huge, MAX_FALL_SPEED)

    player.onGround = false

    moveHorizontal(player.vx * dt)
    moveVertical(player.vy * dt)
    tryGroundSnap()
end

function love.keypressed(key)
    if key == 'space' or key == 'w' or key == 'up' then
        input.jumpQueued = true
    end
end

function love.keyreleased(key)
    if (key == 'space' or key == 'w' or key == 'up') and player.vy < -120 then
        player.vy = -120
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
end