-- TESTS/bindings_explorer/report_dir_spec.lua -- `config.report_dir()` names a folder this repo
-- actually has.
--
-- `:Bindings report` and `:BindingsRuntimeChecklist` both write below `report_dir()`. When the
-- 2026-09-25 reshuffle removed `docs/ROADMAP/personal/All`, the function kept returning it:
-- `:BindingsRuntimeChecklist` no longer saw the existing checklist and silently recreated the old
-- folder with `mkdir -p`. Nobody noticed until the path was read by hand.
--
-- `report_dir()` is built from `stdpath("config")`; the spec checks the same path relative to the
-- checkout it runs in, so it also holds in a worktree.

return function(H)
  local spec_file = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p")
  local config_root = vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(vim.fs.normalize(spec_file))))

  local cfg = require("bindings.usrcmds.bindings_explorer.config")
  local dir = vim.fs.normalize(cfg.report_dir())
  local base = vim.fs.normalize(vim.fn.stdpath("config"))

  H.eq(dir:sub(1, #base + 1), base .. "/", "report_dir() lies inside stdpath('config'): " .. dir)
  local rel = dir:sub(#base + 2)
  H.ok(rel ~= "", "report_dir() is a subfolder, not the config root itself")

  local here = vim.fs.joinpath(config_root, rel)
  H.eq(vim.fn.isdirectory(here), 1, "report_dir() exists in this checkout: " .. here)

  -- The runtime checklist lives there; a moved folder without the file means the two drifted.
  H.eq(
    vim.fn.filereadable(vim.fs.joinpath(here, "BINDINGS-RUNTIME-CHECKLIST.md")),
    1,
    "BINDINGS-RUNTIME-CHECKLIST.md sits in report_dir()"
  )
end
