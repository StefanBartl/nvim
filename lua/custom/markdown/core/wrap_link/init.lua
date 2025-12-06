---@module 'custom.markdown.core.wrap_link'
--- Module for wrapping words, selections, URLs, or file paths in Markdown links [text](url)
---
--- * Der Handler unterscheidet zwischen Normal- und Visual-Modus:
---   1. Visual: Alles innerhalb der Selektion wird in `[]()` gewrapped.
---   2. Normal:
---      * Leerzeichen oder kein Wort → `[]()` einfügen.
---      * URL/Dateipfad → `[text](text)`
---      * normales Wort → `[text]()`, Cursor wird innerhalb der Klammern positioniert.
--- * Alle Operationen arbeiten direkt auf den Buffer, keine Autocommands nötig.

local M = {}

local api = vim.api
local fn = vim.fn

---@param opts table|nil Optional keymap options (e.g., { buffer = bufnr })
local function map(mode, lhs, rhs, desc, opts)
  opts = opts or {}
  opts.desc = desc or ""
  vim.keymap.set(mode, lhs, rhs, opts)
end

---@param bufnr integer Buffer number
local function is_markdown_buf(bufnr)
  return vim.bo[bufnr].filetype == "markdown"
end

---@param text string
---@return boolean True if text looks like a URL or file path
local function is_url_or_path(text)
  return text:match("^https?://") or text:match("^file://") or text:match("^%S+%.%S+$")
end

---@param bufnr integer|nil
function M.attach(bufnr)
  if not bufnr or not is_markdown_buf(bufnr) then
    return
  end

  local opts = { buffer = bufnr, noremap = true, silent = true }

  --- Handler for <leader>[ mapping
  local function wrap_handler()
    local mode = vim.fn.mode()
    local row, col = unpack(api.nvim_win_get_cursor(0))

    if mode == "v" or mode == "V" or mode == "\22" then
      -- Visual mode: wrap selection
      local start_pos = fn.getpos("'<")
      local end_pos = fn.getpos("'>")
      local lines = api.nvim_buf_get_lines(bufnr, start_pos[2]-1, end_pos[2], false)

      -- adjust first and last line columns
      lines[1] = lines[1]:sub(start_pos[3])
      lines[#lines] = lines[#lines]:sub(1, end_pos[3]-start_pos[3]+1)

      local text = table.concat(lines, "\n")
      local wrapped = "[" .. text .. "]()"

      api.nvim_buf_set_text(bufnr, start_pos[2]-1, start_pos[3]-1, end_pos[2]-1, end_pos[3], { wrapped })
      api.nvim_win_set_cursor(0, { start_pos[2], start_pos[3] + 1 })
    else
      -- Normal mode
      local word = fn.expand("<cword>")
      local insert_text = ""

      if word == "" then
        -- no word under cursor
        insert_text = "[]()"
        api.nvim_put({ insert_text }, "c", true, true)
        api.nvim_win_set_cursor(0, { row, col + 1 })
      else
        if is_url_or_path(word) then
          -- URL or filepath: wrap with [] before and () after
          insert_text = "[" .. word .. "](" .. word .. ")"
        else
          -- plain word: wrap in [] and insert () after
          insert_text = "[" .. word .. "]()"
        end

        -- replace current word with wrapped version
        vim.cmd("normal! ciw" .. insert_text)

        if not is_url_or_path(word) then
          -- move cursor inside parentheses
          local new_col = col + #word + 3
          api.nvim_win_set_cursor(0, { row, new_col })
        end
      end
    end
  end

  map("n", "<leader>[", wrap_handler, "[Custom.Markdown] Wrap word, selection, URL, or path", opts)
  map("v", "<leader>[", wrap_handler, "[Custom.Markdown] Wrap word, selection, URL, or path", opts)
end

return M
