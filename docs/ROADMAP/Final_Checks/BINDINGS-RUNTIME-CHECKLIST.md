# Bindings — runtime checklist

Generated, not hand-written -- work through it in a real session: trigger
each one yourself, tick it if it does what its description says, leave a
note here if it does not. Nothing on this list was invoked by the
generator to build it -- see `bindings.audit.checklist_lines`'s doc
comment for why.

Checkbox convention: `- [ ]` open, `- [x]` verified.

## Keymaps

### Ai

- [ ] `<leader>aio` -- Ai: Insert AI-generated code after current line
- [ ] `<leader>aia` -- Ai: Ask (prompt for text)
- [ ] `<leader>aie` -- Ai: Explain current context (badge, no panel)
- [ ] `<leader>aiO` -- Ai: Insert AI-generated code before current line
- [ ] `<leader>ais` -- Ai: Send context + a typed task, stream the answer
- [ ] `<leader>air` -- Ai: Rewrite current line with AI-generated code

### Ai/completion

- [ ] `<Tab>` -- Ai: Accept the shown completion suggestion
- [ ] `<C-]>` -- Ai: Dismiss the shown completion suggestion
- [ ] `<C-\><C-a>` -- Ai: Request a completion suggestion at the cursor

### DAP

- [ ] `<leader>daB` -- DAP: Conditional Breakpoint
- [ ] `<leader>dac` -- DAP: Continue
- [ ] `<leader>dae` -- DAP: Evaluate Expression
- [ ] `<leader>dal` -- DAP: List Breakpoints
- [ ] `<leader>daL` -- DAP: Log Point
- [ ] `<leader>daR` -- DAP: Open REPL
- [ ] `<leader>dai` -- DAP: Step Into
- [ ] `<leader>dao` -- DAP: Step Out
- [ ] `<leader>das` -- DAP: Step Over
- [ ] `<leader>dat` -- DAP: Terminate
- [ ] `<leader>dab` -- DAP: Toggle Breakpoint
- [ ] `<leader>dau` -- DAP: Toggle UI

### Debug

- [ ] `<lt>c` -- Debug: Capture to file+clipboard
- [ ] `<lt>y` -- Debug: Capture to clipboard only
- [ ] `<lt>f` -- Debug: Capture to file only
- [ ] `<lt>x` -- Debug: Clear all windows
- [ ] `<lt>m` -- Debug: Messages view (non-error)
- [ ] `<lt>n` -- Debug: Recent messages (all)
- [ ] `<lt>e` -- Debug: Recent errors

### LSP

- [ ] `lsa` -- LSP: Code action (with diff preview)
- [ ] `gra` -- LSP: Code action for the selection (with diff preview)
- [ ] `<leader>xa` -- LSP: Quick fix for the diagnostic on this line
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
- [ ] `lsp` -- LSP: Peek definition (floating, editable)
- [ ] `lsT` -- LSP: Peek type definition (floating, editable)
- [ ] `<leader>do` -- LSP: Picker: document diagnostics
- [ ] `<leader>dos` -- LSP: Picker: document symbols
- [ ] `lsf` -- LSP: Picker: finder (references + implementations + definitions)
- [ ] `lsc` -- LSP: Picker: incoming calls (who calls this)
- [ ] `lsC` -- LSP: Picker: outgoing calls (what this calls)
- [ ] `lsH` -- LSP: Picker: subtypes of this type
- [ ] `lsh` -- LSP: Picker: supertypes of this type
- [ ] `<leader>wo` -- LSP: Picker: workspace diagnostics
- [ ] `<leader>wos` -- LSP: Picker: workspace symbols (live)
- [ ] `]q` -- LSP: Next quickfix entry
- [ ] `[q` -- LSP: Prev quickfix entry
- [ ] `grn` -- LSP: Rename symbol
- [ ] `<leader>rn` -- LSP: Rename symbol (leader variant)
- [ ] `<leader>lsp` -- LSP: Pick root scope (cwd / git root / file path)
- [ ] `<M-s>` -- LSP: Signature help
- [ ] `<C-b>` -- LSP: Show signature or hover (floating toggle)
- [ ] `<leader>xx` -- LSP: Trouble: all diagnostics
- [ ] `<leader>xd` -- LSP: Trouble: buffer diagnostics
- [ ] `<leader>xld` -- LSP: Trouble: definitions
- [ ] `]w` -- LSP: Next entry in the open Trouble diagnostics list
- [ ] `[w` -- LSP: Prev entry in the open Trouble diagnostics list
- [ ] `<leader>xli` -- LSP: Trouble: implementations
- [ ] `<leader>xl` -- LSP: Trouble: location list
- [ ] `<leader>xo` -- LSP: Trouble: outline sidebar (document symbols)
- [ ] `<leader>xq` -- LSP: Trouble: quickfix list
- [ ] `<leader>xlr` -- LSP: Trouble: references
- [ ] `<leader>xls` -- LSP: Trouble: document symbols
- [ ] `<leader>xt` -- LSP: Trouble: toggle diagnostics
- [ ] `<leader>xlt` -- LSP: Trouble: type definitions
- [ ] `<leader>xw` -- LSP: Trouble: workspace diagnostics
- [ ] `<leader>tW` -- LSP: Toggle the LSP breadcrumb in the winbar (global)
- [ ] `<leader>lsw` -- LSP: Add a workspace folder (multi-root / monorepo)

### Recommender

- [ ] `<leader>lrc` -- Recommender: project-wide (cwd)
- [ ] `<leader>lrh` -- Recommender: regex analyzer, high threshold
- [ ] `<leader>lrj` -- Recommender: javascript analyzer
- [ ] `<leader>lrp` -- Recommender: python analyzer
- [ ] `<leader>lrr` -- Recommender: regex analyzer
- [ ] `<leader>lR` -- Recommender: replace mode
- [ ] `<leader>lr` -- Recommender: run
- [ ] `<leader>lrt` -- Recommender: treesitter analyzer

### Reposcope

- [ ] `<leader>rc` -- Reposcope: Close Reposcope
- [ ] `<leader>rs` -- Reposcope: open the UI

### Session

- [ ] `<leader>ha` -- Session: mark this file
- [ ] `<leader>hA` -- Session: mark this file first
- [ ] `<leader>hD` -- Session: dump the mark list
- [ ] `<leader>hE` -- Session: marks (edit list)
- [ ] `<leader>hm` -- Session: marks (picker)
- [ ] `<leader>hp` -- Session: pin this file
- [ ] `<leader>h1` -- Session: jump to mark 1
- [ ] `<leader>h2` -- Session: jump to mark 2
- [ ] `<leader>h3` -- Session: jump to mark 3
- [ ] `<leader>h4` -- Session: jump to mark 4
- [ ] `<leader>h5` -- Session: jump to mark 5
- [ ] `<leader>h6` -- Session: jump to mark 6
- [ ] `<leader>h7` -- Session: jump to mark 7
- [ ] `<leader>h8` -- Session: jump to mark 8
- [ ] `<leader>h9` -- Session: jump to mark 9
- [ ] `<leader>hs` -- Session: add missing default marks

### bindings

