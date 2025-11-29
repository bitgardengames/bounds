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
    -- SAW HAZARDS — sample spawns
    ----------------------------------------------------------
	--Saw.spawn(500, 260, { dir = "horizontal", length = 160, speed = 0.7 })
	--Saw.spawn(360, 300, { dir = "vertical", length = 140, speed = 0.6 })
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