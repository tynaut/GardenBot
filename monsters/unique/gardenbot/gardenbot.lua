delegate.create("gardenbot")
--------------------------------------------------------------------------------
gardenbot = {}
--------------------------------------------------------------------------------
function gardenbot.init(args)
  entity.setDeathParticleBurst("deathPoof")
  entity.setAnimationState("movement", "idle")
  entity.setAggressive(false)
  
  self.inv = inventoryManager.create()

  self.ignore = {beakseed = true, talonseed = true, seedpile = true}
  storage.seedMemory = {}
  storage.failedMemory = {}
  local harvest = entity.configParameter("gardenSettings.gatherables")
  if harvest ~= nil then
    self.harvest = {}
    self.harvestMatch = {}
    self.harvestType = {}
    for _,v in ipairs(harvest) do
      if type(v) == "string" then self.harvest[string.lower(v)] = true end
      if type(v) == "table" then
        if v.match then table.insert(self.harvestMatch, v.match) end
        if v.type then self.harvestType[string.lower(v.type)] = true end
      end
    end
  end
  self.searchType = entity.configParameter("gardenSettings.searchType")
  self.searchDistance = entity.configParameter("gardenSettings.searchDistance")
end
--------------------------------------------------------------------------------
function gardenbot.damage(args)
  if entity.health() <= 0 then
    local spawner = nil
    if entity.type() then spawner = entity.type() .. "spawner" end
    if spawner ~= nil then self.inv.add({name = spawner, count = 1}) end
    self.inv.drop({all = true, position = entity.position()})
    self.dead = true
  end
  self.state.pickState(args.sourceId)
end
--------------------------------------------------------------------------------
function canReachTarget(target, ignoreLOS)
  local position = nil
  local pad = 1.2
  if type(target) == "number" then
    position = world.entityPosition(target)
    pad = pad + entity.configParameter("gardenSettings.interactRange") / 2
  elseif type(target) == "table" then
    position = target
  end
  if position == nil then return nil end
  local collision = false
  local ep = entity.position()
  local blocks = world.collisionBlocksAlongLine(ep, position, true, 2)
  collision = blocks[1] ~= nil
  if string.find(self.searchType, 'lumber$') then collision = #blocks == 2 end
  local fovHeight = entity.configParameter("gardenSettings.fovHeight")
  local min = nil
  local max = nil
  ep[2] = math.ceil(ep[2] + 0.5)
  --Target to the left
  if ep[1] > position[1] then
    min = {position[1]+pad, ep[2] - (fovHeight/2)}
    max = {ep[1]-pad, ep[2] + (fovHeight/2)}
  --Target to the right
  else
    min = {ep[1]+pad, ep[2] - (fovHeight/2)}
    max = {position[1]-pad, ep[2] + (fovHeight/2)}
  end

  local oIds = world.objectQuery(min, max, { callScript = "entity.configParameter", callScriptArgs = {"category"}, callScriptResult = "gardenfence" })
  if oIds[1] ~= nil then
     return false,world.entityPosition(oIds[1])
  end
  return ignoreLOS == true or not collision
end
--------------------------------------------------------------------------------
function distanceSort(a, b)
  local position = entity.position()
  local da = world.magnitude(position, world.entityPosition(a))
  local db = world.magnitude(position, world.entityPosition(b))
  return da < db
end

