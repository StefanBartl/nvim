# Analyse: Plugin-Changes-Monitor für gitsuite.nvim (`:Git plugins …`)

Stand: 2026-10-07 · Status: **reine Analyse, kein Code geändert** · Maschine der
Messungen: STEVESPC (Windows 11, Neovim 0.12.2, git 2.53.0.windows.3, lazy.nvim
11.17.5, 50 lazy-verwaltete Klone).

Methode: ein 3-Runden-Workflow mit 10 Agents (4× Recon, 4× Design mit echten
Messungen an deinen Klonen, 1× Verifier, 1× Planer/Kritiker), strikt read-only und
ohne Netz (`GIT_NO_LAZY_FETCH=1`). Der Verifier hat 24 tragende Behauptungen
nachgeprüft: 22 bestätigt, 1 korrigiert, 1 teilweise bestätigt, 0 falsch (Details
in Abschnitt 10).

---

## 0. Kurzfassung

**Machbar, sinnvoll und in gitsuite.nvim gut aufgehoben.** Empfohlen wird ein neuer
Scope `plugins` (`:Git plugins log|report|…`), strikt lesend, in **5 einzeln
auslieferbaren Stufen**, zusammen ca. **17–21 Sessions**. Die Vorstufe
(`:Git plugins log <plugin>`) ist schon nach 3–4 Sessions nutzbar.

Die drei Befunde, die das Design tragen:

1. **Der Anlass lässt sich nur über das HEAD-Reflog des Klons rekonstruieren.**
   Lazy hält das Ergebnis eines Updates (`plugin._.updated`) ausschließlich im
   Speicher und löscht es beim nächsten `:Lazy`-Lauf. `lazy-lock.json` ist bei dir
   gitignored (und enthält ohnehin nur den *aktuellen* Stand). Das Reflog dagegen
   ist persistent, überlebt Neustarts, braucht keinen Hook und ist **ohne
   git-Prozess lesbar** (50 Klone in ~60 ms). Beim nvim-treesitter-Update steht
   dort exakt `f873ec29 → e289100f` (2026-10-07 20:54:51), das sind **86 Commits**.
2. **Das Ziel für „was kommt noch“ muss Lazys Ziel sein, nie `origin/HEAD`.**
   Der naive Vergleich meldet auf deiner Maschine **315 falsche „neue Commits“**
   (blink.cmp 240, neo-tree 48, trouble 15, mini.ai 10, lensline 2), weil
   version-/branch-gepinnte Plugins gegen ein anderes Ziel auflösen.
3. **Breaking-Marker finden nur etwa die Hälfte dessen, was ein Mensch „breaking“
   nennt**, und im Referenzfall gehen die 3 echten Treffer in 23 Parser-Bumps
   unter. Es braucht Bündelung gleicher Betreffs, einen Tag-Banner und einen
   ehrlichen Heuristik-Hinweis im Berichtskopf („0 Treffer ≠ keine Breaking
   Changes“).

Antwort auf deine konkrete Frage nach den **Commit-Nummern** im Anlassfall
(nvim-treesitter `f873ec29..e289100f`, Position in `git log --reverse`):

| Position | Commit | Datum | Betreff |
| --- | --- | --- | --- |
| 17/86 | `c82bf96f` | 2026-04-01 | `feat!: drop support for Nvim 0.11` (bei 0.12.2 ohne Wirkung) |
| 43/86 | `78bebef1` | 2026-07-18 | `fix(hlsplaylist,muttrc,tmux,zathurarc)!: drop support` |
| 46/86 | `ddc93c67` | 2026-07-18 | `feat(prolog,problog)!: drop support` |

Dazu 23 Parser-Bumps `feat(<lang>)!: update parser and queries` (alle betroffenen
Sprachen sind bei dir installiert). Positionen 43 und 46 hat der Verifier nicht
einzeln nachgezählt, 17 schon.

**Entscheidungen: alle 14 offenen Fragen wurden am 2026-10-07 getroffen** (Tabelle
in Abschnitt 13); die Arbeit liegt als zehn Vault-Tasks mit Tag `plugins-monitor`
vor, Start mit `lib-git-log-runner-primitives` und `plugins-log`.

---

## 1. Auftrag (bereinigt)

Anlass: Nach `:Lazy sync` wurde nvim-treesitter aktualisiert, mit Breaking
Changes. Hilfreich wäre die Commit-Nummer der Breaking Changes und eine Übersicht
gewesen. Gewünscht in **gitsuite.nvim** (ausdrücklich, auch wenn reposcope.nvim
thematisch näher liegen könnte):

- **Vorstufe:** ein Usercmd, dem man ein installiertes Plugin (aus der Liste der
  installierten, mit Completion) oder explizit ein Repo/einen Pfad gibt, und das
  dann die letzten Commits anzeigt.
- **Hauptfeature:** ein Usercmd, das **alle installierten Plugins** überwacht
  bzw. deren Commits mit dem aktuell installierten Stand vergleicht, die
  übrigbleibenden Commits **zusammenfasst**, **Breaking Changes sammelt** und in
  einer **praktischen UI** aufbereitet: auswählen, Preview, öffnen. **Der Bericht
  bleibt bestehen**, damit man nacheinander die Breaking Changes mehrerer Plugins
  aufmachen kann.

---

## 2. Der Referenzfall nvim-treesitter (echte Daten)

Alle Zahlen aus deinem lokalen Klon, vom Verifier nachgeprüft:

- Reflog: `25a9b06a` (Clone) → `f873ec29` → `e289100f` (2026-10-07 20:54:51).
  Der Klon steht **detached** auf `e289100f`; der lokale `main` ist noch auf
  `25a9b06a` („behind 5“). „Installiert“ heißt bei Lazy immer *HEAD*, nie der
  lokale Branch.
- Bereich `f873ec29..e289100f`: **86 Commits**, 0 Merges, 26 mit `type!:`, davon
  **23 reine Parser-Bumps** und **3 echte Breaking-Commits** (Tabelle in
  Abschnitt 0). Der Betreff „update parser and queries“ kommt 27× vor.
- Lazy erkennt Breaking nur über das Betreff-Muster `type!:` und zeigt es nur in
  der laufenden `:Lazy`-Ansicht (`render.lua:529`, `sections.lua:49`; Body/Footer
  werden nicht gelesen). In den 26 Treffern geht `c82bf96f` unter.
- Ein einzelner Lua-Kern-Commit ohne jeden Marker (`32dbd2e8 perf(install): make
  install_lang unconditional`) zeigt die Blindstelle: nicht alles ist findbar.
- Die sechs von den Drop-Commits betroffenen Parser (prolog, problog,
  hlsplaylist, muttrc, tmux, zathurarc) sind bei dir installiert (`.so`
  vorhanden). Was zur Laufzeit konkret kaputt ging, wurde **nicht** geprüft.
- Struktur: master/main trennen sich bei `066fd650` (2025-05-12); main hat seither
  497 Commits. Die Rewrite-Commits (z. B. `692b051b feat!: drop modules, general
  refactor and cleanup`, `d3218d98 docs(readme)!: main is now the default
  branch`) liegen alle **vor** deinem Update-Bereich: du warst beim letzten Sync
  schon auf der umgeschriebenen main.

---

## 3. Befunde

### 3.1 lazy.nvim-Internals (Version 11.17.5, Commit `306a055`)

- **Plugin-Liste:** `require("lazy").plugins()` bzw. `lazy.core.config.plugins`
  (Map). Nicht dokumentiert, aber de facto von ≥ 8 Stellen deiner Flotte genutzt.
  Einträge erben per Metatable (`__index`), also nur per Index lesen
  (`vim.deepcopy`/`pairs`/JSON-Encode wären unvollständig). `virtual`-Plugins
  ausfiltern.
- **Update-Ablauf:** `git fetch --recurse-submodules --tags --force`, dann
  `git checkout <commit|tags/<tag>>`. Kein reset/merge/pull/rebase. Folge: jedes
  Update erzeugt einen **detached HEAD** (12 von 50 Klonen).
