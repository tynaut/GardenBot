--------------------------------------------------------------------------------
idleState = {}
--------------------------------------------------------------------------------
function idleState.enterWith(args)
  entity.setAnimationState("movement", "idle")
  if not self.state.pickState() then
    self.state.pickState({ ignoreDistance = true })
  end
  return nil,entity.configParameter("gardenSettings.cooldown", 15)
end
--------------------------------------------------------------------------------