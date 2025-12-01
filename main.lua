--------------------------------------------------------------
-- MAIN GAME MANAGER
--------------------------------------------------------------

local Level = require("level")
local LevelData = require("leveldata")
local Player = require("player")
local Particles = require("particles")
local Collectible = require("collectible")
local Blink = require("blink")
local Idle = require("idle")
local Camera = require("camera")
local Input = require("input")
local Saw = require("saws")
local Door = require("door")
local Exit = require("exit")
local Chamber = require("chamber")
local Plate = require("pressureplate")

local TILE_SIZE = LevelData.tileSize or 48

--------------------------------------------------------------
-- LOVE CALLBACKS
--------------------------------------------------------------

function love.load()
    Blink.init()

    -- initialize player at top-left region of level
	Level.load(LevelData)
    TILE_SIZE = Level.tileSize or TILE_SIZE
    Player.init(Level)

    -- Example collectibles
    Collectible.spawn(TILE_SIZE * 10 + TILE_SIZE/3, TILE_SIZE * 8 + TILE_SIZE/3)
    Collectible.spawn(TILE_SIZE * 25 + TILE_SIZE/3, TILE_SIZE * 5 + TILE_SIZE/3)
    Collectible.spawn(TILE_SIZE * 5  + TILE_SIZE/3, TILE_SIZE *15 + TILE_SIZE/3)

	----------------------------------------------------------
	-- SAW HAZARDS — test layout
	----------------------------------------------------------
	local TILE = TILE_SIZE

	-- Center ceiling-mounted horizontal saw
	Saw.spawn(TILE * 20, TILE * 1, {dir="horizontal", mount="top", speed=1})

	-- Vertical saw in the wall-kick shaft (left-mounted)
	Saw.spawn(TILE * 31,TILE * 13, {dir="vertical", mount="left", speed=1})

	-- Pressure plate
	Plate.spawn(TILE_SIZE * 12, TILE_SIZE * 21)

	-- Exit door
	Door.spawn(TILE * 18, TILE * 13, TILE * 4, TILE * 3)
	Exit.spawn(TILE * 17, TILE * 13)   -- 1 tile in front of door
end

function love.update(dt)
    ----------------------------------------------------------
    -- Input system
    ----------------------------------------------------------
    Input.update()

    ----------------------------------------------------------
    -- Player update with Level collision queries
    ----------------------------------------------------------
    local pl = Player.update(dt, Level)

    Collectible.update(dt, pl)
    Particles.update(dt)
    Blink.update(dt)
	Door.update(dt)
	Plate.update(dt, pl)

    ----------------------------------------------------------
    -- Saw hazards update
    ----------------------------------------------------------
    Saw.update(dt, pl, Level)

    local isIdle = pl.onGround and math.abs(pl.vx) < 5 and math.abs(pl.vy) < 5
    Idle.update(dt, isIdle)

    ----------------------------------------------------------
    -- Camera
    ----------------------------------------------------------
    --Camera.update(pl)

    ----------------------------------------------------------
	-- Completion
	----------------------------------------------------------
	Chamber.update(dt, pl, Door, Exit)
	if Chamber.isComplete then
		print("LEVEL COMPLETE!")
		-- next level, fade out, etc.
	end

    ----------------------------------------------------------
    -- Late input cleanup
    ----------------------------------------------------------
    Input.postUpdate()
end

function love.keypressed(key)
	if key == "printscreen" then
		local time = os.date("%Y-%m-%d_%H-%M-%S")
		love.graphics.captureScreenshot("screenshot_" .. time .. ".png")
	end

    Input.keypressed(key)
end

function love.keyreleased(key)
    Input.keyreleased(key)
end

function love.gamepadpressed(joystick, button)
    Input.gamepadpressed(joystick, button)
end

function love.gamepadreleased(joystick, button)
    Input.gamepadreleased(joystick, button)
end

function love.draw()
    -- background fill from Level.colors
    love.graphics.setColor(Level.colors.background)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    Camera.apply()

    ----------------------------------------------------------
    -- DRAW ORDER
    ----------------------------------------------------------
	local camX, camY = 0, 0
    Level.draw(camX, camY)
    Saw.draw()
    Player.draw()
	Door.draw()
	Plate.draw()
    Particles.draw()
    Collectible.draw()

    Camera.clear()
end