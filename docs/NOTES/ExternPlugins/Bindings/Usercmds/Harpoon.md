# Harpoon — User-Commands

Registriert in [lua/config/harpoon/usrcmds.lua](../../../../../lua/config/harpoon/usrcmds.lua),
aufgerufen aus dem `config`-Block des Plugin-Specs
([lua/plugins/misc.lua](../../../../../lua/plugins/misc.lua)).

Alle Kommandos sind dünne Wrapper um
[lua/config/harpoon/api.lua](../../../../../lua/config/harpoon/api.lua) — dieselbe
API, die auch die Keymaps benutzen. Keymap und Command können also nicht
auseinanderlaufen.

**Status: durchgehend [custom]**, keine Zeilen-Markierung nötig — `harpoon.
nvim` selbst bringt keine `:Harpoon…`-Commands mit, es gibt also keinen
Plugin-Default, gegen den "custom" hier kontrastieren würde.

---

## 1. Unified Verb `:Harpoon`

Gebaut mit `lib.nvim.bindings.usercmd.composer` (`composer.verb`), d.h. mit `<Tab>`-
Completion pro Subcommand/Argument und Usage-Ausgabe statt rohem Vim-Fehler.

| Aufruf | Wirkung |
|---|---|
| `:Harpoon` | Quick-Menu öffnen/schließen (Bare-Form = `menu default`). |
| `:Harpoon menu [default\|telescope\|fzf]` | Listen-UI öffnen. `default` = Harpoon-Quick-Menu, `telescope`/`fzf` = eigene Picker mit gekürzten Labels (`<CR>` edit, `<C-v>` vsplit, `<C-x>` split, `<C-t>` tab). Fehlt der Picker, wird auf das Quick-Menu zurückgefallen. |
| `:Harpoon add [pfad] [--front] [--permanent]` | Datei zur Liste hinzufügen. Ohne `pfad`: aktueller Buffer. Ohne Flags: ans **Ende**. |
| `:Harpoon remove [pfad]` | Eintrag aus der **Live-Liste** entfernen (der Default-Pin-Status bleibt — dafür `unpin`). |
| `:Harpoon pin [pfad] [--front]` | Datei als dauerhaften Default aufnehmen (`harpoon_user_pins.json`) und sofort einfügen. |
| `:Harpoon unpin [pfad]` | Datei aus den dauerhaften Defaults nehmen. Der Listeneintrag selbst bleibt. |
| `:Harpoon defaults sync` | **Top-up**: fehlende Default-Pfade ans Ende anhängen, sonst nichts anfassen. |
| `:Harpoon defaults reset` | **Hard-Reset**: Liste leeren und exakt aus den Defaults neu aufbauen. |
| `:Harpoon select <n>` | Zu Eintrag *n* springen. |
| `:Harpoon preview <n>` | Vollbild-Preview von Eintrag *n* (read-only, `q` schließt). |
| `:Harpoon debug` | Scratch-Buffer mit Index + gekürztem Pfad-Label je Eintrag. |
| `:Harpoon health` | Health-Check (Plugin geladen? plenary/fzf-lua/telescope da? Liste lesbar?). |

### Flags von `:Harpoon add`

| Flag | Kurz | Wirkung |
|---|---|---|
| `--front` | `-f` | Vorne einfügen (Slot 1) statt anhängen. Ist der Pfad schon weiter unten in der Liste, wandert er nach oben — der Aufruf ist also idempotent statt wirkungslos. |
| `--permanent` | `-p` | Zusätzlich als dauerhaften Default-Pin speichern (überlebt `:Harpoon defaults reset` und Neuinstallation der Liste). |

Argument-Typen: `add`/`pin` erwarten eine **lesbare Datei** (`FILE`, Datei-
Completion), `remove`/`unpin` nehmen jeden Pfad (`PATH`), damit auch ein
verwaister Eintrag noch entfernt werden kann.

---

## 2. Flache Aliase

Bleiben absichtlich neben dem Verb bestehen (gleiche Linie wie die Compat-Layer
in `gopath.nvim`/`pickers.nvim`): die beiden `AddToList`-Kommandos sind die
Kurzform für den häufigsten Fall, der Rest existiert, weil er älter ist als das
Verb.

| Alias | Entspricht |
|---|---|
| `:HarpoonAddToList [pfad]` | `:Harpoon add [pfad] --front` |
| `:HarpoonAddToListPermanent [pfad]` | `:Harpoon add [pfad] --front --permanent` |
| `:HarpoonPin [pfad]` | `:Harpoon pin [pfad]` |
| `:HarpoonUnpin [pfad]` | `:Harpoon unpin [pfad]` |
| `:HarpoonPersistPaths` | `:Harpoon defaults sync` |
| `:HarpoonSetDefaultPaths` | `:Harpoon defaults reset` |
| `:HarpoonDebug` | `:Harpoon debug` |
| `:CheckHealthHarpoon` | `:Harpoon health` |

---

## 3. Temporär vs. permanent

- **Temporär** (`add`, ohne `--permanent`): Eintrag lebt in der Harpoon-Liste
  und wird wie jeder andere Eintrag persistiert — verschwindet aber bei
  `:Harpoon defaults reset` und ist nicht gegen ein versehentliches `dd` im
  Quick-Menu geschützt.
- **Permanent** (`add --permanent` / `pin`): Pfad landet zusätzlich in
  `stdpath("state")/harpoon_user_pins.json`, wird im Quick-Menu mit 📌 markiert
  (`config.harpoon.pin_marks`) und von `defaults sync`/`defaults reset` wieder
  hergestellt.

Alle Schreibzugriffe laufen über `config.harpoon.persist_paths.with_pins_key`,
d.h. auf **einem** globalen Bucket (`PINS_KEY = stdpath("config")`), unabhängig
vom aktuellen cwd — siehe [docs/NOTES/Harpoon.md](../../../Harpoon.md) §1.
