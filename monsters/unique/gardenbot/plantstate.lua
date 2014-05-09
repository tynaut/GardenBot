--------------------------------------------------------------------------------
plantState = {}
--------------------------------------------------------------------------------
function plantState.enter()
  local position = entity.position()
  local target = plantState.findPosition(position)
  if target ~= nil then
    return {
      targetPosition = target.position,
      targetSeed = target.seed,
      timer = entity.randomizeParameterRange("gardenSettings.locateTime"),
      located = false
    }
  end
  return nil,entity.configParameter("gardenSettings.cooldown", 15)
end
--------------------------------------------------------------------------------
function plantState.update(dt, stateData)
  stateData.timer = stateData.timer - dt
  if stateData.targetPosition == nil then
    return true
  end
  
  local position = entity.position()
  local toTarget = world.distance(stateData.targetPosition, position)
  local distance = world.magnitude(toTarget)
  --TODO put a delay time here
  if distance < entity.configParameter("gardenSettings.interactRange") then
    entity.setFacingDirection(util.toDirection(toTarget[1]))
    entity.setAnimationState("movement", "work")
    if not stateData.located then
      stateData.located = true
      stateData.timer = entity.randomizeParameterRange("gardenSettings.plantTime")
    elseif stateData.timer < 0 then
      local seed,oId = plantState.getSeedName(stateData.targetSeed)
      if oId ~= nil then
        seed = self.inv.takeFromContainer(oId, {name = seed.name, count = 1})
      end
      if seed ~= nil then
        --TODO fail check to add to ignored seeds
        if world.placeObject(seed.name, stateData.targetPosition, 1, seed.data) then
          if oId == nil then self.inv.remove({name = seed.name, count = 1, data = seed.data}) end
          plantState.addToMemory(seed.name, stateData.targetPosition)
        else
          local fp = stateData.targetPosition[1] .. "," .. stateData.targetPosition[2]
          if storage.failedMemory[fp] then
            storage.failedMemory[fp] = storage.failedMemory[fp] + 1
          else storage.failedMemory[fp] = 1 end
          self.inv.add(seed)
        end
        return true
      end
    end
  else
    local dy = entity.configParameter("gardenSettings.fovHeight") / 2
    move({util.toDirection(toTarget[1]), toTarget[2] + dy})
  end

  return stateData.timer < 0,entity.configParameter("gardenSettings.cooldown", 15)
end
--------------------------------------------------------------------------------
function plantState.findPosition(position)

  local direction = entity.facingDirection()
  local basePosition = {
    math.floor(position[1] + 0.5),
    math.floor(position[2] + 0.5) - 1
  }
  
  local dy = 0
  if string.find(self.searchType, 'lumber$') then dy = -2 end
  
  for offset = 1, entity.configParameter("gardenSettings.plantDistance", 10), 1 do
    for d = -1, 2, 2 do
      local targetPosition = vec2.add({ offset * d, dy }, basePosition)
      --local modName = world.mod(vec2.add({0, -1}, targetPosition), "foreground")
      --if modName == nil or not string.find(modName, "tilled") then return nil end
      --local p1 = vec2.add(targetPosition, {0, -1})
      --local p2 = vec2.add(targetPosition, {0, 1})
      --local objects = world.objectQuery(p1, p2)
      --local objects = world.objectQuery(targetPosition, 0.5)
      local ps = targetPosition[1] .. "," .. targetPosition[2]
      local failedMemory = storage.failedMemory[ps]
      if canReachTarget(targetPosition) and (failedMemory == nil or failedMemory < 3) then
        local seed = plantState.getSeedName()
        if seed ~= nil then
          local d = plantState.plotSize(seed.name)
          if world.placeObject("gardenbotplot" .. d, targetPosition) then
            return { position = targetPosition, seed = seed.name}
          end
        end
      end
    end
  end
  --TODO if seed is 2 plot, and fails, then try looking for a 1 plot seed and try again
  return nil
end
--------------------------------------------------------------------------------
function plantState.plotSize(name)
  if string.find(name, "sapling") then return "S" end
  if storage.seedMemory[name] ~= nil then return storage.seedMemory[name] end
  return 2
end
--------------------------------------------------------------------------------
function plantState.addToMemory(name, pos)
  if storage.seedMemory[name] ~= nil then return nil end
  local seedIds = world.objectQuery(pos, 0, {name = name})
  if seedIds[1] then
    local bounds = world.callScriptedEntity(seedIds[1], "entity.boundBox")
    local plot = (bounds[3] - bounds[1]) - 2
    storage.seedMemory[name] = plot
  end
end
--------------------------------------------------------------------------------
function plantState.getSeedName(name)
  local position = entity.position()
  local search = entity.configParameter("gardenSettings.seed", "seed")
  if name ~= nil then search = name end
  local seed = nil
  seed = self.inv.findMatch(self.lastSeed, self.ignore)
  if seed == nil then seed = self.inv.findMatch(search, self.ignore) end
  if seed ~= nil then return seed,nil end
  
  local distance = 2 * self.searchDistance
  local fovHeight = entity.configParameter("gardenSettings.fovHeight")
  local min = vec2.add({-distance, -fovHeight/2}, position)
  local max = vec2.add({distance, fovHeight/2}, position)
  local objectIds = world.objectQuery(min, max, { callScript = "entity.configParameter", callScriptArgs = {"category"}, callScriptResult = "storage" })
  for _,oId in ipairs(objectIds) do
    if canReachTarget(oId) then
      seed = self.inv.matchInContainer(oId, {name = search, ignore = self.ignore})
      if seed ~= nil then return seed,oId end
    end
  end
  return nil
end
--------------------------------------------------------------------------------