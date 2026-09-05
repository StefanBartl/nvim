# RULES — Stand der Checklists-Anwendung (WKDBooks/Checklists/regeln)

## Table of content

  - [Intro](#intro)
  - [Überblick: 9 Regel-Familien](#berblick-9-regel-familien)
  - [✅ LLS-* (34 Regeln) — fertig](#lls-34-regeln-fertig)
  - [✅ SEC-* (23 Regeln, `SEC-01`…`SEC-45`) — fertig](#sec-23-regeln-sec-01sec-45-fertig)
  - [🟨 DEP-* (7 Regeln) — läuft](#dep-7-regeln-luft)
    - [Ergebnis je Repo](#ergebnis-je-repo)
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
| `DEP-*` | 7 | `LUA_NVIM.md` | 🟨 **läuft** — 4/8 betroffene Repos gefixt |
| `TS-*` | 5 | `LUA_NVIM.md` | ⬜ nicht begonnen |
| `PRIN-*` | 37 | `PRINCIPLES.md` | ⬜ nicht begonnen |
| `ERR-*` | 34 | `LUA_NVIM.md` | ⬜ nicht begonnen |
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

## 🟨 DEP-* (7 Regeln) — läuft

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
| github_stats.nvim | DEP-01 (`config/init.lua`, `storage.lua`) | ⬜ offen | — |
| debugging.nvim | DEP-02 (`tools/proc_trace.lua:135`) | ⬜ offen | — |
| filetree.nvim | DEP-02 (`features/system/shell_run/init.lua:76`) | ⬜ offen | — |
| sandbox.nvim | DEP-02 (5 Stellen: docker/nerdctl/podman `exec_in_container.lua`, `wsl/exec_in_distro.lua`, `bindings/usrcmds/container_commands_buffer.lua`) | ⬜ offen | — |

**Fix-Muster:** `vim.loop` → `vim.uv or vim.loop`, passend zur bereits im
jeweiligen Repo etablierten Konvention (nicht bloßes `vim.uv`, auch wenn der
Floor 0.10+ ist — Konsistenz mit dem Rest der Datei/des Repos hat Vorrang).
`mdview.nvim` hat sogar einen echten 0.9+-Floor, dort ist der Fallback nicht
nur Konvention, sondern zwingend.

**4 von 8 betroffenen Repos durch.**

---

## ⬜ Noch nicht begonnen

| Familie | Regeln | Worum es geht (Kurzfassung) |
|---|---|---|
| `TS-*` | 5 | Treesitter-Query-Konventionen (Directives vs. Predicates, `#match?` vs. `#any-match?`, `;; extends`, Main-Thread-Pflicht, keine vordefinierten Captures) — vermutlich bei den meisten der 32 Repos gar nicht anwendbar (nur Repos mit eigenen Query-Dateien) |
| `PRIN-*` | 37 | Grundprinzipien (Modularität, API-Design, Namenskonventionen, Dokumentationspflichten auf Prinzip-Ebene) |
| `ERR-*` | 34 | Fehlerbehandlung: `pcall`-Pflicht an Systemgrenzen, Type Guards, explizite Rückgaben, kein `notify()` in Low-Level-Code, strukturierte Fehlertypen, Rückgabewert-Präzision (`nil` vs. `false` vs. strukturiertes Fehlerobjekt), Fail-Open vs. Fail-Closed |
| `UI-*` | 34 | UI-Konventionen (Float-Größen, Highlight-Gruppen, Statuszeilen-Verhalten, Tastenkonflikte) |
| `LUA-*` | 45 | Allgemeine Lua/Neovim-Idiome jenseits von Deprecations |
| `PERF-*` | 57 | Performance-Patterns (Hotpath-Vermeidung von `pcall`, Debouncing, `vim.wait`-Nutzung, Caching) — größte Familie |

**Vorschlag für die Reihenfolge, wenn's weitergeht:** `TS-*` (5, wahrscheinlich
meist N/A, schnell durch) → `ERR-*`/`UI-*` (je 34, mittelgroß) → `PRIN-*` (37)
→ `LUA-*` (45) → `PERF-*` (57, größte und wahrscheinlich aufwendigste, da sie
am meisten Kontext pro Fund braucht). Keine Autoren-Vorgabe, nur eine
Einschätzung nach Größe.

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

