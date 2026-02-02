---@module 'config/menu/custom_menu.lua'
--- Returns the menu table for quick requires if desired
---
--- Enhanced with:
--- - Copy All (entire buffer)
--- - Copy/Delete marked or selected content
--- - Delete All/Buffer
--- - Delete File
--- - Unicode Table (floating window)

-- Default toggles for top-level entries
local notify = require("lib.notify").create("[config.menu.custom_menu]")

local defaults = {
  enable_format = true,
  enable_code_actions = true,
  enable_lsp_section = true,
  enable_git_section = true,
  enable_edit_config = true,
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

-- Merge helper
local function merge_table(dst, src)
  for k, v in pairs(src or {}) do
    dst[k] = v
  end
  return dst
end

---Check if text is selected in visual mode
---@return boolean
local function has_selection()
  local mode = vim.fn.mode()
  return mode == "v" or mode == "V" or mode == "\22" -- \22 is <C-v>
end

---Get selected text in visual mode
---@return string[]|nil lines
local function get_selected_text()
  if not has_selection() then
    return nil
  end

  -- Get visual selection marks
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")

  local start_line = start_pos[2]
  local end_line = end_pos[2]

  return vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
end

---Open Unicode Table in floating window
---@return nil
local function open_unicode_table()
  -- Check if unicode.vim is available
  local ok = pcall(vim.cmd, "UnicodeTable")

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
          -- Could set additional window options here
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

-- Build the final menu table
return function(opts)
  opts = merge_table(merge_table({}, defaults), opts or {})

  local ok_default, default_menu = pcall(require, "menus.default")
  if not ok_default then
    default_menu = {}
  end

  -- Load nested modules
  local ok_lsp, lsp_module = pcall(require, "menus.lsp")
  if not ok_lsp then
    vim.notify("[nvzone.menu.custom]: lsp_module not loaded. " .. lsp_module, 2)
  end
  local ok_gs, gitsigns_module = pcall(require, "menus.gitsigns")
  if not ok_gs then
    vim.notify("[nvzone.menu.custom]: gitsigns_module not loaded. " .. gitsigns_module, 2)
  end

  local menu = {}

  -- Helper to shallow-copy list-like table
  local function append_list(dst, src)
    for _, v in ipairs(src or {}) do
      table.insert(dst, v)
    end
  end

  append_list(menu, default_menu)

  local composed = {}

  -- Format Buffer
  if opts.enable_format then
    table.insert(composed, {
      name = "Format Buffer",
      cmd = function()
        local ok, conform = pcall(require, "conform")
        if ok then
          conform.format({ lsp_fallback = true })
        else
          pcall(vim.lsp.buf.format)
        end
      end,
      rtxt = "<leader>fm",
    })
  end

  if opts.enable_code_actions then
    table.insert(composed, {
      name = "Code Actions",
      cmd = vim.lsp.buf.code_action,
      rtxt = "<leader>ca",
    })
  end

  table.insert(composed, { name = "separator" })

  if opts.enable_lsp_section then
    table.insert(composed, {
      name = "  Lsp Actions",
      hl = "Exblue",
      items = ok_lsp and "lsp" or "lsp",
    })

    table.insert(composed, { name = "separator" })
  end

  -- ============================================================================
  -- Copy
  -- ============================================================================

  if opts.enab_copy_all then
    table.insert(composed, {
      name = "Copy All (Buffer)",
      cmd = "%y+",
      rtxt = "<C-a>",
    })
  end

  if opts.enable_copy_marked then
    table.insert(composed, {
      name = "Copy Marked/Selected",
      cmd = function()
        local lines = get_selected_text()
        if lines then
          -- Copy visual selection
          vim.cmd("normal! gvy")
          notify.info("Copied selection to clipboard")
        else
          -- Copy entire buffer as fallback
          vim.cmd("%y+")
          notify.info("Copied entire buffer to clipboard")
        end
      end,
      rtxt = "<C-c>",
    })
  end

  if opts.enable_paste then
    table.insert(composed, {
      name = "Paste Content",
      cmd = function()
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
      end,
      rtxt = "<C-v>",
    })
  end

  table.insert(composed, { name = "separator" })

  -- ============================================================================
  -- Delete Operations
  -- ============================================================================

  if opts.enable_delete_marked then
    table.insert(composed, {
      name = "Delete Marked/Selected",
      cmd = function()
        if has_selection() then
          -- Delete visual selection
          vim.cmd("normal! gvd")
          notify.info("Deleted selection")
        else
          notify.warn("No selection to delete")
        end
      end,
      rtxt = "dm",
    })
  end

  if opts.enable_delete_all then
    table.insert(composed, {
      name = "Delete All (Clear Buffer)",
      cmd = function()
        local choice = vim.fn.confirm(
          "Delete all content in buffer?",
          "&Yes\n&No",
          2
        )
        if choice == 1 then
          vim.cmd("%d")
          notify.info("Buffer cleared")
        end
      end,
      rtxt = "da",
    })
  end

  if opts.enable_delete_file then
    table.insert(composed, {
      name = "🗑️  Delete File",
      cmd = function()
        local filepath = vim.api.nvim_buf_get_name(0)
        if filepath == "" then
          notify.warn("Buffer has no associated file")
          return
        end

        local filename = vim.fn.fnamemodify(filepath, ":t")
        local choice = vim.fn.confirm(
          string.format('Delete file "%s"?', filename),
          "&Yes\n&No",
          2
        )

        if choice == 1 then
          local ok, err = pcall(vim.fn.delete, filepath)
          if ok and err == 0 then
            vim.cmd("bdelete!")
            notify.info("File deleted: " .. filename)
          else
            notify.error("Failed to delete file: " .. tostring(err))
          end
        end
      end,
      rtxt = "df",
    })
  end

  table.insert(composed, { name = "separator" })

  -- ============================================================================
  -- Tools
  -- ============================================================================

  if opts.enable_open_terminal then
    table.insert(composed, {
      name = "  Open in terminal",
      hl = "ExRed",
      cmd = function()
        local state_ok, state = pcall(require, "menu.state")
        local old_buf = (state_ok and state.old_data and state.old_data.buf) and state.old_data.buf
          or vim.api.nvim_get_current_buf()
        local old_bufname = vim.api.nvim_buf_get_name(old_buf)
        local old_buf_dir = vim.fn.fnamemodify(old_bufname ~= "" and old_bufname or vim.loop.cwd() or "./", ":h")

        local thecmd = "cd " .. old_buf_dir

        if vim.g.base46_cache then
          local ok_term, nvterm = pcall(require, "nvchad.term")
          if ok_term and nvterm and nvterm.new then
            nvterm.new({ cmd = thecmd, pos = "sp" })
            return
          end
        end

        vim.cmd("enew")
        vim.fn.jobstart({ vim.o.shell, vim.o.shellcmdflag, thecmd .. " ; " .. vim.o.shell }, { term = true })
      end,
    })
  end

  if opts.enable_color_picker then
    table.insert(composed, {
      name = "  Color Picker",
      cmd = function()
        local ok, huefy = pcall(require, "minty.huefy")
        if ok and huefy and huefy.open then
          pcall(huefy.open)
        end
      end,
    })
  end

  if opts.enable_unicode_table then
    table.insert(composed, {
      name = "  Unicode Table",
      hl = "ExCyan",
      cmd = open_unicode_table,
      rtxt = "uni",
    })
  end

  -- Git section
  if opts.enable_git_section and ok_gs then
    table.insert(composed, { name = "separator" })
    table.insert(composed, {
      name = "  Git Actions",
      hl = "ExGreen",
      items = ok_gs and "gitsigns" or "gitsigns",
    })
  end

  return composed
end
