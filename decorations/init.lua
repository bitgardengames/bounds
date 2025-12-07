local Particles = require("particles")
local Theme = require("theme")

local Decorations = {}

local registry = {}
local list = {}
local updatable = {}

Decorations.list = list
Decorations.style = Theme.decorations
Decorations.colors = Theme.decorations

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

    if prefab.init then
        prefab.init(inst, entry)
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

function Decorations.setJunctionBoxesActive(active)
    for _, inst in ipairs(list) do
        if inst.type == "conduit_junctionbox" then
            inst.data.active = not not active
        end
    end
end

Decorations.Particles = Particles

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

return Decorations