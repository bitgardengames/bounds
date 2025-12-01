local Exit = {}

Exit.x = 0
Exit.y = 0
Exit.w = 48
Exit.h = 48

Exit.active = false

function Exit.spawn(x, y)
    Exit.x = x
    Exit.y = y
    Exit.active = true
end

function Exit.playerInside(player)
    if not Exit.active then return false end

    local px = player.x + player.w/2
    local py = player.y + player.h/2

    return px >= Exit.x and px <= Exit.x + Exit.w
       and py >= Exit.y and py <= Exit.y + Exit.h
end

return Exit