- **Flüchtig:** `_.updated`/`_.updates` leben nur im Speicher; `Manage.clear`
  leert sie bei jedem `:Lazy`-Lauf.
- **Events:** `LazyUpdate` feuert **vor** dem Schreiben der Lockdatei, `LazySync`
  **danach**; `:Lazy sync` feuert nacheinander Clean/Install/Update/Sync (ein
  Handler auf mehrere Events liefe mehrfach). Reihenfolge nur aus dem Quelltext
  gelesen, nicht live geprüft.
- **Zwei Populationen:** (a) 50 lazy-verwaltete Drittanbieter-Klone, (b) 43
  `dir`-Mode-Eigenplugins unter `E:/repos` (`_.is_local`; Lazy überspringt
  fetch/checkout/update für sie, sie fehlen im Lock). Auf der Workstation
  (`SOURCE=remote`) sind es ca. 116 lazy-verwaltete Repos (laut deiner Notiz,
  dort nicht gemessen).
- **Klon-Strategie:** alle 50 Klone sind **blobless** (`remote.origin.promisor`,
  `partialclonefilter=blob:none`).
- **Zielauflösung (`Git.get_target`, `manage/git.lua:118-154`):** `commit` → `tag`
  → `version` (höchster passender Semver-Tag, auch `defaults.version`) →
  `origin/<branch>` bzw. `origin/HEAD`; `pin=true` bleibt stehen.

### 3.2 Woher „alt“ und „neu“? Quellenhierarchie

| Quelle | Taugt für | Befund |
| --- | --- | --- |
| **HEAD-Reflog des Klons** (`.git/logs/HEAD`) | „angewendet“ (letztes Update) | **Beste Quelle.** Persistent, exakt (from/to/Zeit), prozessfrei lesbar. Auf deiner Maschine nur zwei Eintragsarten: 50× `clone`, 13× `checkout`. Tiefe nur 11 Tage (frische Installation vom 2026-09-26). |
| Lazy `_.updated` | Gegenprobe in derselben Session | Nach Neustart/`:Lazy`-Lauf weg. |
| `lazy-lock.json` (Historie) | — | **Unbrauchbar.** Auf main nie getrackt (gitignored), nur 22 Commits auf Alt-Branches, letzter Stand 2025-07. Für nvim-treesitter ergäbe es **497 statt 86 Commits** (master/main-Divergenz). |
| Eigener Snapshot-Store | Ergänzung | Nötig für „gesehen“-Marker, Überleben bei Klon-Löschung/Reflog-Ablauf, Cache. **Kein Ersatz** fürs Reflog. |
| Reflog der Remote-Refs / `FETCH_HEAD` | „ausstehend“: Alter des Remote-Stands | `FETCH_HEAD`-mtime zählt **nur bei Größe > 0** (ein fehlgeschlagener Fetch kürzt ihn auf 0 Byte). |

**Algorithmus `resolve_range(plugin, mode)`** (Details in der Design-Runde):

- **Modus `updated`:** letzte Reflog-Transition mit `old ≠ new`. Pflichtregeln:
  1. **Verweilregel:** ein Zustand muss ≥ 120 s bestanden haben, sonst ist es ein
     Install-Checkout und kein Update (sonst erschiene trouble.nvim als
     „Rollback von 15 Commits“, mini.ai als „Rollback“, blink.cmp als
     „divergiert“).
  2. **Richtung** per `git merge-base --is-ancestor`: *forward* /
     *rollback* / *diverged*; nie „N neue Commits“, wenn nicht *forward*.
  3. **Plausibilität:** die letzte `new`-SHA muss dem aufgelösten HEAD
     entsprechen, sonst Fallback auf Snapshot.
  4. Update-Läufe über mehrere Plugins per Zeit-Clustering (hier: 8 Plugins
     zwischen 20:54:48 und 20:54:53); Schwelle konfigurierbar (Workstation mit
     EDR ist langsamer).
- **Modus `pending`:** HEAD (Datei) gegen Lazys Ziel (Tiers wie oben, selbst
  nachgebaut, **mit Prerelease-Filter**: ohne ihn wählt `vim.version.range("1.*")`
  fälschlich `v2.0.0-rc.1`). Kann kein Ziel bestimmt werden → `unknown_target`,
  **nie** Fallback auf `origin/HEAD`. Kein eigener `fetch` in v1; die Frische
  liefert `:Lazy check`, angezeigt wird das Alter.
- **Modus `recent N`** (Vorstufe): ein `git log -n N`, HEAD/Lock/Tags markiert.
- **Geometrie:** `git log --left-right A...B` liefert in *einem* Aufruf neue und
  nur-lokale Commits (Divergenz/Force-Push/Downgrade ohne zweiten Aufruf).
- **Randfälle mit Soll-Verhalten** (Erstinstallation, entferntes/neu installiertes
  Plugin, Rollback via `:Lazy restore`, detached HEAD, Submodule, `.git`-Datei,
  Force-Push mit fehlendem `from`, Pin/`commit`-Spec, `lock ≠ HEAD`, abgelaufenes
  Reflog) stehen im Workflow-Ergebnis; jeder bekommt eine ehrliche Zeile statt
  „N neue Commits“.

### 3.3 Blobless-Klone: was offline geht

(Alle 50 Klone blobless. `GIT_NO_LAZY_FETCH=1` in **jedem** Spawn, sonst lädt git
heimlich Objekte aus dem Netz nach und schreibt in den Klon.)

| Geht offline | Scheitert (rc 128) bzw. würde das Netz nutzen |
| --- | --- |
| `git log` inkl. Body (`%b`), `--name-status --no-renames`, `rev-list`, `for-each-ref` (inkl. Tag-Meldungen), `diff-tree --name-status --no-renames` | `log --stat/--numstat/-p`, `show --stat`/Patch, `diff --stat` eines Zwischencommits, Pickaxe `-S/-G` |
| Diff `--stat`/Patch **nur**, wenn beide Endpunkte früher ausgecheckt waren | Rename-Erkennung (ohne `--no-renames` brach es in neo-tree nach Teilausgabe mit rc 128 ab) |

- **`git show` ist nicht verlässlich**, selbst mit `-s`: bei `692b051b` scheitert
  es, `git log -1` funktioniert. Im Feature **nur `git log` und `git diff-tree`**,
  rc immer prüfen, nie Teilausgaben anzeigen.
- Folge für die UI: Commit-Liste mit Betreff/Body/Autor/Zeit/Breaking-Flag und
  Dateiliste kommen sofort; Patch/Stat brauchen Netz → eigener „Diff nicht
  lokal“-Zustand mit Bestätigung bzw. Browser-Compare-URL.
- Ein **hermetisches Blobless-Testfixture** ist lokal baubar
  (`file://` + `uploadpack.allowFilter`, mindestens 3 Commits ohne Checkout älterer
  Stände). Auf den CI-Runnern ungeprüft.

### 3.4 Breaking-Erkennung (empirisch)

Korpus: letzte 300 Commits jedes der 50 Klone, **10.886 Commits**, 35
Kandidatenregeln, 615 Commits manuell beurteilt (**ein Beurteiler**, also
subjektiv). Ergebnis: vier Stufen.

| Stufe | Regeln (Kern) | Anteil | Präzision |
| --- | --- | --- | --- |
| **sicher** | `type(scope)!:` (nicht Parser/Bulk), Footer `BREAKING CHANGE:`/`BREAKING-CHANGE:`/`BREAKING_CHANGE:` (Großschreibung), Betreff beginnt mit `BREAKING` | 1,0 % | **96 %** (KI 85–99) |
| **wahrscheinlich** | „drop support/compat“, „requires Neovim x“, Kleinschreib-Footer, „by default“ | 0,7 % | 42 % (KI 29–58) |
| **Hinweis** | remove/rename/deprecate-Wörter, gelöschte/verschobene Lua-Module, Body-„breaking“ (eingeklappt, per Score sortiert) | 7,9 % | ~10 % |
| **Parser / Bulk** | `!` bei Tree-sitter-Bumps; ≥ 3 gleiche normalisierte Betreffe → eine Gruppenzeile | — | formal breaking, praktisch Rauschen |
| (ohne Stufe) | 89,9 % der Commits | | 1 von 139 Stichproben war doch breaking |

