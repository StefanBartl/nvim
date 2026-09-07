# Roadmap für meine `.nvim` Plugins + `nvim-config`

## TOP interessant gerade

- [ ] ai: mit slaude code die beste für den rechner lokale llm installieren, soll ein paar modelle auspropoeren,  vpn hängen nicht offen ins netz, opencode usw / ollame alternativen verwenden: https://www.youtube.com/watch?v=M1j_uRqKMKI
    Wichrig: genau lernen, wie da sfunkitnert, llm, auch wuantisierung usw... graka _> iwe aerbeiten di egnau, ram upgrde treiber erstllen usw....

- [ ] TAKT -> aai impllementierung von anfang an mitbauen

- [ ] docmap-desktop - aber für tosca

---

## `nvim-config`


---

## `myplugins`

### `filetree.nvim`

- [ ] handle guard wegen "nur auf einer seite aufmachen" -> wenn ich filetree links offen habe `M-l`, dann auf einen Buffer in der tableitse mit der mausklicke, öffnet sich der filetree sofort rechts neu; Genau das sollte ja nicht  passieren, vor allem nicht wenn default open für filetree auf links gesetzt iost (was normalerweoiße bei mir gesetzt sein sollte -> checken!)

- [ ] update von referenzen (`x`, `p`, `m`, ...): in freitext pfaden wie ../Test/Tester.md wir d momentan nicht updatet. eventuell mit `gopath.nvim` zusammenarbeiten?

---

### `pickers.nvim`

- [ ] in picker wie :RepoFiles oder leader ff - eigentlich generell für pickers.nvim - Cheatheet `?` aber rein nur mit ? geht das nicht, das wprde nur ? in die prompt einfügen, daher vl `C-?` wenn das geht. das solte dann auch in der picker ui stehen
  - [ ] ![screesnhot pciker ui](./assets/ROADMAP-1788781968.png) man sieht in dem screenshot, dass in der titellsete CWD > f h stzehet, awarum? was bedeutet das?

---

## Plugin-Liste

Hier die Liste meiner Plugins - du findest sie unter `$REPOS_DIR\repos` - und du hast Zugriff darauf:

buffer-ctx.nvim
cascade.nvim
casedesk.nvim
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
hover.nvim
images.nvim
insights.nvim
language.nvim
lib.nvim
lsp.nvim
markdown.nvim
mdview.nvim
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

