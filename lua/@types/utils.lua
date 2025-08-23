---@alias MoveDirectionDbg '"up"'|'"down"'

---@class DebugDumpOpts
---@field loc? string                 -- Source location hint (defaults to caller via get_loc)
---@field title? string               -- Notification title (auto from loc)
---@field level? integer              -- vim.log.levels (defaults to INFO)
---@field method? '"notify"'|'"float"'  -- Where to show output; 'notify' or 'float' (scratch window)
---@field max_notify_lines? integer   -- If lines exceed this and method=='notify', fallback to 'float'
---@field wrap? boolean               -- Wrap long lines in float window
---@field filetype? string            -- Filetype for syntax highlighting (defaults to 'lua')
---@field on_open? fun(win:integer)   -- Optional window hook


---@class ExtmarkLeakEntry
---@field name string
---@field buf integer
---@field count integer
---@field ft string

---@class ModuleSizeRow
---@field mod string
---@field size number  -- size in MiB (approx)


---@class DebugSetupOpts
---@field set_global_dd? boolean     -- if true, defines _G.dd as a thin wrapper around M.dump
---@field create_commands? boolean   -- default true
---@field create_keymaps? boolean    -- default true
---@field create_autocmds? boolean   -- default true
---@field leader? string             -- leader prefix for keymaps (default "<leader>d")
---@field default_method? '"notify"'|'"float"'



---@alias Path string

---@class NewFileOpts
---@field recursive boolean       -- create parent directories
---@field overwrite boolean       -- force overwrite if file exists
---@field write_now boolean       -- write immediately after opening/renaming

---@class NewFileAPI
---@field ensure_parent fun(path: Path, recursive: boolean): boolean
---@field edit_new fun(path: Path, opts?: NewFileOpts): nil
---@field save_as fun(path: Path, opts?: NewFileOpts): nil
---@field write_to fun(path: Path, opts?: NewFileOpts): nil


---@class ProjectRoot
---@field get fun(bufnr?: integer): Path  -- Compute the project root for a buffer