- **Recall ist niedrig:** sicher 34 %, sicher+wahrscheinlich ~46 %, mit Hinweisen
  ~76 % (Spanne 36–95 %). Marker-Regeln sehen vor allem, was Maintainer selbst
  flaggen.
- **Blindstellen:** 12 von 50 Plugins ohne Commit-Konvention (neogit, nvim-dap,
  lensline, …); Verhaltensänderungen ohne Marker (z. B. `vim-matchup: enable
  treesitter virtual text by default`); Nicht-Commit-Ereignisse (Default-Branch-
  Wechsel, Repo-Transfer, History-Rewrite, Archivierung).
- **Tag-Banner** („MAJOR a → b“, `git tag --merged NEW --no-merged OLD`, offline):
  78 % der Major-Bereiche enthalten Marker, nur 2 % der Minor-/Patch-Bereiche.
  Beim Auslöser nvim-treesitter greift es **nicht** (keine Tags seit v0.9.3).
- **Changelog-Parser** (`## <Version>`/`### …break…`): nur 13 von 50 Klonen haben
  einen Changelog mit Breaking-Abschnitt (12 davon release-please, also aus den
  `!`-Commits abgeleitet); nur **nach** dem Update lokal lesbar (Blob fehlt im
  Blobless-Klon). Geringer Mehrwert in der Breite, aber sicher.
- **Relevanz-Hebel ohne Netz:** installierte Sprachen (`site/parser/<lang>.so`)
  für Parser-Bumps; Neovim-Floor-Abstufung (`drop support for Nvim 0.11` bei
  0.12.2 → „betrifft dich nicht“).
- **Anzeige „Commit i von n“** per `git log --topo-order --reverse OLD..NEW`; das
  **Committer**-Datum (`%cI`) verwenden, nicht das Autor-Datum (die ersten ~85
  Rewrite-Commits haben Autordaten von 2023/24).
- **CRLF:** in 34 von 50 Plugins enthalten Bodies `\r` → vor dem Matching
  normalisieren.
- **Lua-Parität:** die Regeln lassen sich mit `vim.regex` portieren (11 Regeln auf
  allen 10.886 Commits identisch zu Python belegt, 1,4 s); Lua-Patterns scheiden
  aus (keine Alternation).

### 3.5 Performance

- Ein git-Spawn kostet auf Windows **120–390 ms** (streut mit der Systemlast;
  belastbar ist nur die Größenordnung: die **Prozessanzahl** dominiert, nicht die
  Nutzlast; 86 Commits mit Body und `--name-status` in einem Aufruf: ~470 ms).
- **Prozessfrei** (HEAD, packed-refs, Reflog, `.git/config`, `FETCH_HEAD`-mtime
  per Dateilesen): 50 Klone in **25–80 ms**, also 50–100× billiger.
- **Budget = Anzahl *geänderter* Plugins**, nicht der installierten:
  unverändert = 0 Spawns; geändert = **1** `git log --left-right A...B …` (+1
  Tag-Abfrage nur bei `pending` + version-Plugin).
- Pool: Optimum ~8 gleichzeitig (12 ist schon langsamer, Gewinn nur 1,5–2×).
  Empfohlener Default `parallel = 4` (EDR auf der Workstation), konfigurierbar.
- Für den Stand vom 2026-10-07 genügen **≤ 8 Spawns** (ca. 0,3–0,5 s); Kaltlauf
  ohne Reflog und ohne Cache (Worst Case 50 Spawns) ca. 3 s bei 8 Jobs.
- Startkosten null: kein Scan in `setup()`, alles lazy per `require` aus den
  Routen-Closures.

### 3.6 Bestand in gitsuite.nvim und lib.nvim

**Direkt nutzbar** (heute aber Dashboard-privat): Pfadauflösung
(`dashboard/repos.lua`), Scan/Worker-Pool (`dashboard/status.lua`, Pool nur als
lokale Funktion), `util/progress`, `util/notify`, JSON-State
(`state/dashboard_pages.lua`), `ui.kit`-Dialoge, URL-Grammatik
(`lib.nvim.git.remote`). `dashboard/view.lua` (1826 Zeilen, Modul-Singletons,
hart auf `RepoDashboardRecord`) taugt nur als **Muster** (ROW_KEYMAPS, Legende,
`reopen()`).

**Fehlt in lib.nvim** (gegengeprüft, je ≥ 2 reale Duplikate im Fleet):

- `git.log` (+ reiner `parse_log`), `git.rev_parse(rev)`, `git.tags` (mit
  `creatordate`-Fix; `refs()` sortiert annotierte Tags falsch), `merge_base`,
  `is_ancestor`, öffentlicher generischer Runner,
- `run_argv`-Optionen `timeout_ms`/`env`/`cwd` (gibt es nicht),
- `async.map_limit` (nur `Semaphore` existiert),
- `remote.commit_url/compare_url/tag_url` (+ nil-Guard in `host_kind`, der bei
  `hosts_cfg == nil` wirft),
- eine öffentliche „installierte Plugins“-Registry (`lazy_dirs()` in
  `deps/spec/init.lua:300` ist privat).

**K-6:** alle lib-Primitive als **ein** Push (maximal zwei) → 3-OS-CI +
`publish-ci-verified` abwarten → erst dann gitsuite pushen. Lokal blockiert nichts
(beide Repos laufen bei dir im `dir`-Modus), nur die Push-Reihenfolge wartet.
Rückfall bei rotem lib-CI: `gitlog.lua`/`pool.lua` lokal in gitsuite, später
Swap.

---

## 4. Heimat: gitsuite vs. reposcope vs. eigenes Plugin

Deine Entscheidung (gitsuite) wird sachlich gestützt.

| Kriterium | gitsuite | reposcope | eigenes Plugin |
| --- | --- | --- | --- |
| Domäne | Git-Tooling über lokale Klone (dasselbe Argument, mit dem das Dashboard 2026-09 hierher zog) | Discovery/Suche/Klonen bei GitHub/GitLab/Codeberg; README sagt selbst „Maintaining … is gitsuite“ | neutral, aber ein weiteres Git-Plugin |
| Vorhandene Bausteine | Repo-Set, Pool, Progress, State, URL-Grammatik, ui.kit, lazygit | keine Prozess-/Commit-/Diff-Primitive | alles neu verdrahten |
| Datenquelle | lokales git (Reflog, Refs, log) | Provider-/Token-Schicht, Ratenlimits, nur 3 Hosts | wie gitsuite |
| Neue Abhängigkeiten | keine neue Kante | neue Git-Abhängigkeiten | volle Repo-/CI-/Doku-Kosten |
| Scope-Reinheit | **schlecht** (zweite Multi-Repo-Ausnahme) | Thema nah, Funktion fern | am saubersten |

**Ehrliche Folgekosten in gitsuite:**

1. **Zweite Multi-Repo-Familie.** `docs/scope.md` sagt „Nine families“ und
   „`dashboard` is the one cross-repository view“; ca. **14 Doku-Stellen**
   (scope, architecture, around-it, commands, configuration, what-you-get,
   requirements, health, README, docs/README, `doc/gitsuite.txt` §4/5/7/9,
   CONTRIBUTING-Layout, integrations) plus zwei tote Anker. Einmalig ~1 Session,
   gehört in **einen** Doku-Task in Stufe 1.
2. **Undokumentierte Lazy-Struktur** → Adapter nur mit Typ-Guards,
   Fake-Lazy-Vertragsspec, Health-Warnung bei anderer Major, Fallback `clones`.
3. K-6/lib.nvim-Push (ein gebündelter, später ein kleiner für Tree-Kill).
4. Neue Persistenz + ein Event (mit den vier Pflichtstellen: `events.lua`, @types,
   `doc/gitsuite.txt` §7, `events_spec.lua`).

