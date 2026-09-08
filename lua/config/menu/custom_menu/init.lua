---@module 'config.menu.custom_menu'
--- The general (non-plugin) section of the right-click menu: format, copy,
--- paste, delete, and a few tools. Built with `lib.nvim.contextmenu`'s
--- `entry`/`group` builders, so every entry is gated where it is written and
--- the separators fall out of the grouping instead of being placed by hand.
---
--- Returns a function: `require("config.menu.custom_menu")(opts)` yields the
--- item list for the *current* buffer/mode, so entries that depend on state
--- (a visual selection, a named file) are resolved at open time, not once at
--- setup.

local notify = require("lib.nvim.notify").create("[config.menu.custom_menu]")
local contextmenu = require("lib.nvim.contextmenu")
local kit = require("lib.nvim.ui.kit")

local defaults = {
  enable_format = true,
  enable_code_actions = true,
  enable_git_section = true,
  enable_copy_all = true,
  enable_copy_marked = true,
  enable_paste = true,
  enable_delete_marked = true,
  enable_delete_all = true,
  enable_delete_file = true,
  enable_open_terminal = true,
  enable_color_picker = true,
  enable_unicode_table = true,
}

---@param dst table
---@param src table|nil
local function merge_table(dst, src)
  for k, v in pairs(src or {}) do
    dst[k] = v
  end
  return dst
end

---Tag an entry with a highlight group, passing a gated-off `nil` through so
---this can wrap an `entry(...)` call inline.
---@param item Lib.ContextMenu.Item|nil
---@param hl string
---@return Lib.ContextMenu.Item|nil
local function colored(item, hl)
  if item then
    item.hl = hl
  end
  return item
end

---Check if text is selected in visual mode
---@return boolean
local function has_selection()
  local mode = vim.fn.mode()
  return mode == "v" or mode == "V" or mode == "\22" -- \22 is <C-v>
end

---Open Unicode Table in floating window
---@return nil
local function open_unicode_table()
  -- Check if unicode.vim is available
  local ok = pcall(function()
    vim.cmd("UnicodeTable")
  end)

  if not ok then
    notify.warn("unicode.vim plugin not available")
    return
  end

  -- The plugin opens its own window
  vim.schedule(function()
    -- Get the unicode table buffer
    local bufs = vim.api.nvim_list_bufs()
    for _, buf in ipairs(bufs) do
      if vim.bo[buf].filetype == "unicode" then
        -- Customize window if needed
        local win = vim.fn.bufwinid(buf)
        if win ~= -1 then
          vim.api.nvim_win_set_config(win, {
            border = "rounded",
            title = " Unicode Table ",
            title_pos = "center",
          })
        end
        break
      end
    end
  end)
end

---Format the buffer through conform.nvim, or the LSP when it isn't installed.
---@return nil
local function format_buffer()
  local ok, conform = pcall(require, "conform")
  if ok then
    conform.format({ lsp_fallback = true })
  else
    pcall(vim.lsp.buf.format)
  end
end

---Copy the visual selection, or the whole buffer when nothing is selected.
---@return nil
local function copy_marked()
  if has_selection() then
    vim.cmd("normal! gvy")
    notify.info("Copied selection to clipboard")
  else
    vim.cmd("%y+")
    notify.info("Copied entire buffer to clipboard")
  end
end

---Put the system clipboard's content below the cursor, linewise.
---@return nil
local function paste_clipboard()
  local ok, text = pcall(vim.fn.getreg, "+")
  if not ok or not text or text == "" then
    notify.info("System clipboard is empty")
    return
  end

  if type(text) ~= "string" then
    return
  end

  local lines = vim.split(text, "\n", { plain = true })
  vim.api.nvim_put(lines, "l", true, true)
end

---Delete the visual selection (no-op with a warning when there is none).
---@return nil
local function delete_marked()
  if has_selection() then
    vim.cmd("normal! gvd")
    notify.info("Deleted selection")
  else
    notify.warn("No selection to delete")
  end
end

---Clear the buffer, after a confirm.
---@return nil
local function delete_all()
  kit.confirm({
    question = "Delete all content in buffer?",
    on_answer = function(yes)
      if yes then
        vim.cmd("%d")
        notify.info("Buffer cleared")
      end
    end,
  })
