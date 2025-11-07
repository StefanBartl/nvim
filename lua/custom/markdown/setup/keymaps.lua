---@module 'custom.markdown.setup.keymaps'
--- Buffer-local Markdown keymaps (fold, headings, wrap, toc, images/links)
--- Idempotent, performance-friendly, and conflict-free.

--- AUDIT: SEPARIEREN anstatt eine große fiole.

local M = {}
local api = vim.api
local anchor = require("custom.markdown.anchor.jump")
local image = require("custom.markdown.handler.image")
local handler = require("custom.markdown.handler")

-- --- Small helpers -----------------------------------------------------------

---@param base table|nil
---@param extra table|nil
---@return table
local function with(base, extra)
  if not extra then
    return base or {}
  end
  if not base then
    local out = {}
    for k, v in pairs(extra) do
      out[k] = v
    end
    return out
  end
  for k, v in pairs(extra) do
    base[k] = v
  end
  return base
end

---@param modes string|string[]
---@param lhs string
---@param rhs function|string
---@param desc string
---@param opts table|nil
local function map(modes, lhs, rhs, desc, opts)
  -- If rhs is nil, skip and log which mapping would have been set.
  if rhs == nil then
    vim.notify(
      string.format(
        "[Custom.Markdown] SKIP mapping %s -> nil (modes=%s) ; desc=%s",
        tostring(lhs),
        vim.inspect(modes),
        tostring(desc)
      ),
      vim.log.levels.WARN
    )
    return
  end

  local o = { noremap = true, silent = true, desc = desc }
  if opts then
    for k, v in pairs(opts) do
      o[k] = v
    end
  end

  local ok, err = pcall(vim.keymap.set, modes, lhs, rhs, o)
  if not ok then
    vim.notify(
      string.format(
        "[Custom.Markdown] FAILED to set mapping %s (modes=%s): %s",
        tostring(lhs),
        vim.inspect(modes),
        tostring(err)
      ),
      vim.log.levels.ERROR
    )
  end
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
function M.apply(bufnr)
  local cfg = require("custom.markdown.config").get()
  if bufnr and not is_markdown_buf(bufnr) then
    return
  end
  local o = bufnr and { buffer = bufnr } or nil

  -- Load submodules safely
  local ok_head, headings = pcall(require, "custom.markdown.core.headings")
  local ok_wrap, wrap = pcall(require, "custom.markdown.core.wrap")
  local ok_fold, fold = pcall(require, "custom.markdown.core.fold")
  local ok_prev, fold_prev = pcall(require, "custom.markdown.core.fold_prev")
  local ok_lvls, fold_lvls = pcall(require, "custom.markdown.core.fold_levels")
  local ok_toc, toc = pcall(require, "custom.markdown.core.toc")

  -- Wrap visual toggle ** ----------------------------------------------------
  if ok_wrap and wrap.toggle_visual_bold then
    map("x", "**", wrap.toggle_visual_bold, "[Custom.Markdown] Toggle ** around selection", o)
  end

  -- Headings navigation -------------------------------------------------------
  if ok_head then
    if headings.goto_prev_heading then
      map({ "n", "v", "x" }, "mk", headings.goto_prev_heading, "[Custom.Markdown] Previous heading (H2+)", o)
    end
    if headings.goto_next_heading then
      map({ "n", "v", "x" }, "mj", headings.goto_next_heading, "[Custom.Markdown] Next heading (H2+)", o)
    end
  end

  -- Folding controls ----------------------------------------------------------
  if ok_fold then
    map("n", "<localleader>f", fold.toggle_under_cursor, "[Custom.Markdown] Toggle fold under cursor & center", o)
    if cfg.use_zf_override then
      map(
        "n",
        "zf",
        fold.toggle_under_cursor,
        "[Custom.Markdown] Toggle fold under cursor & center (override)",
        with(o or {}, { nowait = true })
      )
    end
    map("n", "zu", fold.unfold_all_center, "[Custom.Markdown] Unfold all & center", o)
  end

  if ok_prev and fold_prev.fold_prev_heading_then_center then
    map("n", "zi", fold_prev.fold_prev_heading_then_center, "[Custom.Markdown] Fold previous heading & center", o)
  end

  if ok_lvls and fold_lvls.fold_levels then
    map("n", "zk", function()
      fold_lvls.fold_levels({ 2, 3, 4, 5, 6 })
    end, "[Custom.Markdown] Fold H2+ (keep H1 open)", o)
  end

  -- TOC insert/refresh --------------------------------------------------------
  if ok_toc and toc.update_markdown_toc then
    map("n", "<leader>toc", function()
      toc.update_markdown_toc("## Table of content")
    end, "[Custom.Markdown] Insert/Refresh TOC", o)
  end

  -- AUDIT: If/Else implementieren (dann aber auch 2 options, mj oder im mouse handler oder beides (default))

  -- (Mouse-) Action-Handler -------------------------------------------------------------
  -- Double-click and Ctrl+Click for opening with system application: files, images
  map("n", "<2-LeftMouse>", handler.handle_cursor_action, "[Custom.Markdown] Handle cursor action (TOC/Image/Link)", o)
  map("n", "<C-LeftMouse>", handler.handle_cursor_action, "[Custom.Markdown] Handle cursor action (TOC/Image/Link)", o)
  map("n", "ma", handler.handle_cursor_action, "[Custom.Markdown] Handle cursor action (TOC/Image/Link)", o)
  map("n", "mi", function()
    image.open()
  end, "[Custom.Markdown] Open image under cursor", o)
  map("n", "mj", anchor.jump, "[Custom.Markdown] Jump to TOC anchor", o)

  -- Headings level shift ------------------------------------------------------
  if ok_head and headings.increase and headings.decrease then
    local opts = with({ silent = true, noremap = true, nowait = true }, o)

    -- Line
		map("n", "<leader>mhi", function()
				local cur = vim.api.nvim_win_get_cursor(0)
				headings.shift_range(cur[1], cur[1], 1)
		end, "[Custom.Markdown] Increase heading in line (buffer)", opts)

		map("n", "<leader>mhd", function()
				local cur = vim.api.nvim_win_get_cursor(0)
				headings.shift_range(cur[1], cur[1], -1)
		end, "[Custom.Markdown] Decrease heading in line (buffer)", opts)

		-- Visual mode
		map("v", "<leader>mhi", function()
			vim.go.operatorfunc = "v:lua.require'custom.markdown.core.headings'._op_increase"
			return "g@"
		end, "[Custom.Markdown] Increase headings in selection (buffer)", opts)

		map("v", "<leader>mhd", function()
			vim.go.operatorfunc = "v:lua.require'custom.markdown.core.headings'._op_decrease"
			return "g@"
		end, "[Custom.Markdown] Decrease ALL headings in selection (buffer)", opts)


    -- Whole buffer
		if ok_head and type(headings.shift_range) == "function" then
			local function whole_buf_lines()
				local b = bufnr or api.nvim_get_current_buf()
				return 1, api.nvim_buf_line_count(b)
			end

		-- FIX: First-Level Headling (`#`) wird übersrpungen
			map("n", "<leader>mhI", function()
				local s, e = whole_buf_lines()
				headings.shift_range(s, e, 1)
			end, "[Custom.Markdown] Increase ALL headings (buffer)", opts)

			map("n", "<leader>mhD", function()
				local s, e = whole_buf_lines()
				headings.shift_range(s, e, -1)
			end, "[Custom.Markdown] Decrease ALL headings (buffer)", opts)
		end

		-- Operator-pending
    if headings._op_increase and headings._op_decrease then
      map("n", "<leader>mha", function()
        vim.go.operatorfunc = "v:lua.require'custom.markdown.core.headings'._op_increase"
        return "g@"
      end, "[Custom.Markdown] Increase headings (operator-pending)", with({ expr = true }, opts))

      map("n", "<leader>mhx", function()
        vim.go.operatorfunc = "v:lua.require'custom.markdown.core.headings'._op_decrease"
        return "g@"
      end, "[Custom.Markdown] Decrease headings (operator-pending)", with({ expr = true }, opts))
    end

  end
end

return M
