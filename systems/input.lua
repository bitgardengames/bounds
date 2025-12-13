--------------------------------------------------------------
-- INPUT MODULE (Keyboard + Gamepad)
-- • Unified keyboard + gamepad input
-- • Held / pressed / released
-- • Axis-based movement (analog-ready)
-- • Time-based jump buffering
-- • Global input locking (cutscenes, drop tubes, sleep)
--------------------------------------------------------------

local Input = {}

local unpack = table.unpack or unpack

--------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------

local DEADZONE = 0.22
local JUMP_BUFFER_TIME = 0.12

--------------------------------------------------------------
-- STATE
--------------------------------------------------------------

Input.down     = {}   -- held
Input.pressed  = {}   -- pressed this frame
Input.released = {}   -- released this frame

Input.locked = false

-- jump buffer
Input.jumpTimer = 0

-- cached per-frame values
Input.jumpDown = false
Input.moveAxis = 0

--------------------------------------------------------------
-- INPUT MAPS
--------------------------------------------------------------

Input.actions = {
    jump  = { "space", "w", "up", "gp_btn_a", "gp_btn_cross" },
    left  = { "a", "left", "gp_left" },
    right = { "d", "right", "gp_right" },
}

--------------------------------------------------------------
-- GAMEPAD
--------------------------------------------------------------

local gamepad = nil

local function ensureGamepad()
    if gamepad and gamepad:isConnected() then return end
    local pads = love.joystick.getJoysticks()
    gamepad = pads[1]
end

local function axis(value)
    if math.abs(value) < DEADZONE then return 0 end
    return value
end

local function setHeld(key, active)
    if active then
        Input.down[key] = true
    else
        Input.down[key] = nil
    end
end

--------------------------------------------------------------
-- KEYBOARD EVENTS
--------------------------------------------------------------

function Input.keypressed(key)
    Input.down[key] = true
    Input.pressed[key] = true
end

function Input.keyreleased(key)
    Input.down[key] = nil
    Input.released[key] = true

    -- jump buffering (on release feels best for Bounds)
    for _, k in ipairs(Input.actions.jump) do
        if k == key then
            Input.jumpTimer = JUMP_BUFFER_TIME
            break
        end
    end
end

--------------------------------------------------------------
-- GAMEPAD EVENTS
--------------------------------------------------------------

function Input.gamepadpressed(joystick, button)
    ensureGamepad()
    if joystick ~= gamepad then return end

    local key = "gp_btn_" .. button
    Input.down[key] = true
    Input.pressed[key] = true
end

function Input.gamepadreleased(joystick, button)
    ensureGamepad()
    if joystick ~= gamepad then return end

    local key = "gp_btn_" .. button
    Input.down[key] = nil
    Input.released[key] = true

    -- jump buffering
    if button == "a" or button == "cross" then
        Input.jumpTimer = JUMP_BUFFER_TIME
    end
end

--------------------------------------------------------------
-- UPDATE (call once per frame)
--------------------------------------------------------------

function Input.update(dt)
    ensureGamepad()

    ----------------------------------------------------------
    -- Gamepad axes / d-pad
    ----------------------------------------------------------
    local axisX = 0

    if gamepad then
        axisX = axis(gamepad:getAxis(1))

        setHeld("gp_left",  axisX < 0 or gamepad:isGamepadDown("dpleft"))
        setHeld("gp_right", axisX > 0 or gamepad:isGamepadDown("dpright"))
        setHeld("gp_up",    gamepad:isGamepadDown("dpup"))
        setHeld("gp_down",  gamepad:isGamepadDown("dpdown"))
    end

    ----------------------------------------------------------
    -- Jump buffer countdown
    ----------------------------------------------------------
    Input.jumpTimer = math.max(0, Input.jumpTimer - dt)

    ----------------------------------------------------------
    -- Cache jumpDown
    ----------------------------------------------------------
    Input.jumpDown = false
    for _, k in ipairs(Input.actions.jump) do
        if Input.down[k] then
            Input.jumpDown = true
            break
        end
    end

    ----------------------------------------------------------
    -- Cache move axis (keyboard + analog)
    ----------------------------------------------------------
    local move = 0

    if Input.down.a or Input.down.left or Input.down.gp_left then
        move = move - 1
    end
    if Input.down.d or Input.down.right or Input.down.gp_right then
        move = move + 1
    end

    move = move + axisX
    Input.moveAxis = math.max(-1, math.min(1, move))
end

--------------------------------------------------------------
-- POST UPDATE (clear one-frame states)
--------------------------------------------------------------

function Input.postUpdate()
    for k in pairs(Input.pressed) do Input.pressed[k] = nil end
    for k in pairs(Input.released) do Input.released[k] = nil end
end

--------------------------------------------------------------
-- LOCKING
--------------------------------------------------------------

function Input.setLocked(b)
    Input.locked = b
end

--------------------------------------------------------------
-- QUERY HELPERS
--------------------------------------------------------------

local function anyActive(state, keys)
    for _, k in ipairs(keys) do
        if state[k] then return true end
    end
    return false
end

function Input.isDown(...)
    if Input.locked then return false end

    for i = 1, select("#", ...) do
        local key = select(i, ...)
        if Input.down[key] then return true end
    end
    return false
end

function Input.wasPressed(key)
    return not Input.locked and Input.pressed[key]
end

function Input.wasReleased(key)
    return not Input.locked and Input.released[key]
end

function Input.isJumpDown()
    return not Input.locked and Input.jumpDown
end

function Input.wasJumpReleased()
    return not Input.locked and anyActive(Input.released, Input.actions.jump)
end

function Input.consumeJump()
    if not Input.locked and Input.jumpTimer > 0 then
        Input.jumpTimer = 0
        return true
    end
    return false
end

function Input.getMoveAxis()
    if Input.locked then return 0 end
    return Input.moveAxis
end

return Input