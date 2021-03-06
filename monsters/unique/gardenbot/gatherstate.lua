--------------------------------------------------------------------------------
gatherState = {}
--------------------------------------------------------------------------------
function gatherState.enter()
  local position = entity.position()
  local target = gatherState.findTargetPosition(position)
  if target ~= nil then
    return {
      targetId = target.targetId,
      targetPosition = target.targetPosition,
      timer = entity.randomizeParameterRange("gardenSettings.locateTime"),
      located = false
    }
  end
  return nil,1
end
--------------------------------------------------------------------------------
function gatherState.update(dt, stateData)
  stateData.timer = stateData.timer - dt
  if stateData.targetPosition == nil then
    return true,entity.configParameter("gardenSettings.cooldown", 15)
  end
  
  local position = entity.position()
  local toTarget = world.distance(stateData.targetPosition, position)
  local distance = world.magnitude(toTarget)
  if distance - 1 <= entity.configParameter("gardenSettings.interactRange") then
    entity.setFacingDirection(util.toDirection(toTarget[1]))
    entity.setAnimationState("movement", "work")
    if not stateData.located then
      stateData.located = true
      stateData.timer = entity.randomizeParameterRange("gardenSettings.depositTime")
    elseif stateData.timer < 0 then
      local r = world.takeItemDrop(stateData.targetId, entity.id())
      if r ~= nil then
        self.inv.add({name = r.name, count = r.count, data = r.data})
        if self.seedMemory and self.seedMemory[r.name] ~= nil then self.lastSeed = r.name end
      end
    end
  else
    local dy = entity.configParameter("gardenSettings.fovHeight") / 2
    move({util.toDirection(toTarget[1]), toTarget[2] + dy})
  end

  return stateData.timer < 0
end
--------------------------------------------------------------------------------
function gatherState.findTargetPosition(position)
  local objectIds = {}
  if string.find(self.searchType, '^linear') then
    local p1 = vec2.add({-self.searchDistance, 0}, position)
    local p2 = vec2.add({self.searchDistance, 0}, position)
    objectIds = world.itemDropQuery(p1, p2)
  elseif string.find(self.searchType, '^radial') then
    objectIds = world.itemDropQuery(position, self.searchDistance)
  end
  if entity.configParameter("gardenSettings.efficiency") then
    table.sort(objectIds, distanceSort)
  end
  for _,oId in pairs(objectIds) do
    if gatherState.canGather(world.entityName(oId)) then
      local oPos = world.entityPosition(oId)
      --local dy = entity.configParameter("gardenSettings.fovHeight") / 2
      --oPos[2] = oPos[2] + dy
      --local tPos = {0, oPos[2]}
      --if oPos[1] < position[1] then
      --  tPos[1] = oPos[1] + entity.configParameter("gardenSettings.interactRange")
      --else
      --  tPos[1] = oPos[1] - entity.configParameter("gardenSettings.interactRange")
      --end
	  if canReachTarget(oId) then
        return { targetId = oId, targetPosition = oPos }
	  end
    end
  end

  return nil
end

function gatherState.canGather(name)
  if name == nil then return false end
  if self.harvest[string.lower(name)] then return true end
  if self.harvestType[world.itemType(name)] then return true end
  for _,v in ipairs(self.harvestMatch) do
    local match = string.match(string.lower(name), v)
    if match ~= nil then return true end
  end
  return false
end