# Peronal Plugins - ROADMAP - MISC

## CDX Task

- [ ] Updaten die docs:
  - `docs/**`
    - `doc/**.txt` vimdoc
      - auch C:\Users\bartl\AppData\Local\nvim\docs\NOTES\PersonelPlugins\BINDINGS wenn nötig
- [ ] Comitte und pushe auf main!

--

## Übergreifende Befunde aus `MyPlugin-Notes` (Analyse 2026-08-08)

Quelle: `E:/repos/Notes/MyPlugin-Notes/`. Die plugin-spezifischen Punkte stehen
in den jeweiligen Dateien; hier steht nur, was **mehr als ein Plugin** betrifft.

---

### 1. `vim.system()`/`uv.spawn()` erbt die Shell-Umgebung nicht

Der wertvollste Befund des gesamten Notizbestands, aufgeschrieben in
`reposcope/reposcope-Notes.md`, aber allgemeingültig:

Ein Subprozess aus Neovim bekommt **nur explizit übergebene** Umgebungsvariablen.
Keine `.zshrc`, kein `.profile`, kein OS-Keyring. Deshalb schlägt `gh api` aus
Neovim fehl, obwohl `gh auth status` in der Shell einen gültigen Login meldet —
der Token liegt im Keyring, und der ist im neuen Prozesskontext nicht aktiv.

Gegenprobe, die es festnagelt: `env -i gh api /search/repositories?q=neovim`
scheitert in der Shell mit derselben Meldung.

Betrifft heute mindestens `reposcope.nvim` (gh/curl/wget), `github_stats.nvim`,
`pdfport.nvim` (pandoc/pdftotext/ollama), `sandbox.nvim` (docker/podman/nerdctl),
`replacer.nvim` (ripgrep), `pickers.nvim` (fd/rg).

- [ ] Als Regel in `All/Checklists.md` aufnehmen: Wer ein CLI spawnt, das
      Authentifizierung oder PATH-Zustand braucht, muss `env` explizit füllen.
- [ ] Prüfen, ob `lib.nvim.cross.run` dafür bereits einen Helfer hat — wenn
      nicht, gehört er dorthin und nicht in jedes Plugin einzeln.

**Zweiter, verwandter Befund** (schon in `open.nvim.md` festgehalten, hier als
Querverweis): `jobstart(argv, { detach = true })` führt auf Windows **kein
Konsolenprogramm** aus — libuvs `DETACHED_PROCESS` lässt das Kind ohne
Standard-Handles zurück, powershell.exe beendet sich vor der ersten Anweisung,
und die Job-ID sieht trotzdem nach Erfolg aus. Beide Fallen zusammen erklären
einen grossen Teil der „mal geht's, mal nicht"-Bugs.

**Aufwand:** Quick Win (Regel + Prüfung), Mittel (falls ein `lib.nvim`-Helfer entsteht)
**Nutzen:** hoch.

ZUsatztask: in e:\repos\WKDBook gitb es ein ekdbook-beovim: DOrt diesse ekrenntnis als ausfphörocj erklärenden markdown artikel implemenbtieren

### 2. API-Keys: nie das Plugin verwalten lassen

Aus `nvim-typepilot/typepilot.md`: Keys kommen aus der Umgebung, das Plugin
speichert nichts und gibt nichts aus. `:checkhealth` meldet höchstens
*vorhanden ja/nein* — nie den Wert.

- [ ] Als Regel in `All/Checklists.md`, verbindlich für alle Plugins mit
      API-Zugriff. Siehe `IDEAS/typepilot.nvim.md`.

Direkt daran hängt ein Punkt aus `cmdlog.nvim.md`: cmdlog schreibt heute jeden
`:`-Befehl mit — inklusive `:!curl -H "Authorization: Bearer …"` — im Klartext
nach `stdpath("data")`. Ein `redact_patterns`-Filter fehlt.

**Aufwand:** Quick Win
**Nutzen:** hoch.

### 3. Videos in READMEs — das Verfahren steht fest

`VideosinReadmes.md` klärt eine Frage, die sonst bei jedem Release neu gestellt
wird:

- GitHub rendert **kein** `<video>`-Tag in READMEs (Sicherheitsgründe).
- Funktionierender Weg: MP4 in einen Dummy-Issue hochladen, die erzeugte
  `user-images.githubusercontent.com`-URL kopieren und **als nackten Link** in
  die README setzen — nicht als `[Text](URL)`, nicht als Markdown-Bild. GitHub
  baut daraus selbst eine Inline-Vorschau.
- Alternative: GIF unter `/assets/` (wird direkt angezeigt).

Betrifft konkret offene Punkte: Demo-Video für `pickers.nvim`/MyGrep (steht in
`TODOS.md`), GIFs/Screenshots für `nvim-slots`, das vorhandene
`cmdlog/Cmdlog-Picker-Demo/` (MP4 plus neun Screenshots liegen fertig da).

- [ ] Als Absatz in die README-Templates unter
      `MyPlugin-Notes/README-TEMPLATES/` übernehmen, damit es nicht in einer
      losen Notiz bleibt.
- [ ] Die bereits aufgenommene cmdlog-Demo tatsächlich einbinden.

**Aufwand:** Quick Win
**Nutzen:** mittel-hoch — Material liegt fertig herum und wird nicht genutzt.

### 4. Quickfix als gemeinsamer Ausgang

`PluginsDoc/QuickfixList.md` beschreibt den `:cdo`-Workflow: Trefferliste →
Quickfix → Massenbearbeitung.

Mehrere eigene Plugins produzieren Trefferlisten (`pickers.nvim`,
`replacer.nvim` — hat mit `export.lua` bereits einen Quickfix-Export,
`documentation.nvim`, `markdown.nvim`s Link-Diagnostics). Ein einheitlicher
Quickfix-Ausgang macht sie untereinander kombinierbar, ohne dass sie
voneinander wissen müssen.

- [ ] Prüfen, welche Plugins den Ausgang schon haben und wo er fehlt —
      insbesondere der Marks-Punkt in `pickers.nvim.md` sollte direkt dorthin
      münden.

**Aufwand:** Quick Win je Plugin
**Nutzen:** mittel-hoch.

### 5. Die Config-/Options-Regel ist ausformuliert

`cmdlog/OPTIONS.CONFIG.md` hält das Muster fest, das inzwischen überall
angewendet wird: eine zentrale `default_config`, `M.options` immer als
`vim.tbl_deep_extend("force", {}, defaults, user or {})`, Zugriff ausschliesslich
über `config.options.X`, neue Optionen nur in den Defaults ergänzen — `setup()`
bleibt unverändert.

Der Bestand folgt dem bereits (`config/DEFAULTS.lua` + `config/init.lua` in
praktisch jedem Repo).

- [ ] Nichts zu tun. Der Text ist aber die beste vorhandene Begründung dafür und
      gehört in die Checklisten übernommen, statt in den Plugin-Notizen zu liegen.

**Aufwand:** Quick Win. **Nutzen:** niedrig (rein dokumentarisch).

