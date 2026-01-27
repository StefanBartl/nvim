=== Autocmd Audit Report ===

Root: C:\Users\bartl\AppData\Local\nvim/lua
Total autocmds found: 112

--- Summary by Event ---
  BufDelete            : 4
  BufEnter             : 11
  BufLeave             : 2
  BufReadPost          : 3
  BufWinEnter          : 6
  BufWinLeave          : 1
  BufWipeout           : 1
  BufWritePost         : 2
  BufWritePre          : 7
  ColorScheme          : 6
  CursorHold           : 1
  CursorMoved          : 5
  CursorMovedI         : 1
  DiagnosticChanged    : 1
  DirChanged           : 1
  FileType             : 17
  InsertEnter          : 2
  LspAttach            : 1
  ModeChanged          : 3
  OptionSet            : 1
  TermOpen             : 1
  TextChanged          : 2
  TextYankPost         : 1
  User                 : 3
  VimEnter             : 6
  VimLeavePre          : 5
  WinClosed            : 3
  WinEnter             : 2
  WinLeave             : 1

--- Autocmd Details ---

[1]
    lib/autocmd/init.lua:74

[2]
    autocmds/terminals/init.lua:44

[3]
    autocmds/git/gitsigns_refresh.lua:18

[4]
    autocmds/git/conflicts_qf.lua:21

[5]
    autocmds/terminals/init.lua:78

[6]
    config/harpoon/hardening.lua:146

[7]
    usrcmds/reload/init.lua:122

[8]
    wkdnvchad/ui/statusline/modules/lsp/symbols/document_symbols.lua:239

[9]
    autocmds/general/init.lua:74

[10]
    autocmds/git/line_diff_on_hold.lua:185

[11]
    custom/insert/boilerplate/templates/nvim.lua:13

[12]
    autocmds/general/init.lua:62

[13] BufDelete
    wkdnvchad/ui/statusline/modules/lsp/symbols/document_symbols.lua:402

[14] BufDelete
    autocmds/auto-center-fexplorer.lua:149

[15] BufDelete
    config/neotree/utils/buffer.lua:126

[16] BufDelete
    wkdnvchad/ui/statusline/modules/lsp/helpers/paths.lua:299

[17] BufEnter
    config/markdown_preview/init.lua:95

[18] BufEnter
    config/markdown_preview/init.lua:67

[19] BufEnter
    config/neotree/cwd_sync/init.lua:301

[20] BufEnter
    wkdoptions/hl_config/path_cache/init.lua:99

[21] BufEnter
    config/neotree/current_hl/init.lua:256

[22] BufEnter
    wkdoptions/hl_config/breadcrumbs/init.lua:80

[23] BufEnter
    wkdoptions/hl_config/cword_occurrences/init.lua:355

[24] BufEnter
    wkdoptions/hl_config/features/indent_scope.lua:228

[25] BufEnter
    wkdoptions/hl_config/features/signcolumn_tint.lua:91

[26] BufEnter
    config/neotest/core/init.lua:62

[27] BufEnter
    wkdoptions/hl_config/breadcrumbs/init.lua:91

[28] BufLeave
    lib/ui/hover_select/window.lua:143

[29] BufLeave
    wkdoptions/hl_config/cword_occurrences/init.lua:365

[30] BufReadPost
    autocmds/general/init.lua:86

[31] BufReadPost
    autocmds/text/init.lua:132

[32] BufReadPost
    wkdoptions/hl_config/init.lua:224

[33] BufWinEnter
    lsp/tools/ts_type_lookup/noice_integration.lua:54

[34] BufWinEnter
    config/snacks/custom_dashboard/autocmds.lua:66

[35] BufWinEnter
    config/snacks/___dashboard/autocmds.lua:70

[36] BufWinEnter
    debugging/views/autocmds.lua:35

[37] BufWinEnter
    autocmds/git/conflict_marks.lua:17

[38] BufWinEnter
    wkdoptions/hl_config/features/mode_tint.lua:93

[39] BufWinLeave
    autocmds/git/conflict_marks.lua:28

[40] BufWipeout
    lsp/tools/lsp_signature/open_floating_preview.lua:116

[41] BufWritePost
    autocmds/benchmarks/context/cache.lua:161

[42] BufWritePost
    custom/markdown/tableview/live.lua:178

[43] BufWritePre
    lsp/languages/typescript.lua:99

[44] BufWritePre
    lsp/tools/eslint_prettier/autocmds/init.lua:18

[45] BufWritePre
    lsp/formatter/init.lua:137

[46] BufWritePre
    autocmds/general/init.lua:23

[47] BufWritePre
    autocmds/text/init.lua:67

[48] BufWritePre
    autocmds/text/init.lua:96

