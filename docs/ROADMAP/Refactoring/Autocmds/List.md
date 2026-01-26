Autocmd Audit Summary
---------------------
Total unique autocmd calls: 110
Total event registrations: 98

Event frequency:
  "FileType": 17
  "BufEnter": 11
  "BufWritePre": 7
  "VimEnter": 6
  "BufWinEnter": 6
  "ColorScheme": 6
  "CursorMoved": 5
  "VimLeavePre": 5
  "BufDelete": 4
  "User": 3
  "BufReadPost": 3
  "ModeChanged": 3
  "WinClosed": 3
  "InsertEnter": 2
  "BufLeave": 2
  "WinEnter": 2
  "BufWritePost": 1
  "BufWinLeave": 1
  "DirChanged": 1
  "LspAttach": 1
  "TermOpen": 1
  "TextChanged": 1
  "BufWipeout": 1
  "CursorMovedI": 1
  "WinLeave": 1
  "OptionSet": 1
  "TextYankPost": 1
  "CursorHold": 1
  "DiagnosticChanged": 1

Detailed listing (by source)
----------------------------

1. autocmds/auto-center-fexplorer.lua:138
Events: CursorMoved
Implementation:
  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    group = group,
    buffer = bufnr,
    callback = function()
      if config.enabled then
        schedule_center(bufnr)
      end
    end,
    desc = "Auto-center cursor in file explorer",
  })


2. autocmds/auto-center-fexplorer.lua:150
Events: BufDelete
Implementation:
  vim.api.nvim_create_autocmd("BufDelete", {
    group = group,
    buffer = bufnr,
    callback = function()
      if timers[bufnr] then
        if not timers[bufnr]:is_closing() then
          timers[bufnr]:stop()
          timers[bufnr]:close()
        end
        timers[bufnr] = nil
      end
      enabled_buffers[bufnr] = nil
    end,
    desc = "Cleanup auto-center resources",
  })


3. autocmds/auto-center-fexplorer.lua:188
Events: FileType
Implementation:
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("AutoCenterExplorerSetup", { clear = true }),
    callback = function(args)
      if is_explorer_filetype(args.match) then
        setup_buffer(args.buf)
      end
    end,
    desc = "Setup auto-centering for file explorer buffers",
  })


4. autocmds/general/init.lua:29
Events: BufWritePre
Implementation:
    api.nvim_create_autocmd("BufWritePre", {
      group = grp,
      callback = function(event)
        -- Optional: skip URL-like or remote buffers (e.g., "ssh://host/path", "http://…")
        if cfg.auto_mkdir.skip_remote and event.match:match(cfg.auto_mkdir.detect_remote_pattern) then
          return
        end
        -- Resolve to a real path if possible; falls back to the raw buffer path.
        local file = (uv.fs_realpath and uv.fs_realpath(event.match)) or event.match
        -- Create the parent directory recursively ("p" flag).
        -- Uses Vim’s robust `mkdir()` which handles both Linux and macOS gracefully.
        vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
      end,
      desc = "Auto-create the parent directory before writing a file",
    })


5. autocmds/general/init.lua:49
Events: VimEnter
Implementation:
    api.nvim_create_autocmd("VimEnter", {
      group = grp,
      callback = function()
        helpers.kitty_set_spacing(cfg.kitty.enter_padding, cfg.kitty.enter_margin)
      end,
      desc = "Kitty: reduce spacing for the current window on VimEnter",
    })


6. autocmds/general/init.lua:56
Events: VimLeavePre
Implementation:
    api.nvim_create_autocmd("VimLeavePre", {
      group = grp,
      callback = function()
        helpers.kitty_set_spacing(cfg.kitty.leave_padding, cfg.kitty.leave_margin)
      end,
      desc = "Kitty: restore spacing for the current window on VimLeavePre",
    })


7. autocmds/general/init.lua:68
Events:
Implementation:
    api.nvim_create_autocmd(cfg.cursorline.show_events, {
      group = grp_show,
      callback = function(event)
        -- Only enable cursorline for "normal" buffers (empty buftype).
        if vim.bo[event.buf].buftype == "" then
          vim.opt_local.cursorline = true
        end
      end,
      desc = "Enable cursorline in the active window on relevant events",
    })


8. autocmds/general/init.lua:80
Events:
Implementation:
    api.nvim_create_autocmd(cfg.cursorline.hide_events, {
      group = grp_hide,
      callback = function()
        vim.opt_local.cursorline = false
      end,
      desc = "Disable cursorline in inactive windows or insert mode",
    })


9. autocmds/general/init.lua:92
Events: BufReadPost
Implementation:
    api.nvim_create_autocmd("BufReadPost", {
      group = grp,
      callback = function(event)
        local buf = event.buf
        -- Skip specific filetypes (commit messages, rebase plans, etc.)
        if vim.tbl_contains(cfg.last_loc.exclude, vim.bo[buf].filetype) then
          return
        end
        -- Guard against running twice per buffer
        if vim.b[buf].__custom_last_loc_done then
          return
        end
        vim.b[buf].__custom_last_loc_done = true

        -- Retrieve the last-position mark (default: `"`).
        local mark = api.nvim_buf_get_mark(buf, cfg.last_loc.mark)
        local lcount = api.nvim_buf_line_count(buf)
        if mark[1] > 0 and mark[1] <= lcount then
          -- pcall to avoid throwing if the window is in a nonstandard state.
          pcall(api.nvim_win_set_cursor, 0, mark)
        end
      end,
      desc = "Jump to the last cursor position on file open",
    })


10. autocmds/general/init.lua:120
Events: FileType
Implementation:
    api.nvim_create_autocmd("FileType", {
      group = helpers.augroup("goto_file"),
      pattern = helpers.snorm_pattern(cfg.goto_file.pattern),
      callback = function()
        -- Validate Treesitter availability; otherwise, keep default behavior.
        local ok_ts = pcall(require, "nvim-treesitter.ts_utils")
        if not ok_ts then
          return
        end

        -- Preload ordered case modules
        local cases = gofile_loader.load_ordered_cases(cfg)
        local logger = logger_mod(cfg)

        local function gf_dispatch()
          local dispatch_cases = require("autocmds.general.gofile_case_dispatcher")
          local ts_utils = require("nvim-treesitter.ts_utils")

          local bufnr = api.nvim_get_current_buf()
          local node = ts_utils.get_node_at_cursor()

          logger.debug("gf invoked", {
            buf = bufnr,
            node_type = node and node:type() or nil,
          })

          local handled = false
          if dispatch_cases then
            handled = dispatch_cases(node, bufnr, ts_utils, cfg, cases)
          end

          if not handled then
            logger.info("falling back to builtin gf")
            vim.cmd.normal({ args = { "gf" }, bang = true })
          end
        end

        local lhs_list =  {"gf"}

        for _, lhs in ipairs(lhs_list) do
          vim.keymap.set("n", lhs, gf_dispatch, {
            buffer = 0,
            noremap = true,
            silent = true,
            desc = "Markdown-aware gf with modular resolver",
          })
        end
      end,
      desc = "Markdown: override gf to follow links/URLs with fallback",
    })


