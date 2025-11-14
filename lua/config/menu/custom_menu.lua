---@module 'config/menu/custom_menu.lua'
-- Returns the menu table for quick requires if desired

-- Default toggles for top-level entries; consumers can override by passing opts to setup()
local defaults = {
  enable_format = true,
  enable_code_actions = true,
  enable_lsp_section = true,
  enable_git_section = true,
  enable_edit_config = true,
  enable_copy = true,
  enable_paste = true,
  enable_delete = true,
  enable_open_terminal = true,
  enable_color_picker = true,
}

-- Merge helper
local function merge_table(dst, src)
  for k, v in pairs(src or {}) do
    dst[k] = v
  end
  return dst
end

-- Build the final menu table by composing the default menu and optional nested menus.
-- This returns a menu table compatible with the menu system used in your config (i.e. it
-- returns the content that would normally live in menus/<name>.lua).
return function(opts)
  opts = merge_table(merge_table({}, defaults), opts or {})

  local ok_default, default_menu = pcall(require, "menus.default")
  if not ok_default then
    -- Fallback minimal skeleton if menus.default is missing
    default_menu = {}
  end

  -- Load nested modules if available; if not available we'll still reference their name
  local ok_lsp, lsp_module = pcall(require, "menus.lsp")
  if not ok_lsp then
    vim.notify("[nvzone.menu.custom]: lsp_mopdule not loaded. " .. lsp_module, 2)
  end
  local ok_gs, gitsigns_module = pcall(require, "menus.gitsigns")
  if not ok_gs then
    vim.notify("[nvzone.menu.custom]: gitsigns_mopdule not loaded. " .. gitsigns_module, 2)
  end

  -- Compose new entries (we will clone default_menu and then patch)
  local menu = {}

  -- Helper to shallow-copy list-like table
  local function append_list(dst, src)
    for _, v in ipairs(src or {}) do
      table.insert(dst, v)
    end
  end

  -- Start from default_menu contents where present
  append_list(menu, default_menu)

  -- We'll now adjust menu: ensure LSP section, Git nested entry, and Paste entry exist per toggles.

  local composed = {}

  -- Format Buffer (if enabled)
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
    -- if lsp_menu exists we reference it by string to let menu system load it like other ones
    table.insert(composed, {
      name = "  Lsp Actions",
      hl = "Exblue",
      items = ok_lsp and "lsp" or "lsp",
    })

    table.insert(composed, { name = "separator" })
  end

  if opts.enable_edit_config then
    table.insert(composed, {
      name = "Edit Config",
      cmd = function()
        vim.cmd("tabnew")
        local conf = vim.fn.stdpath("config")
        vim.cmd("tcd " .. conf .. " | e init.lua")
      end,
      rtxt = "ed",
    })
  end

  if opts.enable_copy then
    table.insert(composed, {
      name = "Copy Content",
      cmd = "%y+",
      rtxt = "<C-c>",
    })
  end

  if opts.enable_paste then
    table.insert(composed, {
      name = "Paste Content",
      cmd = function()
        local ok, text = pcall(vim.fn.getreg, "+")
        if not ok or not text or text == "" then
          vim.notify("System clipboard is empty", vim.log.levels.INFO)
          return
        end

        if type(text) ~= "string" then
          return
        end
        -- Insert at cursor position preserving as much context as possible
        local lines = vim.split(text, "\n", { plain = true })
        -- nvim_put arguments: lines, type, after, follow
        vim.api.nvim_put(lines, "l", true, true)
      end,
      rtxt = "<C-v>",
    })
  end

  if opts.enable_delete then
    table.insert(composed, {
      name = "Delete Content",
      cmd = "%d",
      rtxt = "dc",
    })
  end

  table.insert(composed, { name = "separator" })

  if opts.enable_open_terminal then
    table.insert(composed, {
      name = "  Open in terminal",
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
        vim.fn.jobstart(
          { vim.o.shell, vim.o.shellcmdflag, thecmd .. " ; " .. vim.o.shell },
          { term = true }
        )
      end,
    })
  end

  table.insert(composed, { name = "separator" })

  if opts.enable_color_picker then
    table.insert(composed, {
      name = "  Color Picker",
      cmd = function()
        local ok, huefy = pcall(require, "minty.huefy")
        if ok and huefy and huefy.open then
          pcall(huefy.open)
        end
      end,
    })
  end

  -- Add Git nested section if requested
  if opts.enable_git_section and ok_gs then
    table.insert(composed, { name = "separator" })
    table.insert(composed, {
      name = "  Git Actions",
      hl = "ExGreen",
      items = ok_gs and "gitsigns" or "gitsigns",
    })
  end

  -- Return the composed menu structure
  return composed
end
