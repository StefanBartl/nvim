# LazyGit — Keymaps

Plugin: [`kdheepak/lazygit.nvim`](https://github.com/kdheepak/lazygit.nvim).
Spec in [lua/plugins/git.lua](../../../../../lua/plugins/git.lua), Bridge-Setup
in [lua/config/lazygit/init.lua](../../../../../lua/config/lazygit/init.lua).

---

## In Neovim (Keymap)

| Mapping | Aktion | = Command | Status |
|---|---|---|---|
| `<leader>lg` | LazyGit-Floating-Window öffnen | `:LazyGit` | **[custom]** |

Das Plugin selbst registriert **keinen** Default-Keymap — im README wird
lediglich `<leader>gg` als *Beispiel*-Mapping vorgeschlagen (nicht automatisch
gesetzt). Diese Config bindet stattdessen bewusst `<leader>lg` (`keys` im Lazy-
Spec, siehe [lua/plugins/git.lua](../../../../../lua/plugins/git.lua) Z. 19-21) —
`<leader>gg` ist in dieser Config bereits an Neogit vergeben (siehe
[Neogit.md](Neogit.md)). Die Map ist also vollständig **[custom]**, auch wenn
sie textuell dem README-Beispiel ähnelt.

---

## Innerhalb von LazyGit selbst (Terminal-Float, externer Prozess)

LazyGit ist kein Neovim-Buffer, sondern der externe `lazygit`-TUI-Prozess in
einem Terminal-Float. Seine eigenen Tastenkürzel (`o`, Navigation, Staging
etc.) kommen aus `lazygit` selbst, nicht aus diesem Neovim-Plugin, und werden
hier nicht dokumentiert.

Zwei Tasten sind in dieser Config per LazyGit-`customCommands` **zusätzlich**
belegt, um Dateien zurück in die Eltern-Neovim-Instanz zu holen (nvr-Bridge):

| Taste (in LazyGit) | Aktion | Effekt in Neovim | Status |
|---|---|---|---|
| `o` | LazyGit-Default | Datei im System-Dateimanager öffnen | **[default]** (lazygit-TUI, nicht Neovim) |
| `O` | Custom Command → `nvr` → `:LazygitBadd` | Datei als Hintergrund-Buffer (`:badd`), kein Fokuswechsel | **[custom]** |
| `<C-o>` | Custom Command → `nvr` → `:LazygitReplace` | Datei ersetzt sichtbaren Editor-Buffer, fokus-sicher | **[custom]** |

Konfiguriert in der externen `lazygit`-`config.yml`
(`customCommands`, Referenz-Kopie unter
[lua/config/lazygit/docs/config.yml](../../../../../lua/config/lazygit/docs/config.yml)),
nicht in Neovim selbst. Details zum RPC-Mechanismus (`$NVIM` + `nvr`):
[lua/config/lazygit/README.md](../../../../../lua/config/lazygit/README.md).

Siehe [Usercmds/Lazygit.md](../Usercmds/Lazygit.md) für die Neovim-seitigen
Commands `:LazygitBadd` / `:LazygitReplace`, die diese beiden Tasten aufrufen.
