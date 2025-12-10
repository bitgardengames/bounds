local Plate = require("objects.pressureplate")
local Decorations = require("decorations.init")
local LaserReceiver = require("objects.laserreceiver")

local Chamber = {
    exitEnabled = false,
    isComplete  = false,
    current     = 1,
    total       = 1,
    criteria    = {},
}

local function defaultCriteria(objects)
    if objects and objects.plates and #objects.plates > 0 then
        return { plates = { mode = "all" } }
    end

    return {}
end

local function evaluateRequirement(requirement, checkId, fallbackAll, fallbackAny)
    if not requirement then
        return true
    end

    local mode = requirement.mode or "all"
    local ids = requirement.ids

    if not ids or #ids == 0 then
        if mode == "all" then
            return fallbackAll()
        elseif mode == "any" then
            return fallbackAny()
        elseif mode == "none" then
            return not fallbackAny()
        end

        return false
    end

    local matches = 0

    for _, id in ipairs(ids) do
        if checkId(id) then
            matches = matches + 1
        end
    end

    if mode == "all" then
        return matches == #ids
    elseif mode == "any" then
        return matches > 0
    elseif mode == "none" then
        return matches == 0
    end

    return false
end

local function platesSatisfied(criteria)
    return evaluateRequirement(
        criteria,
        Plate.isDown,
        Plate.allDown,
        function() return Plate.isDown() end
    )
end

local function receiversSatisfied(criteria)
    local function allActive()
        if #LaserReceiver.list == 0 then return false end

        for _, inst in ipairs(LaserReceiver.list) do
            if not LaserReceiver.isActive(inst.id) then
                return false
            end
        end

        return true
    end

    local function anyActive()
        for _, inst in ipairs(LaserReceiver.list) do
            if LaserReceiver.isActive(inst.id) then
                return true
            end
        end

        return false
    end

    return evaluateRequirement(
        criteria,
        LaserReceiver.isActive,
        allActive,
        anyActive
    )
end

function Chamber.reset(index, total, criteria, objects)
    Chamber.current = index or Chamber.current
    Chamber.total   = total or Chamber.total
    Chamber.exitEnabled = false
    Chamber.isComplete  = false
    Chamber.criteria    = criteria or defaultCriteria(objects)
end

function Chamber.update(dt, Player, Door, ExitTrigger)
    local criteria = Chamber.criteria or {}

    local plateOk = platesSatisfied(criteria.plates)
    local laserOk = receiversSatisfied(criteria.lasers)

    local readyToOpen = plateOk and laserOk

    if readyToOpen then
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