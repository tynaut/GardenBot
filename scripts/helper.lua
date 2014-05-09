helper = {}

function helper.log(args, indent)
  if type(indent) ~= "number" then indent = 1 end
  
  local t = helper.indent(indent)

  if args == nil then
    world.logInfo(t .. "nil")
  elseif type(args) == "boolean" then
    if args then world.logInfo(t .. "TRUE") else world.logInfo(t .. "FALSE") end
  elseif type(args) == "string" or type(args) == "number" then
    world.logInfo(t .. args)
  elseif type(args) == "table" then
    for i,v in pairs(args) do
      world.logInfo(t .. i .. "(" .. type(v) .. ")")
      helper.log(v, indent + 1)
    end
  end
end

function helper.indent(t)
  local indent = "#"
  local result = ""
  if type(t) == "number" and t > 0 then
    for i = 0,t,1 do
      result = result .. indent
    end
  end
  return result
end