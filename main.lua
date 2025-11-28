--------------------------------------------------------------------
-- CONSTANTS
--------------------------------------------------------------------

local TILE_SIZE     = 32
local LEVEL_WIDTH   = 40
local LEVEL_HEIGHT  = 22
local GRAVITY       = 1350
local MAX_FALL_SPEED = 950
local CORNER_RADIUS = 8

local WALL_SLIDE_FACTOR = 0.45
local WALL_JUMP_PUSH    = 260
local WALL_JUMP_UP      = -480

--------------------------------------------------------------------
-- MODULES
--------------------------------------------------------------------

local Particles = require("particles")
local Collectible = require("collectible")
local Blink = require("blink")
local Idle = require("idle")

--------------------------------------------------------------------
-- LEVEL LAYOUT (40 x 22)
--------------------------------------------------------------------

local levelLayout = {
    "........................................",
    "........................................",
    "....................###.................",
    "........................................",
    "..........#####.........................",
    "........................................",
    "........................................",
    "......####.........................####..",
    "........................................",
    "...................###..................",
    "........................................",
    "........................................",
    "..###.................#####.............",
    "........................................",
    ".................................#...#..",
    "..................####...........#...#..",
    ".................................#...#..",
    ".................................#...#..",
    "####.............####................#..",
    "........................................",
    "........................................",
    "########################################"
}

--------------------------------------------------------------------
-- PLAYER
--------------------------------------------------------------------

local player = {
    x = TILE_SIZE * 2,
    y = TILE_SIZE * 4,

    w = 24,
    h = 24,

    radius = 12,
    outline = 3,

    eyeDirX = 0,
    eyeDirY = 0,

    -- deformation
    contactBottom = 0,
    contactTop    = 0,
    contactLeft   = 0,
    contactRight  = 0,

    springVert    = 0,
    springVertVel = 0,

    springHorz    = 0,
    springHorzVel = 0,

    vertK = 185,
    vertD = 22,

    horzK = 150,
    horzD = 20,

    -- movement
    vx = 0,
    vy = 0,

    maxSpeed        = 320,
    acceleration    = 2200,
    deceleration    = 2900,
    airAcceleration = 1750,
    airDeceleration = 1500,
	preJumpSquish = 0,
    jumpStrength = -520,

    onGround = false,

    coyoteTime     = 0.12,
    coyoteTimer    = 0,
    jumpBufferTime = 0.12,
    jumpBufferTimer = 0,

    wallCoyoteTime = 0.15,
    wallCoyoteTimerLeft  = 0,
    wallCoyoteTimerRight = 0,

    lastDir = 0, -- for turn puff fix
}

--------------------------------------------------------------------
-- COLORS, CAMERA, INPUT
--------------------------------------------------------------------

local colors = {
    --background    = {22/255, 24/255, 33/255},
    background    = {146/255, 182/255, 240/255},
    solid         = {84/255, 84/255, 93/255},
    playerFill    = {236/255, 247/255, 255/255},
    playerOutline = {0,0,0},
}

local camera = {x = 0, y = 0}
local input = { jumpQueued = false }

--------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------

local function clamp(v, mn, mx)
    return (v<mn and mn) or (v>mx and mx) or v
end

local function approach(a, b, dt, speed)
    if a < b then return math.min(a + speed*dt, b)
    else          return math.max(a - speed*dt, b)
    end
end

local function tileAt(tx, ty)
    if tx < 0 or ty < 0 or tx >= LEVEL_WIDTH or ty >= LEVEL_HEIGHT then
        return "#"
    end
    return levelLayout[ty+1]:sub(tx+1, tx+1)
end

--------------------------------------------------------------------
-- COLLISION
--------------------------------------------------------------------

local function tryGroundSnap()
    if player.vy < 0 or player.onGround then return end

    local epsilon = 2
    local footY   = player.y + player.h
    local below   = math.floor(footY / TILE_SIZE)

    local lx = math.floor((player.x+1)/TILE_SIZE)
    local rx = math.floor((player.x+player.w-2)/TILE_SIZE)

    for tx = lx, rx do
        if tileAt(tx, below) == "#" then
            local snapY = below*TILE_SIZE - player.h
            if footY - snapY <= epsilon then
                player.y = snapY
                player.vy = 0
                player.onGround = true
                player.contactBottom = math.max(player.contactBottom, 0.5)
                return
            end
        end
    end
