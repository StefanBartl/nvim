# Arch&Coding-Regeln — verschoben

Diese Datei enthält keine Regeln mehr. Kanonische Fassung liegt im `Notes`-Repo:

- [`LUA_NVIM.md`](https://github.com/StefanBartl/Notes/blob/master/MyNotes/Checklists/Lua/LUA_NVIM.md) —
  Lua-/Neovim-spezifische Umsetzung (`lib.nvim`, Fehlerbehandlung, Neovim-API, Buffer/Window,
  State, Metatables/Memoisierung, Code-Stil, Annotationen, Importreihung, Konfigurierbarkeit)
- [`PRINCIPLES.md`](https://github.com/StefanBartl/Notes/blob/master/MyNotes/Checklists/Lua/PRINCIPLES.md) —
  sprachneutrale Architektur- und Clean-Code-Prinzipien
- [`README.md`](https://github.com/StefanBartl/Notes/blob/master/MyNotes/Checklists/Lua/README.md) —
  Übersicht, welche Datei wann gilt

Lokaler Pfad: `E:\repos\Notes\MyNotes\Checklists\Lua\`

Grund: Die Regeln waren über drei Dateien (`Arch&Coding-Regeln.md`, `Checklist.md`,
`Zentrale-Prinzipien.md`) mit erheblicher Redundanz verteilt und teils fachlich veraltet
(`vim.loop` statt `vim.uv`, unbegrenzte `pcall`-Pflicht im Widerspruch zur eigenen
Kostentabelle, u. a.). Die Neuaufteilung trennt nach Zeitpunkt der Anwendung statt nach
Thema — Details siehe `README.md` oben.
