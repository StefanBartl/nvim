# Finishing Task for `lib.nvim`-related

## Aufgabe

Alle Plugins analysieren auf:
  - Module im Plugin, dass sich für die `lib.nvim` anbieten könnte. Dieses Modul / Funkltion dann mit absoluten pfad und Zeile in die Datei:  `nvim/docs/ROADMAP/personal/FINISH/lib_NEW_MODULES.md`. Wir können dann später diese Datei analysieren und entschieden, ob wior das tatsächlich machen
  - Module, die durch Module der `lib.nvim` ersetzt werden sollen. Diese in die Datei `nvim/docs/ROADMAP/personal/FINISH/replace_moduls.md` schreiben


## Erledigt

Analysiert am 2026-07-14 per Multi-Agent-Scan; Ergebnisse in `lib_NEW_MODULES.md` und
`replace_moduls.md`. `filetreepicker.nvim` und `mygrep.nvim` sind in `plugins/personal/init.lua`
auskommentiert und liegen nicht unter `E:\repos` — konnten daher nicht analysiert werden.

|          Repo           | Status |
| ------------------------ | ------ |
|   `/buffer-ctx.nvim`    | ✅ |
|     `/cascade.nvim`     | ✅ |
| `/color_my_ascii.nvim`  | ✅ |
|    `/debugging.nvim`    | ✅ |
|      `/diff.nvim`       | ✅ |
|     `/emojis.nvim`      | ✅ |
|     `/fileops.nvim`     | ✅ |
|    `/filetree.nvim`     | ✅ |
| `/filetreepicker.nvim`  | ⚠️ nicht vorhanden (nicht geklont, in config auskommentiert) |
|  `/github_stats.nvim`   | ✅ |
|     `/gopath.nvim`      | ✅ |
|    `/language.nvim`     | ✅ |
|    `/learn-cli.nvim`    | ✅ |
|       `/lib.nvim`       | — (Ziel-Repo) |
|    `/markdown.nvim`     | ✅ |
|     `/mdview.nvim`      | ✅ |
|     `/migrate.nvim`     | ✅ |
|     `/mygrep.nvim`      | ⚠️ nicht vorhanden (nicht geklont, in config auskommentiert) |
|     `/nvim-cmdlog`      | ✅ |
|   `/nvim-containers`    | ✅ |
|      `/open.nvim`       | ✅ |
|     `/pdfport.nvim`     | ✅ |
|     `/pickers.nvim`     | ✅ |
| `/project-insight.nvim` | ✅ |
|   `/recommender.nvim`   | ✅ |
|    `/replacer.nvim`     | ✅ |
|    `/reposcope.nvim`    | ✅ |

---

