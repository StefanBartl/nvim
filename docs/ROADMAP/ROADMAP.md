# Roadmap
leader np / leader pf sind vertauscht  fileops.nvim

## Table of content

  - [cdx](#cdx)
  - [Misc](#misc)
  - [true check](#true-check)
    - [Plugin-Liste](#plugin-liste)

---

## cdx

| Account  | Week Reset Date | Actual/Insgesamt  |    Sub Bis    | Next 5h Reset |
| -------- | --------------- | ----------------- | ------------- | ------------- |
| **main** |   Fr., 11:00    |    60% /  27%     |   ~ 27. Sep   |       -       |
| **dev**  |   Sa., 22:00    |     0% /  0%      |    03. Sep    |       –       |
| **free** |   So., 09:00    |     0% /  0%      | 21. Juli 2027 |       –       |
| **work** |   Sa., 06:00    |     0% /  0%      |   20. Sept    |       –       |

never start more than 3 agents simultaneously; if more are needed, run multiple rounds of up to 3 agents each
antwortet immer auf Deutsch; im Quellcode (Code und Kommentare usw.) immer Englisch verwenden

---

## Misc


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

Ein Freund von mir, mitdem ich gemiensam nvim gelernt habe, hat ~ 30 nvim (+ ein natives docmap-desktop) plugins geschrieben und mir angeboten, dass ich alle üebrhnehmen kann. ich bin daran interessiert, will aber zuerst wissen, wie die codeualität ist, inahltlich ist mir aklles klar, also was die plugins machen, aber ich will keinen schlechten codebase übernehmen. kannst du die plugins analysieren und diese einschätzug machen. bitte ehrlich, keine honig ums maul oder so. ich will wissen, was gut ist, was außergewöhnlich ist (gu t als auch schlecht) was schlecht ist, wo noch viel arbeit rein gesteckt werden muss, overall zustand
Ich hoffe, du kannst das trotzdem so effizient managen, dass dies keine mega aufgabe wird, dass doll es nä,lich auh nicht sein, leider ist mir klar ds das konterkariert meine wüsnche. ckch denke, du must da einen goldenen Zwischenweg finden.

---

### Plugin-Liste

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

