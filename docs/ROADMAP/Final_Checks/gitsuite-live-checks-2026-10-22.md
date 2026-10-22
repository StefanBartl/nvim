# gitsuite.nvim — Live-Checks (Stand 2026-10-22)

Was in gitsuite.nvim gebaut und headless mit Specs abgedeckt ist, aber nur in einer echten Sitzung
geprüft werden kann: echtes Netz, echter `:Lazy sync`, echte Klone, echte Farben. Jeder Abschnitt
gehört zu einer Task im `tasks-vault` (Area `gitsuite.nvim`); ist ein Abschnitt durch, die Task mit
`done` schließen (oder mir Bescheid geben). Ein Befund: unter "Befunde" eine Zeile, ich mache daraus
eine `kind: bug`-Task.

**Vorher:** gitsuite.nvim und lib.nvim aktuell (`:Lazy update gitsuite.nvim lib.nvim`, Stand
mindestens `gitsuite.nvim@8cdcd02`, `lib.nvim@e0a39f4`), Neovim neu starten, `:checkhealth gitsuite`
ohne Fehler.

---

## 1. `:Git dashboard`: fertige Repos bedienen, während `gf` läuft — offen

Task `gitsuite.nvim/dashboard-act-during-bulk-fetch-live-check`. Code: `gitsuite.nvim@48ea4d6`
(Sperre pro Repo), `@8081052` (`gf` holt jetzt `dashboard.fetch_jobs` = 4 Repos gleichzeitig).

```vim
:Git dashboard $REPOS_DIR
```

- [ ] `gf`, bestätigen: noch nicht geholte Zeilen zeigen `· fetch queued`, laufende `⟳ fetch...`
      (jetzt bis zu **vier** gleichzeitig), der Titel zählt mit (`fetch 4/12`)
- [ ] Auf einer schon fertigen Zeile `P` (oder `f`): läuft sofort, der Bulk-Fetch läuft weiter
- [ ] Auf einer wartenden oder laufenden Zeile `P`: eine klare Meldung, keine Aktion
- [ ] Ein fehlgeschlagenes Repo (z. B. ohne Netz zu seinem Host) zeigt `✗ fetch failed`; die
      Schlussmeldung nennt die Fehler; danach ist die Anzeige wieder normal
- [ ] Gefühlt schneller als vorher? Optional zum Vergleich in `setup()`
      `dashboard = { fetch_jobs = 1 }` setzen, `gf` stoppen, dann wieder 4 (Default)

---

## 2. `:Lazy sync`-Hook: Toast nach dem Sync — offen

Task `gitsuite.nvim/plugins-lazy-sync-hook-live-check`. Code: `gitsuite.nvim@c219283`,
Config `nvim-config@28fa91aa`.

- [ ] In der gitsuite-Spec (`lua/plugins/personal/specs/project.lua`) `plugins.after_sync = "toast"`
      setzen (oder nur zum Testen, danach wieder `"off"`)
- [ ] Neovim frisch starten, **ohne** vorher eine Datei zu öffnen oder `:Git` aufzurufen
      (gitsuite ist dann noch nicht geladen), `:Lazy sync`
- [ ] Nach dem Sync erscheint genau **ein** Toast „plugins: N of M updated, K commits ->
      :Git plugins report --last“ (bzw. „the sync updated nothing“); der Fokus bleibt im Lazy-Fenster
- [ ] `:checkhealth gitsuite` zeigt „lazy integration: toast (listening on User LazySync)“
- [ ] `:Git plugins report --last` zeigt den gespeicherten Report — **neu:** im Report-Tab (Abschnitt 4)
- [ ] Optional `after_sync = "open"`: nach einem Sync mit Updates öffnet sich der Report-Tab

Kommt kein Toast, obwohl gitsuite geladen ist: Lazy feuert das Event vermutlich nicht in die
benannte Gruppe nach. Bitte als Befund notieren.

---

## 3. GS-30: die manuelle Checkliste — offen

