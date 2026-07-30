# `pickers.nvim`

- [x] `<S-CR>` / `<C-o>` (open_background) reagierten nicht: die Keys wurden ausschließlich ins **List-Window** gemerged (`entry_actions.adapters.snacks.get_keys()` → `win.list.keys`), ein snacks-Picker startet aber mit Fokus im **Input-Prompt**. Das Mapping war beim Tippen also unerreichbar und der Key fiel auf snacks' `confirm` durch → Datei öffnete normal + Picker schloss. Snacks' eigene Defaults binden `<CR>` deshalb in beiden Fenstern (`snacks/picker/config/defaults.lua`: input `{ "confirm", mode = { "n", "i" } }` + list `"confirm"`).
  Fix: neues `get_input_keys()` in [pickers.nvim/entry_actions/adapters/snacks.lua](../../../../../repos/pickers.nvim/lua/pickers/entry_actions/adapters/snacks.lua) (mode-qualifizierte Form, da das Input-Window i+n braucht — das List-Window ist normal-mode-only und behält die Bare-String-Form), gemerged in [config/snacks/picker/init.lua](../../../lua/config/snacks/picker/init.lua).
  Nebenbei ergänzt: `pcall`-Guard um `entry_actions()` + explizite `dependencies = { "StefanBartl/pickers.nvim" }` auf dem snacks-Spec ([plugins/snacks.lua](../../../lua/plugins/snacks.lua)). War *nicht* die Ursache (Ladereihenfolge war schon korrekt), aber verhindert, dass ein fehlgeschlagener `require` die komplette Picker-Config still verschluckt.
  Ein Lib-Modul für "open in background" existiert bereits (`lib.nvim/buffer/open_background.lua`) und wird von pickers.nvim + `lazygit/actions/badd.lua` geteilt — keine neue Abstraktion nötig.

---

