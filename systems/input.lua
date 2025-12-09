--------------------------------------------------------------
-- INPUT MODULE (Keyboard + Gamepad)
-- Supports: held state, pressed/released, jump buffering,
-- and unified movement input for Player.
--------------------------------------------------------------

local Input = {}

local unpack = table.unpack or unpack

local jumpKeys = { space = true, w = true, up = true }
local jumpButtons = { a = true, cross = true }
local jumpInputs = { "space", "w", "up", "gp_btn_a", "gp_btn_cross" }

local function isJumpKey(key)
    return jumpKeys[key] ~= nil
end

local function isJumpButton(button)
    return jumpButtons[button] ~= nil
end

local function anyActive(stateTable, keys)
    for _, key in ipairs(keys) do
        if stateTable[key] then return true end
    end
    return false
end

-- key/button states
Input.down     = {}   -- held
Input.pressed  = {}   -- down this frame
Input.released = {}   -- released this frame

-- jump buffer
Input.jumpQueued = false

-- gamepad state
local gamepad = nil
local deadzone = 0.22

--------------------------------------------------------------
-- INTERNAL HELPERS
--------------------------------------------------------------

local function ensureGamepad()
    -- pick first connected gamepad
    if gamepad and gamepad:isConnected() then return end
    local pads = love.joystick.getJoysticks()
    gamepad = pads[1] or nil
end

local function stickAxis(value)
    if math.abs(value) < deadzone then return 0 end
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
    Input.down[key]    = true
    Input.pressed[key] = true
end

function Input.keyreleased(key)
    Input.down[key]     = nil
    Input.released[key] = true

    if isJumpKey(key) then
        Input.jumpQueued = true
    end
end

--------------------------------------------------------------
-- GAMEPAD EVENTS
--------------------------------------------------------------

function Input.gamepadpressed(joystick, button)
    ensureGamepad()
    if joystick ~= gamepad then return end

    local key = "gp_btn_" .. button

    Input.down[key]    = true
    Input.pressed[key] = true

end

function Input.gamepadreleased(joystick, button)
    ensureGamepad()
    if joystick ~= gamepad then return end

    local key = "gp_btn_" .. button

    Input.down[key]     = nil
    Input.released[key] = true

    -- Jump buttons
    if isJumpButton(button) then Input.jumpQueued = true end
end

--------------------------------------------------------------
-- UPDATE (called each frame)
--------------------------------------------------------------

function Input.update()
    ensureGamepad()

    if gamepad then
        ------------------------------------------------------
        -- ANALOG STICK
        ------------------------------------------------------
        local lx = stickAxis(gamepad:getAxis(1))
        local leftDown = lx < 0 or gamepad:isGamepadDown("dpleft")
        local rightDown = lx > 0 or gamepad:isGamepadDown("dpright")

        setHeld("gp_left", leftDown)
        setHeld("gp_right", rightDown)

        ------------------------------------------------------
        -- D-PAD (digital)
        ------------------------------------------------------
        setHeld("gp_up", gamepad:isGamepadDown("dpup"))
        setHeld("gp_down", gamepad:isGamepadDown("dpdown"))
    end
end

--------------------------------------------------------------
-- LATE UPDATE (clear one-frame states after use)
--------------------------------------------------------------

function Input.postUpdate()
    for key in pairs(Input.pressed) do Input.pressed[key] = nil end
    for key in pairs(Input.released) do Input.released[key] = nil end
end

--------------------------------------------------------------
-- QUERY HELPERS
--------------------------------------------------------------

function Input.isDown(...)
    for i = 1, select("#", ...) do
        local key = select(i,...)
        if Input.down[key] then return true end
    end
    return false
end

function Input.wasPressed(key)
    return Input.pressed[key]
end

function Input.wasReleased(key)
    return Input.released[key]
end

function Input.wasJumpPressed()
    return anyActive(Input.pressed, jumpInputs)
end

function Input.wasJumpReleased()
    return anyActive(Input.released, jumpInputs)
end

function Input.isJumpDown()
    return Input.isDown(unpack(jumpInputs))
end

--------------------------------------------------------------
-- JUMP BUFFER CONSUMPTION
--------------------------------------------------------------

function Input.consumeJump()
    if Input.jumpQueued then
        Input.jumpQueued = false
        return true
    end
    return false
end

return Input