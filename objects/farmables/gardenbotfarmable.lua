
if init == nil then
    function init(virtual)
        if not virtual then
            storage.startTime = world.time()
            if storage.stage == nil then advance() end
        else
            storage.stage = nil
            storage.growth = nil
            storage.duration = nil
        end
    end
  
    function main()
        if storage.duration ~= nil then
            storage.growth = storage.growth + entity.dt()
            if storage.growth > storage.duration then
                advance()
            end
        end
    end
    
    function advance()
        local growing = entity.configParameter("growing")
        local alts = entity.configParameter("stageAlts")
        local stage = storage.stage
        local alt = "0"
        storage.growth = 0
        if stage == nil then
            stage = "0"
        else
            if growing[stage] and growing[stage].success then
                stage = tostring(growing[stage].success)
            end
        end

        if alts and type(alts[stage]) == "number" then
            alt = tostring(math.random(0, alts[stage]))
        end

        if growing[stage] and growing[stage].duration then
            storage.duration = math.random(growing[stage].duration[1],growing[stage].duration[2])
        else
            storage.duration = nil
        end

        storage.stage = stage
        if entity.configParameter("animation") then
            entity.setAnimationState("growingState", stage)
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
        entity["break"]()
    end

    function canHarvest()
        local interactions = entity.configParameter("interactionTransition")
        if interactions[storage.stage] ~= nil then
            return true
        end
        return false
    end
end