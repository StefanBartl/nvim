# Module

## 3. `custom/insert` + `usrcmds/copy` → shared path-text core
`:Insert filepath|module` (inserts at cursor) and `:Copy path|module` (to clipboard) format the *same* things: cwd-relative / absolute / lua-module / custom separator / depth. We already shared `get_module_path` last session — the rest (modes/formats/depth) is still duplicated in both. → extract one path-formatting core; Insert and Copy become two *sinks* (cursor vs clipboard).
