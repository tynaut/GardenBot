inventoryManager = {}

function inventoryManager.create()
  local self = {}
  
  if storage.inventoryManager == nil then
    storage.inventoryManager = {}
  end

  function self.inventoryCount(args)
    local inv = storage.inventoryManager
    if args ~= nil and args.group ~= nil then
      local g,i = self.indexOf(args)
      if g ~= nil and inv[g] ~= nil then
        return table.maxn(inv[g].children)
      end
    end
    return table.maxn(inv)
  end
  
  function self.findMatch(name, ignore, value)
    if value == nil then value = true end
    if type(name) ~= "table" then name = {name} end
    if type(ignore) ~= "table" or ignore == nil then ignore = {} end
    local inv = storage.inventoryManager
    for i,v in ipairs(inv) do
      for _,n in ipairs(name) do
        if v.name ~= nil then
          local match = string.match(v.name, n)
          if match ~= nil and ignore[v.name] ~= value then
            return v.name,i
          end
        end
      end
    end
    return nil
  end
  
  function self.getNameAt(args)
    local inv = storage.inventoryManager
    local name = nil
    if args ~= nil then
      local index = 1
      if args.index ~= nil and type(args.index) == "number" then index = args.index end
      if args.group ~= nil then
        for i,v in ipairs(inv) do
          if type(v) == "table" and v.group == args.group then
            if v.children[index] ~= nil then
              name = v.children[index].name
            end
            break
          end
        end
      elseif inv[index] ~= nil then
        name = inv[index].name
      end
    end
    return name
  end
  
  function self.indexOf(args)
    local inv = storage.inventoryManager
    local group = nil
    local name = nil
    local j = nil
    local k = nil
    if type(args) == "string" then
      name = args
    elseif type(args) == "table" then
      if args.name ~= nil and type(args.name) == "string" then name = args.name end
      if args.group ~= nil and type(args.group) == "string" then group = args.group end
    end
    
    if group ~= nil then
      for i,v in ipairs(inv) do
        if type(v) == "table" and v.group == group then
          j = i
          inv = v.children
        end
      end
    end
    if name ~= nil then
      for i,v in ipairs(inv) do
        if type(v) == "table" and v.name == name then
          k = i
          break
        end
      end
    end

    if j == nil and k == nil then return nil end
    if j == nil then return k end
    return j,k
  end
  
  -- Add item to inventory
  --
  -- @param args item to add, could be a string or table { item, count, group}
  function self.add(args)
    --if helper ~= nil then helper.log("ADD INVENTORY " .. world.entityName(entity.id())) end
    if args == nil then return false end
    local inv = storage.inventoryManager
    local count = 1
    local group = nil
    local name = nil
    local data = nil
    if type(args) == "string" then
      name = args
    elseif type(args) == "table" then
      if args.count ~= nil and type(args.count) == "number" then count = args.count end
      if args.name ~= nil and type(args.name) == "string" then name = args.name end
      if args.group ~= nil and type(args.group) == "string" then group = args.group end
      data = args.data
    end
    if count < 0 then return false end
    if group ~= nil then    
      local g,i = self.indexOf({name = name, group = group})
      if g == nil then
        table.insert(inv, {group = group, children = {{name = name, count = count }}})
      else
        if i == nil then
          table.insert(inv[g].children, {name = name, count = count, data = data })
        else
          inv[g].children[i].count = inv[g].children[i].count + count
        end
      end
    elseif name ~= nil then
      local i = self.indexOf(name)
      --TODO because stacks > 1000 just cease to exist?
      if i == nil or inv[i].count + count > 1000 then
        table.insert(inv, {name = name, count = count, data = data })
      else
        inv[i].count = inv[i].count + count
      end
    elseif args[1] ~= nil then
      for _,v in ipairs(args) do
        if v ~= nil then
          if v.name ~= nil then
            self.add(v)
          elseif v.group then
            for _,w in ipairs(v.children) do
              w.group = v.group
              self.add(w)
            end
          end
        end
      end
    else
      return false
    end
    --if helper ~= nil then helper.log(inv) end
    storage.inventoryManager = inv
    return true
  end

  function self.remove(args)
    --if helper ~= nil then helper.log("REMOVE INVENTORY " .. world.entityName(entity.id())) end
    local inv = storage.inventoryManager
    local result = nil
    if type(args) == "string" then
      local i = self.indexOf({name = args})
      if i ~= nil then
        local r = table.remove(inv, i)
        result = {r}
      end
    elseif type(args) == "table" then
      local count = nil
      local group = nil
      local name = nil
      if args.count ~= nil and type(args.count) == "number" then count = args.count end
      if args.name ~= nil and type(args.name) == "string" then name = args.name end
      if args.group ~= nil and type(args.group) == "string" then group = args.group end
      if args.all ~= nil and type(args.all) == "boolean" and args.all then
        if group ~= nil then
          local g,i = self.indexOf({group = group})
          if g ~= nil then
            result = {inv[g]}
            table.remove(inv, g)
          end
        else
          result = inv
          inv = {}
        end
      elseif name ~= nil then
        if group ~= nil then
          local g,i = self.indexOf({group = group, name = name})
          if g ~= nil and i ~= nil then
            if inv[g].children[i].count > count then
              inv[g].children[i].count = inv[g].children[i].count - count
              result = {{name = name, count = count }}
            else
              local r = table.remove(inv[g].children, i)
              result = {r}
            end
          end
        else
          local i = self.indexOf(name)
          if i ~= nil then
            if inv[i].count > count then
              inv[i].count = inv[i].count - count
              result = {{name = name, count = count }}
            else
              local r = table.remove(inv, i)
              result = {r}
            end
          end
        end
      end
    end
    storage.inventoryManager = inv
    --if helper ~= nil then helper.log(inv) end
    return result
  end

  function self.drop(args)
    if type(args) ~= "table" or args.position == nil then return nil end
    
    local result = self.remove(args)
    if result == nil then return nil end
    
    for i,v in ipairs(result) do
      if v ~= nil and v.name ~= nil then
        world.spawnItem(v.name, args.position, v.count, v.data)
      elseif v~= nil and v.group ~= nil then
        for j,c in pairs(v.children) do
          if c ~= nil and c.name ~= nil then
            world.spawnItem(c.name, args.position, c.count, c.data)
          end
        end
      end
    end
  end
  
  function self.emptyContainerSlots(container)
    if type(container) ~= "number" then return nil end
    local size = world.containerSize(container)
    local count = 0
    for i = 0,size,1 do
      local item = world.containerItemAt(container, i)
      if item == nil then
        count = count + 1
      end
    end
    return count
  end
  
  function self.canAddToContainer(container, args)
    if type(container) ~= "number" then return false end
    local fitCount = 0
    local index = nil
    if type(args) == "table" and args.name ~= nil then
     fitCount = world.containerItemsCanFit(container, args)
    elseif args == nil then
      local inv = storage.inventoryManager
      for i,v in ipairs(inv) do
        fitCount = world.containerItemsCanFit(container, v)
        if fitCount > 0 then
          index = i
          break
        end
      end
    end
    return fitCount > 0, index
  end
  
  function self.putInContainer(container, args)
    --helper.log("PUTINCONTAINER")
    --helper.log(args)
    if type(container) ~= "number" then return false end
    local fitCount = 0
    if type(args) == "table" and args.name then
      fitCount = world.containerItemsCanFit(container, args)
      return fitCount > 0, world.containerAddItems(container, args)
    elseif args == nil then
      local inv = storage.inventoryManager
      local leftovers = {}
      while next(inv) ~= nil do
        local item = table.remove(inv, 1)
        --helper.log(item)
        item = world.containerAddItems(container, item)
        --helper.log(item)
        if item ~= nil then
          table.insert(leftovers, item)
        end
      end
      storage.inventoryManager = leftovers
    end
    return fitCount > 0
  end
  
  function self.takeFromContainer(container, args)
    if type(container) ~= "number" then return nil end
    if type(args) == "number" then
      return world.containerTakeAt(container, args)
    elseif type(args) == "string" then
      local n,i = self.matchInContainer(container, args)
      if n ~= nil then return world.containerTakeAt(container, i) end
    elseif type(args) == "table" then
      local n = nil
      local index = 0
      if args.name ~= nil then n,index = self.matchInContainer(container, args.name) end
      if args.index ~= nil then index = args.index end
      if args.count ~= nil then
        return world.containerTakeNumItemsAt(container, index, args.count)
      else
        return world.containerTakeAt(container, index)
      end
    elseif args == nil then
      return world.containerTakeAll(container)
    end
    
    return nil
  end
  
  function self.matchInContainer(container, args)
    if type(container) ~= "number" then return false end
    local size = world.containerSize(container)
    local index = 0
    local name = nil
    local ignore = {}
    if type(args) == "string" then 
      name = args
    elseif type(args) == "table" then
      name = args.name
      if type(args.index) == "number" then index = args.index end
      if type(args.ignore) == "table" then ignore = args.ignore end
    end
    if type(name) ~= "table" then name = {name} end
    for i = index,size,1 do
      for _,n in ipairs(name) do
        local item = world.containerItemAt(container, i)
        if item ~= nil then
          local match = string.match(item.name, n)
          if match ~= nil and ignore[item.name] ~= true then
            return item.name,i
          end
        end
      end
    end
    return nil
  end
  
  return self
end


