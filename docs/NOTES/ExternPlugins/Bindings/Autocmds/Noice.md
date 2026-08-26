# Noice — Autocmds

| Gruppe | Event(s) | Quelle | Zweck |
|---|---|---|---|
| `NoiceBufferMaps` | `FileType` (Pattern `noice*`) | [lua/bindings/mappings/noice.lua](../../../../../lua/bindings/mappings/noice.lua) | Setzt die buffer-lokalen Scroll-/Dismiss-Keymaps (`<A-j/k/Down/Up/x>`) für jeden Buffer, dessen Filetype mit `noice` beginnt — siehe [Keymaps/Noice.md](../Keymaps/Noice.md). |

Status: **[custom]**. `noice.nvim` selbst legt keinen vergleichbaren Autocmd
an — die Buffer mit Filetype `noice*` (z. B. `noice_lsp_docs`) entstehen aus
dem Plugin heraus, aber das Verknüpfen von Keymaps daran ist reine
Config-Ergänzung dieses Repos.

Die Gruppe wird über `Autocmd.group("NoiceBufferMaps", true)`
([lib.nvim.bindings.autocmd](../../../../../lua/lib/nvim/bindings/autocmd.lua)) angelegt, das
zweite Argument (`clear = true`) verhindert doppelte Registrierung bei einem
Config-Reload.

Kein `config.noice`-Modul (siehe
[lua/config/noice/init.lua](../../../../../lua/config/noice/init.lua)) fügt
eigene Autocmds hinzu — die Datei enthält ausschließlich `opts` für
`noice.setup()` (Presets, Views, Routes, LSP-Overrides), keine
Autocmd-Registrierung.
