local Plate = require("pressureplate")

local Chamber = {
    exitEnabled = false,
    isComplete  = false,
    current     = 1,
    total       = 1,
}

function Chamber.reset(index, total)
    Chamber.current = index or Chamber.current
    Chamber.total   = total or Chamber.total
    Chamber.exitEnabled = false
    Chamber.isComplete  = false
end

function Chamber.update(dt, Player, Door, ExitTrigger)
    local plateOk = Plate.isDown()
    local laserOk = true
    local switchOk = true

    if plateOk and laserOk and switchOk then
        Door.setOpen(true)
        Chamber.exitEnabled = true
    else
        Door.setOpen(false)
        Chamber.exitEnabled = false
    end

    if Chamber.exitEnabled and ExitTrigger.playerInside(Player) and not Chamber.isComplete then
        Chamber.isComplete = true
    end
end

return Chamber