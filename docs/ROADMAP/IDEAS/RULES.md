# `rules.nvim`

**Konzept festgelegt:** 2026-09-12 · **Status:** v1-Engine implementiert und
verdrahtet (`:Rules check --family=<PREFIX>`, alle vier Check-Typen,
`DEP-*`-Pilot in `Checklists/regeln/LUA_NVIM.md` migriert, in `personal/init.lua`
konfiguriert, gegen echte Daten getestet). Offen: die drei Gates und
`--format=json`.

Ein Plugin, das eine Regelsammlung (wie `$REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists/`)
gegen ein konkretes Repo prüft — Dry-Run, Report, Quickfix. Das Plugin selbst ist
**inhaltlich leer**: es bringt die Engine, kein einziges Regelwort. Wessen Regeln
geprüft werden, bestimmt eine Config-Zeile (`rulesets = {...}`), nicht der Installer.

---

## Table of content

  - [Kernbefund aus der Praxis](#kernbefund-aus-der-praxis-p5-lauf-2026-09-05)
  - [Vokabular](#vokabular-rule-check-family-gate-ruleset)
  - [Ruleset-Format](#ruleset-format-fenced-rule-block-in-markdown)
  - [Befehle](#befehle)
  - [Wo das private Regelwerk lebt](#wo-das-private-regelwerk-lebt)
  - [v1-Scope](#v1-scope)
  - [Bewusste Nicht-Ziele](#bewusste-nicht-ziele)
  - [Zusätzliche Features](#zusätzliche-features-über-die-ursprüngliche-notiz-hinaus)
  - [Repo-Struktur](#repo-struktur)
  - [Entscheidungslog](#entscheidungslog)
  - [Status / nächste Schritte](#status--nächste-schritte)

---

## Kernbefund aus der Praxis (P5-Lauf, 2026-09-05)

Bevor das Konzept feststand, wurde das hier skizzierte Szenario einmal von Hand
durchgespielt: [`P5_WIEDERHOLUNGSLAEUFE_2026-09-05.md`](../personal/All/FINISH/ERLEDIGT/LAST_CDX_TASKS_2026-09-05/P5_WIEDERHOLUNGSLAEUFE_2026-09-05.md).
Drei Regel-Familien wurden dabei tatsächlich gegen den Katalog aus `Checklists/`
geprüft, mit völlig unterschiedlichem Ergebnis:

| Familie | Prüfmethode | Ergebnis |
| --- | --- | --- |
| `DEP-*` (7 Regeln, veraltete APIs) | ein `grep`-Pattern pro Regel über alle 32 Repos | **100 % mechanisch**, kein Urteil nötig |
| `SEC-*` (24 Regeln) | Agent pro Repo, vollständiger Regeltext, Quellcode gelesen | brauchte **echtes Urteil pro Fundstelle** — reines Pattern-Matching hätte den GitHub-Token-Leak in `github_stats.nvim` nicht von harmlosen Treffern unterschieden |
| `PRIN-*`/`LUA-*`/`ERR-*`/`UI-*`/`PERF-*` (~230 Regeln) | Pilot an `buffer-ctx.nvim`, volle Regeltexte gelesen | reine **Handprüfung** — Stunden pro Repo, laut Hochrechnung Tage bis Wochen über alle 32 |

**Konsequenz für das Konzept:** `rules.nvim` kann nicht versprechen, „die Regeln zu
prüfen". Es liefert für drei unterschiedliche Regel-Typen drei unterschiedliche
Dinge — und sagt bei jedem Lauf ehrlich, welches gerade greift. Ein Tool, das bei
einer reinen Urteilsregel ein automatisches ✅ vortäuscht, ist schlimmer als gar
keine Prüfung.

Ebenfalls aus der Praxis gelernt (P5, `8.1`): Bevor neue Prüfungen entstehen, zuerst
prüfen, ob es sie nicht schon gibt — `lib.nvim.bindings.audit` und
`lib.nvim.dev.duplicates` waren beide fertige Module, deren `create_usercmd()` aber
in keiner Config je aufgerufen wurde. **Modul fertig ist nicht dasselbe wie Befehl
tippbar** — das gilt für `rules.nvim` selbst genauso wie für alles, was es einbindet.

---

## Vokabular: Rule, Check, Family, Gate, Ruleset

- **Rule** — `{id, severity, check?, ...}`. Die **Family** ergibt sich aus dem
  ID-Präfix (`SEC-`, `PERF-`, `DEP-`, …) — keine separate Metadatenspalte, genau
  wie im bestehenden `Checklists/README.md`-Schema.
- **Check** (optional!) — die automatisierbare Teilmenge einer Regel:

  | Typ | Deckt ab | Beispiel |
  | --- | --- | --- |
  | `grep` (Pattern + Include/Exclude-Globs, optional `unless`-Gegenmuster) | `DEP-*` komplett, Teile von `SEC-*` | `vim.tbl_flatten()` |
  | `file_exists` / `file_absent` | `NEW-*`/`REL-*`-Struktur | README, LICENSE |
  | `json_key_absent` | `.luarc.json` ohne `workspace.library` | `NEW-36` |
  | `lua_predicate(repo_path)` | alles Komplexere | `stylua.toml`-`line_endings` gegen `.gitattributes` |
  | *(keiner)* | `PRIN-*`, die meisten `LUA-*`/`ERR-*`/`UI-*`/`PERF-*` | reine Urteilsregeln |

  Eine Regel ohne `check` ist der **Normalfall**, keine Lücke. `:Rules check`
  gibt für sie nie ein automatisches Verdikt aus, sondern eine **Worklist-Zeile**
  (ID, Titel, Link zur Regel) — zur Weitergabe an einen Menschen oder eine
  Agenten-Session, nicht zur automatischen Abhakung.
- **Family** — der ID-Präfix, zugleich die Einheit für `:Rules check --family=X`.
  Genau die Wellen-Logik, mit der `SEC-*` und `DEP-*` im P5-Lauf tatsächlich
  durchgearbeitet wurden — ein Repo gegen **alle** Familien auf einmal zu prüfen
  ist laut Hochrechnung ein mehrstündiges bis mehrtägiges Vorhaben und erzeugt
  einen Report, den niemand liest.
- **Gate** — ein benannter Regel-Ausschnitt, gebunden an einen Zeitpunkt
  (`new_project`, `review`, `release` — direkte Entsprechung zu `gates/*.md`;
  eigene Gates sind möglich).
- **Ruleset** — eine Sammlung von Rules + Metadaten (Name, Quelle). Wird per
  Config-Pfad geladen, nicht mitgeliefert.

## Ruleset-Format: Fenced `rule`-Block in Markdown

Kein Tabellen-Parsing (fragil — genau das Problem, das `Checklists/KONZEPT.md`
selbst mehrfach beschreibt: Struktur ändert sich, ein Parser auf Spaltenposition
bricht still). Kein Vollumzug nach Lua (verliert GitHub-Rendering, Syntax-Highlighting
der Prosa, das Lesen-während-des-Schreibens aus `WORKFLOW.md`). Stattdessen ein
fest getackter Fenced Block **pro Regel**, direkt in der Markdown-Datei:

````markdown
### `DEP-01` — `vim.loop` ohne Fallback

```rule
id = "DEP-01",
severity = "recommended",
check = { type = "grep", pattern = "vim%.loop%.", unless = "vim%.uv or vim%.loop" },
```

Seit Neovim 0.10 heißt die Uv-API `vim.uv`. Repos mit Floor < 0.10 brauchen
den Fallback `vim.uv or vim.loop`; darunter greift die Regel nicht.

> Beleg: gopath.nvim `alternate/helpers/directory.lua`, mdview.nvim (4 Module).
````

- Prosa, Beispiele, Belege, Cross-Links bleiben **exakt wie heute** — frei
  formuliert, GitHub-lesbar, git-diff-freundlich.
- Der Parser sucht nur nach dem Marker ` ```rule `, unabhängig davon, wie sich
  die Prosa drumherum entwickelt — ein stabiler Vertrag statt Tabellen-Raten.
- `load("return {" .. block .. "}")` macht daraus eine Tabelle. Kein YAML/JSON,
  keine neue Dependency, sicher, weil es die eigenen lokalen Dateien sind
  (gleiches Vertrauensniveau wie jedes `require()`).
- Eine Regel **ist** die Datei — kein generiertes Zwischen-Artefakt, das mit
  handgeschriebenen Checks kollidieren könnte. Prosa ändert sich, Check-Block
  bleibt unberührt, und umgekehrt.
- Funktioniert für jeden Nutzer mit eigenen Markdown-Checklisten, nicht nur für
  dieses Lua/Neovim-Regelwerk — das Format kennt kein Lua/Neovim, nur der
  Regel-Inhalt selbst tut es.

**Migration:** `Checklists/` bleibt vorerst im heutigen Tabellenformat. Nur die
für v1 gewählte Pilot-Familie `DEP-*` (7 Regeln) wird ins neue Format überführt,
über einen einmaligen Migrations-Helfer (`:Rules migrate-legacy-row <file>` —
Tabellenzeile → Heading + Fenced Block + Prosa-Stub) direkt in `rules.nvim`.
Kein Big-Bang-Rewrite von ~250 Regeln; weitere Familien wandern nur um, falls
sich das Format bewährt — wellenweise, wie schon `SEC-*`/`DEP-*` geprüft wurden.

## Befehle

Eng an den Situationen aus `Checklists/WORKFLOW.md`:

```
:Rules new-project                 -- NEW_PROJECT-Gate als Checkliste
:Rules review [--diff=<git-ref>]   -- REVIEW-Gate, per Default nur gegen den Diff
:Rules release                     -- RELEASE-Gate
:Rules check --family=<PREFIX> [path]  -- eine Regel-Familie, ganzer Baum (Wellen-Logik)
:Rules migrate-legacy-row <file>   -- Migrations-Helfer, s.o.
```

Ausgabe immer in die **Quickfix-Liste** (das ist `UI-36` aus dem eigenen Katalog:
Trefferlisten gehören dorthin, nicht nur in eine Plugin-eigene UI) plus ein
lesbarer Report-Float mit Severity-Icons (🔴/🟡/🟢, dieselbe Legende wie in
`Checklists/README.md`) und Link zur Regel-Doku. `--format=json` für
Headless/CI, nicht-0 Exit-Code bei 🔴-Funden (`NEW-40`: der Runner scheitert laut).

## Wo das private Regelwerk lebt

Nicht im Plugin. Reiner lokaler Pfad, exakt das Muster, das `pickers.nvim`s
`repos_dir` oder `documentation.nvim`s `root` schon vorleben:

```lua
require("rules").setup({
  rulesets = { vim.env.REPOS_DIR .. "/WKDBooks/Development/wkdbook-Lua/Checklists" }
})
```

Kein zweites Repo, keine Veröffentlichung des eigenen Regelwerks. Wer
`rules.nvim` installiert, bekommt ohne eigene `rulesets`-Angabe ein leeres oder
minimal-generisches Werkzeug — keine fremden Stilregeln aufgezwungen.

## v1-Scope

Volle Engine (Loader, alle vier Check-Typen, Gates, Report, Quickfix,
`:checkhealth`) + nur `DEP-*` als konvertierte Pilot-Familie (bereits vollständig
mechanisch, siehe oben). Rest von `Checklists/` bleibt Backlog — kein Aufwand,
~250 Regeln vorab zu übersetzen, bevor die Engine überhaupt läuft.

## Bewusste Nicht-Ziele

- **`LLS-*` (LuaLS-Diagnosen).** Wird bereits durch einen eigenen, aktiven
  Prozess (LuaLS + `luacheck`) auf 0 gehalten — explizit ausgeschlossen, damit
  es niemand „hilfsbereit" nachträgt.
- **Natives Binary (C/C++/Rust/Go) für Performance.** Die P5-Daten zeigen: der
  Flaschenhals ist nirgends Rechenzeit (der „mehrere Minuten statt Sekunden"-Fall
  bei `magic_numbers` war ein Scoping-Bug — Scan über 52 Ordner statt über
  einen —, kein Sprachproblem), sondern **Urteilszeit** bei den nicht-mechanischen
  Regeln. Ein natives Binary beschleunigt genau den Teil nicht, der langsam ist,
  kostet aber Cross-Compile/Distributions-Aufwand — widerspricht dem
  „keine zwei Implementierungen derselben Sache"-Grundsatz aus `TOOL-PLACEMENT.md`.
  `ripgrep` (schon überall im Ökosystem im Einsatz) ist für die mechanischen
  Checks bereits „nativ genug".
- **Automatisches Reparieren.** Die `SEC-*`/`DEP-*`-Wellenläufe haben gezeigt,
  was funktioniert: ein Agent bekommt Regeltext + Fundliste, entscheidet und
  committet selbst, pro Repo einzeln. `rules.nvim` ändert nie selbst Code — nur
  Report, Quickfix, optional eine Markdown-Worklist zur Weitergabe an eine
  Coding-Session.
- **Separates Preset-Repo für das eigene Regelwerk.** Entschieden gegen ein
  zweites Repo (s. o.) — reiner Config-Pfad reicht und hält Engine und Inhalt
  sauber getrennt.

## Zusätzliche Features (über die ursprüngliche Notiz hinaus)

- **Waiver-Datei pro Zielrepo** (`.rules-waivers.json` o. ä.):
  `{rule_id = "Begründung"}` — das Muster aus `NEW_PROJECT.md`: „was nicht
  zutrifft, wird abgehakt **mit Notiz**". Ohne das flaggt jeder Lauf dieselben
  bewusst akzeptierten Ausnahmen erneut.
- **ID-Kollisionsprüfung beim Laden.** Mehrere Rulesets dürfen nie dieselbe ID
  doppelt vergeben — billig zu prüfen, verhindert stille Verwechslung.
- **Engine sprachneutral.** Die vier Check-Primitive kennen kein Lua/Neovim —
  nur das eigene Beispiel-Ruleset ist es. Macht „generisches Regel-Werkzeug"
  in der Doku tatsächlich wahr, nicht nur Marketing.
- **Spätere Integration (v2, kein Kernfeature):** ein Tab in `documentation.nvim`s
  Browser-View über den stabilen `--format=json`-Export — das Rendern übernimmt
  `documentation.nvim`, `rules.nvim` liefert nur den Export.

## Repo-Struktur

Standard-Skelett aus `Checklists/gates/NEW_PROJECT.md`, nichts Neues erfunden:

```
rules.nvim/
  lua/rules/{config,engine/checks,report,gates,bindings}/...
  docs/RULESET-FORMAT.md   -- wie man eigene Rules/Checks schreibt
  doc/rules.txt, TESTS/, README.md, LICENSE, .luarc.json, stylua.toml
```

Abhängigkeit: `lib.nvim` (Compound-Command über `lib.nvim.usercmd.composer`,
`lib.nvim.progress`-Registry für lange Dry-Runs — Report während eines vollen
Familien-Durchlaufs, nicht erst am Ende). Bei der Umsetzung nicht vergessen,
woran es beim `lib.nvim`-Audit selbst schon einmal scheiterte: der Befehl muss
in `lua/plugins/personal/init.lua` tatsächlich verdrahtet **und** in einer
frischen Session getestet werden — „Modul funktioniert bei direktem `require`"
ist keine Abnahme.

Intern (nicht im öffentlichen Repo):
[`wkdbook-myplugins/rules.nvim/`](B:/repos/WKDBooks/Development/wkdbook-myplugins/rules.nvim/)
— `ROADMAP/` für zurückgestellte Ideen, `NOTES/` für Entwurfsentscheidungen.

## Entscheidungslog

| Datum | Entscheidung |
| --- | --- |
| 2026-09-12 | v1-Scope: volle Engine + nur `DEP-*` als Pilot-Familie, Rest bleibt Backlog |
| 2026-09-12 | Privates Regelwerk nur über lokalen Config-Pfad, kein zweites Repo |
| 2026-09-12 | Ruleset-Format: Fenced ` ```rule ` Lua-Tabellen-Block in Markdown statt Tabellen-Parsing oder Vollumzug nach Lua; Migrations-Helfer lebt als Dev-Subcommand in `rules.nvim` |
| 2026-09-12 | Repo `stefanbartl/rules.nvim` angelegt (MIT, `main`) |

## Status / nächste Schritte

- [x] Konzept abgestimmt und hier dokumentiert
- [x] Repo `stefanbartl/rules.nvim` angelegt, Minimalgerüst gepusht
- [x] `wkdbook-myplugins/rules.nvim/{ROADMAP,NOTES,handovers}` angelegt
- [x] Engine implementiert: Loader (Fenced-`rule`-Block-Parser, ID-Kollisionsprüfung),
      alle vier Check-Typen (`grep` inkl. `patterns`-Any-of, `file_exists`/`file_absent`,
      `json_key_absent`, `lua_predicate`), Runner, Report (Quickfix + lesbarer Buffer),
      `:checkhealth rules` — 31 Tests grün, `luacheck`/`stylua` grün
- [x] `DEP-*` (7 Regeln) in `Checklists/regeln/LUA_NVIM.md` ins Fenced-Block-Format migriert
- [x] Command in `personal/init.lua` verdrahtet (`rulesets` zeigt auf `Checklists/`)
      und in einer frischen headless Session gegen echte Daten getestet
      (`:Rules check --family=DEP` findet reale Treffer in `nvim-config` und im
      eigenen `rules.nvim`-Quellcode, `DEP-05` erscheint korrekt als Worklist statt
      als vorgetäuschtes ✅/❌)
- [ ] Gates (`new_project`/`review`/`release`) — zurückgestellt, bis eine zweite
      Regel-Familie sie sinnvoll ausübt (siehe `docs/ROADMAP.md` im Plugin-Repo)
- [ ] `--format=json` für Headless/CI

## Literatur und Referenzen

- [`Checklists/README.md`](B:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/README.md), [`WORKFLOW.md`](B:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/WORKFLOW.md), [`KONZEPT.md`](B:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/KONZEPT.md)
- [`P5_WIEDERHOLUNGSLAEUFE_2026-09-05.md`](../personal/All/FINISH/ERLEDIGT/LAST_CDX_TASKS_2026-09-05/P5_WIEDERHOLUNGSLAEUFE_2026-09-05.md)
- [`wkdbook-myplugins/TOOL-PLACEMENT.md`](B:/repos/WKDBooks/Development/wkdbook-myplugins/TOOL-PLACEMENT.md), [`HEREDOC.md`](B:/repos/WKDBooks/Development/wkdbook-myplugins/HEREDOC.md)
