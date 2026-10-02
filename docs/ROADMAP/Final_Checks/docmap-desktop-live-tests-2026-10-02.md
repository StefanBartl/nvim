# docmap-desktop — Live-Test-Checkliste (Stand 2026-10-02)

Alles, was zu `v0.6.0` und zur Traffic-Integration (L11) gebaut ist, aber nie in einem echten
Fenster oder mit echten Daten lief. Gebaut und mit Fixtures bzw. `cargo test` (129 grün) und
`node --test` geprüft ist alles; was hier steht, kann keine Sitzung ohne deine Maschine, deine
GUI oder deinen GitHub-Token. Checkbox-Konvention: `- [ ]` offen, `- [x]` verifiziert. Bei jedem
Punkt eine Zeile `Notiz:` für Beobachtungen. Findet sich etwas, ist `v0.6.1` die billige Antwort.

Hintergrund: Plan und Entscheidungen in
`$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/docmap-desktop/` (`ROADMAP/PLAN.md`,
`Backlog/TASKS/docmap-desktop_HANDOVER.md`); Bau-Protokoll der Traffic-Integration in
`ALL/Backlog/FEATURES/github-stats-traffic-integration*.md`.

---

## Wie starte ich das?

Installer: <https://github.com/StefanBartl/docmap-desktop/releases/latest>
→ `docmap-desktop_0.6.0_x64-setup.exe`. **`v0.6.0` wurde am 2026-10-02 neu geschnitten.** Hast du
die erste Fassung schon installiert, jetzt neu installieren; die richtige erkennst du in
*Help → About* am Engine-Commit **`440bfb7`** (die alte hatte `4bd684e`).

---

## A1 — die installierte App durchklicken (`docs/RELEASING.md`)

- [ ] **Help → About** nennt Engine `440bfb7` und einen Build.
  Notiz:
- [ ] Ein Projekt ist wählbar, seine Karte lädt.
  Notiz:
- [ ] **Generate map** läuft, die Statuszeile meldet es.
  Notiz:
- [ ] **File → Settings…** öffnet, der Theme-Wechsel greift.
  Notiz:
- [ ] **Add from a parent folder** (z. B. `E:\repos`): Checkliste erscheint, Import läuft,
      bereits vorhandene Projekte werden gemeldet statt doppelt angelegt.
  Notiz:
- [ ] **View as matrix…**: Raster öffnet, Zelle = Aufrufstellen, der Tooltip nennt die Module.
  Notiz:

---

## A3 — Traffic (L11) gegen einen echten Fetch

Voraussetzung: in Neovim mit deinem Token `:GithubStats fetch`. Danach in der App.

**Die sieben Punkte der Ende-zu-Ende-Prüfung:**

- [ ] **Zwei Maschinen.** Fetch auf A, synchronisieren, B öffnen: Der Digest von B wird beim
      Start neu aufgebaut (nicht veraltet), und B hat im Intervall nicht erneut gefetcht.
  Notiz:
- [ ] **Plugin fehlt.** App und `documentation.nvim` verhalten sich wie vorher; kein Fehler,
      nichts Leeres gerendert.
  Notiz:
- [ ] **`ui.nvim` fehlt, Plugin da.** Die Sonde findet trotzdem `github_stats.digest`.
  Notiz:
- [ ] **Lazy-geladenes Plugin.** `soft_require.probe` lädt es; kein User-Command nötig.
  Notiz:
- [ ] **Überschriebenes `digest_dir`.** `root.json` am Standardort verweist darauf; App und
      Plugin finden es ohne Einstellung.
  Notiz:
- [ ] **Feindlicher Digest.** Fixture mit `<img onerror=…>` als Referrer, `../../etc/passwd` und
      `C:\Windows` als Pfaden, einer 3-MiB-Datei und `schema: 99`: Text ist inert, nichts
      außerhalb der Projektwurzel bekommt einen Link, die Datei wird mit Meldung abgelehnt.
  Notiz:
- [ ] **Privates Repo + Opt-out.** Für ein ausgeschlossenes Projekt wird nichts angezeigt, und in
      keinem exportierten Artefakt steht etwas davon.
  Notiz:

**Die Oberfläche dazu (nie in einem echten Fenster gesehen):**

- [ ] Seitenleiste: die Traffic-Zeile eines Projekts mit GitHub-Remote zeigt echte Zahlen.
  Notiz:
- [ ] Übersicht: 30-Tage-Zahl an den Zeilen, die welche haben; die Sortierung nach Traffic
      stimmt mit den Zahlen überein; ein Projekt ohne Remote zeigt nichts.
  Notiz:
- [ ] **Detaildialog** (Klick auf die Traffic-Zeile): Sparkline pro Serie über die ganze
      gespeicherte Spanne, Referrer, Top-10-Seiten. Mindestbreite der App: nichts abgeschnitten,
      kein horizontales Scrollen.
  Notiz:
- [ ] Eine Top-Seite, die im Projekt existiert, ist ein Link und öffnet die Datei in deinem
      Editor an der richtigen Stelle; eine, die es nicht gibt, bleibt Text.
  Notiz:
- [ ] **Look again** liest nach einem neuen Fetch die neuen Zahlen.
  Notiz:
- [ ] Opt-out an einem Projekt: Zeile und Dialog verschwinden sofort, ohne Neustart.
  Notiz:

**Die Härtungen, die erst im Review dazukamen:**

- [ ] **Ask Neovim** findet bei normaler Konfiguration den Ordner (Knopf in den Einstellungen).
  Notiz:
- [ ] **Ask Neovim, hängende Konfiguration:** in `init.lua` vorübergehend etwas Blockierendes
      (z. B. `vim.fn.input("x")`) einbauen. Der Knopf bricht nach ca. 30 s mit der Meldung
      „no answer within 30 s … does the Neovim configuration wait for input?" ab und ist danach
      wieder bedienbar. Konfiguration zurückbauen.
  Notiz:
- [ ] `root.json` mit einem **relativen** `digest_dir` (z. B. `"somewhere/else"`) wird ignoriert;
      die Auffindung fällt auf `<Ordner>/digest` zurück.
  Notiz:
- [ ] **Zwei Repos, gleicher Dateiname** (`a_b/c` und `a/b_c` teilen den Stem `a_b_c`): sagt die
      Seitenleiste „nicht erfasst", zeigt auch der Dialog nichts Fremdes.
  Notiz:

---

## documentation.nvim und rules.nvim in Neovim

- [ ] `:DocBrowse traffic` im Browser-Modus zeigt dieselben Zahlen wie die App (P3).
  Notiz:
- [ ] `:Rules stats` auf dem echten Regelsatz
      (`$REPOS_DIR/WKDBooks/Development/wkdbook-lua/checklists`) lädt weiter alle Regeln, nachdem
      der Parser Titel, Section und Text mitführt und die Blöcke in der Sandbox laufen
      (erwartet: 421 Regeln, 13 Familien, 32 mit `check`; Abweichung = Fund).
  Notiz:
- [ ] Windows-Pfad mit `%` (z. B. ein Projektordner `100%`): ein Panel, das die Engine über
      `--api=` fragt (Commits, Telemetry), meldet eine klare Verweigerung statt eines falschen
      Ergebnisses. Nur relevant, wenn du so einen Ordner hast; sonst überspringen.
  Notiz:

---

## Von `documentation.nvim` noch nie visuell geprüft

Beides ist syntaktisch und strukturell geprüft, aber nicht in einem echten Fenster gesehen.
`docmap-desktop/tools/preview/` löst das nur für die Oberfläche der App, und ein Browser ist
nicht WebView2 — also in der App öffnen, nicht im Browser.

- [ ] Das **eingeklappte Engine-Panel** auf der generierten Seite.
  Notiz:
- [ ] Das **Kanten-Popup** im Aufrufgraphen.
  Notiz:
- [ ] Phase 4 (UI-Politur): die Typografie-Skala (16 verschiedene `font-size`-Werte gemessen) und
      die Zebra-Streifen brauchen ein Urteil von dir, bevor jemand sie anfasst.
  Notiz:
