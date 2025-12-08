--------------------------------------------------------------
-- TIMER — Simple scheduling system for delayed callbacks
-- Supports:
--   Timer.after(delay, function)
--   Timer.every(interval, function)
--   Timer.update(dt)
--------------------------------------------------------------

local Timer = {}

Timer.tasks = {}

--------------------------------------------------------------
-- INTERNAL: create a task
--------------------------------------------------------------
local function newTask(delay, interval, callback)
    return {
        time = delay,               -- countdown
        interval = interval,        -- nil = one-shot
        callback = callback,
        alive = true,
    }
end

--------------------------------------------------------------
-- PUBLIC: run once after delay
--------------------------------------------------------------
function Timer.after(delay, callback)
    local t = newTask(delay, nil, callback)
    table.insert(Timer.tasks, t)
    return t
end

--------------------------------------------------------------
-- PUBLIC: run repeatedly every interval
--------------------------------------------------------------
function Timer.every(interval, callback)
    local t = newTask(interval, interval, callback)
    table.insert(Timer.tasks, t)
    return t
end

--------------------------------------------------------------
-- PUBLIC: cancel a timer
--------------------------------------------------------------
function Timer.cancel(task)
    if task then
        task.alive = false
    end
end

--------------------------------------------------------------
-- UPDATE: must be called every frame
--------------------------------------------------------------
function Timer.update(dt)
    for i = #Timer.tasks, 1, -1 do
        local t = Timer.tasks[i]

        if t.alive then
            t.time = t.time - dt

            if t.time <= 0 then
                -- fire callback
                t.callback()

                if t.interval then
                    -- repeating timer: reset countdown
                    t.time = t.interval
                else
                    -- one-shot: remove it
                    table.remove(Timer.tasks, i)
                end
            end
        else
            table.remove(Timer.tasks, i)
        end
    end
end

return Timer