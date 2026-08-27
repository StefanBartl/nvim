# Todo-Comments — Keymaps

Registriert als `keys`-Tabelle direkt im Lazy-Spec in
[lua/plugins/workflow.lua](../../../../../lua/plugins/workflow.lua) — kein
eigenes `bindings.mappings.*`-Modul, keine which-key-Spec-Umleitung wie bei
Harpoon. Lazy.nvim setzt die Maps selbst (native `keys`-Lazy-Loading), nicht
`lib.nvim.bindings.keymap`.

`todo-comments.nvim` liefert laut README **keine** Default-Keymaps aus — nur
die Commands `:TodoQuickFix`, `:TodoTrouble`, `:TodoTelescope` und die API
`require("todo-comments").jump_next()` / `.jump_prev()` (im README als
Beispiel für optionale `]t`/`[t`-Maps gezeigt, aber ohne eigene
Standardbindung). Alles unten ist folglich **[custom]** — inklusive der
Tatsache, *dass* überhaupt etwas gebunden ist.

---

## Globale Keymaps

| Mapping | Aktion | Status |
|---|---|---|
| `<leader>ST` | Snacks-Picker `todo_comments()` — alle Todo-Kommentare mit den Plugin-Default-Keywords | [custom] |
| `<leader>sT` | Snacks-Picker `todo_comments({ keywords = KEYWORDS })` — explizit mit der projekteigenen Keyword-Liste aus [config/todo_comments/keywords/init.lua](../../../../../lua/config/todo_comments/keywords/init.lua) gefiltert | [custom] |

Beide Maps rufen **nicht** die Plugin-eigenen Commands (`:TodoTelescope` /
`:TodoQuickFix`) auf, sondern gehen über `snacks.picker.todo_comments(...)` —
diese Config nutzt `folke/snacks.nvim` als Picker-Frontend anstelle des in
todo-comments eingebauten Telescope-/Trouble-/Quickfix-Wegs. Ist Snacks nicht
geladen, wird nur eine Warnung genotified (`notify.warn(...)`), kein Fallback
auf `:TodoTelescope`.

Der Unterschied zwischen den beiden Maps liegt einzig in der Keyword-Quelle:
`<leader>ST` nimmt, was Snacks/todo-comments intern als Default kennt,
`<leader>sT` erzwingt explizit die projekteigene, erweiterte Keyword-Tabelle
(inkl. `AUDIT`, `ROADMAP`, `REF`, `DEVONLY` etc., siehe
[config/todo_comments/keywords/init.lua](../../../../../lua/config/todo_comments/keywords/init.lua)).

---

## Nicht gebunden (nur per Command erreichbar, Plugin-Default)

`:TodoQuickFix`, `:TodoTrouble`, `:TodoTelescope` — von `todo-comments.nvim`
selbst bereitgestellt, in dieser Config **ohne** Keymap-Entsprechung. Ebenso
ist `require("todo-comments").jump_next()`/`jump_prev()` (README-Beispiel für
`]t`/`[t`) hier **nicht** gebunden — im Repo gibt es an keiner Stelle ein `]t`
oder `[t` für Todo-Comments (die einzigen `]t`/`[t`-Treffer im Code sind
`noop`-Overrides in neo-tree-Fenstern und gehören nicht zu diesem Plugin).
