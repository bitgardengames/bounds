local Particles = require("systems.particles")
local Theme = require("theme")

local Decorations = {}

local registry = {}
local list = {}
local updatable = {}
local strips = {}

Decorations.list = list
Decorations.style = Theme.decorations
Decorations.colors = Theme.decorations
Decorations.strips = strips
Decorations.Particles = Particles

local function shallowCopy(source)
    if not source then return {} end

    local copy = {}
    for k, v in pairs(source) do
        copy[k] = v
    end

    return copy
end

function Decorations.register(name, prefab)
    assert(prefab.draw, "Prefab '" .. name .. "' must include a draw function.")
    registry[name] = prefab
end

function Decorations.spawn(entry, tileSize)
    local prefab = registry[entry.type]
    if not prefab then
        print("Warning: unknown decoration type '" .. tostring(entry.type) .. "'")
        return
    end

    tileSize = tileSize or 48

    local wTiles = prefab.w or 1
    local hTiles = prefab.h or 1

    local inst = {
        type = entry.type,
        x = entry.tx * tileSize,
        y = entry.ty * tileSize,
        w = wTiles * tileSize,
        h = hTiles * tileSize,
        data = shallowCopy(entry.data),
        config = entry,
    }

	inst.config = entry
	inst.config.tileSize = tileSize

    if prefab.init then
        prefab.init(inst, entry)
    end

    -- route platform strips to their own layer
    if entry.type == "platformstrip" then
        table.insert(strips, inst)
    else
        table.insert(list, inst)
        if prefab.update then
            table.insert(updatable, inst)
        end
    end

    table.insert(list, inst)

    if prefab.update then
        updatable[#updatable + 1] = inst
    end
end

function Decorations.spawnLayer(layer, tileSize)
    for _, obj in ipairs(layer.objects or {}) do
        Decorations.spawn(obj, tileSize)
    end
end

function Decorations.clear()
    for i = #list, 1, -1 do list[i] = nil end
    for i = #updatable, 1, -1 do updatable[i] = nil end
    for i = #strips, 1, -1 do strips[i] = nil end
end

function Decorations.draw()
    for _, d in ipairs(list) do
        local prefab = registry[d.type]
        if prefab then
            prefab.draw(d.x, d.y, d.w, d.h, d)
        end
    end
end

function Decorations.update(dt)
    if #updatable == 0 then return end

    for _, inst in ipairs(updatable) do
        local prefab = registry[inst.type]
        if prefab and prefab.update then
            prefab.update(inst, dt)
        end
    end
end

function Decorations.setIndicatorActive(id, active)
    for _, inst in ipairs(list) do
        if inst.type == "conduit_indicator" and inst.data.id == id then
            inst.data.active = active
        end
    end
end

function Decorations.setIndicators(map)
    for _, inst in ipairs(list) do
        if inst.type == "conduit_indicator" then
            local id = inst.data.id
            if id and map[id] ~= nil then
                inst.data.active = map[id]
            end
        end
    end
end

function Decorations.drawStrips()
    for _, d in ipairs(strips) do
        local prefab = registry[d.type]
        if prefab then
            prefab.draw(d.x, d.y, d.w, d.h, d)
        end
    end
end

local function loadPrefab(moduleName)
    local loader = require("decorations.prefabs." .. moduleName)
    loader(Decorations)
end

loadPrefab("panels")
loadPrefab("vents")
loadPrefab("fans")
loadPrefab("lights")
loadPrefab("pipes")
loadPrefab("conduit")
loadPrefab("steam")
loadPrefab("signs")
loadPrefab("platformtrack")
loadPrefab("backgroundnoise")
loadPrefab("panelseams")
loadPrefab("platformstrip")

return Decorations