end

local function moveHorizontal(amount)
    if amount == 0 then return false end

    local collided = false

    local topTile    = math.floor(player.y / TILE_SIZE)
    local bottomTile = math.floor((player.y + player.h - 1) / TILE_SIZE)

    if amount > 0 then
        local rightEdge = player.x + player.w
        local startTile = math.floor((rightEdge - 1)/TILE_SIZE)
        local endTile   = math.floor((rightEdge + amount - 1)/TILE_SIZE)
        local targetX   = player.x + amount

        for tx = startTile+1, endTile do
            for ty = topTile, bottomTile do
                if tileAt(tx,ty) == "#" then
                    collided = true
                    targetX = tx*TILE_SIZE - player.w
                    break
                end
            end
        end

        player.x = targetX
    else
        local leftEdge = player.x
        local startTile = math.floor(leftEdge/TILE_SIZE)
        local endTile   = math.floor((leftEdge + amount)/TILE_SIZE)
        local targetX   = player.x + amount

        for tx = startTile-1, endTile, -1 do
            for ty = topTile, bottomTile do
                if tileAt(tx,ty) == "#" then
                    collided = true
                    targetX = (tx+1)*TILE_SIZE
                    break
                end
            end
        end

        player.x = targetX
    end

    if collided then
        player.vx = 0

        if amount > 0 then
            player.contactRight = math.max(player.contactRight, 0.6)
            player.springHorzVel = player.springHorzVel - 60
            player.wallCoyoteTimerRight = player.wallCoyoteTime
        else
            player.contactLeft = math.max(player.contactLeft, 0.6)
            player.springHorzVel = player.springHorzVel + 60
            player.wallCoyoteTimerLeft = player.wallCoyoteTime
        end
    end

    return collided
end

local function moveVertical(amount)
    if amount == 0 then return false end
    local collided = false

    local lx = math.floor(player.x / TILE_SIZE)
    local rx = math.floor((player.x+player.w-1)/TILE_SIZE)

    if amount > 0 then
        local bottomEdge = player.y + player.h
        local startTile  = math.floor(bottomEdge/TILE_SIZE)
        local endTile    = math.floor((bottomEdge+amount)/TILE_SIZE)
        local targetY    = player.y + amount

        for ty = startTile, endTile do
            for tx = lx, rx do
                if tileAt(tx,ty) == "#" then
                    collided = true
                    targetY = ty*TILE_SIZE - player.h
                    break
                end
            end
        end

        player.y = targetY

        if collided then
            player.vy = 0
            player.onGround = true

            player.contactBottom = math.max(player.contactBottom, 0.7)
            player.springVertVel = player.springVertVel - 160
        end
    else
        local topEdge = player.y
        local startTile = math.floor(topEdge/TILE_SIZE)
        local endTile   = math.floor((topEdge+amount)/TILE_SIZE)
        local targetY   = player.y + amount

        for ty = startTile, endTile, -1 do
            for tx = lx, rx do
                if tileAt(tx,ty) == "#" then
                    collided = true
                    targetY = (ty+1)*TILE_SIZE
                    break
                end
            end
        end

        player.y = targetY

        if collided then
            player.vy = 0
            player.contactTop = math.max(player.contactTop, 0.6)
            player.springVertVel = player.springVertVel + 80

			-- Ceiling bonk puff (cute upward poof)
			Particles.puff(
				player.x + player.w/2 + (math.random()-0.5)*4,
				player.y - 2,                             -- impact point at top of blob
				(math.random() * 32 - 16) * 1.4,          -- strong outward cone (left/right)
				35 + math.random()*25,                    -- strong downward velocity
				4, 0.28,
				{1,1,1,0.9}
			)
        end
    end

    return collided
end