- [ ] `""` -- Surround selection with double quotes (")
- [ ] `''` -- Surround selection with single quotes (')
- [ ] `()` -- Surround selection with ()
- [ ] `<A-Down>` -- [Noice] LSP Scroll forward
- [ ] `<A-Up>` -- [Noice] LSP Scroll backward
- [ ] `<A-j>` -- [Noice] LSP Scroll forward
- [ ] `<A-k>` -- [Noice] LSP Scroll backward
- [ ] `<A-x>` -- [Noice] Dismiss UI
- [ ] `<C-A-S-p>` -- [Text] Paste from system clipboard (insert mode, literal)
- [ ] `<C-S-j>` -- Move down by screen line (through wrapped text)
- [ ] `<C-S-k>` -- Move up by screen line (through wrapped text)
- [ ] `<C-a>` -- [General] Select all
- [ ] `<C-c>` -- [General] Copy whole file
- [ ] `<C-h>` -- [Text] Left
- [ ] `<C-j>` -- [Text] Down
- [ ] `<C-k>` -- [Text] Up
- [ ] `<C-l>` -- [Text] Right
- [ ] `<C-r>` -- Redo (branch-aware)
- [ ] `<C-s>` -- [General] Save file
- [ ] `<CR>` -- Insert blank line
- [ ] `<Esc>` -- [General] Clear search highlight
- [ ] `<F1>` -- [General] Disable F1
- [ ] `<M-O>` -- [Open] List every openable target in the buffer
- [ ] `<M-j>` -- Move down by screen line (through wrapped text)
- [ ] `<M-k>` -- Move up by screen line (through wrapped text)
- [ ] `<M-o>` -- [Open] Open whatever is under the cursor
- [ ] `<S-h>` -- [Window] Resize narrower
- [ ] `<S-j>` -- [Window] Resize shorter
- [ ] `<S-k>` -- [Window] Resize taller
- [ ] `<S-l>` -- [Window] Resize wider
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
- [ ] `<leader>X` -- [Execute] Run the `code` / line under the cursor
- [ ] `<leader>bn` -- [Buffers] New
- [ ] `<leader>bx` -- [Buffers] Close current, go to next
- [ ] `<leader>cp` -- [General] Copy file path
- [ ] `<leader>cs` -- [casedesk] Save session (case-aware)
- [ ] `<leader>date` -- [General] Insert date
- [ ] `<leader>dt` -- [General] Diff windows in tab
- [ ] `<leader>fm` -- [General] Format file
- [ ] `<leader>q` -- [Windows] Close window
- [ ] `<leader>s` -- [Pickers] Tabbed search (files/all/grep/buffers)
- [ ] `<leader>tc` -- [Tabs] New tab
- [ ] `<leader>tg` -- [Pickers] Grep (own prompt)
- [ ] `<leader>tn` -- [Tabs] Next tab
- [ ] `<leader>tp` -- [Tabs] Previous tab
- [ ] `<leader>tx` -- [Tabs] Close tab
- [ ] `<leader>wK` -- [General] WhichKey (all)
- [ ] `<leader>wR` -- Rotate window layout
- [ ] `<leader>wh` -- Move window to horizontal split (top)
- [ ] `<leader>wj` -- Move window to horizontal split (bottom)
- [ ] `<leader>wk` -- [General] WhichKey query
- [ ] `<leader>wl` -- Move window to vertical split (left)
- [ ] `<leader>wr` -- Move window to vertical split (right)
- [ ] `<leader>x` -- [Execute] Put the `code` / line under the cursor on the command line
- [ ] `<leader>zm` -- [Window] Zoom toggle.
- [ ] `P` -- Paste before cursor (leading/trailing blank lines trimmed)
- [ ] `[]` -- Surround selection with []
- [ ] `[u` -- Jump to the head of the enclosing structure (repeatable)
- [ ] `]u` -- Jump to the end of the enclosing structure (repeatable)
- [ ] ``` -- Surround selection with backticks (`)
- [ ] `jk` -- [General] Exit to normal mode
- [ ] `p` -- Paste after cursor (leading/trailing blank lines trimmed)
- [ ] `{}` -- Surround selection with {}

### buffer-ctx

- [ ] `<leader>cnf` -- buffer-ctx: copy filepath (cwd-relative)
- [ ] `<leader>cnl` -- buffer-ctx: copy location (path:line)
- [ ] `<leader>cnm` -- buffer-ctx: copy module path

### buffer_ctx

- [ ] `<C-p>` -- [buffer-ctx] Mark: yank marked lines
- [ ] `<S-m>` -- [buffer-ctx] Mark: toggle line (or N with a count)
- [ ] `<leader>ob` -- [buffer-ctx] Open current buffer in the browser
- [ ] `<leader>of` -- [buffer-ctx] Reveal current buffer in the file manager

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

### casedesk

- [ ] `<leader>cf` -- casedesk: find files in this case
- [ ] `<leader>cF` -- casedesk: find files across every case
- [ ] `<leader>cg` -- casedesk: grep this case
- [ ] `<leader>cG` -- casedesk: grep across every case

### config

- [ ] `<leader>ntD` -- Configured vs registered adapters (debugging.nvim)
- [ ] `<leader>ntO` -- Toggle output panel
- [ ] `<leader>nta` -- Run all tests
- [ ] `<leader>ntd` -- Debug nearest test
- [ ] `<leader>ntf` -- Run file tests
- [ ] `<leader>nto` -- Show output
- [ ] `<leader>ntr` -- Discovered positions per adapter (debugging.nvim)
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

### filetree/source_switcher/global

- [ ] `<leader>ns` -- filetree: pick a tree source

### filetree/tree_toggle/global

- [ ] `<M-c>` -- filetree: toggle tree in this window
- [ ] `<M-f>` -- filetree: toggle tree as a float
- [ ] `<M-l>` -- filetree: toggle tree on the left
- [ ] `<M-r>` -- filetree: toggle tree on the right

### gitsuite

- [ ] `<leader>gb` -- gitsuite: [gitsuite.nvim] Blame (full)
- [ ] `<leader>dh` -- gitsuite: [gitsuite.nvim] Diff history
- [ ] `<leader>dc` -- gitsuite: [gitsuite.nvim] Close diffview
- [ ] `<leader>dv` -- gitsuite: [gitsuite.nvim] Open diffview
- [ ] `<leader>di` -- gitsuite: [gitsuite.nvim] Toggle inline diff
- [ ] `<leader>lg` -- gitsuite: [gitsuite.nvim] Open lazygit

### gopath

- [ ] `gC` -- gopath: check path exists / offer create
- [ ] `gY` -- gopath: copy path:line:col
- [ ] `g?` -- gopath: debug under cursor
- [ ] `gM` -- gopath: reveal in file explorer
- [ ] `gT` -- gopath: reveal in filetree.nvim (soft dependency)
- [ ] `gF` -- gopath: open here
- [ ] `g|` -- gopath: open in split
- [ ] `g}` -- gopath: open in tab
- [ ] `g\` -- gopath: open in vsplit
- [ ] `<leader>pp` -- gopath: probe path under cursor (vsplit)

### insights

- [ ] `<leader>fi` -- insights: file info float
- [ ] `<leader>pS` -- insights: symbols (fzf, cwd functions)
- [ ] `<leader>ps` -- insights: symbols (telescope, cwd functions)
- [ ] `<leader>sT` -- insights: todo comments (picker)
- [ ] `<leader>ST` -- insights: todo comments (quickfix)

### language/spell

- [ ] `<leader>ss` -- language: Toggle spell session (current buffer)

### language/translate

- [ ] `<leader>lt` -- language: Translate motion
- [ ] `<leader>lt` -- language: Translate selection

### lib

- [ ] `<M-.>` -- repeat last real command (lib.nvim.lastcmd)

### media

- [ ] `<leader>Mf` -- media: poster frame
- [ ] `<leader>Mo` -- media: play in external player
- [ ] `<leader>Mp` -- media: describe media file
- [ ] `<leader>Ms` -- media: contact sheet

### my

- [ ] `<leader>od` -- my: cycle diff profile
- [ ] `<leader>oh` -- my: toggle cursorline highlight

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
- [ ] `<leader>pbf` -- [pickers] plugins_book: find files
- [ ] `<leader>pbg` -- [pickers] plugins_book: live grep
- [ ] `<leader>pbs` -- [pickers] plugins_book: smart (grep + find)
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
- [ ] `<leader>CF` -- pickers: Smart (grep + find) in nvim config
- [ ] `<leader>mp` -- pickers: Find files in CWD; add grep=<pattern> to filter by content
- [ ] `<leader>li` -- pickers: Live grep in CWD
- [ ] `<leader>CW` -- pickers: Smart (grep + find) in CWD
- [ ] `<leader>dp` -- pickers: Dir: navigate (alias / depth / path)
- [ ] `<leader>.` -- pickers: File explorer / browser (active engine)
- [ ] `<leader>fb` -- pickers: Find files in interactively picked folder

### runtime-analysis

- [ ] `<C-e>` -- [Session] Open marks menu
- [ ] `<M-1>` -- [Session] Preview mark 1 (full screen)
- [ ] `<M-2>` -- [Session] Preview mark 2 (full screen)
- [ ] `<M-3>` -- [Session] Preview mark 3 (full screen)
- [ ] `<M-4>` -- [Session] Preview mark 4 (full screen)
- [ ] `<M-5>` -- [Session] Preview mark 5 (full screen)
- [ ] `<M-6>` -- [Session] Preview mark 6 (full screen)
- [ ] `<M-7>` -- [Session] Preview mark 7 (full screen)
- [ ] `<M-8>` -- [Session] Preview mark 8 (full screen)
- [ ] `<M-9>` -- [Session] Preview mark 9 (full screen)
- [ ] `<M-S>` -- [Session] Toggle chip visibility
- [ ] `_` -- [Slots] Toggle slot bar (counted: built-in _ motion)

### spotlight

- [ ] `<leader>sC` -- spotlight: clear all spotlights
- [ ] `<leader>sW` -- spotlight: toggle whole-line rendering for the token under cursor
- [ ] `<leader>sL` -- spotlight: open the spotlight list
- [ ] `]k` -- spotlight: next occurrence (×count)
- [ ] `[k` -- spotlight: previous occurrence (×count)
- [ ] `<leader>sq` -- spotlight: matching lines to quickfix
- [ ] `<leader>sK` -- spotlight: toggle every occurrence of the token under cursor (dot-repeatable)
- [ ] `<leader>sk` -- spotlight: toggle this occurrence only

### terminal

- [ ] `<C-j>` -- terminal: Window down (count; hands off at the edge)
- [ ] `<C-h>` -- terminal: Window left (count; hands off at the edge)
- [ ] `<C-l>` -- terminal: Window right (count; hands off at the edge)
- [ ] `<C-k>` -- terminal: Window up (count; hands off at the edge)
- [ ] `<Esc>` -- terminal: Leave terminal mode
- [ ] `<A-h>` -- terminal: Toggle the terminal (a count picks terminal N)

### ui.nvim

- [ ] `<leader>bc` -- ui.nvim: close buffer(s), count-aware
- [ ] `<leader>bq` -- ui.nvim: close every listed buffer in the current tab, flashed first
- [ ] `<leader>tl` -- ui.nvim: move buffer one position left in the tabline
- [ ] `<leader>tr` -- ui.nvim: move buffer one position right in the tabline
- [ ] `<leader>tt` -- ui.nvim: move current buffer into a new tab
- [ ] `<Tab>` -- ui.nvim: next buffer
- [ ] `<S-Tab>` -- ui.nvim: previous buffer
- [ ] `<leader>bu` -- ui.nvim: reopen the most recently closed tab
- [ ] `<leader>uP` -- ui.nvim: open the visual theme picker (live preview)
- [ ] `<leader>bp` -- ui.nvim: pin/unpin the current buffer's tab
- [ ] `<M-p>` -- ui.nvim: toggle the sticky code context
- [ ] `<leader>ut` -- ui.nvim: toggle between the two configured themes

## Usercmds

### :Ai

- [ ] `:Ai provider` -- Switch the active provider, or back to auto (one outside the allow-list asks first)
- [ ] `:Ai append` -- Insert AI-generated code after the range (default: current line)
- [ ] `:Ai rewrite` -- Replace the range (default: current line) with AI-generated code
- [ ] `:Ai stream` -- Ask, streaming the answer into a panel (prompts for text if omitted)
- [ ] `:Ai ask` -- Ask once, non-streaming (prompts for text if omitted)
- [ ] `:Ai prepend` -- Insert AI-generated code before the range (default: current line)
- [ ] `:Ai info` -- Show the active provider, resolution order, and per-provider availability
- [ ] `:Ai` -- Ask or stream a prompt to the active AI provider

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

- [ ] `:Bindings check all` -- Eigene und fremde zusammen — das Verhalten vor der Scope-Trennung
- [ ] `:Bindings report` -- Drift-Bericht als Markdown-Datei; ohne `out=` nach docs/ROADMAP/Final_Checks/BINDINGS-DRIFT-<datum>.md
- [ ] `:Bindings report all` -- Eigene und fremde zusammen, als Markdown-Datei
- [ ] `:Bindings report extern` -- Nur die fremden, als Markdown-Datei
- [ ] `:Bindings report repo` -- Drift-Bericht mit der Checkout-Achse, als Markdown-Datei
- [ ] `:Bindings audit keys` -- Actions whose every key needs an extended terminal encoding (optional: scope to a repo path)
- [ ] `:Bindings audit` -- Keymap actions vs. command routes, registered in this session (optional: scope to a repo path)
- [ ] `:Bindings check extern` -- Nur die fremden: Cheatsheets fremder Plugins gegen die Session, dazu live registrierte Commands ohne Cheatsheet, deren Plugin dieser Korpus nicht abdeckt
- [ ] `:Bindings status` -- Dashboard: Korpus-, Live- und Plugin-Zahlen plus die Routenliste
- [ ] `:Bindings audit prefixes` -- Command names that are a strict prefix of another live command (<Tab>/abbreviation collisions)
- [ ] `:Bindings audit gaps` -- Keymap actions with no obvious command counterpart (optional: scope to a repo path)
- [ ] `:Bindings check repo` -- Drift-Bericht mit der Checkout-Achse: dokumentierte Bindings ungeladener Plugins gegen deren lokalen Quellbaum; `root=<dir>` nimmt jedes Lua-Projekt unter einem Sammelverzeichnis statt der Lazy-Spec-Auflösung
- [ ] `:Bindings search autocmds` -- Live-Grep, nur Autocmds-Cheatsheets; `hover.nvim` als Argument scopt auf dessen Sheet
- [ ] `:Bindings browse autocmds` -- Gruppierte Ansicht der Autocmds-Tabellenzeilen; `personal`/`extern` oder ein Cheatsheet-Stamm scopen
- [ ] `:Bindings search keymaps` -- Live-Grep, nur Keymaps-Cheatsheets; `hover.nvim` als Argument scopt auf dessen Sheet
- [ ] `:Bindings audit naming` -- Routes whose last path segment is a bare vague word (deep/full/check/...) -- candidates for a naming review, not a verdict
- [ ] `:Bindings search` -- Live-Grep über beide BINDINGS-Bäume (Picker-Engine, sonst Prompt+Liste); ein Cheatsheet-Stamm als Argument scopt auf dessen Sheets
- [ ] `:Bindings` -- Cheatsheets in docs/NOTES/{PersonelPlugins/BINDINGS,ExternPlugins/Bindings} durchsuchen
- [ ] `:Bindings check` -- Drift-Bericht: dokumentiert-aber-nicht-live / live-aber-undokumentiert (Personal, read-only)
- [ ] `:Bindings search usercmds` -- Live-Grep, nur Usercmds-Cheatsheets; `hover.nvim` als Argument scopt auf dessen Sheet
- [ ] `:Bindings path` -- BINDINGS-Wurzel(n) in die Zwischenablage kopieren
- [ ] `:Bindings browse usercmds` -- Gruppierte Ansicht der Usercmds-Tabellenzeilen; `personal`/`extern` oder ein Cheatsheet-Stamm scopen
- [ ] `:Bindings conflicts` -- lhs values claimed by more than one plugin/registration in this session
- [ ] `:Bindings browse keymaps` -- Gruppierte Ansicht der Keymaps-Tabellenzeilen; `personal`/`extern` oder ein Cheatsheet-Stamm scopen
- [ ] `:Bindings browse` -- Gruppierte Ansicht aller Tabellenzeilen (Keymaps+Usercmds+Autocmds); `personal`/`extern` oder ein Cheatsheet-Stamm scopen
- [ ] `:Bindings audit checklist` -- Markdown checklist over every keymap action and command route, for a manual runtime pass (view only -- :BindingsRuntimeChecklist writes it to a file)

### :Cascade

- [ ] `:Cascade cycle list` -- List the cycle groups in effect for this buffer
- [ ] `:Cascade rotate` -- Rotate list form (range-aware; ! or 'prev' = backward)
- [ ] `:Cascade sort` -- Sort list A-Z (range-aware; ! = Z-A)
- [ ] `:Cascade cycle add` -- Add a cycle group at runtime: :Cascade cycle add on,off,maybe
- [ ] `:Cascade reverse` -- Reverse list order (range-aware)
- [ ] `:Cascade strings` -- Strings domain: on/off/toggle for this buffer, or `now` to convert the literal at the cursor
- [ ] `:Cascade indent` -- Indent line/range (+renumber; arg = levels)
- [ ] `:Cascade strip` -- Strip checkboxes (range-aware)
- [ ] `:Cascade dedent` -- Dedent line/range (+renumber; arg = levels)
- [ ] `:Cascade renumber` -- Renumber list block (range-aware; 'all' = every list in the buffer, 'selection' = numbers inside the lines)

### :Case

- [ ] `:Case swat` -- Open SWAT/Technicals.md of the case
- [ ] `:Case kb` -- Open Research/KB.md of the case
- [ ] `:Case jql` -- Open Research/JQL.md of the case
- [ ] `:Case reply` -- Open Replies/00_PSO.md of the case
- [ ] `:Case reassign` -- Move the case to Reassigned
- [ ] `:Case solved` -- Move the case to Solved
- [ ] `:Case unassigned` -- Move the case to Unassigned
- [ ] `:Case assigned` -- Move the case to Assigned
- [ ] `:Case translate` -- Translate the current buffer or selection (language.nvim; asks for confirmation first, the text goes to a third party); [lang] defaults to config.translate_default_target
- [ ] `:Case research` -- Open Research/00_Research.md of the case
- [ ] `:Case notes` -- Open Notes.md of the case
- [ ] `:Case summary` -- Open Summary.md of the case
- [ ] `:Case spotlight` -- Open the case's Activity Stream and mark its error codes, KBA numbers, versions and attachments (spotlight.nvim)
- [ ] `:Case translate stream` -- Open the case's newest Activity Stream and translate it (language.nvim; asks for confirmation first, the text goes to a third party); --to takes a language and defaults to config.translate_default_target
- [ ] `:Case spotlight show` -- Show the markings saved for this case: text, colour slot, match mode, origin file
- [ ] `:Case spotlight load` -- Replace the active spotlights with the markings saved for this case, and follow it from now on; asks before replacing spotlights that are saved nowhere
- [ ] `:Case task` -- Open Task.md of the case
- [ ] `:Case links open` -- Open the case's Links.md (the links it uses, each with what it is for); creates it for a case that has none yet
- [ ] `:Case insert` -- Insert a case token (number/title/company/name/snow-url/sap-number/sap-url/asset/...) at the cursor and copy it
- [ ] `:Case route` -- Record which department the case was routed to (config.routing_targets)
- [ ] `:Case links add` -- Add a link to the case's Links.md with what it is for: the URL (default: a URL on the clipboard), then the purpose (asked for if missing, required); --section picks tickets|docs|swarm (default: by the link), --label the link text, --case another case
- [ ] `:Case reopen` -- Move a closed/solved case back into its area's open state
- [ ] `:Case reply check` -- Pre-send gate on the current buffer: emojis, stray markdown headlines, dead links
- [ ] `:Case otheragent` -- Move the case to OtherAgent
- [ ] `:Case t2` -- Move the case to T2
- [ ] `:Case checklist` -- Update the first-reply checklist in Notes.md (what applies to the case, what the case's assets/ folder already proves is done; your ticks stay) and open it; --no-open only writes
- [ ] `:Case ai test` -- Send one synthetic question (no customer data) to the AI provider (--provider takes any ai.nvim provider id), to check key, network and allow-list
- [ ] `:Case ai provider` -- Choose the AI provider for this session (asks if omitted; any ai.nvim provider id works, in any case; Tab completion suggests the common ones); one outside the machine's allow-list needs a confirmation and runs in test mode
- [ ] `:Case ai log` -- The last AI sends, metadata only (time, case, action, provider, data classes, outcome)
- [ ] `:Case sla` -- SAP-SLA clocks (first reaction, cadence, correction) and how much of each is left; --doc opens the source agreement
- [ ] `:Case timeline` -- Work sessions reconstructed from file mtimes, oldest first
- [ ] `:Case import` -- Import a file into the current case (copies it; you pick the target folder)
- [ ] `:Case ai` -- Which AI provider casedesk uses and why, the machine's allow-list, and each provider's availability
- [ ] `:Case spotlight save` -- Store the active spotlights as this case's markings (spotlight.nvim); asks before replacing the saved ones of a case the spotlights are not bound to
- [ ] `:Case ai info` -- Same as :Case ai
- [ ] `:Case ki import` -- File a pasted AI answer into Research/Replies/Notes
- [ ] `:Case ki logs` -- Choose log files of this case (multi-select), anonymize and condense them, send them to the AI provider and file the analysis; --preview saves the anonymized prompt and sends nothing, --raw keeps the logs as they are (not anonymized, always behind a warning popup)
- [ ] `:Case checklist draft` -- Write the first reply from the checklist's open questions into Replies/00_PSO.md (while that is still the unfilled scaffold, else onto the clipboard)
- [ ] `:Case copy` -- Deprecated alias of :Case import
- [ ] `:Case pdf` -- Extract the text of this case's PDF attachments into .pdf.text.md sidecar files next to each PDF, so :Cases grep finds it (needs pdftotext from poppler)
- [ ] `:Case solution` -- Show the case's documented solution (offers to create one if there is none); --edit opens the file straight away
- [ ] `:Case sync` -- Add missing blueprint pieces to an existing case
- [ ] `:Case snow` -- Open (or copy) the case's ServiceNow ticket id
- [ ] `:Case clipboard` -- Copy fields of the case to the clipboard: number, title, header (123456 - Title), snow, link, snowurl, resolveurl, path, status, summary, solution, tags, the wordings (firstResponse greets the case's contact), ... (comma- or space-separated, plus an optional case number); a multi-select if none is named; --labels prefixes each value with its name, --sep joins them, --edit also opens the file of a copied wording
- [ ] `:Case versions` -- Curated version digest from ToscaSupportInfo*.txt (EXTRACTION.md); a component copies its version, --all lists everything, --raw opens the file
- [ ] `:Case links` -- docs.tricentis.com links (Activity Streams + Replies) pointing at a different Tosca version than the customer's own
- [ ] `:Case anonymize` -- Best-effort PII scrub of the newest Activity Stream (actor names, emails, S-user ids, Account/Contact/Opened by) - copies the result and shows what got redacted; not a guarantee against names only mentioned in free prose
- [ ] `:Case files` -- Fuzzy-find files in this case's own folder (pickers.nvim)
- [ ] `:Case grep` -- Live-grep this case's own folder (pickers.nvim)
- [ ] `:Case history` -- The git history of the case folder — newest commits with the files they changed (the real history, unlike :Case timeline's file times)
- [ ] `:Case spotlight list` -- List the cases that have saved spotlight markings, with how many
- [ ] `:Case template` -- Insert a reply block from Workflow/Templates at the cursor
- [ ] `:Case diff` -- Compare this case's activity stream or solution against another case's (diff.nvim)
- [ ] `:Case similar` -- Past cases with similar title/Summary wording (TF-IDF, no AI)
- [ ] `:Case jql suggest` -- Write Jira searches built from the stream's error codes, KBA numbers, version and SAP component into Research/JQL.md
- [ ] `:Case kbindex` -- Write config.article_index: one line per KB/SWAT article (ID, topic, title, keywords) for a grep before opening articles
- [ ] `:Case preflight` -- Write a check-this-first checklist into the case (config.preflights), e.g. dex: Windows GPO before logs
- [ ] `:Case activity` -- Paste the clipboard (a SNOW Activity Stream) into a new Research/ file
- [ ] `:Case attachments insert` -- Pick files from Downloads (native dialog), move them into this case's assets/
- [ ] `:Case add` -- Add a markdown file ('reply [suffix]' auto-numbers, e.g. :Case add reply AskForPDF)
- [ ] `:Case attachments find` -- Picker over every case's attachments at once
- [ ] `:Case attachments` -- List and open this case's attachments (assets/)
- [ ] `:Case imp` -- Notes for this case, its company and its contact (also shown in :Case info, :Case open and :Case new)
- [ ] `:Case known` -- Which KB/SWAT articles are already filed in config.article_dirs and which are still missing (IDs from the arguments, else the clipboard)
- [ ] `:Case info` -- Short infocard for a case (e edit, o open folder, s summary)
- [ ] `:Case promote` -- Move this case's confirmed solution into the shared Cases/Solutions collection (dedup check, customer names replaced)
- [ ] `:Case new` -- Scaffold a new case (prompts for missing fields); --steps asks one question at a time, --form everything at once in one float (config.new_mode sets the default)
- [ ] `:Case` -- SAP Support case scaffolding
- [ ] `:Case imp done` -- Retire a note that applies to this case
- [ ] `:Case open` -- Open a case's Summary.md (or its newest file), reveal folder in filetree.nvim
- [ ] `:Case imp add` -- Note something for this case, its company or its contact — e.g. a manager is pressing for a first response
- [ ] `:Case tag` -- Tag the root cause of this case from the controlled vocabulary (config.root_cause_tags) — :Case similar and :Cases tag use it
- [ ] `:Case fingerprint` -- Other cases carrying the same error string (RdpConnectionException, 0x80070524, ...) — exact match, across customers

### :Cases

- [ ] `:Cases grep` -- Full-text search across every case's markdown files
- [ ] `:Cases find` -- Filter cases by multiple fields at once (field=pattern field=pattern ...)
- [ ] `:Cases normalize` -- Fix corpus naming inconsistencies found by doctor (dry-run + confirm)
- [ ] `:Cases files` -- Fuzzy-find files across every case in every area (pickers.nvim)
- [ ] `:Cases doctor` -- Report corpus naming inconsistencies (read-only)
- [ ] `:Cases livegrep` -- Live-grep across every case in every area (pickers.nvim) -- :Cases grep is the fixed-pattern/quickfix version
- [ ] `:Cases stale` -- Open cases untouched for at least N days, or per-priority threshold if N omitted
- [ ] `:Cases solutions` -- Search every documented solution in the corpus (keyword-weighted, no AI); no pattern lists them all
- [ ] `:Cases close` -- Close multiple cases at once (marks from :Cases list, or an interactive multi-select), then pick one destination
- [ ] `:Cases export` -- Bundle Summary/Notes/Research/Replies into one PDF (pandoc + headless browser)
- [ ] `:Cases insert` -- Insert a token from ANOTHER case (number/title/company/name match) at the cursor and copy it
- [ ] `:Cases pickers` -- Discovery menu: attachments, links, cases without .case.json, terminology, CLI commands, solutions
- [ ] `:Cases terminology` -- Every term collected from every Terminologie.md across the work repo
- [ ] `:Cases history` -- Every case for a company, grouped by state (default: current buffer's company)
- [ ] `:Cases list` -- List every case, grouped by state
- [ ] `:Cases sla` -- SLA dashboard: every open case with a priority, sorted by what breaches next
- [ ] `:Cases tag` -- Every case with a root-cause tag (asks, with per-tag counts, if omitted)
- [ ] `:Cases clipboard` -- Copy standard wordings (config.wordings: firstResponse, firstResponseDelay, germanSpeaker, ...) to the clipboard as written; a picker if none is named; case fields need :Case clipboard; --edit also opens the file, --sep joins several
- [ ] `:Cases title` -- Filter cases by title
- [ ] `:Cases` -- Cross-case queries (field filters, listing)
- [ ] `:Cases sla report` -- SLA compliance report across every case (not just open): first-response quote per priority, outliers with delta. --year filters by .case.json's year
- [ ] `:Cases wordings` -- Open a standard wording from Workflow/Templates and copy it to the clipboard (alias of :Cases clipboard KIND --edit; config.wordings and config.wording_dirs: firstResponse, firstResponseDelay, germanSpeaker, TCSupportInfo, ...)
- [ ] `:Cases recent` -- Most recently touched cases first
- [ ] `:Cases area` -- Every case of one area (asks, with per-area counts, if omitted)
- [ ] `:Cases imp` -- Every note on file (:Case imp), expired ones marked
- [ ] `:Cases stats` -- Counts by area / state / company / year
- [ ] `:Cases week` -- Cases worked on in a date range (default this week; last, last 4 weeks, month, ...), sorted by priority
- [ ] `:Cases company` -- Filter cases by company
- [ ] `:Cases links check` -- Check docs.tricentis.com links for dead pages (optionally one case)
- [ ] `:Cases notes` -- Filter cases by the Notes field of the infocard
- [ ] `:Cases account` -- Filter cases by account (alias for company)
- [ ] `:Cases contact` -- Filter cases by contact (alias for name)
- [ ] `:Cases routed_to` -- Filter cases by routed_to
- [ ] `:Cases name` -- Filter cases by name
- [ ] `:Cases outcome` -- Filter cases by outcome
- [ ] `:Cases tosca_version` -- Filter cases by tosca_version
- [ ] `:Cases priority` -- Filter cases by priority

### :Cdx

- [ ] `:Cdx prompt` -- Copy a prompt template (any .md of PROMPT/) to the clipboard; SHAs (space- or comma-separated) replace {SHA}, none keeps it

### :ChecklistsFileGrep

- [ ] `:ChecklistsFileGrep` -- [pickers coll] :ChecklistsFileGrep [query] → :Pickers checklists filegrep

### :ChecklistsFiles

- [ ] `:ChecklistsFiles` -- [pickers coll] :ChecklistsFiles → :Pickers checklists files

### :ChecklistsGrep

- [ ] `:ChecklistsGrep` -- [pickers coll] :ChecklistsGrep → :Pickers checklists grep

### :ChecklistsSmart

- [ ] `:ChecklistsSmart` -- [pickers coll] :ChecklistsSmart → :Pickers checklists smart

### :Clipboard

- [ ] `:Clipboard reports` -- Copy the path of docs/ROADMAP/reports (= path reports)
- [ ] `:Clipboard path reports` -- Copy the path of docs/ROADMAP/reports
- [ ] `:Clipboard path handovers` -- Copy the path of docs/ROADMAP/handovers
- [ ] `:Clipboard handovers` -- Copy the path of docs/ROADMAP/handovers (= path handovers)

### :Cmdlog

- [ ] `:Cmdlog` -- Command history pickers
- [ ] `:Cmdlog favorites` -- Favorited commands
- [ ] `:Cmdlog full` -- All commands, including duplicates
- [ ] `:Cmdlog import` -- Import favorites from a JSON file, merging with the current list
- [ ] `:Cmdlog project` -- Command history for the current Git project
- [ ] `:Cmdlog risky test` -- Show which risky_patterns match a command (tune the list without guessing)
- [ ] `:Cmdlog nvim` -- Neovim command-line history, deduplicated
- [ ] `:Cmdlog export` -- Export favorites to a JSON file (default: favorites path + .export.json)
- [ ] `:Cmdlog lua` -- Lua-mode command history, deduplicated
- [ ] `:Cmdlog stats` -- Commands sorted by usage frequency
- [ ] `:Cmdlog nvim-full` -- Neovim command-line history, including duplicates
- [ ] `:Cmdlog shell` -- Shell command history, deduplicated
- [ ] `:Cmdlog shell-full` -- Shell command history, including duplicates

### :ColorMyAscii

- [ ] `:ColorMyAscii schemes pick` -- Pick a color scheme with Telescope
- [ ] `:ColorMyAscii` -- ASCII art syntax highlighting
- [ ] `:ColorMyAscii hover` -- Show a float with the applied highlight/group/keyword info for the character under the cursor (also copied to a register)
- [ ] `:ColorMyAscii schemes list` -- List available color schemes
- [ ] `:ColorMyAscii toggle` -- Toggle ASCII art highlighting  :ColorMyAscii toggle [global|buffer]
- [ ] `:ColorMyAscii fence-jump` -- Jump between a fence's opening/closing delimiter (%-style); falls back to the built-in % elsewhere
- [ ] `:ColorMyAscii check-fences` -- Check current buffer for unmatched fenced code blocks
- [ ] `:ColorMyAscii debug` -- Show debug information
- [ ] `:ColorMyAscii ensure-blank-lines` -- Ensure blank lines before and after fenced code blocks
- [ ] `:ColorMyAscii schemes switch` -- Switch to a different color scheme
- [ ] `:ColorMyAscii show-config` -- Show current configuration

### :ContextOpen

- [ ] `:ContextOpen list` -- List every openable target in the buffer
- [ ] `:ContextOpen` -- Open whatever is under the cursor (gopath/markdown/images/pdfport/open.nvim, unified)

### :Copy

- [ ] `:Copy boilerplate` -- boilerplate → :Copy
- [ ] `:Copy filename` -- filename → :Copy
- [ ] `:Copy module` -- module → :Copy
- [ ] `:Copy timestamp` -- timestamp → :Copy
- [ ] `:Copy mdlink` -- mdlink → :Copy
- [ ] `:Copy bufnr` -- bufnr → :Copy
- [ ] `:Copy filepath` -- filepath → :Copy
- [ ] `:Copy date` -- date → :Copy
- [ ] `:Copy uuid` -- uuid → :Copy
- [ ] `:Copy location` -- location → :Copy
- [ ] `:Copy snippet` -- snippet → :Copy
- [ ] `:Copy git` -- git → :Copy
- [ ] `:Copy linecount` -- linecount → :Copy
- [ ] `:Copy annotation` -- annotation → :Copy
- [ ] `:Copy env` -- env → :Copy

### :CopyFilepathAbsolute

- [ ] `:CopyFilepathAbsolute` -- [buffer-ctx compat] Copy absolute filepath to clipboard

### :CopyFilepathEnv

- [ ] `:CopyFilepathEnv` -- [buffer-ctx compat] Copy filepath, $REPOS_DIR/$NVIM_CONFIG_DIR folded in

### :CopyFilepathRelative

- [ ] `:CopyFilepathRelative` -- [buffer-ctx compat] Copy cwd-relative filepath to clipboard

### :CopyFilepathRepos

- [ ] `:CopyFilepathRepos` -- [buffer-ctx compat] Copy $REPOS_DIR-relative filepath to clipboard

### :CopyLocation

- [ ] `:CopyLocation` -- Copy the absolute path, line and column to the clipboard

### :CwdHere

- [ ] `:CwdHere` -- (no description)

### :Dap

- [ ] `:Dap toggle-breakpoint` -- Toggle Breakpoint
- [ ] `:Dap conditional-breakpoint` -- Conditional Breakpoint (condition, or prompts when omitted)
- [ ] `:Dap log-point` -- Log Point (message, or prompts when omitted)
- [ ] `:Dap list-breakpoints` -- List Breakpoints
- [ ] `:Dap toggle-ui` -- Toggle UI
- [ ] `:Dap eval` -- Evaluate Expression
- [ ] `:Dap terminate` -- Terminate
- [ ] `:Dap repl` -- Open REPL
- [ ] `:Dap step-out` -- Step Out
- [ ] `:Dap step-over` -- Step Over
- [ ] `:Dap continue` -- Continue
- [ ] `:Dap step-into` -- Step Into

### :Data

- [ ] `:Data pretty` -- Pretty-print, format auto-detected (fenced block, register contents, or filetype)
- [ ] `:Data` -- Format/filter with json/yaml/xml auto-detected from a fenced block or filetype (range-aware; no range = whole buffer)
- [ ] `:Data filter` -- Interactively filter flattened path/value entries, format auto-detected (requires pickers.nvim; --preview to diff before replacing)
- [ ] `:Data lines` -- One 'path: value' per leaf, format auto-detected (--sep to override)
- [ ] `:Data sort` -- Pretty-print with object keys sorted, format auto-detected
- [ ] `:Data keys` -- Only the (dotted) key paths, format auto-detected

### :Debug

- [ ] `:Debug` -- Unified debugging entry point — :Debug {category} {action}
- [ ] `:Debug proc log` -- Open the process-call log
- [ ] `:Debug neotest state` -- The current buffer's neotest tree
- [ ] `:Debug neotest adapters` -- Configured (neotest.setup) vs registered adapters
- [ ] `:Debug neotest file` -- Does any adapter's is_test_file() want this file?
- [ ] `:Debug neotest root` -- The project root each adapter derives, and its markers
- [ ] `:Debug neotest framework` -- Test-framework marker files and package.json frameworks found in the cwd
- [ ] `:Debug proc watch` -- External process-tree watcher for UI freezes (Windows only)
- [ ] `:Debug proc status` -- Show whether the process logger runs
- [ ] `:Debug indent show` -- Print the indent options
- [ ] `:Debug performance startup` -- Benchmark startup time and list the slowest sourced scripts
- [ ] `:Debug indent treesitter` -- Prefer Tree-sitter indent (true) or set cindent/smartindent on (false)
- [ ] `:Debug neotest discover` -- Positions per registered adapter, tests in total
- [ ] `:Debug inspect tab` -- Tab page: windows and buffers
- [ ] `:Debug noice errors` -- Popup with the recent error messages
- [ ] `:Debug noice all` -- Popup with the recent messages of every level
- [ ] `:Debug cursor state` -- Cursor, window and buffer state
- [ ] `:Debug markdown inline` -- Gather markdown inline-highlight debug info
- [ ] `:Debug report buf` -- Buffer report to :messages
- [ ] `:Debug report win` -- Window report to :messages (optionally for a window id)
- [ ] `:Debug report tab` -- Tab report to :messages
- [ ] `:Debug inspect window` -- Window-scoped options and state
- [ ] `:Debug inspect buffer` -- Buffer-scoped options and state
- [ ] `:Debug health` -- Run :checkhealth debugging
- [ ] `:Debug markdown log` -- Open the markdown debug log
- [ ] `:Debug messages show` -- Popup with the recent non-error messages (last 10 s, extendable)
- [ ] `:Debug messages capture` -- Capture :messages to a file and the clipboard
- [ ] `:Debug messages clear` -- Close the recent-messages popups
- [ ] `:Debug dump` -- Dump a global Lua variable (or the word under the cursor)
- [ ] `:Debug proc start` -- Log the duration of system()/jobstart calls; slow ones get a traceback
- [ ] `:Debug keylogger start` -- Log keys typed in the current terminal buffer (optionally to a file)
- [ ] `:Debug module reload` -- Reload the Lua module of the current buffer
- [ ] `:Debug autocmds all` -- Sources-vs-runtime view of autocmds, with the diff
- [ ] `:Debug autocmds sources` -- Static source-code audit of autocmd call sites
- [ ] `:Debug autocmds runtime` -- Live autocmds for an event / pattern

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

### :Diff

- [ ] `:Diff` -- (no description)

### :DiffBuffers

- [ ] `:DiffBuffers` -- (no description)

### :DiffClear

- [ ] `:DiffClear` -- (no description)

### :DiffExit

- [ ] `:DiffExit` -- (no description)

### :DiffHistory

- [ ] `:DiffHistory` -- (no description)

### :DiffOrig

- [ ] `:DiffOrig` -- (no description)

### :DiffProfile

- [ ] `:DiffProfile` -- (no description)

### :DirPicker

- [ ] `:DirPicker` -- [pickers compat] :DirPicker [nav] → :Pickers dir [nav]

### :DocBrowse

- [ ] `:DocBrowse` -- Browse the module map in the editor (:DocBrowse [live] [history|trail|endpoints|module])

### :DocMapAll

- [ ] `:DocMapAll` -- Generate every configured project's module map, fast scan (same as :DocMap all)

### :DocMapAllFull

- [ ] `:DocMapAllFull` -- Generate every configured project's module map, with LuaLS enrichment (same as :DocMap all full)

### :Emojis

- [ ] `:Emojis overlay` -- Open the quick-insert overlay (grid|grid_keys|list)
- [ ] `:Emojis count` -- Count emojis in the given scope
- [ ] `:Emojis replace` -- Replace emojis with :shortcode: placeholders in the given scope
- [ ] `:Emojis insert` -- Open the insert picker
- [ ] `:Emojis toggle` -- Cycle the emoji checkbox on the cursor line (or the given range)
- [ ] `:Emojis` -- [emojis] :Emojis [clear|insert|list|count|replace|unreplace|first|next|wrap|overlay|toggle|unicode] [word|line|visual|%|cwd]
- [ ] `:Emojis first` -- Jump to the first emoji in the buffer
- [ ] `:Emojis unreplace` -- Restore :shortcode: placeholders back to emojis in the given scope
- [ ] `:Emojis wrap` -- Surround emojis with the configured marker in the given scope
- [ ] `:Emojis next` -- Jump to the next emoji in the buffer (wraps)
- [ ] `:Emojis list` -- List emojis found in the given scope
- [ ] `:Emojis unicode` -- Unicode toolkit: name (char under cursor) | search[!] <query> | table | digraphs

### :EslintFix

- [ ] `:EslintFix` -- Run eslint_d --fix on current file (requires eslint config in project root)

### :Execute

- [ ] `:Execute` -- Run Ex, Lua or shell text from the buffer; without a bang it is typed into the command line first

### :File

- [ ] `:File rename` -- Rename the file on disk and update the buffer (reloads)
- [ ] `:File copy` -- Copy the file to a new path without opening it
- [ ] `:File move` -- Move the file on disk and update the buffer (no reload)
- [ ] `:File duplicate` -- Copy the file to a new path and open the copy
- [ ] `:File touch` -- Create an empty file if it does not exist yet
- [ ] `:File writeto` -- Write a copy, the buffer name stays
- [ ] `:File mkdir` -- Create the parent dirs of the current buffer
- [ ] `:File write` -- Set the buffer name and write it to disk
- [ ] `:File saveas` -- Save as: the buffer name changes
- [ ] `:File new` -- Set the buffer name (creates parent dirs, no write)
- [ ] `:File next` -- Next file in the directory (optionally filtered, e.g. *.lua)
- [ ] `:File path` -- Copy the current file's path to the clipboard (abs/rel/name/dir)
- [ ] `:File info` -- Show size, mtime and permissions of the current file
- [ ] `:File lockinfo` -- Diagnose which process locks the file
- [ ] `:File cd` -- Set the cwd to the buffer's directory and refresh the explorer
- [ ] `:File open` -- Reopen the current file in a different window target
- [ ] `:File first` -- Jump to the first file in the directory
- [ ] `:File last` -- Jump to the last file in the directory
- [ ] `:File bulk rename` -- Batch-rename files in the directory via a Lua pattern (preview + confirm)
- [ ] `:File help` -- Show the :File sub-commands
- [ ] `:File prev` -- Previous file in the directory (optionally filtered)

### :FileGrep

- [ ] `:FileGrep` -- [pickers] :FileGrep [query] → :Pickers cwd filegrep (query seeds the prompt)

### :FileGrepConfig

- [ ] `:FileGrepConfig` -- [pickers] :FileGrepConfig [query] → :Pickers config filegrep

### :Filetree

- [ ] `:Filetree copy absolute_raw` -- Copy the plain absolute path, never folded
- [ ] `:Filetree source debug` -- Print the source list, where it came from, and which sources can load
- [ ] `:Filetree source pick` -- Pick a neo-tree source from a floating list
- [ ] `:Filetree source` -- Pick a neo-tree source from a list, or switch to a named one
- [ ] `:Filetree cwd mode` -- Set the cwd/root policy (follow | project | nearest | lock | manual | tree_leads)
- [ ] `:Filetree cwd scope` -- Set the directory scope of the cwd policy (:cd | :tcd | :lcd)
- [ ] `:Filetree source prev` -- Switch to the previous neo-tree source (wrapping)
- [ ] `:Filetree filter clear` -- Clear current filter
- [ ] `:Filetree rename` -- Open batch rename buffer
- [ ] `:Filetree filter` -- Open the filter input, or apply a query directly
- [ ] `:Filetree source next` -- Switch to the next neo-tree source (wrapping)
- [ ] `:Filetree copy project_relative` -- Copy path relative to the project root
- [ ] `:Filetree copy project_root` -- Copy the detected project root (cwd-independent; folded like absolute)
- [ ] `:Filetree copy buffer_relative` -- Copy path relative to the buffer open in the editor (./x, ../x)
- [ ] `:Filetree copy line` -- Copy path with line number
- [ ] `:Filetree copy stem` -- Copy stem (no extension)
- [ ] `:Filetree copy uri` -- Copy as file:// URI
- [ ] `:Filetree breadcrumbs update` -- Update breadcrumb display
- [ ] `:Filetree copy env_rooted` -- Copy absolute path with an env-var root folded in ($REPOS_DIR/…)
- [ ] `:Filetree copy name` -- Copy filename
- [ ] `:Filetree copy dirname` -- Copy absolute parent directory (folded like absolute)
- [ ] `:Filetree copy absolute` -- Copy absolute path (as $REPOS_DIR/… / $NVIM_CONFIG_DIR/… under an env_roots root)
- [ ] `:Filetree copy pick` -- Open format picker
- [ ] `:Filetree copy relative` -- Copy relative path
- [ ] `:Filetree session save` -- Save current session
- [ ] `:Filetree reveal pause` -- Pause auto-reveal for [ms] milliseconds (default 2000)
- [ ] `:Filetree session clear` -- Clear saved session
- [ ] `:Filetree clipboard clear` -- Clear clipboard
- [ ] `:Filetree clipboard show` -- Show copy/cut clipboard
- [ ] `:Filetree reveal resume` -- Resume auto-reveal
- [ ] `:Filetree mdrefs confirm` -- Confirm the pending references fix-up (quickfix picker)
- [ ] `:Filetree references` -- List where the file under the cursor (or a path) is referenced; a directory runs refs unused
- [ ] `:Filetree mdrefs cancel` -- Cancel the pending references fix-up (quickfix picker)
- [ ] `:Filetree safety dry-run` -- Toggle safety dry-run
- [ ] `:Filetree git refresh` -- Refresh git status
- [ ] `:Filetree size refresh` -- Refresh size annotations
- [ ] `:Filetree clipboard copy` -- Stage the marked nodes (else the current one) for copy
- [ ] `:Filetree info` -- Show node info float
- [ ] `:Filetree move` -- Move the current node (or all marked): prompts for a destination unless one is given
- [ ] `:Filetree info close` -- Close info float
- [ ] `:Filetree session restore` -- Restore session
- [ ] `:Filetree keys` -- List keys claimed by more than one filetree action
- [ ] `:Filetree require` -- Copy as require("…") string
- [ ] `:Filetree wholocks` -- Diagnose who is holding a file open (Windows EBUSY/EPERM); --json for structured output
- [ ] `:Filetree reveal` -- Reveal current buffer in tree
- [ ] `:Filetree refs unused` -- List unreferenced asset files under a dir (--all: any file); pick to trash
- [ ] `:Filetree refs list` -- List where the file under the cursor (or a path) is referenced
- [ ] `:Filetree require relative` -- Copy as relative require
- [ ] `:Filetree find` -- Find files (optionally scoped to a directory)
- [ ] `:Filetree clipboard paste` -- Paste staged nodes
- [ ] `:Filetree diff close` -- Close diff windows
- [ ] `:Filetree clipboard cut` -- Stage the marked nodes (else the current one) for cut
- [ ] `:Filetree diff marked` -- Diff marked nodes
- [ ] `:Filetree refs status` -- Show engine state: modes, providers, ripgrep, pending undo
- [ ] `:Filetree safety list` -- List safety backups
- [ ] `:Filetree openas split` -- Open current node in a horizontal split
- [ ] `:Filetree cwd status` -- Show the active mode, its scope, root and the cwd
- [ ] `:Filetree toggle` -- Toggle the tree at left, right, float or current (default left), revealing the current file
- [ ] `:Filetree quickpick cwd` -- Number the tree's entries with the tree rooted at the cwd
- [ ] `:Filetree traverse down` -- Set current dir as root
- [ ] `:Filetree open pick` -- Open with app picker
- [ ] `:Filetree traverse up` -- Navigate to parent directory
- [ ] `:Filetree open` -- Open the tree focused on a directory or file
- [ ] `:Filetree quickpick cancel` -- Leave the mode
- [ ] `:Filetree watcher exit` -- Exit watcher quarantine
- [ ] `:Filetree hooks events` -- List registered hook events
- [ ] `:Filetree quickpick` -- Number the tree's visible entries and open one by typing its number
- [ ] `:Filetree hooks clear` -- Clear hooks
- [ ] `:Filetree watcher enter` -- Enter watcher quarantine
- [ ] `:Filetree traverse goto` -- Change the tree root to a given directory
- [ ] `:Filetree open app` -- Open with named app
- [ ] `:Filetree filelist dirs abs` -- Copy recursive dir list (absolute)
- [ ] `:Filetree trash dry-run` -- Toggle dry-run mode
- [ ] `:Filetree mdlink` -- Copy Markdown links for the marked nodes (else the current one)
- [ ] `:Filetree mdlink insert` -- Insert markdown link(s) (marked nodes, else the current one) into the editor window
- [ ] `:Filetree trash undo` -- Undo last trash operation
- [ ] `:Filetree trash history` -- Show trash history
- [ ] `:Filetree open system` -- Open with system default
- [ ] `:Filetree mdlink recursive` -- Markdown links for every file under current node
- [ ] `:Filetree smartrename` -- Rename with LSP reference update
- [ ] `:Filetree filelist dirs rel` -- Copy recursive dir list (relative)
- [ ] `:Filetree mdlink marked` -- Markdown links for all marked nodes
- [ ] `:Filetree filelist files abs` -- Copy recursive file list (absolute)
- [ ] `:Filetree filelist files rel` -- Copy recursive file list (relative)
- [ ] `:Filetree cwd unlock` -- Leave lock mode, back to the previous one
- [ ] `:Filetree openas badd` -- Add current node to buffer list (no focus switch)
- [ ] `:Filetree openas vsplit` -- Open current node in a vertical split
- [ ] `:Filetree symlink checkall` -- Report symlink state of every marked node (else the node under the cursor)
- [ ] `:Filetree symlink paste` -- Paste the marked source as a link, kind picked automatically
- [ ] `:Filetree symlink check` -- Report whether the node/path is a symlink, and whether it's broken
- [ ] `:Filetree symlink` -- Prompt for a target path, create a symlink/hardlink to it in the current tree directory
- [ ] `:Filetree symlink repairall` -- Repair every broken symlink among the marked nodes
- [ ] `:Filetree symlink mark` -- Mark a link source (node/buffer/explicit path), no prompt
- [ ] `:Filetree handles` -- List tracked neo-tree watcher handles
- [ ] `:Filetree symlink repair` -- If broken, search the filesystem for a new target
- [ ] `:Filetree cwd toggle` -- Cycle through the configured modes
- [ ] `:Filetree cwd here` -- Pin the cwd to the node under the cursor
- [ ] `:Filetree openas tabnew` -- Open current node in a new tab
- [ ] `:Filetree marks all` -- Mark all visible nodes
- [ ] `:Filetree marks show` -- Show floating list
- [ ] `:Filetree renamebatch dry-run` -- Toggle dry-run for the batch rename at runtime
- [ ] `:Filetree copymove dry-run` -- Toggle dry-run for copy/move at runtime — trash and safety always had one
- [ ] `:Filetree clipfiles` -- Copy the marked nodes (else the current one) to the OS clipboard as files
- [ ] `:Filetree template` -- Create file from template — pick a template first
- [ ] `:Filetree marks clear` -- Clear all marks
- [ ] `:Filetree search` -- Open live search
- [ ] `:Filetree create` -- Smart create file or directory
- [ ] `:Filetree grep` -- Grep in the node's directory (picker if installed, else rg/grep quickfix)
- [ ] `:Filetree search clear` -- Clear search highlighting
- [ ] `:Filetree health` -- Run :checkhealth filetree
- [ ] `:Filetree resize` -- Set tree window width
- [ ] `:Filetree cwd lock` -- Lock the cwd to a directory (default: the current one)

### :FindConfig

- [ ] `:FindConfig` -- [pickers compat] :FindConfig → :Pickers config files

### :FindInFolder

- [ ] `:FindInFolder` -- [pickers compat] :FindInFolder → :Pickers folder files

### :FindOnSystem

- [ ] `:FindOnSystem` -- [pickers compat] :FindOnSystem → :Pickers system files

### :Format

- [ ] `:Format clear` -- Clear buffer content
- [ ] `:Format indent` -- Fix indentation: indent [--spaces|--tabs] [width]
- [ ] `:Format enum` -- Enumerate tokens in visual selection: enum [STYLE] [sep=SEP] [start=N] [inline=bool]
- [ ] `:Format case` -- Change case: case <upper|lower|title|sentence>
- [ ] `:Format column` -- Align selected char to column: column <N> [fill]
- [ ] `:Format textwidth` -- Reflow text to width: textwidth <N|max>
- [ ] `:Format sort` -- Sort buffer lines: sort [-r] [-i] [-n]
- [ ] `:Format table` -- Format Markdown table(s): table [ALIGN] [header=ALIGN] [cell=ALIGN] [skip=COL] [scope=cursor|buffer|cwd|PATH]
- [ ] `:Format squeeze` -- Collapse consecutive blank lines to at most one

### :Ft

- [ ] `:Ft refs unused` -- List unreferenced asset files under a dir (--all: any file); pick to trash
- [ ] `:Ft session clear` -- Clear saved session
- [ ] `:Ft session restore` -- Restore session
- [ ] `:Ft session save` -- Save current session
- [ ] `:Ft refs list` -- List where the file under the cursor (or a path) is referenced
- [ ] `:Ft hooks clear` -- Clear hooks
- [ ] `:Ft refs status` -- Show engine state: modes, providers, ripgrep, pending undo
- [ ] `:Ft breadcrumbs update` -- Update breadcrumb display
- [ ] `:Ft diff close` -- Close diff windows
- [ ] `:Ft diff marked` -- Diff marked nodes
- [ ] `:Ft filter clear` -- Clear current filter
- [ ] `:Ft copy stem` -- Copy stem (no extension)
- [ ] `:Ft copy env_rooted` -- Copy absolute path with an env-var root folded in ($REPOS_DIR/…)
- [ ] `:Ft copy name` -- Copy filename
- [ ] `:Ft copy absolute` -- Copy absolute path (as $REPOS_DIR/… / $NVIM_CONFIG_DIR/… under an env_roots root)
- [ ] `:Ft copy dirname` -- Copy absolute parent directory (folded like absolute)
- [ ] `:Ft filter` -- Open the filter input, or apply a query directly
- [ ] `:Ft require` -- Copy as require("…") string
- [ ] `:Ft copy uri` -- Copy as file:// URI
- [ ] `:Ft copy line` -- Copy path with line number
- [ ] `:Ft copy project_relative` -- Copy path relative to the project root
- [ ] `:Ft copy absolute_raw` -- Copy the plain absolute path, never folded
- [ ] `:Ft require relative` -- Copy as relative require
- [ ] `:Ft size refresh` -- Refresh size annotations
- [ ] `:Ft mdrefs cancel` -- Cancel the pending references fix-up (quickfix picker)
- [ ] `:Ft clipboard cut` -- Stage the marked nodes (else the current one) for cut
- [ ] `:Ft find` -- Find files (optionally scoped to a directory)
- [ ] `:Ft clipboard paste` -- Paste staged nodes
- [ ] `:Ft clipboard clear` -- Clear clipboard
- [ ] `:Ft clipboard show` -- Show copy/cut clipboard
- [ ] `:Ft wholocks` -- Diagnose who is holding a file open (Windows EBUSY/EPERM); --json for structured output
- [ ] `:Ft cwd scope` -- Set the directory scope of the cwd policy (:cd | :tcd | :lcd)
- [ ] `:Ft cwd mode` -- Set the cwd/root policy (follow | project | nearest | lock | manual | tree_leads)
- [ ] `:Ft traverse goto` -- Change the tree root to a given directory
- [ ] `:Ft cwd lock` -- Lock the cwd to a directory (default: the current one)
- [ ] `:Ft keys` -- List keys claimed by more than one filetree action
- [ ] `:Ft clipboard copy` -- Stage the marked nodes (else the current one) for copy
- [ ] `:Ft move` -- Move the current node (or all marked): prompts for a destination unless one is given
- [ ] `:Ft reveal resume` -- Resume auto-reveal
- [ ] `:Ft references` -- List where the file under the cursor (or a path) is referenced; a directory runs refs unused
- [ ] `:Ft mdrefs confirm` -- Confirm the pending references fix-up (quickfix picker)
- [ ] `:Ft git refresh` -- Refresh git status
- [ ] `:Ft reveal` -- Reveal current buffer in tree
- [ ] `:Ft copy relative` -- Copy relative path
- [ ] `:Ft reveal pause` -- Pause auto-reveal for [ms] milliseconds (default 2000)
- [ ] `:Ft info close` -- Close info float
- [ ] `:Ft info` -- Show node info float
- [ ] `:Ft hooks events` -- List registered hook events
- [ ] `:Ft copy pick` -- Open format picker
- [ ] `:Ft copy project_root` -- Copy the detected project root (cwd-independent; folded like absolute)
- [ ] `:Ft mdlink` -- Copy Markdown links for the marked nodes (else the current one)
- [ ] `:Ft mdlink insert` -- Insert markdown link(s) (marked nodes, else the current one) into the editor window
- [ ] `:Ft trash history` -- Show trash history
- [ ] `:Ft mdlink recursive` -- Markdown links for every file under current node
- [ ] `:Ft smartrename` -- Rename with LSP reference update
- [ ] `:Ft mdlink marked` -- Markdown links for all marked nodes
- [ ] `:Ft filelist files rel` -- Copy recursive file list (relative)
- [ ] `:Ft trash undo` -- Undo last trash operation
- [ ] `:Ft openas split` -- Open current node in a horizontal split
- [ ] `:Ft template` -- Create file from template — pick a template first
- [ ] `:Ft trash dry-run` -- Toggle dry-run mode
- [ ] `:Ft openas vsplit` -- Open current node in a vertical split
- [ ] `:Ft openas badd` -- Add current node to buffer list (no focus switch)
- [ ] `:Ft openas tabnew` -- Open current node in a new tab
- [ ] `:Ft clipfiles` -- Copy the marked nodes (else the current one) to the OS clipboard as files
- [ ] `:Ft filelist files abs` -- Copy recursive file list (absolute)
- [ ] `:Ft filelist dirs abs` -- Copy recursive dir list (absolute)
- [ ] `:Ft quickpick cancel` -- Leave the mode
- [ ] `:Ft quickpick cwd` -- Number the tree's entries with the tree rooted at the cwd
- [ ] `:Ft quickpick` -- Number the tree's visible entries and open one by typing its number
- [ ] `:Ft watcher enter` -- Enter watcher quarantine
- [ ] `:Ft watcher exit` -- Exit watcher quarantine
- [ ] `:Ft filelist dirs rel` -- Copy recursive dir list (relative)
- [ ] `:Ft toggle` -- Toggle the tree at left, right, float or current (default left), revealing the current file
- [ ] `:Ft traverse up` -- Navigate to parent directory
- [ ] `:Ft open system` -- Open with system default
- [ ] `:Ft traverse down` -- Set current dir as root
- [ ] `:Ft open app` -- Open with named app
- [ ] `:Ft open pick` -- Open with app picker
- [ ] `:Ft open` -- Open the tree focused on a directory or file
- [ ] `:Ft copy buffer_relative` -- Copy path relative to the buffer open in the editor (./x, ../x)
- [ ] `:Ft renamebatch dry-run` -- Toggle dry-run for the batch rename at runtime
- [ ] `:Ft search` -- Open live search
- [ ] `:Ft cwd unlock` -- Leave lock mode, back to the previous one
- [ ] `:Ft safety list` -- List safety backups
- [ ] `:Ft cwd status` -- Show the active mode, its scope, root and the cwd
- [ ] `:Ft cwd toggle` -- Cycle through the configured modes
- [ ] `:Ft cwd here` -- Pin the cwd to the node under the cursor
- [ ] `:Ft safety dry-run` -- Toggle safety dry-run
- [ ] `:Ft source prev` -- Switch to the previous neo-tree source (wrapping)
- [ ] `:Ft rename` -- Open batch rename buffer
- [ ] `:Ft source next` -- Switch to the next neo-tree source (wrapping)
- [ ] `:Ft source pick` -- Pick a neo-tree source from a floating list
- [ ] `:Ft source debug` -- Print the source list, where it came from, and which sources can load
- [ ] `:Ft source` -- Pick a neo-tree source from a list, or switch to a named one
- [ ] `:Ft copymove dry-run` -- Toggle dry-run for copy/move at runtime — trash and safety always had one
- [ ] `:Ft handles` -- List tracked neo-tree watcher handles
- [ ] `:Ft symlink mark` -- Mark a link source (node/buffer/explicit path), no prompt
- [ ] `:Ft marks show` -- Show floating list
- [ ] `:Ft marks clear` -- Clear all marks
- [ ] `:Ft grep` -- Grep in the node's directory (picker if installed, else rg/grep quickfix)
- [ ] `:Ft create` -- Smart create file or directory
- [ ] `:Ft health` -- Run :checkhealth filetree
- [ ] `:Ft symlink repair` -- If broken, search the filesystem for a new target
- [ ] `:Ft marks all` -- Mark all visible nodes
- [ ] `:Ft symlink check` -- Report whether the node/path is a symlink, and whether it's broken
- [ ] `:Ft symlink repairall` -- Repair every broken symlink among the marked nodes
- [ ] `:Ft symlink checkall` -- Report symlink state of every marked node (else the node under the cursor)
- [ ] `:Ft symlink` -- Prompt for a target path, create a symlink/hardlink to it in the current tree directory
- [ ] `:Ft symlink paste` -- Paste the marked source as a link, kind picked automatically
- [ ] `:Ft resize` -- Set tree window width
- [ ] `:Ft search clear` -- Clear search highlighting

### :Git

- [ ] `:Git conflict theirs` -- Resolve the conflict under the cursor: keep theirs
- [ ] `:Git conflict base` -- Resolve the conflict under the cursor: keep the common ancestor (diff3/zdiff3 only)
- [ ] `:Git diff split` -- Open the diff view
- [ ] `:Git branch switch` -- Switch to another local branch
- [ ] `:Git conflict none` -- Resolve the conflict under the cursor: keep neither
- [ ] `:Git diff close` -- Close every open diff view and leave diff mode (diff.nvim :DiffClear)
- [ ] `:Git conflict next` -- Jump to the next conflict marker in this buffer
- [ ] `:Git diff rev` -- Diff the current file against an arbitrary revision
- [ ] `:Git diff head` -- Diff the current file against HEAD
- [ ] `:Git branch current` -- Show the current branch
- [ ] `:Git diff last` -- Diff the current file against the previous commit
- [ ] `:Git branch list` -- List local branches
- [ ] `:Git blame full` -- Show full blame for the current file
- [ ] `:Git blame line` -- Show blame for the current line
- [ ] `:Git browse file` -- Open the current file on its web host
- [ ] `:Git conflict prev` -- Jump to the previous conflict marker in this buffer
- [ ] `:Git conflict refresh` -- Re-scan the current buffer for conflict markers
- [ ] `:Git plugins report` -- Report what changed in the installed plugins: the last update (--mode=updated) or what is pending (--mode=pending); reads local state only
- [ ] `:Git hunk inline` -- Toggle inline diff: invert word_diff & linehl, preview current hunk inline
- [ ] `:Git diff history` -- Show file history (diff.nvim :DiffHistory)
- [ ] `:Git conflict list` -- List every file with unresolved conflicts in the quickfix list
- [ ] `:Git conflict ours` -- Resolve the conflict under the cursor: keep ours
- [ ] `:Git hunk preview` -- Preview the hunk under the cursor
- [ ] `:Git hunk stage` -- Stage the hunk under the cursor
- [ ] `:Git hunk stage-buffer` -- Stage every hunk in the current buffer
- [ ] `:Git conflict both` -- Resolve the conflict under the cursor: keep both
- [ ] `:Git browse selection` -- Open the current visual selection (with line range) on its web host
- [ ] `:Git blame toggle` -- Toggle current-line blame virtual text
- [ ] `:Git dashboard update` -- Update (fetch + ff-only pull) every repository in dir/$REPOS_DIR, headless
- [ ] `:Git ui neogit` -- Open neogit
- [ ] `:Git ui lazygit` -- Open lazygit in a floating terminal (optionally for the repo containing <dir>)
- [ ] `:Git plugins log` -- Show the newest commits of an installed plugin (or any clone): picker with preview, --count=<n>, --out=buffer|clipboard
- [ ] `:Git status quickfix` -- Export repo status to the quickfix list
- [ ] `:Git ui diffview open` -- Open diffview
- [ ] `:Git status repo` -- Show repo status (branch, ahead/behind, dirty)
- [ ] `:Git ui diffview close` -- Close the current diffview
- [ ] `:Git status todos` -- Pre-commit gate: TODO/FIXME/... annotations in the changed files only
- [ ] `:Git status lint` -- Pre-commit gate: LSP diagnostics for the changed files that already have a loaded buffer
- [ ] `:Git status relink` -- Fix references (Markdown links, etc.) to files git status reports as renamed
- [ ] `:Git dashboard` -- Show the git dashboard of every repository in dir/$REPOS_DIR (or one repository); <C-l>/<C-h> flip through dashboard.groups
- [ ] `:Git browse repo` -- Open the repository root on its web host
- [ ] `:Git status spell` -- Pre-commit gate: misspellings in the changed files' on-disk content

### :GithubStats

- [ ] `:GithubStats diff` -- Compare periods: {repo} {metric} {YYYY-MM} {YYYY-MM}
- [ ] `:GithubStats debug` -- Debug configuration and test API connection
- [ ] `:GithubStats referrers` -- Show top referrers: {repo} [limit]
- [ ] `:GithubStats digest` -- Rebuild the per-repository digest other programs read (after a sync, the local one may lag)
- [ ] `:GithubStats show` -- Show stats for repo/metric: {repo} {metric} [start] [end]
- [ ] `:GithubStats paths` -- Show top paths: {repo} [limit]
- [ ] `:GithubStats export` -- Export to CSV/Markdown: {repo|all} {clones|views|both} {filepath}
- [ ] `:GithubStats chart` -- Show sparkline chart: {repo} {clones|views|both} [start|range] [end]
- [ ] `:GithubStats summary` -- Show summary across all repos: {clones|views}

### :GitsuiteLazygitBadd

- [ ] `:GitsuiteLazygitBadd` -- [gitsuite] Add file to buffer list (called via nvr from lazygit)

### :GitsuiteLazygitReplace

- [ ] `:GitsuiteLazygitReplace` -- [gitsuite] Replace visible editor buffer with file (called via nvr from lazygit)

### :Gopath

- [ ] `:Gopath cache info` -- Show filesystem cache stats
- [ ] `:Gopath to-repos-dir` -- Rewrite the current line's repos-root path to $VAR, or just a visual selection of it (see env_variable_resolution.shorten_dirs)
- [ ] `:Gopath to-nvim-dir` -- Rewrite the current line's stdpath('config') occurrences to $VAR, or just a visual selection of it (see env_variable_resolution.shorten_known_dirs)
- [ ] `:Gopath cache build` -- Rebuild the filesystem cache
- [ ] `:Gopath cache add-root` -- Add a directory to the filesystem cache roots
- [ ] `:Gopath probe` -- Probe path under cursor/selection
- [ ] `:Gopath copy` -- Copy path:line:col to clipboard
- [ ] `:Gopath check` -- Check existence / offer to create the path under the cursor
- [ ] `:Gopath debug` -- Show resolution info for the path under the cursor
- [ ] `:Gopath open` -- Resolve & open the path under the cursor

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

### :GopathToNvimDir

- [ ] `:GopathToNvimDir` -- Gopath: shorten line's stdpath('config') occurrences to $VAR, or just a visual selection of it (alias for :Gopath to-nvim-dir)

### :GopathToReposDir

- [ ] `:GopathToReposDir` -- Gopath: shorten line's repos-root path to $VAR, or just a visual selection of it (alias for :Gopath to-repos-dir)

### :GrepConfig

- [ ] `:GrepConfig` -- [pickers compat] :GrepConfig → :Pickers config grep

### :Hover

- [ ] `:Hover all` -- Everything at once: every switch, every type and the mode
- [ ] `:Hover mode` -- Set the mode: auto opens by itself, manual only on request, off not at all
- [ ] `:Hover nav` -- Move the magnified view
- [ ] `:Hover zoom` -- Magnify a detail of the picture on screen, or step back out
- [ ] `:Hover links` -- whether a target written with link syntax hovers at all
- [ ] `:Hover why` -- Say why nothing hovered at the cursor
- [ ] `:Hover show` -- Show the hover for whatever is under the cursor, ignoring every volume switch
- [ ] `:Hover auto` -- Which target types open by themselves; a type toggles it, `all`/`none` set every one
- [ ] `:Hover open` -- Open what the hover is showing, in whatever handles it outside Neovim
- [ ] `:Hover toggle` -- Turn the hover off for this session, or back on
- [ ] `:Hover paths missing` -- whether a bare path that resolves to nothing is reported as broken
- [ ] `:Hover border` -- Border style: rounded, single, double, heavy, ascii, dashed, block, solid, shadow, none
- [ ] `:Hover links web shot eager` -- let the automatic trigger render a page, not only an explicit request
- [ ] `:Hover links web shot` -- render a hovered link in a headless browser and draw the page into the float
- [ ] `:Hover paths code` -- whether a bare path hovers inside executable code, not just comments and strings
- [ ] `:Hover images` -- whether pictures and rasterized PDF pages are drawn into the float
- [ ] `:Hover positions` -- whether a plugin may say something about a cursor position that points at nothing
- [ ] `:Hover office` -- render office documents through a PDF instead of showing a badge
- [ ] `:Hover links web fetch pdf` -- show a link that answers with a PDF as its first page, paged and zoomable
- [ ] `:Hover paths` -- whether a path written in prose or a comment hovers
- [ ] `:Hover next` -- Step to the next plugin with something to say about this place
- [ ] `:Hover dashboard` -- Open the board: every switch, its state, and the command that acts on it
- [ ] `:Hover links web` -- whether http(s) links hover (off by default: documentation is made of links)
- [ ] `:Hover zen` -- Put the hover on screen full screen, or take it back
- [ ] `:Hover pin` -- Keep this hover on screen while the cursor goes elsewhere
- [ ] `:Hover links web fetch` -- fetch a hovered link for its status code and page title (implies `links web on`)
- [ ] `:Hover resize` -- Make the hover on screen bigger or smaller

### :Image

- [ ] `:Image convert` -- Write a copy in another format, same stem (photo.jpg -> photo.png); `pdf` takes the same route as :Image export
- [ ] `:Image optimise` -- Write a smaller copy next to the source: metadata stripped, best compression (photo.png -> photo.optimised.png); needs ImageMagick
- [ ] `:Image ocr` -- Read the text out of an image into a scratch buffer (tesseract); --lang=<code> overrides ocr.lang
- [ ] `:Image scale` -- Write a resized copy next to the source (photo.png -> photo.scaled.png); needs ImageMagick
- [ ] `:Image screenshot` -- Capture a screen selection interactively, save it and link it
- [ ] `:Image replace` -- Replace an existing image with the clipboard contents
- [ ] `:Image export` -- Export an image as a PDF, next to the source file
- [ ] `:Image info` -- An image's format, dimensions and size
- [ ] `:Image paste` -- Save an image from the clipboard and link it: :Image paste [env|abs|rel|repos] [name]; with {name} named directly instead of the configured name prompt; the mode word (or path=relative|absolute|repos|env|<prefix>) picks the link path (default: paste.default_path_mode, asked interactively when that is false)
- [ ] `:Image pickers` -- Browse images below cfile/cwd/path (live preview with snacks.picker)
- [ ] `:Image` -- :Image — show, compare and insert images in the terminal
- [ ] `:Image show` -- Show an image (without a path: the one under the cursor); an http(s) URL too with display.remote.enabled
- [ ] `:Image compare` -- Pick two images below cfile/cwd/path and compare them side by side
- [ ] `:Image debug` -- Measure image placement: report (log draws), columns (constant vs. scaling offset), float (is a window where it says it is), disarm (undo report's instrumentation)
- [ ] `:Image redact` -- Open an image in redaction mode: mark boxes and black them out, the original stays
- [ ] `:Image calibrate` -- Measure this terminal's image placement (test card, nudged into place); the result is stored
- [ ] `:Image list` -- List the images in the buffer (or in the selection) and show one
- [ ] `:Image pin` -- Pin the display — no clearing on cursor movement
- [ ] `:Image next` -- Jump to the buffer's next image and show it
- [ ] `:Image zen` -- Show an image large, in an editable window (not a preview window)
- [ ] `:Image check` -- Check whether this terminal can display images
- [ ] `:Image gallery` -- Show the buffer's (or the selection's) images side by side
- [ ] `:Image prev` -- Jump to the buffer's previous image and show it
- [ ] `:Image draw` -- Draw an image at a named position in the current window (without a path: the one under the cursor)

### :Insert

- [ ] `:Insert filepath` -- filepath → :Insert
- [ ] `:Insert imagepaste` -- images.nvim: paste the clipboard image, insert its Markdown link at the cursor (requires images.nvim)
- [ ] `:Insert mdlink` -- mdlink → :Insert
- [ ] `:Insert filename` -- filename → :Insert
- [ ] `:Insert date` -- date → :Insert
- [ ] `:Insert timestamp` -- timestamp → :Insert
- [ ] `:Insert git` -- git → :Insert
- [ ] `:Insert linecount` -- linecount → :Insert
- [ ] `:Insert bufnr` -- bufnr → :Insert
- [ ] `:Insert module` -- module → :Insert
- [ ] `:Insert env` -- env → :Insert
- [ ] `:Insert snippet` -- snippet → :Insert
- [ ] `:Insert location` -- location → :Insert
- [ ] `:Insert uuid` -- uuid → :Insert
- [ ] `:Insert annotation` -- annotation → :Insert
- [ ] `:Insert boilerplate` -- boilerplate → :Insert

### :Insights

- [ ] `:Insights count` -- Count project files
- [ ] `:Insights imports` -- import/require usage report (filters + optional picker UI)
- [ ] `:Insights cache clear` -- Clear symbol cache
- [ ] `:Insights compress` -- Archive a directory (default: cwd)
- [ ] `:Insights tree` -- Write project file tree
- [ ] `:Insights cache info` -- Show symbol cache stats
- [ ] `:Insights fileinfo` -- Toggle fs.stat float for current buffer
- [ ] `:Insights cache build` -- Rebuild symbol cache
- [ ] `:Insights clipboard` -- Copy tree to clipboard
- [ ] `:Insights symbols` -- Symbol index (scope/type/ui in any order)
- [ ] `:Insights imports reverse` -- List every file that imports <module>
- [ ] `:Insights conflicts` -- Quickfix unresolved git conflicts
- [ ] `:Insights smells` -- Magic numbers + unconfigured behaviour constants (flags + optional directory)
- [ ] `:Insights imports unused` -- Bound import names never referenced again in their file
- [ ] `:Insights devserver list` -- List tracked dev servers
- [ ] `:Insights unimported` -- Check used-but-unimported components
- [ ] `:Insights devserver` -- List tracked dev servers
- [ ] `:Insights todos` -- Annotation comments (TODO/FIX/...) — keyword filter and/or UI, any order
- [ ] `:Insights metrics` -- Lua code metrics (flags + optional directory)

### :JSON

- [ ] `:JSON sort` -- Pretty-print with object keys sorted (see data.format.<fmt> for why this equals 'pretty' today)
- [ ] `:JSON filter` -- Interactively filter flattened path/value entries (requires pickers.nvim; --preview to diff before replacing)
- [ ] `:JSON keys` -- List only the (dotted) key paths, no values
- [ ] `:JSON` -- JSON format/filter (range-aware; no range = whole buffer)
- [ ] `:JSON compact` -- Collapse onto one line
- [ ] `:JSON pretty` -- Pretty-print (default 2-space indent; pretty 4 for 4)
- [ ] `:JSON to` -- Convert to yaml
- [ ] `:JSON lines` -- One 'path: value' per leaf, nested keys dotted (--sep to override)
- [ ] `:JSON ndjson` -- Pretty-print each line as its own JSON object; malformed lines are left untouched

### :KitPreview

- [ ] `:KitPreview` -- ui.kit: live theme playground

### :LastSession

- [ ] `:LastSession` -- Load the session you left on exit (nvim +LastSession)

### :LearnPlanViewer

- [ ] `:LearnPlanViewer` -- CLI-Lernplan-Viewer öffnen (optional: week N)

### :Lib

- [ ] `:Lib notify history` -- Open the notify history (optionally filtered by source)
- [ ] `:Lib helptags` -- Regenerate all helptags now
- [ ] `:Lib ps-profile` -- Open the active PowerShell profile
- [ ] `:Lib cwd-here` -- lcd to the current buffer's directory
- [ ] `:Lib notify last` -- Show the last delivered message in full (viewer)
- [ ] `:Lib cache stats` -- Hit rate, entries and evictions of every in-memory cache namespace
- [ ] `:Lib deps show` -- List a plugin's declared external tools, why each matters, and what's missing
- [ ] `:Lib deps install` -- Offer to install missing external tools — one plugin's, or every plugin's (asks first)
- [ ] `:Lib deps status` -- Every declared tool across every plugin, and what's missing here
- [ ] `:Lib deps project` -- Scan this directory's files and show which treesitter parsers and tools are missing for them
- [ ] `:Lib notify clear` -- Clear the notify history (optionally by source)

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
- [ ] `:Lsp log open` -- Open Neovim's LSP log file in a split
- [ ] `:Lsp log level` -- Set the LSP log level (trace|debug|info|warn|error|off)
- [ ] `:Lsp diag` -- Diagnostics into a list, or jump to the next or previous one
- [ ] `:Lsp hints` -- Inlay hints: control globally, or for one filetype
- [ ] `:Lsp workspace` -- Workspace-wide diagnostics: control globally, or for one project (path, `.`, or a $REPOS_DIR folder)
- [ ] `:Lsp implement` -- Implementation markers: control globally, or for one filetype
- [ ] `:Lsp peek` -- Peek a definition (or type, implementation, declaration) in a float
- [ ] `:Lsp recover` -- Auto-recover servers that should be running here and are not
- [ ] `:Lsp winbar` -- LSP breadcrumb in the winbar: control globally, or for one filetype
- [ ] `:Lsp lightbulb` -- Code-action indicator: control globally, or for one filetype
- [ ] `:Lsp info` -- Detailed LSP information for the current buffer
- [ ] `:Lsp servers` -- Servers set up, and the clients currently attached
- [ ] `:Lsp status` -- Show what lsp.nvim has set up
- [ ] `:Lsp doctor` -- Per-buffer diagnosis (same as :LspDoctor)
- [ ] `:Lsp health` -- Run :checkhealth lsp
- [ ] `:Lsp start` -- Start servers for this buffer (auto-detect, or one by name)

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

### :MDLinksView

- [ ] `:MDLinksView` -- List mdlinks in a scope, then open / export them

### :MDView

- [ ] `:MDView open` -- Re-open a browser tab against the already-running session
- [ ] `:MDView log trace` -- Show the internal log ring, filtered to TRACE and above
- [ ] `:MDView preview-tab` -- Toggle the in-Neovim tab preview (works standalone, no server needed)
- [ ] `:MDView write` -- Switch cursor caret and block editing together, starting the preview if needed; no argument toggles
- [ ] `:MDView weblogs` -- Show the relay's captured stdout, including [client] browser-side diagnostics
- [ ] `:MDView standalone` -- Preview via the relay's own file watcher, with no Neovim in the chain
- [ ] `:MDView start` -- Start the relay and open the preview for the current buffer (or the given file)
- [ ] `:MDView log warn` -- Show the internal log ring, filtered to WARN and above
- [ ] `:MDView cursor` -- Set the Neovim-cursor marker in the preview (line|caret|section|off|toggle — toggle flips section on/off)
- [ ] `:MDView file-log` -- Toggle persistent file logging, then report the state
- [ ] `:MDView log export` -- Write the internal log ring to a file (default: stdpath log)
- [ ] `:MDView log` -- Show the internal log ring
- [ ] `:MDView file-log on` -- Enable persistent file logging (optionally set its path)
- [ ] `:MDView file-log toggle` -- Toggle persistent file logging, then report the state
- [ ] `:MDView file-log off` -- Disable persistent file logging
- [ ] `:MDView file-log status` -- Report persistent file logging state without changing anything
- [ ] `:MDView theme` -- Switch the preview theme (optionally -light/-dark); no argument reports the current theme
- [ ] `:MDView diagnose` -- Write a full component-state diagnostics report to a file and open it
- [ ] `:MDView overlay` -- Toggle a preview overlay (floating TOC, …); no name lists them
- [ ] `:MDView overlay list` -- List the known preview overlays and whether each is on
- [ ] `:MDView blanklines` -- Show every blank line as extra space, or collapse them (CommonMark default); no argument toggles
- [ ] `:MDView pin` -- Hold the preview on the current document instead of following the active buffer; no argument toggles
- [ ] `:MDView reveal` -- Reveal/hide all private (```private) blocks in the preview
- [ ] `:MDView sync` -- Pause/resume the nvim->browser scroll sync; no argument reports the state
- [ ] `:MDView breadcrumbs` -- Show the session breadcrumbs (document + heading over time)
- [ ] `:MDView breadcrumbs clear` -- Discard the recorded session breadcrumbs
- [ ] `:MDView breadcrumbs export` -- Write the session breadcrumbs outline to a file (default: stdpath log)
- [ ] `:MDView log error` -- Show the internal log ring, filtered to ERROR and above
- [ ] `:MDView log info` -- Show the internal log ring, filtered to INFO and above
- [ ] `:MDView lang` -- Show the preview in another language (<code> | off | refresh); no argument reports the state
- [ ] `:MDView log debug` -- Show the internal log ring, filtered to DEBUG and above

