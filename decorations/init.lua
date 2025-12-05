local Particles = require("particles")

local Decorations = {}

local registry = {}
local list = {}

Decorations.list = list

Decorations.style = {
    --dark = {0.1, 0.1, 0.1, 1},
    --dark = {32/255, 38/255, 45/255, 1},
	dark = {0.075, 0.075, 0.085, 1},
    --outline = {45/255, 66/255, 86/255, 1},
	outline = {35/255, 52/255, 70/255, 1},   -- #233446
    panel = {0.90, 0.90, 0.93, 1},
    background = {69/255, 89/255, 105/255},
    metal = {96/255, 118/255, 134/255, 1},
    grill = {72/255, 91/255, 104/255, 1},
    fanFill = {0.88, 0.88, 0.92, 1},
	pipe = {70/255, 82/255, 96/255, 1},
}

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
end

function Decorations.spawnLayer(layer, tileSize)
    for _, obj in ipairs(layer.objects or {}) do
        Decorations.spawn(obj, tileSize)
    end
end

function Decorations.clear()
    for i = #list, 1, -1 do
        list[i] = nil
    end
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
    for _, inst in ipairs(list) do
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

return Decorations
