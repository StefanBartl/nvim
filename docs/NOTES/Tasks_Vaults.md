# Zwei Task-Vaults: tasks-vault und tricentis-vault

Kurz: `:Tasks` arbeitet **immer** im `tasks-vault`. Der `tricentis-vault` wird
über casedesk angesprochen, nicht über `:Tasks`. Ein „Umschalten“ von `:Tasks`
gibt es nicht als Befehl, nur den Lua-Einzeiler unten.

| Vault | Wofür | Gesetzt in |
| --- | --- | --- |
| `$REPOS_DIR/tasks-vault` | Entwicklung der Werkzeuge (Plugins, nvim-config, Desktop-Apps) | `lua/plugins/personal/specs/project.lua`, Spec `tasks.nvim`, `opts.vault` (Fallback: `$TASKS_VAULT`) |
| `$REPOS_DIR/tricentis-vault` | Arbeit bei Tricentis (Fälle, SAP-Support, CS, Horizon, Learning, Meetings) | gleiche Datei, Spec `casedesk.nvim`, `opts.tasks.vault` |

## a) Welcher Vault ist gerade aktiv?

- `:TasksVault` (ohne Argument, = `:TasksVault status`) zeigt den Vault von
  `:Tasks`, die Zahl der Areas und die Area des aktuellen Buffers.
- An den Areas erkennt man ihn auch: `tasks-vault` hat Plugin-Namen
  (`casedesk.nvim`, `nvim-config`, `ALL` …), `tricentis-vault` hat
  `SAP-Support`, `CS`, `Horizon`, `Learning`, `Meetings`, `Tricentis`, `ALL`.
- Die casedesk-Befehle nutzen **immer** den tricentis-vault, egal was
  `:TasksVault` meldet (sie rufen die tasks.nvim-API mit eigenem Root auf).

## b) Neue Task im richtigen Vault anlegen

| Ziel | Befehl |
| --- | --- |
| Task für Plugin/Config (tasks-vault) | `:Tasks new …` |
| Nächster Schritt aus einem Fall (tricentis-vault, Tag `sap-<nr>`/`cs-<nr>`) | `:Case task new [nr]` |
| Tricentis-Task ohne Fall (Meetings, Learning, Horizon …) | `:Tricentis task new [area]` |
| Offene Tricentis-Tasks ansehen | `:Tricentis tasks [area]` bzw. `:Case task list [nr]` |

Doku dazu: `$REPOS_DIR/casedesk.nvim/docs/tasks.md`.

## Notlösung: `:Tasks` selbst auf den tricentis-vault umbiegen (nur diese Sitzung)

```vim
:lua require("tasks_nvim.vault").configure({ vault = vim.env.REPOS_DIR .. "/tricentis-vault" })
:TasksVault
```

Zurück:

```vim
:lua require("tasks_nvim.vault").configure({ vault = vim.env.REPOS_DIR .. "/tasks-vault" })
```

Hinweise:

- `tasks_nvim.vault` ist ein internes Modul (so schaltet auch `:TasksVault create`
  für die Sitzung um), keine öffentliche API; kann sich ändern.
- Nach einem Neustart gilt wieder `opts.vault` aus `project.lua`.
- `extra_areas` (`ALL`, `nvim-config` …) bleiben dabei gesetzt; im
  tricentis-vault stört das nicht, wenn es die Ordner dort nicht gibt.
- Lieber die casedesk-Befehle nutzen: die setzen die Fall-Tags und Konventionen
  (`:Case task new`) automatisch.

## Headless-CLI

Gleiche CLI, nur `--vault=` wechselt:

```bash
nvim --headless -u NONE -l $REPOS_DIR/tasks.nvim/scripts/tasks.lua list --vault=$REPOS_DIR/tricentis-vault
```
