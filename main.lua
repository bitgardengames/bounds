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
local currentChamber = 1
local chamberCount = #LevelData.chambers
local gameComplete = false

local function clearActors()
    Decorations.clear()
    Saw.clear()
    Cube.clear()
    Plate.clear()
    SecurityCamera.clear()
    Exit.clear()
end

local function spawnDecorations(chamber)
    Decorations.clear()
    for _, layer in ipairs(chamber.layers or {}) do
        if layer.kind == "decor" then
            Decorations.spawnLayer(layer, TILE_SIZE)
        end
    end
end

local function spawnObjects(chamber)
    local objects = chamber.objects or {}

    if objects.door then
        Door.spawn(objects.door.tx, objects.door.ty, TILE_SIZE)
    end

    if objects.exit then
        Exit.spawn(objects.exit.tx * TILE_SIZE, objects.exit.ty * TILE_SIZE)
    else
        Exit.clear()
    end

    if objects.plates and objects.plates[1] then
        local plate = objects.plates[1]
        Plate.spawn(plate.tx * TILE_SIZE, plate.ty * TILE_SIZE)
    else
        Plate.clear()
    end

    Cube.clear()
    for _, cube in ipairs(objects.cubes or {}) do
        Cube.spawn(cube.tx * TILE_SIZE, cube.ty * TILE_SIZE)
    end

    Saw.clear()
    for _, saw in ipairs(objects.saws or {}) do
        Saw.spawn(saw.tx * TILE_SIZE, saw.ty * TILE_SIZE, {
            dir = saw.dir,
            mount = saw.mount,
            speed = saw.speed,
            length = saw.length,
            sineAmp = saw.sineAmp,
            sineFreq = saw.sineFreq,
        })
    end

    SecurityCamera.clear()
    SecurityCamera.tileSize = TILE_SIZE
    if objects.securityCameras and objects.securityCameras[1] then
        local cam = objects.securityCameras[1]
        SecurityCamera.spawn(cam.tx, cam.ty)
    end
end

local function loadChamber(index)
    local chamber = LevelData.chambers[index]
    assert(chamber, "No chamber data for index " .. tostring(index))

    chamber.tileSize = LevelData.tileSize

    Level.load(chamber)
    TILE_SIZE = Level.tileSize or TILE_SIZE

    Chamber.reset(index, chamberCount)
    clearActors()
    spawnDecorations(chamber)
    spawnObjects(chamber)

    local spawn = (chamber.objects and chamber.objects.playerStart) or { tx = 2, ty = 4 }
    Player.setSpawn(spawn.tx * TILE_SIZE, spawn.ty * TILE_SIZE)
end

--------------------------------------------------------------
-- LOVE CALLBACKS
--------------------------------------------------------------

function love.load()
    Blink.init()

    Player.init(Level)
    loadChamber(currentChamber)
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
    if Chamber.isComplete and not gameComplete then
        if currentChamber < chamberCount then
            currentChamber = currentChamber + 1
            loadChamber(currentChamber)
        else
            gameComplete = true
            print("LEVEL COMPLETE!")
        end
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