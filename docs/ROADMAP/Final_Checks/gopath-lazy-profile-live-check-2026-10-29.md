# gopath.nvim — VeryLazy-Messung mit UI (Stand 2026-10-29)

Task `gopath.nvim/lazy-profile-cache-measure`. Rest aus `gopath.nvim/cache-load-from-disk-lazy`
(done, `gopath.nvim@e0a6412`): der Akzeptanzpunkt "mit UI gemessen" ist offen, weil `VeryLazy`
headless nicht feuert. Headless gemessen auf TRI-70ZBFB4: `load_from_disk` kostet im Median 59 ms
(40 bis 64 ms) bei 26 427 Pfaden / 3,3 MB, die mtime-Prüfung 0,4 ms. Ziel: wie viel die
VeryLazy-Welle durch `e0a6412` kleiner wurde. Ist der Abschnitt durch, die Task mit `done` schließen.

**Vorher:** Maschine notieren (Rechnername: ______), gopath.nvim ist unter `$REPOS_DIR/gopath.nvim`
ausgecheckt und sauber (`git -C "$REPOS_DIR/gopath.nvim" status` ohne Änderungen: der Vergleich
wechselt den Commit). Pfadzahl des Caches: ______ (Wert aus gopath-Cache/`:checkhealth gopath`,
Befehl in `gopath.nvim/docs` nachsehen, falls unklar). Messen ohne weitere Last auf der Maschine.

## 1. Messung mit dem Fix (`main`)

- [ ] `git -C "$REPOS_DIR/gopath.nvim" switch main` (Stand mit `e0a6412`), Neovim normal starten
- [ ] Einige Sekunden warten, dann `:Lazy profile`: den Wert von `gopath.nvim` unter `VeryLazy`
      notieren. Lauf 1: ______ ms
- [ ] Neovim neu starten, gleich messen. Lauf 2: ______ ms
- [ ] Noch einmal. Lauf 3: ______ ms

## 2. Vergleich ohne den Fix (`e0a6412~1`)

- [ ] `git -C "$REPOS_DIR/gopath.nvim" switch --detach e0a6412~1`, Neovim neu starten
- [ ] Gleich messen (wie oben, zwei- bis dreimal): Lauf 1 ______ ms, Lauf 2 ______ ms, Lauf 3 ______ ms
- [ ] **Danach unbedingt zurück:** `git -C "$REPOS_DIR/gopath.nvim" switch main`; prüfen mit
      `git -C "$REPOS_DIR/gopath.nvim" branch --show-current` (muss `main` sein, nicht detached)

## 3. Festhalten

- [ ] Beide Werte (mit/ohne Fix) mit Rechnername und Pfadzahl in den Notizen der erledigten Task
      `cache-load-from-disk-lazy` (Backlog) festhalten
- [ ] Erwartung zum Gegenlesen: Unterschied in der Größenordnung der headless gemessenen 40 bis
      60 ms; weicht die Messung stark ab (z. B. < 10 ms), als Notiz festhalten, kein Bug an sich

### Falls rot

Falls nach dem Vergleich der Repo-Stand nicht `main` ist oder `git switch` wegen lokaler
Änderungen scheitert: nichts erzwingen, Zustand notieren. Streuung zwischen den Läufen > 30 %:
weitere Läufe machen oder Hintergrundlast prüfen.

**Danach:** Task `gopath.nvim/lazy-profile-cache-measure` mit `done` schließen.

---

## Befunde

-
