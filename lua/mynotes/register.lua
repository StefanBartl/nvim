---@module 'mynotes.register'
--- Declarative registration of commands and keymaps for note collections.

local core = require("mynotes.core")

local M = {}

---@param name string
---@param spec MyNotesSpec
---@param commands MyNotesActions
---@param keys MyNotesKeys|nil
function M.register(name, spec, commands, keys)
  local function cwd()
    return core.resolve_cwd(spec)
  end

  vim.api.nvim_create_user_command(commands.files, function()
    local c = cwd()
    if not c then
      return
    end

    local fzf = core.try_fzf()
    if fzf then
      fzf.files({ cwd = c, prompt = spec.title .. " > " })
      return
    end

    local tel = core.try_telescope()
    if tel then
      tel.find_files({
        cwd = c,
        prompt_title = spec.title,
        hidden = true,
      })
    end
  end, { desc = name .. ": find files" })

  vim.api.nvim_create_user_command(commands.grep, function()
    if not core.has_rg() then
      vim.notify("[MyNotes] ripgrep not available", vim.log.levels.ERROR)
      return
    end

    local c = cwd()
    if not c then
      return
    end

    local fzf = core.try_fzf()
    if fzf then
      fzf.live_grep({ cwd = c, prompt = spec.title .. " > " })
      return
    end

    local tel = core.try_telescope()
    if tel then
      tel.live_grep({
        cwd = c,
        prompt_title = spec.title,
      })
    end
  end, { desc = name .. ": live grep" })

  if keys then
    if keys.files then
      vim.keymap.set("n", keys.files, function()
        vim.cmd(commands.files)
      end, { desc = name .. ": files" })
    end

    if keys.grep then
      vim.keymap.set("n", keys.grep, function()
        vim.cmd(commands.grep)
      end, { desc = name .. ": grep" })
    end
  end
end

return M
