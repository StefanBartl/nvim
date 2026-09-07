# Bindings — runtime checklist

Generated, not hand-written -- work through it in a real session: trigger
each one yourself, tick it if it does what its description says, leave a
note here if it does not. Nothing on this list was invoked by the
generator to build it -- see `bindings.audit.checklist_lines`'s doc
comment for why.

Checkbox convention: `- [ ]` open, `- [x]` verified.

## Keymaps

### Debug

- [ ] `<lt>c` -- Debug: Capture to file+clipboard
- [ ] `<lt>y` -- Debug: Capture to clipboard only
- [ ] `<lt>f` -- Debug: Capture to file only
- [ ] `<lt>x` -- Debug: Clear all windows
- [ ] `<lt>m` -- Debug: Messages view
- [ ] `<lt>n` -- Debug: Noice all
- [ ] `<lt>e` -- Debug: Noice errors

### LSP

- [ ] `lsa` -- LSP: Code action
- [ ] `]d` -- LSP: Next diagnostic (buffer)
- [ ] `[d` -- LSP: Prev diagnostic (buffer)
- [ ] `<leader>tq` -- LSP: Diagnostics -> quickfix (plain)
- [ ] `<leader>lq` -- LSP: Diagnostics -> loclist (buffer)
- [ ] `<leader>wq` -- LSP: Diagnostics -> quickfix (workspace)
- [ ] `lss` -- LSP: Document symbols
- [ ] `<leader>ft` -- LSP: Format buffer once
- [ ] `<leader>fl` -- LSP: Format via the language server directly
- [ ] `<leader>tft` -- LSP: Toggle format-on-save
- [ ] `lsD` -- LSP: Go to declaration
- [ ] `lsd` -- LSP: Go to definition
- [ ] `lsi` -- LSP: List implementations
- [ ] `lsr` -- LSP: List references
- [ ] `lst` -- LSP: Go to type definition
- [ ] `grt` -- LSP: Go to type definition (g-prefix variant)
- [ ] `<leader>th` -- LSP: Toggle inlay hints (global)
- [ ] `<leader>tH` -- LSP: Toggle inlay hints for this filetype
- [ ] `<leader>tb` -- LSP: Toggle the code-action indicator (global)
- [ ] `<leader>tB` -- LSP: Toggle the code-action indicator for this filetype
- [ ] `]l` -- LSP: Next location-list entry
- [ ] `[l` -- LSP: Prev location-list entry
- [ ] `<leader>lb` -- LSP: Toggle Marksman markdown hints
- [ ] `<leader>do` -- LSP: Picker: document diagnostics
- [ ] `<leader>dos` -- LSP: Picker: document symbols
- [ ] `lsc` -- LSP: Picker: incoming calls (who calls this)
- [ ] `lsC` -- LSP: Picker: outgoing calls (what this calls)
- [ ] `<leader>wo` -- LSP: Picker: workspace diagnostics
- [ ] `<leader>wos` -- LSP: Picker: workspace symbols (live)
- [ ] `]q` -- LSP: Next quickfix entry
- [ ] `[q` -- LSP: Prev quickfix entry
- [ ] `grn` -- LSP: Rename symbol
- [ ] `<leader>rn` -- LSP: Rename symbol (leader variant)
- [ ] `<leader>lsp` -- LSP: Pick root scope (cwd / git root / file path)
- [ ] `<M-s>` -- LSP: Signature help
- [ ] `<leader>xx` -- LSP: Trouble: all diagnostics
- [ ] `<leader>xd` -- LSP: Trouble: buffer diagnostics
- [ ] `<leader>xld` -- LSP: Trouble: definitions
- [ ] `]w` -- LSP: Next entry in the open Trouble diagnostics list
- [ ] `[w` -- LSP: Prev entry in the open Trouble diagnostics list
- [ ] `<leader>xli` -- LSP: Trouble: implementations
- [ ] `<leader>xl` -- LSP: Trouble: location list
- [ ] `<leader>xq` -- LSP: Trouble: quickfix list
- [ ] `<leader>xlr` -- LSP: Trouble: references
- [ ] `<leader>xls` -- LSP: Trouble: document symbols
- [ ] `<leader>xt` -- LSP: Trouble: toggle diagnostics
- [ ] `<leader>xlt` -- LSP: Trouble: type definitions
- [ ] `<leader>xw` -- LSP: Trouble: workspace diagnostics
- [ ] `<leader>lsw` -- LSP: Add a workspace folder (multi-root / monorepo)

### Reposcope

- [ ] `<leader>rc` -- Reposcope: Close Reposcope
- [ ] `<leader>rs` -- Reposcope: open the UI

### bindings