11. autocmds/git/blame_on_hold.lua:17
Events: CursorHold
Implementation:
  api.nvim_create_autocmd("CursorHold", {
    group = shared.augroup("blame_on_hold"),
    callback = function()
      local bt = vim.bo.buftype
      if cfg.ignore_buftypes and vim.tbl_contains(cfg.ignore_buftypes, bt) then
        return
      end
      local ok, gs = pcall(require, "gitsigns")
      if not ok or not gs.blame_line then
        return
      end

      local function run()
        pcall(gs.blame_line, {
          full = false,
          ignore_whitespace = true,
          virt_text = (cfg.virt ~= false),
        })
      end

      local delay = tonumber(cfg.delay or 0) or 0
      if delay > 0 then
        vim.defer_fn(run, delay)
      else
        run()
      end
    end,
    desc = "Git: inline blame on CursorHold (gitsigns)",
  })


12. autocmds/git/commit_ft.lua:18
Events: FileType
Implementation:
  api.nvim_create_autocmd("FileType", {
    group = api.nvim_create_augroup("git_autocmds_commit_ft", { clear = true }),
    pattern = "gitcommit",
    callback = function()
      if cfg.spell ~= false then
        vim.opt_local.spell = true
      end
      if cfg.textwidth then
        vim.opt_local.textwidth = cfg.textwidth
      end
      if cfg.colorcolumn then
        vim.opt_local.colorcolumn = cfg.colorcolumn
      end
      if cfg.formatoptions then
        vim.opt_local.formatoptions = cfg.formatoptions
      end
      if cfg.start_in_insert then
        vim.schedule(function()
          if vim.bo.filetype == "gitcommit" then
            vim.cmd("startinsert")
          end
        end)
      end
    end,
    desc = "Git: commit message buffer settings",
  })


13. autocmds/git/conflicts_qf.lua:21
Events:
Implementation:
  api.nvim_create_autocmd(events, {
    group = shared.augroup("conflicts_qf"),
    callback = function()
      local git = cfg.git_cmd or "git"
      if not shared.in_git_repo(git) then
        return
      end

      local filter = cfg.diff_filter or "U"
      local cmd = string.format("%s diff --name-only --diff-filter=%s", git, filter)
      local conflicts = fn.systemlist(cmd)
      if type(conflicts) ~= "table" or #conflicts == 0 then
        return
      end

      -- Build qf items (safe array push)
      local qf = { [#conflicts] = {} }
      for i = 1, #conflicts do
        qf[i] = { filename = conflicts[i], lnum = 1, col = 1, text = "Git conflict" }
      end
      fn.setqflist(qf, "r")
      if cfg.open_qf ~= false then
        vim.cmd("copen")
      end
      if cfg.notify ~= false then
        notify.warn("Git conflicts detected:\n" .. table.concat(conflicts, "\n"))
      end
    end,
    desc = "Git: populate quickfix with unresolved conflicts",
  })


14. autocmds/git/conflict_marks.lua:17
Events: BufWinEnter
Implementation:
  api.nvim_create_autocmd("BufWinEnter", {
    group = shared.augroup("conflict_marks_on"),
    callback = function()
      local id_a = fn.matchadd(cfg.hl_a or "DiffDelete", [[^<<<<<<< .\+$]])
      local id_b = fn.matchadd(cfg.hl_b or "DiffChange", [[^=======\s*$]])
      local id_c = fn.matchadd(cfg.hl_c or "DiffAdd", [[^>>>>>>> .\+$]])
      vim.w._git_conflict_match_ids = { id_a, id_b, id_c }
    end,
    desc = "Git: highlight conflict markers",
  })


15. autocmds/git/conflict_marks.lua:28
Events: BufWinLeave
Implementation:
  api.nvim_create_autocmd("BufWinLeave", {
    group = shared.augroup("conflict_marks_off"),
    callback = function()
      local ids = vim.w._git_conflict_match_ids
      if type(ids) == "table" then
        for _, id in ipairs(ids) do
          pcall(vim.fn.matchdelete, id)
        end
      end
      vim.w._git_conflict_match_ids = nil
    end,
    desc = "Git: clear conflict marker highlights",
  })


16. autocmds/git/gitsigns_refresh.lua:18
Events:
Implementation:
  api.nvim_create_autocmd(events, {
    group = shared.augroup("gitsigns_refresh"),
    callback = function()
      local ok, gs = pcall(require, "gitsigns")
      if ok and gs.refresh then
        pcall(gs.refresh)
      end
    end,
    desc = "Git: refresh gitsigns on focus/enter",
  })


17. autocmds/git/line_diff_on_hold.lua:185
Events:
Implementation:
  api.nvim_create_autocmd(events, {
    group = shared.augroup("line_diff_on_hold"),
    callback = function()
      -- Early, cheap gate at event time
      if not mode_allowed(cfg.modes) then
        return
      end

      local win = api.nvim_get_current_win()
      local now_ms = math.floor((uv.hrtime() or 0) / 1e6)
      local last_ms = last_fire_ms_by_win[win] or 0
      if (now_ms - last_ms) < throttle_ms then
        return
      end
      last_fire_ms_by_win[win] = now_ms

      local buf = api.nvim_get_current_buf()
      if not shared.normal_buf_allowed(cfg.ignore_buftypes) then
        return
      end
      if cfg.require_clean_buffer and vim.bo[buf].modified then
        return
      end

      local git = cfg.git_cmd or "git"
      if not shared.in_git_repo(git) then
        return
      end

      local file = api.nvim_buf_get_name(buf)
      if file == "" then
        return
      end
      if cfg.only_tracked and not is_tracked(git, file) then
        return
      end

      -- Snapshot a generation token for this schedule
      local my_gen = bump_gen(win)

      local function run()
        -- Re-check mode right before any rendering (fixes delayed runs in wrong mode)
        if not mode_allowed(cfg.modes) then
          return
        end
        -- Invalidate stale scheduled runs (mode changed since schedule)
        if gen_by_win[win] ~= my_gen then
          return
        end

        shared.clear_line_diff(buf)

        -- Prefer gitsigns inline preview (guarded + stable viewport)
        if prefer_inline then
          local ok_gs, gs = pcall(require, "gitsigns")
          if ok_gs and gs.preview_hunk_inline then
            local view = fn.winsaveview()
            local cur = api.nvim_win_get_cursor(0)
            local ok_inline = pcall(gs.preview_hunk_inline)
            if ok_inline then
              if restore_view then
                vim.schedule(function()
                  pcall(fn.winrestview, view)
                  pcall(api.nvim_win_set_cursor, 0, cur)
                end)
              end
              api.nvim_create_autocmd({ "CursorMoved", "BufHidden", "InsertEnter" }, {
                group = shared.augroup("line_diff_on_hold_cleanup"),
                buffer = buf,
                once = true,
                callback = function()
                  shared.clear_line_diff(buf)
                end,
                desc = "Git: clear inline diff preview on next move",
              })
              return
            end
          end
        end

        -- Fallback: previous committed content as EOL/right-aligned virtual text
        local lnum = get_lnum()
        local prev = get_previous_line(git, file, lnum)
        if not prev or prev == "" then
          return
        end

        local virt = truncate(prev, tonumber(cfg.max_len or 160) or 160)
        local pos = (cfg.right_align and "right_align") or "eol"
        local pref = (cfg.prefix ~= nil) and tostring(cfg.prefix) or "previous: "

        api.nvim_buf_set_extmark(buf, shared.NS_LINE_DIFF, lnum - 1, 0, {
          virt_text = { { pref .. virt, cfg.hl_prev or "Comment" } },
          virt_text_pos = pos,
          priority = tonumber(cfg.virt_priority or 1000) or 1000,
        })

        api.nvim_create_autocmd({ "CursorMoved", "BufHidden", "InsertEnter" }, {
          group = shared.augroup("line_diff_on_hold_cleanup"),
          buffer = buf,
          once = true,
          callback = function()
            shared.clear_line_diff(buf)
          end,
          desc = "Git: clear previous-line preview on next move",
        })
      end

      local extra = tonumber(cfg.delay or 0) or 0
      if extra > 0 then
        vim.defer_fn(run, extra)
      else
        run()
      end
    end,
    desc = "Git: show line diff/previous content on CursorHold/InsertHold (mode-aware, strict)",
  })


18. autocmds/git/line_diff_on_hold.lua:251
Events: CursorMoved
Implementation:
              api.nvim_create_autocmd({ "CursorMoved", "BufHidden", "InsertEnter" }, {
                group = shared.augroup("line_diff_on_hold_cleanup"),
                buffer = buf,
                once = true,
                callback = function()
                  shared.clear_line_diff(buf)
                end,
                desc = "Git: clear inline diff preview on next move",
              })


19. autocmds/git/line_diff_on_hold.lua:282
Events: CursorMoved
Implementation:
        api.nvim_create_autocmd({ "CursorMoved", "BufHidden", "InsertEnter" }, {
          group = shared.augroup("line_diff_on_hold_cleanup"),
          buffer = buf,
          once = true,
          callback = function()
            shared.clear_line_diff(buf)
          end,
          desc = "Git: clear previous-line preview on next move",
        })


20. autocmds/git/line_diff_on_hold.lua:304
Events: ModeChanged
Implementation:
  api.nvim_create_autocmd("ModeChanged", {
    group = shared.augroup("line_diff_on_hold_modeclear"),
    callback = function()
      local win = api.nvim_get_current_win()
      local buf = api.nvim_get_current_buf()
      if not mode_allowed(cfg.modes) then
        shared.clear_line_diff(buf)
        bump_gen(win) -- invalidate any scheduled, not-yet-run callbacks
      end
    end,
    desc = "Git: clear/abort line diff when leaving allowed modes",
  })


21. autocmds/terminals/init.lua:75
Events:
Implementation:
    vim.api.nvim_create_autocmd(norm_events(cfg.numbers.events, { "TermOpen" }), {
      group = augroup("numbers"),
      callback = function(ev)
        -- Use local options to avoid bleeding into non-terminal windows.
        vim.api.nvim_buf_call(ev.buf, function()
          vim.opt_local.number = false
          vim.opt_local.relativenumber = false
        end)
      end,
      desc = "Terminal: disable absolute and relative line numbers (local)",
    })


22. autocmds/terminals/init.lua:94
Events: VimEnter
Implementation:
    vim.api.nvim_create_autocmd("VimEnter", {
      group = augroup("kitty_enter"),
      command = kitty_cmd(cfg.kitty.enter_padding, cfg.kitty.enter_margin),
      desc = "Kitty: reduce padding/margin for a snug editor frame on startup",
    })


23. autocmds/terminals/init.lua:99
Events: VimLeavePre
Implementation:
    vim.api.nvim_create_autocmd("VimLeavePre", {
      group = augroup("kitty_leave"),
      command = kitty_cmd(cfg.kitty.leave_padding, cfg.kitty.leave_margin),
      desc = "Kitty: restore padding/margin when leaving Neovim",
    })


24. autocmds/terminals/init.lua:109
Events:
Implementation:
    vim.api.nvim_create_autocmd(norm_events(cfg.auto_insert.events, { "TermOpen" }), {
      group = augroup("auto_insert"),
      callback = function()
        -- `startinsert` is safe here; schedule to avoid racing with other handlers.
        vim.schedule(function()
          if vim.bo.buftype == "terminal" then
            vim.cmd("startinsert")
          end
        end)
      end,
      desc = "Terminal: enter Insert mode automatically",
    })


25. autocmds/text/init.lua:94
Events: BufWritePre
Implementation:
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = augroup("trim_trailing"),
      pattern = norm_pattern(cfg.trim_trailing.pattern),
      callback = function(ev)
        local buf = ev.buf
        if
          not should_process(
            buf,
            cfg.trim_trailing.ignore_filetypes,
            cfg.trim_trailing.ignore_buftypes,
            cfg.trim_trailing.only_modifiable,
            cfg.trim_trailing.only_normal_bufs
          )
        then
          return
        end
        -- Use a buffer-local :substitute that ignores errors (`e` flag) and is silent.
        -- The pattern `\s\+$` trims any whitespace at the end of lines.
        vim.api.nvim_buf_call(buf, function()
          vim.cmd([[silent! keepjumps keeppatterns %s/\s\+$//e]])
        end)
      end,
      desc = "Trim trailing whitespace on save",
    })


26. autocmds/text/init.lua:123
Events: BufWritePre
Implementation:
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = augroup("trim_blank"),
      pattern = norm_pattern(cfg.trim_blank.pattern),
      callback = function(ev)
        local buf = ev.buf
        if
          not should_process(
            buf,
            cfg.trim_blank.ignore_filetypes,
            cfg.trim_blank.ignore_buftypes,
            cfg.trim_blank.only_modifiable,
            cfg.trim_blank.only_normal_bufs
          )
        then
          return
        end
        local row, col
        if cfg.trim_blank.preserve_cursor ~= false then
          row, col = unpack(vim.api.nvim_win_get_cursor(0))
        end
        -- Substitute leading whitespace on empty lines with nothing.
        -- `^\s*$` matches lines entirely composed of whitespace.
        vim.api.nvim_buf_call(buf, function()
          vim.cmd([[silent! keepjumps keeppatterns %s/^\s*$//e]])
        end)
        if row and col then
          pcall(vim.api.nvim_win_set_cursor, 0, { row, col })
        end
      end,
      desc = "Trim whitespace on fully blank lines (preserve cursor)",
    })


27. autocmds/text/init.lua:159
Events: BufReadPost
Implementation:
    vim.api.nvim_create_autocmd("BufReadPost", {
      group = augroup("last_loc"),
      pattern = norm_pattern(cfg.last_loc.pattern),
      callback = function(ev)
        local buf = ev.buf
        local ft = vim.bo[buf].filetype or ""
        if cfg.last_loc.exclude and vim.tbl_contains(cfg.last_loc.exclude, ft) then
          return
        end
        -- Get the mark `"` (last known cursor position in this file).
        local target_line = vim.fn.line([['"]])
        local last_line = vim.api.nvim_buf_line_count(buf)
        local min_line = cfg.last_loc.min_line or 1
        if target_line >= min_line and target_line <= last_line then
          -- Use pcall to avoid errors in special windows.
          pcall(function()
            vim.cmd([[normal! g`"]])
          end)
        end
      end,
      desc = "Restore last cursor position after reading a buffer",
    })


28. config/harpoon/hardening.lua:151
Events:
Implementation:
  nvim_create_autocmd(events, {
    group = STATE.augroup,
    callback = function()
      _debounced_save()
    end,
    desc = "Harpoon debounced save",
  })


29. config/harpoon/hardening.lua:160
Events: VimLeavePre
Implementation:
  nvim_create_autocmd("VimLeavePre", {
    group = STATE.augroup,
    callback = function()
      _flush_now()
    end,
    desc = "Harpoon flush pending save",
  })


30. config/harpoon/persist_paths.lua:193
Events: VimEnter
Implementation:
  vim.api.nvim_create_autocmd("VimEnter", {
    group = grp,
    callback = function()
      vim.schedule(function()
        M.inject_now()
      end)
    end,
  })


31. config/markdown_preview/init.lua:67
Events: BufEnter
Implementation:
  vim.api.nvim_create_autocmd("BufEnter", {
    group = aug,
    pattern = "*.md",
    callback = function()
      -- Safe to call repeatedly; with combine_preview=1 it reuses/updates.
      vim.cmd("silent! MarkdownPreview")
    end,
  })


32. config/markdown_preview/init.lua:95
Events: BufEnter
Implementation:
  vim.api.nvim_create_autocmd("BufEnter", {
    group = aug,
    pattern = "*.md",
    callback = function()
      if M._preview_active and vim.fn.exists(":MarkdownPreview") == 2 then
        vim.cmd("silent! MarkdownPreview")
      end
    end,
  })


33. config/neotest/core/init.lua:62
Events: BufEnter
Implementation:
    vim.api.nvim_create_autocmd({ "BufEnter", "BufNewFile" }, {
      group = aug,
      callback = function()
        if is_test_file() then
          vim.schedule(function()
            local ok, neotest = pcall(require, "neotest")
            if ok then
              ---@diagnostic disable-next-line: undefined-field
              pcall(neotest.run.attach)
            end
          end)
        end
      end,
      desc = "Neotest: Auto-attach to test files",
    })


34. config/neotest/core/init.lua:80
Events: User
Implementation:
    vim.api.nvim_create_autocmd("User", {
      pattern = "NeotestRunComplete",
      group = aug,
      callback = function()
        vim.schedule(function()
          local ok, neotest = pcall(require, "neotest")
          if not ok then
            return
          end
          ---@diagnostic disable-next-line: undefined-field
          local results = neotest.state.get_results()
          if not results then
            return
          end

          local has_failed = false
          for _, result in pairs(results) do
            if result.status == "failed" then
              has_failed = true
              break
            end
          end

          if has_failed then
            ---@diagnostic disable-next-line: undefined-field
            neotest.output.open({ enter = false })
          end
        end)
      end,
      desc = "Neotest: Show output on test failure",
    })


35. config/neotree/current_hl/init.lua:184
Events: ColorScheme
Implementation:
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("NeoTreeCurrentHL", { clear = true }),
    callback = apply,
  })


36. config/neotree/current_hl/init.lua:259
Events: BufEnter
Implementation:
  vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "TabEnter", "BufWritePost" }, {
    group = grp,
    callback = deb,
  })


37. config/neotree/cwd_sync/init.lua:273
Events: BufEnter
Implementation:
  vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
    group = aug,
    callback = function()
      schedule_sync(cfg)
    end,
    desc = "Sync Neo-tree with current buffer (reveal)",
  })


38. config/neotree/cwd_sync/init.lua:281
Events: VimLeavePre
Implementation:
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = aug,
    callback = function()
      if S.timer then
        pcall(S.timer.stop, S.timer)
        pcall(S.timer.close, S.timer)
        S.timer = nil
      end
    end,
    desc = "Cleanup NeoTreeCwdSync timer",
  })


39. config/neotree/utils/buffer.lua:126
Events: BufDelete
Implementation:
vim.api.nvim_create_autocmd("BufDelete", {
  group = vim.api.nvim_create_augroup("NeoTreeBufferCacheInvalidate", { clear = true }),
  callback = function(args)
    M.invalidate_cache(args.buf)
  end,
})


40. config/snacks/custom_dashboard/autocmds.lua:18
Events: VimEnter
Implementation:
api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    -- Try to register and open the dashboard after a short delay to let startup finish.
    vim.defer_fn(function()
      local ok_dash, dash = pcall(require, "snacks.dashboard")
      if ok_dash and type(dash.open) == "function" then
        pcall(dash.open)
      end
    end, 50)
  end,
  desc = desc_tag .. "startup open",
})


41. config/snacks/custom_dashboard/autocmds.lua:66
Events: BufWinEnter
Implementation:
api.nvim_create_autocmd({ "BufWinEnter" }, {
  callback = function()
    local ok_dash, dash = pcall(require, "snacks.dashboard")
    if not ok_dash or type(dash.open) ~= "function" then
      return
    end

    vim.defer_fn(function()
      if safe_to_open_dashboard() then
        pcall(dash.open)
      end
    end, 30)
  end,
  desc = desc_tag .. "defensive open on empty buffers",
})


42. config/snacks/___dashboard/autocmds.lua:12
Events: VimEnter
Implementation:
nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    vim.defer_fn(function()
      notify.debug("Snacks ready · dashboard with Sessions loaded")
    end, 50)
  end,
  desc = desc_tag .. "Snacks init hint",
})


43. config/snacks/___dashboard/autocmds.lua:70
Events: BufWinEnter
Implementation:
nvim_create_autocmd({ "BufWinEnter" }, {
  callback = function()
    local ok_dash, dash = pcall(require, "snacks.dashboard")
    if not ok_dash or type(dash.open) ~= "function" then
      return
    end

    -- Defer a tick to let transient buffers finish initialization, then re-check.
    vim.defer_fn(function()
      if safe_to_open_dashboard() then
        -- final protection: pcall to avoid crashing if dash.open errors
        pcall(dash.open)
      end
    end, 30)
  end,
  desc = desc_tag .. "Open custom Snacks dashboard on startup or truly empty buffer (defensive)",
})


44. custom/insert/boilerplate/templates/nvim.lua:13
Events:
Implementation:
    "vim.api.nvim_create_autocmd({ TODO: events }, {",
    "  group = augroup,",
    '  pattern = "TODO: pattern",',
    "  callback = function()",
    "    -- TODO: Implementation",
    "  end,",
    '  desc = "TODO: Description",',
    "})",


45. custom/markdown/fenced_fix/init.lua:159
Events: ColorScheme
Implementation:
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("MarkdownFencedFix", { clear = true }),
  callback = function()
    pcall(M.apply)
  end,
  desc = "Re-apply fenced fix and inline code styling after colorscheme changes",
})


46. custom/markdown/setup/autocmds.lua:21
Events: FileType
Implementation:
  api.nvim_create_autocmd("FileType", {
    group = aug_km,
    pattern = "*",
    callback = function(ev)
      local buf = ev.buf or api.nvim_get_current_buf()
      local ft = vim.bo[buf].filetype or ""

      local function is_md(ftname)
        if not ftname or ftname == "" then
          return false
        end
        if ftname == "md" or ftname == "mdx" then
          return true
        end
        if ftname == "markdown" then
          return true
        end
        if ftname:match("^markdown%.") then
          return true
        end -- e.g. markdown.pandoc, markdown.gfm
        return false
      end

      if not is_md(ft) then
        return
      end

      local ok, err = pcall(function()
        require("custom.markdown.setup.keymaps").apply(buf)
      end)
      if not ok then
        notify.warn(string.format( "[Custom.Markdown] failed to attach keymaps for buffer %d (filetype='%s'): %s", buf, ft, tostring(err) ))
      end
    end,
    desc = "[Custom.Markdown] Install buffer-local Markdown keymaps (robust matcher)",
  })


47. custom/markdown/setup/autocmds.lua:59
Events: FileType
Implementation:
  api.nvim_create_autocmd("FileType", {
    group = aug_uc,
    pattern = "*",
    callback = function(ev)
      local buf = ev.buf or api.nvim_get_current_buf()
      local ft = vim.bo[buf].filetype or ""
      if not (ft == "markdown" or ft == "md" or ft == "mdx" or ft:match("^markdown%.")) then
        return
      end

      local ok, err = pcall(function()
        require("custom.markdown.setup.usercmds").apply(ev)
      end)
      if not ok then
        notify.warn(string.format( "[Custom.Markdown] failed to attach usercommands for buffer %d (ft=%s): %s", buf, ft, tostring(err) ))
      end
    end,
    desc = "[Custom.Markdown] Install buffer-local usercommands for Markdown (robust matcher)",
  })


48. custom/markdown/tableview/autocmds.lua:14
Events: FileType
Implementation:
  api.nvim_create_autocmd("FileType", {
    group = aug,
    pattern = filetypes,
    callback = function(ev)
      -- apply buffer-local keymaps and commands
      pcall(function()
        require("custom.markdown.tableview.mappings").apply(ev.buf)
        require("custom.markdown.tableview.commands").apply(ev)
      end)
    end,
    desc = "[Custom.Markdown.TableView] Install buffer-local maps & commands for markdown",
  })


49. custom/markdown/tableview/live.lua:178
Events: BufWritePost
Implementation:
  api.nvim_create_autocmd("BufWritePost", {
    group = aug,
    pattern = { "*.md", "*.markdown", "*.mdx" },
    callback = function(ev)
      if not state.running then
        return
      end
      M.regenerate(ev.buf)
    end,
    desc = "Regenerate TableView live preview on save",
  })


50. custom/recommender/autocmds.lua:13
Events: WinClosed
Implementation:
  api.nvim_create_autocmd("WinClosed", {
    group = group,
    callback = function(args)
      local winid = tonumber(args.match)
      if not winid then return end

      -- Prüfe, ob das geschlossene Fenster ein Telescope-Prompt war
      local buf_closed = nil
      if api.nvim_win_is_valid(winid) then
        buf_closed = api.nvim_win_get_buf(winid)
      end
      if not buf_closed or vim.bo[buf_closed].filetype ~= "TelescopePrompt" then
        return
      end

      -- Prüfe Target-Window Validität
      if not api.nvim_win_is_valid(target_win) then
        vim.api.nvim_del_augroup_by_id(group)
        return
      end

      local buf = api.nvim_win_get_buf(target_win)
      if not api.nvim_buf_is_valid(buf) then
        vim.api.nvim_del_augroup_by_id(group)
        return
      end

      -- Vergleiche alten Snapshot mit aktuellem Buffer
      local new_lines = api.nvim_buf_get_lines(buf, 0, -1, false)
      local changed = false
      for i = 1, math.min(#buf_snapshot, #new_lines) do
        if buf_snapshot[i] ~= new_lines[i] then
          changed = true
          break
        end
      end

      -- Führe Alias-Insert nur durch, wenn sich der Buffer geändert hat
      if changed and api.nvim_win_is_valid(target_win) then
        api.nvim_set_current_win(target_win)
        api.nvim_put({ alias_text }, "l", false, true)
      end

      -- Autocmd danach sofort löschen
      vim.api.nvim_del_augroup_by_id(group)
    end,
  })


51. debugging/views/autocmds.lua:19
Events: WinEnter
Implementation:
    api.nvim_create_autocmd("WinEnter", {
      group = AUG,
      desc = "Auto-refresh debug views on WinEnter",
      callback = function()
        local win = api.nvim_get_current_win()
        local tag = display.get_window_tag(win)
        if not tag then return end

        vim.defer_fn(function()
          if api.nvim_win_is_valid(win) and api.nvim_get_current_win() == win then
            display.refresh_log_view(win, tag, timings)
          end
        end, 30)
      end,
    })


52. debugging/views/autocmds.lua:35
Events: BufWinEnter
Implementation:
    api.nvim_create_autocmd("BufWinEnter", {
      group = AUG,
      desc = "Refresh on BufWinEnter",
      callback = function(ev)
        local win = vim.fn.bufwinid(ev.buf)
        if win == -1 then return end

        local tag = display.get_window_tag(win)
        if not tag then return end

        vim.defer_fn(function()
          if api.nvim_win_is_valid(win) then
            display.refresh_log_view(win, tag, timings)
          end
        end, 30)
      end,
    })


53. debugging/views/autocmds.lua:54
Events: FileType
Implementation:
  api.nvim_create_autocmd("FileType", {
    group = AUG,
    pattern = { "messages", "noice" },
    desc = "Close debug windows with q or <Esc>",
    callback = function(ev)
      local buf = ev.buf
      if not api.nvim_buf_is_valid(buf) then return end
      if not utils.is_target_view(buf) then return end

      local function close_dbg_window()
        local win = vim.fn.bufwinid(buf)
        if win ~= -1 and api.nvim_win_is_valid(win) then
          api.nvim_win_close(win, true)
        end
      end

      vim.keymap.set("n", "q", close_dbg_window, {
        buffer = buf,
        nowait = true,
        silent = true,
        desc = "Close debug window",
      })

      vim.keymap.set("n", "<Esc>", close_dbg_window, {
        buffer = buf,
        nowait = true,
        silent = true,
        desc = "Close debug window",
      })
    end,
  })


54. lib/autocmd/init.lua:72
Events:
Implementation:
  vim.api.nvim_create_autocmd(event, {
    group = group,
    pattern = opts.pattern,
    desc = opts.desc,
    once = opts.once == true,
    nested = opts.nested == true,
    callback = callback,
  })


55. lib/ui/hover_select/window.lua:143
Events: BufLeave
Implementation:
  api.nvim_create_autocmd({ "BufLeave", "BufWipeout" }, {
    group = augroup,
    buffer = bufnr,
    callback = function()
      if api.nvim_win_is_valid(winid) then
        api.nvim_win_close(winid, true)
      end
    end,
  })


56. lib/ui/hover_select/window.lua:154
Events: WinClosed
Implementation:
  api.nvim_create_autocmd("WinClosed", {
    group = augroup,
    pattern = tostring(winid),
    callback = function()
      if api.nvim_buf_is_valid(bufnr) then
        api.nvim_buf_delete(bufnr, { force = true })
      end
    end,
  })


57. lsp/formatter/init.lua:137
Events: BufWritePre
Implementation:
    api.nvim_create_autocmd("BufWritePre", {
      group = STATE.augroup,
      callback = function(ev)
        if vim.bo[ev.buf].buftype ~= "" then
          return
        end
        -- Silent one-shot format with view preservation
        format(ev.buf)
      end,
      desc = "LSP/Conform: format current buffer on save (toggleable, preserves views)",
    })


58. lsp/languages/c.lua:9
Events: FileType
Implementation:
  vim.api.nvim_create_autocmd("FileType", {
    group = grp,
    pattern = { "c", "cpp" },
    callback = function(_) end,
  })


59. lsp/languages/csharp.lua:9
Events: FileType
Implementation:
  vim.api.nvim_create_autocmd("FileType", {
    group = grp,
    pattern = "cs",
    callback = function(_) end,
  })


60. lsp/languages/go.lua:9
Events: FileType
Implementation:
  vim.api.nvim_create_autocmd("FileType", {
    group = grp,
    pattern = "go",
    callback = function(_) end,
  })


61. lsp/languages/html.lua:10
Events: FileType
Implementation:
  vim.api.nvim_create_autocmd("FileType", {
    group = grp,
    pattern = { "html", "htmldjango", "djangohtml" },
    callback = function(event)
      -- Example small QoL: ensure omnifunc is set for legacy completion fallback
      local bufnr = event.buf
      pcall(function()
        vim.api.nvim_set_option_value("omnifunc", "v:lua.vim.lsp.omnifunc", { buf = bufnr })
      end)
    end,
  })


62. lsp/languages/lua.lua:9
Events: FileType
Implementation:
  vim.api.nvim_create_autocmd("FileType", {
    group = grp,
    pattern = "lua",
    callback = function(_) end,
  })


63. lsp/languages/markdown.lua:26
Events: FileType
Implementation:
  api.nvim_create_autocmd("FileType", {
    group = grp,
    pattern = { "markdown", "mdx" },
    callback = function(ev)
      if not (ev and ev.buf) then
        return
      end

      local bo = vim.bo[ev.buf]
      local bt = bo.buftype or ""

      local is_normal_file = (bt == "")
      local can_recode = is_normal_file and bo.modifiable

      if can_recode then
        bo.fileencoding = "utf-8"
        bo.bomb = false
      end

      bo.textwidth = 0
      bo.formatoptions = "jnql"

      M.setup_reference_hl()

      pcall(vim.keymap.set, "n", "<leader>fm", function()
        local ok, conform = pcall(require, "conform")
        if ok and type(conform.format) == "function" then
          conform.format({ bufnr = ev.buf, timeout_ms = 2000, lsp_fallback = false })
        else
          lsp.buf.format({ bufnr = ev.buf, timeout_ms = 2000 })
        end
      end, { buffer = ev.buf, silent = true, desc = desc_tag .. "Format markdown buffer" })
    end,
    desc = desc_tag .. "Markdown QoL: UTF-8 (nur bei modifizierbar), Soft-Defaults, Format-Keymap",
  })


64. lsp/languages/typescript.lua:103
Events: BufWritePre
Implementation:
  api.nvim_create_autocmd("BufWritePre", {
    group = grp,
    pattern = { "*.ts", "*.tsx", "*.js", "*.jsx" },
    callback = function(ev)
      pcall(organize_imports_sync, ev.buf)
    end,
  })


65. lsp/languages/zig.lua:9
Events: FileType
Implementation:
  vim.api.nvim_create_autocmd("FileType", {
    group = grp,
    pattern = "zig",
    callback = function(_) end,
  })


66. lsp/tools/deprecated_help/__init.lua:194
Events: LspAttach
Implementation:
  api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local bufnr = args.buf
      if not api.nvim_buf_is_valid(bufnr) then
        return
      end
      setup_buffer_mapping(bufnr, opts)
    end,
  })


67. lsp/tools/eslint_prettier/autocmds/init.lua:18
Events: BufWritePre
Implementation:
  api.nvim_create_autocmd("BufWritePre", {
    group = group,
    pattern = { "*.js", "*.cjs", "*.mjs", "*.jsx", "*.ts", "*.tsx", "*.vue", "*.svelte" },
    callback = function(ev)
      if not ctx._enabled then
        return
      end
      local ft = api.nvim_get_option_value("filetype", { buf = ev.buf })
      local allowed = false
      for _, v in ipairs(filetypes) do
        if v == ft then
          allowed = true
          break
        end
      end
      if not allowed then
        return
      end

      local root = core(ev.buf)
      -- run only if either config exists
      if check.has_eslint(root) then
        eslint_fix.eslint_fix(ev.buf)
      end
      if check.has_prettier(root) then
        prettier_fmt.prettier_format(ev.buf)
      end
    end,
  })


68. lsp/tools/lsp_signature/open_floating_preview.lua:116
Events: BufWipeout
Implementation:
  api.nvim_create_autocmd({ "BufWipeout", "BufHidden", "BufLeave", "WinClosed" }, {
    group = aug_id,
    once = true,
    buffer = bufnr,
    callback = function()
      pcall(require("lsp.tools.lsp_signature.state").close)
      pcall(api.nvim_del_augroup_by_id, aug_id)
    end,
  })


69. lsp/tools/ts_type_lookup/noice_integration.lua:54
Events: BufWinEnter
Implementation:
api.nvim_create_autocmd("BufWinEnter", {
  group = group,
  callback = function(ev)
    local bufnr = ev.buf
    if is_noice_buf(bufnr) then
      install_maps(bufnr)
    end
  end,
})


70. mappings/noice.lua:16
Events: FileType
Implementation:
  vim.api.nvim_create_autocmd("FileType", {
    group = grp,
    pattern = "noice*",
    callback = function(ev)
      local bufnr = ev.buf

      -- Scroll forward
      map({ "n", "i", "s" }, "<A-j>", function()
        if not ok2 or not noice_lsp.scroll(4) then
          return "<c-f>"
        end
      end, { buffer = bufnr, silent = true, expr = true, desc = "[Noice] LSP Scroll forward" })

      map({ "n", "i", "s" }, "<A-Down>", function()
        if not ok2 or not noice_lsp.scroll(4) then
          return "<c-f>"
        end
      end, { buffer = bufnr, silent = true, expr = true, desc = "[Noice] LSP Scroll forward" })

      -- Scroll backward
      map({ "n", "i", "s" }, "<A-k>", function()
        if not ok2 or not noice_lsp.scroll(-4) then
          return "<c-b>"
        end
      end, { buffer = bufnr, silent = true, expr = true, desc = "[Noice] LSP Scroll backward" })

      map({ "n", "i", "s" }, "<A-Up>", function()
        if not ok2 or not noice_lsp.scroll(-4) then
          return "<c-b>"
        end
      end, { buffer = bufnr, silent = true, expr = true, desc = "[Noice] LSP Scroll backward" })

      -- Dismiss UI
      map({ "n", "i" }, "<A-x>", function()
        if ok1 then
          noice.cmd("dismiss")
        end
      end, { buffer = bufnr, desc = "[Noice] Dismiss UI" })
    end,
    desc = "Set Noice buffer-local keymaps",
  })


71. options.lua:77
Events: FileType
Implementation:
  api.nvim_create_autocmd("FileType", {
    group = grp,
    pattern = { "markdown" },
    callback = function()
      opt_local.foldmethod = "expr"
      opt_local.foldexpr = "v:lua.require'custom.markdown.core.fold'.foldexpr(v:lnum)"
      opt_local.foldenable = true
      opt_local.foldlevel = 99
      opt_local.foldlevelstart = 99
    end,
    desc = "Enable lightweight markdown-specific folding only for markdown buffers",
  })


72. options.lua:157
Events: OptionSet
Implementation:
vim.api.nvim_create_autocmd("OptionSet", {
  pattern = "diff",
  callback = function()
    if vim.wo.diff then
      vim.wo.wrap = false
      vim.wo.cursorbind = false
    end
  end,
})


73. plugins/workflow.lua:123
Events: FileType
Implementation:
      vim.api.nvim_create_autocmd("FileType", {
        group = augroup,
        pattern = { "markdown", "text", "tex", "plaintex", "norg" },
        desc = "autolist.nvim: set up pre-save renumbering for this buffer",
        callback = function(ev)
          -- Buffer-local pre-save hook: renumber just before write, so the file on disk is already correct.
          vim.api.nvim_create_autocmd("BufWritePre", {
            group = augroup,
            buffer = ev.buf,
            desc = "autolist.nvim: renumber list before saving",
            callback = function()
              -- Use the user command; 'silent!' avoids noise if not applicable.
              vim.cmd([[silent! AutolistRecalculate]])
            end,
          })
        end,
      })


74. plugins/workflow.lua:129
Events: BufWritePre
Implementation:
          vim.api.nvim_create_autocmd("BufWritePre", {
            group = augroup,
            buffer = ev.buf,
            desc = "autolist.nvim: renumber list before saving",
            callback = function()
              -- Use the user command; 'silent!' avoids noise if not applicable.
              vim.cmd([[silent! AutolistRecalculate]])
            end,
          })


75. sessions/autocmds.lua:12
Events: VimEnter
Implementation:
  -- api.nvim_create_autocmd("VimEnter", {
  --   group = aug,
  --   callback = function()
  --     if vim.fn.argc(-1) == 0 then
  --       local ok, _ = require("sessions.core").load(nil)
  --       if ok then vim.notify("Session autoloaded") end
  --     end
  --   end,
  --   desc = "Portable sessions startup hook",
  --   once = true,
  -- })


76. sessions/autocmds.lua:25
Events: VimLeavePre
Implementation:
  api.nvim_create_autocmd("VimLeavePre", {
    group = aug,
    callback = function()
      require("sessions.core").save(nil)
    end,
    desc = "Portable sessions shutdown hook",
  })


77. usrcmds/reload/init.lua:122
Events:
Implementation:
vim.api.nvim_create_autocmd('BufWritePost', {
  pattern = '*.lua',
  callback = function()
    -- Nur für Dateien in lua/ Verzeichnissen
    local filepath = vim.api.nvim_buf_get_name(0)
    if filepath:match('/lua/') then
      reload_current_module()
    end
  end,
  desc = 'Auto-reload Lua modules on save',
})


78. wkddap/commands/autocmds.lua:7
Events: User
Implementation:
  vim.api.nvim_create_autocmd("User", {
    pattern = "DapUIWindowOpen",
    callback = function()
      vim.wo.cursorline = true
    end,
  })


79. wkddap/commands/autocmds.lua:15
Events: User
Implementation:
  vim.api.nvim_create_autocmd("User", {
    pattern = "DapUIWindowClose",
    callback = function()
      vim.wo.cursorline = false
    end,
  })


80. wkdnvchad/ui/statusline/modules/file_icons/devicons.lua:230
Events: ColorScheme
Implementation:
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("WkdNvChadDeviconsCache", { clear = true }),
  callback = function()
    icon_cache = require("lib.memo.lru").new(256)
    hl_cache = { name = "St_FileIcon", fg = nil, bg = nil }
  end,
  desc = "Clear devicons cache on colorscheme change",
})


81. wkdnvchad/ui/statusline/modules/formatters/init.lua:24
Events: ColorScheme
Implementation:
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("WkdNvChadFormattersCache", { clear = true }),
  callback = function()
    escape_cache = require("lib.memo.lru").new(128)
  end,
  desc = "Clear formatters cache on colorscheme change",
})


82. wkdnvchad/ui/statusline/modules/highlighting/init.lua:83
Events: ModeChanged
Implementation:
vim.api.nvim_create_autocmd("ModeChanged", {
  group = vim.api.nvim_create_augroup("WkdNvChadHighlightCache", { clear = true }),
  callback = function()
    mode_band_cache = nil
    last_mode = nil
  end,
  desc = "Clear mode band cache on mode change"
})


83. wkdnvchad/ui/statusline/modules/lsp/helpers/paths.lua:299
Events: BufDelete
Implementation:
vim.api.nvim_create_autocmd("BufDelete", {
  group = vim.api.nvim_create_augroup("WkdNvChadPathsCache", { clear = true }),
  callback = function(args)
    tick_cache[args.buf] = nil
  end,
  desc = "Clear path tick cache on buffer delete"
})


84. wkdnvchad/ui/statusline/modules/lsp/symbols/document_symbols.lua:239
Events:
Implementation:
      api.nvim_create_autocmd(ev, {
        group = aug,
        callback = function(args)
          local bufnr = args.buf or 0
          if bufnr <= 0 then
            bufnr = api.nvim_get_current_buf()
          end
          ensure_doc_symbols_in_bg(bufnr)
        end,
        desc = "Warm LSP documentSymbol cache for breadcrumbs",
      })


85. wkdnvchad/ui/statusline/modules/lsp/symbols/document_symbols.lua:402
Events: BufDelete
Implementation:
vim.api.nvim_create_autocmd("BufDelete", {
  group = vim.api.nvim_create_augroup("WkdNvChadLspSymbolsCache", { clear = true }),
  callback = function(args)
    M.__lsp_doc_cache[args.buf] = nil
    if debounce_timers[args.buf] then
      debounce_timers[args.buf]:stop()
      debounce_timers[args.buf]:close()
      debounce_timers[args.buf] = nil
    end
  end,
  desc = "Clear LSP symbols cache on buffer delete"
})


86. wkdoptions/hl_config/breadcrumbs/init.lua:80
Events: BufEnter
Implementation:
    vim.api.nvim_create_autocmd("BufEnter", {
      group = aug,
      callback = function()
        vim.wo.winbar = ""
      end,
      desc = "Clear winbar (breadcrumbs disabled)",
    })


87. wkdoptions/hl_config/breadcrumbs/init.lua:91
Events: BufEnter
Implementation:
  vim.api.nvim_create_autocmd({ "BufEnter", "CursorMoved", "WinScrolled" }, {
    group = aug,
    callback = function()
      M.refresh_with_config(cfg)
    end,
    desc = "Update breadcrumbs on movement/scroll",
  })


88. wkdoptions/hl_config/cword_occurrences/init.lua:350
Events: CursorMoved
Implementation:
  vim.api.nvim_create_autocmd({ "CursorMoved" }, {
    group = AUG,
    callback = update_debounced,
    desc = "Cword occurrences: update on movement",
  })


89. wkdoptions/hl_config/cword_occurrences/init.lua:355
Events: CursorMovedI
Implementation:
  vim.api.nvim_create_autocmd({ "CursorMovedI" }, {
    group = AUG,
    callback = update_debounced,
    desc = "Cword occurrences: update on movement (insert)",
  })


90. wkdoptions/hl_config/cword_occurrences/init.lua:360
Events: BufEnter
Implementation:
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "WinScrolled" }, {
    group = AUG,
    callback = update_now,
    desc = "Cword occurrences: update on view/window changes",
  })


91. wkdoptions/hl_config/cword_occurrences/init.lua:365
Events: TextChanged
Implementation:
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = AUG,
    callback = update_debounced,
    desc = "Cword occurrences: update on edits",
  })


92. wkdoptions/hl_config/cword_occurrences/init.lua:370
Events: BufLeave
Implementation:
  vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
    group = AUG,
    callback = clear_all,
    desc = "Cword occurrences: clear when leaving",
  })


93. wkdoptions/hl_config/cword_occurrences/init.lua:375
Events: InsertEnter
Implementation:
  vim.api.nvim_create_autocmd({ "InsertEnter" }, {
    group = AUG,
    callback = function()
      if not CC().in_insert then
        clear_all()
      end
    end,
    desc = "Cword occurrences: clear on insert (if configured)",
  })


94. wkdoptions/hl_config/features/current_word.lua:105
Events: CursorMoved
Implementation:
  vim.api.nvim_create_autocmd({ "CursorMoved" }, {
    group = aug,
    callback = M.update,
    desc = "Underline current word (window-local)",
  })


95. wkdoptions/hl_config/features/current_word.lua:111
Events: InsertEnter
Implementation:
  vim.api.nvim_create_autocmd({ "InsertEnter", "BufLeave", "WinLeave" }, {
    group = aug,
    callback = clear_match,
    desc = "Clear current-word underline",
  })


96. wkdoptions/hl_config/features/flash.lua:98
Events: TextYankPost
Implementation:
  vim.api.nvim_create_autocmd("TextYankPost", {
    group = aug,
    callback = function()
      vim.highlight.on_yank({ higroup = "YankFlash", timeout = 150, on_visual = true })
    end,
    desc = "Flash yanked text region",
  })


97. wkdoptions/hl_config/features/indent_scope.lua:228
Events: BufEnter
Implementation:
  vim.api.nvim_create_autocmd({ "BufEnter", "CursorMoved", "WinScrolled" }, {
    group = aug,
    callback = function()
      vim.schedule(function()
        M.refresh(cfg)
      end)
    end,
    desc = "Update indent scope on movement/scroll",
  })


98. wkdoptions/hl_config/features/mode_tint.lua:85
Events: ModeChanged
Implementation:
  vim.api.nvim_create_autocmd("ModeChanged", {
    group = aug,
    callback = function(ev)
      M.update(cfg, ev)
    end,
    desc = "Tint CursorLine per mode",
  })


99. wkdoptions/hl_config/features/mode_tint.lua:93
Events: BufWinEnter
Implementation:
  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = aug,
    callback = function()
      M.update(cfg, nil)
    end,
    desc = "Reapply mode tint on window enter",
  })


100. wkdoptions/hl_config/features/mode_tint.lua:101
Events: WinClosed
Implementation:
  vim.api.nvim_create_autocmd("WinClosed", {
    group = aug,
    callback = function(ev)
      local id = tonumber(ev.match)
      if id then
        M.clear_cache(id)
      end
    end,
    desc = "Purge mode-tint cache",
  })


101. wkdoptions/hl_config/features/signcolumn_tint.lua:91
Events: BufEnter
Implementation:
    vim.api.nvim_create_autocmd("BufEnter", {
      group = aug,
      callback = M.clear,
      desc = "Clear SignColumn tint (feature disabled)",
    })


102. wkdoptions/hl_config/features/signcolumn_tint.lua:99
Events: DiagnosticChanged
Implementation:
  vim.api.nvim_create_autocmd({ "DiagnosticChanged", "BufEnter" }, {
    group = aug,
    callback = M.apply,
    desc = "Tint SignColumn based on worst diagnostic",
  })


103. wkdoptions/hl_config/features/terminal_palette.lua:56
Events: TermOpen
Implementation:
  vim.api.nvim_create_autocmd("TermOpen", {
    group = aug,
    callback = M.apply,
    desc = "Apply terminal-specific palette",
  })


104. wkdoptions/hl_config/init.lua:191
Events: ColorScheme
Implementation:
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = aug,
    callback = function()
      apply_highlights()
      activate_window()
      if State.is_enabled("breadcrumbs") then
        Breadcrumbs.refresh()
      end
      if State.is_enabled("indent_scope") then
        IndentScope.refresh_current()
      end
    end,
    desc = "Re-apply highlights after colorscheme change",
  })


105. wkdoptions/hl_config/init.lua:212
Events: WinEnter
Implementation:
  vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter" }, {
    group = aug,
    callback = activate_window,
    desc = "Activate highlights for active window",
  })


106. wkdoptions/hl_config/init.lua:218
Events: WinLeave
Implementation:
  vim.api.nvim_create_autocmd({ "WinLeave" }, {
    group = aug,
    callback = deactivate_window,
    desc = "Dim highlights for inactive windows",
  })


107. wkdoptions/hl_config/init.lua:224
Events: BufReadPost
Implementation:
  vim.api.nvim_create_autocmd({ "BufReadPost", "TextChanged", "TextChangedI" }, {
    group = aug,
    callback = function()
      if vim.wo.cursorline then
        activate_window()
      end
    end,
    desc = "Re-check column highlight on size changes",
  })


108. wkdoptions/hl_config/path_cache/init.lua:99
Events: BufEnter
Implementation:
  vim.api.nvim_create_autocmd({ "BufEnter", "BufFilePost" }, {
    group = AUG_PATHCACHE,
    callback = function(args)
      M.refresh_buffer_cache(args.buf)
    end,
    desc = "Prime repo path cache per buffer",
  })


109. wkdoptions/hl_config/path_cache/init.lua:106
Events: DirChanged
Implementation:
  vim.api.nvim_create_autocmd("DirChanged", {
    group = AUG_PATHCACHE,
    callback = function()
      -- CWD changed: refresh current buffer cache
      M.refresh_buffer_cache(0)
    end,
    desc = "Refresh repo path cache on :cd/:tcd",
  })


110. wkdoptions/options_config/init.lua:99
Events: ColorScheme
Implementation:
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = AUG_OPTS,
    callback = function()
      apply_cursorline_defaults()
      apply_guicursor()
      apply_matchparen()
    end,
    desc = "Keep base options/guicursor stable across colorscheme changes",
  })


