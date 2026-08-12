# `github_stats.ndim`

- [ ] `github_stats.nvim` besser machen
- [ ] Dashboard mit stats maxi male zeitdauer?

## Subprozess-Umgebung auf `lib.nvim.cross.run.env` umstellen

Ein Subprozess aus `vim.system()`/`vim.uv.spawn()`/`jobstart()` erbt exakt
Neovims eigene Prozess-Umgebung, nicht die einer interaktiven Login-Shell:
unvollständiger `PATH`, unerreichbarer OS-Keyring. Der gemeinsame Helfer dafür
existiert seit dem `cross.run.env`-Commit in `lib.nvim` (siehe dort
`docs/FEATURES/subprocess-env.md` bzw. `:help lib.nvim-spawn-env`).

- [ ] Spawn-Aufrufe auf `env = require("lib.nvim.cross.run.env").build()` bzw.
      `env.apply(spawn_opts)` umstellen — betroffen: prüfen, ob eigene Spawns existieren (aktuell keine gefunden) — sonst Eintrag streichen.

---

