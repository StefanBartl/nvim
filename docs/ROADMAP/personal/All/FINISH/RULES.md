# RULES — Stand der Checklists-Anwendung (WKDBooks/Checklists/regeln)

## Table of content

  - [Intro](#intro)
  - [Überblick: 9 Regel-Familien](#berblick-9-regel-familien)
  - [Aufwandsschätzung der verbleibenden Tasks](#aufwandsschtzung-der-verbleibenden-tasks)
  - [✅ LLS-* (34 Regeln) — fertig](#lls-34-regeln-fertig)
  - [✅ SEC-* (23 Regeln, `SEC-01`…`SEC-45`) — fertig](#sec-23-regeln-sec-01sec-45-fertig)
  - [✅ DEP-* (7 Regeln) — fertig](#dep-7-regeln-fertig)
    - [Ergebnis je Repo](#ergebnis-je-repo)
  - [✅ TS-* (5 Regeln) — fertig](#ts-5-regeln-fertig)
  - [🔶 ERR-* (34 Regeln) — in Arbeit](#err-34-regeln-in-arbeit)
  - [⬜ Noch nicht begonnen](#noch-nicht-begonnen)
  - [Methodik-Hinweise für den nächsten Durchlauf](#methodik-hinweise-fr-den-nchsten-durchlauf)

---

## Intro

Diese Datei trackt **ausschließlich**, welche Regeln aus
`$REPOS_DIR\WKDBooks\Development\wkdbook-Lua\Checklists\regeln\` (`PRINCIPLES.md`,
`LUA_NVIM.md`, `PERFORMANCE.md`) gegen welche der 32 Personal-Plugin-Repos
bereits angewendet wurden — nicht die allgemeine Doku-Standardisierung
(dafür: `LAST_CDX_TASKS_2026-09-05/`). Zweck: in ein paar Wochen, wenn die
Checklists erneut vollständig durchlaufen werden, hier ansetzen können statt
bei null anzufangen.

**Quelle der Wahrheit für die Regel-Texte selbst bleibt der Regelkatalog.**
Diese Datei fasst nur zusammen, was geprüft wurde und was dabei rauskam. Der
volle Wortlaut jedes Funds (inkl. Begründung, warum ein Rule N/A ist) steht in
[`ERLEDIGT/LAST_CDX_TASKS_2026-09-05/P5_WIEDERHOLUNGSLAEUFE_2026-09-05.md`](./ERLEDIGT/LAST_CDX_TASKS_2026-09-05/P5_WIEDERHOLUNGSLAEUFE_2026-09-05.md).

---

## Überblick: 9 Regel-Familien

| Familie | Regeln | Datei | Status |
|---|---|---|---|
| `LLS-*` | 34 | (LuaLS-Diagnostics, kein Katalog-File — mechanisch per Scan-Tool) | ✅ **fertig** — alle 32 Repos auf 0 |
| `SEC-*` | 23 (`SEC-01`…`SEC-45`, lückenhaft nummeriert) | `LUA_NVIM.md` | ✅ **fertig** — alle 32 Repos geprüft |
| `DEP-*` | 7 | `LUA_NVIM.md` | ✅ **fertig** — alle betroffenen Repos gefixt |
| `TS-*` | 5 | `LUA_NVIM.md` | ✅ **fertig** — alle 32 Repos geprüft, 0 Befunde |
| `ERR-*` | 34 | `LUA_NVIM.md` | 🔶 **in Arbeit** — 30/32 Repos gelesen, 16 echte Bugs gefixt |
| `PRIN-*` | 37 | `PRINCIPLES.md` | ⬜ nicht begonnen |
| `UI-*` | 34 | `LUA_NVIM.md` | ⬜ nicht begonnen |
| `LUA-*` | 45 | `LUA_NVIM.md` | ⬜ nicht begonnen |
| `PERF-*` | 57 | `PERFORMANCE.md` | ⬜ nicht begonnen |

**Zählung mit Vorsicht genießen, aber verifiziert (2026-09-05):** Der Katalog
listet Regeln teils als Tabellenzeilen, teils als Aufzählungspunkte
(`- \`ERR-10\` …`) in nachfolgenden Unterabschnitten. Ein erster Grep-Versuch
fing nur Tabellenzeilen und hielt `ERR-*` fälschlich für 7 Regeln (statt 34) —
korrigiert per:

```bash
for f in $REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists/regeln/*.md; do
  grep -oE '`[A-Z]+-[0-9]+`' "$f" | tr -d '`' | sort -u
done | sed -E 's/-[0-9]+$//' | sort | uniq -c | sort -rn
```

**Gesamtaufwand-Einordnung** (Pilot `buffer-ctx.nvim`, 2026-09-05, siehe
P5-Doku §8.2 Pilot-Abschnitt): eine vollständige Prüfung aller ~250
Einzelregeln gegen alle 32 Repos ist ein **mehrtägiges bis mehrwöchiges
Vorhaben**. Empfehlung, die sich bislang bewährt hat: eine Regel-Familie nach
der anderen, komplett über alle 32 Repos, statt ein Repo gegen alle Familien
auf einmal — kleinste/mechanischste Familien zuerst.

---

## Aufwandsschätzung der verbleibenden Tasks

Kurz vorab: das ist eine Schätzung, keine Messung wie bei DEP-*/SEC-*/TS-* — aber ich kann sie an echten Zahlen aus diesem Sweep festmachen statt aus der Luft zu greifen.

**Der eigentliche Kostentreiber ist nicht "Regeln pro Familie", sondern "Repo-Durchgänge".** Beim Lesen eines Repos prüft man ohnehin alle anwendbaren Regeln einer Familie in einem Rutsch — ob eine Familie 23 oder 57 Regeln hat, ändert die Zeit pro Repo-Besuch nur graduell, nicht proportional. Der Referenzwert dafür ist `SEC-*` (23 Regeln, echt kontextabhängig): **32 Repo-Durchgänge, an einem einzigen Tag durchgezogen** — aber mit bis zu 3 parallelen Agenten für die ersten 21 Repos. Das Agenten-Limit ist seitdem auf 1 gleichzeitig verschärft worden, künftige Wellen brauchen also mehr Runden für dieselbe Abdeckung als `SEC-*` gebraucht hat. `TS-*` (5 Regeln, rein mechanisch) hat den Umkehrschluss bestätigt: 3 Greps über alle 32 Repos auf einmal, keine einzelnen Durchgänge nötig, weil kein Repo überhaupt eigene Query-Dateien mitbringt — <1 Sitzung, wie vorhergesagt.

| Familie | Regeln | Repo-Durchgänge nötig | Einschätzung relativ zu `SEC-*` |
|---|---|---|---|
| `ERR-*` | 34 | ~32 | ähnliche Größenordnung wie `SEC-*`, leicht mehr pro Durchgang |
| `UI-*` | 34 | ~32 | wie `ERR-*` |
| `PRIN-*` | 37 | ~32 | wie `ERR-*`/`UI-*`, aber unschärfere Regeln → mehr Ermessensfälle, potenziell mehr Rückfragen an dich statt reinem Abhaken |
| `LUA-*` | 45 | ~32 | viele Treffer sind vermutlich Stilfragen statt Bugs → mehr Bewertungsaufwand pro Fund |
| `PERF-*` | 57 | ~32 | **größte und teuerste** — Hotpath-Beurteilung braucht Verständnis von Aufrufhäufigkeit, nicht nur Pattern-Matching; wahrscheinlich allein so aufwendig wie zwei der mittleren Familien zusammen |

**Fazit:** Die übrigen fünf Familien brauchen je ~32 echte Repo-Durchgänge, macht zusammen grob **160 Repo-Durchgänge** — bei reduzierter Parallelität eher mehr Sitzungen als die eine, die `SEC-*` gebraucht hat. Realistisch bewegt sich das im Bereich von **mehreren vollen Arbeitstagen bis zu zwei, drei Wochen verteilter Sessions**, wenn's wie bisher Familie für Familie durchgezogen wird — deckt sich mit der Einschätzung, die schon im Pilot-Abschnitt der Datei steht ("mehrtägig bis mehrwöchig"), mit `PERF-*` als vermutlich größtem Einzelbrocken darin.

---

## ✅ LLS-* (34 Regeln) — fertig

**Methode:** `scripts/luals-scan/scan.sh` — mechanischer Vorher/Nachher-Scan,
kein Katalog-Text nötig (die Regeln *sind* LuaLS-Diagnostics).

**Ergebnis:** Alle 32 Repos bei 0 Befunden.

- **20 von 32 Repos** waren beim Start bereits durch einen unabhängigen
  `fix(luals)`-Durchgang auf 0 (per `git log --grep "fix(luals)"` verifiziert,
  nicht nur behauptet).
- **12 Repos + lsp.nvim** (13 insgesamt) wurden am 2026-09-05 gezielt
  nachgezogen:

| Repo | Vorher | Befund |
|---|---|---|
| cascade.nvim | 0 | bereits sauber |
| casedesk.nvim | 0 | bereits sauber |
| color_my_ascii.nvim | 0 | bereits sauber |
| github_stats.nvim | 0 | bereits sauber |
| language.nvim | 0 | bereits sauber |
| replacer.nvim | 0 | bereits sauber |
| lsp.nvim | 0 | zwischenzeitlich unabhängig fertig geworden |
| documentation.nvim | 1 | `opts.hover` fehlte auf `Documentation.Opts` |
| hover.nvim | 1 | `vim.deepcopy` auf einem Feld, das auch `boolean` sein darf |
| insights.nvim | 2 | dieselbe Lücke wie documentation.nvim, zwei Klassen |
| pickers.nvim | 1 | bewusste Unterdrückung (Test prüft Abwesenheit von `search_dirs`), kein Bug |
| reposcope.nvim | 1 | `"hover"` fehlte im `ConfigOptionKey`-Enum |
| markdown.nvim | 35 gemeldet | **Messartefakt** — Scan-Tool injiziert `hover.nvim`s Library nicht; im echten Editor 0 Diagnostics. Für `scripts/luals-scan` vorgemerkt, nicht im Plugin behoben |

Fünf echte Ein-Zeiler-Funde, alle aus derselben Ursache: die neue,
optionale `hover.nvim`-Integration fehlte in der jeweiligen Typdeklaration.

---

## ✅ SEC-* (23 Regeln, `SEC-01`…`SEC-45`) — fertig

**Methode:** Runden 1–7 zu 3 parallelen Agenten (je einer pro Repo, vollen
Katalog geprüft, echte Ein-Zeiler-Funde selbst behoben); ab Runde 8
(Sitzungslimit) ein Repo pro Durchgang, ohne Agent.

**Ergebnis: alle 32 Repos geprüft, 18 mit mindestens einem echten Fund.**

| Repo | Befund | Regel(n) |
|---|---|---|
| buffer-ctx.nvim | 0 | — |
| cascade.nvim | 0 (keine SEC-Angriffsfläche) | — |
| casedesk.nvim | fehlendes `cwd` auf zwei `vim.system`-Aufrufen | SEC-02 |
| cmdlog.nvim | 0 (Lücke bereits durch `redact_patterns` geschlossen) | — |
| color_my_ascii.nvim | `:Fence run`/`format` ohne `cwd` | SEC-02 |
| dap.nvim | `zig build`-Spawn ohne `cwd` | SEC-02 |
| debugging.nvim | Statuszeile spleißte Filetype/Colorscheme ungeschützt in Vimscript-`echo` | SEC-03 |
| diff.nvim | HTTP-Fetch hatte Timeout, aber kein Byte-Limit | SEC-21 |
| documentation.nvim | Manifest-Restore prüfte nur Top-Level-Form, nicht Feldtypen | SEC-33 |
| emojis.nvim | 0 | — |
| fileops.nvim | 0 | — |
| filetree.nvim | 0 (inkl. PowerShell-/AppleScript-Escaping verifiziert) | — |
| **github_stats.nvim** | **GitHub-Token im Shell-String, sichtbar im Prozess-Argv**; `fetch_json` ganz ohne Timeout | **SEC-01/03/10**, SEC-21 |
| gopath.nvim | Lua-Patterns aus Treesitter-Text ungeschützt (×2); persistiertes JSON ungeprüft übernommen | SEC-30 ×2, SEC-33 |
| hover.nvim | 0 (Erstdurchlauf, durchgehend defensiv gebaut) | — |
| **images.nvim** | **Linux-Clipboard-Paste baute Shell-String mit Zielpfad in einfachen Anführungszeichen — echte Command-Injection-Fläche** | **SEC-01/03** |
| insights.nvim | sequentielle `git`/`rg`-Aufrufe ohne `cwd` | SEC-02 |
| language.nvim | gemeldetes Wort ungeschützt in `:spellgood!`-String gespleißt | SEC-01/03 |
| lib.nvim | `spawn_shell_command` ohne `cwd`; `curl.download` löschte abgeschnittene Datei bei Fehlschlag nicht | SEC-02, SEC-21 |
| lsp.nvim | `prettier_format` spawnte ohne `cwd` | SEC-02 |
| markdown.nvim | 0 | — |
| mdview.nvim | Release-Downloads ohne Timeout/Byte-Limit; kaputte Binary hätte Checksum-Prüfung umgangen | SEC-20/21 |
| open.nvim | 0 im Repo — **aber Fund im mitbenutzten `lib.nvim`** (`win_reveal.ps1`, `"` in WSL-Pfad hätte `explorer.exe`-Argumente einschmuggeln können) | SEC-01/03 |
| pdfport.nvim | 0 (durchweg vorbildlich — API-Key nie über argv) | — |
| pickers.nvim | `additional_args` nicht shellescaped (eine Lücke in sonst durchgängigem Muster) | SEC-03 |
| recommender.nvim | 0 (kein Prozess-Spawn im ganzen Repo) | — |
| replacer.nvim | Checkpoint-Manifest ungeprüft → Arbitrary-File-Write via `:ReplaceUndo` möglich | SEC-33 |
| **reposcope.nvim** | **Keines der drei Network-Tools (curl/wget/gh) hatte je einen Timeout — breitester Einzelfund der Welle** | **SEC-21, systemisch** |
| runtime-analysis.nvim | 0 (kein Prozess-Spawn im Repo selbst) | — |
| sandbox.nvim | 0 (durchgängig argv-basiert über alle drei Engines) | — |
| sessions.nvim | 0 (liest `.git/HEAD` direkt statt zu spawnen) | — |
| spotlight.nvim | 0 (Snapshot-Restore vorbildlich: Regex immer aus rohem Text neu gebaut) | — |

**Fett = reale Schwachstellen, nicht nur Kosmetik** (3 von 18 Funden).

**Nebenbefund außerhalb der Familie:** `pdfport.nvim`s `platform.open_cmd()`
lieferte unter Windows das bloße Wort `"start"` (cmd.exe-Builtin, keine
Datei) — ein echter Funktionsbug, als Follow-up-Task ausgelagert statt
mitgefixt, inzwischen vom Autor selbst behoben (`7d5b9ec`,
`lib.nvim.cross.open_default`).

---

## ✅ DEP-* (7 Regeln) — fertig

**Methode:** rein mechanisch — ein Grep pro Regel-Pattern über alle 32 Repos
auf einmal, kein Agent nötig.

| Regel | Muster | Treffer |
|---|---|---|
| `DEP-01` | `vim.loop` (ohne `vim.uv or`-Fallback) | 5 Repos |
| `DEP-02` | `termopen()` | 3 Repos (5 Aufrufstellen) |
| `DEP-03` | `nvim_buf_add_highlight()` | 0 |
| `DEP-04` | `nvim_err_writeln()` / `nvim_out_write()` | 0 |
| `DEP-05` | `sign_define()` außerhalb Diagnostics | 0 (Treffer sind DAP-/eigene Plugin-Signs oder korrekt `<0.10`-gegated) |
| `DEP-06` | `vim.tbl_flatten()` | 0 |
| `DEP-07` | `nvim_buf_get_option()` | 0 (nur eine Prosa-Erwähnung in einer README) |

---

### Ergebnis je Repo

| Repo | Regel | Status | Commit |
|---|---|---|---|
| gopath.nvim | DEP-01 | ✅ gefixt | `a33f515`, `b53bc0b` |
| markdown.nvim | DEP-01 (3 Module) | ✅ gefixt | `9fd5d6c` |
| mdview.nvim | DEP-01 (4 Module) | ✅ gefixt | `997fe47` |
| reposcope.nvim | DEP-01 | ✅ gefixt | `fe06de7` |
| github_stats.nvim | DEP-01 (`config/init.lua`, `storage.lua`) | ✅ gefixt | `7947a2d` |
| debugging.nvim | DEP-02 (`tools/proc_trace.lua:135`) | ✅ gefixt | `254eca0` |
| filetree.nvim | DEP-02 (`features/system/shell_run/init.lua:76`) | ✅ bereits korrekt gegatet — Grep-Fehlalarm (String taucht nur in Kommentar/Fallback-Zweig auf) | — |
| sandbox.nvim | DEP-02 (5 Stellen: docker/nerdctl/podman `exec_in_container.lua`, `wsl/exec_in_distro.lua`, `bindings/usrcmds/container_commands_buffer.lua`) | ✅ gefixt (inkl. Testfix `exec_workdir_spec.lua`, volle Suite grün) | `fd2646c` |

**Fix-Muster DEP-01:** `vim.loop` → `vim.uv or vim.loop`, passend zur bereits
im jeweiligen Repo etablierten Konvention (nicht bloßes `vim.uv`, auch wenn
der Floor 0.10+ ist — Konsistenz mit dem Rest der Datei/des Repos hat
Vorrang). `mdview.nvim` hat sogar einen echten 0.9+-Floor, dort ist der
Fallback nicht nur Konvention, sondern zwingend.

**Fix-Muster DEP-02:** `vim.fn.has("nvim-0.11") == 1` gate →
`vim.fn.jobstart(cmd, { term = true })`, sonst `---@diagnostic
disable-next-line: deprecated` + `vim.fn.termopen(cmd)`. Alle drei
betroffenen Repos haben einen Floor < 0.11 (debugging.nvim 0.9+,
filetree.nvim/sandbox.nvim 0.10+), daher ist der Fallback-Zweig zwingend,
nicht nur Kosmetik. **Falle:** ein Test, der nur `vim.fn.termopen` mockt,
bricht lautlos, sobald die lokale/CI-nvim-Version ≥0.11 ist und der Code
in den `jobstart`-Zweig läuft (echter Spawn-Versuch statt Mock) —
`sandbox.nvim`s `exec_workdir_spec.lua` musste deshalb beide Funktionen
stubben.

**8 von 8 betroffenen Repos durch — DEP-* komplett fertig.**

---

## ✅ TS-* (5 Regeln) — fertig

**Methode:** rein mechanisch, kein Agent nötig — `TS-01`…`TS-03`/`TS-05`
setzen eigene Query-Dateien bzw. Query-Strings voraus, `TS-04` einen
Threadpool-Job, der `vim.treesitter` von außerhalb des Main-Threads aufruft.
Alle vier Muster lassen sich per Grep über alle 32 Repos auf einmal
entscheiden:

```bash
find <32 Repos> -type d -iname queries          # eigene Query-Dateien (.scm)?
grep -rlE 'query\.parse|#match\?|#any-match\?|#eq\?|#has-parent\?|;; extends|;; inherits' --include='*.lua' <32 Repos>
grep -rln 'new_work|uv_work' --include='*.lua' <32 Repos>   # TS-04: Treesitter im Threadpool?
```

**Ergebnis: alle 32 Repos geprüft, 0 Befunde.**

| Regel | Worum es geht | Befund |
|---|---|---|
| `TS-01` | Directives vs. Predicates | Kein Repo nutzt Directives (`#set!`/`#offset!`/`#gsub!`/`#trim!`) überhaupt; das einzige Predicate im ganzen Fleet ist ein korrektes `#eq?` (`documentation.nvim/lua/documentation/core/check.lua:768`) |
| `TS-02` | `#match?` vs. `#any-match?` | Kein Repo nutzt `#match?`/`#any-match?` auf einem quantifizierten Capture — Regel greift nirgends |
| `TS-03` | `;; extends`/`;; inherits` | **Kein einziges Repo hat eine eigene `queries/`-Datei** (`find -iname queries` über alle 32 Repos: leer) — Regel ist repo-weit gegenstandslos |
| `TS-04` | Kein `vim.treesitter` außerhalb des Main-Threads | Kein Treffer für `uv.new_work`/`vim.loop.new_work`/Threadpool im ganzen Fleet. Die Repos mit echter TS-lastiger Analyse (`documentation.nvim`, `gopath.nvim`, `insights.nvim`, `recommender.nvim`) parsen synchron auf dem Main-Thread oder lagern auf externe Prozesse aus (`jobstart`) — genau das vom Regel-Text empfohlene Muster |
| `TS-05` | Captures sind nie vordefiniert | Ohne eigene `queries/highlights.scm` (siehe `TS-03`) kann kein Repo diese Regel überhaupt verletzen |

14 Fundstellen mit `vim.treesitter.query.parse(...)`-Inline-Query-Strings
existieren (v. a. `documentation.nvim`, plus `gopath.nvim`, `insights.nvim`,
`recommender.nvim`, `debugging.nvim`) — alle sind reine Lua-Struktur-Parses
(`(identifier) @id`, `(function_declaration ...) @decl` u. ä.) für
Code-Analyse, keine Highlight-Queries, und keiner davon verletzt eine der
fünf Regeln.

**Fazit:** `TS-*` ist eine Familie, die für dieses Fleet strukturell nicht
greift — kein Repo bringt eigene Treesitter-Query-Dateien mit. Bestätigt die
Einschätzung aus der Aufwandsschätzung oben (ein Sitzung, meist N/A).

---

## 🔶 ERR-* (34 Regeln) — in Arbeit

**Methode:** anders als `DEP-*`/`TS-*` sind die meisten `ERR-*`-Regeln
kontextabhängig und brauchen echtes Lesen des Quelltexts — direkt in der
Unterhaltung statt per Subagent, damit der Fortschritt live nachvollziehbar
bleibt (siehe `feedback_agent_limits_and_language`-Notiz in Claudes Memory:
„repo-für-repo, lieber ohne Subagent, wenn es passt"). Genau wie bei `SEC-*`
zählen nur **echte, demonstrierbare Bugs** (falsches Ergebnis, Datenverlust,
Absturz) als Fund — reine Layering-Abweichungen (z. B. `notify()` in einem
„core"-Modul, ohne dass daraus ein falsches Verhalten folgt) werden notiert,
aber nicht als Bug gegen jedes einzelne Repo gefixt; das wäre ein
Architektur-Umbau, kein Ein-Zeiler-Fix, und käme einer Design-Entscheidung
gleich, die nicht mal eben nebenbei getroffen wird.

**Zwei Muster wurden zusätzlich fleet-weit per Grep über alle 32 Repos
geprüft (nicht nur in den einzeln gelesenen Repos), weil sie sich mechanisch
fassen lassen:**

1. **Die `cond and A>B or C<D`-Falle** (der Bug-Typ, der in buffer-ctx.nvim
   und zweimal in fileops.nvim gefunden wurde, s.u.) — ein
   `table.sort`-Comparator-Idiom, bei dem der mittlere Zweig selbst ein
   Boolean ist und dadurch bei `false` in den `or`-Zweig durchfällt.
   **Wichtige Falle beim Grep selbst:** die erste Fassung des Patterns
   (einfache Bezeichner, keine Methodenaufrufe) übersah fileops.nvims Form
   `a:lower() < b:lower()`, weil `:`/`()` nicht in der Zeichenklasse waren —
   erst die erweiterte Fassung fand beide Stellen:
   `\band\b\s*\(?[\w.:()]+\s*[<>=~]=?\s*[\w.:()]+\)?\s+\bor\b\s*\(?[\w.:()]+\s*[<>=~]=?\s*[\w.:()]+\)?`.
   Nach beiden Fixes: **0 verbleibende Treffer im ganzen Fleet** (die
   restlichen 6 Treffer sind reine Boolean-Kombinationen in `if`-Bedingungen,
   keine Wert-Ternaries, einzeln geprüft und harmlos).
2. **Das `X.read(...) or {...Stub...}`-vor-`write()`-Muster**, das in
   casedesk.nvim zum echten Datenverlust-Bug führte (s.u.): Grep
   `\.read\([^)]*\)\s*or\s*\{` über alle 32 Repos — **Treffer nur in
   casedesk.nvim** (3 Stellen, siehe unten), sonst nirgends im Fleet.

**Lehre für den Rest der Familie:** ein Grep-Pattern für einen Bug-Typ, der
bei Repo 1 in einfacher Form auftaucht, sollte nicht als „fleet-weit
erledigt" gelten, bevor es auch gegen Methodenaufruf-Varianten (`a:foo()`),
Klammern und Indexzugriffe (`t[i]`) getestet wurde — genau das hat den
fileops.nvim-Fund beim ersten Durchgang durchrutschen lassen.

**Ab Repo 11 (github_stats.nvim/gopath.nvim/documentation.nvim): auf
explizite Nutzer-Anweisung 3 parallele Agenten statt Direktarbeit in der
Unterhaltung** — ein Agent pro Repo, volle Regel-Familie inkl. Fix-Pflicht,
Testsuite, `git stash`-Verifikation des Regressionstests und
Commit+Push, mit derselben Vorgehensweise wie in dieser Datei dokumentiert.
Zwei weitere, bis dahin unbekannte Bug-Unterarten kamen dabei zum
Vorschein — s. Tabelle: **curated Listen indexweise statt wholesale
gemergt** (gopath.nvim, ERR-52 — bislang nur aus dem Regeltext bekannt, nie
real gefunden) und **ein Config-Accessor gibt die lebende Tabelle per
Referenz zurück, ein Caller sortiert sie danach in-place** (github_stats.nvim
— eine neue Variante der Referenz-Aliasing-Fallen, nicht in ERR-52/53 exakt
so benannt, aber dieselbe Familie: geteilter Zustand, der sich unbemerkt
verändert).

### Ergebnis je Repo (Stand dieser Sitzung, 30/32)

| Repo | Befund | Regel(n) | Commit |
|---|---|---|---|
| **buffer-ctx.nvim** | **`:Format sort -r`/`-r -n` sortierte falsch** — Comparator `reverse and na > nb or na < nb` fiel bei `na < nb` in den `or`-Zweig und lieferte für praktisch jedes ungleiche Paar `true` zurück (kein gültiges `table.sort`-Kriterium mehr) | **ERR-60** | [`2232614`](https://github.com/StefanBartl/buffer-ctx.nvim/commit/2232614) |
| **casedesk.nvim** | **`meta.patch()` konnte ein kaputtes `.case.json` durch einen fast leeren Stub ersetzen** — `meta.read()` gab für „fehlt" und „kaputt" identisch `nil` zurück, `patch()` behandelte beides gleich und schrieb bei jedem Einzelfeld-Update (SLA-Priorität, `last_reply_sent`, ...) einen `{case,year,links}`-Stub, der Titel/Firma/Notizen/... unwiderruflich verwarf | **ERR-11** | [`ed1a5f0`](https://github.com/StefanBartl/casedesk.nvim/commit/ed1a5f0) |
| **fileops.nvim** | **`case_insensitive`-Cycle-Navigation sortierte an zwei Stellen falsch** (`list_files` + der „current file not in list"-Fallback in `navigate`) — Comparator `ci and (a:lower()<b:lower()) or (a<b)` fiel bei `ci=true` und `a:lower()>=b:lower()` in den case-SENSITIVEN `or`-Zweig zurück; für Groß-/Kleinschreibungs-Paare lieferten beide Vergleichsrichtungen `true` (ungültiger Comparator) | **ERR-60** | [`00ba2fc`](https://github.com/StefanBartl/fileops.nvim/commit/00ba2fc) |
| **documentation.nvim** | **`trail_store.load()` konnte bei kaputtem `trails.json` alle Pins/gespeicherten Trails aus JEDEM Repo verlieren** — „Datei fehlt" und „Datei korrupt" kollabierten beide auf ein leeres `db = {}`; `flush()` schreibt immer die GANZE Datei (alle Repos in einer Datei), also hätte der nächste Pin (egal in welchem Repo) die kaputte Datei durch eine fast leere ersetzt. Anders gelöst als bei casedesk.nvim (dort: Schreiben verweigern) — hier: Backup nach `trails.json.corrupt` vorm nächsten Überschreiben, weil ein hartes Verweigern *jeden* Pin in *jedem* Repo blockiert hätte, bis jemand manuell eingreift | **ERR-11** | [`2e0b57b`](https://github.com/StefanBartl/documentation.nvim/commit/2e0b57b) |
| **github_stats.nvim** | **`config.get_repos()` gab die lebende `config.repos`-Tabelle per Referenz zurück**, und `dashboard.render.sort_repos()` sortiert `state.repos` (die exakt diese Tabelle ist) bei JEDEM Rendern in-place — das bloße Öffnen des Dashboards hat die Repo-Reihenfolge der Config für den Rest der Session dauerhaft verändert, inkl. `fetcher.fetch_all`, Export „all", Tab-Completion, `health.lua`, `retention.lua` | **ERR-52/53-Familie** (Referenz-Aliasing) | [`ffadc2d`](https://github.com/StefanBartl/github_stats.nvim/commit/ffadc2d) |
| **gopath.nvim** | **Config-Merge mergte curated Listen indexweise statt wholesale** — `deep_merge_into` rekursierte in JEDES Tabellenfeld gleich, auch reine Arrays; ein Nutzer-Override `order = {"treesitter"}` (auf einen einzigen Resolver einschränken) ergab real `{"treesitter","treesitter","builtin"}` — `builtin` lief trotz explizitem Ausschluss weiter. Dasselbe für `excluded_dirs` (7 Default-Einträge, 6 blieben trotz Override bestehen) | **ERR-52** (der bislang nur aus dem Regeltext bekannte, nie real gefundene Fall) | [`1e41349`](https://github.com/StefanBartl/gopath.nvim/commit/1e41349) |
| cascade.nvim | 0 (durchgängig sauber: `table.sort`-Comparatoren explizit if/else, Config-Normalisierung degradiert Einzelwerte statt abzubrechen (ERR-22-Muster), Autor-Kommentar bestätigt „synchronous-only, kein `defer_fn`") | — | — |
| cmdlog.nvim | 0 echter Bug — `core/store.lua`/`core/favorites.lua` notifizieren direkt aus „core"-Modulen (ERR-04-Layering-Abweichung, aber kein falsches Verhalten), nicht gefixt | (ERR-04, notiert) | — |
| color_my_ascii.nvim | 0 (Debounce-/Cache-Manager und die async `:Fence format`/`run`-Callbacks vorbildlich per Extmark + `nvim_buf_is_valid` gegen Stale-State abgesichert) | — | — |
| dap.nvim | 0 (Coroutine-Resume-Pfade für Attach-Picker/Zig-Build sauber dokumentiert, `cwd`-Fix aus SEC-* bestätigt noch vorhanden) | — | — |
| debugging.nvim | 0 (defer_fn-Callbacks in `views/display.lua`/`bindings/autocmds.lua` validieren Fenster-Handles durchgängig neu — das im Katalog selbst zitierte ERR-33-Positivbeispiel) | — | — |
| diff.nvim | 0 (`render.three_way`/`side_by_side`/`inline` validieren `origin_win` am Ausführungszeitpunkt, auch nach verketteten Async-Resolves für Drei-Wege-Diffs) | — | — |
| emojis.nvim | 0 (Preview-vor-Mutation-Callback in `actions.lua` validiert den Buffer sowohl vorm Löschen des Preview-Highlights als auch in der eigentlichen Mutation erneut) | — | — |
| filetree.nvim | 0 — **124 Dateien, größtes bisher geprüftes Repo dieser Familie**: Checklist + gezielte Stichproben in den Risikobereichen (Batch-Rename ist best-effort statt fail-fast/ERR-42, `refs/apply.lua` verifiziert jede Zeile gegen den aktuellen Inhalt vorm Schreiben/ERR-30, rekursive Walks delegieren an `lib.nvim.fs.collect_recursive` statt eigener Logik — Symlink-Zyklus-Schutz dort zu prüfen, nicht hier noch mal), kein file-für-file-Read aller 124 Dateien | — | — |
| hover.nvim | 0 — sehr gründlich geprüft (1971-Zeilen-`init.lua` komplett gelesen): Generation-Counter für Async konsequent über `show`/`scroll`/`resize`/`zoom`/`nav`/`zen`, Dedup nach Key in den Preview-Modulen (Browser/Download/Konvertierung wird nicht doppelt gestartet), Code kommentiert seine eigene Regel-Konformität explizit (`ERR-04`, `ERR-10`, `ERR-20`, `ERR-52`, `ERR-64` u.a. direkt im Quelltext referenziert) | — | — |
| images.nvim | 0 — ein vermuteter ERR-52-Fund (`extensions`-Liste indexweise gemergt) wurde gebaut, per Repro-Skript gegen echtes Neovim-0.12-Verhalten verifiziert und dann korrekt verworfen: **`vim.tbl_deep_extend` ersetzt nicht-leere Listen bereits komplett, mergt nicht indexweise** — der Fix wäre ein No-Op gewesen. Wichtige Klarstellung für den Rest der Familie (s. Kasten unten) | — | — |
| **insights.nvim** | **`config.setup()` mergte per `tbl_deep_extend("force", defaults, opts)` ohne vorheriges `vim.deepcopy(defaults)`** — nicht angefasste Unterfelder (z. B. `metrics`, wenn nur `symbols` überschrieben wird) blieben dieselbe Tabellen-Referenz wie in `DEFAULTS`; `expand_paths(current)` mutiert genau solche Unterfelder in-place (`cache.dir`, `output_file`, `outdir`) und hätte damit `DEFAULTS` für den Rest der Session und jeden späteren `setup()`-Aufruf verseucht. Aktuell nur durch Zufall maskiert (`expand_path()` ist bei den aktuellen absoluten `stdpath()`-Defaults ein No-Op), aber jeder künftige relative/`~`-Default oder jeder Caller, der in eine von `config.get()` zurückgegebene Tabelle schreibt, hätte geleakt | **ERR-51/53** | [`22e852e`](https://github.com/StefanBartl/insights.nvim/commit/22e852e) |
| **language.nvim** | **`spell/core/actions.lua`s `replace_at()` schrieb eine Ersetzung an eine ungeprüfte Byte-Range** — der Vorschlags-Picker öffnet async, jede Buffer-Änderung in der Zwischenzeit (anderes Fenster, Undo, ein LSP-Fix) lässt `(lnum, col, end_col)` auf inzwischen anderen Text zeigen; `nvim_buf_set_text` überschrieb dann lautlos, was jetzt dort stand, statt des beabsichtigten Worts | **ERR-30** | [`f3ee2d6`](https://github.com/StefanBartl/language.nvim/commit/f3ee2d6) |
| **lib.nvim** | **`fs.collect_recursive` folgte Symlinks in rekursiven Walks** — `walk`/`walk_async` fielen bei fehlendem/`"link"`-`kind_hint` auf `fs_stat` zurück, das Symlinks auflöst statt sie zu erkennen; ein Symlink-Zyklus (`dir/sub/loop -> dir`) rekursiert ohne echte Abbruchbedingung — reproduziert mit echtem Symlink, 192 Einträge vor Windows' Pfadlängen-Limit. **Fleet-weite Wirkung**: filetree.nvims `util/fs.lua`/`refs/scan.lua` delegieren direkt hierher (verifiziert per Grep über alle Repos) | **ERR-34** | [`37b2af8`](https://github.com/StefanBartl/lib.nvim/commit/37b2af8) |
| **lsp.nvim** | **„Organize imports on save" (Java, Astro) lief async in `BufWritePre`** — `vim.lsp.buf.code_action({apply=true})` feuert den Request nur und kehrt sofort zurück, `BufWritePre` (und damit das eigentliche Schreiben) ist längst durch, bevor die Server-Antwort samt Edit ankommt; das Feature organisierte Imports faktisch immer einen Save zu spät, gegen den Buffer-Zustand von *nach* dem Schreiben. TypeScript hatte dafür schon eine synchrone Handumbau-Lösung (`lsp.buf_request_sync`) mit warnendem Docstring — Java/Astro hatten sie nie bekommen | **ERR-30/44** | [`847da5b`](https://github.com/StefanBartl/lsp.nvim/commit/847da5b) |
| **markdown.nvim** | **`rg_files()` kollabierte jeden `rg`-Exitcode >1 (verschwundene Wurzel, Permission Denied, Prozess killed) auf dieselbe leere Liste wie ein echtes „keine Treffer"** — `find_references`/`find_references_async` meldeten im `core.link_delete`-Bestätigungsdialog „0 andere Links zeigen darauf", obwohl die Suche fehlgeschlagen war, nicht ergebnislos — eine Datei konnte so unter noch bestehenden Links weggelöscht werden, die der Scan nie zu sehen bekam | **ERR-11-Familie** (fehlgeschlagen vs. leer kollabiert) | [`ebbdbf4`](https://github.com/StefanBartl/markdown.nvim/commit/ebbdbf4) |
| **mdview.nvim** | **`resync()`s async Callback (`browser.behavior = "reuse"`) griff nach `ws_client.wait_ready` (bis 15s, während ein frisch gebauter Relay-Binary vom Virenscanner geprüft wird) mit `nvim_buf_get_lines` auf einen zwischenzeitlich per `:bwipeout` ungültig gewordenen Buffer zu** — warf „Invalid buffer id" statt den veralteten Push still zu überspringen | **ERR-33** | [`2d9abd6`](https://github.com/StefanBartl/mdview.nvim/commit/2d9abd6) |
| **open.nvim** | **`context.resolve()`s Keyword-Lookup `type(kw)=="function" and kw() or expand_path(tostring(kw))`** — die klassische `and/or`-Falle: liefert die Resolver-Funktion legitim `nil` (z. B. `pwsh_profile`, wenn weder `pwsh` noch `powershell` im PATH steht), fällt der ganze Ausdruck in den `or`-Zweig und `expand_path()`t den **stringifizierten Funktionswert** (`"function: 0x7f..."`) statt des Ergebnisses — `:Open` versuchte danach, einen Fantasie-Pfad zu öffnen | **ERR-60** | [`a51c858`](https://github.com/StefanBartl/open.nvim/commit/a51c858) |
| pdfport.nvim | 0 (durchgängig sauber, wie schon bei SEC-*: `core/dispatcher.lua`/`core/composer.lua` wrappen `callback` konsequent für Cleanup auf jedem Exit-Pfad statt nur dem Erfolgspfad, `config.get()` gibt zwar die lebende Tabelle zurück, aber kein Konsument mutiert sie — nur `pdfport.get_config()` als Public API deep-copy't explizit vorm Herausgeben, Registry-Getter (`all_backends`/`all_producers`) liefern immer frische Arrays, kein `table.sort` mit Ternary-Comparator) | — | — |
| pickers.nvim | 0 — **70 Dateien, zweitgrößtes bisher geprüftes Repo dieser Familie**: Checkliste + gezielte Stichproben (`smart/frecency.lua`s Legacy-Store-Migration verweigert Überschreiben eines nicht-leeren Stores, `config/init.lua`s `M.apply()` validiert jedes Feld einzeln mit Warn-und-Behalten statt Absturz/stillem Datenverlust — das ERR-22-Positivbeispiel, `smart/score.lua`s `table.sort`-Comparator ist explizit if/else, alle drei Engine-`extract/*.lua`-Pfad-Extraktoren (fzf/snacks/telescope) behandeln fehlende Felder explizit statt zu raten), kein file-für-file-Read aller 70 Dateien | — | — |
| recommender.nvim | 0 (durchgängig sauber: `project.lua`s Scan-Generation-Counter für Async-Verzeichnis-Walk/Datei-Reads verhindert exakt die Race, die anderswo in dieser Familie echte Bugs waren; `bindings/usrcmds.lua`/`float/keymaps.lua` validieren Buffer-/Fenster-Handles konsequent neu vorm Zugriff in jedem `vim.schedule`-Callback; `config/init.lua` deep-copy't `DEFAULTS` vorm Mergen statt der insights.nvim-Falle zu wiederholen). Ein bereits im Code selbst per `CDX`-Kommentar markierter toter Zustand (`_pending_insert` in `float/keymaps.lua`) ist ein Cleanup-Hinweis, kein Bug | — | — |
| **replacer.nvim** | **`history.lua`s `M.load()` kollabierte „keine Datei" und „Datei kaputt" auf dieselbe leere Historie** — `M.add()` schreibt immer die GANZE Datei, also hätte der nächste `:Replace`-Apply die kaputte `history.json` durch eine frische Ein-Eintrag-Historie ersetzt, alle vorherigen Suchen unwiederbringlich verloren. Dieselbe Bugklasse wie zuvor bei documentation.nvim, mit derselben Lösung (Backup nach `.corrupt` vorm nächsten Überschreiben). 40 Dateien/8022 LOC insgesamt — `apply.lua`s gechunkte Async-Apply (neuestes Feature), `checkpoint.lua` (bereits SEC-33-gehärtet) und `batch.lua` gezielt mitgeprüft, sonst Checkliste + Stichproben wie bei den anderen Großrepos dieser Familie | **ERR-11-Familie** | [`66f1c88`](https://github.com/StefanBartl/replacer.nvim/commit/66f1c88) |
| **reposcope.nvim** | **`state/favorites_state.lua`s `M.load()` kollabierte „keine Datei" und „Datei kaputt" auf dieselbe leere Liste** — `M.toggle()` schreibt immer die GANZE Datei, also hätte der nächste favorisierte/entfavorisierte Eintrag `favorites.json` durch eine Ein-Eintrag-Liste ersetzt, alle vorher gemerkten Repos unwiederbringlich verloren. Dieselbe Bugklasse zum dritten Mal in dieser Familie (documentation.nvim, replacer.nvim), dieselbe Lösung. **Größtes bisher geprüftes Repo: 106 Dateien/12350 LOC** — Provider-Trio (github/gitlab/codeberg) per Diff auf Drift geprüft: einzige Abweichung (`needs_api` nur bei GitHub) ist laut Commit `ae602e8` eine bewusste, dokumentierte Entscheidung, kein Bug. `state/session_state.lua` hat denselben Kollaps, aber ohne Load-Modify-Save-Zyklus (jedes `:Reposcope session save` überschreibt ohnehin absichtlich) — kein Bug. `state/query_stats.lua` hat exakt dieselbe Struktur wie der gefixte Fund, aber als reine Häufigkeits-Statistik niedrigschwellig genug (vergleichbar mit einem Frecency-Cache), um bewusst ungefixt zu bleiben | **ERR-11-Familie** | [`92345e0`](https://github.com/StefanBartl/reposcope.nvim/commit/92345e0) |
| runtime-analysis.nvim | 0 — **46 Dateien/13683 LOC**. `telemetry/store.lua` und `history.lua` haben dieselbe Load/Save-Kollaps-Struktur wie der reposcope.nvim-Fund, aber beide explizit im Code selbst als bewusst verlusttolerant dokumentiert („a report file is a convenience artifact, not data") — kein Bug, dieselbe Kategorie wie query_stats.lua. Token-basierte Request-Supersession/Cancel-Tracking in `bindings/usrcmds.lua` (1041 Zeilen, `:RA send`/`:RA cancel`) korrekt: unterscheidet sauber zwischen „abgebrochen" und „durch neueren Send überholt". `runner.lua`/`parse.lua` fehlerfrei. Durchgängig außergewöhnlich sorgfältig dokumentierter Code (Autor begründet praktisch jede Design-Entscheidung inline) | — | — |
| **sandbox.nvim** | **`follow_logs()` (docker/nerdctl/podman, `:Sandbox logs -f`) fütterte stdout UND stderr in EINEN geteilten Zeilen-Puffer** — `vim.system` ruft beide Callbacks unabhängig auf, in beliebiger Reihenfolge; eine stdout-Chunk ohne Zeilenumbruch konnte mit einer unabhängig eintreffenden stderr-Chunk zu einer Zeile verschmelzen, die in keinem der beiden echten Streams je existierte (`stdout "foo"` + `stderr "bar\n"` → eine Zeile `"foobar"`). Bug identisch in allen drei Engines (reine Kopien voneinander). **Größtes bisher geprüftes Repo: 233 Dateien/11773 LOC** — Docker/nerdctl/podman-Adapter-Trio (perfekt gespiegelt, keine Drift) und Provider-übergreifende Struktur per Diff-Stichproben geprüft statt Volllesung | **ERR-30-Familie** (unabhängiger Zustand vermischt) | [`73515a8`](https://github.com/StefanBartl/sandbox.nvim/commit/73515a8) |

**Wichtige Klarstellung zu ERR-52 (aus dem images.nvim-Durchgang):**
`vim.tbl_deep_extend` selbst ersetzt eine nicht-leere Listen-Tabelle beim
Merge bereits vollständig, statt sie indexweise zu vermischen (verifiziert
gegen echtes Neovim-0.12-Verhalten, `shared.lua`s `can_merge()` liefert für
nicht-leere Listen `false`). Das im Regeltext beschriebene Risiko trifft also
**nur auf eigene, handgeschriebene Merge-Funktionen** zu (wie gopath.nvims
`deep_merge_into`, der reale Fund dieser Sitzung) — ein Repo, das schlicht
`vim.tbl_deep_extend("force", defaults, opts)` direkt aufruft, hat dieses
Problem nicht. Spart Zeit im Rest der Familie: bei reinem
`vim.tbl_deep_extend`-Gebrauch muss ERR-52 nicht mehr geprüft werden, nur bei
custom Merge-Code.

**Fleet-Muster, das sich über 3 Agent-Runden bestätigt:** die häufigste
ERR-*-Bugklasse in diesem Fleet ist nicht ERR-60 (Lua-Ternary-Falle, nur 2
echte Treffer insgesamt), sondern die **ERR-10/11/51/53-Familie** — ein
Zustand (Config-Default, Cache, Sidecar-Datei) wird per Referenz statt Kopie
geteilt oder „fehlt"/„kaputt" nicht unterschieden, und ein *späterer*, davon
unabhängiger Codepfad mutiert oder überschreibt ihn. 8 von 10 bisherigen
Funden dieser Sitzung gehören in diese Familie (buffer-ctx.nvim/ERR-60 und
fileops.nvim/ERR-60 sind die einzigen zwei „klassischen" Lua-Footgun-Funde).

### Nebenbefund, nicht gefixt

`casedesk.nvim/lua/casedesk/migrate.lua:124` hat dasselbe
`meta.read(...) or {}`-Muster wie der gefixte `meta.patch()`-Bug, aber mit
anderer Absicht: `migrate.run()` soll beim Verschieben eines Falls ohnehin
immer ein vollständiges, korrigiertes Sidecar schreiben (Kommentar: „Existing
sidecar fields always win over a fresh guess"), ein kaputtes JSON ist hier
also eher der Fall, den die Migration reparieren soll, nicht einer, den sie
verweigern sollte. Nicht angefasst, um keine Design-Entscheidung über die
Migrations-Semantik nebenbei zu treffen — bei Bedarf gesondert bewerten.

`github_stats.nvim` (Agent-Runde 1) hat drei weitere Punkte nur dokumentiert,
nicht gefixt:

- Die Katalog-Belege-Referenz `api.lua:143-229` für ERR-42 ist veraltet —
  der Code dort ist inzwischen `fetch_all_metrics` (als „kein
  In-Repo-Caller" markiert, also toter Code) plus reine Pagination. Das
  echte, aktuelle ERR-42-Beispiel ist `fetcher.lua`s `fetch_all`/`fetch_repo`.
  Für den nächsten Katalog-Durchlauf vorgemerkt.
- `fetcher.lua`s `load_last_fetch()` kollabiert „nie gefetcht" und
  „`last_fetch.json` korrupt" beide auf `nil` → wird als „nie gefetcht"
  behandelt → Fetch läuft an. Absichtlich nicht gefixt: das ist im Sinne von
  ERR-21 eher korrektes Fail-Open-Verhalten (lieber fetchen als wegen einer
  kaputten Sidecar-Datei blockieren), es fehlt nur die einmalige Warnung —
  geringer Nutzen für das Risiko einer Änderung an einer selten getroffenen
  Kante.
- `storage.read_metric_history` verwirft jede einzelne `.json`-Datei, die
  nicht parst, lautlos. Nicht gefixt: alle drei Aufrufer in `analytics.lua`
  behandeln einen zweiten Rückgabewert (err) als fatal — ein naiver Fix hätte
  das aktuelle Fail-Open-Verhalten (partielle Historie trotz einer kaputten
  Datei) in Fail-Closed verkehrt (komplette Historie verworfen wegen einer
  Datei). Bräuchte eine koordinierte Vertragsänderung über mehrere
  Aufrufer hinweg — außerhalb des Umfangs eines Ein-Zeiler-Fixes.

`lib.nvim` (Agent-Runde 3) hat einen latenten, nicht gefixten Punkt
dokumentiert: `lib.lua.config.deep_merge` teilt Tabellen-Referenzen für jeden
vom Override nicht berührten Unterbaum mit `base` (dokumentiertes
Verhalten, kein Bug per Vertrag — nur die Eingaben bleiben unangetastet,
nicht das Ergebnis). Ein Konsument (spotlight.nvim, `normalize_palette`/
`normalize_cursor_patterns`) schreibt danach in einen unberührten Unterbaum
zurück, was — nur wenn der ganze `palette`/`cursor`-Zweig in `opts` fehlt —
in die echte `DEFAULTS`-Tabelle zurückschreibt. Kein demonstrierbarer Bug
heute (der zurückgeschriebene Wert ist inhaltsgleich mit dem, was schon da
stand), daher nicht gefixt — ein echter Fix würde jeden unberührten Blattwert
immer tief kopieren, eine größere, im Docstring bewusst vermiedene Änderung
mit Auswirkung auf cascade.nvim, spotlight.nvim, filetree.nvim, mdview.nvim.

### Noch offen (2/32 Repos ungelesen für ERR-*)

sessions.nvim, spotlight.nvim.

(Agent-Runde 4 — markdown.nvim, mdview.nvim, open.nvim — ist zurück und
oben eingetragen: 3/3 mit echtem Fund. pdfport.nvim direkt gelesen: 0 Funde.)

Die beiden fleet-weiten Mechanik-Checks oben (and/or-Ternary-Falle,
read-or-stub-vor-write) müssen für diese Repos **nicht wiederholt** werden —
die liefen bereits über alle 32 Repos (die and/or-Falle sogar zweimal, mit
der erweiterten Regex). Was noch fehlt, ist das kontextabhängige Lesen der
übrigen ERR-Regeln (`ERR-01`…`ERR-07`,
`ERR-10/20-22/30-34/40-44/50-53/61/63-67`).

---

## ⬜ Noch nicht begonnen

| Familie | Regeln | Worum es geht (Kurzfassung) |
|---|---|---|
| `PRIN-*` | 37 | Grundprinzipien (Modularität, API-Design, Namenskonventionen, Dokumentationspflichten auf Prinzip-Ebene) |
| `UI-*` | 34 | UI-Konventionen (Float-Größen, Highlight-Gruppen, Statuszeilen-Verhalten, Tastenkonflikte) |
| `LUA-*` | 45 | Allgemeine Lua/Neovim-Idiome jenseits von Deprecations |
| `PERF-*` | 57 | Performance-Patterns (Hotpath-Vermeidung von `pcall`, Debouncing, `vim.wait`-Nutzung, Caching) — größte Familie |

(`ERR-*` läuft bereits — siehe oben, 🔶 in Arbeit.)

**Vorschlag für die Reihenfolge, wenn's weitergeht:** `ERR-*` zu Ende bringen
→ `UI-*` (34, mittelgroß) → `PRIN-*` (37) → `LUA-*` (45) → `PERF-*` (57,
größte und wahrscheinlich aufwendigste, da sie am meisten Kontext pro Fund
braucht). Keine Autoren-Vorgabe, nur eine Einschätzung nach Größe.

---

## Methodik-Hinweise für den nächsten Durchlauf

- **Mechanisch prüfbare Regeln** (feste API-Namen, Deprecations, Pattern-Matches
  wie `DEP-*`) lassen sich per Grep über alle 32 Repos auf einmal scannen,
  bevor überhaupt ein Repo einzeln angefasst wird — spart Zeit gegenüber
  „ein Agent/eine Session pro Repo gegen den vollen Katalog".
- **Kontextabhängige Regeln** (wie die meisten `SEC-*`, `ERR-*`, `PRIN-*`)
  brauchen echtes Lesen des Quelltexts, keine Abkürzung.
- **Immer gegen den aktuellen Quelltext verifizieren, nicht gegen einen alten
  Belege-Snapshot** — mehrere SEC-Funde waren nur noch teilweise oder gar
  nicht mehr aktuell (z. B. `cmdlog.nvim`s SEC-11/12/13, längst durch
  `redact_patterns` geschlossen).
- **1 Agent/Repo pro Durchgang, nicht mehrere parallel** — mehrere
  gleichzeitige Agenten kosten zu viele Token und sind zwischendurch nicht
  von Hand nachhaltbar (siehe `feedback_agent_limits_and_language`-Notiz in
  Claudes Memory). Bei rein mechanischen Scans (Grep) ist gar kein Agent
  nötig.
- **Regel-Zählung immer nachprüfen**, bevor eine Familie als „klein" gilt —
  der Katalog mischt Tabellen- und Aufzählungsformat (siehe oben).

---