end

---Delete the file behind the current buffer, after a confirm.
---@return nil
local function delete_file()
  local filepath = vim.api.nvim_buf_get_name(0)
  if filepath == "" then
    notify.warn("Buffer has no associated file")
    return
  end

  local filename = vim.fn.fnamemodify(filepath, ":t")
  kit.confirm({
    question = string.format('Delete file "%s"?', filename),
    on_answer = function(yes)
      if not yes then
        return
      end
      local ok, err = pcall(vim.fn.delete, filepath)
      if ok and err == 0 then
        vim.cmd("bdelete!")
        notify.info("File deleted: " .. filename)
      else
        notify.error("Failed to delete file: " .. tostring(err))
      end
    end,
  })
end

---Open a terminal in the current file's directory.
---
--- The buffer is read directly rather than through nvzone/menu's
--- `menu.state.old_data` (which recorded the buffer the menu was opened
--- from): the menu is built for a buffer that is still current at open
--- time, so there is nothing to restore.
---@return nil
local function open_terminal()
  local bufname = vim.api.nvim_buf_get_name(0)
  local dir = vim.fn.fnamemodify(bufname ~= "" and bufname or vim.uv.cwd() or "./", ":h")
  local thecmd = "cd " .. dir

  if vim.g.base46_cache then
    local ok_term, nvterm = pcall(require, "nvchad.term")
    if ok_term and nvterm and nvterm.new then
      nvterm.new({ cmd = thecmd, pos = "sp" })
      return
    end
  end

  vim.cmd("enew")
  vim.fn.jobstart({ vim.o.shell, vim.o.shellcmdflag, thecmd .. " ; " .. vim.o.shell }, {
    term = true,
  })
end

---Open minty's colour picker, when minty is installed.
---@return nil
local function open_color_picker()
  local ok, huefy = pcall(require, "minty.huefy")
  if ok and huefy and huefy.open then
    pcall(huefy.open)
  end
end

--- Build the general menu section for the current buffer.
---@param opts table|nil
---@return Lib.ContextMenu.Item[]
return function(opts)
  opts = merge_table(merge_table({}, defaults), opts or {})

  local out = {}

  contextmenu.group(
    out,
    contextmenu.entry(opts.enable_format, "Format Buffer", format_buffer, "<leader>fm"),
    contextmenu.entry(
      opts.enable_code_actions,
      "Code Actions",
      vim.lsp.buf.code_action,
      "<leader>ca"
    )
  )

  contextmenu.group(
    out,
    contextmenu.entry(opts.enable_copy_all, "Copy All (Buffer)", function()
      vim.cmd("%y+")
    end, "<C-a>"),
    contextmenu.entry(opts.enable_copy_marked, "Copy Marked/Selected", copy_marked, "<C-c>"),
    contextmenu.entry(opts.enable_paste, "Paste Content", paste_clipboard, "<C-v>")
  )

  contextmenu.group(
    out,
    contextmenu.entry(opts.enable_delete_marked, "Delete Marked/Selected", delete_marked, "dm"),
    contextmenu.entry(opts.enable_delete_all, "Delete All (Clear Buffer)", delete_all, "da"),
    contextmenu.entry(opts.enable_delete_file, "  Delete File", delete_file, "df")
  )

  contextmenu.group(
    out,
    colored(
      contextmenu.entry(opts.enable_open_terminal, "  Open in terminal", open_terminal),
      "ExRed"
    ),
    contextmenu.entry(opts.enable_color_picker, "󰏘  Color Picker", open_color_picker),
    colored(
      contextmenu.entry(opts.enable_unicode_table, "  Unicode Table", open_unicode_table, "uni"),
      "ExCyan"
    )
  )

  -- Git: our own item list (config.menu.git), not nvzone/menu's
  -- `menus.gitsigns` -- the section has to survive nvzone/menu being
  -- uninstalled, which was the whole point of the renderer swap.
  if opts.enable_git_section then
    local git = require("config.menu.git").items()
    contextmenu.group(out, colored(contextmenu.submenu("󰊢  Git Actions", git), "ExGreen"))
  end

  return out
end
