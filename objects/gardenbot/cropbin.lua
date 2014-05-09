function init(virtual)
  if not virtual then
    self.inv = inventoryManager.create()
    self.inv.drop({all = true})
  end
end

function main()
  if self.inv and entity.id() then
    local qrt = math.floor(world.containerSize(entity.id()) / 4)
    local count = self.inv.emptyContainerSlots(entity.id())
    local state = nil
    if count == nil then count = 0 end
    if count <= qrt then
      state = "full"
    elseif count <= 2 * qrt then
      state = "lots"
    elseif count <= 3 * qrt then
      state = "little"
    else
      state = "empty"
    end
    if self.harvestState ~= state then
      self.harvestState = state
      entity.setAnimationState("harvestState", state)
    end
  end
end