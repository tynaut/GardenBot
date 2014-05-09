
if init == nil then
  function init(virtual)
    if not virtual then
      local growing = entity.configParameter("growing")
      if storage.growth == nil then storage.growth = 0 end
      storage.startTime = world.time()
      storage.duration = 0
      if growing ~= nil then
        for _,v in pairs(growing) do
          storage.duration = storage.duration + math.floor(math.random(v.duration[1],v.duration[2]))
        end
      end
    else
      storage.growth = 0
      storage.duration = 0
    end
  end
  
  function main()
   local growth = storage.growth
   local currentTime = world.time()
   local d = currentTime - storage.startTime
   if d > 0 then
     storage.growth = growth + d
     storage.startTime = currentTime
   end
  end

  function doHarvest()
    local interactions = entity.configParameter("interactionTransition")
    for _,v in pairs(interactions) do
      local drops = v.dropOptions
      if drops then
        local i = 2
        local odds = drops[1]
        while drops[i] do
          if drops[i+1] == nil or math.random() < odds then
            local j = 1
            while drops[i][j] do
              world.spawnItem(drops[i][j].name, entity.toAbsolutePosition({ 0.0, 1.0 }), drops[i][j].count)
              j = j + 1
            end
            break
          end
          i = i + 1
        end
	    break
      end
    end
    storage.startTime = 0
    storage.growth = 0
    entity["break"]()
  end

  function canHarvest()
    if storage.growth > storage.duration then
      return true
    end
    return false
  end
end