local Exit = {}

Exit.defaultW = 48
Exit.defaultH = 48

Exit.x = 0
Exit.y = 0
Exit.w = Exit.defaultW
Exit.h = Exit.defaultH

Exit.active = false

function Exit.spawn(x, y, w, h)
    Exit.x = x
    Exit.y = y
    Exit.w = w or Exit.defaultW
    Exit.h = h or Exit.defaultH
    Exit.active = true
end

function Exit.clear()
    Exit.active = false
    Exit.x = 0
    Exit.y = 0
    Exit.w = Exit.defaultW
    Exit.h = Exit.defaultH
end

function Exit.playerInside(player)
    if not Exit.active then return false end

    local px = player.x + player.w/2
    local py = player.y + player.h/2

    return px >= Exit.x and px <= Exit.x + Exit.w
       and py >= Exit.y and py <= Exit.y + Exit.h
end

return Exit