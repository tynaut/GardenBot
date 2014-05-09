--------------------------------------------------------------------------------
depositState = {}
--------------------------------------------------------------------------------
function depositState.enter()
  local count = self.inv.inventoryCount()
  if count ~= nil and count > 0 then
    local position = entity.position()
    local target = depositState.findTargetPosition(position)
    if target ~= nil then
      self.homeBin = target.targetId
      return {
        targetId = target.targetId,
        targetPosition = target.targetPosition,
        timer = entity.randomizeParameterRange("gardenSettings.locateTime"),
        located = false
      }
    end
  end
  return nil,entity.configParameter("gardenSettings.cooldown", 15)
end
--------------------------------------------------------------------------------
function depositState.update(dt, stateData)
  stateData.timer = stateData.timer - dt
  if stateData.targetPosition == nil then
    return true,entity.configParameter("gardenSettings.cooldown", 15)
  end
  
  local position = entity.position()
  local toTarget = world.distance(stateData.targetPosition, position)
  local distance = world.magnitude(toTarget)
  if distance < entity.configParameter("gardenSettings.interactRange") then
    entity.setAnimationState("movement", "work")
    if not stateData.located then
      stateData.located = true
      stateData.timer = entity.randomizeParameterRange("gardenSettings.depositTime")
    elseif stateData.timer < 0 then
      --TODO storage not working between game sessions for monsters
      --local seeds = self.inv.remove({group = "seeds", all = true})
      --local items = self.inv.remove({all = true})
      --local result = world.callScriptedEntity(stateData.targetId, "add", items)
      --self.inv.add(seeds)
      self.inv.putInContainer(stateData.targetId)
      return true,entity.configParameter("gardenSettings.cooldown", 15)
    end
  else
    move({util.toDirection(toTarget[1]), toTarget[2]})
  end

  return stateData.timer < 0
end
--------------------------------------------------------------------------------
function depositState.findTargetPosition(position)
  if self.homeBin and self.inv.canAddToContainer(self.homeBin) then
    local oPosition = world.entityPosition(self.homeBin)
    return { targetId = self.homeBin, targetPosition = oPosition }
  end
  local objectIds = {}
  if string.find(self.searchType, '^linear') then
    local p1 = vec2.add({-self.searchDistance, 0}, position)
    local p2 = vec2.add({self.searchDistance, 0}, position)
    objectIds = world.objectLineQuery(p1, p2, { callScript = "entity.configParameter", callScriptArgs = {"category"}, callScriptResult = "storage"})
  elseif string.find(self.searchType, '^radial') then
    objectIds = world.objectQuery(position, self.searchDistance, { callScript = "entity.configParameter", callScriptArgs = {"category"}, callScriptResult = "storage" })
  end
  if entity.configParameter("gardenSettings.efficiency") then
    table.sort(objectIds, distanceSort)
  end
  for _,oId in pairs(objectIds) do
    local oPosition = world.entityPosition(oId)
    if canReachTarget(oId) and self.inv.canAddToContainer(oId) then 
      return { targetId = oId, targetPosition = oPosition }
    end
  end
  
  return nil
end