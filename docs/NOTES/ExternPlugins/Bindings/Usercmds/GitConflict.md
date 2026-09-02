# git-conflict.nvim — User-Commands

**Repo:** `akinsho/git-conflict.nvim` — der Stamm `GitConflict` löst
normalisiert auf `git-conflict.nvim` auf; die Zeile steht hier nur, weil das
Blatt neu ist und die Zuordnung damit auch ohne Nachrechnen lesbar ist.

Alle neun Commands sind **[default]**. Diese Config registriert keinen
eigenen und konfiguriert nichts: der Spec ist
`{ "akinsho/git-conflict.nvim", version = "*", config = true, lazy = false }`
([lua/plugins/git.lua](../../../../../lua/plugins/git.lua)), also
`setup({})` mit den Plugin-Defaults.

`lazy = false` heißt: die Commands existieren ab dem Start, ohne Trigger.
Registriert werden sie in `lua/git-conflict.lua` (`setup_commands`), gesteuert
von `config.default_commands`, das per Default `true` ist.

## Was das Plugin überhaupt tut

Es erkennt Konfliktmarker (`<<<<<<<` / `=======` / `>>>>>>>`) im Buffer,
hebt die drei Abschnitte hervor (`current` als `DiffText`, `incoming` als
`DiffAdd`) und bietet die Auflösung an, ohne dass man die Marker von Hand
löscht. Ohne Konflikt im Buffer tun die Choose-Commands nichts.

## [default] Alle neun

Alle mit `nargs = 0`.

| Command | Wirkung |
|---|---|
| `:GitConflictChooseOurs` | Den *current*-Abschnitt behalten, den Rest samt Markern entfernen. |
| `:GitConflictChooseTheirs` | Den *incoming*-Abschnitt behalten. |
| `:GitConflictChooseBoth` | Beide Abschnitte behalten, nur die Marker entfernen. |
| `:GitConflictChooseBase` | Den *ancestor*-Abschnitt behalten — nur bei Drei-Wege-Konflikten mit `diff3`/`zdiff3`-Stil vorhanden. |
| `:GitConflictChooseNone` | Beide Abschnitte verwerfen, der Konfliktbereich bleibt leer. |
| `:GitConflictNextConflict` | Zum nächsten Konflikt im Buffer springen. |
| `:GitConflictPrevConflict` | Zum vorherigen Konflikt springen. |
| `:GitConflictListQf` | Alle Konflikte des Repositories in die Quickfix-Liste, geöffnet mit `list_opener` (Default `copen`). |
| `:GitConflictRefresh` | Die Konfliktsuche neu ausführen — nach einem externen `git`-Aufruf, der die Marker verändert hat. |

## Die Default-Keymaps, und warum sie kein Kollisionsfall sind

Das Plugin bindet zusätzlich sechs Tasten: `co` / `ct` / `cb` / `c0` für die
vier Choose-Varianten und `]x` / `[x` für die Navigation, jeweils auf
`<Plug>(git-conflict-*)`.

Sie sind **buffer-lokal und werden erst gesetzt, wenn dieser Buffer einen
Konflikt enthält** (`setup_buffer_mappings`, gesetzt mit `bufnr`, danach
`vim.b.conflict_mappings_set`). `]x` / `[x` erscheinen im Extern-Korpus auch
bei Diffview — auch dort buffer-lokal, und in dessen eigenen Fenstern. Die
beiden treffen sich also nicht.

Ein eigenes `Keymaps/GitConflict.md` gibt es (noch) nicht; die sechs Tasten
sind hier vollständig genannt, weil sie ohne Zutun dieser Config gelten.

## Warum dieses Blatt jetzt entstanden ist

Es ist die Antwort auf Punkt 5 des Drift-Handovers: **soll der Extern-Korpus
fremde Commands ohne Cheatsheet abdecken?** Die Entscheidung lautet ja, für
Plugins, die zu einem Arbeitsablauf gehören — und git-conflict.nvim war der
Fall, an dem die Frage entschieden wurde: neun Commands, ein benutztes
Plugin, und im Korpus kam es nicht vor. Werkzeug-Commands, die man einmal im
Quartal tippt, bekommen stattdessen eine Zeile in
[Overview.md](./Overview.md).
