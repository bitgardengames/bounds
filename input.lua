--------------------------------------------------------------
-- INPUT MODULE
-- Handles key state, pressed/released events, jump buffering,
-- and provides a clean polling API for Player and future systems.
--------------------------------------------------------------

local Input = {}

-- key states
Input.down    = {}   -- held keys
Input.pressed = {}   -- keys pressed this frame
Input.released = {}  -- keys released this frame

-- jump buffer flag (Player currently uses p.jumpQueued)
Input.jumpQueued = false

--------------------------------------------------------------
-- KEY PRESSED
--------------------------------------------------------------

function Input.keypressed(key)
    Input.down[key] = true
    Input.pressed[key] = true

    -- Handle jump keys (space, W, up)
    if key == "space" or key == "w" or key == "up" then
        Input.jumpQueued = true
    end
end

--------------------------------------------------------------
-- KEY RELEASED
--------------------------------------------------------------

function Input.keyreleased(key)
    Input.down[key] = nil
    Input.released[key] = true
end

--------------------------------------------------------------
-- CONSUME ONE-FRAME SIGNALS
-- Called once per frame in love.update
--------------------------------------------------------------

function Input.update()
    -- Clear pressed/released each frame after Player reads them
    Input.pressed  = {}
    Input.released = {}
end

--------------------------------------------------------------
-- POLLING UTILITIES (optional but nice)
--------------------------------------------------------------

function Input.isDown(...)
    for i = 1, select("#", ...) do
        if Input.down[ select(i, ...) ] then
            return true
        end
    end
    return false
end

function Input.wasPressed(key)
    return Input.pressed[key]
end

function Input.wasReleased(key)
    return Input.released[key]
end

--------------------------------------------------------------
-- Jump buffer integration
--------------------------------------------------------------

function Input.consumeJump()
    -- Player will call this — returns true once
    if Input.jumpQueued then
        Input.jumpQueued = false
        return true
    end
    return false
end

return Input