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
local MovingPlatform = require("movingplatform")
local Decorations = require("decorations")
local Monitor = require("monitor")
local ContextZones = require("contextzones")

local TILE_SIZE = LevelData.tileSize or 48
local currentChamber = 1
local chamberCount = #LevelData.chambers
local gameComplete = false
local isTransitioning = false

local Transition = {
    active = false,
    phase = "idle",
    timer = 0,
    duration = 0.6,
    alpha = 0,
    nextChamber = nil,
}

-- Forward declarations
local loadChamber

local function startTransition(nextChamber)
    Transition.active = true
    Transition.phase = "fadeOut"
    Transition.timer = 0
    Transition.alpha = 0
    Transition.nextChamber = nextChamber
end

local function updateTransition(dt)
    if not Transition.active then return end

    Transition.timer = math.min(Transition.timer + dt, Transition.duration)

    if Transition.phase == "fadeOut" then
        Transition.alpha = Transition.timer / Transition.duration

        if Transition.timer >= Transition.duration then
            if Transition.nextChamber then
                currentChamber = Transition.nextChamber
                loadChamber(currentChamber)
                Transition.phase = "fadeIn"
                Transition.timer = 0
            else
                Transition.active = false
            end
        end
    elseif Transition.phase == "fadeIn" then
        Transition.alpha = 1 - (Transition.timer / Transition.duration)

        if Transition.timer >= Transition.duration then
            Transition.active = false
            Transition.phase = "idle"
            Transition.alpha = 0
            Transition.nextChamber = nil
            isTransitioning = false
        end
    end
end

local function clearActors()
    Decorations.clear()
    Saw.clear()
    Cube.clear()
    Plate.clear()
    Monitor.clear()
    Exit.clear()
	MovingPlatform.clear()
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

    local doorSpawned = false

    if objects.door then
        Door.spawn(objects.door.tx, objects.door.ty, TILE_SIZE)
        doorSpawned = true
    end

    if objects.exit then
        if doorSpawned then
            Exit.spawn(Door.x, Door.y, Door.w, Door.h)
        else
            Exit.spawn(objects.exit.tx * TILE_SIZE, objects.exit.ty * TILE_SIZE)
        end
    elseif doorSpawned then
        Exit.spawn(Door.x, Door.y, Door.w, Door.h)
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

	if objects.movingPlatforms then
		for _, mp in ipairs(objects.movingPlatforms) do
			MovingPlatform.spawn(
				mp.tx * TILE_SIZE,
				mp.ty * TILE_SIZE,
				{
					dir         = mp.dir or "horizontal",
					length      = mp.length or 160,
					speed       = mp.speed or 60,
					active      = mp.active,       -- true OR false
					target      = mp.target,       -- string ID for plates
					phaseOffset = mp.phaseOffset,
				}
			)
		end
	end

	Monitor.clear()
	Monitor.tileSize = TILE_SIZE

	for _, monitor in ipairs(objects.monitors or {}) do
		Monitor.spawn(monitor.tx, monitor.ty, monitor.dir or 1)
	end
end

local function spawnContextZones(chamber)
    ContextZones.clear()
	ContextZones.tileSize = TILE_SIZE
    if chamber.contextZones then
        for _, z in ipairs(chamber.contextZones) do
			ContextZones.add(z.name, z.tx, z.ty, z.w, z.h, z.effects)
        end
    end
end

function loadChamber(index)
    local chamber = LevelData.chambers[index]
    assert(chamber, "No chamber data for index " .. tostring(index))

    chamber.tileSize = LevelData.tileSize

    Level.load(chamber)
    TILE_SIZE = Level.tileSize or TILE_SIZE

    Chamber.reset(index, chamberCount)
    clearActors()
    spawnDecorations(chamber)
    spawnObjects(chamber)
	spawnContextZones(chamber)

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

	ContextZones.update(pl)

	if not pl.sleeping and not pl.sleepingTransition then
		Blink.update(dt)
	end

    Cube.update(dt, pl)
    Plate.update(dt, pl, Cube.list)
    Door.update(dt)
    Monitor.update(dt)
    MovingPlatform.update(dt)
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
        if currentChamber < chamberCount and not isTransitioning then
            isTransitioning = true
            startTransition(currentChamber + 1)
        elseif currentChamber >= chamberCount then
            gameComplete = true
            print("LEVEL COMPLETE!")
        end
    end

    ----------------------------------------------------------
    -- Late input cleanup
    ----------------------------------------------------------
    Input.postUpdate()

    updateTransition(dt)
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
    Monitor.draw()
    Saw.draw()
    Door.draw()
    Plate.draw()
    Cube.draw()
	MovingPlatform.draw()
	ContextZones.draw() -- remove after debugging
	Player.draw()

    Particles.draw()

    Camera.clear()

    if Transition.active and Transition.alpha > 0 then
        love.graphics.setColor(0, 0, 0, Transition.alpha)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    end
end