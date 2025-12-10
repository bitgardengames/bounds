--------------------------------------------------------------
-- MAIN GAME MANAGER
--------------------------------------------------------------

local Level = require("level.level")
local LevelData = require("level.leveldata")
local Timer = require("systems.timer")
local Particles = require("systems.particles")
local Player = require("player.player")
local Blink = require("player.blink")
local Idle = require("player.idle")
local Camera = require("systems.camera")
local Input = require("systems.input")
local Saw = require("objects.saws")
local Door = require("objects.door")
local Exit = require("systems.exit")
local Chamber = require("level.chamber")
local Plate = require("objects.pressureplate")
local Cube = require("objects.cube")
local MovingPlatform = require("objects.movingplatform")
local Decorations = require("decorations.init")
local Monitor = require("objects.monitor")
local ContextZones = require("systems.contextzones")
local LaserEmitter = require("objects.laseremitter")
local LaserReceiver = require("objects.laserreceiver")
local Liquids = require("systems.liquids")
local DropTube = require("objects.droptube")
local Button = require("objects.button")

local TILE_SIZE = LevelData.tileSize or 48
local currentChamber = 1
local chamberCount = #LevelData.chambers
local gameComplete = false
local isTransitioning = false
local loadChamber

local Transition = {
    active = false,
    phase = "idle",
    timer = 0,
    duration = 0.6,
    alpha = 0,
    nextChamber = nil,
}

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
    Button.clear()
    Exit.clear()
    MovingPlatform.clear()
    LaserEmitter.clear()
    LaserReceiver.clear()
    DropTube.clear()
end

local function spawnDecorations(chamber)
    Decorations.clear()

    ------------------------------------------------------
    -- 1. Spawn normal decor objects from chamber data
    ------------------------------------------------------
    for _, layer in ipairs(chamber.layers or {}) do
        if layer.kind == "decor" then
            Decorations.spawnLayer(layer, TILE_SIZE)
        end
    end

	------------------------------------------------------
	-- 2. AUTO-SPAWN PLATFORM TOP STRIPS (Solids only)
	------------------------------------------------------
	for _, layer in ipairs(chamber.layers or {}) do
		if layer.name == "Solids" and layer.kind == "rectlayer" then
			for _, r in ipairs(layer.rects or {}) do

				Decorations.spawn({
					type = "platformstrip",
					tx   = r.x,
					ty   = r.y - 1,
					w    = r.w,
					h    = 1,
				}, TILE_SIZE)

			end
		end
	end
end

