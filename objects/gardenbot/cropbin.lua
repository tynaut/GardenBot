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
    if count == nil then count = 0 end
    if count <= qrt then
      entity.setAnimationState("harvestState", "full")
    elseif count <= 2 * qrt then
      entity.setAnimationState("harvestState", "lots")
    elseif count <= 3 * qrt then
      entity.setAnimationState("harvestState", "little")
    else
      entity.setAnimationState("harvestState", "empty")
    end
  end
end