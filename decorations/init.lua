local Particles = require("particles")

local Decorations = {}

local registry = {}
local list = {}

Decorations.list = list

Decorations.style = {
    dark = {0.1, 0.1, 0.1, 1},
    outline = {45/255, 66/255, 86/255, 1},
    panel = {0.90, 0.90, 0.93, 1},
    background = {69/255, 89/255, 105/255},
    metal = {82/255, 101/255, 114/255, 1},
    grill = {72/255, 91/255, 104/255, 1},
    fanFill = {0.88, 0.88, 0.92, 1},
}

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
        data = {},
    }

    if prefab.init then
        prefab.init(inst)
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
        if inst.type == "pipe_junctionbox" then
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
loadPrefab("steam")

return Decorations