**So bleiben die Kosten klein:** Stufe 0 ist reiner Einzel-Repo-Scope (Präzedenz
`:Git ui lazygit [dir]`); der Scope heißt `plugins` und ist **keine**
Dashboard-Unterroute; `features/plugins/` importiert nichts aus
`features/dashboard` (Pfad-Helfer gehen nach `util/repos.lua`), damit eine
spätere Auslagerung billig bleibt; kein `features.plugins`-Flag (die bestehenden
`features.*=false` entfernen laut Code ohnehin keine Routen); ein Abgrenzungssatz in
`scope.md`: *plugins reads only local repository state; the only outward step is a
URL handed to the browser; no install, update, pin or clean.* Das
Hosting-API-Verbot bleibt unberührt (nur lokales git + Commit-/Compare-URLs wie
bei `browse`).

---

## 5. Entwurf

### 5.1 Befehlsfläche (Route-Baum, Entwurf)

```
:Git plugins                       zuletzt gespeicherten Bericht öffnen (ohne Scan)
:Git plugins report [--mode=updated|pending] [--all] [--out=…] [--to=…]
                                    berechnen, speichern, anzeigen
:Git plugins log <name|owner/repo|pfad> [n] [--base=head|updated|pending]
                                    Vorstufe: letzte Commits eines Klons (1 Spawn)
:Git plugins breaking [<plugin>]    Breaking-Digest (flach über alle Plugins)
:Git plugins clear [--seen]         Berichte bzw. Gesehen-Marken löschen
```

- Typen (idempotent in `M.register`, Präfix `GITSUITE_` wegen der globalen
  last-write-wins-Registry): `GITSUITE_PLUGIN` (Completion aus Lazy-Tabelle oder
  Verzeichnisliste, **ohne Prozess**), `GITSUITE_PLUGIN_OR_REPO` (Plugin-Name +
  `getcompletion(…,'dir')` + `$REPOS_DIR`), `GITSUITE_REPORT_ID`.
- Ein nicht installiertes `owner/repo` wird mit klarer Meldung abgelehnt (bräuchte
  Netz). Pfade mit Leerzeichen brauchen `\ ` (composer splittet an Whitespace).
- Namensrisiko: `plugins log <pfad>` für ein Nicht-Plugin liest sich schief;
  Alternative `:Git log [target]` als eigene Einzel-Repo-Familie (Frage 7).

### 5.2 Modul-Layout

```
lua/gitsuite/adapter/{lazy,pack,clones}.lua  Quellen (lazy: package.loaded, ohne require)
lua/gitsuite/util/repos.lua                  Extraktion der reinen Pfad-Helfer (Shim bleibt)
lua/gitsuite/features/plugins/
  init.lua      öffentliche API (nur Verdrahtung)
  sources.lua   resolve_first(lazy|pack|clones), Namensauflösung, Completion
  gitfs.lua     prozessfreier Reader (HEAD, packed-refs, Reflog, origin-URL, FETCH_HEAD, index.lock)
  runs.lua      Reflog -> Update-Läufe (Verweilregel, Clustering, Richtung)
  target.lua    Lazys Ziel-Tiers (rein)
  gitlog.lua    der EINE git-Spawn: Verb-Allowlist, Env, parse_log
  pool.lua      begrenzter Pool mit Abbruch (wandert später nach lib.nvim.async.map_limit)
  breaking.lua  Klassifikator + Bündelung (rein)
  summary.lua   deterministischer Digest + Markdown-Export (rein)
  report.lua    Orchestrierung; state.lua  Persistenz; view.lua  UI
```

Rein/headless testbar: `gitfs`, `runs`, `target`, `gitlog.parse_log`, `breaking`,
`summary`. `adapter.resolve_first` bekommt damit seinen **ersten echten
Aufrufer** (heute hat es keinen; `architecture.md` und der Kommentar in
`adapter/init.lua` müssen angepasst werden).

### 5.3 Persistenz und Datenvertrag

- Ablage `stdpath('state')/gitsuite/` (auf Windows fällt state mit data
  zusammen; `stdpath('cache')` ist löschbar und ungeeignet). Schreiben atomar
  über `lib.nvim.fs.write.atomic` (mit `mkdirp`; `fs.json.write` nutzt ein festes
  `.tmp` ohne `mkdirp`), Lesen defensiv: **kaputte/fremde Datei wird nie still
  überschrieben** (`.corrupt`/`.bak`), anders als `dashboard_pages` heute.
- **Zwei Dateien:** `plugins_reports.json` (Berichte, komplett neu geschrieben)
  und `plugins_seen.json` (kleine interaktive Gesehen-Marken `name@sha`), damit ein
  fertiger Scan in Instanz A nie die Markierung aus Instanz B klobbert; beide
  jeweils frisch lesen und mergen.
- **Cache-Schlüssel** `dir@from...to`: ein SHA-Bereich ist unveränderlich, ein
  Treffer spart den Spawn für immer. Klassifikation/Digest werden beim Laden neu
  gerechnet (Regeländerung braucht keine Invalidierung).
- Deckel (nach Entscheidung vom 2026-10-07, ursprünglich 5 / 90 / 300): 20 Berichte,
  365 Tage, 1000 Commits je Plugin, Body ≤ 2 KB (JSON-Größe nicht gemessen;
  Schätzung einige hundert KB bei ~1000 Commits, bei 20 Berichten bis einige MB →
  Größe im Task messen, ggf. Gesamtdeckel).
- Pro Maschine eine eigene Datei (Klone/Reflogs/Lock sind maschinenlokal; deine
  Workstation unterscheidet sich).
- Jede Zeile trägt **Quelle und Konfidenz** sichtbar (`reflog` exakt · Snapshot ·
  `pending` · `new`; Suffix `~` = ungenau).

### 5.4 UI

**Empfehlung für „der Bericht bleibt“: eigener Tab mit Listenfenster +
Preview-Split** (in `nvim --clean` 0.12.2 verifiziert):

| Variante | Bleibt? | Bewertung |
| --- | --- | --- |
| **(a) eigener Tab + Preview-Split** | überlebt `:only` in anderen Tabs; Puffer/Keymaps überleben `:tabclose` | **Default** (`--out=tab`) |
| (b) Float mit hide/restore (= Dashboard) | `:only` schließt Floats; nur ein Eintrag; `bufhidden=wipe` | nur Kurzblick (`--out=popup`) |
| (c) `kit.picker` | schließt bei `<CR>`; Prompt modal, Caller-Keys laufen im Insert-Mode (nur Chords) | Schnellsprung `F` |
| (d) Quickfix | Commits sind keine Orte | nur Export `Q`/`--out=clipboard|path` |

Fensterverwaltung: Puffer `buftype=nofile`, `bufhidden=hide`, `winfixbuf` an
Liste und Preview; Layout vertikal ab 140 Spalten, sonst horizontal;
Cursor-Restore **per Schlüssel** (Plugin-Name/SHA), nie per Zeilenindex;
Fokus-Rückkehr nach dem Öffnen eines Commits/Files per `WinClosed`-Hook
(verifiziert: plain `:tabclose` springt sonst zum *nächsten* Tab);
`:tabonly` schließt den Tab (Puffer lebt, `:Git plugins` baut ihn neu auf);
Sonderfall „Report ist einziger Tab“ vermutlich E784 (unverifiziert).

**Übersicht** (nvim-treesitter-Zeile = echte Daten, Rest Beispielwerte):

```
 Plugin updates · after :Lazy sync · 2026-10-07 20:54 · 50 plugins · 5 changed · 2 with breaking
   PLUGIN           FROM → TO          COMMITS  BREAKING  SRC     AGE
!  nvim-treesitter  f873ec2 → e289100       86  !3 ~23    reflog  4d
!  neo-tree.nvim    v3.31.0 → v3.34.0       12  !1        reflog  9d
●  blink.cmp        v1.9.1 → v1.10.2        41  -         reflog  2w
   mini.ai          v0.17.0 → v0.18.0        3  -         reflog  3w      <- gesehen
✗  trouble.nvim     clone unreadable: .git is not a directory   (r retry · S status)
   45 unchanged hidden · A show all · t pending lens · gf fetch all (network)
```

**Plugin-Detail** (Sektionen BREAKING / GROUPED / OTHER, `c i/n` = Position):

