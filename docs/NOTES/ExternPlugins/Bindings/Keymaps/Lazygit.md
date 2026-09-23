# LazyGit — Keymaps

> **Entfernt, ersetzt durch gitsuite.nvim.** `kdheepak/lazygit.nvim` ist aus
> [lua/plugins/git.lua](../../../../../lua/plugins/git.lua) raus; `<leader>lg`
> ruft jetzt gitsuite.nvims `:Git ui lazygit` (dessen eigener Default-Keymap,
> siehe gitsuites `docs/BINDINGS.md`). `O`/`<C-o>` funktionieren unverändert
> über gitsuite.nvims `features/ui/lazygit/{badd,replace}.lua`. Blatt bleibt
> als historischer Extern-Korpus-Eintrag stehen, alle Links unten zeigen auf
> entfernte Dateien.

Plugin: [`kdheepak/lazygit.nvim`](https://github.com/kdheepak/lazygit.nvim).
Spec war in [lua/plugins/git.lua](../../../../../lua/plugins/git.lua),
Bridge-Setup in `lua/config/lazygit/init.lua` (**entfernt**).

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

**Nicht live:** die Tastenspalte nennt Tasten des **LazyGit-TUI**, nicht
Neovims. `nvim_get_keymap` sieht sie nie, egal ob LazyGit gerade läuft.
Was Neovim davon registriert, sind die zwei `:Lazygit*`-Commands in der
Effekt-Spalte — siehe [Usercmds/Lazygit.md](../Usercmds/Lazygit.md).

| Taste (in LazyGit) | Aktion | Effekt in Neovim | Status |
|---|---|---|---|
| `o` | LazyGit-Default | Datei im System-Dateimanager öffnen | **[default]** (lazygit-TUI, nicht Neovim) |
| `O` | Custom Command → `nvr` → `:LazygitBadd` | Datei als Hintergrund-Buffer (`:badd`), kein Fokuswechsel | **[custom]** |
| `<C-o>` | Custom Command → `nvr` → `:LazygitReplace` | Datei ersetzt sichtbaren Editor-Buffer, fokus-sicher | **[custom]** |

War konfiguriert in der externen `lazygit`-`config.yml` (`customCommands`,
Referenz-Kopie lag in `lua/config/lazygit/docs/config.yml`, entfernt), nicht
in Neovim selbst. Details zum RPC-Mechanismus (`$NVIM` + `nvr`) standen in
`lua/config/lazygit/README.md` (entfernt).

Siehe [Usercmds/Lazygit.md](../Usercmds/Lazygit.md) für die Neovim-seitigen
Commands `:LazygitBadd` / `:LazygitReplace`, die diese beiden Tasten aufrufen.
