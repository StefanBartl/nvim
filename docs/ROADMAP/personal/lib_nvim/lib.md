# `lib.nvim`

Custom PLugins sollen lib.nvim als hard dep nutzen, fallback code (pcall lib.nvim und wenn esnict klappt eigenimplementierung) nur in ausdnahmefällen und gut begrründet

1. Personal Plugins auf `utils`-Folder durchsuchen -> Eventuell Funktionen für die lib dabei?
  1. `lib.nvim/lua/nvim/neotree/**` Folder (filetree.nvim)
2. `cross/fs/mutate`: Retry-Layer für Windows-Sharing-Errors (EPERM/EACCES/EBUSY) implementiert, ungetestet im echten Lock-Fall. Nächster Schritt: `neotree/watch`-Registry (Handle-Leak in neo-trees `fs_watch.lua` fixen) — siehe [handle_guard.md](../filetree/handle_guard.md).

## Neue Features implementieren

> alle Cross-Platform!
> Alle neuen features in die `docs/lib.txt` `vimdoc` sowie die `@types/all_functions` sowie die `init.lua` eintragen

---

