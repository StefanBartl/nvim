---@module 'custom.pathfinder.extractor.terminators'

-- Characters that terminate a path when expanding left/right
---@type table<string,boolean>
return {
  [" "] = true,
  ["\t"] = true,
  ["("] = true,
  [")"] = true,
  ["<"] = true,
  [">"] = true,
  ['"'] = true,
  ["'"] = true,
  [","] = true,
  [";"] = true,
  ["|"] = true,
  ["`"] = true,
}
