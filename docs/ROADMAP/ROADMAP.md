# Roadmap
leader np / leader pf sind vertauscht  fileops.nvim

## Table of content

  - [cdx](#cdx)
  - [Lists](#lists)
  - [Misc](#misc)
  - [true check](#true-check)
  - [Plugin-Liste](#plugin-liste)

---

## cdx

| Account  |    Sub Bis    | Week Reset Date |  Next 5h Reset  | Actual/Insgesamt |
| -------- | ------------- | --------------- | --------------- | ---------------- |
| **main** |   ~ 27. Sep   |   Fr., 11:00    |     13:30       |    19% / 49%     |
| **dev**  |    03. Sep    |   Sa., 22:00    |     14:00       |    53% / 15%     |
| **work** |   20. Sept    |   Sa., 06:00    |     02:50       |    91% / 27%     |
| **free** | 21. Juli 2027 |   So., 09:00    |     --:--       |    --% / -5%     |

never start more than 3 agents simultaneously; if more are needed, run multiple rounds of up to 3 agents each
antwortet immer auf Deutsch; im Quellcode (Code und Kommentare usw.) immer Englisch verwenden

---

## Lists

- [ ] C:/Users/StefanBartl/AppData/Local/nvim/docs/ROADMAP/personal/All/FINISH/MERGED.md
- [ ] C:/Users/StefanBartl/AppData/Local/nvim/docs/ROADMAP/personal/All/PLUGIN_ROADMAPS.md
- [ ] C:/Users/StefanBartl/AppData/Local/nvim/docs/ROADMAP/personal/All/Diagnostics.md
  - [ ]  [`deprecated` (23) -- veraltete Neovim-APIs](#deprecated-23-veraltete-neovim-apis)
  -> das zeigt gut an, was in `migrate.nvim` implementiert werden soll.
    Zusatz Feature: Alle im `h deprecated` implementieren
    - scope `path/cwd` -> damit könnte man dann ein gesamtes repo automatisch ent-deprecaten
    - cool wäre dann eine  Art picker mit den Treffern und im Preview window wird angezeigt, wie es updatet werden soll, dann lann man treffer für treffer entschiedne ob das eh passt. ein `m` - mark feautre wie in `filetree.nvim` wäre ideal um mehrere zu markieren die updatet werden sollen
    - ein test-sheet mit absichtlichen Fehlern, um z utesten und zu belegen, dass dass Plugin funktioniert.
- [ ] C:/Users/StefanBartl/AppData/Local/nvim/docs/ROADMAP/personal/All/WQ.md

---

## Misc

- [ ] `lib.nvim`-`hover` Modul braucht einen `quit` keymap. Manchmal möchte ich kein hover sehen, muss aber auf dem Pfad bleiben... da wäre es gut einen qiut, oder eigentich besser einen toggle zu haben, mit dem ich das hover für den spzifischen pfad zu image/pdf/textfile/usw.. ausschalten kann und wenn ich ihn wieder haben wilk an schalten kann. bzw.: Eigentlich gar nicht für "das eine", sondern auch ein genereeller toggle könnte reichen oder sinnvoll sein, weil: wenn ich sage "ich will gerade kein over sehen" dreh ich ab (für alle), dann wenn wich wieder haben will auf - da ja immer nur ein hover zur selben zeit sein kann, kann es auch nicht sein "ah ichhab hove rabgedreht und will aber dort einen haben" - denn da nn muss ich dorthin hin mit dem cursor und einfach wieder ienschalten. siehst dudas auch so?
- [ ] Logo / Bild für repo (socal prview card aber auch images.nvim hover)
- [ ] `:Bindings search` verbessern, andere optionen durchgehen

- [ ] Anticheat knacken
- [ ] alle keymaps der nvim config durcsheen ob die wirlich gebraucht werden
- [ ] Github Stats auswerten / backupen
- [ ] ai: mit slaude code die beste für den rechner lokale llm installieren, soll ein paar modelle auspropoeren,  vpn hängen nicht offen ins netz, opencode usw / ollame alternativen verwenden: https://www.youtube.com/watch?v=M1j_uRqKMKI
    Wichrig: genau lernen, wie da sfunkitnert, llm, auch wuantisierung usw... graka _> iwe aerbeiten di egnau, ram upgrde treiber erstllen usw....
- [ ] TAKT
- [ ] **mdview: live ansehen, wie Nicht-Markdown-Dateien aussehen.** `experimental.any_file = true`
  weitet die Vorschau von Markdown auf jede normale Textdatei aus; `.lua`/`.py`/`.sh` landen
  dann als hervorgehobene Code-Ansicht im Browser statt im Markdown-Renderer. Gebaut am
  2026-08-24, aber nie durch ein echtes Neovim gelaufen — nur Lua-Harness, Client-vitest und
  Standalone-Relay, und keiner der drei geht durch die Autocmd-Kette, die das Flag verändert.
  Checkliste mit den fünf Fällen (Rendern, proportionaler Scroll-Sync, Breadcrumbs auf
  `#`-Kommentarsprachen, Ausschluss von Terminal/Help/Quickfix/Log-Buffer, Regression mit Flag
  aus) plus vier Fixtures liegt in `C:/repos/mdview.nvim/TESTS/CHECK.md` unter
  *„`experimental.any_file` — release check"*. Ergebnis entscheidet, ob das Flag `experimental`
  verlieren kann.

---

## true check

Ein Freund von mir, mitdem ich gemiensam nvim gelernt habe, hat ~ 30 nvim (+ ein natives docmap-desktop) plugins geschrieben und mir angeboten, dass ich alle üebrhnehmen kann. ich bin daran interessiert, will aber zuerst wissen, wie die codequalität ist, inahltlich ist mir alles klar, also was die plugins machen, aber ich will keine schlechte codebase übernehmen. kannst du die plugins analysieren und diese einschätzug machen. bitte ehrlich, keine honig ums maul oder so. ich will wissen, was gut ist, was außergewöhnlich ist (gut als auch schlecht), was schlecht ist, wo noch viel arbeit rein gesteckt werden muss, overall zustand, usw...
  Ich hoffe, du kannst das trotzdem so effizient managen, dass dies keine mega aufgabe wird, dass soll es nämlich auch nicht sein, leider ist mir klar das dass ein wenig meine wünsche konterkariert. Ich denke, du must da einen goldenen Zwischenweg finden.
  Wenn dir Logikfehler, offensichtliche Bugs oder docs Probleme auffallen in einen Plugin, dann notiere diese gleich.

---

## Plugin-Liste

Hier die Liste meiner Plugins - du findest sie unter `c:\repos` bzw `e:\repos` - und du hast Zugriff darauf:

buffer-ctx.nvim
cascade.nvim
cmdlog.nvim
color_my_ascii.nvim
dap.nvim
debugging.nvim
diff.nvim
documentation.nvim
emojis.nvim
fileops.nvim
filetree.nvim
github_stats.nvim
gopath.nvim
images.nvim
insights.nvim
language.nvim
lib.nvim
lsp.nvim
markdown.nvim
mdview.nvim
migrate.nvim
open.nvim
pdfport.nvim
pickers.nvim
recommender.nvim
replacer.nvim
reposcope.nvim
runtime-analysis.nvim
sandbox.nvim
sessions.nvim
spotlight.nvim

und das native: docmap-desktop

---

