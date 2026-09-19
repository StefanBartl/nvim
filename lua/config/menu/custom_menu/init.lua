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
local icons = require("config.menu.icons")

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
  enable_inspect = true,
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

---Show the treesitter/syntax highlight groups under the cursor (`:h :Inspect`).
---@return nil
local function inspect_here()
  -- Wrapped rather than `pcall(vim.cmd, "Inspect")`: `vim.cmd` is a callable
  -- *table*, not a function. It works at runtime, but `pcall`'s first
  -- parameter is typed as a function, so LuaLS reports a
  -- `param-type-mismatch` here -- ERR-62 calls out this exact case. A closure
  -- makes runtime and type checker agree.
  pcall(function()
    vim.cmd("Inspect")
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
  local cwd = vim.uv.cwd() or "."
  -- Only a named buffer has a directory to derive; for an unnamed one the
  -- answer is the working directory itself, not its parent (`:h` of a
  -- directory climbs one level, which is never what "open a terminal here"
  -- means).
  local dir = bufname ~= "" and vim.fn.fnamemodify(bufname, ":h") or cwd
  if vim.fn.isdirectory(dir) == 0 then
    dir = cwd
  end

  vim.cmd("enew")
  -- `cwd` rather than a `cd <dir> ; $SHELL` string handed to the shell: the
  -- directory comes from a buffer name, and a path is allowed to contain
  -- shell metacharacters. Interpolated, a buffer named `a;rm -rf ~/x` runs
  -- that command the moment the terminal opens -- the `cd` does not even
  -- have to succeed for the part after the `;` to execute.
  --
  -- `vim.o.shell` is passed as a string, not as a one-element argv list:
  -- 'shell' may carry its own quoting (on Windows it defaults to
  -- `"C:\Program Files\Git\bin\bash.exe"`, quotes included), and an argv
  -- element is a literal filename -- the quotes become part of the name and
  -- the spawn fails with E475. Only the shell option itself goes into that
  -- string; nothing derived from the buffer does.
  --
  -- Guarded: `jobstart` *raises* on a cwd it cannot use (E475), and the
  -- `isdirectory` check above cannot close that window -- the directory can
  -- go away between the two. Without the guard that error escapes a menu
  -- callback, and the buffer `enew` just made is left behind empty. Every
  -- other failure in this module reports through `notify`.
  local ok, job = pcall(vim.fn.jobstart, vim.o.shell, {
    term = true,
    cwd = dir,
  })
  if not ok or type(job) ~= "number" or job <= 0 then
    -- `bwipeout`, not `bdelete`: the latter only unlists the buffer, leaving
    -- the empty one behind for the rest of the session. Verified that this
    -- restores both the buffer count and the window's previous file.
    -- Same `vim.cmd`-is-a-callable-table point as `inspect_here` above
    -- (ERR-62): wrapped, not passed to `pcall` directly.
    pcall(function()
      vim.cmd("bwipeout!")
    end)
    notify.error("could not open a terminal in " .. dir .. ": " .. tostring(job))
  end
end

---Open ui.nvim's colour picker (`ui.colorpicker`, the in-house replacement
---for minty's Huefy since 2026-09-19): it opens on the `#hex` under the
---cursor and writes the pick back over it on `<CR>`.
---@return nil
local function open_color_picker()
  local ok, picker = pcall(require, "ui.colorpicker")
  if ok and picker and picker.open then
    pcall(picker.open)
  end
end

--- Build the general menu section for the current buffer.
---@param opts table|nil
---@return Lib.ContextMenu.Item[]
return function(opts)
  opts = merge_table(merge_table({}, defaults), opts or {})

  local out = {}

  -- Each group names itself. The title is a `heading(...)` marker passed as
  -- the group's first argument rather than a parameter of its own, so gating
  -- reaches it: a section whose every entry is switched off in `opts` takes
  -- its title down with it instead of leaving a heading over nothing.
  --
  -- No glyph is baked into a label any more. `icon` is a field, and the kit
  -- renderer measures it into a column of its own -- which is what keeps
  -- these entries aligned with the plugin fly-outs above them, whether or not
  -- a given entry has a glyph.
  contextmenu.group(
    out,
    contextmenu.heading("Code"),
    contextmenu.entry(opts.enable_format, "Format Buffer", format_buffer, "<leader>fm", {
      icon = icons.format,
    }),
    contextmenu.entry(
      opts.enable_code_actions,
      "Code Actions",
      vim.lsp.buf.code_action,
      "<leader>ca",
      { icon = icons.code_action }
    ),
    contextmenu.entry(opts.enable_inspect, "Inspect", inspect_here, nil, {
      icon = icons.inspect,
    })
  )

  contextmenu.group(
    out,
    contextmenu.heading("Clipboard"),
    contextmenu.entry(opts.enable_copy_all, "Copy All (Buffer)", function()
      vim.cmd("%y+")
    end, "<C-a>", { icon = icons.copy_all }),
    contextmenu.entry(
      opts.enable_copy_marked,
      "Copy Marked/Selected",
      copy_marked,
      "<C-c>",
      { icon = icons.copy_marked }
    ),
    contextmenu.entry(
      opts.enable_paste,
      "Paste Content",
      paste_clipboard,
      "<C-v>",
      { icon = icons.paste }
    )
  )

  contextmenu.group(
    out,
    contextmenu.heading("Delete"),
    contextmenu.entry(
      opts.enable_delete_marked,
      "Delete Marked/Selected",
      delete_marked,
      "dm",
      { icon = icons.delete_marked }
    ),
    contextmenu.entry(
      opts.enable_delete_all,
      "Delete All (Clear Buffer)",
      delete_all,
      "da",
      { icon = icons.delete_all }
    ),
    -- The only entry that destroys something outside the buffer, and the only
    -- icon coloured against its section rather than with it.
    contextmenu.entry(opts.enable_delete_file, "Delete File", delete_file, "df", {
      icon = icons.delete_file,
      icon_hl = "DiagnosticError",
    })
  )

  -- Git sits in this group rather than in one of its own: a named section
  -- holding a single entry is a frame around one row, which reads as a fault
  -- rather than as structure.
  --
  -- Its item list is ours (config.menu.git), not nvzone/menu's
  -- `menus.gitsigns` -- the section has to survive nvzone/menu being
  -- uninstalled, which was the whole point of the renderer swap.
  local git = opts.enable_git_section and require("config.menu.git").items() or {}

  contextmenu.group(
    out,
    contextmenu.heading("Tools"),
    colored(
      contextmenu.entry(
        opts.enable_open_terminal,
        "Open in terminal",
        open_terminal,
        nil,
        { icon = icons.terminal }
      ),
      "ExRed"
    ),
    contextmenu.entry(
      opts.enable_color_picker,
      "Color Picker",
      open_color_picker,
      nil,
      { icon = icons.color_picker }
    ),
    colored(
      contextmenu.entry(
        opts.enable_unicode_table,
        "Unicode Table",
        open_unicode_table,
        "uni",
        { icon = icons.unicode_table }
      ),
      "ExCyan"
    ),
    colored(contextmenu.submenu("Git Actions", git, { icon = icons.git }), "ExGreen")
  )

  return out
end