- [ ] `""` -- Surround selection with double quotes (")
- [ ] `''` -- Surround selection with single quotes (')
- [ ] `()` -- Surround selection with ()
- [ ] `<A-Down>` -- [Noice] LSP Scroll forward
- [ ] `<A-Up>` -- [Noice] LSP Scroll backward
- [ ] `<A-h>` -- [Term] Toggle floating
- [ ] `<A-j>` -- [Noice] LSP Scroll forward
- [ ] `<A-k>` -- [Noice] LSP Scroll backward
- [ ] `<A-x>` -- [Noice] Dismiss UI
- [ ] `<C-A-S-p>` -- [Text] Paste from system clipboard (insert mode, literal)
- [ ] `<C-S-j>` -- Move down by screen line (through wrapped text)
- [ ] `<C-S-k>` -- Move up by screen line (through wrapped text)
- [ ] `<C-a>` -- [General] Select all
- [ ] `<C-c>` -- [General] Copy whole file
- [ ] `<C-e>` -- [HARPOON] Open quick menu
- [ ] `<C-h>` -- [Window] Jump left
- [ ] `<C-j>` -- [Window] Jump down
- [ ] `<C-k>` -- [Window] Jump up
- [ ] `<C-l>` -- [Window] Jump right
- [ ] `<C-r>` -- Redo (branch-aware)
- [ ] `<C-s>` -- [General] Save file
- [ ] `<CR>` -- Insert blank line
- [ ] `<Esc>` -- Clear copilot NES overlays or nohl
- [ ] `<F1>` -- [General] Disable F1
- [ ] `<Leader>dt` -- Diff Windows in Tab
- [ ] `<M-1>` -- [HARPOON] Preview entry 1 (full screen)
- [ ] `<M-2>` -- [HARPOON] Preview entry 2 (full screen)
- [ ] `<M-3>` -- [HARPOON] Preview entry 3 (full screen)
- [ ] `<M-4>` -- [HARPOON] Preview entry 4 (full screen)
- [ ] `<M-5>` -- [HARPOON] Preview entry 5 (full screen)
- [ ] `<M-6>` -- [HARPOON] Preview entry 6 (full screen)
- [ ] `<M-7>` -- [HARPOON] Preview entry 7 (full screen)
- [ ] `<M-8>` -- [HARPOON] Preview entry 8 (full screen)
- [ ] `<M-9>` -- [HARPOON] Preview entry 9 (full screen)
- [ ] `<M-O>` -- [Open] List every openable target in the buffer
- [ ] `<M-o>` -- [Open] Open whatever is under the cursor
- [ ] `<S-h>` -- [Window] Resize narrower
- [ ] `<S-j>` -- [Window] Resize shorter
- [ ] `<S-k>` -- [Window] Resize taller
- [ ] `<S-l>` -- [Window] Resize wider
- [ ] `<leader>,` -- [Telescope] File Browser (at CWD)
- [ ] `<leader>/` -- [Text] Toggle comment
- [ ] `<leader>0` -- [Buffers] Go to buffer 10
- [ ] `<leader>1` -- [Buffers] Go to buffer 1
- [ ] `<leader>2` -- [Buffers] Go to buffer 2
- [ ] `<leader>3` -- [Buffers] Go to buffer 3
- [ ] `<leader>4` -- [Buffers] Go to buffer 4
- [ ] `<leader>5` -- [Buffers] Go to buffer 5
- [ ] `<leader>6` -- [Buffers] Go to buffer 6
- [ ] `<leader>7` -- [Buffers] Go to buffer 7
- [ ] `<leader>8` -- [Buffers] Go to buffer 8
- [ ] `<leader>9` -- [Buffers] Go to buffer 9
- [ ] `<leader><CR>` -- Insert blank line below
- [ ] `<leader>BI` -- Copy BINDINGS roots to the clipboard
- [ ] `<leader>bn` -- [Buffers] New
- [ ] `<leader>bx` -- [Buffers] Close current, go to next
- [ ] `<leader>cp` -- [General] Copy file path
- [ ] `<leader>cs` -- [casedesk] Save session (case-aware)
- [ ] `<leader>date` -- [General] Insert date
- [ ] `<leader>dc` -- [Diffview] Close
- [ ] `<leader>dh` -- [Diffview] File History
- [ ] `<leader>di` -- Toggle inline diff (gitsigns)
- [ ] `<leader>dv` -- [Diffview] Open
- [ ] `<leader>fB` -- [FzfLua] Grep current buffer
- [ ] `<leader>fK` -- [FzfLua] Keymaps
- [ ] `<leader>fa` -- [Telescope] Find All Files
- [ ] `<leader>fg` -- [FzfLua] Live Grep
- [ ] `<leader>fgs` -- [FzfLua] Git Status
- [ ] `<leader>fm` -- [General] Format file
- [ ] `<leader>fq` -- [Quickfix] Quickfix
- [ ] `<leader>ftf` -- [FzfLua] Search Tree-sitter symbols
- [ ] `<leader>fth` -- [FzfLua] Colorschemes
- [ ] `<leader>fws` -- [FzfLua] Search workspace symbols (LSP)
- [ ] `<leader>fzf` -- [FzfLua] Files
- [ ] `<leader>hA` -- [HARPOON] Add current file (top of list)
- [ ] `<leader>hD` -- [HARPOON] Dump the current list
- [ ] `<leader>ha` -- [HARPOON] Add current file (end of list)
- [ ] `<leader>hf` -- [HARPOON] Open list in fzf
- [ ] `<leader>hm` -- [HARPOON] Open quick menu
- [ ] `<leader>hp` -- [HARPOON] Add current file permanently (top, pinned default)
- [ ] `<leader>hs` -- [HARPOON] Sync missing default paths
- [ ] `<leader>ht` -- [HARPOON] Open list in telescope
- [ ] `<leader>man` -- [FzfLua] Man Pages
- [ ] `<leader>nvt` -- [nvchad] Themes switcher
- [ ] `<leader>q` -- [Windows] Close window
- [ ] `<leader>tc` -- [Tabs] New tab
- [ ] `<leader>tg` -- [Telescope] Grep
- [ ] `<leader>tn` -- [Tabs] Next tab
- [ ] `<leader>tp` -- [Tabs] Previous tab
- [ ] `<leader>ts` -- [Telescope] UI
- [ ] `<leader>tx` -- [Tabs] Close tab
- [ ] `<leader>wK` -- [General] WhichKey (all)
- [ ] `<leader>wR` -- Rotate window layout
- [ ] `<leader>wh` -- Move window to horizontal split (top)
- [ ] `<leader>wj` -- Move window to horizontal split (bottom)
- [ ] `<leader>wk` -- [General] WhichKey query
- [ ] `<leader>wl` -- Move window to vertical split (left)
- [ ] `<leader>wr` -- Move window to vertical split (right)
- [ ] `<leader>zm` -- [Window] Zoom toggle.
- [ ] `P` -- Paste before cursor (leading/trailing blank lines trimmed)
- [ ] `[]` -- Surround selection with []
- [ ] `[u` -- Jump to the head of the enclosing structure (repeatable)
- [ ] `]u` -- Jump to the end of the enclosing structure (repeatable)
- [ ] ``` -- Surround selection with backticks (`)
- [ ] `jk` -- [General] Exit to normal mode
- [ ] `p` -- Paste after cursor (leading/trailing blank lines trimmed)
- [ ] `{}` -- Surround selection with {}

### cascade

- [ ] `<C-M-y>` -- cascade: cycle char under cursor (in-word)
- [ ] `<C-M-x>` -- cascade: cycle char under cursor back (in-word)
- [ ] `<leader>cP` -- cascade: pick a cycle-group value
- [ ] `<C-y>` -- cascade: increment / cycle word
- [ ] `<C-x>` -- cascade: decrement / cycle word
- [ ] `-` -- cascade: decrement / cycle word
- [ ] `<A-Left>` -- cascade: dedent (Ncount = N lines, +renumber)
- [ ] `<A-Left>` -- cascade: dedent line (insert)
- [ ] `<leader><A-Left>` -- cascade: dedent (Ncount = N levels, +renumber)
- [ ] `+` -- cascade: increment / cycle word
- [ ] `<A-Right>` -- cascade: indent (Ncount = N lines, +renumber)
- [ ] `<A-Right>` -- cascade: indent line (insert)
- [ ] `<leader><A-Right>` -- cascade: indent (Ncount = N levels, +renumber)
- [ ] `<A-Down>` -- cascade: move line/selection down
- [ ] `<A-Down>` -- cascade: move line down (insert)
- [ ] `<A-Up>` -- cascade: move line/selection up
- [ ] `<A-Up>` -- cascade: move line up (insert)
- [ ] `<leader>cR` -- cascade: renumber the numbers inside the selection
- [ ] `<leader><Left>` -- cascade: swap char with left neighbor (Ncount = N times)
- [ ] `<leader><Right>` -- cascade: swap char with right neighbor (Ncount = N times)
- [ ] `<leader><C-Left>` -- cascade: swap word with left neighbor word (Ncount = N times)
- [ ] `<leader><C-Right>` -- cascade: swap word with right neighbor word (Ncount = N times)

### cascade/list

- [ ] `<A-->` -- cascade: toggle bullet point
- [ ] `<A-c>` -- cascade: toggle checkbox bullet
- [ ] `<CR>` -- cascade: continue list
- [ ] `<M-CR>` -- cascade: plain newline (skip list continuation)
- [ ] `<leader>ct` -- cascade: cycle list type
- [ ] `<leader>cT` -- cascade: cycle list type back
- [ ] `<A-0>` -- cascade: toggle numbered list
- [ ] `O` -- cascade: open item above
- [ ] `o` -- cascade: open item below
- [ ] `<leader>cr` -- cascade: renumber
- [ ] `<leader>cv` -- cascade: reverse list order
- [ ] `<leader>cf` -- cascade: rotate list form
- [ ] `<leader>cF` -- cascade: rotate list form back
- [ ] `<leader>cS` -- cascade: sort list A-Z
- [ ] `<A-*>` -- cascade: toggle star bullet
- [ ] `<leader>cX` -- cascade: strip checkboxes
- [ ] `<leader>cx` -- cascade: toggle checkbox

### config

- [ ] `<A-b>` -- <A-b>
- [ ] `<M-c>` -- [Neo-tree] Toggle window (current)
- [ ] `<M-f>` -- [Neo-tree] Toggle window (float)
- [ ] `<M-l>` -- [Neo-tree] Toggle window (left)
- [ ] `<M-r>` -- [Neo-tree] Toggle window (right)
- [ ] `<RightMouse>` -- <RightMouse>
- [ ] `<leader>ns` -- [Neo-tree] Switch Source
- [ ] `<leader>ntD` -- Show loaded adapters
- [ ] `<leader>ntO` -- Toggle output panel
- [ ] `<leader>nta` -- Run all tests
- [ ] `<leader>ntd` -- Debug nearest test
- [ ] `<leader>ntf` -- Run file tests
- [ ] `<leader>nto` -- Show output
- [ ] `<leader>ntr` -- Refresh test discovery
- [ ] `<leader>nts` -- Toggle summary
- [ ] `<leader>ntt` -- Run nearest test
- [ ] `<leader>ntw` -- Toggle watch mode

### fileops

- [ ] `<leader>nF` -- fileops: Next file (background)
- [ ] `<leader>nfn` -- fileops: Next file (stay listed)
- [ ] `<leader>nf` -- fileops: Next file (replace)
- [ ] `<leader>NF` -- fileops: Next file (vsplit)
- [ ] `<leader>pF` -- fileops: Previous file (background)
- [ ] `<leader>pfn` -- fileops: Previous file (stay listed)
- [ ] `<leader>pf` -- fileops: Previous file (replace)
- [ ] `<leader>PF` -- fileops: Previous file (vsplit)

### gopath

- [ ] `gC` -- gopath: check path exists / offer create
- [ ] `gY` -- gopath: copy path:line:col
- [ ] `g?` -- gopath: debug under cursor
- [ ] `gM` -- gopath: reveal in file explorer
- [ ] `gF` -- gopath: open here
- [ ] `g|` -- gopath: open in split
- [ ] `g}` -- gopath: open in tab
- [ ] `g\` -- gopath: open in vsplit
- [ ] `<leader>pp` -- gopath: probe path under cursor (vsplit)

### images

- [ ] `<leader>ig` -- images: every image in the buffer, side by side
- [ ] `<leader>in` -- images: next image
- [ ] `<leader>iv` -- images: paste an image from the clipboard
- [ ] `<leader>ip` -- images: previous image
- [ ] `<leader>is` -- images: take a screenshot and insert it
- [ ] `<leader>im` -- images: show the image under the cursor

### insights

- [ ] `<leader>fi` -- insights: file info float
- [ ] `<leader>pS` -- insights: symbols (fzf, cwd functions)
- [ ] `<leader>ps` -- insights: symbols (telescope, cwd functions)

### language/spell

- [ ] `<leader>ss` -- language: Toggle spell session (current buffer)

### language/translate

- [ ] `<leader>lt` -- language: Translate motion
- [ ] `<leader>lt` -- language: Translate selection

### lib

- [ ] `<M-.>` -- repeat last real command (lib.nvim.lastcmd)

### lsp

- [ ] `<C-b>` -- [LSP] Show signature or hover (floating toggle)
- [ ] `<leader>fm` -- [lsp] Format markdown buffer
- [ ] `grn` -- LSP: Rename symbol
- [ ] `grt` -- LSP: Go to type definition (g-prefix variant)

### markdown.nvim/editing

- [ ] `ma` -- markdown.nvim: Cursor action
- [ ] `<2-LeftMouse>` -- markdown.nvim: Cursor action / heading fold
- [ ] `<C-LeftMouse>` -- markdown.nvim: Cursor action
- [ ] `zk` -- markdown.nvim: Fold below H2 (toggle outline)
- [ ] `zi` -- markdown.nvim: Fold prev heading
- [ ] `<localleader>f` -- markdown.nvim: Fold toggle
- [ ] `zf` -- markdown.nvim: Fold toggle
- [ ] `<C-Left>` -- markdown.nvim: Decrease heading level
- [ ] `<S-Left>` -- markdown.nvim: Decrease all headings
- [ ] `<C-Left>` -- markdown.nvim: Decrease heading level (visual)
- [ ] `<C-Right>` -- markdown.nvim: Increase heading level
- [ ] `<S-Right>` -- markdown.nvim: Increase all headings
- [ ] `<C-Right>` -- markdown.nvim: Increase heading level (visual)
- [ ] `mj` -- markdown.nvim: Jump to anchor
- [ ] `<C-f>` -- markdown.nvim: Next heading / fence
- [ ] `]]` -- markdown.nvim: Next heading / fence
- [ ] `<leader><C-f>` -- markdown.nvim: Next heading of level
- [ ] `mi` -- markdown.nvim: Open image
- [ ] `<C-p>` -- markdown.nvim: Prev heading / fence
- [ ] `[[` -- markdown.nvim: Prev heading / fence
- [ ] `<leader><C-p>` -- markdown.nvim: Prev heading of level
- [ ] `<leader>mtf` -- markdown.nvim: Format table at cursor
- [ ] `]|` -- markdown.nvim: Next table cell
- [ ] `[|` -- markdown.nvim: Prev table cell
- [ ] `<leader>toc` -- markdown.nvim: Insert/refresh TOC
- [ ] `**` -- markdown.nvim: Toggle bold
- [ ] `zu` -- markdown.nvim: Unfold all
- [ ] `<leader>[` -- markdown.nvim: Wrap word in link
- [ ] `<leader>[` -- markdown.nvim: Wrap selection in link

### markdown.nvim/tableview

- [ ] `<leader>tvx` -- markdown.nvim: Toggle box-drawing table preview
- [ ] `<leader>tvb` -- markdown.nvim: Open table in browser
- [ ] `<leader>tvc` -- markdown.nvim: Close TableView
- [ ] `<leader>tvm` -- markdown.nvim: Toggle table auto-format mode
- [ ] `<leader>tvs` -- markdown.nvim: Select and preview table
- [ ] `<leader>tvt` -- markdown.nvim: Toggle table preview at cursor

### pickers

- [ ] `<leader>chf` -- [pickers] checklists: find files
- [ ] `<leader>chg` -- [pickers] checklists: live grep
- [ ] `<leader>mlf` -- [pickers] notes_lua: find files
- [ ] `<leader>mlg` -- [pickers] notes_lua: live grep
- [ ] `<leader>mnf` -- [pickers] notes: find files
- [ ] `<leader>mng` -- [pickers] notes: live grep
- [ ] `<leader>mns` -- [pickers] notes: smart (grep + find)
- [ ] `<leader>mvf` -- [pickers] notes_nvim: find files
- [ ] `<leader>mvg` -- [pickers] notes_nvim: live grep
- [ ] `<leader>spf` -- [pickers] spickzettel: find files
- [ ] `<leader>spg` -- [pickers] spickzettel: live grep
- [ ] `<leader>wkf` -- [pickers] wkdbooks: find files
- [ ] `<leader>wkg` -- [pickers] wkdbooks: live grep
- [ ] `<leader>wks` -- [pickers] wkdbooks: smart (grep + find)
- [ ] `<leader>wlf` -- [pickers] wkdbooks_lua: find files
- [ ] `<leader>wlg` -- [pickers] wkdbooks_lua: live grep
- [ ] `<leader>wvf` -- [pickers] wkdbooks_nvim: find files
- [ ] `<leader>wvg` -- [pickers] wkdbooks_nvim: live grep
- [ ] `<leader>fc` -- pickers: Find files in nvim config
- [ ] `<leader>gc` -- pickers: Grep in nvim config
- [ ] `<leader>cf` -- pickers: Smart (grep + find) in nvim config
- [ ] `<leader>li` -- pickers: Live grep in CWD
- [ ] `<leader>cw` -- pickers: Smart (grep + find) in CWD
- [ ] `<leader>dp` -- pickers: Dir: navigate (alias / depth / path)
- [ ] `<leader>.` -- pickers: File explorer / browser (active engine)
- [ ] `<leader>fb` -- pickers: Find files in interactively picked folder

### spotlight

- [ ] `<leader>sC` -- spotlight: clear all spotlights
- [ ] `<leader>sW` -- spotlight: toggle whole-line rendering for the token under cursor
- [ ] `<leader>sL` -- spotlight: open the spotlight list
- [ ] `]k` -- spotlight: next occurrence (×count)
- [ ] `[k` -- spotlight: previous occurrence (×count)
- [ ] `<leader>sq` -- spotlight: matching lines to quickfix
- [ ] `<leader>sK` -- spotlight: toggle every occurrence of the token under cursor (dot-repeatable)
- [ ] `<leader>sk` -- spotlight: toggle this occurrence only

### wkdnvchad

- [ ] `<S-Tab>` -- [Buffers] Prev
- [ ] `<Tab>` -- [Buffers] Next
- [ ] `<leader>bc` -- [Buffers] Close
- [ ] `<leader>tl` -- [Tabs] Move tab left
- [ ] `<leader>tr` -- [Tabs] Move tab right
- [ ] `<leader>tt` -- [Tabs] Move current buffer to new tab

### wkdoptions

- [ ] `gh` -- Git hunk peek

## Usercmds

### :AllDrives

- [ ] `:AllDrives` -- [pickers compat] :AllDrives → :Pickers drives files

### :AllDrivesGrep

- [ ] `:AllDrivesGrep` -- [pickers compat] :AllDrivesGrep → :Pickers drives grep

### :AstroBuild

- [ ] `:AstroBuild` -- Build Astro project

### :AstroCheckStructure

- [ ] `:AstroCheckStructure` -- Check Astro project structure

### :AstroDevStart

- [ ] `:AstroDevStart` -- Start Astro dev server

### :AstroFindUsage

- [ ] `:AstroFindUsage` -- Find component usage

### :AstroListComponents

- [ ] `:AstroListComponents` -- List all Astro components

### :AstroNewComponent

- [ ] `:AstroNewComponent` -- Create new Astro component

### :AstroNewPage

- [ ] `:AstroNewPage` -- Create new Astro page

### :AstroPreview

- [ ] `:AstroPreview` -- Preview Astro build

### :Bindings

- [ ] `:Bindings report extern` -- Nur die fremden, als Markdown-Datei
- [ ] `:Bindings report all` -- Eigene und fremde zusammen, als Markdown-Datei
- [ ] `:Bindings report` -- Drift-Bericht als Markdown-Datei; ohne `out=` nach docs/ROADMAP/personal/All/BINDINGS-DRIFT-<datum>.md
- [ ] `:Bindings check all` -- Eigene und fremde zusammen — das Verhalten vor der Scope-Trennung
- [ ] `:Bindings check extern` -- Nur die fremden: live registrierte Commands ohne Cheatsheet, deren Plugin dieser Korpus nicht abdeckt
- [ ] `:Bindings report repo` -- Drift-Bericht mit der Checkout-Achse, als Markdown-Datei
- [ ] `:Bindings audit prefixes` -- Command names that are a strict prefix of another live command (<Tab>/abbreviation collisions)
- [ ] `:Bindings status` -- Dashboard: Korpus-, Live- und Plugin-Zahlen plus die Routenliste
- [ ] `:Bindings audit gaps` -- Keymap actions with no obvious command counterpart (optional: scope to a repo path)
- [ ] `:Bindings audit keys` -- Actions whose every key needs an extended terminal encoding (optional: scope to a repo path)
- [ ] `:Bindings check repo` -- Drift-Bericht mit der Checkout-Achse: dokumentierte Bindings ungeladener Plugins gegen deren lokalen Quellbaum; `root=<dir>` nimmt jedes Lua-Projekt unter einem Sammelverzeichnis statt der Lazy-Spec-Auflösung
- [ ] `:Bindings browse keymaps` -- Picker über Keymaps-Tabellenzeilen; `personal`/`extern` oder ein Cheatsheet-Stamm scopen
- [ ] `:Bindings browse autocmds` -- Picker über Autocmds-Tabellenzeilen; `personal`/`extern` oder ein Cheatsheet-Stamm scopen
- [ ] `:Bindings` -- Cheatsheets in docs/NOTES/{PersonelPlugins/BINDINGS,ExternPlugins/Bindings} durchsuchen
- [ ] `:Bindings search usercmds` -- Live-Grep, nur Usercmds-Cheatsheets; `hover.nvim` als Argument scopt auf dessen Sheet
- [ ] `:Bindings search` -- Live-Grep über beide BINDINGS-Bäume (Picker-Engine, sonst Prompt+Liste); ein Cheatsheet-Stamm als Argument scopt auf dessen Sheets
- [ ] `:Bindings search keymaps` -- Live-Grep, nur Keymaps-Cheatsheets; `hover.nvim` als Argument scopt auf dessen Sheet
- [ ] `:Bindings check` -- Drift-Bericht: dokumentiert-aber-nicht-live / live-aber-undokumentiert (Personal, read-only)
- [ ] `:Bindings search autocmds` -- Live-Grep, nur Autocmds-Cheatsheets; `hover.nvim` als Argument scopt auf dessen Sheet
- [ ] `:Bindings browse` -- Picker über alle Tabellenzeilen (Keymaps+Usercmds+Autocmds); `personal`/`extern` oder ein Cheatsheet-Stamm scopen
- [ ] `:Bindings path` -- BINDINGS-Wurzel(n) in die Zwischenablage kopieren
- [ ] `:Bindings browse usercmds` -- Picker über Usercmds-Tabellenzeilen; `personal`/`extern` oder ein Cheatsheet-Stamm scopen
- [ ] `:Bindings audit naming` -- Routes whose last path segment is a bare vague word (deep/full/check/...) -- candidates for a naming review, not a verdict
- [ ] `:Bindings audit checklist` -- Markdown checklist over every keymap action and command route, for a manual runtime pass (view only -- :BindingsRuntimeChecklist writes it to a file)
- [ ] `:Bindings audit` -- Keymap actions vs. command routes, registered in this session (optional: scope to a repo path)
- [ ] `:Bindings conflicts` -- lhs values claimed by more than one plugin/registration in this session

### :Cascade

- [ ] `:Cascade strip` -- Strip checkboxes (range-aware)
- [ ] `:Cascade indent` -- Indent line/range (+renumber; arg = levels)
- [ ] `:Cascade sort` -- Sort list A-Z (range-aware; ! = Z-A)
- [ ] `:Cascade rotate` -- Rotate list form (range-aware; ! or 'prev' = backward)
- [ ] `:Cascade reverse` -- Reverse list order (range-aware)
- [ ] `:Cascade dedent` -- Dedent line/range (+renumber; arg = levels)
- [ ] `:Cascade renumber` -- Renumber list block (range-aware; 'all' = every list in the buffer, 'selection' = numbers inside the lines)
- [ ] `:Cascade cycle list` -- List the cycle groups in effect for this buffer
- [ ] `:Cascade cycle add` -- Add a cycle group at runtime: :Cascade cycle add on,off,maybe

### :Case

- [ ] `:Case timeline` -- Work sessions reconstructed from file mtimes, oldest first
- [ ] `:Case sla` -- SAP-SLA clocks (first reaction, cadence, correction) and how much of each is left; --doc opens the source agreement
- [ ] `:Case template` -- Insert a reply block from Workflow/Templates at the cursor
- [ ] `:Case ki` -- Build the AI-analysis prompt from the clipboard's activity stream, copy it back
- [ ] `:Case ki import` -- File a pasted AI answer into Research/Replies/Notes
- [ ] `:Case similar` -- Past cases with similar title/Summary wording (TF-IDF, no AI)
- [ ] `:Case t2` -- Move the case to T2
- [ ] `:Case activity` -- Paste the clipboard (a SNOW Activity Stream) into a new Research/ file
- [ ] `:Case info` -- Short infocard for a case (e edit, o open folder, s summary)
- [ ] `:Case new` -- Scaffold a new case (prompts for missing fields)
- [ ] `:Case copy` -- Copy a file into the current case
- [ ] `:Case open` -- Open a case's folder
- [ ] `:Case attachments` -- List and open this case's attachments (assets/)
- [ ] `:Case add` -- Add a markdown file ('reply [suffix]' auto-numbers, e.g. :Case add reply AskForPDF)
- [ ] `:Case ocr` -- Read the text out of this case's screenshots into <image>.ocr.md sidecars, so :Case grep finds it (needs tesseract)
- [ ] `:Case insert` -- Insert a case token (number/title/company/name/asset/...) at the cursor and copy it
- [ ] `:Case versions` -- Curated version digest from ToscaSupportInfo*.txt (EXTRACTION.md); a component copies its version, --all lists everything, --raw opens the file
- [ ] `:Case solved` -- Move the case to Solved
- [ ] `:Case reassign` -- Move the case to Reassigned
- [ ] `:Case assigned` -- Move the case to Assigned
- [ ] `:Case otheragent` -- Move the case to OtherAgent
- [ ] `:Case unassigned` -- Move the case to Unassigned
- [ ] `:Case doclinks` -- docs.tricentis.com links (Activity Streams + Replies) pointing at a different Tosca version than the customer's own
- [ ] `:Case reply` -- Open Replies/00_PSO.md of the case
- [ ] `:Case notes` -- Open Notes.md of the case
- [ ] `:Case solution` -- Show the case's documented solution (offers to create one if there is none); --edit opens the file straight away
- [ ] `:Case sync` -- Add missing blueprint pieces to an existing case
- [ ] `:Case research` -- Open Research/00_Research.md of the case
- [ ] `:Case snow` -- Open (or copy) the case's ServiceNow ticket id
- [ ] `:Case summary` -- Open Summary.md of the case
- [ ] `:Case reply check` -- Pre-send gate on the current buffer: emojis, stray markdown headlines, dead links
- [ ] `:Case` -- SAP Support case scaffolding

### :Cases

- [ ] `:Cases list` -- List every case, grouped by state
- [ ] `:Cases normalize` -- Fix corpus naming inconsistencies found by doctor (dry-run + confirm)
- [ ] `:Cases close` -- Close multiple cases at once (marks from :Cases list, or an interactive multi-select), then pick one destination
- [ ] `:Cases doctor` -- Report corpus naming inconsistencies (read-only)
- [ ] `:Cases name` -- Filter cases by name
- [ ] `:Cases history` -- Every case for a company, grouped by state (default: current buffer's company)
- [ ] `:Cases sla` -- SLA dashboard: every open case with a priority, sorted by what breaches next
- [ ] `:Cases title` -- Filter cases by title
- [ ] `:Cases stale` -- Open cases untouched for at least N days, or per-priority threshold if N omitted
- [ ] `:Cases find` -- Filter cases by multiple fields at once (field=pattern field=pattern ...)
- [ ] `:Cases linkcheck` -- Check docs.tricentis.com links for dead pages (optionally one case)
- [ ] `:Cases terminology` -- Every term collected from every Terminologie.md across the work repo
- [ ] `:Cases insert` -- Insert a token from ANOTHER case (number/title/company/name match) at the cursor and copy it
- [ ] `:Cases grep` -- Full-text search across every case's markdown files
- [ ] `:Cases pickers` -- Discovery menu: attachments, links, cases without .case.json, terminology, CLI commands, solutions
- [ ] `:Cases export` -- Bundle Summary/Notes/Research/Replies into one PDF (pandoc + headless browser)
- [ ] `:Cases solutions` -- Search every documented solution in the corpus (keyword-weighted, no AI); no pattern lists them all
- [ ] `:Cases stats` -- Counts by state / company / year
- [ ] `:Cases sla report` -- SLA compliance report across every case (not just open): first-response quote per priority, outliers with delta. --year filters by .case.json's year
- [ ] `:Cases company` -- Filter cases by company
- [ ] `:Cases priority` -- Filter cases by priority
- [ ] `:Cases recent` -- Most recently touched cases first
- [ ] `:Cases notes` -- Filter cases by notes
- [ ] `:Cases tosca_version` -- Filter cases by tosca_version
- [ ] `:Cases` -- Cross-case queries (field filters, listing)

### :CheckHealthHarpoon

- [ ] `:CheckHealthHarpoon` -- Harpoon: run the health check (alias for :Harpoon health)

### :ChecklistsFiles

- [ ] `:ChecklistsFiles` -- [pickers coll] :ChecklistsFiles → :Pickers checklists files

### :ChecklistsGrep

- [ ] `:ChecklistsGrep` -- [pickers coll] :ChecklistsGrep → :Pickers checklists grep

### :ChecklistsSmart

- [ ] `:ChecklistsSmart` -- [pickers coll] :ChecklistsSmart → :Pickers checklists smart

### :Cmdlog

- [ ] `:Cmdlog project` -- Command history for the current Git project
- [ ] `:Cmdlog shell-full` -- Shell command history, including duplicates
- [ ] `:Cmdlog lua` -- Lua-mode command history, deduplicated
- [ ] `:Cmdlog full` -- All commands, including duplicates
- [ ] `:Cmdlog` -- Command history pickers
- [ ] `:Cmdlog favorites` -- Favorited commands
- [ ] `:Cmdlog nvim` -- Neovim command-line history, deduplicated
- [ ] `:Cmdlog shell` -- Shell command history, deduplicated
- [ ] `:Cmdlog nvim-full` -- Neovim command-line history, including duplicates
- [ ] `:Cmdlog stats` -- Commands sorted by usage frequency
- [ ] `:Cmdlog export` -- Export favorites to a JSON file (default: favorites path + .export.json)
- [ ] `:Cmdlog risky test` -- Show which risky_patterns match a command (tune the list without guessing)
- [ ] `:Cmdlog import` -- Import favorites from a JSON file, merging with the current list

### :ColorMyAscii

- [ ] `:ColorMyAscii show-config` -- Show current configuration
- [ ] `:ColorMyAscii` -- ASCII art syntax highlighting
- [ ] `:ColorMyAscii debug` -- Show debug information
- [ ] `:ColorMyAscii toggle` -- Toggle ASCII art highlighting  :ColorMyAscii toggle [global|buffer]
- [ ] `:ColorMyAscii ensure-blank-lines` -- Ensure blank lines before and after fenced code blocks
- [ ] `:ColorMyAscii fence-jump` -- Jump between a fence's opening/closing delimiter (%-style); falls back to the built-in % elsewhere
- [ ] `:ColorMyAscii schemes list` -- List available color schemes
- [ ] `:ColorMyAscii hover` -- Show a float with the applied highlight/group/keyword info for the character under the cursor (also copied to a register)
- [ ] `:ColorMyAscii schemes pick` -- Pick a color scheme with Telescope
- [ ] `:ColorMyAscii schemes switch` -- Switch to a different color scheme
- [ ] `:ColorMyAscii check-fences` -- Check current buffer for unmatched fenced code blocks

### :ContextOpen

- [ ] `:ContextOpen list` -- List every openable target in the buffer
- [ ] `:ContextOpen` -- Open whatever is under the cursor (gopath/markdown/images/pdfport/open.nvim, unified)

### :CopyLocation

- [ ] `:CopyLocation` -- Copy the absolute path, line and column to the clipboard

### :CwdHere

- [ ] `:CwdHere` -- (no description)

### :Debug

- [ ] `:Debug performance startup` -- (no description)
- [ ] `:Debug` -- Unified debugging entry point — :Debug {category} {action}
- [ ] `:Debug noice all` -- (no description)
- [ ] `:Debug noice errors` -- (no description)
- [ ] `:Debug inspect tab` -- (no description)
- [ ] `:Debug inspect window` -- (no description)
- [ ] `:Debug dump` -- (no description)
- [ ] `:Debug module reload` -- (no description)
- [ ] `:Debug health` -- (no description)
- [ ] `:Debug keylogger start` -- (no description)
- [ ] `:Debug messages clear` -- (no description)
- [ ] `:Debug messages show` -- (no description)
- [ ] `:Debug messages capture` -- (no description)
- [ ] `:Debug report win` -- (no description)
- [ ] `:Debug cursor state` -- (no description)
- [ ] `:Debug report tab` -- (no description)
- [ ] `:Debug proc start` -- (no description)
- [ ] `:Debug proc status` -- (no description)
- [ ] `:Debug markdown log` -- (no description)
- [ ] `:Debug markdown inline` -- (no description)
- [ ] `:Debug indent show` -- (no description)
- [ ] `:Debug inspect buffer` -- (no description)
- [ ] `:Debug autocmds all` -- (no description)
- [ ] `:Debug autocmds runtime` -- (no description)
- [ ] `:Debug autocmds sources` -- (no description)
- [ ] `:Debug proc log` -- (no description)
- [ ] `:Debug proc watch` -- (no description)
- [ ] `:Debug report buf` -- (no description)
- [ ] `:Debug indent treesitter` -- (no description)

### :DiagLoc

- [ ] `:DiagLoc` -- Diagnostics of the current buffer into the location list [severity]

### :DiagNextLoc

- [ ] `:DiagNextLoc` -- Jump to the next diagnostic in the current buffer [severity]

### :DiagNextQF

- [ ] `:DiagNextQF` -- Jump to the next quickfix entry

### :DiagPrevLoc

- [ ] `:DiagPrevLoc` -- Jump to the previous diagnostic in the current buffer [severity]

### :DiagPrevQF

- [ ] `:DiagPrevQF` -- Jump to the previous quickfix entry

### :DiagQF

- [ ] `:DiagQF` -- Workspace diagnostics into the quickfix list [severity]

### :DirPicker

- [ ] `:DirPicker` -- [pickers compat] :DirPicker [nav] → :Pickers dir [nav]

### :EslintFix

- [ ] `:EslintFix` -- Run eslint_d --fix on current file (requires eslint config in project root)

### :Fence

- [ ] `:Fence` -- [color_my_ascii] Fence actions (export, yank, open, run, format, import, lang, select, wrap, unwrap, align)

### :File

- [ ] `:File move` -- (no description)
- [ ] `:File next` -- (no description)
- [ ] `:File prev` -- (no description)
- [ ] `:File first` -- (no description)
- [ ] `:File duplicate` -- (no description)
- [ ] `:File copy` -- (no description)
- [ ] `:File rename` -- (no description)
- [ ] `:File last` -- (no description)
- [ ] `:File path` -- (no description)
- [ ] `:File help` -- (no description)
- [ ] `:File open` -- (no description)
- [ ] `:File bulk rename` -- (no description)
- [ ] `:File info` -- (no description)
- [ ] `:File lockinfo` -- (no description)
- [ ] `:File touch` -- (no description)
- [ ] `:File cd` -- (no description)
- [ ] `:File writeto` -- (no description)
- [ ] `:File mkdir` -- (no description)
- [ ] `:File write` -- (no description)
- [ ] `:File new` -- (no description)
- [ ] `:File saveas` -- (no description)

### :Filetree

- [ ] `:Filetree clipboard cut` -- (no description)
- [ ] `:Filetree smartrename` -- (no description)
- [ ] `:Filetree info close` -- (no description)
- [ ] `:Filetree info` -- (no description)
- [ ] `:Filetree session clear` -- (no description)
- [ ] `:Filetree diff close` -- (no description)
- [ ] `:Filetree filter` -- (no description)
- [ ] `:Filetree session restore` -- (no description)
- [ ] `:Filetree mdlink recursive` -- (no description)
- [ ] `:Filetree diff marked` -- (no description)
- [ ] `:Filetree clipboard clear` -- (no description)
- [ ] `:Filetree handles` -- (no description)
- [ ] `:Filetree create` -- (no description)
- [ ] `:Filetree session save` -- (no description)
- [ ] `:Filetree marks show` -- (no description)
- [ ] `:Filetree clipboard copy` -- (no description)
- [ ] `:Filetree clipboard show` -- (no description)
- [ ] `:Filetree rename` -- (no description)
- [ ] `:Filetree marks clear` -- (no description)
- [ ] `:Filetree search` -- (no description)
- [ ] `:Filetree marks all` -- (no description)
- [ ] `:Filetree size refresh` -- (no description)
- [ ] `:Filetree search clear` -- (no description)
- [ ] `:Filetree clipboard paste` -- (no description)
- [ ] `:Filetree trash undo` -- (no description)
- [ ] `:Filetree copy uri` -- (no description)
- [ ] `:Filetree mdlink marked` -- (no description)
- [ ] `:Filetree filelist files abs` -- (no description)
- [ ] `:Filetree mdlink` -- (no description)
- [ ] `:Filetree open pick` -- (no description)
- [ ] `:Filetree open system` -- (no description)
- [ ] `:Filetree filelist dirs rel` -- (no description)
- [ ] `:Filetree move` -- (no description)
- [ ] `:Filetree traverse down` -- (no description)
- [ ] `:Filetree filelist dirs abs` -- (no description)
- [ ] `:Filetree require relative` -- (no description)
- [ ] `:Filetree require` -- (no description)
- [ ] `:Filetree traverse up` -- (no description)
- [ ] `:Filetree open app` -- (no description)
- [ ] `:Filetree renamebatch dry-run` -- (no description)
- [ ] `:Filetree breadcrumbs update` -- (no description)
- [ ] `:Filetree mdrefs cancel` -- (no description)
- [ ] `:Filetree trash history` -- (no description)
- [ ] `:Filetree trash dry-run` -- (no description)
- [ ] `:Filetree template` -- (no description)
- [ ] `:Filetree mdrefs confirm` -- (no description)
- [ ] `:Filetree openas tabnew` -- (no description)
- [ ] `:Filetree copymove dry-run` -- (no description)
- [ ] `:Filetree openas badd` -- (no description)
- [ ] `:Filetree openas vsplit` -- (no description)
- [ ] `:Filetree openas split` -- (no description)
- [ ] `:Filetree filelist files rel` -- (no description)
- [ ] `:Filetree copy project_relative` -- (no description)
- [ ] `:Filetree copy line` -- (no description)
- [ ] `:Filetree grep` -- (no description)
- [ ] `:Filetree reveal pause` -- (no description)
- [ ] `:Filetree cwd unlock` -- (no description)
- [ ] `:Filetree cwd status` -- (no description)
- [ ] `:Filetree filter clear` -- (no description)
- [ ] `:Filetree reveal resume` -- (no description)
- [ ] `:Filetree safety dry-run` -- (no description)
- [ ] `:Filetree copy absolute` -- (no description)
- [ ] `:Filetree reveal` -- (no description)
- [ ] `:Filetree link` -- (no description)
- [ ] `:Filetree safety list` -- (no description)
- [ ] `:Filetree copy stem` -- (no description)
- [ ] `:Filetree cwd forget` -- (no description)
- [ ] `:Filetree cwd here` -- (no description)
- [ ] `:Filetree copy name` -- (no description)
- [ ] `:Filetree hooks clear` -- (no description)
- [ ] `:Filetree copy dirname` -- (no description)
- [ ] `:Filetree copy relative` -- (no description)
- [ ] `:Filetree cwd toggle` -- (no description)
- [ ] `:Filetree hooks events` -- (no description)
- [ ] `:Filetree watcher enter` -- (no description)
- [ ] `:Filetree watcher exit` -- (no description)
- [ ] `:Filetree refs status` -- (no description)
- [ ] `:Filetree refs undo` -- (no description)
- [ ] `:Filetree git refresh` -- (no description)
- [ ] `:Filetree copy pick` -- (no description)
- [ ] `:Filetree health` -- (no description)
- [ ] `:Filetree cwd lock` -- Lock the cwd to a directory (default: the current one)
- [ ] `:Filetree copy project_root` -- (no description)
- [ ] `:Filetree resize` -- (no description)
- [ ] `:Filetree cwd scope` -- Set the directory scope of the cwd policy (:cd | :tcd | :lcd)
- [ ] `:Filetree find` -- Find files (optionally scoped to a directory)
- [ ] `:Filetree cwd mode` -- Set the cwd/root policy (follow | project | nearest | lock | manual | tree_leads)

### :FindConfig

- [ ] `:FindConfig` -- [pickers compat] :FindConfig → :Pickers config files

### :FindInFolder

- [ ] `:FindInFolder` -- [pickers compat] :FindInFolder → :Pickers folder files

### :FindOnSystem

- [ ] `:FindOnSystem` -- [pickers compat] :FindOnSystem → :Pickers system files

### :Ft

- [ ] `:Ft session restore` -- (no description)
- [ ] `:Ft session clear` -- (no description)
- [ ] `:Ft session save` -- (no description)
- [ ] `:Ft marks all` -- (no description)
- [ ] `:Ft marks clear` -- (no description)
- [ ] `:Ft marks show` -- (no description)
- [ ] `:Ft search` -- (no description)
- [ ] `:Ft diff close` -- (no description)
- [ ] `:Ft diff marked` -- (no description)
- [ ] `:Ft mdlink` -- (no description)
- [ ] `:Ft mdlink marked` -- (no description)
- [ ] `:Ft renamebatch dry-run` -- (no description)
- [ ] `:Ft copymove dry-run` -- (no description)
- [ ] `:Ft mdlink recursive` -- (no description)
- [ ] `:Ft template` -- (no description)
- [ ] `:Ft open system` -- (no description)
- [ ] `:Ft open app` -- (no description)
- [ ] `:Ft search clear` -- (no description)
- [ ] `:Ft size refresh` -- (no description)
- [ ] `:Ft rename` -- (no description)
- [ ] `:Ft handles` -- (no description)
- [ ] `:Ft health` -- (no description)
- [ ] `:Ft resize` -- (no description)
- [ ] `:Ft git refresh` -- (no description)
- [ ] `:Ft filter clear` -- (no description)
- [ ] `:Ft find` -- Find files (optionally scoped to a directory)
- [ ] `:Ft cwd scope` -- Set the directory scope of the cwd policy (:cd | :tcd | :lcd)
- [ ] `:Ft cwd mode` -- Set the cwd/root policy (follow | project | nearest | lock | manual | tree_leads)
- [ ] `:Ft cwd lock` -- Lock the cwd to a directory (default: the current one)
- [ ] `:Ft create` -- (no description)
- [ ] `:Ft filter` -- (no description)
- [ ] `:Ft info close` -- (no description)
- [ ] `:Ft clipboard paste` -- (no description)
- [ ] `:Ft clipboard clear` -- (no description)
- [ ] `:Ft openas vsplit` -- (no description)
- [ ] `:Ft smartrename` -- (no description)
- [ ] `:Ft clipboard copy` -- (no description)
- [ ] `:Ft clipboard cut` -- (no description)
- [ ] `:Ft clipboard show` -- (no description)
- [ ] `:Ft info` -- (no description)
- [ ] `:Ft openas split` -- (no description)
- [ ] `:Ft open pick` -- (no description)
- [ ] `:Ft openas badd` -- (no description)
- [ ] `:Ft reveal resume` -- (no description)
- [ ] `:Ft reveal pause` -- (no description)
- [ ] `:Ft openas tabnew` -- (no description)
- [ ] `:Ft grep` -- (no description)
- [ ] `:Ft reveal` -- (no description)
- [ ] `:Ft safety list` -- (no description)
- [ ] `:Ft safety dry-run` -- (no description)
- [ ] `:Ft copy absolute` -- (no description)
- [ ] `:Ft link` -- (no description)
- [ ] `:Ft copy uri` -- (no description)
- [ ] `:Ft cwd unlock` -- (no description)
- [ ] `:Ft cwd forget` -- (no description)
- [ ] `:Ft watcher exit` -- (no description)
- [ ] `:Ft hooks events` -- (no description)
- [ ] `:Ft hooks clear` -- (no description)
- [ ] `:Ft cwd status` -- (no description)
- [ ] `:Ft watcher enter` -- (no description)
- [ ] `:Ft refs status` -- (no description)
- [ ] `:Ft refs undo` -- (no description)
- [ ] `:Ft cwd toggle` -- (no description)
- [ ] `:Ft cwd here` -- (no description)
- [ ] `:Ft copy project_root` -- (no description)
- [ ] `:Ft filelist files abs` -- (no description)
- [ ] `:Ft copy name` -- (no description)
- [ ] `:Ft filelist dirs rel` -- (no description)
- [ ] `:Ft filelist files rel` -- (no description)
- [ ] `:Ft filelist dirs abs` -- (no description)
- [ ] `:Ft move` -- (no description)
- [ ] `:Ft copy pick` -- (no description)
- [ ] `:Ft trash undo` -- (no description)
- [ ] `:Ft trash history` -- (no description)
- [ ] `:Ft mdrefs confirm` -- (no description)
- [ ] `:Ft trash dry-run` -- (no description)
- [ ] `:Ft mdrefs cancel` -- (no description)
- [ ] `:Ft breadcrumbs update` -- (no description)
- [ ] `:Ft require relative` -- (no description)
- [ ] `:Ft require` -- (no description)
- [ ] `:Ft copy stem` -- (no description)
- [ ] `:Ft traverse down` -- (no description)
- [ ] `:Ft copy project_relative` -- (no description)
- [ ] `:Ft copy line` -- (no description)
- [ ] `:Ft copy dirname` -- (no description)
- [ ] `:Ft copy relative` -- (no description)
- [ ] `:Ft traverse up` -- (no description)

### :GithubStats

- [ ] `:GithubStats export` -- Export to CSV/Markdown: {repo|all} {clones|views|both} {filepath}
- [ ] `:GithubStats show` -- Show stats for repo/metric: {repo} {metric} [start] [end]
- [ ] `:GithubStats diff` -- Compare periods: {repo} {metric} {YYYY-MM} {YYYY-MM}
- [ ] `:GithubStats referrers` -- Show top referrers: {repo} [limit]
- [ ] `:GithubStats debug` -- Debug configuration and test API connection
- [ ] `:GithubStats summary` -- Show summary across all repos: {clones|views}
- [ ] `:GithubStats chart` -- Show sparkline chart: {repo} {clones|views|both} [start|range] [end]
- [ ] `:GithubStats paths` -- Show top paths: {repo} [limit]

### :Gopath

- [ ] `:Gopath open` -- Resolve & open the path under the cursor
- [ ] `:Gopath check` -- Check existence / offer to create the path under the cursor
- [ ] `:Gopath debug` -- Show resolution info for the path under the cursor
- [ ] `:Gopath cache add-root` -- Add a directory to the filesystem cache roots
- [ ] `:Gopath cache build` -- Rebuild the filesystem cache
- [ ] `:Gopath cache info` -- Show filesystem cache stats
- [ ] `:Gopath copy` -- Copy path:line:col to clipboard
- [ ] `:Gopath probe` -- Probe path under cursor/selection

### :GopathCacheAddRoot

- [ ] `:GopathCacheAddRoot` -- Gopath: add cache root (alias for :Gopath cache add-root <dir>)

### :GopathCacheBuild

- [ ] `:GopathCacheBuild` -- Gopath: rebuild fs cache (alias for :Gopath cache build)

### :GopathCacheInfo

- [ ] `:GopathCacheInfo` -- Gopath: show cache info (alias for :Gopath cache info)

### :GopathCheck

- [ ] `:GopathCheck` -- Gopath: check existence / offer create (alias for :Gopath check)

### :GopathCopy

- [ ] `:GopathCopy` -- Gopath: copy path:line:col (alias for :Gopath copy)

### :GopathDebug

- [ ] `:GopathDebug` -- Gopath: debug resolution (alias for :Gopath debug)

### :GopathOpen

- [ ] `:GopathOpen` -- Gopath: open target (alias for :Gopath open [mode])

### :GopathProbe

- [ ] `:GopathProbe` -- Gopath: probe path under cursor/selection (! = split)

### :GopathResolve

- [ ] `:GopathResolve` -- Gopath: show resolution result (alias for :Gopath debug)

### :GrepConfig

- [ ] `:GrepConfig` -- [pickers compat] :GrepConfig → :Pickers config grep

### :Harpoon

- [ ] `:Harpoon health` -- Run the Harpoon health check
- [ ] `:Harpoon menu` -- Open a Harpoon list UI (quick menu, telescope or fzf)
- [ ] `:Harpoon` -- Harpoon: unified list command
- [ ] `:Harpoon select` -- Jump to list entry <index>
- [ ] `:Harpoon preview` -- Full-screen preview of list entry <index> ('q' to close)
- [ ] `:Harpoon debug` -- Dump the current Harpoon list into a scratch buffer
- [ ] `:Harpoon add` -- Add a file to the list (default: current buffer, appended)
- [ ] `:Harpoon defaults sync` -- Add any missing default path (existing entries untouched)
- [ ] `:Harpoon pin` -- Pin a file as a persistent Harpoon default

### :HarpoonAddToList

- [ ] `:HarpoonAddToList` -- Harpoon: add a file at the TOP of the list (alias for :Harpoon add --front)

### :HarpoonAddToListPermanent

- [ ] `:HarpoonAddToListPermanent` -- Harpoon: add a file at the TOP and keep it as a default (alias for :Harpoon add --front --permanent)

### :HarpoonDebug

- [ ] `:HarpoonDebug` -- Harpoon: dump the current list (alias for :Harpoon debug)

### :HarpoonPersistPaths

- [ ] `:HarpoonPersistPaths` -- Harpoon: add any missing default path (alias for :Harpoon defaults sync)

### :HarpoonPin

- [ ] `:HarpoonPin` -- Harpoon: pin a file as a persistent default (alias for :Harpoon pin)

### :Hover

- [ ] `:Hover pin` -- Keep this hover on screen while the cursor goes elsewhere
- [ ] `:Hover zen` -- Put the hover on screen full screen, or take it back
- [ ] `:Hover resize` -- Make the hover on screen bigger or smaller
- [ ] `:Hover next` -- Step to the next plugin with something to say about this place
- [ ] `:Hover why` -- Say why nothing hovered at the cursor
- [ ] `:Hover office` -- render office documents through a PDF instead of showing a badge
- [ ] `:Hover status` -- Report the mode and every switch in one message
- [ ] `:Hover nav` -- Move the magnified view
- [ ] `:Hover mode` -- Set the mode: auto opens by itself, manual only on request, off not at all
- [ ] `:Hover images` -- whether pictures and rasterized PDF pages are drawn into the float
- [ ] `:Hover zoom` -- Magnify a detail of the picture on screen, or step back out
- [ ] `:Hover toggle` -- Turn the hover off for this session, or back on
- [ ] `:Hover show` -- Show the hover for whatever is under the cursor, ignoring every volume switch
- [ ] `:Hover auto` -- Which target types open by themselves; a type toggles it, `all`/`none` set every one
- [ ] `:Hover border` -- Border style: rounded, single, double, heavy, ascii, dashed, block, solid, shadow, none
- [ ] `:Hover links web fetch` -- fetch a hovered link for its status code and page title (implies `links web on`)
- [ ] `:Hover links web fetch pdf` -- show a link that answers with a PDF as its first page, paged and zoomable
- [ ] `:Hover links web` -- whether http(s) links hover (off by default: documentation is made of links)
- [ ] `:Hover links` -- whether a target written with link syntax hovers at all
- [ ] `:Hover links web shot eager` -- let the automatic trigger render a page, not only an explicit request
- [ ] `:Hover links web shot` -- render a hovered link in a headless browser and draw the page into the float
- [ ] `:Hover paths code` -- whether a bare path hovers inside executable code, not just comments and strings
- [ ] `:Hover positions` -- whether a plugin may say something about a cursor position that points at nothing
- [ ] `:Hover paths missing` -- whether a bare path that resolves to nothing is reported as broken
- [ ] `:Hover paths` -- whether a path written in prose or a comment hovers

### :Image

- [ ] `:Image paste` -- Save an image from the clipboard and link it; with {name} named directly instead of the configured name prompt
- [ ] `:Image screenshot` -- Capture a screen selection interactively, save it and link it
- [ ] `:Image list` -- List the images in the buffer (or in the selection) and show one
- [ ] `:Image prev` -- Jump to the buffer's previous image and show it
- [ ] `:Image` -- :Image — show, compare and insert images in the terminal
- [ ] `:Image show` -- Show an image (without a path: the one under the cursor); an http(s) URL too with display.remote.enabled
- [ ] `:Image replace` -- Replace an existing image with the clipboard contents
- [ ] `:Image next` -- Jump to the buffer's next image and show it
- [ ] `:Image export` -- Export an image as a PDF, next to the source file
- [ ] `:Image optimise` -- Write a smaller copy next to the source: metadata stripped, best compression (photo.png -> photo.optimised.png); needs ImageMagick
- [ ] `:Image pin` -- Pin the display — no clearing on cursor movement
- [ ] `:Image draw` -- Draw an image at a named position in the current window (without a path: the one under the cursor)
- [ ] `:Image zen` -- Show an image large, in an editable window (not a preview window)
- [ ] `:Image check` -- Check whether this terminal can display images
- [ ] `:Image info` -- An image's format, dimensions and size
- [ ] `:Image scale` -- Write a resized copy next to the source (photo.png -> photo.scaled.png); needs ImageMagick
- [ ] `:Image compare` -- Pick two images below cfile/cwd/path and compare them side by side
- [ ] `:Image calibrate` -- Measure this terminal's image placement (test card, nudged into place); the result is stored
- [ ] `:Image ocr` -- Read the text out of an image into a scratch buffer (tesseract); --lang=<code> overrides ocr.lang
- [ ] `:Image convert` -- Write a copy in another format, same stem (photo.jpg -> photo.png); `pdf` takes the same route as :Image export
- [ ] `:Image gallery` -- Show the buffer's (or the selection's) images side by side
- [ ] `:Image redact` -- Open an image in redaction mode: mark boxes and black them out, the original stays
- [ ] `:Image pickers` -- Browse images below cfile/cwd/path (live preview with snacks.picker)
- [ ] `:Image debug` -- Measure image placement: report (log draws), columns (constant vs. scaling offset), float (is a window where it says it is)

### :Insights

- [ ] `:Insights devserver` -- List tracked dev servers
- [ ] `:Insights smells` -- Magic numbers + unconfigured behaviour constants (flags + optional directory)
- [ ] `:Insights count` -- Count project files
- [ ] `:Insights clipboard` -- Copy tree to clipboard
- [ ] `:Insights fileinfo` -- Toggle fs.stat float for current buffer
- [ ] `:Insights tree` -- Write project file tree
- [ ] `:Insights symbols` -- Symbol index (scope/type/ui in any order)
- [ ] `:Insights metrics` -- Lua code metrics (flags + optional directory)
- [ ] `:Insights cache info` -- Show symbol cache stats
- [ ] `:Insights cache build` -- Rebuild symbol cache
- [ ] `:Insights devserver list` -- List tracked dev servers
- [ ] `:Insights cache clear` -- Clear symbol cache
- [ ] `:Insights conflicts` -- Quickfix unresolved git conflicts
- [ ] `:Insights unimported` -- Check used-but-unimported components
- [ ] `:Insights imports unused` -- Bound import names never referenced again in their file
- [ ] `:Insights imports` -- import/require usage report (filters + optional picker UI)
- [ ] `:Insights imports reverse` -- List every file that imports <module>
- [ ] `:Insights compress` -- Archive a directory (default: cwd)

### :KitPreview

- [ ] `:KitPreview` -- lib.nvim.ui.kit: live theme playground

### :LastSession

- [ ] `:LastSession` -- Load the 'last' session (nvim +LastSession)

### :Lib

- [ ] `:Lib helptags` -- Regenerate all helptags now
- [ ] `:Lib deps status` -- Every declared tool across every plugin, and what's missing here
- [ ] `:Lib cwd-here` -- lcd to the current buffer's directory
- [ ] `:Lib deps install` -- Offer to install missing external tools — one plugin's, or every plugin's (asks first)
- [ ] `:Lib deps show` -- List a plugin's declared external tools, why each matters, and what's missing
- [ ] `:Lib ps-profile` -- Open the active PowerShell profile

### :LibAutocmdDocs

- [ ] `:LibAutocmdDocs` -- Write the registered autocmds into bindings/autocmd as markdown

### :LibAutocmdDocsAll

- [ ] `:LibAutocmdDocsAll` -- Write bindings/autocmd for every repo under dir/$REPOS_DIR that this session registered something for

### :LibAutocmdDocsCheck

- [ ] `:LibAutocmdDocsCheck` -- Check bindings/autocmd against what is registered

### :LibBindingsAudit

- [ ] `:LibBindingsAudit` -- Keymap actions vs. command routes, registered in this session (optional: scope to a repo path)

### :LibBindingsAuditChecklist

- [ ] `:LibBindingsAuditChecklist` -- Markdown checklist over every keymap action and command route, for a manual runtime pass (optional: scope to a repo path; never invokes anything)

### :LibBindingsAuditGaps

- [ ] `:LibBindingsAuditGaps` -- Keymap actions with no obvious command counterpart (optional: scope to a repo path)

### :LibBindingsAuditKeys

- [ ] `:LibBindingsAuditKeys` -- Actions whose every key needs an extended terminal encoding (optional: scope to a repo path)

### :LibBindingsAuditNaming

- [ ] `:LibBindingsAuditNaming` -- Routes whose last path segment is a bare vague word (deep/full/check/...) -- candidates for a naming review, not a verdict

### :LibBindingsAuditPrefixes

- [ ] `:LibBindingsAuditPrefixes` -- Command names that are a strict prefix of another live command (<Tab>/abbreviation collisions)

### :LibKeymapConflicts

- [ ] `:LibKeymapConflicts` -- lhs values claimed by more than one plugin/registration in this session

### :LibLogger

- [ ] `:LibLogger` -- lib.nvim.logger control: show|on|off|level <l>|dump|clear|tags

### :LibUsercmdDocs

- [ ] `:LibUsercmdDocs` -- Write the registered user commands into bindings/usercmd as markdown

### :LibUsercmdDocsCheck

- [ ] `:LibUsercmdDocsCheck` -- Check bindings/usercmd against what is registered

### :LintAndFormat

- [ ] `:LintAndFormat` -- Run eslint_d --fix then prettier --write on current file

### :LiveGrep

- [ ] `:LiveGrep` -- [pickers compat] :LiveGrep → :Pickers cwd grep

### :Lsp

- [ ] `:Lsp format` -- Format once, or control format-on-save
- [ ] `:Lsp hints` -- Inlay hints: control globally, or for one filetype
- [ ] `:Lsp lightbulb` -- Code-action indicator: control globally, or for one filetype
- [ ] `:Lsp start` -- Start servers for this buffer (auto-detect, or one by name)
- [ ] `:Lsp diag` -- Diagnostics into a list, or move within one
- [ ] `:Lsp log open` -- Open Neovim's LSP log file in a split
- [ ] `:Lsp log level` -- Set the LSP log level (trace|debug|info|warn|error|off)
- [ ] `:Lsp doctor` -- Per-buffer diagnosis (same as :LspDoctor)
- [ ] `:Lsp health` -- Run :checkhealth lsp
- [ ] `:Lsp info` -- Detailed LSP information for the current buffer
- [ ] `:Lsp servers` -- Servers set up, and the clients currently attached
- [ ] `:Lsp recover` -- Auto-recover servers that should be running here and are not
- [ ] `:Lsp status` -- Show what lsp.nvim has set up

### :LspDoctor

- [ ] `:LspDoctor` -- (no description)

### :LspFormat

- [ ] `:LspFormat` -- [lsp_conform] format current buffer once (silent)

### :LspFormatOff

- [ ] `:LspFormatOff` -- [lsp_conform] disable format-on-save (silent)

### :LspFormatOn

- [ ] `:LspFormatOn` -- [lsp_conform] enable format-on-save (silent)

### :LspFormatStatus

- [ ] `:LspFormatStatus` -- [lsp_conform] show state of formater

### :LspFormatToggle

- [ ] `:LspFormatToggle` -- [lsp_conform] toggle format-on-save (silent)

### :LspFormatWhich

- [ ] `:LspFormatWhich` -- Show formatter chain & availability for current buffer

### :LspInfo

- [ ] `:LspInfo` -- [lsp.usercmds] Show LSP information for current buffer

### :LspLog

- [ ] `:LspLog` -- [lsp.usercmds] Open LSP log file

### :LspMdHints

- [ ] `:LspMdHints` -- (no description)

### :LspRecover

- [ ] `:LspRecover` -- [lsp.usercmds] Auto-recover missing LSP servers

### :LspStartHere

- [ ] `:LspStartHere` -- [lsp.usercmds] Start LSP servers (auto-detect or specify name)

### :LspStatus

- [ ] `:LspStatus` -- [lsp.usercmds] Show LSP status for current buffer

### :LspWorkspaceDiagnosticsOff

- [ ] `:LspWorkspaceDiagnosticsOff` -- [lsp_workspace_diagnostics] disable workspace-wide diagnostics populate on LSP attach

### :LspWorkspaceDiagnosticsOn

- [ ] `:LspWorkspaceDiagnosticsOn` -- [lsp_workspace_diagnostics] enable workspace-wide diagnostics populate on LSP attach

### :LspWorkspaceDiagnosticsStatus

- [ ] `:LspWorkspaceDiagnosticsStatus` -- [lsp_workspace_diagnostics] show current state

### :LspWorkspaceDiagnosticsToggle

- [ ] `:LspWorkspaceDiagnosticsToggle` -- [lsp_workspace_diagnostics] toggle workspace-wide diagnostics populate on LSP attach

### :LuaLsInspectLibrary

- [ ] `:LuaLsInspectLibrary` -- [lsp.lua_ls] Inspect current workspace library configuration

### :LuaLsReloadLibrary

- [ ] `:LuaLsReloadLibrary` -- [lsp.lua_ls] Reload workspace library (useful when @types not detected)

### :LuaLsSetProfile

- [ ] `:LuaLsSetProfile` -- [lsp.lua_ls] Set library profile (minimal/normal/full)

### :MDTableAlign

- [ ] `:MDTableAlign` -- (no description)

### :MDTableCol

- [ ] `:MDTableCol dec` -- (no description)
- [ ] `:MDTableCol inc` -- (no description)

### :MDTableDebug

- [ ] `:MDTableDebug` -- (no description)

### :MDTableFixMissingSeparator

- [ ] `:MDTableFixMissingSeparator` -- (no description)

### :MDTableFlavor

- [ ] `:MDTableFlavor` -- (no description)

### :MDTableFoldAll

- [ ] `:MDTableFoldAll` -- (no description)

### :MDTableFoldRow

- [ ] `:MDTableFoldRow` -- (no description)

### :MDTableFromCSV

- [ ] `:MDTableFromCSV` -- (no description)

### :MDTableLint

- [ ] `:MDTableLint` -- (no description)

### :MDTableProfile

- [ ] `:MDTableProfile` -- (no description)

### :MDTableReflowHeader

- [ ] `:MDTableReflowHeader` -- (no description)

### :MDTableToCSV

- [ ] `:MDTableToCSV` -- (no description)

### :MDTableUnwrap

- [ ] `:MDTableUnwrap` -- (no description)

### :MDTableWrap

- [ ] `:MDTableWrap` -- (no description)

### :MDTableWrapVisible

- [ ] `:MDTableWrapVisible` -- (no description)

### :MDTableWrapVisual

- [ ] `:MDTableWrapVisual` -- (no description)

### :MDView

- [ ] `:MDView breadcrumbs export` -- Write the session breadcrumbs outline to a file (default: stdpath log)
- [ ] `:MDView breadcrumbs` -- Show the session breadcrumbs (document + heading over time)
- [ ] `:MDView breadcrumbs clear` -- Discard the recorded session breadcrumbs
- [ ] `:MDView preview-tab` -- Toggle the in-Neovim tab preview (works standalone, no server needed)
- [ ] `:MDView log debug` -- Show the internal log ring, filtered to DEBUG and above
- [ ] `:MDView log info` -- Show the internal log ring, filtered to INFO and above
- [ ] `:MDView blanklines` -- Show every blank line as extra space, or collapse them (CommonMark default); no argument toggles
- [ ] `:MDView log error` -- Show the internal log ring, filtered to ERROR and above
- [ ] `:MDView log warn` -- Show the internal log ring, filtered to WARN and above
- [ ] `:MDView log trace` -- Show the internal log ring, filtered to TRACE and above
- [ ] `:MDView overlay list` -- List the known preview overlays and whether each is on
- [ ] `:MDView theme` -- Switch the preview theme (optionally -light/-dark); no argument reports the current theme
- [ ] `:MDView log` -- Show the internal log ring
- [ ] `:MDView cursor` -- Set the Neovim-cursor marker in the preview (line|caret|section|off|toggle — toggle flips section on/off)
- [ ] `:MDView pin` -- Hold the preview on the current document instead of following the active buffer; no argument toggles
- [ ] `:MDView sync` -- Pause/resume the nvim->browser scroll sync; no argument reports the state
- [ ] `:MDView reveal` -- Reveal/hide all private (```private) blocks in the preview
- [ ] `:MDView file-log toggle` -- Toggle persistent file logging, then report the state
- [ ] `:MDView log export` -- Write the internal log ring to a file (default: stdpath log)
- [ ] `:MDView file-log status` -- Report persistent file logging state without changing anything
- [ ] `:MDView file-log` -- Toggle persistent file logging, then report the state
- [ ] `:MDView file-log off` -- Disable persistent file logging
- [ ] `:MDView file-log on` -- Enable persistent file logging (optionally set its path)
- [ ] `:MDView weblogs` -- Show the relay's captured stdout, including [client] browser-side diagnostics
- [ ] `:MDView overlay` -- Toggle a preview overlay (floating TOC, …); no name lists them
- [ ] `:MDView start` -- Start the relay and open the preview for the current buffer (or the given file)
- [ ] `:MDView diagnose` -- Write a full component-state diagnostics report to a file and open it
- [ ] `:MDView standalone` -- Preview via the relay's own file watcher, with no Neovim in the chain
- [ ] `:MDView open` -- Re-open a browser tab against the already-running session

### :Markdown

- [ ] `:Markdown table` -- (no description)
- [ ] `:Markdown refs` -- (no description)
- [ ] `:Markdown export` -- (no description)
- [ ] `:Markdown mdview` -- (no description)
- [ ] `:Markdown gaps` -- (no description)
- [ ] `:Markdown image` -- (no description)
- [ ] `:Markdown create` -- (no description)
- [ ] `:Markdown toc` -- (no description)
- [ ] `:Markdown list` -- (no description)
- [ ] `:Markdown render` -- (no description)
- [ ] `:Markdown headline_spacing` -- (no description)
- [ ] `:Markdown links` -- (no description)
- [ ] `:Markdown scope` -- (no description)
- [ ] `:Markdown preview` -- (no description)

### :MarkdownNvimUnderlineHeadings

- [ ] `:MarkdownNvimUnderlineHeadings` -- (no description)

### :MasonInstallAll

- [ ] `:MasonInstallAll` -- NvChad: install every configured Mason package

### :MdFormat

- [ ] `:MdFormat` -- [lsp] Format Markdown (prefer mdformat for .md)

### :MdFormatPrettier

- [ ] `:MdFormatPrettier` -- [lsp] Format via Prettier

### :MdSetRoot

- [ ] `:MdSetRoot` -- [md_words] Set project root for Markdown word scanning (empty = cwd)

### :MdWordStats

- [ ] `:MdWordStats` -- [md_words] Show word-cache statistics

### :MyOptList

- [ ] `:MyOptList` -- List all options config keys

### :MyOptSet

- [ ] `:MyOptSet` -- Set options config value

### :MyOptShow

- [ ] `:MyOptShow` -- Show options config value

### :MyPlugins

- [ ] `:MyPlugins clone` -- Clone every listed plugin not yet present (or just --only=<name>) into dir/$REPOS_DIR; --dry-run previews without cloning
- [ ] `:MyPlugins list` -- Render every plugin in plugins.personal.list, and whether it's present in dir/$REPOS_DIR, into a scratch buffer (yank/:sort/search it; no git)
- [ ] `:MyPlugins pull` -- git pull --ff-only on every present listed plugin (or just --only=<name>)
- [ ] `:MyPlugins update` -- Fetch + fast-forward pull every present listed plugin (or just --only=<name>) — brings this machine level with another machine's pushed commits
- [ ] `:MyPlugins dashboard` -- Open reposcope.nvim's git-status dashboard (:Reposcope status) for dir/$REPOS_DIR

### :MyPluginsDashboard

- [ ] `:MyPluginsDashboard` -- Shorthand for :MyPlugins dashboard [dir] — opens reposcope.nvim's git-status dashboard

### :MyReposUpdate

- [ ] `:MyReposUpdate` -- [usrcmds.update_repos] Fetch and update git repositories in a directory (or just --only=<name>)

### :NeoTreeCheckHealth

- [ ] `:NeoTreeCheckHealth` -- Run Neo-tree config health checks

### :NeoTreeDebugSources

- [ ] `:NeoTreeDebugSources` -- [Neo-tree] Debug source detection

### :NeotestActions

- [ ] `:NeotestActions` -- Open Neotest actions picker

### :NeotestDebugAdapters

- [ ] `:NeotestDebugAdapters` -- [NeoTest Debug] Show adapter status

### :NeotestDebugFile

- [ ] `:NeotestDebugFile` -- [NeoTest Debug] Show file test status

### :NeotestDebugFramework

- [ ] `:NeotestDebugFramework` -- [NeoTest Debug] Framework detection details

### :NeotestDebugNearest

- [ ] `:NeotestDebugNearest` -- Debug nearest test using DAP

### :NeotestDebugRoot

- [ ] `:NeotestDebugRoot` -- [NeoTest Debug] Test root detection

### :NeotestDebugState

- [ ] `:NeotestDebugState` -- [NeoTest Debug] Show current state

### :NeotestOutput

- [ ] `:NeotestOutput` -- Open Neotest output

### :NeotestOutputPanelToggle

- [ ] `:NeotestOutputPanelToggle` -- Toggle Neotest output panel

### :NeotestRunAll

- [ ] `:NeotestRunAll` -- Run all tests in project

### :NeotestRunFile

- [ ] `:NeotestRunFile` -- Run all tests in current file

### :NeotestRunNearest

- [ ] `:NeotestRunNearest` -- Run nearest test

### :NeotestSummaryToggle

- [ ] `:NeotestSummaryToggle` -- Toggle Neotest summary

### :NeotestValidateConsumer

- [ ] `:NeotestValidateConsumer` -- Validate Neo-tree tests consumer setup

### :NeotestWatchToggle

- [ ] `:NeotestWatchToggle` -- Toggle Neotest watch mode

### :NotesFiles

- [ ] `:NotesFiles` -- [pickers coll] :NotesFiles → :Pickers notes files

### :NotesGrep

- [ ] `:NotesGrep` -- [pickers coll] :NotesGrep → :Pickers notes grep

### :NotesLuaFiles

- [ ] `:NotesLuaFiles` -- [pickers coll] :NotesLuaFiles → :Pickers notes_lua files

### :NotesLuaGrep

- [ ] `:NotesLuaGrep` -- [pickers coll] :NotesLuaGrep → :Pickers notes_lua grep

### :NotesLuaSmart

- [ ] `:NotesLuaSmart` -- [pickers coll] :NotesLuaSmart → :Pickers notes_lua smart

### :NotesNvimFiles

- [ ] `:NotesNvimFiles` -- [pickers coll] :NotesNvimFiles → :Pickers notes_nvim files

### :NotesNvimGrep

- [ ] `:NotesNvimGrep` -- [pickers coll] :NotesNvimGrep → :Pickers notes_nvim grep

### :NotesNvimSmart

- [ ] `:NotesNvimSmart` -- [pickers coll] :NotesNvimSmart → :Pickers notes_nvim smart

### :NotesSmart

- [ ] `:NotesSmart` -- [pickers coll] :NotesSmart → :Pickers notes smart

### :OpenWithSystemApplication

- [ ] `:OpenWithSystemApplication` -- (no description)

### :Pickers

- [ ] `:Pickers builtin` -- Native picker (git/lsp/search/…) — see docs/builtins.md
- [ ] `:Pickers` -- [pickers.nvim] :Pickers [scope] [nav|action] [action]
- [ ] `:Pickers cwd` -- Scope: cwd
- [ ] `:Pickers notes` -- User-defined collection: notes
- [ ] `:Pickers folder` -- Scope: folder
- [ ] `:Pickers wkdbooks_lua` -- User-defined collection: wkdbooks_lua
- [ ] `:Pickers spickzettel` -- User-defined collection: spickzettel
- [ ] `:Pickers checklists` -- User-defined collection: checklists
- [ ] `:Pickers drives` -- Scope: drives
- [ ] `:Pickers wkdbooks` -- Scope: wkdbooks
- [ ] `:Pickers system` -- Scope: system
- [ ] `:Pickers config` -- Scope: config
- [ ] `:Pickers dir` -- Directory navigation (depth / alias / explicit path)
- [ ] `:Pickers wkdbooks_nvim` -- User-defined collection: wkdbooks_nvim
- [ ] `:Pickers repos` -- Scope: repos
- [ ] `:Pickers notes_nvim` -- User-defined collection: notes_nvim
- [ ] `:Pickers notes_lua` -- User-defined collection: notes_lua

### :PickersRepeat

- [ ] `:PickersRepeat` -- [pickers] :PickersRepeat — reopen the last :Pickers action

### :PickersResume

- [ ] `:PickersResume` -- [pickers] :PickersResume — reopen the last picker with its last query

### :PickersScopes

- [ ] `:PickersScopes` -- [pickers] :PickersScopes — list every resolvable scope (built-ins + collections)

### :PowershellProfile

- [ ] `:PowershellProfile` -- Open the current PowerShell profile

### :PrettierFormat

- [ ] `:PrettierFormat` -- Run prettier --write on current file (requires prettier config in project root)

### :RA

- [ ] `:RA usage` -- Report which of your own keymaps/commands you actually press
- [ ] `:RA inspect` -- Walk a live package.loaded table -- functions, tables, metatables, what's shadowed
- [ ] `:RA history` -- Browse this project's request history and reopen one
- [ ] `:RA send` -- Send the current buffer as an HTTP request
- [ ] `:RA history clear` -- Clear this project's request history
- [ ] `:RA import` -- Import a curl command (visual selection, or the clipboard) into a new request buffer
- [ ] `:RA env` -- Show/select the environment {{vars}} resolve against
- [ ] `:RA request` -- Open a new HTTP request buffer
- [ ] `:RA cancel` -- Cancel the in-flight request, if any
- [ ] `:RA yank` -- Yank just the last response's body to the unnamed register
- [ ] `:RA provenance` -- Who wrapped a function right now — e.g. :RA provenance vim.notify
- [ ] `:RA startup start` -- Start watching for main-loop stalls (reports after 12s)
- [ ] `:RA startup watch` -- Like `startup start`, but keeps measuring until `startup report`
- [ ] `:RA startup probe` -- Print the --cmd line that measures a startup from the very beginning
- [ ] `:RA loaded snapshots` -- List saved loaded snapshots for <prefix>
- [ ] `:RA export` -- Export the request under the cursor as a curl command, yanked to the unnamed register
- [ ] `:RA loaded snapshot` -- Persist a loaded-vs-declared snapshot for <prefix>
- [ ] `:RA usage start` -- Start counting keymap/command presses (opt-in, local only)

### :RARequest

- [ ] `:RARequest` -- Open a new HTTP request buffer (alias: :RA request)

### :RASend

- [ ] `:RASend` -- Send the current buffer as an HTTP request (alias: :RA send)

### :RATelemetryNvimConfig

- [ ] `:RATelemetryNvimConfig` -- runtime-analysis.telemetry: alias for :RATelemetry setup nvim-config

### :RATelemetryNvimConfigFull

- [ ] `:RATelemetryNvimConfigFull` -- runtime-analysis.telemetry: alias for :RATelemetry full nvim-config

### :RATelemetrySetupAllFull

- [ ] `:RATelemetrySetupAllFull` -- runtime-analysis.telemetry: same as :RATelemetrySetupAll, forcing profile_args + timing on

### :RATelemetryStartAll

- [ ] `:RATelemetryStartAll` -- runtime-analysis.telemetry: start every live instance (same as :RATelemetry start)

### :RepoFiles

- [ ] `:RepoFiles` -- [pickers] :RepoFiles [repo] — pick repo (or jump to [repo]), then find files

### :RepoGrep

- [ ] `:RepoGrep` -- [pickers] :RepoGrep [repo] — pick repo (or jump to [repo]), then live grep

### :Reposcope

- [ ] `:Reposcope print-dev` -- Print whether developer mode is currently active
- [ ] `:Reposcope stats` -- Display collected request stats and metrics
- [ ] `:Reposcope prompt` -- Reload visible prompt fields (e.g. :Reposcope prompt prefix keywords)
- [ ] `:Reposcope close` -- Close all Reposcope windows and buffers
- [ ] `:Reposcope filter-clear` -- Clear the active filter and show the full list again
- [ ] `:Reposcope favorites` -- List or clear favorited repositories (:Reposcope favorites list|clear)
- [ ] `:Reposcope status` -- Show the git status overview of all repositories in a directory (or one repository)
- [ ] `:Reposcope sort` -- Open an interactive menu to sort the repository list
- [ ] `:Reposcope session` -- Manage the persisted search session (:Reposcope session save|restore|clear)
- [ ] `:Reposcope toggle-dev` -- Toggle developer mode (debug logging, internal info)
- [ ] `:Reposcope update` -- Update (fetch + ff-only pull) all cloned repositories in a directory
- [ ] `:Reposcope providers` -- List available providers and show which one is active
- [ ] `:Reposcope filter-prompt` -- Open a floating prompt to filter repositories interactively
- [ ] `:Reposcope start` -- Open the Reposcope UI
- [ ] `:Reposcope queries` -- Show your most-frequent search queries (:Reposcope queries list|clear)
- [ ] `:Reposcope skipped-readmes` -- Print the number of debounced (skipped) README fetches

### :Sandbox

- [ ] `:Sandbox container rename` -- Rename a container
- [ ] `:Sandbox volume list` -- List all local volumes
- [ ] `:Sandbox volume create` -- Create a new named volume
- [ ] `:Sandbox image inspect` -- Inspect detailed information about an image
- [ ] `:Sandbox image load` -- Load (import) an image from a tarball on disk
- [ ] `:Sandbox image history` -- Show an image's layer history
- [ ] `:Sandbox image save` -- Save (export) an image to a tarball on disk
- [ ] `:Sandbox image build` -- Build an image from a Dockerfile/Containerfile (streams to a terminal buffer)
- [ ] `:Sandbox network connect` -- Connect a container to a network
- [ ] `:Sandbox network disconnect` -- Disconnect a container from a network
- [ ] `:Sandbox volume inspect` -- Inspect detailed information about a volume
- [ ] `:Sandbox network inspect` -- Inspect detailed information about a network
- [ ] `:Sandbox network create` -- Create a new named network
- [ ] `:Sandbox network list` -- List all local networks
- [ ] `:Sandbox compose up` -- Start the compose project detected in cwd (detached)
- [ ] `:Sandbox image tag` -- Tag a local image with a new repository:tag
- [ ] `:Sandbox image pull` -- Pull an image (--buffer: stream to a terminal buffer)
- [ ] `:Sandbox container exec-once` -- Run a one-off command inside a container (non-interactive)  [workdir=<path>]
- [ ] `:Sandbox container exec` -- Open a shell session inside a running container  [workdir=<path>]
- [ ] `:Sandbox container logs` -- Show logs of a container
- [ ] `:Sandbox container list` -- List all containers
- [ ] `:Sandbox image push` -- Push an image to a remote registry
- [ ] `:Sandbox container unpause` -- Resume a paused container's processes
- [ ] `:Sandbox container inspect` -- Inspect detailed information about a container
- [ ] `:Sandbox image list` -- List all local images
- [ ] `:Sandbox container pause` -- Pause a running container's processes
- [ ] `:Sandbox container cp` -- Copy a file/directory between the host and a container (either side may be <id>:<path>)
- [ ] `:Sandbox container run` -- Interactively create and start a new container (prompts for image, name, ports, volumes, env)
- [ ] `:Sandbox container top` -- List the processes running inside a container
- [ ] `:Sandbox container stats` -- Show a one-shot resource usage snapshot of a container
- [ ] `:Sandbox wsl export` -- Export a distro to a tarball on disk
- [ ] `:Sandbox wsl start` -- Start a WSL distro
- [ ] `:Sandbox wsl list` -- List all registered WSL distributions
- [ ] `:Sandbox devcontainer build` -- Build/pull a .devcontainer/devcontainer.json's image and start a container from it
- [ ] `:Sandbox wsl set-version` -- Toggle a distro between WSL1/WSL2
- [ ] `:Sandbox wsl exec` -- Open a shell or run a command inside a WSL distro
- [ ] `:Sandbox wsl set-default` -- Set a distro as the WSL default
- [ ] `:Sandbox wsl import` -- Import a distro from a tarball
- [ ] `:Sandbox docs generate` -- Regenerate docs/GENERATED_COMMANDS.md from the live route table, so docs/BINDINGS.md (hand-maintained) can be diffed against it to catch drift
- [ ] `:Sandbox devcontainer attach` -- Open a shell in the running devcontainer for the project in cwd
- [ ] `:Sandbox compose logs` -- Show logs for the compose project detected in cwd
- [ ] `:Sandbox engine set` -- Switch the active engine for this session
- [ ] `:Sandbox registry logout` -- Log out of a registry
- [ ] `:Sandbox compose ps` -- List services in the compose project detected in cwd
- [ ] `:Sandbox engine get` -- Show the currently active engine and why
- [ ] `:Sandbox registry login` -- Log in to a registry (prompts for username/password)

### :Sbx

- [ ] `:Sbx devcontainer attach` -- Open a shell in the running devcontainer for the project in cwd
- [ ] `:Sbx compose up` -- Start the compose project detected in cwd (detached)
- [ ] `:Sbx image list` -- List all local images
- [ ] `:Sbx image history` -- Show an image's layer history
- [ ] `:Sbx container inspect` -- Inspect detailed information about a container
- [ ] `:Sbx network connect` -- Connect a container to a network
- [ ] `:Sbx image load` -- Load (import) an image from a tarball on disk
- [ ] `:Sbx network inspect` -- Inspect detailed information about a network
- [ ] `:Sbx network disconnect` -- Disconnect a container from a network
- [ ] `:Sbx container cp` -- Copy a file/directory between the host and a container (either side may be <id>:<path>)
- [ ] `:Sbx container run` -- Interactively create and start a new container (prompts for image, name, ports, volumes, env)
- [ ] `:Sbx image build` -- Build an image from a Dockerfile/Containerfile (streams to a terminal buffer)
- [ ] `:Sbx wsl export` -- Export a distro to a tarball on disk
- [ ] `:Sbx wsl import` -- Import a distro from a tarball
- [ ] `:Sbx wsl set-version` -- Toggle a distro between WSL1/WSL2
- [ ] `:Sbx wsl set-default` -- Set a distro as the WSL default
- [ ] `:Sbx image save` -- Save (export) an image to a tarball on disk
- [ ] `:Sbx image tag` -- Tag a local image with a new repository:tag
- [ ] `:Sbx wsl start` -- Start a WSL distro
- [ ] `:Sbx image push` -- Push an image to a remote registry
- [ ] `:Sbx wsl list` -- List all registered WSL distributions
- [ ] `:Sbx devcontainer build` -- Build/pull a .devcontainer/devcontainer.json's image and start a container from it
- [ ] `:Sbx image inspect` -- Inspect detailed information about an image
- [ ] `:Sbx network create` -- Create a new named network
- [ ] `:Sbx container exec-once` -- Run a one-off command inside a container (non-interactive)  [workdir=<path>]
- [ ] `:Sbx container exec` -- Open a shell session inside a running container  [workdir=<path>]
- [ ] `:Sbx volume create` -- Create a new named volume
- [ ] `:Sbx container logs` -- Show logs of a container
- [ ] `:Sbx volume list` -- List all local volumes
- [ ] `:Sbx container list` -- List all containers
- [ ] `:Sbx compose ps` -- List services in the compose project detected in cwd
- [ ] `:Sbx engine set` -- Switch the active engine for this session
- [ ] `:Sbx compose logs` -- Show logs for the compose project detected in cwd
- [ ] `:Sbx docs generate` -- Regenerate docs/GENERATED_COMMANDS.md from the live route table, so docs/BINDINGS.md (hand-maintained) can be diffed against it to catch drift
- [ ] `:Sbx container rename` -- Rename a container
- [ ] `:Sbx network list` -- List all local networks
- [ ] `:Sbx container top` -- List the processes running inside a container
- [ ] `:Sbx container stats` -- Show a one-shot resource usage snapshot of a container
- [ ] `:Sbx engine get` -- Show the currently active engine and why
- [ ] `:Sbx wsl exec` -- Open a shell or run a command inside a WSL distro
- [ ] `:Sbx registry logout` -- Log out of a registry
- [ ] `:Sbx registry login` -- Log in to a registry (prompts for username/password)
- [ ] `:Sbx volume inspect` -- Inspect detailed information about a volume
- [ ] `:Sbx container unpause` -- Resume a paused container's processes
- [ ] `:Sbx container pause` -- Pause a running container's processes
- [ ] `:Sbx image pull` -- Pull an image (--buffer: stream to a terminal buffer)

### :Session

- [ ] `:Session rename` -- Rename a session: :Session rename <old> <new>
- [ ] `:Session save-timestamp` -- Save session with timestamp suffix
- [ ] `:Session load-tab` -- Load a tab session into a new tab: :Session load-tab <name>
- [ ] `:Session load` -- Load session [name] (omit for the configured default_name)
- [ ] `:Session save-layout` -- Save the current window-split layout: :Session save-layout <name>
- [ ] `:Session load-layout` -- Restore a window-split layout: :Session load-layout <name>
- [ ] `:Session toggle-track` -- Toggle git skip-worktree on a session file
- [ ] `:Session save-tab` -- Save only the current tab's window layout [name]
- [ ] `:Session list` -- List all saved sessions
- [ ] `:Session current` -- Print the active session name

### :SessionLoad

- [ ] `:SessionLoad` -- Open the session picker with preview (Snacks/Telescope)

### :Spellcheck

- [ ] `:Spellcheck` -- Spell/grammar review

### :SpickzettelFiles

- [ ] `:SpickzettelFiles` -- [pickers coll] :SpickzettelFiles → :Pickers spickzettel files

### :SpickzettelGrep

- [ ] `:SpickzettelGrep` -- [pickers coll] :SpickzettelGrep → :Pickers spickzettel grep

### :SpickzettelSmart

- [ ] `:SpickzettelSmart` -- [pickers coll] :SpickzettelSmart → :Pickers spickzettel smart

### :Spotlight

- [ ] `:Spotlight prev` -- Jump to the previous spotlight occurrence  (! ignores nav.scope)
- [ ] `:Spotlight toggle` -- Toggle a spotlight (cursor token, range selection, or explicit TEXT)
- [ ] `:Spotlight map` -- Mark every matching line in the sign column (all spotlights, or just TEXT's)
- [ ] `:Spotlight map clear` -- Clear the sign-column occurrence map in the current buffer
- [ ] `:Spotlight lock` -- Toggle whether a spotlight keeps its palette slot permanently (TEXT, or the cursor token)
- [ ] `:Spotlight yank` -- Yank matching lines to the unnamed register (all spotlights, or just TEXT's)
- [ ] `:Spotlight` -- Spotlight: persistent multi-token highlighting
- [ ] `:Spotlight sets switch` -- Clear the active spotlights and restore a saved set
- [ ] `:Spotlight refresh` -- Re-apply every spotlight to every window (and redefine the palette)
- [ ] `:Spotlight sets list` -- List every saved set and how many spotlights it holds
- [ ] `:Spotlight winopt` -- Per-window opt-out: on / off / toggle (default) / status
- [ ] `:Spotlight line` -- Toggle whole-line rendering for a spotlight (TEXT, or the cursor token)
- [ ] `:Spotlight list` -- Open the spotlight list (swatch + pattern + match count)  [filter]
- [ ] `:Spotlight qf` -- Matching lines to the quickfix list (all spotlights, or just TEXT's)
- [ ] `:Spotlight next` -- Jump to the next spotlight occurrence  (! ignores nav.scope)
- [ ] `:Spotlight qf all` -- Matching lines across every loaded buffer to the quickfix list
- [ ] `:Spotlight add` -- Add a spotlight for the literal TEXT
- [ ] `:Spotlight here` -- Toggle a spotlight for only this occurrence (cursor token or range selection)
- [ ] `:Spotlight persist` -- Per-file persistence: on / off / default (clear override) / status

### :StartupCheck

- [ ] `:StartupCheck` -- Startup: report policy violations only

### :StartupReport

- [ ] `:StartupReport` -- Startup: phase timeline (themed float)

### :SystemInfo

- [ ] `:SystemInfo` -- Show system information (float + clipboard)

### :TableViewBox

- [ ] `:TableViewBox` -- (no description)

### :TableViewClose

- [ ] `:TableViewClose` -- (no description)

### :TableViewMarkdown

- [ ] `:TableViewMarkdown` -- (no description)

### :TableViewOpenBrowser

- [ ] `:TableViewOpenBrowser` -- (no description)

### :TableViewOpenBrowserNice

- [ ] `:TableViewOpenBrowserNice` -- (no description)

### :TableViewSelect

- [ ] `:TableViewSelect` -- (no description)

### :TableViewToggle

- [ ] `:TableViewToggle` -- (no description)

### :Theme

- [ ] `:Theme` -- Theme ändern (Shortcut für :UI theme)

### :ToggleInlineDiff

- [ ] `:ToggleInlineDiff` -- Toggle inline diff: invert word_diff & linehl, preview current hunk inline

### :ToggleLintFormatOnSave

- [ ] `:ToggleLintFormatOnSave` -- Toggle automatic lint+format on save (toggle via API)

### :Translate

- [ ] `:Translate` -- Translate (popup by default; ! = interactive window)

### :TranslateReplace

- [ ] `:TranslateReplace` -- Translate and replace in place

### :Tricentis

- [ ] `:Tricentis commands` -- Pick a CLI command from anywhere in the work repo and copy it (topic: all|enginelab|mobile|api|excel|engines|tosca|workflow|notes|terminologie|cases|todo)
- [ ] `:Tricentis` -- Cross-repo tools for the whole WKDBook-Tricentis knowledge base (not case-scoped)
- [ ] `:Tricentis cheatsheet` -- Render every CLI command of a topic into one grouped scratch buffer
- [ ] `:Tricentis links` -- Search links across the work repo (scope: all|cases|notes|workflow|terminologie|tosca|todo)

### :TypeDefAttachNoiceKeys

- [ ] `:TypeDefAttachNoiceKeys` -- Attach type lookup keymaps to current Noice buffer

### :TypeDefFindInNodeModules

- [ ] `:TypeDefFindInNodeModules` -- Search symbol in node_modules (rg fallback). Defaults to <cword>.

### :TypeDefGoTo

- [ ] `:TypeDefGoTo` -- Go to type definition for symbol string (vsplit). Defaults to <cword>.

### :TypeDefPeek

- [ ] `:TypeDefPeek` -- Peek type definition for symbol string (floating). Defaults to <cword>.

### :TypeDefPick

- [ ] `:TypeDefPick` -- Workspace symbols for a query (default: the word under the cursor)

### :UI

- [ ] `:UI` -- UI Kontrolle (Base46, Transparenz, Themes)

### :WKDDiffProfile

- [ ] `:WKDDiffProfile` -- Set diff profile (minimal/context/review/strict)

### :WKDOptionsHLDebugCtx

- [ ] `:WKDOptionsHLDebugCtx` -- Debug breadcrumb context providers

### :WKDOptionsHLList

- [ ] `:WKDOptionsHLList` -- List all highlight config keys

### :WKDOptionsHLSet

- [ ] `:WKDOptionsHLSet` -- Set highlight config value

### :WKDOptionsHLShow

- [ ] `:WKDOptionsHLShow` -- Show highlight config value

### :WhoLocks

- [ ] `:WhoLocks` -- [usrcmds.who_locks] Diagnose who is holding a file open (Windows EBUSY/EPERM); --json for structured output

### :WinHorizontal

- [ ] `:WinHorizontal` -- Move current window to horizontal split

### :WinVertical

- [ ] `:WinVertical` -- Move current window to vertical split

### :WkdBookFiles

- [ ] `:WkdBookFiles` -- [pickers] :WkdBookFiles — pick wkdbook, then find files

### :WkdBookGrep

- [ ] `:WkdBookGrep` -- [pickers] :WkdBookGrep — pick wkdbook, then live grep

### :WkdbooksFiles

- [ ] `:WkdbooksFiles` -- [pickers coll] :WkdbooksFiles → :Pickers wkdbooks files

### :WkdbooksGrep

- [ ] `:WkdbooksGrep` -- [pickers coll] :WkdbooksGrep → :Pickers wkdbooks grep

### :WkdbooksLuaFiles

- [ ] `:WkdbooksLuaFiles` -- [pickers coll] :WkdbooksLuaFiles → :Pickers wkdbooks_lua files

### :WkdbooksLuaGrep

- [ ] `:WkdbooksLuaGrep` -- [pickers coll] :WkdbooksLuaGrep → :Pickers wkdbooks_lua grep

### :WkdbooksLuaSmart

- [ ] `:WkdbooksLuaSmart` -- [pickers coll] :WkdbooksLuaSmart → :Pickers wkdbooks_lua smart

### :WkdbooksNvimFiles

- [ ] `:WkdbooksNvimFiles` -- [pickers coll] :WkdbooksNvimFiles → :Pickers wkdbooks_nvim files

### :WkdbooksNvimGrep

- [ ] `:WkdbooksNvimGrep` -- [pickers coll] :WkdbooksNvimGrep → :Pickers wkdbooks_nvim grep

### :WkdbooksNvimSmart

- [ ] `:WkdbooksNvimSmart` -- [pickers coll] :WkdbooksNvimSmart → :Pickers wkdbooks_nvim smart

### :WkdbooksSmart

- [ ] `:WkdbooksSmart` -- [pickers coll] :WkdbooksSmart → :Pickers wkdbooks smart

## ⚠ Handle with care

102 item(s) flagged by a keyword guess (delete/remove/kill/
shutdown/... in the description or route) -- a candidate for extra
caution, not a verdict. Read the description before triggering any of these.

- [ ] `<Del>` (bindings) -- Smart delete (<Del>)
- [ ] `<leader>Q` (bindings) -- [Windows] Force quit all
- [ ] `<leader>hd` (bindings) -- [HARPOON] Remove current file from the list
- [ ] `dw` (bindings) -- [Edit] Delete word backwards without yanking
- [ ] `x` (bindings) -- [Edit] Delete char without yanking
- [ ] `<leader>ntS` (config) -- Stop test
- [ ] `<leader>dcf` (fileops) -- fileops: Delete current file
- [ ] `DD` (markdown.nvim/editing) -- markdown.nvim: Delete line + linked file (asks first)
- [ ] `:AstroDevStop` -- Stop Astro dev server
- [ ] `:BindingsRuntimeChecklist` -- Write the runtime checklist (lib.nvim.bindings.audit.checklist_lines) to docs/ROADMAP/personal/All/BINDINGS-RUNTIME-CHECKLIST.md; ! to overwrite
- [ ] `:Cascade cycle remove` -- Remove the runtime cycle group containing a value
- [ ] `:Case delete` -- Permanently delete a case (types the case number back to confirm)
- [ ] `:Case close` -- Move the case somewhere (pick a destination, or delete)
- [ ] `:CmpReloadWords` -- [lsp.completion.personal_names] Reload extra.lua and the personal-plugin list without restarting
- [ ] `:Debug keylogger stop` -- (no description)
- [ ] `:Debug proc stop` -- (no description)
- [ ] `:File delete` -- (no description)
- [ ] `:GithubStats dashboard` -- Open GitHub Stats Dashboard (use :GithubStats! dashboard to force refresh)
- [ ] `:GithubStats compact` -- Archive old clones/views data and prune stale referrers/paths snapshots (use 'dry-run' to preview)
- [ ] `:GithubStats fetch` -- Fetch GitHub stats (use 'force' to bypass interval)
- [ ] `:Harpoon remove` -- Remove a file from the live list (default: current buffer)
- [ ] `:Harpoon defaults reset` -- Rebuild the list from the default paths, in that exact order
- [ ] `:Harpoon unpin` -- Remove a file from the persistent Harpoon defaults
- [ ] `:HarpoonSetDefaultPaths` -- Harpoon: reset the list to the default paths (alias for :Harpoon defaults reset)
- [ ] `:HarpoonUnpin` -- Harpoon: drop a file from the persistent defaults (alias for :Harpoon unpin)
- [ ] `:Image clear` -- Remove the displayed images
- [ ] `:Image orphans` -- Find images in the target directory with no link, and optionally delete them
- [ ] `:Insights devserver kill` -- Kill tracked dev servers
- [ ] `:Lib deps reset-first-run` -- Forget that a plugin's (or every plugin's) first-run popup was already shown
- [ ] `:Lsp autorestart` -- Bring a crashed server back automatically: control or report
- [ ] `:Lsp workspace` -- Workspace-wide diagnostics on attach: control or force now
- [ ] `:Lsp root` -- Root scope and workspace folders: pick, show, add, remove, list
- [ ] `:Lsp restart` -- Restart clients on this buffer (all, or one by name)
- [ ] `:Lsp force-restart` -- Restart one server with a full cleanup first
- [ ] `:Lsp stop` -- Stop clients on this buffer (all, or one by name)
- [ ] `:LspForceRestart` -- [lsp.usercmds] Force-restart LSP with full cleanup
- [ ] `:LspRestartHere` -- [lsp.usercmds] Restart LSP clients (all or specify name)
- [ ] `:LspStopHere` -- [lsp.usercmds] Stop LSP clients (all or specify name)
- [ ] `:LspWorkspaceDiagnosticsNow` -- [lsp_workspace_diagnostics] force-populate workspace diagnostics now, regardless of the toggle
- [ ] `:MDView selection` -- Mirror the visual selection (v/V/CTRL-V) into the preview, or stop mirroring; no argument toggles
- [ ] `:MDView zoom` -- Adjust the preview font-size zoom (+ | - | reset | <factor>)
- [ ] `:MDView file-log path` -- Set the file log path (or `default` to reset it); omit to report the current path
- [ ] `:MDView stop` -- Stop the relay, detach autocommands, and (in isolated mode) close the browser
- [ ] `:MDView toggle` -- Start if stopped, stop if running
- [ ] `:MdRebuildWords` -- [md_words] Force full rebuild of the project-wide word cache
- [ ] `:MyPlugins remove` -- Remove clean (no uncommitted/unpushed work) listed plugins (or just --only=<name>), after confirmation
- [ ] `:MyPlugins fetch` -- git fetch --all --prune on every present listed plugin (or just --only=<name>)
- [ ] `:MyPlugins mode` -- Show, or persistently switch, plugins.personal.source's OVERRIDE (restart required to apply)
- [ ] `:MyPlugins reclone` -- Delete (if clean) and re-clone present listed plugins, or clone missing ones fresh, after confirmation; --dry-run previews the safe/unsafe/missing split without touching anything
- [ ] `:MyPlugins picker` -- Interactive multi-select: assign clone/update/pull/fetch/remove/reclone per plugin, then run them all at once
- [ ] `:NeotestClearAll` -- Stop tests and close all windows
- [ ] `:NeotestStop` -- Stop running tests
- [ ] `:RA usage stop` -- Stop counting keymap/command presses
- [ ] `:RA startup report` -- Stop measuring and show the stall timeline
- [ ] `:RATelemetry` -- runtime-analysis.telemetry: report|status|start|stop|flush|reset|disable|enable|disabled|coverage|export|export-all|open|compare|startup|flamegraph|cost|snapshot|snapshots|snapshot-compare|setup|full [namespace] [days]
- [ ] `:RATelemetryResetAll` -- runtime-analysis.telemetry: reset every live instance, prompting once for a backup directory if anything would be lost (same as :RATelemetry reset)
- [ ] `:RATelemetrySetupAll` -- runtime-analysis.telemetry: backup+reset+re-wrap+start every configured, loaded target (own profile_args/timing policy)
- [ ] `:RATelemetryStopAll` -- runtime-analysis.telemetry: stop every live instance (same as :RATelemetry stop)
- [ ] `:Reposcope filter` -- Filter the repository list by substring (no args resets the list)
- [ ] `:Sandbox wsl shutdown-all` -- Shut down the WSL2 VM and all running distros
- [ ] `:Sandbox image remove` -- Remove a local image
- [ ] `:Sandbox image prune` -- Remove all dangling images (--buffer: stream to a terminal buffer)
- [ ] `:Sandbox volume remove` -- Remove a volume
- [ ] `:Sandbox volume prune` -- Remove all unused volumes
- [ ] `:Sandbox network prune` -- Remove all unused networks
- [ ] `:Sandbox network remove` -- Remove a network
- [ ] `:Sandbox container start` -- Start a stopped container (--buffer: stream to a terminal buffer)
- [ ] `:Sandbox container stop` -- Stop a running container (--buffer: stream to a terminal buffer)
- [ ] `:Sandbox container kill` -- Force kill a container (--buffer: stream to a terminal buffer)
- [ ] `:Sandbox container logs-follow` -- Stream a container's logs live (press q in the buffer to stop)
- [ ] `:Sandbox container restart` -- Restart a container (--buffer: stream to a terminal buffer)
- [ ] `:Sandbox container prune` -- Remove all stopped containers (--buffer: stream to a terminal buffer)
- [ ] `:Sandbox container remove` -- Remove a stopped container (--buffer: stream to a terminal buffer)
- [ ] `:Sandbox compose down` -- Stop and remove the compose project detected in cwd
- [ ] `:Sandbox wsl stop` -- Stop (terminate) a WSL distro
- [ ] `:Sandbox compose restart` -- Restart the compose project detected in cwd
- [ ] `:Sandbox engine reset` -- Clear the session engine override, falling back to .sandboxrc/config
- [ ] `:Sbx container remove` -- Remove a stopped container (--buffer: stream to a terminal buffer)
- [ ] `:Sbx container prune` -- Remove all stopped containers (--buffer: stream to a terminal buffer)
- [ ] `:Sbx network prune` -- Remove all unused networks
- [ ] `:Sbx image remove` -- Remove a local image
- [ ] `:Sbx compose down` -- Stop and remove the compose project detected in cwd
- [ ] `:Sbx wsl stop` -- Stop (terminate) a WSL distro
- [ ] `:Sbx wsl shutdown-all` -- Shut down the WSL2 VM and all running distros
- [ ] `:Sbx compose restart` -- Restart the compose project detected in cwd
- [ ] `:Sbx network remove` -- Remove a network
- [ ] `:Sbx container logs-follow` -- Stream a container's logs live (press q in the buffer to stop)
- [ ] `:Sbx container start` -- Start a stopped container (--buffer: stream to a terminal buffer)
- [ ] `:Sbx container kill` -- Force kill a container (--buffer: stream to a terminal buffer)
- [ ] `:Sbx container stop` -- Stop a running container (--buffer: stream to a terminal buffer)
- [ ] `:Sbx image prune` -- Remove all dangling images (--buffer: stream to a terminal buffer)
- [ ] `:Sbx volume remove` -- Remove a volume
- [ ] `:Sbx engine reset` -- Clear the session engine override, falling back to .sandboxrc/config
- [ ] `:Sbx volume prune` -- Remove all unused volumes
- [ ] `:Sbx container restart` -- Restart a container (--buffer: stream to a terminal buffer)
- [ ] `:Session delete` -- Delete a session by name
- [ ] `:Session save` -- Save session [name] (tab-complete to overwrite an existing one)
- [ ] `:Spotlight sets save` -- Save the active spotlights as a named set (overwrites if it already exists)
- [ ] `:Spotlight sets delete` -- Delete a saved set (does not touch the active spotlights)
- [ ] `:Spotlight clear` -- Remove every spotlight
- [ ] `:Spotlight remove` -- Remove the spotlight matching TEXT exactly
- [ ] `:TSParserPolicy` -- Show/set the treesitter parser install policy (off|prompt|auto|reset)
