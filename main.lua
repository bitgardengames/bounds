--------------------------------------------------------------
-- MAIN GAME MANAGER
--------------------------------------------------------------

local Level       = require("level")
local LevelData = require("leveldata")
local Player      = require("player")
local Particles   = require("particles")
local Collectible = require("collectible")
local Blink       = require("blink")
local Idle        = require("idle")
local Camera      = require("camera")
local Input       = require("input")
local Saw         = require("saws")

local TILE_SIZE = 32

--------------------------------------------------------------
-- LOVE CALLBACKS
--------------------------------------------------------------

function love.load()
    Blink.init()

    -- initialize player at top-left region of level
	Level.load(LevelData)
    Player.init()

    -- Example collectibles
    Collectible.spawn(TILE_SIZE * 10 + 16, TILE_SIZE * 8 + 16)
    Collectible.spawn(TILE_SIZE * 25 + 16, TILE_SIZE * 5 + 16)
    Collectible.spawn(TILE_SIZE * 5  + 16, TILE_SIZE *15 + 16)

	----------------------------------------------------------
	-- SAW HAZARDS — test layout
	----------------------------------------------------------
	--[[Saw.spawn(32*15, 30*32, { dir = "horizontal", mount = "bottom" })
	Saw.spawn(32*51, 24*32, { dir = "horizontal", mount = "top" })
	Saw.spawn(93*32, 25*32, { dir = "vertical", mount = "left" })
	Saw.spawn(89*32, 25*32, { dir = "vertical", mount = "right" })]]

	local TILE = 32

	-- left wall saw (blade sticks right)
	Saw.spawn(106*TILE, 30*TILE, { dir="horizontal", mount="bottom" })

	-- left wall saw (blade sticks right)
	Saw.spawn(112*TILE, 26*TILE, { dir="horizontal", mount="top" })

	-- left wall saw (blade sticks right)
	Saw.spawn(92*TILE, 25*TILE, { dir="vertical", mount="left" })

	-- right wall saw (blade sticks left)
	Saw.spawn(89*TILE, 25*TILE, { dir="vertical", mount="right" })
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

    ----------------------------------------------------------
    -- Saw hazards update
    ----------------------------------------------------------
    Saw.update(dt, pl, Level)

    local isIdle = pl.onGround and math.abs(pl.vx) < 5 and math.abs(pl.vy) < 5
    Idle.update(dt, isIdle)

    ----------------------------------------------------------
    -- Camera
    ----------------------------------------------------------
    Camera.update(pl)

    ----------------------------------------------------------
    -- Late input cleanup
    ----------------------------------------------------------
    Input.postUpdate()
end

function love.keypressed(key)
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
    Particles.draw()
    Collectible.draw()

    Camera.clear()
end