local function spawnObjects(chamber)
    local objects = chamber.objects or {}

    local doorSpawned = false

    if objects.door then
        Door.spawn(objects.door.tx, objects.door.ty, TILE_SIZE, {
            id = objects.door.id or "door",
        })
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

    Plate.clear()
    for index, plate in ipairs(objects.plates or {}) do
        Plate.spawn(plate.tx * TILE_SIZE, plate.ty * TILE_SIZE, plate)
    end

    Cube.clear()
    for index, cube in ipairs(objects.cubes or {}) do
        Cube.spawn(cube.tx * TILE_SIZE, cube.ty * TILE_SIZE, {
            id = cube.id or string.format("cube_%d", index),
        })
    end

    Saw.clear()
    for index, saw in ipairs(objects.saws or {}) do
        Saw.spawn(saw.tx * TILE_SIZE, saw.ty * TILE_SIZE, {
            id = saw.id or string.format("saw_%d", index),
            dir = saw.dir,
            mount = saw.mount,
            speed = saw.speed,
            length = saw.length,
            sineAmp = saw.sineAmp,
            sineFreq = saw.sineFreq,
            active = saw.active,
            target = saw.target,
        })
    end

    LaserEmitter.clear()
    for _, emitter in ipairs(objects.laserEmitters or {}) do
        LaserEmitter.spawn(emitter.tx, emitter.ty, emitter.dir)
    end

    LaserReceiver.clear()
    for index, receiver in ipairs(objects.laserReceivers or {}) do
        LaserReceiver.spawn(receiver.tx, receiver.ty, receiver.dir, receiver.id)
    end

    DropTube.clear()
    DropTube.tileSize = TILE_SIZE
    for index, tube in ipairs(objects.dropTubes or {}) do
        DropTube.spawn(tube.tx, tube.ty, {
            id       = tube.id or string.format("droptube_%d", index),
            segments = tube.segments or tube.length,
        })
    end

	if objects.buttons then
		for _, b in ipairs(objects.buttons) do
			Button.spawn(b.tx, b.ty, b)
		end
	end

    if objects.movingPlatforms then
        for _, mp in ipairs(objects.movingPlatforms) do
                MovingPlatform.spawn(
                    mp.tx * TILE_SIZE,
                    mp.ty * TILE_SIZE,
                    {
                        dir         = mp.dir or "horizontal",
                        trackTiles  = mp.trackTiles or 2,
                        widthTiles  = mp.widthTiles or 2,
                        speed       = mp.speed or 0.3,
                        active      = mp.active,       -- true OR false
                        target      = mp.target,       -- string ID for plates
                        loop        = mp.loop,
                    }
                )
            end
        end

    Monitor.clear()
    Monitor.tileSize = TILE_SIZE

    for index, monitor in ipairs(objects.monitors or {}) do
        Monitor.spawn(monitor.tx, monitor.ty, monitor.dir or 1, {
            id = monitor.id or string.format("monitor_%d", index),
        })
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
    local chamber = LevelData.chambers[index]  -- Brute force here for testing, return to index when done, 1 or index
    assert(chamber, "No chamber data for index " .. tostring(index))

    chamber.tileSize = LevelData.tileSize

    Level.load(chamber)
    TILE_SIZE = Level.tileSize or TILE_SIZE

    Chamber.reset(index, chamberCount, chamber.doorCriteria, chamber.objects)
    clearActors()
    spawnDecorations(chamber)
    spawnObjects(chamber)
	spawnContextZones(chamber)
	Player.init(Level)

	-- Instead of spawning directly, begin the drop-in sequence
	local dropTube = DropTube.list[1]  -- simple: first tube in the chamber
	if dropTube then
		Timer.after(0.8, function()
			DropTube.dropPlayer(dropTube)
		end)
	end
end

--------------------------------------------------------------
-- LOVE CALLBACKS
--------------------------------------------------------------

function love.load()
    Blink.init()
    loadChamber(currentChamber)
end

function love.update(dt)
	Timer.update(dt)
    ----------------------------------------------------------
    -- Input system
    ----------------------------------------------------------
    Input.update()

    ----------------------------------------------------------
    -- Player update with Level collision queries
    ----------------------------------------------------------
    local pl = Player.update(dt, Level)

	-- Handle drop-tube respawn
	if pl.pendingTubeRespawn then
		pl.pendingTubeRespawn = false

		local tube = DropTube.list[1]
		if tube then
			DropTube.dropPlayer(tube)
		end
	end

	ContextZones.update(pl)

	if not pl.sleeping and not pl.sleepingTransition then
		Blink.update(dt)
	end

    Cube.update(dt, pl)
    Plate.update(dt, pl, Cube.list)
	Button.update(dt, pl)
    Door.update(dt)
    Monitor.update(dt)
    MovingPlatform.update(dt)
    LaserEmitter.update(dt)
    LaserReceiver.update(dt, LaserEmitter.list)
    DropTube.update(dt)
    Particles.update(dt)
	Liquids.update(dt)
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
    -- Indicator logic
    ----------------------------------------------------------
	local chamber = LevelData.chambers[currentChamber]

	if chamber.indicatorLogic then
		local map = chamber.indicatorLogic(Plate, MovingPlatform, LaserReceiver)
		Decorations.setIndicators(map)
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

    if key == "r" then
        local mx, my = love.mouse.getPosition()
		Liquids.ripple(mx, my, 500)
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
	Button.draw()
    LaserEmitter.draw()
    LaserReceiver.draw()
    Saw.draw()
    Door.draw()
    Plate.draw()
    Cube.draw()
	MovingPlatform.draw()
	Liquids.draw()
	ContextZones.draw() -- remove after debugging
	Player.draw()
	DropTube.draw()

    Particles.draw()

    Camera.clear()

    if Transition.active and Transition.alpha > 0 then
        love.graphics.setColor(0, 0, 0, Transition.alpha)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    end
end