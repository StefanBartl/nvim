# Neogit — User-Commands

Alle vier Commands sind **[default]**, registriert in `plugin/neogit.lua` des
Plugins. Diese Config registriert keinen eigenen; die Keymaps innerhalb der
Neogit-Oberfläche stehen in [Keymaps/Neogit.md](../Keymaps/Neogit.md).

## [default] Alle vier

| Command | Wirkung |
|---|---|
| `:Neogit [args]` | Öffnet die Neogit-Oberfläche. `nargs = "*"` mit eigener Completion (`neogit.complete`); Argumente werden über `neogit.lib.util.parse_command_args` geparst, etwa `kind=split` für die Fensterart oder ein Startbildschirm wie `commit`. |
| `:NeogitCommit [commit]` | Öffnet die Commit-Ansicht für den angegebenen Commit, ohne Argument für `HEAD`. Der direkte Weg zu „was steckt in diesem Commit", ohne über die Statusansicht zu gehen. |
| `:NeogitLogCurrent [datei]` | `git log` für die angegebene Datei, ohne Argument für die aktuelle. **Nimmt einen Range** (`range = "%"`): mit `:5,20NeogitLogCurrent` wird daraus ein `git log -L5,20:datei`, also die Historie genau dieser Zeilen. |
| `:NeogitResetState` | Verwirft die gespeicherten Flags. Neogit merkt sich pro Repository, welche Optionen zuletzt gesetzt waren (`neogit.lib.state`); wenn ein Popup dauerhaft mit einem unerwünschten Flag aufgeht, ist das der Reset dafür. |

## Zwei Git-Oberflächen nebeneinander

Diese Config hat sowohl Neogit als auch Fugitive
([Usercmds/Fugitive.md](./Fugitive.md)) und dazu Lazygit
([Usercmds/Lazygit.md](./Lazygit.md)). Das ist kein Versehen und keine
Redundanz: Fugitive ist eine Command-Sprache über Git-Objekte (`:Gread`,
`:Gclog`, `:GMove`), Neogit eine Oberfläche für den Commit-Ablauf, Lazygit
ein eingebettetes TUI.

Ihre Command-Namen können sich schon durch die Präfixe nicht in die Quere
kommen — `G…` gegen `Neogit…` gegen `Lazygit…`. Eine echte Kollisionsprüfung
über den ganzen Extern-Korpus, wie sie der Personal-Korpus in seinem
`Usercmds/Overview.md` hat, gibt es hier noch nicht.
