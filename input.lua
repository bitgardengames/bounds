--------------------------------------------------------------
-- INPUT MODULE (Keyboard + Gamepad)
-- Supports: held state, pressed/released, jump buffering,
-- and unified movement input for Player.
--------------------------------------------------------------

local Input = {}

local function isJumpKey(key)
    return key == "space" or key == "w" or key == "up"
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
    if button == "a" or button == "cross" then
        Input.jumpQueued = true
    end
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

        if lx < -deadzone then
            Input.down["gp_left"] = true
        else
            Input.down["gp_left"] = nil
        end

        if lx > deadzone then
            Input.down["gp_right"] = true
        else
            Input.down["gp_right"] = nil
        end

        ------------------------------------------------------
        -- D-PAD (digital)
        ------------------------------------------------------
        if gamepad:isGamepadDown("dpleft") then
            Input.down["gp_left"] = true
        end
        if gamepad:isGamepadDown("dpright") then
            Input.down["gp_right"] = true
        end

        ------------------------------------------------------
        -- D-PAD Vertical (if needed later)
        ------------------------------------------------------
        if gamepad:isGamepadDown("dpup") then
            Input.down["gp_up"] = true
        else
            Input.down["gp_up"] = nil
        end

        if gamepad:isGamepadDown("dpdown") then
            Input.down["gp_down"] = true
        else
            Input.down["gp_down"] = nil
        end
    end
end

--------------------------------------------------------------
-- LATE UPDATE (clear one-frame states after use)
--------------------------------------------------------------

function Input.postUpdate()
    Input.pressed  = {}
    Input.released = {}
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
    return Input.wasPressed("space")
        or Input.wasPressed("w")
        or Input.wasPressed("up")
        or Input.wasPressed("gp_btn_a")
        or Input.wasPressed("gp_btn_cross")
end

function Input.wasJumpReleased()
    return Input.wasReleased("space")
        or Input.wasReleased("w")
        or Input.wasReleased("up")
        or Input.wasReleased("gp_btn_a")
        or Input.wasReleased("gp_btn_cross")
end

function Input.isJumpDown()
    return Input.isDown("space", "w", "up", "gp_btn_a", "gp_btn_cross")
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