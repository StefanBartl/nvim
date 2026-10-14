---@module 'config.ui_statusline.acronyms_slot'
--- The text of the personal `expand` slot (ui.slots, kind `expand`): the
--- acronym notes of the WKDBook-Tricentis repo, shown as one foldable float.
---
--- Three files hold acronyms; all of them are shown, one after the other, each
--- under a header that names its source. A file that is not there (another
--- machine) is skipped and listed at the end; when none is there the function
--- raises a plain message, which the slot reports instead of opening an empty
--- float. The root is `$REPOS_DIR` (set per machine by setup-claude-code.ps1).

local M = {}

--- Files below `$REPOS_DIR/WKDBook-Tricentis`, in display order.
---@type string[]
M.sources = {
  "Terminologie/Tosca_Component_Akronyms.md",
  "MyDomains/Tosca/Cheetsheets/Tosca_Akronyms.md",
  "MyDomains/Tosca/Notes/SAP/Akronyms.md",
}

---@return string[] lines
function M.lines()
  local root = vim.env.REPOS_DIR
  if not root or root == "" then
    error("acronyms: $REPOS_DIR is not set", 0)
  end
  local base = vim.fs.joinpath(root, "WKDBook-Tricentis")
  local out, missing = {}, {}
  for _, rel in ipairs(M.sources) do
    local path = vim.fs.joinpath(base, rel)
    local ok, lines = pcall(vim.fn.readfile, path)
    if ok and #lines > 0 then
      if #out > 0 then
        vim.list_extend(out, { "", string.rep("─", 40), "" })
      end
      out[#out + 1] = "<< " .. rel .. " >>"
      out[#out + 1] = ""
      vim.list_extend(out, lines)
    else
      missing[#missing + 1] = rel
    end
  end
  if #out == 0 then
    error("acronyms: no file found under " .. base, 0)
  end
  if #missing > 0 then
    vim.list_extend(out, { "", "(not found here: " .. table.concat(missing, ", ") .. ")" })
  end
  return out
end

return M
