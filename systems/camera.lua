--------------------------------------------------------------
-- CAMERA MODULE
-- Handles tracking the player and applying transforms
--------------------------------------------------------------

local Camera = {
    x = 0,
    y = 0
}

--------------------------------------------------------------
-- UPDATE — center camera on player
--------------------------------------------------------------

function Camera.update(player)
    Camera.x = player.x - love.graphics.getWidth() / 2 + player.w / 2
    Camera.y = player.y - love.graphics.getHeight() / 2 + player.h / 2
end

--------------------------------------------------------------
-- APPLY — push + translate for world rendering
--------------------------------------------------------------

function Camera.apply()
    love.graphics.push()
    love.graphics.translate(-Camera.x, -Camera.y)
end

--------------------------------------------------------------
-- CLEAR — pop transform
--------------------------------------------------------------

function Camera.clear()
    love.graphics.pop()
end

return Camera