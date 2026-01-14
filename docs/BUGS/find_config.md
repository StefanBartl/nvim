1. find config soll path separators unempfindlich sein
Das hat nicht funktionert:

```lua
--- Open fzf-lua file picker rooted at the config dir.
--- Accepts '/' as universal path separator on Windows by normalizing output paths.
---@param opts Custom.FindConfigOptions
---@return nil
local function Find_in_config(opts)
  ---@diagnostic disable-next-line: different-requires
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok or not fzf or type(fzf.files) ~= "function" then
    notify.error("fzf-lua not found or does not expose 'files' function")
    return
  end

  local cwd = get_nvim_config_dir()
  local is_windows = vim.fn.has("win32") == 1

  local default_fzf_opts = {
    ["-i"] = "",
  }

  local merged = vim.tbl_extend("force", {
    cwd = cwd,
    prompt = "Config Files❯ ",
    fzf_opts = default_fzf_opts,
    -- Force fd to use '/' on Windows
    cmd = is_windows and "fd --type f --path-separator /" or nil,
    -- Normalize file actions to handle both separators
    file_ignore_patterns = {},
    actions = {
      ["default"] = function(selected)
        if not selected or #selected == 0 then return end
        -- Normalize path before opening
        local file = selected[1]
        if is_windows then
          file = file:gsub("\\", "/")
        end
        vim.cmd("edit " .. vim.fn.fnameescape(file))
      end,
    },
  }, opts or {})

  if opts and opts.fzf_opts then
    merged.fzf_opts = vim.tbl_extend("force", default_fzf_opts, opts.fzf_opts)
  end

  local ok_call, err = pcall(function()
    fzf.files(merged)
  end)

  if not ok_call then
    notify.error("fzf-lua.files failed: " .. tostring(err))
  end
end
```

