# Todo-Comments — User-Commands

Alle fünf Commands sind **[default]** — `todo-comments.nvim` bringt sie in
seiner eigenen `plugin/todo.vim` mit, als Vimscript-`command!`, nicht über die
Lua-API. Diese Config registriert keinen einzigen eigenen Todo-Command; ihr
Zugang zu denselben Daten läuft über den Snacks-Picker, siehe
[Keymaps/TodoComments.md](../Keymaps/TodoComments.md).

Das Plugin ist `lazy = false`
([lua/plugins/workflow.lua](../../../../../lua/plugins/workflow.lua)), die
Commands existieren also ab dem Start und ohne Trigger.

## [default] Aus `plugin/todo.vim`

Alle fünf nehmen `-nargs=*` und reichen die Argumente an die jeweilige Suche
durch (`keywords=TODO,FIX` filtert etwa auf zwei Keywords).

| Command | Wirkung | In dieser Config benutzbar? |
|---|---|---|
| `:TodoQuickFix` | `todo-comments.search.setqflist(<args>)` — Treffer in die Quickfix-Liste. | ja |
| `:TodoLocList` | `todo-comments.search.setloclist(<args>)` — Treffer in die Location-List des Fensters. | ja |
| `:TodoTelescope` | Ruft `:Telescope todo-comments todo` auf. | **nein** — Telescope ist in dieser Config nicht die Picker-Engine. |
| `:TodoFzfLua` | Ruft `require("todo-comments.fzf").todo()` auf. | nur, wenn `fzf-lua` geladen ist. |
| `:TodoTrouble` | Ruft `:Trouble todo` auf. | nur, wenn `trouble.nvim` geladen ist. |

`:TodoQuickFix` und `:TodoLocList` sind damit die beiden, die ohne jede
weitere Abhängigkeit funktionieren — sie brauchen nur `ripgrep`, das
todo-comments ohnehin für seine Suche voraussetzt.

## Warum diese Commands hier trotzdem selten vorkommen

Die zwei gebundenen Wege dieser Config (`<leader>ST`, `<leader>sT`) gehen
**nicht** über einen dieser Commands, sondern über
`snacks.picker.todo_comments(...)`. Der Unterschied ist nicht kosmetisch: der
Snacks-Weg kennt die projekteigene Keyword-Liste aus
[config/todo_comments/keywords](../../../../../lua/config/todo_comments/keywords/init.lua)
(`AUDIT`, `ROADMAP`, `REF`, `DEVONLY`, …), die Plugin-Commands nehmen die
Keywords aus `opts.keywords` des Setups — dieselbe Tabelle, aber über einen
anderen Pfad. Details in [Keymaps/TodoComments.md](../Keymaps/TodoComments.md).

## Herkunftsnotiz

Diese fünf Commands sind Vimscript, kein Lua. Für `:Bindings check` heißt das,
dass ihre Herkunft nicht aus dem Callback kommt, sondern aus der `script_id`
— eine Zahl, die zwischen zwei Sessions wechselt. Seit die Eigentümerspalte
sie über `vim.fn.getscriptinfo` zurück in einen Pfad auflöst, stehen
`:TodoFzfLua` und `:TodoLocList` im Bericht als `todo-comments.nvim` statt als
`vimscript script_id=19`, und genau das hat sie diesem Blatt zugeordnet.