Task `gitsuite.nvim/live-test-checklist`. Die Checkliste selbst steht im Vault:
`tasks-vault/ALL/manual-test-checklists/gitsuite.md` (Abschnitte 1–7: `:Git browse` gegen GitLab und
Codeberg, `:Git ui lazygit` mit `nvr`-Brücke unter Windows, der Key-Race nach `<leader>lg`, ein echter
Merge-Konflikt und `replacer --changed`, die vier Diff-Tasten, `:Git dashboard`,
`:Git dashboard update`).

- [ ] Checkliste einmal durchgegangen, Befunde dort unter "Findings"
- [ ] Ergebnis der `nvr`-Brücke: Satz in `gitsuite.nvim/docs/cross-platform.md` ("nvr bridge")
      ersetzt "has not yet been verified" (kann ich nach deinem Lauf schreiben)

**Neu seit der Checkliste**, bitte im selben Lauf mitnehmen:

- [ ] `:Git ui lazygit` ohne terminal.nvim läuft jetzt über `lib.nvim.terminal.spawn`
      (`gitsuite.nvim@9e76786`): Float öffnet, `q` in lazygit schließt ihn, kein leerer Puffer bleibt
      zurück (`:ls!`)

---

## 4. Der Report-Tab von `:Git plugins` — offen

Task `gitsuite.nvim/plugins-report-ui-live-check`. Code: `gitsuite.nvim@015747b` … `@6d15390`, Fix
`@8cdcd02`. Headless und in der Test-TUI (120×30) geprüft; Farben und echte Klone nicht.

```vim
:Git plugins report
```

- [ ] Ein eigener Tab öffnet sich: links (ab 140 Spalten) bzw. oben die Liste, daneben bzw. darunter
      die Preview; oben die Legende (`<CR> open │ D digest │ …`)
- [ ] Erste Zeile ist die Zusammenfassung; Breaking-Plugins stehen oben, jeder Zustand mit Symbol
      **und** Wort (`! breaking`, `↑ updated`, `✗ error`)
- [ ] Farben: Breaking rot, `updated` grün, Hashes als Zahl, Gedimmtes grau — passend zu deinem
      Farbschema; nach `:colorscheme <anderes>` noch farbig
- [ ] `<CR>` auf einem Plugin: Detail mit BREAKING / GROUPED / OTHER; mit `j` über die Commits:
      Preview zeigt Nachricht und die geänderten Dateien (bei lazy-Klonen **ohne** `+/-`-Zahlen,
      mit dem Hinweis „blobless“ — das ist so gewollt); rechts in der Legende steht die Stelle
      des Commits im Update, `c 17/86` (`gitsuite.nvim@5d78497`; fehlt bei Plugins, deren Liste
      nicht das ganze Update ist)
- [ ] `D`: Breaking-Digest über alle Plugins; `]b` springt zum nächsten ungesehenen
- [ ] `m` auf einem Commit, dann auf einem Plugin: „unseen“-Zähler sinkt; `q`, `:Git plugins`:
      Marken sind noch da, Cursor steht wieder auf derselben Zeile
- [ ] `o` auf einem Commit: Browser öffnet die Commit-Seite; auf einem Plugin die Compare-Seite
- [ ] `S`: Status-Popup des Klons; `C`: CHANGELOG im vorigen Tab, schreibgeschützt;
      `Q`: Breaking-Commits in der Quickfix-Liste (im vorigen Tab); `F`: Picker springt zu Commit
- [ ] `?`: alle Tasten, nichts abgeschnitten; `O`: Menü der Aktionen
- [ ] `:tabonly` in einem anderen Tab, dann `:Git plugins`: Tab kommt wieder, gleiche Sicht
- [ ] Neovim neu starten, `:Git plugins`: zeigt den letzten gespeicherten Report ohne Scan

---

## Befunde

<!-- eine Zeile pro Befund: Abschnitt, was passiert ist, was erwartet war -->