```
 nvim-treesitter  f873ec2 → e289100  86 commits · !3 breaking · ~23 grouped          c 1/86
 BREAKING (3)
 ! c82bf96  2026-04-01  feat!: drop support for Nvim 0.11
 ! 78bebef  2026-07-18  fix(hlsplaylist,muttrc,tmux,zathurarc)!: drop support
 ! ddc93c7  2026-07-18  feat(prolog,problog)!: drop support
 GROUPED (23)
 ▸ ~ 23 × feat(<lang>)!: update parser and queries    kdl, scheme, …       <CR> expand
```

**Preview in zwei Stufen:** Stufe 1 (immer, offline): Betreff, Body, Autor, Datum,
Dateiliste per `diff-tree --name-status --no-renames` (1 Spawn/Commit, LRU-Cache,
Stale-Guard). Stufe 2 (Patch/Stat): im Blobless-Klon nur nach Bestätigung
(`plugins.preview.patch = 'ask'|'never'|'auto'`) — in der **ersten Version nicht
enthalten**, stattdessen Hinweis „Patch nicht lokal“ + Browser-Compare-URL.

**Öffnen:** Browser (`o`/`K`: Commit-URL bzw. Compare-URL; `go` erzwingt Compare;
`gy` kopiert), lokaler Klon in lazygit (`L`, `:Git ui lazygit <dir>`) bzw.
`S` (Status), CHANGELOG (`C`), Hash kopieren (`y`/`Y`), Aktionsmenü `O`
(`kit.menu`), Schnellsprung `F`, Export `Q`. **Kein** Push/Pull im Report (Lazy
besitzt die Checkouts).

**Kern-Keys** (Parität: gleiche Taste = gleiche Bedeutung wie Dashboard/Lazy,
sonst bewusst neu; eine Tabelle erzeugt Maps, winbar-Legende und `?`-Hilfe, dazu
eine Spec gegen `BINDINGS.md`): `<CR>` öffnen · `q` zurück/verstecken · `]]`/`[[`
nächstes Plugin · **`]b`/`[b` nächster ungesehener Breaking** · `p` Preview ·
`e` gesehen · `B` Digest · `t` Basis `updated`↔`pending` · `r`/`R` neu lesen/neu
berechnen · `s` Sortierzyklus · `A` alle zeigen · `?` Hilfe. Abweichung zum
Dashboard: `p` ist dort Push, hier Preview (Frage 13).

**Gesehen-Modell:** `seen[plugin].commits[sha]`, Plugin gilt als gesehen, solange
`to` gleich bleibt; ein neuer Bereich markiert nur die neuen Commits als
ungesehen.

**Highlights** `GitSuitePlugins*` (link, `default=true`, bei `ColorScheme` neu),
Zustand immer mit Glyphe **und** Wort (nie nur Farbe), `plugins.ascii=true` als
Fallback, erste Pufferzeile = Zusammenfassung.

### 5.5 Hooks, Events, Toast

- **Event** `User GitsuitePluginsReported` (nach erfolgreichem Speichern; Partizip-
  Form wie die Bestandsevents), `data = { id, mode, plugins, commits, breaking,
  errors, at }`. gitsuite kennt keine Konsumenten; Chip/Statusline abonniert die
  Config selbst.
- **Sync-Hook** (Stufe 4a, **Default aus**): Listener auf `User LazySync` in
  benannter augroup unter `integrations/lazy.lua`, ~200 ms defer, rechnet `updated`,
  speichert, zeigt nur einen `kit.toast` ohne Fokus (`plugins.after_sync =
  'off'|'toast'|'open'`). Kein Lauf headless (`+qa` würde ihn abschneiden). Damit er
  feuert, muss gitsuite zum Sync-Zeitpunkt geladen sein (Install-Spec `event`
  um `'User LazySync'` ergänzen; aus dem Code gelesen, nicht live geprüft).
- Hintergrund Default „off“: deine Entscheidung vom 2026-10-04, die Update-Liste
  nicht automatisch zu berechnen.

### 5.6 Config und Health

- Neuer Block `plugins` in `DEFAULTS.lua` (jeder Schlüssel **muss** in `KNOWN`
  stehen, sonst wird er als „unknown option“ verworfen): `sources='auto'`,
  `roots`, `include_local=false`, `mode='updated'`, `max_commits=1000`,
  `parallel=4`, `timeout_ms=30000`, `run_window_s=300`, `keep_reports=20`,
  `max_age_days=365`, `seen_ttl_days=365`, `merges=false`, `breaking={keywords,collapse_repeats=5,ignore}`,
  `summarize=false`. Neue Checker nötig (`is_positive_int`, `is_one_of`,
  `is_sources`, `is_function_or_false`); @types, `configuration.md`,
  `doc/gitsuite.txt` §5, `config_spec`, Install-Spec der nvim-config
  (`specs/project.lua`) mitziehen.
- `health.lua`: eigene Sektion „plugin sources“ (fehlende optionale Quelle = `info`,
  nie `warn`/`error`), `warn` bei Lazy-Major ≠ 11, bei nicht existierenden
  `roots`, bei git < 2.44 (Mindestversion von `GIT_NO_LAZY_FETCH` unverifiziert).

### 5.7 Invarianten („gitsuite aktualisiert nichts“)

- **I1** Kein Schreibzugriff auf Klone: Runner mit **Verb-Allowlist** (`log`,
  `for-each-ref`, `rev-parse`, `cat-file`, `merge-base`, `diff-tree`), jedes andere
  Verb wirft (Spec).
- **I2** Persistenz nur unter `stdpath('state')/gitsuite/`.
- **I3** Kein Netz (`GIT_NO_LAZY_FETCH=1`, `GIT_TERMINAL_PROMPT=0`,
  `GCM_INTERACTIVE=never`, kein Fetch, keine Hosting-API). Ein späteres `--fetch`
  wäre die einzige Ausnahme (Stufe 4b, explizit, mit Bestätigung).
- Zusätzlich: Commit-Texte fremder Repos sind **untrusted** (Steuerzeichen/Länge
  bereinigen, Revs mit führendem `-` ablehnen, KI nur als gekennzeichneter Hook).

### 5.8 Deterministische Zusammenfassung zuerst, KI nur als Hook

`summary.lua` liefert ohne KI: Commit-Zahl, Zeitraum, Zähler je Conventional-Type,
Top-Scopes, Autoren (mit Bot-Anteil), Tags samt Tag-Meldung, Breaking/Gruppen,
betroffene Verzeichnisse, Major-Sprung-Hinweis, plus Markdown-Export. KI optional als
Config-Funktion `plugins.summarize = function(input, done)`, **nur auf ausdrückliche
Taste**, `input.untrusted=true`, Ergebnis als „KI-Text (Provider, Zeit)“ markiert.
Brücke zu ai.nvim (`ask` mit explizitem Provider, `bulk`-Leine; auf der Workstation
nur Copilot/Claude) gehört in die nvim-config bzw. `docs/integrations.md`,
**kein** `require("ai")` in gitsuite.

---

## 6. Stufenplan

| Stufe | Inhalt | Repos | Aufwand | Risiko |
| --- | --- | --- | --- | --- |
| **0** Vorstufe | `:Git plugins log <plugin\|pfad>` (Einzel-Repo, offline, 1 Spawn); lib-Block L1; Adapter lazy/pack/clones; Typ + Completion; Picker mit Preview; Health-Zeile | lib.nvim (zuerst), gitsuite, nvim-config | 3–4 Sessions | mittel (K-6, undokumentierte Lazy-Struktur) |
| **1** Overview | `:Git plugins report` über alle Plugins, Modi `updated`/`pending` **ohne Fetch**; gitfs/runs/target; Pool; Persistenz v1; Config; Event; Health; **Scope-Doku-Sprung** | gitsuite, nvim-config, WKDBooks | ~4 Sessions | mittel–hoch (Korrektheit von Basis/Ziel) |
| **2** Breaking | Klassifikator (4 Stufen), Bündelung mit Footer-Ventil, Tag-Banner, Position i/n, Relevanz (Parser/Neovim-Floor), `summary.lua`/Markdown, Fixture-Gate | gitsuite | 2–3 Sessions | mittel (Heuristikgüte) |
| **3** Persistente UI | Spike (0,5) → Tab + Preview-Split, Übersicht/Digest/Detail, Preview Stufe 1, Öffnen-Aktionen, Gesehen-Marken (eigene Datei), Keymap-Tabelle | gitsuite, nvim-config (ui.nvim nur falls Spike es nahelegt) | 3–4 Sessions | mittel (UI-Container, Tastenkollision) |
| **4** Extras (einzeln, je Option aus) | 4a Sync-Hook + Toast · 4b explizites `--fetch` (Bestätigung, Timeout, Tree-Kill) · 4c KI-Hook | gitsuite, lib.nvim (4b), nvim-config | ~4 Sessions | 4a mittel · 4b **hoch** · 4c niedrig–mittel |