### :Mark

- [ ] `:Mark toggle` -- Toggle the mark on the current line, or over a range
- [ ] `:Mark yank` -- Yank all marked lines to the system clipboard

### :MarkLineToggle

- [ ] `:MarkLineToggle` -- [buffer-ctx compat] Toggle mark on current line

### :MarkLinesYank

- [ ] `:MarkLinesYank` -- [buffer-ctx compat] Yank all marked lines

### :MasonInstallAll

- [ ] `:MasonInstallAll` -- Install every configured Mason package (LSP servers, DAP adapters, linters, formatters)

### :MdFormat

- [ ] `:MdFormat` -- [lsp] Format Markdown (prefer mdformat for .md)

### :MdFormatPrettier

- [ ] `:MdFormatPrettier` -- [lsp] Format via Prettier

### :MdSetRoot

- [ ] `:MdSetRoot` -- [md_words] Set project root for Markdown word scanning (empty = cwd)

### :MdWordStats

- [ ] `:MdWordStats` -- [md_words] Show word-cache statistics

### :Media

- [ ] `:Media transcribe` -- Speech to text  :Media transcribe [path] [engine=] [lang=] [task=transcribe|translate] [out=buffer|sidecar|srt|vtt]
- [ ] `:Media engines` -- List registered transcription engines and their availability
- [ ] `:Media health` -- Run health check
- [ ] `:Media` -- Describe the file, or open the dashboard when there is none  :Media [path]
- [ ] `:Media window` -- Play in an mpv window :Media window [path] [at=90] [screen=1]
- [ ] `:Media spectrogram` -- Spectrogram picture :Media spectrogram [path] [width=1200] [height=300]
- [ ] `:Media probe` -- Describe the file  :Media probe [path]
- [ ] `:Media play` -- Play in an external player  :Media play [path]
- [ ] `:Media frame` -- Poster frame  :Media frame [path] [at=10%] [width=800]
- [ ] `:Media waveform` -- Waveform picture :Media waveform [path] [width=1200] [height=300]
- [ ] `:Media sheet` -- Contact sheet  :Media sheet [path] [rows=3] [cols=4] [width=1200]
- [ ] `:Media text` -- Anything to text :Media text [path] [out=buffer|sidecar|srt|vtt]
- [ ] `:Media dashboard` -- One list across image/pdf/audio/video  :Media dashboard [cfile|cwd] [path=<dir>]