[49] BufWritePre
    plugins/workflow.lua:129

[50] ColorScheme
    wkdoptions/hl_config/init.lua:191

[51] ColorScheme
    wkdnvchad/ui/statusline/modules/file_icons/devicons.lua:230

[52] ColorScheme
    wkdnvchad/ui/statusline/modules/formatters/init.lua:24

[53] ColorScheme
    wkdoptions/options_config/init.lua:96

[54] ColorScheme
    custom/markdown/fenced_fix/init.lua:160

[55] ColorScheme
    config/neotree/current_hl/init.lua:181

[56] CursorHold
    autocmds/git/blame_on_hold.lua:17

[57] CursorMoved
    wkdoptions/hl_config/features/current_word.lua:105

[58] CursorMoved
    wkdoptions/hl_config/cword_occurrences/init.lua:345

[59] CursorMoved
    autocmds/git/line_diff_on_hold.lua:251

[60] CursorMoved
    autocmds/auto-center-fexplorer.lua:137

[61] CursorMoved
    autocmds/git/line_diff_on_hold.lua:282

[62] CursorMovedI
    wkdoptions/hl_config/cword_occurrences/init.lua:350

[63] DiagnosticChanged
    wkdoptions/hl_config/features/signcolumn_tint.lua:99

[64] DirChanged
    wkdoptions/hl_config/path_cache/init.lua:106

[65] FileType
    lsp/languages/csharp.lua:9

[66] FileType
    config/neotree/cwd_sync/disable_follow.lua:29

[67] FileType
    plugins/workflow.lua:123

[68] FileType
    autocmds/git/commit_ft.lua:18

[69] FileType
    custom/markdown/tableview/autocmds.lua:14

[70] FileType
    autocmds/auto-center-fexplorer.lua:187

[71] FileType
    debugging/views/autocmds.lua:54

[72] FileType
    lsp/languages/go.lua:9

[73] FileType
    custom/markdown/setup/autocmds.lua:59

[74] FileType
    options.lua:77

[75] FileType
    lsp/languages/markdown.lua:26

[76] FileType
    lsp/languages/zig.lua:9

[77] FileType
    mappings/noice.lua:16

[78] FileType
    custom/markdown/setup/autocmds.lua:21

[79] FileType
    lsp/languages/lua.lua:9

[80] FileType
    lsp/languages/c.lua:9

[81] FileType
    lsp/languages/html.lua:10

[82] InsertEnter
    wkdoptions/hl_config/cword_occurrences/init.lua:370

[83] InsertEnter
    wkdoptions/hl_config/features/current_word.lua:111

[84] LspAttach
    lsp/tools/deprecated_help/__init.lua:203

[85] ModeChanged
    wkdoptions/hl_config/features/mode_tint.lua:85

[86] ModeChanged
    wkdnvchad/ui/statusline/modules/highlighting/init.lua:83

[87] ModeChanged
    autocmds/git/line_diff_on_hold.lua:304

[88] OptionSet
    options.lua:157

[89] TermOpen
    wkdoptions/hl_config/features/terminal_palette.lua:56

[90] TextChanged
    autocmds/benchmarks/context/cache.lua:136

[91] TextChanged
    wkdoptions/hl_config/cword_occurrences/init.lua:360

[92] TextYankPost
    wkdoptions/hl_config/features/flash.lua:98

[93] User
    config/neotest/core/init.lua:79

[94] User
    wkddap/commands/autocmds.lua:15

[95] User
    wkddap/commands/autocmds.lua:7

[96] VimEnter
    config/snacks/custom_dashboard/autocmds.lua:18

[97] VimEnter
    sessions/autocmds.lua:12

[98] VimEnter
    autocmds/terminals/init.lua:63

[99] VimEnter
    autocmds/general/init.lua:43

[100] VimEnter
    config/harpoon/persist_paths.lua:188

[101] VimEnter
    config/snacks/___dashboard/autocmds.lua:12

[102] VimLeavePre
    config/neotree/cwd_sync/init.lua:309

[103] VimLeavePre
    autocmds/terminals/init.lua:68

[104] VimLeavePre
    autocmds/general/init.lua:50

[105] VimLeavePre
    sessions/autocmds.lua:25

[106] VimLeavePre
    config/harpoon/hardening.lua:155

[107] WinClosed
    lib/ui/hover_select/window.lua:154

[108] WinClosed
    wkdoptions/hl_config/features/mode_tint.lua:101

[109] WinClosed
    custom/recommender/autocmds.lua:13

[110] WinEnter
    debugging/views/autocmds.lua:19

[111] WinEnter
    wkdoptions/hl_config/init.lua:212

[112] WinLeave
    wkdoptions/hl_config/init.lua:218


