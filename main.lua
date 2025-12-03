--------------------------------------------------------------
-- MAIN GAME MANAGER
--------------------------------------------------------------

local Level = require("level")
local LevelData = require("leveldata")
local Player = require("player")
local Particles = require("particles")
local Blink = require("blink")
local Idle = require("idle")
local Camera = require("camera")
local Input = require("input")
local Saw = require("saws")
local Door = require("door")
local Exit = require("exit")
local Chamber = require("chamber")
local Plate = require("pressureplate")
local Cube = require("cube")
local Decorations = require("decorations")
local SecurityCamera = require("securitycamera")

local TILE_SIZE = LevelData.tileSize or 48

--------------------------------------------------------------
-- LOVE CALLBACKS
--------------------------------------------------------------

function love.load()
    Blink.init()

    -- initialize player at top-left region of level
    Level.load(LevelData)
    TILE_SIZE = Level.tileSize or TILE_SIZE

    -- Spawn decorations
    for _, layer in ipairs(LevelData.layers) do
        if layer.kind == "decor" then
            Decorations.spawnLayer(layer, TILE_SIZE)
        end
    end

    Player.init(Level)

    ----------------------------------------------------------
    -- SAW HAZARDS — test layout
    ----------------------------------------------------------
    local TILE = TILE_SIZE

    SecurityCamera.spawn(1, 2)

    -- Center ceiling-mounted horizontal saw
    Saw.spawn(TILE * 20, TILE * 1, {dir="horizontal", mount="top", speed=1})

    -- Vertical saw in the wall-kick shaft (left-mounted)
    Saw.spawn(TILE * 31, TILE * 13, {dir="vertical", mount="left", speed=1})

    -- Pressure plate
    Plate.spawn(TILE_SIZE * 12, TILE_SIZE * 21)

    -- Ze Cube
    Cube.spawn(48*10, 48*20)

    -- Exit door
    Door.spawn(16, 20, TILE)
    Exit.spawn(TILE * 5, TILE * 18)
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

	if not pl.sleeping and not pl.sleepingTransition then
		Blink.update(dt)
	end

    Cube.update(dt, pl)
    Plate.update(dt, pl, Cube.list)
    Door.update(dt)
    SecurityCamera.update(dt)
    Particles.update(dt)
    Decorations.update(dt)

    ----------------------------------------------------------
    -- Saw hazards update
    ----------------------------------------------------------
    Saw.update(dt, pl, Level)

    ----------------------------------------------------------
    -- Idle → Sleep integration
    ----------------------------------------------------------
    -- "isIdle" is still needed to drive small idle animations,
    -- but if the player is sleeping, Idle.update must be disabled.
    local isIdle =
        pl.onGround and
        math.abs(pl.vx) < 5 and
        math.abs(pl.vy) < 5

    -- only drive Idle when not sleeping
    Idle.update(dt, isIdle and not pl.sleeping)

    ----------------------------------------------------------
    -- Camera
    ----------------------------------------------------------
    -- Camera.update(pl)   -- camera fixed for now

    ----------------------------------------------------------
    -- Completion / triggers
    ----------------------------------------------------------
    Chamber.update(dt, pl, Door, Exit)
    if Chamber.isComplete then
        print("LEVEL COMPLETE!")
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
    SecurityCamera.draw(Decorations.style)
    Saw.draw()
    Player.draw()
    Door.draw()
    Cube.draw()
    Plate.draw()
    Particles.draw()

    Camera.clear()
end