---@module 'custom.markdown.ui.keymaps'
--- Buffer-local Markdown keymaps (fold, headings, wrap, toc).
--- Safe, idempotent, and config-gated.

local M = {}

-- Fast locals
local api = vim.api

-- --- Small helpers -----------------------------------------------------------

---@param base table|nil
---@param extra table|nil
---@return table
local function with(base, extra)
  if not extra then return base or {} end
  if not base then
    -- avoid mutating caller's table
    local out = {}
    for k, v in pairs(extra) do out[k] = v end
    return out
  end
  for k, v in pairs(extra) do base[k] = v end
  return base
end

---@param modes string|string[]
---@param lhs string
---@param rhs function|string
---@param desc string
---@param opts table|nil
local function map(modes, lhs, rhs, desc, opts)
  local o = { noremap = true, silent = true, desc = desc }
  if opts then o = with(o, opts) end
  vim.keymap.set(modes, lhs, rhs, o)
end

---@param bufnr integer|nil
---@return boolean
local function is_markdown_buf(bufnr)
  bufnr = bufnr or api.nvim_get_current_buf()
  if not (api.nvim_buf_is_loaded(bufnr) and api.nvim_buf_is_valid(bufnr)) then
    return false
  end
  return (vim.bo[bufnr].filetype == "markdown")
end

-- --- Keymap installer --------------------------------------------------------

---@param bufnr integer|nil
local function apply_keymaps(bufnr)
  -- Resolve config once
  local cfg_get = require("custom.markdown.config").get
  local cfg = cfg_get()

  -- Optional feature gates (keep behavior stable if keys are absent)
  local enable_double_asterisk = (cfg.map_double_asterisk ~= false)
  local use_zf_override        = (cfg.use_zf_override == true)

  -- Load submodules defensively (no hard crash if optional parts are missing)
  local ok_fold,      fold      = pcall(require, "custom.markdown.core.fold")
  local ok_prev,      fold_prev = pcall(require, "custom.markdown.core.fold_prev")
  local ok_lvls,      fold_lvls = pcall(require, "custom.markdown.core.fold_levels")
  local ok_head,      headings  = pcall(require, "custom.markdown.core.headings")
  local ok_wrap,      wrap      = pcall(require, "custom.markdown.core.wrap")
  local ok_toc,       toc       = pcall(require, "custom.markdown.core.toc")

  -- Buffer-targeted options (nil => global maps, else buffer-local)
  local o = bufnr and { buffer = bufnr } or nil

  -- Guard: only map in Markdown buffers when buffer-local requested
  if o and not is_markdown_buf(bufnr) then
    return
  end

  -- Wrap (Visual **toggle) ----------------------------------------------------
  if enable_double_asterisk and ok_wrap and wrap.toggle_visual_bold then
    map("x", "**", wrap.toggle_visual_bold, "[Markdown] Toggle ** around selection", o)
  end

  -- Headings navigation -------------------------------------------------------
  if ok_head then
    if headings.goto_prev_heading then
      map({ "n", "v", "x" }, "mk", headings.goto_prev_heading, "[Markdown] Previous heading (H2+)", o)
    end
    if headings.goto_next_heading then
      map({ "n", "v", "x" }, "mj", headings.goto_next_heading, "[Markdown] Next heading (H2+)", o)
    end
  end

  -- Folding controls ----------------------------------------------------------
  if ok_fold then
    map("n", "<localleader>f", fold.toggle_under_cursor,
      "[Markdown] Toggle fold under cursor & center", o)

    if use_zf_override then
      -- keep 'nowait' here to avoid zf waiting for a motion
      map("n", "zf", fold.toggle_under_cursor,
        "[Markdown] Toggle fold under cursor & center (override)", with(o and { buffer = o.buffer } or {}, { nowait = true }))
    end

    map("n", "zu", fold.unfold_all_center, "[Markdown] Unfold all & center", o)
  end

  if ok_prev and fold_prev.fold_prev_heading_then_center then
    map("n", "zi", fold_prev.fold_prev_heading_then_center, "[Markdown] Fold previous heading & center", o)
  end

  if ok_lvls and fold_lvls.fold_levels then
    map("n", "zk", function() fold_lvls.fold_levels({ 2, 3, 4, 5, 6 }) end,
      "[Markdown] Fold H2+ (keep H1 open)", o)
  end

  -- TOC (insert/refresh) ------------------------------------------------------
  if ok_toc and toc.update_markdown_toc then
    map("n", "<leader>toc", function()
      toc.update_markdown_toc("## Table of content")
    end, "[Markdown] Insert/Refresh TOC", o)
  end

  -- Headings level shift ------------------------------------------------------
  if ok_head and headings.increase and headings.decrease then
    local opts = with({ silent = true, noremap = true, nowait = true }, o)

    -- Line / Visual
    map({ "n", "v", "x" }, "<leader>mhI", headings.increase,
      "[Markdown] Increase heading level(s) (line/selection, H2+)", opts)
    map({ "n", "v", "x" }, "<leader>mhD", headings.decrease,
      "[Markdown] Decrease heading level(s) (line/selection, H2+)", opts)

    -- Operator-pending (usage: <leader>mhi{motion}, <leader>mhd{motion})
    if headings._op_increase and headings._op_decrease then
      map("n", "<leader>mhi", function()
        vim.go.operatorfunc = "v:lua.require'custom.markdown.core.headings'._op_increase"
        return "g@"
      end, "[Markdown] Increase headings (operator-pending)", with({ expr = true }, opts))

      map("n", "<leader>mhd", function()
        vim.go.operatorfunc = "v:lua.require'custom.markdown.core.headings'._op_decrease"
        return "g@"
      end, "[Markdown] Decrease headings (operator-pending)", with({ expr = true }, opts))
    end

    -- Whole-buffer helpers
    if headings.shift_range then
      local function whole_buf_lines()
        local b = bufnr or api.nvim_get_current_buf()
        return 1, api.nvim_buf_line_count(b)
      end

      map("n", "<leader>mhIA", function()
        local s, e = whole_buf_lines()
        headings.shift_range(s, e, 1)
      end, "[Markdown] Increase ALL headings (buffer, H2+)", opts)

      map("n", "<leader>mhDA", function()
        local s, e = whole_buf_lines()
        headings.shift_range(s, e, -1)
      end, "[Markdown] Decrease ALL headings (buffer, H2+)", opts)
    end
  end
