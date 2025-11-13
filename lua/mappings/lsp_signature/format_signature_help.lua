---@module 'mappings.lsp_signature.format_signature_help'

local split_lines = require("mappings.lsp_signature.split_lines")

--- Format signatureHelp result to lines for popup.
---@param result table
---@return string[]|nil
return function (result)
  if not result then return nil end
  local sigs = result.signatures or (result.value and result.value.signatures)
  if not sigs or #sigs == 0 then return nil end

  local active = nil
  if type(result.activeSignature) == "number" then
    active = result.activeSignature
  elseif result.value and type(result.value.activeSignature) == "number" then
    active = result.value.activeSignature
  end

  local idx = 1
  if type(active) == "number" then
    idx = math.max(1, active + 1) -- convert 0-based to 1-based when necessary
  end

  local sig = sigs[idx] or sigs[1]
  if not sig then return nil end

  local label = sig.label or ""
  ---@type string[]
  local lines = split_lines(label)

  if sig.documentation then
    local doc_text = ""
    if type(sig.documentation) == "string" then
      doc_text = sig.documentation
    elseif type(sig.documentation) == "table" and sig.documentation.value then
      doc_text = sig.documentation.value
    end
    if doc_text ~= "" then
      table.insert(lines, "")
      for _, ln in ipairs(split_lines(doc_text)) do
        table.insert(lines, ln)
      end
    end
  end

  return lines
end
