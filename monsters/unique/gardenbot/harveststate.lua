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
      local result = harvestState.harvestFarmable(stateData.targetId)
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
    objectIds = world.objectLineQuery(p1, p2, { callScript = "entity.configParameter", callScriptArgs = {"category"}, callScriptResult = "farmable" })
  elseif string.find(self.searchType, '^radial') then
    objectIds = world.objectQuery(position, self.searchDistance, { callScript = "entity.configParameter", callScriptArgs = {"category"}, callScriptResult = "farmable" })
  end
  if entity.configParameter("gardenSettings.efficiency") then
    table.sort(objectIds, distanceSort)
  end
  for _,oId in pairs(objectIds) do
    local oPosition = world.entityPosition(oId)
    if canReachTarget(oId) and harvestState.canHarvest(oId) then
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
--------------------------------------------------------------------------------
function harvestState.canHarvest(oId)
  local stage = nil
  if world.farmableStage then stage = world.farmableStage(oId) end
  local interactions = world.callScriptedEntity(oId, "entity.configParameter", "interactionTransition", nil)
  if stage ~= nil and interactions[tostring(stage)] ~= nil then
      return true
  end
  return false
end
--------------------------------------------------------------------------------
function harvestState.harvestFarmable(oId)
  local stage = "2"
  if world.farmableStage then stage = world.farmableStage(oId) end
  local drops = world.callScriptedEntity(oId, "entity.configParameter", "interactionTransition." .. tostring(stage) .. ".dropOptions", nil)
  --world.callScriptedEntity(oId, "entity.randomizeParameter", "interactionTransition." .. stage .. ".dropOptions")
    if drops then
      local pos = world.entityPosition(oId)
      local i = 2
      local odds = drops[1]
      while drops[i] do
        if drops[i+1] == nil or math.random() < odds then
          local j = 1
          while drops[i][j] do
            local name = drops[i][j].name
            if self.harvest[string.lower(name)] == nil and world.itemType(name) == "generic" then
              self.harvest[string.lower(name)] = true
            end
            world.spawnItem(name, {pos[1], pos[2] + 1}, drops[i][j].count)
            j = j + 1
          end
          break
        end
        i = i + 1
      end
    end
    world.callScriptedEntity(oId, "entity.break")
end