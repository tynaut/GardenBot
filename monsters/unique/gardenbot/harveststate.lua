--------------------------------------------------------------------------------
harvestState = {}
--------------------------------------------------------------------------------
function harvestState.enter()
  local position = entity.position()
  local target = nil
  local type = nil
  if string.find(self.searchType, 'farm$') then 
    type = "farm"
    target = harvestState.findFarmPosition(position)
  elseif string.find(self.searchType, 'lumber$') then
    type = "lumber"
    target = harvestState.findLumberPosition(position)
  end
  if target ~= nil then
    return {
      targetId = target.targetId,
      targetPosition = target.targetPosition,
      timer = entity.randomizeParameterRange("gardenSettings.locateTime"),
      located = false,
      count = 0,
      type = type
    }
  end
  return nil,entity.configParameter("gardenSettings.cooldown", 15)
end
--------------------------------------------------------------------------------
function harvestState.update(dt, stateData)
  if stateData.type == "farm" then 
    return harvestState.farmUpdate(dt, stateData)
  elseif stateData.type == "lumber" then
    return harvestState.lumberUpdate(dt, stateData)
  end
end
--------------------------------------------------------------------------------
function harvestState.farmUpdate(dt, stateData)
  stateData.timer = stateData.timer - dt
  if stateData.targetPosition == nil then
    return true
  end
  
  local position = entity.position()
  local toTarget = world.distance(stateData.targetPosition, position)
  local distance = world.magnitude(toTarget)
  if distance < entity.configParameter("gardenSettings.interactRange") then
    entity.setAnimationState("movement", "work")
    entity.setFacingDirection(util.toDirection(toTarget[1]))
    if not stateData.located then
      stateData.located = true
      stateData.timer = entity.randomizeParameterRange("gardenSettings.harvestTime")
    elseif stateData.timer < 0 then
      local result = world.callScriptedEntity(stateData.targetId, "doHarvest")
    end
  else
    move(util.toDirection(toTarget[1]))
  end

  return stateData.timer < 0
end
--------------------------------------------------------------------------------
function harvestState.findFarmPosition(position)
  local objectIds = {}
  if string.find(self.searchType, '^linear') then
    local p1 = vec2.add({-self.searchDistance, 0}, position)
    local p2 = vec2.add({self.searchDistance, 0}, position)
    --objectIds = world.objectLineQuery(p1, p2, { callScript = "entity.configParameter", callScriptArgs = {"category"}, callScriptResult = "farmable" })
    --TODO use vanilla props for this
    objectIds = world.objectLineQuery(p1, p2, { callScript = "canHarvest" })
  elseif string.find(self.searchType, '^radial') then
    --objectIds = world.objectQuery(position, self.searchDistance, { callScript = "entity.configParameter", callScriptArgs = {"category"}, callScriptResult = "farmable" })
    objectIds = world.objectQuery(position, self.searchDistance, { callScript = "canHarvest" })
  end
  if entity.configParameter("gardenSettings.efficiency") then
    table.sort(objectIds, distanceSort)
  end
  for _,oId in pairs(objectIds) do
    local oPosition = world.entityPosition(oId)
    if canReachTarget(oId) then 
      return { targetId = oId, targetPosition = oPosition }
    end
  end
  
  return nil
end
--------------------------------------------------------------------------------
function harvestState.lumberUpdate(dt, stateData)
  stateData.timer = stateData.timer - dt
  if stateData.targetPosition == nil or not world.entityExists(stateData.targetId) then
    return true,entity.configParameter("gardenSettings.cooldown", 15)
  end
  
  local position = entity.position()
  local toTarget = world.distance(stateData.targetPosition, position)
  local distance = world.magnitude(toTarget)
  if distance < entity.configParameter("gardenSettings.interactRange") then
    if not stateData.located then
      stateData.located = true
      stateData.timer = 0
    end
    if stateData.timer <= 0 then
      entity.setFacingDirection(util.toDirection(toTarget[1]))
      entity.setAnimationState("attack", "melee")
      stateData.timer = entity.randomizeParameterRange("gardenSettings.harvestTime")
      world.damageTiles({stateData.targetPosition}, "foreground", position, "plantish", 2)
      stateData.count = stateData.count + 1
    end  
  else
    local dy = entity.configParameter("gardenSettings.fovHeight") / 2
    move({util.toDirection(toTarget[1]), toTarget[2] + dy})
  end

  if stateData.timer < 0 or stateData.count > 5 then
    self.ignore[stateData.targetId] = true
    return true,entity.configParameter("gardenSettings.cooldown", 15)
  end
  return false
end
--------------------------------------------------------------------------------
function harvestState.findLumberPosition(position)
  local objectIds = {}
  if string.find(self.searchType, '^linear') then
    local p1 = vec2.add({-self.searchDistance, 0}, position)
    local p2 = vec2.add({self.searchDistance, 0}, position)
    objectIds = world.entityLineQuery(p1, p2, {notAnObject = true})
  elseif string.find(self.searchType, '^radial') then
    objectIds = world.entityQuery(position, self.searchDistance, {notAnObject = true})
  end
  if entity.configParameter("gardenSettings.efficiency") then
    table.sort(objectIds, distanceSort)
  end
  for _,oId in pairs(objectIds) do
    local oPosition = world.entityPosition(oId)
    oPosition[2] = oPosition[2] + 1
    if world.entityType(oId) == "plant" and canReachTarget(oId) and not self.ignore[oId] then 
      return { targetId = oId, targetPosition = oPosition }
    end
  end
  
  return nil
end