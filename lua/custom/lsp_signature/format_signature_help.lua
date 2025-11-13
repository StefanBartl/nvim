---@module 'custom.lsp_signature.format_signature_help'
local split_lines = require("custom.lsp_signature.split_lines")

--- Format signatureHelp result into lines for floating window
--- Returns lines + optional highlight info for active parameter
---@param result table
return function(result)
  if not result then return nil end

  local sigs = result.signatures or (result.value and result.value.signatures)
  if not sigs or #sigs == 0 then return nil end

  local active = result.activeSignature
  if result.value and type(result.value.activeSignature) == "number" then
    active = result.value.activeSignature
  end
  local idx = (type(active) == "number") and (active + 1) or 1
  local sig = sigs[idx] or sigs[1]
  if not sig then return nil end

  local label = sig.label or ""
  local lines = split_lines(label)

  -- Compute active parameter highlight
  local hl = nil
  if sig.parameters and sig.activeParameter then
    local param = sig.parameters[sig.activeParameter + 1] -- 0-based
    if param and param.label then
      -- param.label can be string or [start, end]
      if type(param.label) == "table" and #param.label == 2 then
        hl = { line = 1, col_start = param.label[1] + 1, col_end = param.label[2] }
      elseif type(param.label) == "string" then
        local s, e = string.find(label, vim.pesc(param.label), 1, true)
        if s and e then
          hl = { line = 1, col_start = s, col_end = e }
        end
      end
    end
  end

  -- Append documentation if exists
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

  return lines, hl
end
