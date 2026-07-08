# `pickers.nvim`

- [ ] `telescope-selected-index` implementierung prüfen: Momentan passt weder die Indexierung sobald sich in der Prompt etwas tut noch oftmals die indexierung gleich beim start. ist es nciht möglich, nachdem die resultatsliste upgedatet aht (zb nahch einen keystroke in dre prompt), dass danach nochmal drüber gegangen und die nummerierung eingebetet wird mit einen kurzen debounce ... oder eine ganz andere möglichkeit, af die ich noch nict gedacht habe vielleicht?

---

stefan.bartl.work:

Ja, machbar — beide Scopes lassen sich technisch abbilden, aber mit unterschiedlichem Risiko:

- **Scope "nur pickers.nvim"**: einfach und sauber. Telescope- und fzf-lua-Aufrufe akzeptieren `history`/`--history` pro Call (nicht nur global in `setup()`), also kann `pickers.nvim` seine eigenen History-Dateien pro Engine-Call mitgeben — ganz ohne den globalen `telescope.setup()`/`fzf-lua.setup()` des Users anzufassen.
- **Scope "global" (auch außerhalb von pickers.nvim)**: bedeutet, dass `pickers.nvim` selbst `telescope.setup()`/`require("fzf-lua").setup()` mit-konfiguriert. Das ist reihenfolgeabhängig — je nachdem ob dein eigenes `config/telescope/init.lua` vor oder nach `pickers.setup()` läuft, gewinnt der eine oder andere. Sicherer Weg: pickers.nvim exportiert nur die fertigen History-Optionen als Funktion, die du selbst in deinen bestehenden `telescope.setup()`/`fzf-lua.setup()` einhängst — statt dass pickers.nvim im Hintergrund heimlich mit-`setup()`t.

**Kurzer Schlachtplan:**

1. `DEFAULTS.lua`: neue Config `history = { enabled = false, scope = "plugin"|"global", backend = "auto" }` (`auto` = SQLite via `telescope-smart-history` falls vorhanden, sonst file-basiert — analog zu deinem bestehenden `config/telescope/history` Modul).
2. Neues Modul `lua/pickers/history/init.lua`: löst Backend + Pfade auf (default unter `stdpath("data")/pickers.nvim/history/`), exportiert `telescope_opts()` und `fzf_history_path(kind)` — **getrennt pro Kind** (files/grep/repo-picker), was sogar ein Vorteil gegenüber deiner jetzigen fzf-Lösung wäre (dort ist es eine einzige gemeinsame Datei für alles).
3. `engines/telescope.lua` + `engines/fzf.lua`: wenn `cfg.history.enabled`, `call_opts.history` bzw. `fzf_opts["--history"]` aus Schritt 2 setzen (scope="plugin" — wirkt nur innerhalb pickers.nvim-Aufrufen).
4. `scope="global"`: zusätzlich `M.history.telescope_opts()` / `M.history.fzf_opts()` public exportieren, damit du sie selbst in deine bestehenden `config/telescope/init.lua` / `config/fzf/init.lua` einhängen kannst — kein automatisches Monkey-Patching von pickers.nvim aus.
5. Tests in `pickers_spec.lua`: Pfad-/Backend-Auflösung (reine Funktionen, kein echtes Telescope/fzf nötig).
6. Docs (`README.md`, `BINDINGS.md`, `CHEATSHEET.md`) um den neuen `history`-Config-Block ergänzen.

Größte Designentscheidung vorab: soll `scope="plugin"` der Default sein (sicher, isoliert, aber dann zwei parallele History-Systeme falls du fzf/telescope auch direkt nutzt), oder soll pickers.nvim von Anfang an nur die Helper-Funktionen anbieten und du bindest sie in deine bestehende `history`-Config ein (dann automatisch "global", ohne Duplikat)? Ich würde zu Letzterem raten, da du ja bereits ein funktionierendes History-Setup hast, das nur wiederverwendet statt verdoppelt werden sollte.

Alte Hintergrund-Suche ist durchgelaufen, aber inhaltlich überholt — die relevanten Infos (History-Setup, `lib.nvim`-Pfad) habe ich zwischenzeitlich schon direkt gefunden und verwendet. Kein weiterer Handlungsbedarf dadurch.

Auch diese alte Hintergrundsuche ist inzwischen irrelevant — `lib.nvim`/`usercmd` habe ich bereits direkt unter [E:\repos\lib.nvim](E:\repos\lib.nvim) gefunden und verifiziert. Kein weiterer Handlungsbedarf.