**Summe ca. 17–21 Sessions.** Jede Stufe ist einzeln nutzbar/auslieferbar.

Abnahmekriterien (Auszug, vollständig im Workflow-Ergebnis):

- **Stufe 0:** `:Git plugins log nvim-treesitter` ergänzt Namen ohne Prozess und
  zeigt in genau 1 Spawn die letzten N Commits mit HEAD-Markierung; explizites
  Klon-Verzeichnis funktioniert; Spec weist `fetch/checkout/pull` ab;
  `log --name-status --no-renames` läuft im hermetischen Blobless-Fixture
  (`--stat` scheitert erwartungsgemäß mit rc 128).
- **Stufe 1:** Referenzfall dieser Maschine: Modus `updated` meldet für
  nvim-treesitter `f873ec29 → e289100f` mit 86 Commits und genau **8 Plugins im
  Lauf von 20:54**; die 4 Install-Checkouts (blink.cmp, mini.ai, trouble.nvim,
  treesitter#1) erscheinen **nicht** als Update/Rollback. Modus `pending`:
  blink.cmp/trouble/mini.ai/neo-tree/lensline zeigen **0** statt 240/15/10/48/2.
  Unveränderte Plugins kosten 0 Spawns; zweiter Lauf mit gleichem `(from,to)` 0
  Spawns (Cache).
- **Stufe 2:** nvim-treesitter `f873ec29..e289100f`: genau 3 „sicher“ (17/86, 43,
  46) + **eine** gebündelte Parser-Gruppe statt ~26 Einzelzeilen; Fixture-Gate
  Präzision „sicher“ ≥ 90 %, „wahrscheinlich“ ≥ 35 %, Drift 0.
- **Stufe 3:** der Bericht überlebt `:only` in anderen Tabs und das Öffnen von
  Commit/Datei/Browser; `:Git plugins` nach Neustart öffnet den letzten Bericht
  ohne Scan; nacheinander Breaking-Commits verschiedener Plugins öffnen (`]b`)
  ohne Neuaufbau.

---

## 7. Tests (Kurzfassung)

- Specs unter `TESTS/gitsuite/` mit **echten Temp-Repos** (`tempname()`, nie in den
  Live-Checkout schreiben, Commit `0a434ac`): `plugins_gitfs`, `_runs`, `_target`
  (inkl. Regression „kein Fallback auf origin/HEAD“ = die 315), `_gitlog`
  (CRLF, leerer Body, Allowlist weist Schreibverben ab), `_breaking`
  (tabellengetriebener Korpus), `_summary`, `_sources`, `_state`, `_report`,
  `_usrcmds`; erweitern: `config_spec`, `events_spec`, `adapter_spec`.
- **Fake-Lazy:** `package.loaded['lazy.core.config']` mit Metatable-Vererbung
  (beweist Nur-Index-Lesen) + `package.preload['lazy']`, das beim `require` wirft
  (beweist: `is_available()` ruft kein `require`).
- **Fixture-Korpus** aus echten Commits (kuratiert ~120–150 Zeilen) als
  `TESTS/fixtures/breaking/` + Präzisions-Gate.
- **3-OS-Fallen:** Windows-8.3-Kurzpfade und macOS `/private/var` → über
  `normalize_path`/`fs_realpath` vergleichen; `git init -b main`, `-c
  user.name/email`, `commit.gpgsign=false`, `core.autocrlf=false`; feste
  `GIT_COMMITTER_DATE`; keine Timer-/FS-Event-Specs (macOS-Flake-Historie GS-00);
  Pool-Spec über injizierten Runner; `GIT_NO_LAZY_FETCH` wird von altem git
  ignoriert, Specs dürfen nicht von seiner Wirkung abhängen.
- Fenster-Spec für die UI (Tab öffnen, `:only` anderswo, `:tabonly`, Wiederöffnen,
  Cursor-Restore) und TUI-Harness-Lauf.

---

## 8. Risiken (Auszug aus dem Register)

| # | Risiko | Gegenmaßnahme |
| --- | --- | --- |
| R1 | Falsche Basis/Ziel (origin/HEAD statt Lazy-Ziel; Install-Checkout als Rollback; Lock-Historie als Basis) | Tiers wie Lazy, Verweilregel 120 s, Richtungsprüfung, `unknown_target` statt Fallback, Regression-Specs |
| R2 | Interne Lazy-Struktur ändert sich | nur Datenlesen, Typ-Guards, Health-Warnung bei anderer Major, Fake-Lazy-Vertragsspec, Fallback `clones` |
| R3 | Reflog verloren/abgelaufen (Klon gelöscht; 90/30 Tage; auto-gc unbeobachtet) | persistierte Berichte, Zustand `no_update_recorded`, nie „aktuell“ behaupten |
| R4 | Breaking-Heuristik: Rauschen **und** Blindheit (Recall ~46 %) | Bündelung mit Footer-Ventil, Heuristik-Hinweis im Kopf, Tag-Banner, Rohlog bleibt zugänglich |
| R5 | Blobless: Patch/`show`/diff.nvim laden still Blobs nach und schreiben in fremde Klone | `GIT_NO_LAZY_FETCH=1`, Verb-Allowlist, nur `log`/`diff-tree`, `--no-renames`, rc prüfen, Patch erst später und bestätigt |
| R6 | `--fetch` (Stufe 4b): Netz, Credential-Prompt, EDR-Freeze (60–90 s), Mutation von 50–116 Klonen | v1 ohne Fetch; später nur explizit, Bestätigung, Timeout, `GIT_TERMINAL_PROMPT=0`, Tree-Kill (`taskkill /T`), Lock-Prüfung |
| R7 | Prozesslast Windows/EDR | prozessfreier Schnellpfad, Spawn nur für Geänderte, Cache, `parallel=4`, Fortschritt + Abbruch |
| R8 | K-6/lib.nvim-Wartezeit (macOS-Flake-Historie), parallele Worktrees | ein gebündelter Block, Feature-Detection, lokale Fassungen als Rückfall |
| R9 | Scope-/Doku-Drift (~14 Stellen, tote Anker, BINDINGS ohne Generator, vier Kopien der Tasteninfo) | ein Doku-Task in Stufe 1, kein `features.plugins`-Flag, Spec Tabelle ↔ BINDINGS |
| R10 | Scope-Creep zum Update-Manager | Invarianten I1–I3 + Verb-Allowlist-Spec + Abgrenzungssatz |
| R11 | UI-Entscheidung Tab vs. Picker offen, `:tabonly`, Tastenkollision mit Dashboard (Push bei `p`) | Spike zuerst, Schlüssel statt Zeilenindex, bewusste Abweichungen dokumentieren |
| R12 | Persistenz: kaputte Datei überschrieben, zwei Instanzen | Version, defensives Lesen, `.corrupt`/`.bak`, atomar, getrennte Seen-Datei |
| R13 | Untrusted Text (Escape-Sequenzen, Prompt-Injection über Commit-Messages) | bereinigen, Längendeckel, `-`-Revs ablehnen, KI nur als markierter Hook |

---

## 9. Widersprüche der Teilanalysen und ihre Auflösung

| Thema | Widerspruch | Auflösung im Plan |
| --- | --- | --- |
| UI-Container | Tab + Preview-Split (ui_ux) vs. ein `kit.picker` mit Chords (architecture) | Tab als Default, Picker nur für `F`; **Spike GS-48** entscheidet endgültig |
| Auto-Toast | ui_ux Default `toast` vs. architecture kein Listener vs. deine Entscheidung 2026-10-04 | Default **off**, Hook erst Stufe 4a |
| Event/Dateien | `GitsuitePluginsChanged` + eine Datei vs. `…Reported` + zwei Dateien | zwei Dateien (schützt Marker), Partizip-Name `GitsuitePluginsReported`; zweites Event bei Seen-Änderung offen |
| Pool-Größe | Dashboard 8, `:MyPlugins sync` 2, Messung Optimum 8 | Default 4, konfigurierbar |
| lib-first vs. local-first | Recon C: alles zuerst nach lib · Architektur: lokale Kopien | beides: parallel entwickeln, Push-Reihenfolge lib → CI → gitsuite, lokale Kopie nur als Rückfall |
| Lazy-API-Nutzung | `get_target`/`fast_check` per pcall nutzen vs. nur Daten lesen | nur Daten lesen, `_.updates.to` höchstens Gegenprobe |
| Lock-Historie | 5 vs. 22 Commits | 22 (`git log --all`) stimmt; Schluss identisch: als Basis unbrauchbar |
| Parser-Zählung | „24 PARSER + 3“ (=27) vs. 26 `!`-Commits | **verifiziert: 23 Parser-Bumps + 3 echte = 26**; die Zahl vor Stufe 2 im Fixture einmalig festnageln |
| `git show -s` offline | geht vs. geht nicht | commit-abhängig → nur `git log`/`git diff-tree` |
| Blobless testbar | „nicht lokal“ vs. hermetisch baubar | hermetisch baubar (bestätigt), CI ungeprüft |

---

## 10. Verifikation und Lücken

**Vom Verifier bestätigt:** Lazys Zielauflösung; Event-Timing aus dem Quelltext;
`_.updated` nur im Speicher; Lazys Breaking-Erkennung nur Betreff;
`is_local`-Verhalten; die nvim-treesitter-Zahlen (86/0/26/23/3); Reflog-Befunde
(50× clone, 13× checkout, 12 Klone mit ≥ 2 HEADs); Lock gitignored (22 Commits nur
auf Alt-Branches, 497 vs. 86); Blobless überall, 12 detached; Offline-Matrix;
315 falsche Commits; Dashboard-/`kit.picker`-/lib.nvim-Befunde mit Zeilenzitaten;
`vim.version.range`-Prerelease-Falle; `vim.pack.get(nil,{info=false})` prozessfrei.
Lazy-Zeilennummern waren teils um 1–3 verrutscht (Befund unberührt).

**Nicht untersucht / dünn belegt** (ehrlich):

- Nie ein echtes `:Lazy sync`/`check` mit neuem Code ausgeführt; Event-Reihenfolge
  nur gelesen.
- **Nur diese Maschine.** Workstation (EDR, ~116 Klone, `SOURCE=remote`), Linux,
  macOS, andere git-Versionen, reftable: ungemessen. Clustering-Schwellen und
  Pool-Größen dort unverifiziert. Spawn-Kosten (120–390 ms) vom Verifier nicht
  nachgemessen.
- Reflog trägt nur **einen** echten Update-Lauf und 11 Tage Historie; ob auto-gc in
  den Klonen je Reflog-Einträge expired, nie beobachtet (nur Wegwerf-Repo).
- Breaking-Heuristik: **ein Beurteiler**, kleine Stichproben (KI „wahrscheinlich“
  29–58 %, „Hinweis“ 5–21 %), Recall nur aus 139 Blindstichproben mit 1 Treffer
  geschätzt; Fenster = letzte 300 Commits, nicht echte Update-Bereiche; keine
  nicht-englischen Betreffs.
- Laufzeitwirkung der Breaking Changes in deiner Config nicht geprüft.
- Latenz eines Promisor-Fetch nie gemessen (kein Netz); Mindestversion von
  `GIT_NO_LAZY_FETCH` (2.44 aus dem Gedächtnis) unverifiziert.
- Forge-URL-Pfade: GitHub aus Lazys Code belegt; **GitLab/Codeberg aus dem
  Gedächtnis**.
- UI: kein gerenderter Prototyp; Fensterverhalten nur in `nvim --clean`;
  Session-Plugins, einziger Tab (E784?), Fokus nach lazygit-Float offen.
- `vim.pack`-Pfad nur gegen einen Fake (0 Einträge real); Worktree/Submodul-Klone;
  Lazy-Sonderfälle (`version`+`branch`, `version=false`).
- Mehrere Rechner: Lock ist gitignored und maschinenlokal; falls du es später
  trackst, entsteht der Zustand „Restore ausstehend“ (`lock ≠ HEAD`), im Plan noch
  nicht ausgearbeitet.
- Bekannte Dashboard-Schulden (`update_all` vs. `gu` mit unterschiedlicher
  Repo-Menge, `features.*`-Doku-Falschaussage, `BINDINGS.md` ohne Generator,
  `docs/NOTES/BINDINGS-FORMAT.md` fehlt unter diesem Pfad) sind **nicht** Teil
  dieses Plans und sollen in Stufe 1 nicht stillschweigend mitverbessert werden.

---

## 11. Offene Fragen an dich (mit Empfehlung) — am 2026-10-07 entschieden, siehe Abschnitt 13

1. **Standardbasis:** „Was hat das letzte Update geändert“ (`updated`, Reflog,
   beantwortet den Anlass) oder „Was kommt noch“ (`pending`)? *Empfehlung:*
   beide, `updated` als Default mit Umschalter `t`.
2. **Fenster-Form:** eigener Tab (überlebt `:only`) vs. Float wie das Dashboard vs.
   `kit.picker`? *Empfehlung:* Tab als Default, Picker nur als `F`, `--out=popup`
   als Kurzblick.
3. **Auto-Trigger nach `:Lazy sync`:** aus / nur Toast / automatisch öffnen? Und
   `event='User LazySync'` im Install-Spec? *Empfehlung:* aus (Stufe 4a später).
4. **Darf gitsuite fetchen?** *Empfehlung:* v1 nein (Frische kommt von `:Lazy
   check`); expliziter, bestätigter `--fetch` erst in Stufe 4b.
5. **Welche Plugins zählen:** nur lazy-verwaltete Drittanbieter-Klone (hier 50,
   Workstation ~116) oder auch die 43 `dir`-Mode-Eigenplugins? *Empfehlung:*
   Eigen-Repos standardmäßig aus (`include_local`, `--all`).
6. **Mehrere Rechner / Lockfile:** Reflog + Store je Maschine reicht? Oder soll das
   Lock künftig getrackt werden? *Empfehlung:* je Maschine; Lock-Tracking nur,
   wenn du es willst (dann „Restore ausstehend“ nacharbeiten).
7. **Scope-Name/Zuschnitt:** `:Git plugins log|report|…` oder `:Git updates` oder
   Unterroute von `dashboard`? Soll die Vorstufe als `:Git log [target]` eigener
   Einzel-Repo-Befehl sein? *Empfehlung:* `plugins` wie entworfen.
8. **Nummerierung/Ablage:** seit der Task-Migration vom 2026-10-04 gibt es keinen
   GS-Zähler mehr (neue Arbeit = Task-Datei `gitsuite.nvim/ROADMAP/tasks/<slug>.md`
   mit ID `gitsuite.nvim/<slug>`); GS-32..39 sind im verworfenen Engine-Bericht
   reserviert, GS-40 wäre kollisionsfrei. Welches Schema? Bericht-Original bleibt
   hier unter `reports/`, im Vault nur ein Zeiger.
9. **KI-Zusammenfassung:** ja/nein? *Empfehlung:* nur als Config-Hook auf
   ausdrückliche Taste (Stufe 4c); Provider auf der Workstation nur Copilot/Claude.
10. **Aufbewahrung:** 5 Berichte, 90 Tage, 300 Commits je Plugin, Body ≤ 2 KB —
    passt das? Sollen Gesehen-Marken nie verfallen?
11. **Breaking-Gewichtung:** „sicher“+„wahrscheinlich“ sofort sichtbar, „Hinweis“
    eingeklappt? Neovim-Floor-Abstufung und Parser-Relevanz schon in v1?
12. **lib.nvim-Block L1** auch als Basis für `:MyPlugins sync` und das Dashboard
    (spätere Umstellung) oder deren Eigenbauten unangetastet lassen?
13. **Tasten:** `p` ist im Dashboard Push, im Report Preview — akzeptabel? Soll es
    eine Quickfix-Export-Taste geben (`Q`)?
14. **Browser öffnen:** `lib.nvim.cross.open_default` (keine Zusatz-Abhängigkeit,
    empfohlen) oder wie `browse` über open.nvim?

---

## 12. Karten-Skizzen und Ablage

Nur Skizzen (Format der bestehenden Karten); **verbindlich sind die Vault-Tasks aus
Abschnitt 13** (Entscheidung zu Frage 8: kein GS-Zähler, Task-Dateien).

| Karte (Skizze) | Slug | Art | Aufwand | Abhängigkeit |
| --- | --- | --- | --- | --- |
| GS-40 | `lib-git-log-runner-primitives` | TASKS | M (1,5–2) | — |
| GS-41 | `plugins-log-vorstufe` | FEATURES | M (1,5–2) | GS-40 |
| GS-42 | `plugins-report-updated-pending` | FEATURES | L (~4) | GS-41 |
| GS-43 | `plugins-breaking-classifier-digest` | FEATURES | M (2–3) | GS-42 |
| GS-48 | `ui-spike-picker-keys-viewer-focus` | TASKS | XS (0,5) | GS-41 |
| GS-44 | `plugins-report-ui-persistent` | FEATURES | L (3–4) | GS-43, GS-48 |
| GS-45 | `plugins-lazy-sync-hook-toast` | FEATURES | S (1) | GS-42 (sinnvoll ab GS-44) |
| GS-46 | `plugins-explicit-fetch` | FEATURES | M (2) | GS-42, GS-44 |
| GS-47 | `plugins-ai-summary-hook` | FEATURES | S (1) | GS-43 |

**Wiederverwendbares aus dieser Analyse** (liegt im Scratchpad dieser Session und
verschwindet mit ihm; bei Start von Stufe 2 sichern): `scratchpad/bc/` mit
`bc_tiers.py` (Regelstufen-Referenz), `fixture_corpus.json` (615 gelabelte Commits,
310 KB), `parity.lua` (vim.regex-Port), `make_fixture.py`. Empfehlung laut
`TOOL-PLACEMENT.md`: dauerhaft bleiben die **Daten** (kuratierter Fixture-Korpus +
Labels als `TESTS/fixtures/breaking/`), die **Definitionen** (Regelstufen als
Lua-Modul im Plugin) und ein Lua-Eval-Skript `TOOLS/scripts/breaking-eval.lua`
(`nvim -l`, Präzision je Stufe); die Python-Extraktionsskripte bleiben Wegwerf.

Der vollständige Roh-Output des Workflows (alle 10 Agents mit Belegen
`Pfad:Zeile`/Kommandos) liegt in
`~/.claude/projects/E--repos-gitsuite-nvim--claude-worktrees-nvim-config-continuation-0338eb/<session>/subagents/workflows/wf_7aaf7123-c9f/journal.jsonl`.

---

## 13. Entscheidungen vom 2026-10-07 und daraus entstandene Tasks

Alle 14 Fragen aus Abschnitt 11 wurden in vier Runden beantwortet; 13 davon exakt
nach Empfehlung, **Frage 10 (Aufbewahrung) bewusst „großzügiger“**.

| # | Thema | Entscheidung |
| --- | --- | --- |
| 1 | Standardbasis | `updated` als Default, Umschalter `t` zu `pending` (beide werden gebaut) |
| 2 | Fensterform | Eigener Tab + Preview-Split (`--out=tab`); Float nur als `--out=popup`, `kit.picker` nur als Schnellsprung `F` |
| 3 | Auto-Trigger nach `:Lazy sync` | **Aus**; Hook später als Opt-in (`plugins.after_sync`, Default `off`) |
| 4 | Fetch | v1 **nie**; expliziter, bestätigter `--fetch` erst in einer späteren Stufe |
| 5 | Umfang | Nur lazy-verwaltete Drittanbieter-Klone; Eigen-Repos per `--all` / `plugins.include_local` |
| 6 | Mehrere Rechner / Lock | Reflog + Store je Maschine; Lockfile bleibt gitignored, kein „Restore ausstehend“ in v1 |
| 7 | Scope-Name | `:Git plugins log\|report\|breaking\|clear`; Vorstufe ist kein eigener `:Git log` |
| 8 | Nummerierung/Ablage | Vault-Task-Dateien, **kein** GS-Zähler; Report-Original bleibt in `reports/` |
| 9 | KI | Nur als Config-Hook (`plugins.summarize`), später, nur auf Taste |
| 10 | Aufbewahrung | **Großzügiger:** `keep_reports=20`, `max_age_days=365`, `max_commits=1000` je Plugin, Body ≤ 2 KB, `seen_ttl_days=365` (statt 5 / 90 / 300 / 90) |
| 11 | Breaking-Gewichtung | „sicher“ + „wahrscheinlich“ sichtbar, „Hinweis“ eingeklappt, Parser/Bulk als eine Gruppe; Relevanz-Hebel (installierte Parser, Neovim-Floor) schon in v1 |
| 12 | lib.nvim-Block L1 | Erst für `plugins`; Umstellung von Dashboard und `:MyPlugins sync` als Folge-Task |
| 13 | Tasten | `p` = Preview (Abweichung zum Dashboard-Push, dokumentieren), `Q` = Quickfix-Export |
| 14 | Browser öffnen | `lib.nvim.cross.open_default` |

**Folge der Entscheidung zu Frage 10:** die Berichtsdatei kann deutlich größer
werden als die Schätzung im Abschnitt 5.3 (einige hundert KB bei ~1000 Commits, bei
20 Berichten bis einige MB). Der Task `plugins-report` verlangt deshalb, die
Dateigröße zu **messen** und ggf. einen Gesamtdeckel festzulegen (neuester Bericht
und Reviewed-Marker werden nie rotiert).

### Tasks im Vault (`gitsuite.nvim/ROADMAP/tasks/`, Tag `plugins-monitor`)

Reihenfolge und Kette (`blocked_by`) lassen sich mit `tasks plan gitsuite.nvim`
prüfen; sofort startbar sind **`lib-git-log-runner-primitives`** und
**`plugins-log`** (Letzteres wartet nur beim Push auf lib, `after` statt
`blocked_by`).

| Task (ID `gitsuite.nvim/…`) | Art | Prio / Aufwand | wartet auf |
| --- | --- | --- | --- |
| `lib-git-log-runner-primitives` | task | 2 / M | — |
| `plugins-log` (Stufe 0) | feature | 2 / M | (`after` lib-Block) |
| `plugins-report` (Stufe 1) | feature | 2 / L | `plugins-log` |
| `plugins-breaking-classifier` (Stufe 2) | feature | 2 / M | `plugins-report` |
| `plugins-ui-spike` | task | 2 / XS | `plugins-log` |
| `plugins-report-ui` (Stufe 3) | feature | 2 / L | Klassifikator, Spike |
| `plugins-lazy-sync-hook` (4a, optional) | feature | 3 / S | `plugins-report` |
| `plugins-explicit-fetch` (4b, optional) | feature | 3 / M | `plugins-report` |
| `plugins-ai-summary-hook` (4c, optional) | feature | 3 / S | Klassifikator |
| `plugins-adopt-lib-primitives` (Folge-Task zu Frage 12) | task | 3 / S | lib-Block, `plugins-log` |

Die Planberechnung des Task-Tools schätzt aus der Aufwandsskala **ca. 11,75
Personentage** (Spanne 8–18,75 d; kritischer Pfad 8 d über 4 Tasks). Das ist eine
andere Einheit als die „17–21 Sessions“ in Abschnitt 6 (Sessions inkl. CI-Warten,
Doku und Messungen) und kein Widerspruch.