### :My

- [ ] `:My hl list` -- List all highlight config keys
- [ ] `:My opt show` -- Show an editor-option config value, or the whole table
- [ ] `:My opt list` -- List all editor-option config keys
- [ ] `:My diff` -- Build 'diffopt' from a named profile
- [ ] `:My opt set` -- Set an editor-option config value (bang toggles a boolean)
- [ ] `:My status` -- Which subsystems are loaded, key counts, current diffopt
- [ ] `:My hl debug` -- Report what each breadcrumb context provider returns here
- [ ] `:My hl why` -- Explain whether the current buffer is skipped, and by which rule
- [ ] `:My hl show` -- Show a highlight config value, or the whole table
- [ ] `:My hl set` -- Set a highlight config value (bang toggles a boolean)

### :MyPlugins

- [ ] `:MyPlugins unlisted` -- Show *.nvim checkouts in dir/$REPOS_DIR that plugins.personal does not list yet (read-only; the 'new plugin not wired up' check)
- [ ] `:MyPlugins open` -- Picker over the files of one folder of an area (tasks|roadmap|backlog|handover|notes|all, default all) through pickers.nvim; --action=grep|smart searches content, --list or --to= delivers the file list
- [ ] `:MyPlugins jumpTo` -- Open plugins/personal/specs/* at the install spec of the given plugin
- [ ] `:MyPlugins pull` -- git pull --ff-only on every present listed plugin (or just --only=<name>)
- [ ] `:MyPlugins update` -- Fetch + fast-forward pull every present listed plugin (or just --only=<name>) — brings this machine level with another machine's pushed commits
- [ ] `:MyPlugins list` -- Render every plugin in plugins.personal.core.list, and whether it's present in dir/$REPOS_DIR, into a scratch buffer (yank/:sort/search it; no git)
- [ ] `:MyPlugins dashboard` -- Open gitsuite.nvim's git-status dashboard (:Git dashboard) for dir/$REPOS_DIR; --fetch runs :MyPlugins fetch first, --fetch-this scopes that fetch to the plugin the current buffer/cwd belongs to
- [ ] `:MyPlugins clone` -- Clone every listed plugin not yet present (or just --only=<name>) into dir/$REPOS_DIR; --dry-run previews without cloning
- [ ] `:MyPlugins task preview` -- Show the file of a task (an open one, else its finished copy in Backlog/) rendered in the browser through mdview.nvim; the file is opened as it is, nothing is written to the vault
- [ ] `:MyPlugins tasks` -- List the open tasks of one area (default: all) as a Markdown table in a scratch buffer; filter with --status= --prio= --effort=S,M|<=M --kind= --category=bug|security|performance|docs|ruleset|ux|bindings|refactor|tests|ci --severity=low|medium|high|critical --tag= --stale=<days>|refs (refs: a file named in refs: changed since updated) --blocked, order with --sort=default|prio-effort|severity|frecency, deliver with --to=buffer|clipboard|qf|file:<path>|mdview (a browser preview through mdview.nvim, Markdown only) and --format=md|csv
- [ ] `:MyPlugins task template` -- Copy the task file template to the + register (--to=buffer|file:<path> for the other targets; --with-plan adds the optional ## Plan section)
- [ ] `:MyPlugins task folderize` -- Turn a plain task file into a folder task (<slug>/<slug>.md) so assets can be attached
- [ ] `:MyPlugins task done` -- Finish a task after confirmation: status done, moved to Backlog/FEATURES|TASKS with a date prefix, Backlog README and index updated; --yes skips the question
- [ ] `:MyPlugins task attach` -- Copy a file (screenshot, log) into the task's assets/ folder, turning a plain task into a folder task, and put the Markdown link in the + register; name=<file name> renames the copy
- [ ] `:MyPlugins tasks index` -- (Re)write ROADMAP/TASKS.md of one area (default: every area); --check writes nothing and reports rule findings and stale indexes
- [ ] `:MyPlugins task new` -- Without arguments: a Markdown form (tick kind, prio, effort, category, severity, status; <C-s> submits) and the question whether to attach assets. With an area: create ROADMAP/tasks/<slug>.md in it and open it; the words after the area are the title (asked for when missing); --folder makes a folder task that can hold assets
- [ ] `:MyPlugins task estimate` -- Sums of effort and value of an area (default: all) or of one task and everything before it, with what is missing; --walk goes through the tasks without effort or value and asks for them one by one
- [ ] `:MyPlugins task plan` -- The plan of the open tasks of an area (default: all) or of one task and everything before it (--for=<id>): what is ready now, decisions by leverage, stages, critical path, an estimate line; filters like list; --ready shows only what can be started
- [ ] `:MyPlugins task quickwins` -- The quick wins (value 4+ and effort S or less by default, both written on the task), best return first, plus the small tasks that miss a value; --report=<file> writes the Markdown
- [ ] `:MyPlugins task next` -- What to start next: the best ready task with the reason, and a dialog to jump into it; --actor=cdx asks for the AI queue instead of yours
- [ ] `:MyPlugins task open` -- Open the file of a task (an open one, else its finished copy in Backlog/); a part of the name is enough when it points at one task, else the candidates are offered
- [ ] `:MyPlugins task planfile` -- Create a plan file ROADMAP/plans/<slug>.md in an area (the words after the area are the title): the undertaking that tasks join with plan=<id> phase=<word>; --areas=a,b lists the areas whose tasks belong, --phases=a,b,c names the stages in order, --gate=hard forbids starting a stage before the earlier ones are finished, --target=<task> is the task that means done

### :MyPluginsDashboard

- [ ] `:MyPluginsDashboard` -- Shorthand for :MyPlugins dashboard [dir] — opens gitsuite.nvim's git-status dashboard (:Git dashboard)

### :NeotestActions

- [ ] `:NeotestActions` -- Open Neotest actions picker

### :NeotestDebugNearest

- [ ] `:NeotestDebugNearest` -- Debug nearest test using DAP

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

### :NotesFileGrep

- [ ] `:NotesFileGrep` -- [pickers coll] :NotesFileGrep [query] → :Pickers notes filegrep

### :NotesFiles

- [ ] `:NotesFiles` -- [pickers coll] :NotesFiles → :Pickers notes files

### :NotesGrep

- [ ] `:NotesGrep` -- [pickers coll] :NotesGrep → :Pickers notes grep

### :NotesLuaFileGrep

- [ ] `:NotesLuaFileGrep` -- [pickers coll] :NotesLuaFileGrep [query] → :Pickers notes_lua filegrep

### :NotesLuaFiles

- [ ] `:NotesLuaFiles` -- [pickers coll] :NotesLuaFiles → :Pickers notes_lua files

### :NotesLuaGrep

- [ ] `:NotesLuaGrep` -- [pickers coll] :NotesLuaGrep → :Pickers notes_lua grep

### :NotesLuaSmart

- [ ] `:NotesLuaSmart` -- [pickers coll] :NotesLuaSmart → :Pickers notes_lua smart

### :NotesNvimFileGrep

- [ ] `:NotesNvimFileGrep` -- [pickers coll] :NotesNvimFileGrep [query] → :Pickers notes_nvim filegrep

### :NotesNvimFiles

- [ ] `:NotesNvimFiles` -- [pickers coll] :NotesNvimFiles → :Pickers notes_nvim files

### :NotesNvimGrep

- [ ] `:NotesNvimGrep` -- [pickers coll] :NotesNvimGrep → :Pickers notes_nvim grep

### :NotesNvimSmart

- [ ] `:NotesNvimSmart` -- [pickers coll] :NotesNvimSmart → :Pickers notes_nvim smart

### :NotesSmart

- [ ] `:NotesSmart` -- [pickers coll] :NotesSmart → :Pickers notes smart

### :Open

- [ ] `:Open viewer` -- List links in a scope, then open / export them
- [ ] `:Open` -- Open path/URL with the specified handler
- [ ] `:Open` -- :Open — open path/URL with the specified handler

### :OpenInBrowser

- [ ] `:OpenInBrowser` -- [buffer-ctx] Open current buffer with the OS-registered application (browser)

### :PdfPort

- [ ] `:PdfPort float` -- Show PDF text in float window  :PdfPort float [path] [pages=1-3,5]
- [ ] `:PdfPort merge` -- Merge two or more PDFs  :PdfPort merge <output.pdf> <a.pdf> <b.pdf> [...]
- [ ] `:PdfPort terminal` -- Render PDF as terminal image  :PdfPort terminal [path] [pages=1-3,5]
- [ ] `:PdfPort text` -- Extract PDF text to buffer
- [ ] `:PdfPort` -- Open PDF (interactive mode picker)
- [ ] `:PdfPort health` -- Run health check
- [ ] `:PdfPort system` -- Open PDF with system application
- [ ] `:PdfPort create` -- Create a PDF from a source file (path arg, cfile, or current buffer)
- [ ] `:PdfPort producers` -- List all registered creation producers with live availability
- [ ] `:PdfPort backends` -- List all registered backends with live availability

### :Pickers

- [ ] `:Pickers system` -- Scope: system
- [ ] `:Pickers repos` -- Scope: repos
- [ ] `:Pickers` -- [pickers.nvim] :Pickers [scope] [nav|action] [action]
- [ ] `:Pickers config` -- Scope: config
- [ ] `:Pickers drives` -- Scope: drives
- [ ] `:Pickers folder` -- Scope: folder
- [ ] `:Pickers cwd` -- Scope: cwd
- [ ] `:Pickers dir` -- Directory navigation (depth / alias / explicit path)
- [ ] `:Pickers notes_nvim` -- User-defined collection: notes_nvim
- [ ] `:Pickers tabs` -- Open a tab group: its first target, then tab_next/tab_prev cycle the rest (pickers.tabs)
- [ ] `:Pickers wkdbooks_lua` -- User-defined collection: wkdbooks_lua
- [ ] `:Pickers wkdbooks` -- User-defined collection: wkdbooks
- [ ] `:Pickers builtin` -- Native picker (git/lsp/search/…) — see docs/builtins.md
- [ ] `:Pickers plugins_book` -- User-defined collection: plugins_book
- [ ] `:Pickers spickzettel` -- User-defined collection: spickzettel
- [ ] `:Pickers wkdbooks_nvim` -- User-defined collection: wkdbooks_nvim
- [ ] `:Pickers notes_lua` -- User-defined collection: notes_lua
- [ ] `:Pickers checklists` -- User-defined collection: checklists
- [ ] `:Pickers notes` -- User-defined collection: notes

### :PickersRepeat

- [ ] `:PickersRepeat` -- [pickers] :PickersRepeat — reopen the last :Pickers action

### :PickersResume

- [ ] `:PickersResume` -- [pickers] :PickersResume — reopen the last picker with its last query

### :PickersScopes

- [ ] `:PickersScopes` -- [pickers] :PickersScopes — list every resolvable scope (built-ins + collections)

### :PluginsBookFileGrep

- [ ] `:PluginsBookFileGrep` -- [pickers coll] :PluginsBookFileGrep [query] → :Pickers plugins_book filegrep

### :PluginsBookFiles

- [ ] `:PluginsBookFiles` -- [pickers coll] :PluginsBookFiles → :Pickers plugins_book files

### :PluginsBookGrep

- [ ] `:PluginsBookGrep` -- [pickers coll] :PluginsBookGrep → :Pickers plugins_book grep

### :PluginsBookSmart

- [ ] `:PluginsBookSmart` -- [pickers coll] :PluginsBookSmart → :Pickers plugins_book smart

### :PowershellProfile

- [ ] `:PowershellProfile` -- Open the current PowerShell profile

### :PrettierFormat

- [ ] `:PrettierFormat` -- Run prettier --write on current file (requires prettier config in project root)

### :RA

- [ ] `:RA usage start` -- Start counting keymap/command presses (opt-in, local only)
- [ ] `:RA startup profile` -- Start Neovim N times (default 5) and report the averaged per-file startup cost
- [ ] `:RA import` -- Import a curl command (visual selection, or the clipboard) into a new request buffer
- [ ] `:RA env` -- Show/select the environment {{vars}} resolve against
- [ ] `:RA export` -- Export the request under the cursor as a curl command, yanked to the unnamed register
- [ ] `:RA provenance` -- Who wrapped a function right now — e.g. :RA provenance vim.notify
- [ ] `:RA inspect` -- Walk a live package.loaded table -- functions, tables, metatables, what's shadowed
- [ ] `:RA history clear` -- Clear this project's request history
- [ ] `:RA cancel` -- Cancel the in-flight request, if any
- [ ] `:RA startup probe` -- Print the --cmd line that measures a startup from the very beginning
- [ ] `:RA history` -- Browse this project's request history and reopen one
- [ ] `:RA send` -- Send the current buffer as an HTTP request
- [ ] `:RA yank` -- Yank just the last response's body to the unnamed register
- [ ] `:RA usage` -- Report which of your own keymaps/commands you actually press
- [ ] `:RA request` -- Open a new HTTP request buffer
- [ ] `:RA startup start` -- Start watching for main-loop stalls (reports after 12s)
- [ ] `:RA startup watch` -- Like `startup start`, but keeps measuring until `startup report`
- [ ] `:RA loaded snapshot` -- Persist a loaded-vs-declared snapshot for <prefix>
- [ ] `:RA loaded snapshots` -- List saved loaded snapshots for <prefix>

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

### :Recommender

- [ ] `:Recommender` -- (no description)

### :Replace

- [ ] `:Replace` -- (no description)

### :ReplaceBatch

- [ ] `:ReplaceBatch` -- Usage: :ReplaceBatch[!] {source} [scope] [--flags]   (source: file path, clipboard/+, unnamed/", or qf/quickfix)

### :ReplaceEscape

- [ ] `:ReplaceEscape` -- Escape text for use as a Vim regex pattern

### :ReplaceFNames

- [ ] `:ReplaceFNames` -- Usage: :ReplaceFNames[!] {old} {new} [scope] [--dry]

### :ReplaceHistory

- [ ] `:ReplaceHistory` -- Re-run a recent :Replace from history: :ReplaceHistory

### :ReplaceRoot

- [ ] `:ReplaceRoot` -- Replace with an auto-detected project root as scope: :ReplaceRoot[!] {old} {new} [--flags]

### :ReplaceTest

- [ ] `:ReplaceTest` -- Open a small live regex pattern-test float: :ReplaceTest [pattern] [sample]

### :ReplaceUndo

- [ ] `:ReplaceUndo` -- Restore files from a replacer checkpoint: :ReplaceUndo [id]

### :Replacer

- [ ] `:Replacer` -- (no description)

### :RepoFiles

- [ ] `:RepoFiles` -- [pickers] :RepoFiles [repo] — pick repo (or jump to [repo]), then find files

### :RepoGrep

- [ ] `:RepoGrep` -- [pickers] :RepoGrep [repo] — pick repo (or jump to [repo]), then live grep

### :Reposcope

- [ ] `:Reposcope prompt` -- Reload visible prompt fields (e.g. :Reposcope prompt prefix keywords)
- [ ] `:Reposcope session` -- Manage the persisted search session (:Reposcope session save|restore|clear)
- [ ] `:Reposcope queries` -- Show your most-frequent search queries (:Reposcope queries list|clear)
- [ ] `:Reposcope filter-clear` -- Clear the active filter and show the full list again
- [ ] `:Reposcope sort` -- Open an interactive menu to sort the repository list
- [ ] `:Reposcope skipped-readmes` -- Print the number of debounced (skipped) README fetches
- [ ] `:Reposcope print-dev` -- Print whether developer mode is currently active
- [ ] `:Reposcope stats` -- Display collected request stats and metrics
- [ ] `:Reposcope providers` -- List available providers and show which one is active
- [ ] `:Reposcope messages` -- Show reposcope's message history in a buffer (yankable); `clear` forgets it
- [ ] `:Reposcope toggle-dev` -- Toggle developer mode (debug logging, internal info)
- [ ] `:Reposcope favorites` -- List or clear favorited repositories (:Reposcope favorites list|clear)
- [ ] `:Reposcope start` -- Open the Reposcope UI
- [ ] `:Reposcope close` -- Close all Reposcope windows and buffers
- [ ] `:Reposcope filter-prompt` -- Open a floating prompt to filter repositories interactively

### :RevealInFm

- [ ] `:RevealInFm` -- [buffer-ctx] Reveal current buffer in the system file manager

### :Rules

- [ ] `:Rules messages` -- Open this plugin's notify history (toast + :messages log)
- [ ] `:Rules list` -- List the rules in the quickfix list, each at its source line; --family= and --severity= narrow it, --format=json prints the document of the machine contract
- [ ] `:Rules set` -- Change parts of a rule's file (key=value, a value may hold spaces): every line it was not asked to change stays byte for byte; an open buffer of the file is reloaded, one with unsaved changes is reported
- [ ] `:Rules catalog` -- Build the reading documents of a one-file-per-rule ruleset from its layouts; --check for CI
- [ ] `:Rules reinstate` -- Bring a retired rule back from _retired/. Where it stood is not recorded: give --after=<ID>, --before=<ID> or --section=<heading> --layout=<file>, or it stands in no layout. Asks first (--yes skips the question)
- [ ] `:Rules move` -- Move a rule's {{rule ID}} line within its layout or into another (--to=<file>#<section>, or --after=<ID> / --before=<ID>); the rule's own file is not touched
- [ ] `:Rules waive` -- Accept the findings of a rule in this project: a waiver in .rules-waivers.json with a reason (reason=, required), a last day (expires=) and places (paths=, comma separated; a blank in a path is typed as it is). The project is that of this buffer or the working directory (--project= names it)
- [ ] `:Rules stats` -- Structural overview of every loaded rule: per-family totals, automated-vs-manual, severity -- no check run
- [ ] `:Rules gate` -- Run a configured gate (setup({ gates = {...} })), --diff=<git-ref> to scope to that diff
- [ ] `:Rules show` -- Jump to one rule's source location by id, e.g. :Rules show DEP-06
- [ ] `:Rules retire` -- Move a rule's file to _retired/ and out of every layout; its id stays taken. Asks first (--yes skips the question), --by=<ID> names the rule that takes its place
- [ ] `:Rules check` -- Sweep one rule family (--family=PREFIX) across PATH (default: cwd), --format=json for machine-readable output
- [ ] `:Rules new` -- Make a rule in the next free id of the family. The words after the family are the title; with a title and severity= the rule is made and opened, with less the Markdown form opens (family, title, severity, place, text; <C-s> checks it, shows what would be made and asks). A family no rule has yet is asked about first (--yes skips the question)
- [ ] `:Rules renew` -- Give a waiver a new last day (expires=YYYY-MM-DD, or --no-expiry for none) and, with reason=, a new reason; its paths stay. The way on for a waiver that expired

### :RulesVault

- [ ] `:RulesVault` -- The rules vault: open, copy, link, search and show its rulesets, rules and families; create a vault
- [ ] `:RulesVault link` -- Insert a Markdown link to a rule, a family or a part at the cursor, relative to the current file
- [ ] `:RulesVault clipboard` -- Copy the path of a rule file, a family folder or a part of a ruleset to the + register
- [ ] `:RulesVault find` -- Pick a file by name in the ruleset of a rule id, in a family or in a part, through pickers.nvim
- [ ] `:RulesVault grep` -- Search the content of the files of a ruleset, a family or a part through pickers.nvim
- [ ] `:RulesVault tree` -- Show a ruleset as a tree: family, then rules, with counts per family and a marker on the retired ones
- [ ] `:RulesVault open` -- Open the rule file of an id, the folder of a family, or a part of a ruleset (rules, layouts, catalogs, all)
- [ ] `:RulesVault cdx` -- Copy a prompt for an agent session that names the rule, family or part to the + register

### :Sandbox

- [ ] `:Sandbox container unpause` -- Resume a paused container's processes
- [ ] `:Sandbox container rename` -- Rename a container
- [ ] `:Sandbox container pause` -- Pause a running container's processes
- [ ] `:Sandbox container stats` -- Show a one-shot resource usage snapshot of a container
- [ ] `:Sandbox container top` -- List the processes running inside a container
- [ ] `:Sandbox container inspect` -- Inspect detailed information about a container
- [ ] `:Sandbox container run` -- Interactively create and start a new container (prompts for image, name, ports, volumes, env)
- [ ] `:Sandbox image pull` -- Pull an image (--buffer: stream to a terminal buffer)
- [ ] `:Sandbox image push` -- Push an image to a remote registry
- [ ] `:Sandbox container cp` -- Copy a file/directory between the host and a container (either side may be <id>:<path>)
- [ ] `:Sandbox image list` -- List all local images
- [ ] `:Sandbox compose logs` -- Show logs for the compose project detected in cwd
- [ ] `:Sandbox container exec-once` -- Run a one-off command inside a container (non-interactive)  [workdir=<path>]
- [ ] `:Sandbox wsl set-version` -- Toggle a distro between WSL1/WSL2
- [ ] `:Sandbox wsl set-default` -- Set a distro as the WSL default
- [ ] `:Sandbox wsl exec` -- Open a shell or run a command inside a WSL distro
- [ ] `:Sandbox wsl export` -- Export a distro to a tarball on disk
- [ ] `:Sandbox network create` -- Create a new named network
- [ ] `:Sandbox wsl import` -- Import a distro from a tarball
- [ ] `:Sandbox container list` -- List all containers
- [ ] `:Sandbox image tag` -- Tag a local image with a new repository:tag
- [ ] `:Sandbox wsl start` -- Start a WSL distro
- [ ] `:Sandbox container exec` -- Open a shell session inside a running container  [workdir=<path>]
- [ ] `:Sandbox container logs` -- Show logs of a container
- [ ] `:Sandbox image build` -- Build an image from a Dockerfile/Containerfile (streams to a terminal buffer)
- [ ] `:Sandbox image load` -- Load (import) an image from a tarball on disk
- [ ] `:Sandbox network connect` -- Connect a container to a network
- [ ] `:Sandbox network inspect` -- Inspect detailed information about a network
- [ ] `:Sandbox network disconnect` -- Disconnect a container from a network
- [ ] `:Sandbox compose up` -- Start the compose project detected in cwd (detached)
- [ ] `:Sandbox volume list` -- List all local volumes
- [ ] `:Sandbox network list` -- List all local networks
- [ ] `:Sandbox volume create` -- Create a new named volume
- [ ] `:Sandbox volume inspect` -- Inspect detailed information about a volume
- [ ] `:Sandbox image save` -- Save (export) an image to a tarball on disk
- [ ] `:Sandbox compose services` -- List services declared in the compose file (static, no engine call)
- [ ] `:Sandbox wsl list` -- List all registered WSL distributions
- [ ] `:Sandbox devcontainer lazygit` -- Open gitsuite.nvim's lazygit for the devcontainer's workspace (optional)
- [ ] `:Sandbox devcontainer attach` -- Open a shell in the running devcontainer for the project in cwd
- [ ] `:Sandbox image history` -- Show an image's layer history
- [ ] `:Sandbox image inspect` -- Inspect detailed information about an image
- [ ] `:Sandbox compose ps` -- List services in the compose project detected in cwd
- [ ] `:Sandbox devcontainer build` -- Build/pull a .devcontainer/devcontainer.json's image and start a container from it
- [ ] `:Sandbox registry logout` -- Log out of a registry
- [ ] `:Sandbox engine set` -- Switch the active engine for this session
- [ ] `:Sandbox docs generate` -- Regenerate docs/GENERATED_COMMANDS.md from the live route table, so docs/BINDINGS.md (hand-maintained) can be diffed against it to catch drift
- [ ] `:Sandbox engine get` -- Show the currently active engine and why
- [ ] `:Sandbox registry login` -- Log in to a registry (prompts for username/password)

### :Sbx

- [ ] `:Sbx container list` -- List all containers
- [ ] `:Sbx container exec` -- Open a shell session inside a running container  [workdir=<path>]
- [ ] `:Sbx compose services` -- List services declared in the compose file (static, no engine call)
- [ ] `:Sbx compose ps` -- List services in the compose project detected in cwd
- [ ] `:Sbx compose logs` -- Show logs for the compose project detected in cwd
- [ ] `:Sbx engine get` -- Show the currently active engine and why
- [ ] `:Sbx engine set` -- Switch the active engine for this session
- [ ] `:Sbx compose up` -- Start the compose project detected in cwd (detached)
- [ ] `:Sbx container logs` -- Show logs of a container
- [ ] `:Sbx network disconnect` -- Disconnect a container from a network
- [ ] `:Sbx network connect` -- Connect a container to a network
- [ ] `:Sbx network create` -- Create a new named network
- [ ] `:Sbx registry login` -- Log in to a registry (prompts for username/password)
- [ ] `:Sbx docs generate` -- Regenerate docs/GENERATED_COMMANDS.md from the live route table, so docs/BINDINGS.md (hand-maintained) can be diffed against it to catch drift
- [ ] `:Sbx wsl set-version` -- Toggle a distro between WSL1/WSL2
- [ ] `:Sbx wsl set-default` -- Set a distro as the WSL default
- [ ] `:Sbx wsl export` -- Export a distro to a tarball on disk
- [ ] `:Sbx wsl import` -- Import a distro from a tarball
- [ ] `:Sbx registry logout` -- Log out of a registry
- [ ] `:Sbx wsl exec` -- Open a shell or run a command inside a WSL distro
- [ ] `:Sbx wsl start` -- Start a WSL distro
- [ ] `:Sbx devcontainer build` -- Build/pull a .devcontainer/devcontainer.json's image and start a container from it
- [ ] `:Sbx devcontainer attach` -- Open a shell in the running devcontainer for the project in cwd
- [ ] `:Sbx wsl list` -- List all registered WSL distributions
- [ ] `:Sbx devcontainer lazygit` -- Open gitsuite.nvim's lazygit for the devcontainer's workspace (optional)
- [ ] `:Sbx network list` -- List all local networks
- [ ] `:Sbx network inspect` -- Inspect detailed information about a network
- [ ] `:Sbx volume inspect` -- Inspect detailed information about a volume
- [ ] `:Sbx container cp` -- Copy a file/directory between the host and a container (either side may be <id>:<path>)
- [ ] `:Sbx container top` -- List the processes running inside a container
- [ ] `:Sbx container stats` -- Show a one-shot resource usage snapshot of a container
- [ ] `:Sbx container run` -- Interactively create and start a new container (prompts for image, name, ports, volumes, env)
- [ ] `:Sbx container inspect` -- Inspect detailed information about a container
- [ ] `:Sbx image list` -- List all local images
- [ ] `:Sbx container rename` -- Rename a container
- [ ] `:Sbx container pause` -- Pause a running container's processes
- [ ] `:Sbx container exec-once` -- Run a one-off command inside a container (non-interactive)  [workdir=<path>]
- [ ] `:Sbx container unpause` -- Resume a paused container's processes
- [ ] `:Sbx image pull` -- Pull an image (--buffer: stream to a terminal buffer)
- [ ] `:Sbx image push` -- Push an image to a remote registry
- [ ] `:Sbx image inspect` -- Inspect detailed information about an image
- [ ] `:Sbx volume list` -- List all local volumes
- [ ] `:Sbx volume create` -- Create a new named volume
- [ ] `:Sbx image history` -- Show an image's layer history
- [ ] `:Sbx image load` -- Load (import) an image from a tarball on disk
- [ ] `:Sbx image tag` -- Tag a local image with a new repository:tag
- [ ] `:Sbx image build` -- Build an image from a Dockerfile/Containerfile (streams to a terminal buffer)
- [ ] `:Sbx image save` -- Save (export) an image to a tarball on disk

### :Session

- [ ] `:Session marks select` -- Jump to mark <index>
- [ ] `:Session marks preview` -- Read-only preview of mark <index> (q closes)
- [ ] `:Session marks import-harpoon` -- Take over a harpoon v2 list (bucket defaults to stdpath('config'))
- [ ] `:Session marks list` -- Print the list
- [ ] `:Session marks debug` -- Dump the list, its scope and its store into a scratch buffer
- [ ] `:Session load` -- Load session [name] (omit for the configured default_name)
- [ ] `:Session save-timestamp` -- Save session with timestamp suffix
- [ ] `:Session load-layout` -- Restore a window-split layout: :Session load-layout <name>
- [ ] `:Session marks` -- Open the mark list in the configured picker
- [ ] `:Session marks menu` -- Open the mark list: auto|edit|kit|snacks|telescope|fzf
- [ ] `:Session load-tab` -- Load a tab session into a new tab: :Session load-tab <name>
- [ ] `:Session toggle-track` -- Toggle git skip-worktree on a session file
- [ ] `:Session save-tab` -- Save only the current tab's window layout [name]
- [ ] `:Session chip-toggle` -- Show/hide the corner chip on demand
- [ ] `:Session marks add` -- Add a file to the list (default: current buffer, appended)
- [ ] `:Session rename` -- Rename a session: :Session rename <old> <new>
- [ ] `:Session stale` -- List saved sessions whose recorded branch no longer exists
- [ ] `:Session marks defaults sync` -- Append every missing default and pin; the rest stays
- [ ] `:Session save-layout` -- Save the current window-split layout: :Session save-layout <name>
- [ ] `:Session list` -- List all saved sessions
- [ ] `:Session current` -- Print the active session name

### :SessionLoad

- [ ] `:SessionLoad` -- Open the session picker with preview (Snacks/Telescope)

### :Spellcheck

- [ ] `:Spellcheck` -- Spell/grammar review

### :SpickzettelFileGrep

- [ ] `:SpickzettelFileGrep` -- [pickers coll] :SpickzettelFileGrep [query] → :Pickers spickzettel filegrep

### :SpickzettelFiles

- [ ] `:SpickzettelFiles` -- [pickers coll] :SpickzettelFiles → :Pickers spickzettel files

### :SpickzettelGrep

- [ ] `:SpickzettelGrep` -- [pickers coll] :SpickzettelGrep → :Pickers spickzettel grep

### :SpickzettelSmart

- [ ] `:SpickzettelSmart` -- [pickers coll] :SpickzettelSmart → :Pickers spickzettel smart

### :Spotlight

- [ ] `:Spotlight qf` -- Matching lines to the quickfix list (all spotlights, or just TEXT's)
- [ ] `:Spotlight next` -- Jump to the next spotlight occurrence  (! ignores nav.scope)
- [ ] `:Spotlight sets switch` -- Clear the active spotlights and restore a saved set
- [ ] `:Spotlight prev` -- Jump to the previous spotlight occurrence  (! ignores nav.scope)
- [ ] `:Spotlight map clear` -- Clear the sign-column occurrence map in the current buffer
- [ ] `:Spotlight line` -- Toggle whole-line rendering for a spotlight (TEXT, or the cursor token)
- [ ] `:Spotlight refresh` -- Re-apply every spotlight to every window (and redefine the palette)
- [ ] `:Spotlight persist` -- Per-file persistence: on / off / default (clear override) / status
- [ ] `:Spotlight qf all` -- Matching lines across every loaded buffer to the quickfix list
- [ ] `:Spotlight sets list` -- List every saved set and how many spotlights it holds
- [ ] `:Spotlight winopt` -- Per-window opt-out: on / off / toggle (default) / status
- [ ] `:Spotlight yank` -- Yank matching lines to the unnamed register (all spotlights, or just TEXT's)
- [ ] `:Spotlight list` -- Open the spotlight list (swatch + pattern + match count)  [filter]
- [ ] `:Spotlight lock` -- Toggle whether a spotlight keeps its palette slot permanently (TEXT, or the cursor token)
- [ ] `:Spotlight map` -- Mark every matching line in the sign column (all spotlights, or just TEXT's)
- [ ] `:Spotlight add` -- Add a spotlight for the literal TEXT
- [ ] `:Spotlight` -- Spotlight: persistent multi-token highlighting
- [ ] `:Spotlight toggle` -- Toggle a spotlight (cursor token, range selection, or explicit TEXT)
- [ ] `:Spotlight here` -- Toggle a spotlight for only this occurrence (cursor token or range selection)

### :StartupCheck

- [ ] `:StartupCheck` -- Startup: report policy violations only

### :StartupReport

- [ ] `:StartupReport` -- Startup: phase timeline (themed float)

### :Surround

- [ ] `:Surround` -- (no description)

### :SystemInfo

- [ ] `:SystemInfo` -- Show system information (float + clipboard)

### :Tasks

- [ ] `:Tasks folderize` -- Turn a plain task file into a folder task (<slug>/<slug>.md) so assets can be attached
- [ ] `:Tasks index` -- (Re)write ROADMAP/TASKS.md of one area (default: every area); --check writes nothing and reports rule findings and stale indexes
- [ ] `:Tasks next` -- What to start next: the best ready task with the reason, and a dialog to jump into it; --actor=cdx asks for the AI queue instead of yours
- [ ] `:Tasks estimate` -- Sums of effort and value of an area (default: all) or of one task and everything before it, with what is missing; --walk goes through the tasks without effort or value and asks for them one by one
- [ ] `:Tasks new` -- Without arguments: a Markdown form (tick kind, prio, effort, category, severity, status; <C-s> submits) and the question whether to attach assets. With an area: create ROADMAP/tasks/<slug>.md in it and open it; the words after the area are the title (asked for when missing); --folder makes a folder task that can hold assets
- [ ] `:Tasks done` -- Finish a task after confirmation: status done, moved to Backlog/FEATURES|TASKS with a date prefix, Backlog README and index updated; --yes skips the question
- [ ] `:Tasks plan` -- The plan of the open tasks of an area (default: all) or of one task and everything before it (--for=<id>): what is ready now, decisions by leverage, stages, critical path, an estimate line; filters like list; --ready shows only what can be started
- [ ] `:Tasks template` -- Copy the task file template to the + register (--to=buffer|file:<path> for the other targets; --with-plan adds the optional ## Plan section)
- [ ] `:Tasks attach` -- Copy a file (screenshot, log) into the task's assets/ folder, turning a plain task into a folder task, and put the Markdown link in the + register; name=<file name> renames the copy
- [ ] `:Tasks planfile` -- Create a plan file ROADMAP/plans/<slug>.md in an area (the words after the area are the title): the undertaking that tasks join with plan=<id> phase=<word>; --areas=a,b lists the areas whose tasks belong, --phases=a,b,c names the stages in order, --gate=hard forbids starting a stage before the earlier ones are finished, --target=<task> is the task that means done
- [ ] `:Tasks quickwins` -- The quick wins (value 4+ and effort S or less by default, both written on the task), best return first, plus the small tasks that miss a value; --report=<file> writes the Markdown
- [ ] `:Tasks open` -- Open the file of a task (an open one, else its finished copy in Backlog/); a part of the name is enough when it points at one task, else the candidates are offered
- [ ] `:Tasks preview` -- Show the file of a task (an open one, else its finished copy in Backlog/) rendered in the browser through mdview.nvim; the file is opened as it is, nothing is written to the vault
- [ ] `:Tasks folder` -- Picker over the files of one folder of an area (tasks|roadmap|backlog|handover|notes|all, default all) through pickers.nvim; --action=grep|smart searches content, --list or --to= delivers the file list
- [ ] `:Tasks list` -- List the open tasks of one area (default: all) as a Markdown table in a scratch buffer; filter with --status= --prio= --effort=S,M|<=M --kind= --category=bug|security|performance|docs|ruleset|ux|bindings|refactor|tests|ci --severity=low|medium|high|critical --tag= --stale=<days>|refs (refs: a file named in refs: changed since updated) --blocked, order with --sort=default|prio-effort|severity|frecency, deliver with --to=buffer|clipboard|qf|file:<path>|mdview (a browser preview through mdview.nvim, Markdown only) and --format=md|csv

### :TasksVault

- [ ] `:TasksVault clipboard` -- Copy the path of an area's Backlog folder (or features|tasks|roadmap|all) to the + register
- [ ] `:TasksVault paste` -- Insert the path of an area's Backlog folder (or features|tasks|roadmap|all) at the cursor
- [ ] `:TasksVault open` -- Open the index of an area's Backlog (or features|tasks|roadmap|all) in a buffer, else its folder in the explorer
- [ ] `:TasksVault` -- The task vault: open, copy, paste and search the Backlog of an area, make notes, create a vault
- [ ] `:TasksVault tree` -- Show the folder of an area's Backlog (or features|tasks|roadmap|all) in the file explorer
- [ ] `:TasksVault link` -- Insert a Markdown link to the Backlog of an area at the cursor, relative to the current file
- [ ] `:TasksVault find` -- Pick a file by name in the folder of an area's Backlog (or features|tasks|roadmap|all) through pickers.nvim
- [ ] `:TasksVault cdx` -- Copy a prompt for Claude Code that names the folder of an area's Backlog to the + register
- [ ] `:TasksVault status` -- Show the vault in use, its number of areas and the area of this buffer
- [ ] `:TasksVault create` -- Create a vault folder (with the areas named after it): lists what happens and the setup() step that is left to you, then uses it for this session
- [ ] `:TasksVault new` -- Create a dated note in Backlog/FEATURES or Backlog/TASKS of an area, add its README row and open it; the words after the kind are the title
- [ ] `:TasksVault grep` -- Search the content of the files in the folder of an area's Backlog through pickers.nvim

### :Terminal

- [ ] `:Terminal hide` -- Hide a terminal's window; its job keeps running
- [ ] `:Terminal open` -- Show and focus a terminal, creating it when needed
- [ ] `:Terminal` -- Named terminals of this project
- [ ] `:Terminal toggle` -- Toggle a terminal (the name "3" is the toggle key with count 3)
- [ ] `:Terminal adopt` -- Show a tmux/WezTerm terminal's screen in a read-only buffer
- [ ] `:Terminal cheat` -- Show the cheatsheet of the shell (]] [[ pages, / searches, <CR> types the line)
- [ ] `:Terminal send file` -- Send the file to a terminal (typed only; --exec presses Enter)
- [ ] `:Terminal run` -- Run a command (typed as a line; --direct starts it as the job itself); put -- before a command with dashed words
- [ ] `:Terminal list` -- Pick one of this project's terminals: open, close or send a line
- [ ] `:Terminal send selection` -- Send the selection to a terminal (typed only; --exec presses Enter)
- [ ] `:Terminal send line` -- Send the line to a terminal (typed only; --exec presses Enter)

### :Testing

- [ ] `:Testing doctor` -- Show the project's resolved configuration and the dependency report
- [ ] `:Testing cache stats` -- Show the size and age of the result cache of the project
- [ ] `:Testing` -- testing.nvim: run, file, last, list, init, migrate, conformance, surface, budget, cache, health, config, doctor
- [ ] `:Testing health` -- Run :checkhealth testing
- [ ] `:Testing config` -- Show the effective configuration
- [ ] `:Testing surface` -- List the plugin's keymaps, commands and autocmds and how much the specs exercised
- [ ] `:Testing budget` -- Measure the performance budgets and compare them with the baseline
- [ ] `:Testing conformance` -- Run the conformance checks K1..K15 on the project (report only unless --gate)
- [ ] `:Testing terminal` -- Repeat the last run (else run the project) in a terminal.nvim terminal
- [ ] `:Testing list` -- List the spec files that would run, run nothing
- [ ] `:Testing last` -- Repeat the last run
- [ ] `:Testing run` -- Run the spec files of the project (headless child nvim)
- [ ] `:Testing file` -- Run the spec file of the current buffer

### :Theme

- [ ] `:Theme` -- Show the current colorscheme, or switch to one

### :ToggleLintFormatOnSave

- [ ] `:ToggleLintFormatOnSave` -- Toggle automatic lint+format on save

### :Translate

- [ ] `:Translate` -- Translate (popup by default; ! = interactive window)

### :TranslateReplace

- [ ] `:TranslateReplace` -- Translate and replace in place

### :Tricentis

- [ ] `:Tricentis commands` -- Pick a CLI command from anywhere in the work repo and copy it (topic: all|enginelab|mobile|api|excel|engines|tosca|workflow|notes|terminologie|cases|todo)
- [ ] `:Tricentis` -- Tools that reach across the whole WKDBook-Tricentis work repo, not case-scoped (links, commands, absences)
- [ ] `:Tricentis pto back` -- The return checklist and every open case whose deadline passed while you were away
- [ ] `:Tricentis cheatsheet` -- Render every CLI command of a topic into one grouped scratch buffer
- [ ] `:Tricentis links` -- Search links across the work repo (scope: all|cases|notes|workflow|terminologie|tosca|todo)
- [ ] `:Tricentis pto` -- Absence checklist, the mails with the return date filled in, and the open cases whose deadline falls before you are back (files in config.pto_dir)

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

- [ ] `:UI status` -- Show the current UI configuration
- [ ] `:UI variant` -- Show the current statusline variant, or switch to one
- [ ] `:UI tabline-style` -- Show the current tabline style, or switch to one
- [ ] `:UI themes` -- List every colorscheme, the active one marked
- [ ] `:UI slots` -- Numbered slots: list, run, add, edit, move, clear, panel, bar
- [ ] `:UI theme` -- Show the current colorscheme, or switch to one
- [ ] `:UI help` -- Print the long help text
- [ ] `:UI tabline-styles` -- List all tabline styles
- [ ] `:UI toggle` -- Switch between the two configured themes
- [ ] `:UI keys` -- List the mappings under a prefix
- [ ] `:UI picker` -- Open the visual theme picker with live preview
- [ ] `:UI modules` -- List the available statusline segments
- [ ] `:UI progress` -- Show what is running now
- [ ] `:UI variants` -- List all statusline variants
- [ ] `:UI zen` -- Toggle the zen box
- [ ] `:UI winpick` -- Pick a window by letter and jump to it
- [ ] `:UI notify` -- Toggle notify toasts, open or clear the history
- [ ] `:UI context` -- Same command as sticky, older name
- [ ] `:UI color` -- Open the colour picker, optionally on a colour
- [ ] `:UI screenkey` -- Toggle the screenkey HUD
- [ ] `:UI transparency` -- Toggle transparency (on/off to set it)
- [ ] `:UI sticky` -- The sticky context: toggle, depth, line cap, jump

### :UrlView

- [ ] `:UrlView` -- List urls in a scope, then open / export them

### :WinHorizontal

- [ ] `:WinHorizontal` -- Move current window to horizontal split

### :WinVertical

- [ ] `:WinVertical` -- Move current window to vertical split

### :WkdbooksFileGrep

- [ ] `:WkdbooksFileGrep` -- [pickers coll] :WkdbooksFileGrep [query] → :Pickers wkdbooks filegrep

### :WkdbooksFiles

- [ ] `:WkdbooksFiles` -- [pickers coll] :WkdbooksFiles → :Pickers wkdbooks files

### :WkdbooksGrep

- [ ] `:WkdbooksGrep` -- [pickers coll] :WkdbooksGrep → :Pickers wkdbooks grep

### :WkdbooksLuaFileGrep

- [ ] `:WkdbooksLuaFileGrep` -- [pickers coll] :WkdbooksLuaFileGrep [query] → :Pickers wkdbooks_lua filegrep

### :WkdbooksLuaFiles

- [ ] `:WkdbooksLuaFiles` -- [pickers coll] :WkdbooksLuaFiles → :Pickers wkdbooks_lua files

### :WkdbooksLuaGrep

- [ ] `:WkdbooksLuaGrep` -- [pickers coll] :WkdbooksLuaGrep → :Pickers wkdbooks_lua grep

### :WkdbooksLuaSmart

- [ ] `:WkdbooksLuaSmart` -- [pickers coll] :WkdbooksLuaSmart → :Pickers wkdbooks_lua smart

### :WkdbooksNvimFileGrep

- [ ] `:WkdbooksNvimFileGrep` -- [pickers coll] :WkdbooksNvimFileGrep [query] → :Pickers wkdbooks_nvim filegrep

### :WkdbooksNvimFiles

- [ ] `:WkdbooksNvimFiles` -- [pickers coll] :WkdbooksNvimFiles → :Pickers wkdbooks_nvim files

### :WkdbooksNvimGrep

- [ ] `:WkdbooksNvimGrep` -- [pickers coll] :WkdbooksNvimGrep → :Pickers wkdbooks_nvim grep

### :WkdbooksNvimSmart

- [ ] `:WkdbooksNvimSmart` -- [pickers coll] :WkdbooksNvimSmart → :Pickers wkdbooks_nvim smart

### :WkdbooksSmart

- [ ] `:WkdbooksSmart` -- [pickers coll] :WkdbooksSmart → :Pickers wkdbooks smart

### :Wrap

- [ ] `:Wrap` -- (no description)

### :XML

- [ ] `:XML compact` -- Collapse onto one line
- [ ] `:XML` -- XML format/filter (range-aware; no range = whole buffer)
- [ ] `:XML pretty` -- Pretty-print (default 2-space indent; pretty 4 for 4)
- [ ] `:XML lines` -- One 'path: value' per leaf, nested keys dotted (--sep to override)
- [ ] `:XML sort` -- Pretty-print with object keys sorted (see data.format.<fmt> for why this equals 'pretty' today)
- [ ] `:XML keys` -- List only the (dotted) key paths, no values
- [ ] `:XML filter` -- Interactively filter flattened path/value entries (requires pickers.nvim; --preview to diff before replacing)

### :YAML

- [ ] `:YAML filter` -- Interactively filter flattened path/value entries (requires pickers.nvim; --preview to diff before replacing)
- [ ] `:YAML to` -- Convert to json
- [ ] `:YAML` -- YAML format/filter (range-aware; no range = whole buffer)
- [ ] `:YAML lines` -- One 'path: value' per leaf, nested keys dotted (--sep to override)
- [ ] `:YAML pretty` -- Pretty-print (default 2-space indent; pretty 4 for 4)
- [ ] `:YAML keys` -- List only the (dotted) key paths, no values
- [ ] `:YAML sort` -- Pretty-print with object keys sorted (see data.format.<fmt> for why this equals 'pretty' today)

## ⚠ Handle with care

155 item(s) flagged by a keyword guess (delete/remove/kill/
shutdown/... in the description or route) -- a candidate for extra
caution, not a verdict. Read the description before triggering any of these.

- [ ] `<leader>aix` (Ai) -- Ai: Stop every running stream
- [ ] `<leader>dar` (DAP) -- DAP: Restart
- [ ] `<leader>hd` (Session) -- Session: unmark this file
- [ ] `<Del>` (bindings) -- Smart delete (<Del>)
- [ ] `<leader>Q` (bindings) -- [Windows] Force quit all
- [ ] `dw` (bindings) -- [Edit] Delete word backwards without yanking
- [ ] `x` (bindings) -- [Edit] Delete char without yanking
- [ ] `<leader>ntS` (config) -- Stop test
- [ ] `<leader>dcf` (fileops) -- fileops: Delete current file
- [ ] `<leader>fa` (pickers) -- pickers: Find all files in CWD (forces hidden+no_ignore+follow)
- [ ] `:Ai stop` -- Stop every running stream (one-shot asks and edits cannot be stopped)
- [ ] `:Ai key` -- Choose the API-key profile for this session (reset = back to the configured one)
- [ ] `:AstroDevStop` -- Stop Astro dev server
- [ ] `:BindingsRuntimeChecklist` -- Write the runtime checklist (lib.nvim.bindings.audit.checklist_lines) to docs/ROADMAP/Final_Checks/BINDINGS-RUNTIME-CHECKLIST.md; ! to overwrite
- [ ] `:Cascade cycle remove` -- Remove the runtime cycle group containing a value
- [ ] `:Case close` -- Move the case somewhere (pick a destination, or delete)
- [ ] `:Case ki` -- Build the AI-analysis prompt from the clipboard's activity stream and copy it back; --send sends it (anonymized) to the configured AI provider and files the answer, --preview stops after saving the anonymized prompt, --raw sends/previews it NOT anonymized (always behind a warning popup), --inline embeds the policy documents
- [ ] `:Case clean` -- Strip AI-paste artifacts (Gemini utm_source, LaTeX leftovers) from cfile/cwd/path=.../the current buffer
- [ ] `:Case spotlight clear` -- Delete the markings saved for this case (and clear the spotlights if they are this case's active ones)
- [ ] `:Case ai provider reset` -- Forget this session's AI provider choice and use the install spec's again
- [ ] `:Case image getText` -- Read ONE screenshot's text and look at it before writing the sidecar (needs tesseract); --preset=log for dense structured-log screenshots
- [ ] `:Case ocr` -- Read the text out of this case's screenshots into .ocr.md sidecar files next to each screenshot, so :Case grep finds it (needs tesseract); --preset=log tunes tesseract for dense structured-log screenshots
- [ ] `:Case delete` -- Permanently delete a case (types the case number back to confirm)
- [ ] `:Clipboard remove citeX` -- Remove all "[cite: N]" markers from the buffer (Ex command) -> clipboard
- [ ] `:CmpReloadWords` -- [lsp.completion.personal_names] Reload extra.lua and the personal-plugin list without restarting
- [ ] `:Dap restart` -- Restart
- [ ] `:Debug proc stop` -- Stop logging and restore the wrapped functions
- [ ] `:Debug keylogger stop` -- Stop the key logger
- [ ] `:DocMap` -- Regenerate the module map (:DocMap [check|full|open|graph|why <a> <b>|dot|mermaid|consumers|diff <ref>|impact <ref>|churn [range]|untested|pick|checklist [all]|plugins|bindings|tools|endpoints|serve [stop]|helptags|annotate [--write|--sidecar]|all [full]])
- [ ] `:Emojis clear` -- Remove emojis from the given scope
- [ ] `:File delete` -- Delete the file from disk and close the buffer
- [ ] `:Filetree refs undo` -- Revert the last reference rewrite
- [ ] `:Filetree symlink delete` -- Remove marked symlinks (else the node under the cursor) via trash — never a non-symlink
- [ ] `:Filetree cwd forget` -- Drop the policy saved for this project (persist)
- [ ] `:Format cite` -- Remove [cite: N] markers (AI answers)
- [ ] `:Format filter` -- Filter lines: filter [--remove] <pattern> ...
- [ ] `:Format unique` -- Remove duplicate buffer lines: unique [-i]
- [ ] `:Format trim` -- Remove trailing whitespace from buffer
- [ ] `:Ft refs undo` -- Revert the last reference rewrite
- [ ] `:Ft cwd forget` -- Drop the policy saved for this project (persist)
- [ ] `:Ft symlink delete` -- Remove marked symlinks (else the node under the cursor) via trash — never a non-symlink
- [ ] `:Git hunk toggle-deleted` -- Toggle showing deleted lines inline
- [ ] `:Git hunk reset-buffer` -- Reset every hunk in the current buffer
- [ ] `:Git hunk reset` -- Reset the hunk under the cursor
- [ ] `:GithubStats dashboard` -- Open GitHub Stats Dashboard (use :GithubStats! dashboard to force refresh)
- [ ] `:GithubStats fetch` -- Fetch GitHub stats (use 'force' to bypass interval)
- [ ] `:GithubStats compact` -- Archive old clones/views data and prune stale referrers/paths snapshots (use 'dry-run' to preview)
- [ ] `:Image orphans` -- Find images in the target directory with no link, and optionally delete them
- [ ] `:Image clear` -- Remove the displayed images
- [ ] `:Insights devserver kill` -- Kill tracked dev servers
- [ ] `:Lib deps reset-first-run` -- Forget that a plugin's (or every plugin's) first-run popup was already shown
- [ ] `:Lsp root` -- Root scope and workspace folders: pick, show, add, remove, list
- [ ] `:Lsp autorestart` -- Bring a crashed server back automatically: control or report
- [ ] `:Lsp restart` -- Restart clients on this buffer (all, or one by name)
- [ ] `:Lsp force-restart` -- Restart one server with a full cleanup first
- [ ] `:Lsp stop` -- Stop clients on this buffer (all, or one by name)
- [ ] `:LspForceRestart` -- [lsp.usercmds] Force-restart LSP with full cleanup
- [ ] `:LspRestartHere` -- [lsp.usercmds] Restart LSP clients (all or specify name)
- [ ] `:LspStopHere` -- [lsp.usercmds] Stop LSP clients (all or specify name)
- [ ] `:LspWorkspaceDiagnosticsNow` -- [lsp_workspace_diagnostics] force-populate workspace diagnostics now, regardless of the toggle
- [ ] `:MDView spotlight` -- Mirror spotlight.nvim's highlights into the preview, or stop mirroring; no argument toggles
- [ ] `:MDView edit` -- Click a block in the preview to edit its source lines, or stop; no argument toggles
- [ ] `:MDView toggle` -- Start if stopped, stop if running
- [ ] `:MDView stop` -- Stop the relay, detach autocommands, and (in isolated mode) close the browser
- [ ] `:MDView selection` -- Mirror the visual selection (v/V/CTRL-V) into the preview, or stop mirroring; no argument toggles
- [ ] `:MDView paragraph` -- Tint the paragraph/list/table/code block the cursor is in, in the preview, or stop; no argument toggles
- [ ] `:MDView file-log path` -- Set the file log path (or `default` to reset it); omit to report the current path
- [ ] `:MDView zoom` -- Adjust the preview font-size zoom (+ | - | reset | <factor>)
- [ ] `:Mark clear` -- Remove every mark in this buffer (optionally only one category)
- [ ] `:MdRebuildWords` -- [md_words] Force full rebuild of the project-wide word cache
- [ ] `:Media cache clear` -- Delete every rendered still
- [ ] `:My opt reset` -- Restore key(s) to the values the plugin shipped; no key = all
- [ ] `:My guicursor` -- Set 'guicursor' from a named preset
- [ ] `:My hl reset` -- Restore key(s) to the values the plugin shipped; no key = all
- [ ] `:My` -- my.nvim: highlights, editor options, diff profiles, guicursor presets
- [ ] `:MyPlugins mode` -- Show, or persistently switch, plugins.personal.core.source's OVERRIDE (restart required to apply)
- [ ] `:MyPlugins picker` -- Interactive multi-select: assign clone/update/pull/fetch/remove/reclone per plugin, then run them all at once
- [ ] `:MyPlugins reclone` -- Delete (if clean) and re-clone present listed plugins, or clone missing ones fresh, after confirmation; --dry-run previews the safe/unsafe/missing split without touching anything
- [ ] `:MyPlugins fetch` -- git fetch --all --prune on every present listed plugin (or just --only=<name>)
- [ ] `:MyPlugins remove` -- Remove clean (no uncommitted/unpushed work) listed plugins (or just --only=<name>), after confirmation
- [ ] `:MyPlugins sync` -- Fetch ALL listed plugin repos first, then pull every one that is behind (fast-forward only); the ones that cannot be pulled (dirty, diverged, no upstream, unreachable ...) are collected into a triage list instead of stopping the run. --dry-run classifies without pulling, --no-fetch skips the fetch, --jobs=<n> sets the parallel fetches (default 2, max 6), --only=<name> syncs one repo
- [ ] `:MyPlugins sync issues` -- Reopen the triage list (unresolved and skipped repos) of the last :MyPlugins sync, also after a restart
- [ ] `:MyPlugins task set` -- Change frontmatter of an open task (key=value, a value may hold spaces, an empty value removes the key) and regenerate the index; a finished task takes remind= only (set it, or take it away)
- [ ] `:MyPlugins task lists` -- Pick a named list (built in, saved, or from setup({ lists })) and open it as the task dashboard; save and delete lists with the dashboard key gl or `tasks lists`
- [ ] `:NeotestClearAll` -- Stop tests and close all windows
- [ ] `:NeotestStop` -- Stop running tests
- [ ] `:Pickers browse` -- Browse a directory on the engine's item picker, with new/rename/delete rows (pickers.browse)
- [ ] `:RA usage stop` -- Stop counting keymap/command presses
- [ ] `:RA startup report` -- Stop measuring and show the stall timeline
- [ ] `:RATelemetry` -- runtime-analysis.telemetry: report|status|start|stop|flush|reset|disable|enable|disabled|coverage|export|export-all|open|compare|startup|flamegraph|cost|snapshot|snapshots|snapshot-compare|setup|full [namespace] [days]
- [ ] `:RATelemetryResetAll` -- runtime-analysis.telemetry: reset every live instance, prompting once for a backup directory if anything would be lost (same as :RATelemetry reset)
- [ ] `:RATelemetrySetupAll` -- runtime-analysis.telemetry: backup+reset+re-wrap+start every configured, loaded target (own profile_args/timing policy)
- [ ] `:RATelemetryStopAll` -- runtime-analysis.telemetry: stop every live instance (same as :RATelemetry stop)
- [ ] `:ReplacePreset` -- Run a saved preset: :ReplacePreset {name}
- [ ] `:ReplaceSavePreset` -- Usage: :ReplaceSavePreset {name} {old} {new} [scope] [--flags]
- [ ] `:Reposcope filter` -- Filter the repository list by substring (no args resets the list)
- [ ] `:Rules unwaive` -- Remove a waiver from .rules-waivers.json: the findings it accepted flag again. Asks first (--yes skips the question)
- [ ] `:RulesVault create` -- Make a rules vault: folder, README, .rules.json, .gitattributes, .gitignore, CI and a first ruleset. Lists what happens and the setup() step that is left to you, then asks (--yes skips it). Never overwrites a file, never adds a remote
- [ ] `:Sandbox container kill` -- Force kill a container (--buffer: stream to a terminal buffer)
- [ ] `:Sandbox container restart` -- Restart a container (--buffer: stream to a terminal buffer)
- [ ] `:Sandbox container remove` -- Remove a stopped container (--buffer: stream to a terminal buffer)
- [ ] `:Sandbox container prune` -- Remove all stopped containers (--buffer: stream to a terminal buffer)
- [ ] `:Sandbox container start` -- Start a stopped container (--buffer: stream to a terminal buffer)
- [ ] `:Sandbox container stop` -- Stop a running container (--buffer: stream to a terminal buffer)
- [ ] `:Sandbox wsl stop` -- Stop (terminate) a WSL distro
- [ ] `:Sandbox container logs-follow` -- Stream a container's logs live (press q in the buffer to stop)
- [ ] `:Sandbox image remove` -- Remove a local image
- [ ] `:Sandbox image prune` -- Remove all dangling images (--buffer: stream to a terminal buffer)
- [ ] `:Sandbox network prune` -- Remove all unused networks
- [ ] `:Sandbox compose down` -- Stop and remove the compose project detected in cwd
- [ ] `:Sandbox network remove` -- Remove a network
- [ ] `:Sandbox volume prune` -- Remove all unused volumes
- [ ] `:Sandbox volume remove` -- Remove a volume
- [ ] `:Sandbox compose restart` -- Restart the compose project detected in cwd
- [ ] `:Sandbox wsl shutdown-all` -- Shut down the WSL2 VM and all running distros
- [ ] `:Sandbox engine reset` -- Clear the session engine override, falling back to .sandboxrc/config
- [ ] `:Sbx container logs-follow` -- Stream a container's logs live (press q in the buffer to stop)
- [ ] `:Sbx compose restart` -- Restart the compose project detected in cwd
- [ ] `:Sbx engine reset` -- Clear the session engine override, falling back to .sandboxrc/config
- [ ] `:Sbx compose down` -- Stop and remove the compose project detected in cwd
- [ ] `:Sbx network prune` -- Remove all unused networks
- [ ] `:Sbx network remove` -- Remove a network
- [ ] `:Sbx wsl shutdown-all` -- Shut down the WSL2 VM and all running distros
- [ ] `:Sbx wsl stop` -- Stop (terminate) a WSL distro
- [ ] `:Sbx container prune` -- Remove all stopped containers (--buffer: stream to a terminal buffer)
- [ ] `:Sbx container remove` -- Remove a stopped container (--buffer: stream to a terminal buffer)
- [ ] `:Sbx container start` -- Start a stopped container (--buffer: stream to a terminal buffer)
- [ ] `:Sbx container stop` -- Stop a running container (--buffer: stream to a terminal buffer)
- [ ] `:Sbx container restart` -- Restart a container (--buffer: stream to a terminal buffer)
- [ ] `:Sbx container kill` -- Force kill a container (--buffer: stream to a terminal buffer)
- [ ] `:Sbx volume prune` -- Remove all unused volumes
- [ ] `:Sbx image remove` -- Remove a local image
- [ ] `:Sbx volume remove` -- Remove a volume
- [ ] `:Sbx image prune` -- Remove all dangling images (--buffer: stream to a terminal buffer)
- [ ] `:Session marks defaults reset` -- Rebuild the list from the defaults and pins, in that order
- [ ] `:Session marks unpin` -- Stop treating a file as a default (the list entry stays)
- [ ] `:Session marks pin` -- Pin a file: a default that survives `defaults reset`
- [ ] `:Session marks remove` -- Remove a file from the list (default: current buffer)
- [ ] `:Session delete-stale` -- Delete every stale session (see :Session stale), one confirm for the whole batch
- [ ] `:Session delete` -- Delete a session by name
- [ ] `:Session save` -- Save session [name] (tab-complete to overwrite an existing one)
- [ ] `:Spotlight sets delete` -- Delete a saved set (does not touch the active spotlights)
- [ ] `:Spotlight sets save` -- Save the active spotlights as a named set (overwrites if it already exists)
- [ ] `:Spotlight clear` -- Remove every spotlight
- [ ] `:Spotlight remove` -- Remove the spotlight matching TEXT exactly
- [ ] `:TSParserPolicy` -- Show/set the treesitter parser install policy (off|prompt|auto|reset)
- [ ] `:Tasks lists` -- Pick a named list (built in, saved, or from setup({ lists })) and open it as the task dashboard; save and delete lists with the dashboard key gl or `tasks lists`
- [ ] `:Tasks set` -- Change frontmatter of an open task (key=value, a value may hold spaces, an empty value removes the key) and regenerate the index; a finished task takes remind= only (set it, or take it away)
- [ ] `:Terminal pin` -- Restart a native terminal as a pane of tmux/WezTerm so it outlives Neovim
- [ ] `:Terminal close` -- Stop a terminal's job and remove it
- [ ] `:Testing cache clear` -- Delete the result cache of the project (it is regenerable: costs time, never correctness)
- [ ] `:Testing init` -- Generate .testing.lua, TESTS/minimal_init.lua, scripts/test.sh and a CI job (never overwrites)
- [ ] `:Testing migrate` -- Plan the move of a plugin repo to testing.nvim (dry-run; `apply` writes into a clean git tree)
- [ ] `:UI kit-presets` -- List all popup/toast presets
- [ ] `:UI kit-preset` -- Show or switch the popup/toast border and colors