--------------------------------------------------------------------
-- LEVEL RENDERING
--------------------------------------------------------------------

local function isSolid(c, r)
    if r < 1 or r > LEVEL_HEIGHT then return false end
    if c < 1 or c > LEVEL_WIDTH then return false end
    return levelLayout[r]:sub(c,c) == "#"
end

local function drawLevel()
    local T = TILE_SIZE
    local r = CORNER_RADIUS
    local shadowOffset = 3

    -- fill + shadow
    for row = 1, LEVEL_HEIGHT do
        local line = levelLayout[row]
        local runStart = nil

        for col = 1, LEVEL_WIDTH+1 do
            local solid = (col <= LEVEL_WIDTH) and (line:sub(col,col) == "#")

            if solid and not runStart then
                runStart = col
            elseif runStart and (not solid) then
                local runEnd = col - 1
                local x = (runStart-1)*T
                local y = (row-1)*T
                local w = (runEnd-runStart+1)*T
                local h = T

                local ix, iy = x+1, y+1
                local iw, ih = w-2, h-2

                love.graphics.setColor(0,0,0,0.35)
                love.graphics.rectangle("fill",
                    ix+shadowOffset, iy+shadowOffset,
                    iw, ih, r,r)

                love.graphics.setColor(colors.solid)
                love.graphics.rectangle("fill", ix, iy, iw, ih, r,r)

                runStart = nil
            end
        end
    end

    -- outlines
    love.graphics.setColor(0,0,0)
    love.graphics.setLineWidth(3)

    for row = 1, LEVEL_HEIGHT do
        for col = 1, LEVEL_WIDTH do
            if isSolid(col,row) then
                local x = (col-1)*T
                local y = (row-1)*T

                if not isSolid(col,row-1) then
                    love.graphics.line(x,y, x+T,y)
                end
                if not isSolid(col,row+1) then
                    love.graphics.line(x+T,y+T, x,y+T)
                end
                if not isSolid(col-1,row) then
                    love.graphics.line(x,y+T, x,y)
                end
                if not isSolid(col+1,row) then
                    love.graphics.line(x+T,y, x+T,y+T)
                end
            end
        end
    end
end

--------------------------------------------------------------------
-- BLOB RENDERER (unchanged, squish-aware)
--------------------------------------------------------------------

local function drawPlayer()
	local breathe = Idle.getScale()
	local r = player.radius * breathe

    local cx = player.x + player.w/2
    local cy = player.y + player.h - r

    -- lean
    local vxNorm = clamp(player.vx / player.maxSpeed, -1, 1)
    local lean = vxNorm * 0.10

    local cb = player.contactBottom
    local ct = player.contactTop
    local cl = player.contactLeft
    local cr = player.contactRight

    local sv = player.springVert
    local sh = player.springHorz

    cb = cb + clamp(-sv,0,0.60) + player.preJumpSquish * 0.70
	ct = ct + (breathe - 1) * 1.2 -- Increase top deformation slightly more than bottom
    ct = ct + clamp( sv,0,0.45)
    cl = cl + clamp( sh,0,0.50)
    cr = cr + clamp(-sh,0,0.50)

    local baseEyeOffsetX = r*0.45
    local baseEyeOffsetY = -r*0.25
    local eyeRadius = r*0.28 * Blink.getEyeScale()

    local lx = player.eyeDirX * (r*0.22)
    local ly = player.eyeDirY * (r*0.22)

    local segments = 48
    local poly = {}

    love.graphics.push()
    love.graphics.translate(cx, cy)
    love.graphics.rotate(lean)

    for i=0,segments do
        local angle = (i/segments)*math.pi*2
        local dx = math.cos(angle)
        local dy = math.sin(angle)
        local dist = r

        if dy > 0 then dist = dist - cb*r*0.34*(dy*dy)
        else           dist = dist + cb*r*0.10*(dy*dy) end

        if dy < 0 then dist = dist - ct*r*0.32*(dy*dy)
        else           dist = dist + ct*r*0.10*(dy*dy) end

        if dx < 0 then dist = dist - cl*r*0.36*(dx*dx)
        else           dist = dist + cl*r*0.10*(dx*dx) end

        if dx > 0 then dist = dist - cr*r*0.36*(dx*dx)
        else           dist = dist + cr*r*0.10*(dx*dx) end

        poly[#poly+1] = dx*dist
        poly[#poly+1] = dy*dist
    end

    -- anchor
    local bottom = -1e9
    for i=2,#poly,2 do bottom = math.max(bottom, poly[i]) end
    local shift = r - bottom
    for i=2,#poly,2 do poly[i] = poly[i] + shift end

    -- outline
    local outlinePoly = {}
    local thick = player.outline

    for i=1,#poly,2 do
        local x=poly[i]
        local y=poly[i+1]
        local len = math.sqrt(x*x+y*y)
        if len < .0001 then len = .0001 end
        local nx = x/len
        local ny = y/len
        outlinePoly[#outlinePoly+1] = x + nx*thick
        outlinePoly[#outlinePoly+1] = y + ny*thick
    end

    love.graphics.setColor(colors.playerOutline)
    love.graphics.polygon("fill", outlinePoly)

    love.graphics.setColor(colors.playerFill)
    love.graphics.polygon("fill", poly)

    love.graphics.setColor(0,0,0)
    local eyeOffsetX = baseEyeOffsetX
    local eyeOffsetY = baseEyeOffsetY + cb*r*0.10
    love.graphics.circle("fill", -eyeOffsetX+lx, eyeOffsetY+ly, eyeRadius)
    love.graphics.circle("fill",  eyeOffsetX+lx, eyeOffsetY+ly, eyeRadius)

	if eyeRadius < 0.5 then
		love.graphics.setLineWidth(2)
		love.graphics.line(-eyeOffsetX+lx - r*0.20, eyeOffsetY+ly, -eyeOffsetX+lx + r*0.20, eyeOffsetY+ly)
		love.graphics.line( eyeOffsetX+lx - r*0.20, eyeOffsetY+ly, eyeOffsetX+lx + r*0.20, eyeOffsetY+ly)
	end

    love.graphics.pop()
end

--------------------------------------------------------------------
-- CAMERA
--------------------------------------------------------------------

local function updateCamera()
    camera.x = player.x - love.graphics.getWidth()/2 + player.w/2
    camera.y = player.y - love.graphics.getHeight()/2 + player.h/2
end

--------------------------------------------------------------------
-- UPDATE LOOP (wall jumps + particles + rigidity fixes)
--------------------------------------------------------------------

function love.update(dt)
	local wasOnGround = player.onGround

    --------------------------------------------------------
    -- contact smoothing
    --------------------------------------------------------
    player.contactBottom = approach(player.contactBottom, player.onGround and 0.35 or 0, dt, 10)
    player.contactTop    = approach(player.contactTop, 0, dt, 14)
    player.contactLeft   = approach(player.contactLeft, 0, dt, 14)
    player.contactRight  = approach(player.contactRight, 0, dt, 14)

    --------------------------------------------------------
    -- movement input
    --------------------------------------------------------
    local move = 0
    if love.keyboard.isDown("a","left")  then move = move - 1 end
    if love.keyboard.isDown("d","right") then move = move + 1 end

    --------------------------------------------------------
    -- jump buffer + coyote timers
    --------------------------------------------------------
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

    player.wallCoyoteTimerLeft  = math.max(player.wallCoyoteTimerLeft  - dt, 0)
    player.wallCoyoteTimerRight = math.max(player.wallCoyoteTimerRight - dt, 0)

    --------------------------------------------------------
    -- horizontal control
    --------------------------------------------------------
    local targetSpeed = move * player.maxSpeed
    local accelerating = math.abs(targetSpeed) > 0

    local accel = accelerating and (player.onGround and player.acceleration or player.airAcceleration) or (player.onGround and player.deceleration or player.airDeceleration)

    if accelerating then
        local dir = (targetSpeed > player.vx) and 1 or -1
        player.vx = player.vx + dir*accel*dt

        if (dir==1 and player.vx>targetSpeed) or (dir==-1 and player.vx<targetSpeed) then
            player.vx = targetSpeed
        end

        --------------------------------------------------------
        -- SHARP TURN / BURST START PUFF (FIXED: one-shot)
        --------------------------------------------------------
		local reversing = math.abs(player.vx) > 40 and ((dir == 1 and player.lastDir == -1) or (dir == -1 and player.lastDir == 1))
        local burstStart = (math.abs(player.vx) < 5 and math.abs(targetSpeed) > 200)

        if (reversing or burstStart) and player.onGround then
            Particles.puff(
                player.x + player.w/2,
                player.y + player.h,
                (math.random()-0.5)*30,
                5,
                4, 0.25,
                {1,1,1,0.9}
            )
        end

        player.lastDir = dir

		--------------------------------------------------------
		-- RUNNING DUST (while sprinting)
		--------------------------------------------------------
		if player.onGround then
			local speed = math.abs(player.vx)

			-- Threshold for sprinting dust
			if speed > player.maxSpeed * 0.55 then
				-- Spawn every ~0.05–0.09 seconds depending on speed
				player.runDustTimer = (player.runDustTimer or 0) - dt

				local interval = 0.12 - (speed / player.maxSpeed) * 0.04
				if player.runDustTimer <= 0 then
					player.runDustTimer = interval

					Particles.puff(
						player.x + player.w/2 + (math.random() - 0.5) * 8,
						player.y + player.h + 2,
						(math.random()*22 - 11),       -- sideways
						-(10 + math.random()*18),      -- upward
						3.5, 0.28,
						{1,1,1,0.85}
					)
				end
			else
				-- Reset timer if not sprinting
				player.runDustTimer = 0
			end
		end
    else
        if player.vx > 0 then
			player.vx = math.max(player.vx - accel*dt, 0)
        elseif player.vx < 0 then
			player.vx = math.min(player.vx + accel*dt, 0)
		end
    end

    --------------------------------------------------------
    -- wall slide friction
    --------------------------------------------------------
    local touchingLeft  = player.wallCoyoteTimerLeft  > 0
    local touchingRight = player.wallCoyoteTimerRight > 0
    local touchingWall  = touchingLeft or touchingRight

    if touchingWall and not player.onGround and player.vy > 0 then
        player.vy = player.vy * WALL_SLIDE_FACTOR

        if math.random() < 0.12 then
            local dir = touchingLeft and -1 or 1
			Particles.wallDust(
				player.x + player.w/2 + dir*12,
				player.y + player.h/2 + math.random()*10,
				dir * -22,                   -- wider outward burst
				4 + math.random()*12,        -- soft downward puff
				3.5, 0.32,
				{1,1,1,0.9}
			)
        end
    end

    --------------------------------------------------------
    -- jump logic (ground + coyote + wall jump)
    --------------------------------------------------------
    local doWallJump  = false
    local wallJumpDir = 0

    if player.jumpBufferTimer > 0 then
        if not player.onGround then
            if player.wallCoyoteTimerLeft > 0 then
                doWallJump = true
                wallJumpDir = 1
            elseif player.wallCoyoteTimerRight > 0 then
                doWallJump = true
                wallJumpDir = -1
            end
        end
    end

    if doWallJump then
        player.vx = WALL_JUMP_PUSH * wallJumpDir
        player.vy = WALL_JUMP_UP

        player.jumpBufferTimer = 0

        player.springVertVel = player.springVertVel + 110
        player.springHorzVel = player.springHorzVel + (-wallJumpDir * 120)

        Particles.puff(
            player.x + player.w/2 + (-wallJumpDir)*10,
            player.y + player.h/2,
            -wallJumpDir * 50,
            -40 + math.random()*60,
            5, 0.25,
            {1,1,1,1}
        )

	else
		local canJump = player.jumpBufferTimer > 0 and (player.onGround or player.coyoteTimer > 0)

		if canJump then
			-- Instant jump, no input lag
			player.vy = player.jumpStrength
			player.onGround = false
			player.jumpBufferTimer = 0

			-- Anticipation-style squash impulse (decays over a few frames)
			player.preJumpSquish = 1.0  -- how strong the “collect” pose is

			-- Existing spring kick
			player.springVertVel = player.springVertVel + 110

			-- Existing jump puff
			Particles.puff(
				player.x + player.w/2,
				player.y + player.h,
				(math.random()-0.5)*60,
				20 + math.random()*20,
				6, 0.35,
				{1,1,1,1}
			)
		end
    end

	--------------------------------------------------------
	-- anticipation squish decay
	--------------------------------------------------------
	if player.preJumpSquish > 0 then
		-- Fast decay so it only lasts a handful of frames
		player.preJumpSquish = math.max(player.preJumpSquish - dt * 9.0, 0)
	end

    --------------------------------------------------------
    -- gravity
    --------------------------------------------------------
    player.vy = player.vy + GRAVITY * dt
    player.vy = clamp(player.vy, -math.huge, MAX_FALL_SPEED)

    --------------------------------------------------------
    -- movement + collision
    --------------------------------------------------------
    player.onGround = false
    moveHorizontal(player.vx * dt)
    moveVertical(player.vy * dt)
    tryGroundSnap()

	local justLanded = (not wasOnGround) and player.onGround

	if justLanded then
		for i=1,3 do
			Particles.puff(
				player.x + player.w/2 + (math.random()-0.5)*12,
				player.y + player.h + 2,
				(math.random()-0.5)*40,
				math.random()*20,
				4, 0.30,
				{1,1,1,1}
			)
		end
	end

    --------------------------------------------------------
    -- springs
    --------------------------------------------------------
    do
        local s = player.springVert
        local v = player.springVertVel
        local f = -player.vertK*s - player.vertD*v
        v = v + f*dt
        s = s + v*dt
        player.springVert = clamp(s, -0.40, 0.40)
        player.springVertVel = v
    end

    do
        local s = player.springHorz
        local v = player.springHorzVel
        local f = -player.horzK*s - player.horzD*v
        v = v + f*dt
        s = s + v*dt
        player.springHorz = clamp(s, -0.40, 0.40)
        player.springHorzVel = v
    end

    --------------------------------------------------------
    -- eyes
    --------------------------------------------------------
    local dx,dy = 0,0
    if math.abs(player.vx) > 20 then dx = (player.vx>0)and 1 or -1 end
    if math.abs(player.vy) > 50 then dy = (player.vy>0)and 0.5 or -0.3 end

    player.eyeDirX = approach(player.eyeDirX, dx, dt, 6)
    player.eyeDirY = approach(player.eyeDirY, dy, dt, 6)

    --------------------------------------------------------
    -- PARTICLES
    --------------------------------------------------------
    Particles.update(dt)
	Collectible.update(dt, player)
	Blink.update(dt)
	local isIdle = player.onGround and math.abs(player.vx) < 5 and math.abs(player.vy) < 5
	Idle.update(dt, isIdle)

    updateCamera()
end

--------------------------------------------------------------------
-- INPUT
--------------------------------------------------------------------

function love.keypressed(key)
    if key=="space" or key=="w" or key=="up" then
        input.jumpQueued = true
    end
end

function love.keyreleased(key)
    if (key=="space" or key=="w" or key=="up") and player.vy < -120 then
        player.vy = -120
    end
end

--------------------------------------------------------------------
-- DRAW
--------------------------------------------------------------------

function love.draw()
    -- draw background fill
    love.graphics.setColor(colors.background)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    love.graphics.push()
    love.graphics.translate(-camera.x, -camera.y)

    drawLevel()
    drawPlayer()
    Particles.draw()
	Collectible.draw()

    love.graphics.pop()
end

function love.load()
    Blink.init()

	Collectible.spawn(TILE_SIZE * 10 + 16, TILE_SIZE * 8 + 16)
	Collectible.spawn(TILE_SIZE * 25 + 16, TILE_SIZE * 5 + 16)
	Collectible.spawn(TILE_SIZE * 5  + 16, TILE_SIZE *15 + 16)
end