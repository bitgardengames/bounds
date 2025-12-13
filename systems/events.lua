--------------------------------------------------------------
-- EVENTS — Lightweight global event bus
-- • Decouples gameplay systems
-- • Safe for prefab init + teardown
--------------------------------------------------------------

local Events = {
    listeners = {},
    DEBUG = true,
}

--------------------------------------------------------------
-- REGISTER
--------------------------------------------------------------
function Events.on(eventName, fn)
    assert(type(eventName) == "string", "Events.on: eventName must be a string")
    assert(type(fn) == "function", "Events.on: listener must be a function")

    local list = Events.listeners[eventName]
    if not list then
        list = {}
        Events.listeners[eventName] = list
    end

    table.insert(list, fn)

    -- Return an unsubscribe handle (optional usage)
    return function()
        Events.off(eventName, fn)
    end
end

--------------------------------------------------------------
-- UNREGISTER
--------------------------------------------------------------
function Events.off(eventName, fn)
    local list = Events.listeners[eventName]
    if not list then return end

    for i = #list, 1, -1 do
        if list[i] == fn then
            table.remove(list, i)
        end
    end

    if #list == 0 then
        Events.listeners[eventName] = nil
    end
end

--------------------------------------------------------------
-- EMIT
--------------------------------------------------------------
function Events.emit(eventName, payload)
    if Events.DEBUG then
        if payload and payload.id then
            print("[Events]", eventName, payload.id)
        else
            print("[Events]", eventName)
        end
    end

    local list = Events.listeners[eventName]
    if not list then return end

    -- Copy to protect against mutation during emit
    local snapshot = {}
    for i = 1, #list do
        snapshot[i] = list[i]
    end

    for _, fn in ipairs(snapshot) do
        fn(payload)
    end
end

--------------------------------------------------------------
-- CLEAR (used on chamber load)
--------------------------------------------------------------
function Events.clear()
    Events.listeners = {}
end

return Events