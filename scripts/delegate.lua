if delegate == nil or delegate.v == nil or delegate.v < 1 then
    --------------------------------------------------------------------------------
    delegate = {
        v = 1,
        delegates = {},
        callbacks = {}
    }
    --------------------------------------------------------------------------------
    -- overload hooks
    --------------------------------------------------------------------------------
    delegate.init = init
    function init(args)
        local result = delegate.triggerAll("init")
        if result == nil and delegate.init ~= nil then delegate.init(args) end
    end
    --------------------------------------------------------------------------------
    delegate.main = main
    function main()
        if delegate.tick ~= nil then delegate.tick() end
        local result = delegate.triggerAll("main")
        if result == nil and delegate.main ~= nil then delegate.main() end
    end
    --------------------------------------------------------------------------------
    delegate.die = die
    function die()
        local result = delegate.triggerAll("die")
        if result == nil and delegate.die ~= nil then delegate.die() end
    end
    --------------------------------------------------------------------------------
    delegate.damage = damage
    function damage(args)
        local result = delegate.triggerAll("damage", args)
        if result == nil and delegate.damage ~= nil then delegate.damage(args) end
    end
    --------------------------------------------------------------------------------
    delegate.interact = interact
    function interact(args)
        local result = delegate.triggerAll("interact", args)
        if result == nil and delegate.interact ~= nil then delegate.interact(args) end
    end
    --------------------------------------------------------------------------------
    -- delegate functions
    --------------------------------------------------------------------------------
    function delegate.create(targetName)
       table.insert(delegate.delegates, targetName)
    end
    --------------------------------------------------------------------------------
    function delegate.remove(targetName)
        for i,d in ipairs(delegate.delegates) do
            if d == targetName then
                table.remove(delegate.delegates, i)
                return
            end
        end
    end
    --------------------------------------------------------------------------------
    function delegate.triggerAll(functionName, args)
        for _,d in pairs(delegate.delegates) do
            local result = delegate.callback(d, functionName, args)
            if result ~= nil then return result end
        end
    end
    --------------------------------------------------------------------------------
    function delegate.callback(targetName, functionName, args)
        if _ENV[targetName] ~= nil and _ENV[targetName][functionName] ~= nil then
            return _ENV[targetName][functionName](args)
        end
    end
    --------------------------------------------------------------------------------
    function delegate.delayCallback(targetName, functionName, args, delay)
        if type(delay) ~= "number" then delay = 0 end
        table.insert(delegate.callbacks, {t = targetName, f = functionName, a = args, d = delay})
        if delegate.tick == nil then
            delegate.tick = delegate.delayTick
        end
    end
    --------------------------------------------------------------------------------
    function delegate.delayTick()
        for i,call in ipairs(delegate.callbacks) do
            if call.d <= 0 then
                table.remove(delegate.callbacks, i)
                delegate.callback(call.t, call.f, call.a)
            else
                delegate.callbacks[i].d = delegate.callbacks[i].d - entity.dt()
            end
        end
        if next(delegate.callbacks) == nil then delegate.tick = nil end
    end
    --------------------------------------------------------------------------------
end