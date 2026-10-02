# FINAL_CHECKS — die letzten Prüfungen, die nur du machen kannst (docmap-desktop)

**Stand: 2026-10-02.** Beide Punkte brauchen deine Maschine, deine GUI bzw. deinen
GitHub-Token. Gebaut und mit Fixtures getestet ist alles; es lief nur nichts davon
gegen echte Daten oder in einem echten Fenster. Wenn ein Punkt erledigt ist,
hier streichen; wenn die Datei leer ist, löschen.

Der restliche Stand (Queue, Schulden, Reviews) steht in
`$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/docmap-desktop/Backlog/TASKS/docmap-desktop_HANDOVER.md`
und die Queue in `.../docmap-desktop/ROADMAP/PLAN.md`.

---

## A1 — die installierte App durchklicken

`v0.5.0` (oder, falls inzwischen geschnitten, die neueste Version) ist öffentlich, ohne dass
jemand die App geöffnet hat. Installer:
`https://github.com/StefanBartl/docmap-desktop/releases/latest` → `…_x64-setup.exe`.

Die vier Standardpunkte aus `docs/RELEASING.md`:

- [ ] Ein Projekt wählbar, seine Karte lädt.
- [ ] **Generate map** läuft, die Statuszeile meldet es.
- [ ] **File → Settings…** öffnet, der Theme-Wechsel greift.
- [ ] **Help → About** nennt Engine und Build (Commit, ob er die Engine beschreibt).

Dazu die zwei Dinge, für die `v0.5.0` gebaut wurde:

- [ ] **Add from a parent folder** (z. B. `E:\repos`): Checkliste erscheint, Import
      läuft, bereits vorhandene Projekte werden gemeldet statt doppelt angelegt.
- [ ] **View as matrix…**: Raster öffnet, Zelle = Aufrufstellen, Tooltip nennt die Module.

Findet sich etwas: ein Patch-Release (`v0.5.1`) ist die billige Antwort, kein Zurückziehen.

---

## A3 — Traffic (L11) gegen einen echten Fetch

Erst mit deinem Token `:GithubStats fetch` ausführen (in Neovim, `github_stats.nvim`).
Danach diese Punkte, mit echten Daten über alle drei Repos
(`github_stats.nvim`, `documentation.nvim`, `docmap-desktop`):

- [ ] **Zwei Maschinen.** Fetch auf A, synchronisieren, B öffnen: Der Digest von B
      wird beim Start neu aufgebaut (nicht veraltet), und B hat innerhalb des
      Intervalls nicht erneut gefetcht.
- [ ] **Plugin fehlt.** App und `documentation.nvim` verhalten sich wie vorher;
      kein Fehler, nichts Leeres gerendert.
- [ ] **`ui.nvim` fehlt, Plugin da.** Die Sonde findet trotzdem `github_stats.digest`.
- [ ] **Lazy-geladenes Plugin.** `soft_require.probe` lädt es; kein User-Command nötig.
- [ ] **Überschriebenes `digest_dir`.** `root.json` am Standardort verweist darauf;
      App und Plugin finden es ohne Einstellung.
- [ ] **Feindlicher Digest.** Fixture mit `<img onerror=…>` als Referrer,
      `../../etc/passwd` und `C:\Windows` als Pfade, einer 3-MiB-Datei und
      `schema: 99`: Text ist inert, nichts außerhalb der Projektwurzel bekommt
      einen Link, die Datei wird mit Meldung abgelehnt.
- [ ] **Privates Repo + Opt-out.** Für ein ausgeschlossenes Projekt wird nichts
      angezeigt, und in keinem exportierten Artefakt steht etwas davon.

Hintergrund (Plan, Build-Log, Konzept) liegt im Backlog:
`$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/ALL/Backlog/FEATURES/github-stats-traffic-integration.md`
und `.../github_stats.nvim/ROADMAP/IDEAS/GITHUB_STATS_CONCEPT.md`.
