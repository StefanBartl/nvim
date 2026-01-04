Initializing ...                                                                                >=================== 001/694                                                                                [34mlua\@types\vim_uv.lua:236:47[0m [[33mWarning[0m] Undefined type or alias `err`. [35m(undefined-doc-name)[0m
    ---@return uv.uv_process_t?, string? process, err
    [90m                                              ^^^[0m
[34mlua\@types\vim_uv.lua:246:11[0m [[33mWarning[0m] Undefined param `fd`. [35m(undefined-doc-param)[0m
    ---@param fd integer File descriptor
    [90m          ^^[0m
[34mlua\@types\vim_uv.lua:247:11[0m [[33mWarning[0m] Undefined param `enable`. [35m(undefined-doc-param)[0m
    ---@param enable boolean
    [90m          ^^^^^^[0m
                                                                                [34mlua\@types\vim_uv.lua:246:11[0m [[33mWarning[0m] Undefined param `fd`. [35m(undefined-doc-param)[0m
    ---@param fd integer File descriptor
    [90m          ^^[0m
[34mlua\@types\vim_uv.lua:247:11[0m [[33mWarning[0m] Undefined param `enable`. [35m(undefined-doc-param)[0m
    ---@param enable boolean
    [90m          ^^^^^^[0m
[34mlua\@types\vim_uv.lua:236:47[0m [[33mWarning[0m] Undefined type or alias `err`. [35m(undefined-doc-name)[0m
    ---@return uv.uv_process_t?, string? process, err
    [90m                                              ^^^[0m
                                                                                [34mlua\autocmds\general\gofile_case_dispatcher\init.lua:98:38[0m [[33mWarning[0m] Cannot assign `TSNode|nil` to parameter `userdata|nil`.
- `TSNode` cannot match `userdata|nil`
- `TSNode` cannot match any subtypes in `userdata|nil`
- Type `TSNode` cannot match `nil`
- Type `TSNode` cannot match `userdata` [35m(param-type-mismatch)[0m
          local handled = local_mod.call(node, bufnr, cfg, ts_utils, logger, normalized)
    [90m                                     ^^^^[0m
[34mlua\autocmds\general\gofile_case_dispatcher\init.lua:140:38[0m [[33mWarning[0m] Cannot assign `TSNode|nil` to parameter `userdata|nil`.
- `TSNode` cannot match `userdata|nil`
- `TSNode` cannot match any subtypes in `userdata|nil`
- Type `TSNode` cannot match `nil`
- Type `TSNode` cannot match `userdata` [35m(param-type-mismatch)[0m
          local handled = local_mod.call(node, bufnr, cfg, ts_utils, logger, normalized)
    [90m                                     ^^^^[0m
                                                                                >=================== 015/694 [Found 5 problems in 2 files]                                                                                >=================== 034/694 [Found 5 problems in 2 files]                                                                                >>================== 045/694 [Found 5 problems in 2 files]                                                                                [34mlua\autocmds\patches\usercommands.lua:339:25[0m [[33mWarning[0m] Cannot assign `string` to parameter `integer`.
- `string` cannot match `integer`
- Type `string` cannot match `integer` [35m(param-type-mismatch)[0m
          tbl_insert(lines, line:gsub("%s+$", ""))
    [90m                        ^^^^^^^^^^^^^^^^^^^^^[0m
                                                                                [34mlua\autocmds\patches\validate.lua:136:20[0m [[33mWarning[0m] Cannot assign `uv.uv_handle_t` to `integer|uv.uv_pipe_t|nil`.
- `uv.uv_handle_t` cannot match `integer|uv.uv_pipe_t|nil`
- `uv.uv_handle_t` cannot match any subtypes in `integer|uv.uv_pipe_t|nil`
- Type `uv.uv_handle_t` cannot match `nil`
- Type `uv.uv_handle_t` cannot match `integer`
- Type `uv.uv_handle_t` cannot match `uv.uv_pipe_t` [35m(assign-type-mismatch)[0m
        stdio = { nil, stdout, stderr },
    [90m                   ^^^^^^[0m
[34mlua\autocmds\patches\validate.lua:136:28[0m [[33mWarning[0m] Cannot assign `uv.uv_handle_t` to `integer|uv.uv_pipe_t|nil`.
- `uv.uv_handle_t` cannot match `integer|uv.uv_pipe_t|nil`
- `uv.uv_handle_t` cannot match any subtypes in `integer|uv.uv_pipe_t|nil`
- Type `uv.uv_handle_t` cannot match `nil`
- Type `uv.uv_handle_t` cannot match `integer`
- Type `uv.uv_handle_t` cannot match `uv.uv_pipe_t` [35m(assign-type-mismatch)[0m
        stdio = { nil, stdout, stderr },
    [90m                           ^^^^^^[0m
                                                                                >>================== 052/694 [Found 8 problems in 4 files]                                                                                >>>================= 070/694 [Found 8 problems in 4 files]                                                                                >>>================= 075/694 [Found 8 problems in 4 files]                                                                                >>>================= 087/694 [Found 8 problems in 4 files]                                                                                >>>================= 102/694 [Found 8 problems in 4 files]                                                                                [34mlua\config\neotest\debug\init.lua:19:5[0m [[33mWarning[0m] Need check nil. [35m(need-check-nil)[0m
        info("Forcing test discovery...")
    [90m    ^^^^[0m
[34mlua\config\neotest\debug\init.lua:39:5[0m [[33mWarning[0m] Need check nil. [35m(need-check-nil)[0m
        info(msg)
    [90m    ^^^^[0m
[34mlua\config\neotest\debug\init.lua:59:5[0m [[33mWarning[0m] Need check nil. [35m(need-check-nil)[0m
        info(table.concat(lines, "\n"))
    [90m    ^^^^[0m
[34mlua\config\neotest\debug\init.lua:82:5[0m [[33mWarning[0m] Need check nil. [35m(need-check-nil)[0m
        info(table.concat(lines, "\n"))
    [90m    ^^^^[0m
[34mlua\config\neotest\debug\init.lua:49:7[0m [[33mWarning[0m] Need check nil. [35m(need-check-nil)[0m
          warn("No adapters configured")
    [90m      ^^^^[0m
[34mlua\config\neotest\debug\init.lua:65:7[0m [[33mWarning[0m] Need check nil. [35m(need-check-nil)[0m
          warn("No test tree available")
    [90m      ^^^^[0m
[34mlua\config\neotest\debug\init.lua:23:9[0m [[33mWarning[0m] Need check nil. [35m(need-check-nil)[0m
            info("Tests found: " .. vim.tbl_count(tree))
    [90m        ^^^^[0m
[34mlua\config\neotest\debug\init.lua:25:9[0m [[33mWarning[0m] Need check nil. [35m(need-check-nil)[0m
            warn("No tests discovered")
    [90m        ^^^^[0m
                                                                                >>>>================ 118/694 [Found 16 problems in 5 files]                                                                                [34mlua\config\neotree\current_hl\init.lua:132:20[0m [[33mWarning[0m] Undefined field `timer_stop`. [35m(undefined-field)[0m
          pcall(vim.uv.timer_stop, S.timer)
    [90m                   ^^^^^^^^^^[0m
                                                                                >>>>================ 130/694 [Found 17 problems in 6 files]                                                                                >>>>>=============== 145/694 [Found 17 problems in 6 files]                                                                                >>>>>=============== 153/694 [Found 17 problems in 6 files]                                                                                [34mlua\config\neotree\trash\init.lua:146:23[0m [[33mWarning[0m] Undefined field `os_homedir`. [35m(undefined-field)[0m
          local home = uv.os_homedir()
    [90m                      ^^^^^^^^^^[0m
                                                                                >>>>>=============== 165/694 [Found 18 problems in 7 files]                                                                                [34mlua\config\neotree\undo\init.lua:142:19[0m [[33mWarning[0m] Undefined field `os_homedir`. [35m(undefined-field)[0m
      local home = uv.os_homedir()
    [90m                  ^^^^^^^^^^[0m
                                                                                >>>>>>============== 181/694 [Found 19 problems in 8 files]                                                                                >>>>>>============== 198/694 [Found 19 problems in 8 files]                                                                                >>>>>>>============= 215/694 [Found 19 problems in 8 files]                                                                                >>>>>>>============= 220/694 [Found 19 problems in 8 files]                                                                                [34mlua\custom\init.lua:9:40[0m [[33mWarning[0m] Missing required fields in type `FunctionIndexConfig`: `enable_keymaps`, `keymaps`, `default_scope` [35m(missing-fields)[0m
    require("custom.function_index").setup({
    [90m                                       ^[0m
                                                                                >>>>>>>============= 228/694 [Found 20 problems in 9 files]                                                                                [34mlua\custom\lua_project_file_stats\init.lua:86:9[0m [[33mWarning[0m] Cannot assign `LuaProjectFileStats.Stats` to `LuaProjectFileStats.FolderStats`.
- `LuaProjectFileStats.Stats` cannot match `LuaProjectFileStats.FolderStats`
- Type `LuaProjectFileStats.Stats` cannot match `LuaProjectFileStats.FolderStats` [35m(assign-type-mismatch)[0m
            state.folder_summary[folder] = utils.create_empty_stats()
    [90m        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^[0m
                                                                                >>>>>>>============= 233/694 [Found 21 problems in 10 files]                                                                                [34mlua\custom\markdown\codeblock_formatter\run\async_worker.lua:449:10[0m [[33mWarning[0m] Duplicate field `format_blocks_async`. [35m(duplicate-set-field)[0m
    function M.format_blocks_async(bufnr, sline, eline, opts)
    [90m         ^^^^^^^^^^^^^^^^^^^^^[0m
[34mlua\custom\markdown\codeblock_formatter\run\async_worker.lua:626:10[0m [[33mWarning[0m] Duplicate field `format_buffer_async`. [35m(duplicate-set-field)[0m
    function M.format_buffer_async()
    [90m         ^^^^^^^^^^^^^^^^^^^^^[0m
[34mlua\custom\markdown\codeblock_formatter\run\async_worker.lua:631:10[0m [[33mWarning[0m] Duplicate field `format_range_async`. [35m(duplicate-set-field)[0m
    function M.format_range_async(sline, eline)
    [90m         ^^^^^^^^^^^^^^^^^^^^[0m
                                                                                >>>>>>>>============ 245/694 [Found 24 problems in 11 files]                                                                                [34mlua\custom\markdown\codeblock_formatter2\init.lua:332:7[0m [[33mWarning[0m] Need check nil. [35m(need-check-nil)[0m
          handle:close()
    [90m      ^^^^^^[0m
                                                                                >>>>>>>>============ 255/694 [Found 25 problems in 12 files]                                                                                >>>>>>>>============ 264/694 [Found 25 problems in 12 files]                                                                                [34mlua\custom\markdown\init.lua:26:25[0m [[33mWarning[0m] Undefined field `increase`. [35m(undefined-field)[0m
    M.shift_increase = head.increase
    [90m                        ^^^^^^^^[0m
[34mlua\custom\markdown\init.lua:27:25[0m [[33mWarning[0m] Undefined field `decrease`. [35m(undefined-field)[0m
    M.shift_decrease = head.decrease
    [90m                        ^^^^^^^^[0m
[34mlua\custom\markdown\init.lua:33:17[0m [[33mWarning[0m] Missing required fields in type `CodeblockFormatterConfig`: `notify_level`, `prefer_treesitter`, `ts_block_node` [35m(missing-fields)[0m
    formatter.setup({
    [90m                ^[0m
[34mlua\custom\markdown\init.lua:79:10[0m [[33mWarning[0m] Missing required fields in type `UIMarkdownFencedFixOpts`: `enable_legacy`, `enable_ts` [35m(missing-fields)[0m
      .setup({
    [90m         ^[0m
                                                                                [34mlua\custom\markdown\setup\keymaps.lua:105:20[0m [[33mWarning[0m] Cannot assign `integer|nil` to parameter `integer`.
- `nil` cannot match `integer`
- Type `nil` cannot match `integer` [35m(param-type-mismatch)[0m
      wrap_link.attach(bufnr)
    [90m                   ^^^^^[0m
                                                                                >>>>>>>>============ 273/694 [Found 30 problems in 14 files]                                                                                >>>>>>>>>=========== 284/694 [Found 30 problems in 14 files]                                                                                >>>>>>>>>=========== 303/694 [Found 30 problems in 14 files]                                                                                >>>>>>>>>>========== 315/694 [Found 30 problems in 14 files]                                                                                >>>>>>>>>>========== 328/694 [Found 30 problems in 14 files]                                                                                [34mlua\custom\repo_pickers\select\router.lua:99:34[0m [[33mWarning[0m] This function expects a maximum of 3 argument(s) but instead it is receiving 4. [35m(redundant-parameter)[0m
            sel_vim.select(c, w, cb, "Select WkdBook")
    [90m                                 ^^^^^^^^^^^^^^^^[0m
[34mlua\custom\repo_pickers\select\router.lua:196:34[0m [[33mWarning[0m] This function expects a maximum of 3 argument(s) but instead it is receiving 4. [35m(redundant-parameter)[0m
            sel_vim.select(c, w, cb, "Select WkdBook")
    [90m                                 ^^^^^^^^^^^^^^^^[0m
[34mlua\custom\repo_pickers\select\router.lua:111:44[0m [[33mWarning[0m] This function expects a maximum of 3 argument(s) but instead it is receiving 4. [35m(redundant-parameter)[0m
            handled = sel_tel.select(c, w, cb, "WkdBooks")
    [90m                                           ^^^^^^^^^^[0m
[34mlua\custom\repo_pickers\select\router.lua:117:36[0m [[33mWarning[0m] This function expects a maximum of 3 argument(s) but instead it is receiving 4. [35m(redundant-parameter)[0m
              sel_vim.select(c, w, cb, "Select WkdBook")
    [90m                                   ^^^^^^^^^^^^^^^^[0m
[34mlua\custom\repo_pickers\select\router.lua:128:44[0m [[33mWarning[0m] This function expects a maximum of 3 argument(s) but instead it is receiving 4. [35m(redundant-parameter)[0m
            handled = sel_fzf.select(c, w, cb, "WkdBooks> ")
    [90m                                           ^^^^^^^^^^^^[0m
[34mlua\custom\repo_pickers\select\router.lua:134:36[0m [[33mWarning[0m] This function expects a maximum of 3 argument(s) but instead it is receiving 4. [35m(redundant-parameter)[0m
              sel_vim.select(c, w, cb, "Select WkdBook")
    [90m                                   ^^^^^^^^^^^^^^^^[0m
[34mlua\custom\repo_pickers\select\router.lua:147:44[0m [[33mWarning[0m] This function expects a maximum of 3 argument(s) but instead it is receiving 4. [35m(redundant-parameter)[0m
            handled = sel_tel.select(c, w, cb, "WkdBooks")
    [90m                                           ^^^^^^^^^^[0m
[34mlua\custom\repo_pickers\select\router.lua:153:36[0m [[33mWarning[0m] This function expects a maximum of 3 argument(s) but instead it is receiving 4. [35m(redundant-parameter)[0m
              sel_vim.select(c, w, cb, "Select WkdBook")
    [90m                                   ^^^^^^^^^^^^^^^^[0m
[34mlua\custom\repo_pickers\select\router.lua:163:44[0m [[33mWarning[0m] This function expects a maximum of 3 argument(s) but instead it is receiving 4. [35m(redundant-parameter)[0m
            handled = sel_fzf.select(c, w, cb, "WkdBooks> ")
    [90m                                           ^^^^^^^^^^^^[0m
[34mlua\custom\repo_pickers\select\router.lua:169:36[0m [[33mWarning[0m] This function expects a maximum of 3 argument(s) but instead it is receiving 4. [35m(redundant-parameter)[0m
              sel_vim.select(c, w, cb, "Select WkdBook")
    [90m                                   ^^^^^^^^^^^^^^^^[0m
[34mlua\custom\repo_pickers\select\router.lua:180:44[0m [[33mWarning[0m] This function expects a maximum of 3 argument(s) but instead it is receiving 4. [35m(redundant-parameter)[0m
            handled = sel_fzf.select(c, w, cb, "WkdBooks> ")
    [90m                                           ^^^^^^^^^^^^[0m
[34mlua\custom\repo_pickers\select\router.lua:188:44[0m [[33mWarning[0m] This function expects a maximum of 3 argument(s) but instead it is receiving 4. [35m(redundant-parameter)[0m
            handled = sel_tel.select(c, w, cb, "WkdBooks")
    [90m                                           ^^^^^^^^^^[0m
                                                                                >>>>>>>>>>========== 338/694 [Found 42 problems in 15 files]                                                                                >>>>>>>>>>>========= 352/694 [Found 42 problems in 15 files]                                                                                [34mlua\debugging\views\capture.lua:21:16[0m [[33mWarning[0m] Need check nil. [35m(need-check-nil)[0m
      local sys = (uname.sysname or ""):lower()
    [90m               ^^^^^[0m
[34mlua\debugging\views\capture.lua:22:16[0m [[33mWarning[0m] Need check nil. [35m(need-check-nil)[0m
      local rel = (uname.release or ""):lower()
    [90m               ^^^^^[0m
                                                                                >>>>>>>>>>>========= 363/694 [Found 44 problems in 16 files]                                                                                [34mlua\lib\buf_win_tab\capture\init.lua:111:13[0m [[33mWarning[0m] Undefined field `is_closing`. [35m(undefined-field)[0m
      if not uv.is_closing(t) then
    [90m            ^^^^^^^^^^[0m
                                                                                >>>>>>>>>>>>======== 386/694 [Found 45 problems in 17 files]                                                                                [34mlua\lib\hover_select\docs\v3-EXAMPLE-CONFIG-MULTISELECT.lua:77:29[0m [[33mWarning[0m] Cannot assign `string|string[]` to parameter `<T:table>`.
- `string` cannot match `table`
- Type `string` cannot match `table` [35m(param-type-mismatch)[0m
          for _, file in ipairs(selected_files) do
    [90m                            ^^^^^^^^^^^^^^[0m
[34mlua\lib\hover_select\docs\v3-EXAMPLE-CONFIG-MULTISELECT.lua:110:34[0m [[33mWarning[0m] Cannot assign `string|string[]` to parameter `<T:table>`.
- `string` cannot match `table`
- Type `string` cannot match `table` [35m(param-type-mismatch)[0m
          for _, selection in ipairs(selections) do
    [90m                                 ^^^^^^^^^^[0m
[34mlua\lib\hover_select\docs\v3-EXAMPLE-CONFIG-MULTISELECT.lua:47:31[0m [[33mWarning[0m] Cannot assign `string|string[]` to parameter `<T:table>`.
- `string` cannot match `table`
- Type `string` cannot match `table` [35m(param-type-mismatch)[0m
            for i, task in ipairs(selected) do
    [90m                              ^^^^^^^^[0m
[34mlua\lib\hover_select\docs\v3-EXAMPLE-CONFIG-MULTISELECT.lua:151:24[0m [[33mWarning[0m] Cannot assign `string|string[]` to parameter `table`.
- `string` cannot match `table`
- Type `string` cannot match `table` [35m(param-type-mismatch)[0m
              table.concat(selected, "\n")
    [90m                       ^^^^^^^^[0m
                                                                                [34mlua\lib\hover_select\init.lua:78:13[0m [[33mWarning[0m] This function requires 4 argument(s) but instead it is receiving 3. [35m(missing-parameter)[0m
        winid = window.create(bufnr, win_config, merged_win_opts)
    [90m            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^[0m
[34mlua\lib\hover_select\init.lua:75:15[0m [[33mWarning[0m] This function requires 4 argument(s) but instead it is receiving 3. [35m(missing-parameter)[0m
          winid = window.create(bufnr, win_config, merged_win_opts)
    [90m              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^[0m
                                                                                [34mlua\lib\hover_select\quicktest.lua:34:29[0m [[33mWarning[0m] Cannot assign `string|string[]` to parameter `<T:table>`.
- `string` cannot match `table`
- Type `string` cannot match `table` [35m(param-type-mismatch)[0m
          for i, item in ipairs(selected) do
    [90m                            ^^^^^^^^[0m
                                                                                [34mlua\lib\hover_select\test_multiselect.lua:49:29[0m [[33mWarning[0m] Cannot assign `string|string[]` to parameter `<T:table>`.
- `string` cannot match `table`
- Type `string` cannot match `table` [35m(param-type-mismatch)[0m
          for i, item in ipairs(selected) do
    [90m                            ^^^^^^^^[0m
[34mlua\lib\hover_select\test_multiselect.lua:121:29[0m [[33mWarning[0m] Cannot assign `string|string[]` to parameter `<T:table>`.
- `string` cannot match `table`
- Type `string` cannot match `table` [35m(param-type-mismatch)[0m
          for _, file in ipairs(selected) do
    [90m                            ^^^^^^^^[0m
[34mlua\lib\hover_select\test_multiselect.lua:72:72[0m [[33mWarning[0m] Cannot assign `string|string[]` to parameter `table`.
- `string` cannot match `table`
- Type `string` cannot match `table` [35m(param-type-mismatch)[0m
            string.format("Selected %d items: %s", #selected, table.concat(selected, ", ")),
    [90m                                                                       ^^^^^^^^[0m
                                                                                >>>>>>>>>>>>======== 399/694 [Found 55 problems in 21 files]                                                                                >>>>>>>>>>>>======== 407/694 [Found 55 problems in 21 files]                                                                                >>>>>>>>>>>>>======= 427/694 [Found 55 problems in 21 files]                                                                                >>>>>>>>>>>>>>====== 457/694 [Found 55 problems in 21 files]                                                                                >>>>>>>>>>>>>>====== 469/694 [Found 55 problems in 21 files]                                                                                >>>>>>>>>>>>>>====== 484/694 [Found 55 problems in 21 files]                                                                                >>>>>>>>>>>>>>>===== 500/694 [Found 55 problems in 21 files]                                                                                >>>>>>>>>>>>>>>===== 514/694 [Found 55 problems in 21 files]                                                                                >>>>>>>>>>>>>>>>==== 523/694 [Found 55 problems in 21 files]                                                                                >>>>>>>>>>>>>>>>==== 533/694 [Found 55 problems in 21 files]                                                                                >>>>>>>>>>>>>>>>==== 540/694 [Found 55 problems in 21 files]                                                                                >>>>>>>>>>>>>>>>==== 548/694 [Found 55 problems in 21 files]                                                                                >>>>>>>>>>>>>>>>>=== 565/694 [Found 55 problems in 21 files]                                                                                >>>>>>>>>>>>>>>>>=== 569/694 [Found 55 problems in 21 files]                                                                                >>>>>>>>>>>>>>>>>=== 583/694 [Found 55 problems in 21 files]                                                                                >>>>>>>>>>>>>>>>>=== 589/694 [Found 55 problems in 21 files]                                                                                >>>>>>>>>>>>>>>>>>== 605/694 [Found 55 problems in 21 files]                                                                                >>>>>>>>>>>>>>>>>>== 623/694 [Found 55 problems in 21 files]                                                                                [34mlua\usrcmds\gather\lua\confirm.lua:121:20[0m [[33mWarning[0m] Cannot assign `string|string[]` to parameter `string|number`.
- `string[]` cannot match `string|number`
- `string[]` cannot match any subtypes in `string|number`
- Type `string[]` cannot match `number`
- Type `string[]` cannot match `string` [35m(param-type-mismatch)[0m
            if selected:match("^✓") then
    [90m                   ^[0m
                                                                                >>>>>>>>>>>>>>>>>>>= 639/694 [Found 56 problems in 22 files]                                                                                [34mlua\usrcmds\gather\lua\init.lua:109:13[0m [[33mWarning[0m] Cannot assign `string|string[]` to `"functions"|"strings"|"tables"`.
- `string[]` cannot match `"functions"|"strings"|"tables"`
- `string[]` cannot match any subtypes in `"functions"|"strings"|"tables"`
- Type `string[]` cannot match `"strings"`
- Type `string[]` cannot match `"tables"`
- Type `string[]` cannot match `"functions"` [35m(assign-type-mismatch)[0m
          local gather_type = selected
    [90m            ^^^^^^^^^^^[0m
                                                                                >>>>>>>>>>>>>>>>>>>= 647/694 [Found 57 problems in 23 files]                                                                                >>>>>>>>>>>>>>>>>>>= 652/694 [Found 57 problems in 23 files]                                                                                >>>>>>>>>>>>>>>>>>>= 659/694 [Found 57 problems in 23 files]                                                                                [34mlua\usrcmds\mymessages\init.lua:24:16[0m [[33mWarning[0m] Need check nil. [35m(need-check-nil)[0m
      local sys = (uname.sysname or ""):lower()
    [90m               ^^^^^[0m
[34mlua\usrcmds\mymessages\init.lua:25:16[0m [[33mWarning[0m] Need check nil. [35m(need-check-nil)[0m
      local rel = (uname.release or ""):lower()
    [90m               ^^^^^[0m
                                                                                >>>>>>>>>>>>>>>>>>>> 672/694 [Found 59 problems in 24 files]                                                                                [34mlua\usrcmds\update_repos\init.lua:150:3[0m [[33mWarning[0m] Need check nil. [35m(need-check-nil)[0m
      info("Updating repositories asynchronously...")
    [90m  ^^^^[0m
[34mlua\usrcmds\update_repos\init.lua:105:5[0m [[33mWarning[0m] Need check nil. [35m(need-check-nil)[0m
        error("No repository directory provided and REPOS_DIR is not set")
    [90m    ^^^^^[0m
[34mlua\usrcmds\update_repos\init.lua:111:5[0m [[33mWarning[0m] Need check nil. [35m(need-check-nil)[0m
        error("Repository directory is not accessible: " .. base_dir)
    [90m    ^^^^^[0m
[34mlua\usrcmds\update_repos\init.lua:118:5[0m [[33mWarning[0m] Need check nil. [35m(need-check-nil)[0m
        info("No git repositories found in " .. base_dir)
    [90m    ^^^^[0m
[34mlua\usrcmds\update_repos\init.lua:131:11[0m [[33mWarning[0m] Need check nil. [35m(need-check-nil)[0m
              error("Repository update finished with errors:\n\n" .. table.concat(errors, "\n\n"))
    [90m          ^^^^^[0m
[34mlua\usrcmds\update_repos\init.lua:133:11[0m [[33mWarning[0m] Need check nil. [35m(need-check-nil)[0m
              info("All repositories updated successfully")
    [90m          ^^^^[0m
                                                                                >>>>>>>>>>>>>>>>>>>> 688/694 [Found 65 problems in 25 files]                                                                                >>>>>>>>>>>>>>>>>>>> 694/694 [Found 65 problems in 25 files]                                                                                Diagnosis complete, 65 problems found
