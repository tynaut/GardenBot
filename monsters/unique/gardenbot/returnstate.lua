--------------------------------------------------------------------------------
returnState = {}
--------------------------------------------------------------------------------
function returnState.enterWith(args)
    if self.spawnPoint == nil then self.spawnPoint = entity.configParameter("spawnPoint") end
    if self.homeBin ~= nil or self.spawnPoint ~= nil then
      local position = entity.position()
      local range = entity.configParameter("gardenSettings.wanderRange")
      local hPos = nil
      if self.homeBin ~= nil and world.entityExists(self.homeBin) then
        hPos = world.entityPosition(self.homeBin)
      else
        hPos = self.spawnPoint
      end
      local toTarget = world.distance(hPos, position)
      local distance = world.magnitude(toTarget)
      --if (type(args) == "table" and args.ignoreDistance) then world.logInfo("FORCED RETURN TO HOME") end
      if (type(args) == "table" and args.ignoreDistance) or distance > range then
        return {
          targetPosition = hPos,
          timer = entity.configParameter("gardenSettings.returnTime", 5)
        }
      end
    end
  return nil,entity.configParameter("gardenSettings.cooldown", 15)
end
--------------------------------------------------------------------------------
function returnState.update(dt, stateData)
  stateData.timer = stateData.timer - dt
  if stateData.targetPosition == nil then
    return true,entity.configParameter("gardenSettings.cooldown", 15)
  end
  
  local position = entity.position()
  local toTarget = world.distance(stateData.targetPosition, position)
  local distance = world.magnitude(toTarget)
  if distance < 3 * entity.configParameter("gardenSettings.interactRange") then
    stateData.timer = -1
    self.ignore = {}
    entity.setAnimationState("movement", "idle")
  else
    if stateData.timer < 0 then
      local p = stateData.targetPosition
      entity.setPosition({p[1], p[2] + 3})
      entity.setAnimationState("movement", "idle")
    else
      move({util.toDirection(toTarget[1]), toTarget[2]})
    end
  end

  return stateData.timer < 0,entity.configParameter("gardenSettings.cooldown", 15)
end