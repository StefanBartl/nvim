# vim-visual-multi — User-Commands

Alle sieben globalen Commands sind **[default]**, definiert als Vimscript
`com!` in `plugin/visual-multi.vim`. Diese Config registriert keinen eigenen;
sie greift nur in die Keymaps ein (`VM_default_mappings = 0` plus eine eigene
`VM_maps`-Tabelle, siehe
[lua/plugins/ui.lua](../../../../../lua/plugins/ui.lua) und
[Keymaps/VisualMulti.md](../Keymaps/VisualMulti.md)).

Der Spec ist `event = "UIEnter"`, die Commands existieren also kurz nach dem
Start.

## [default] Die sieben globalen

| Command | Wirkung |
|---|---|
| `:VMSearch[!] [pattern]` | Startet den Multi-Cursor-Modus aus einer Suche heraus: alle Treffer des Patterns (ohne Argument: das letzte Suchmuster) werden zu Regionen. Nimmt einen Range, gilt also auf Wunsch nur für einen Zeilenbereich. |
| `:VMLive` | Der Live-Modus: tippen filtert die Regionen, während man schreibt. |
| `:VMClear` | Harter Reset (`vm#hard_reset()`). Der Ausweg, wenn der Multi-Cursor-Zustand hängt und `<Esc>` nicht mehr greift. |
| `:VMRegisters[!] [name]` | Zeigt die VM-eigenen Register — beim Mehrfach-Yank landet pro Region ein Eintrag, und dieser Command macht sie sichtbar. |
| `:VMTheme [name]` | Wechselt das Farbschema der Regionen-Hervorhebung, mit Completion über die verfügbaren Themes. |
| `:VMDebug` | Debug-Ausgabe des Plugins. |
| `:VMFromSearch[!]` | **Veraltet.** Ruft nur noch `vm#special#commands#deprecated()` auf, das auf `:VMSearch` verweist. Steht hier, weil es live registriert ist. |

## Die buffer-lokalen, die nur im VM-Modus existieren

Sechs weitere Commands legt das Plugin **erst an, wenn der Multi-Cursor-Modus
läuft** — mit `-buffer`, in `autoload/vm/special/commands.vim`. Sie tauchen
in keinem `:Bindings check` auf, solange kein VM-Buffer offen ist, und das ist
korrekt so:

`:VMFilterRegions` `:VMFilterLines` `:VMRegionsToBuffer` `:VMMassTranspose`
`:VMQfix` `:VMSort`

Sie sind hier bewusst als Prosa und nicht als Tabelle aufgeführt: eine
Tabellenzeile würde geprüft und in jeder normalen Session als „dokumentiert,
nicht registriert" gemeldet — dieselbe Klasse, die
[Overview.md](./Overview.md) beschreibt, nur eine Ebene tiefer. Eine
Erwähnung genügt, damit der Prüfer sie kennt.

## Warum die Keymaps hier so viele Befunde erzeugt haben

Nicht die Commands, sondern die Tasten: `Keymaps/VisualMulti.md` schreibt den
Leader `\\` mit in den Key (`\\A`, `\\z`, …), die Plugin-Quelle nicht. Fünf
der 16 verbliebenen `keymap-not-live`-Befunde des Extern-Korpus sind genau
das — eine Notationsdifferenz, keine Drift. Steht in
`bindings_explorer/docs/MEASURING.md`, „Was ein Befund nicht ist".
