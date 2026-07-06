# `pickers.nvim`

1. Haben alle picker (telescope, fzf-lua) history usw.. ?
2. selected index: wenn in der prompt ewas getippt wird, muss der index aktualisert werden, weil sich die items in der reihenfolge ändern
3. `RepoFiles`: die Möglchkeit, ein repo hier gleich direlt anzugeben, also `:RepoFiles lib.nvim` und dann übersrpingt er den ersten picker und geht gleich in eine find files in lib.nvim ; super wäre es, wenn es möglich wsäre, dass es eine dynamische autocomüpletion gibt, also wenn ich im REPOS_DIR ordner lib.nvim undf markdown.nvim habe, dass dann in `:RepoFiles ....` wenn man auf tab geht dies zwei repos autocompleted werden, wenn dann ein drittes dazu kommt, soll auch das sderinnen sein. ich weiß aber nicht, ob das möglich ist, das wäre nr ein zusätzliches feature.... Dasselbe aus diesem Punkt gilt für `:RepoGrep`



- [ ] `telescope-selected-index` implementierung prüfen: Momentan passt weder die Indexierung sobald sich in der Prompt etwas tut noch oftmals die indexierung gleich beim start. ist es nciht möglich, nachdem die resultatsliste upgedatet aht (zb nahch einen keystroke in dre prompt), dass danach nochmal drüber gegangen und die nummerierung eingebetet wird mit einen kurzen debounce ... oder eine ganz andere möglichkeit, af die ich noch nict gedacht habe vielleicht?

---

