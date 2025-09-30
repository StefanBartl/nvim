# Beispielkonfiguartionen repo pickers

## nur :RepoFiles/:RepoGrep aktiv

```lua
require("custom.repo_pickers").enable({
  selector = "auto",      -- "auto" | "vim_select" | "telescope" | "fzf"
  engine   = "auto",      -- "auto" | "telescope" | "fzf"
  expose_engine_cmds = false,  -- wichtig: engine-spezifische Commands NICHT registrieren
  keymaps_lhs = { repo_files = "<leader>rf", repo_grep = "<leader>rg" },
}, { usercmds = true, keymaps = true })
```

---

## Engine-spezifische Commands temporär aktivieren (nur wenn man sie braucht)

```lua
require("custom.repo_pickers").enable({
  selector = "auto",
  engine   = "auto",
  expose_engine_cmds = true,   -- registriert zusätzlich RepoFindFilesFzf/Telescope etc.
}, { usercmds = true })
```

---

## full

```lua
require("custom.repo_pickers").enable({
  -- repos_dir = "/home/steve/repos",
  only_git = true,
  selector = "fzf",
  engine   = "auto",
  show_relative = true,
  usercmd_names = {
    find_files_telescope = "RepoFilesTelescope",
    grep_telescope       = "RepoGrepTelescope",
    find_files_fzf       = "RepoFilesFzf",
    grep_fzf             = "RepoGrepFzf",
  },
  keymaps_lhs = {
    repo_files = nil,
    repo_grep  = nil,
  },
}, { usercmds = true, keymaps = true })
```

---