end

-- --- Public setup ------------------------------------------------------------

function M.setup()
  local cfg_get = require("custom.markdown.config").get
  local cfg = cfg_get()
  if not cfg.enable_keymaps then return end

  if cfg.ft_only ~= false then
    -- Strict: only in Markdown buffers (idempotent)
    local aug = api.nvim_create_augroup("CustomMarkdownKeymaps", { clear = true })
    api.nvim_create_autocmd("FileType", {
      group = aug,
      pattern = { "markdown", "markdown.mdx", "mdx" },
      callback = function(ev) apply_keymaps(ev.buf) end,
      desc = "custom.markdown: install buffer-local Markdown keymaps",
    })
  else
    -- Lax: set once globally + ensure future Markdown buffers also get the maps
    if not vim.g.__custom_markdown_keymaps_installed then
      apply_keymaps(nil)
      vim.g.__custom_markdown_keymaps_installed = true
    end
    local aug = api.nvim_create_augroup("CustomMarkdownKeymapsLax", { clear = true })
    api.nvim_create_autocmd("FileType", {
      group = aug,
      pattern = { "markdown", "markdown.mdx", "mdx" },
      callback = function(ev) apply_keymaps(ev.buf) end,
      desc = "custom.markdown: ensure maps for future Markdown buffers",
    })
  end

	-- Open image/file under cursor with system application ----------------------
	map("n", "gx", function()
		-- Get current line
		local line = api.nvim_get_current_line()
		local col = api.nvim_win_get_cursor(0)[2] + 1

		-- Match Markdown image/link syntax: ![alt](path) or [text](path)
		local path = line:match("%[.-%]%((.-)%)")

		if path then
			-- Resolve relative path from current file's directory
			local current_file = api.nvim_buf_get_name(0)
			local current_dir = vim.fn.fnamemodify(current_file, ":h")
			local full_path = vim.fn.resolve(current_dir .. "/" .. path)

			-- Open with system default application (Windows)
			if vim.fn.has("win32") == 1 then
				vim.fn.jobstart({ "cmd.exe", "/c", "start", '""', full_path }, { detach = true })
			-- macOS
			elseif vim.fn.has("mac") == 1 then
				vim.fn.jobstart({ "open", full_path }, { detach = true })
			-- Linux
			else
				vim.fn.jobstart({ "xdg-open", full_path }, { detach = true })
			end

			vim.notify("Opening: " .. full_path, vim.log.levels.INFO)
		else
			vim.notify("No link found under cursor", vim.log.levels.WARN)
		end
	end, "[Markdown] Open image/link with system app", o)
end

return M
