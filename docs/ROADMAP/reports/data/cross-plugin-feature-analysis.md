# Cross-Plugin-Feature-Analyse: `data.nvim` ↔ Ökosystem (2026-09-15)

> **Zweck:** Analyse in beide Richtungen — (A) welche Features aus anderen
> `StefanBartl/*.nvim`-Plugins sinnvoll in `data.nvim` einfließen könnten, und
> (B) welche Fähigkeiten von `data.nvim` (bzw. seiner `lib.nvim`-Basis) für
> andere Plugins nützlich wären. Reine Analyse, keine Code-Änderung — alle
> Aussagen sind gegen den tatsächlichen Code geprüft (Datei:Zeile, nicht nur
> READMEs), Stand `data.nvim@d0c6fa8`. Geprüft wurden alle 33 vom Auftrag
> genannten Plugins unter `E:\repos`, plus `casedesk.nvim` (von `data.nvim`
> selbst referenziert).

---

## Table of Content

- [0. Methodik](#0-methodik)
- [1. Ausgangslage: was `data.nvim` heute ist](#1-ausgangslage-was-datanvim-heute-ist)
- [2. Bereits dokumentierte Cross-Links (Kontext, nichts Neues)](#2-bereits-dokumentierte-cross-links-kontext-nichts-neues)
- [3. Richtung A — Features anderer Plugins → `data.nvim`](#3-richtung-a--features-anderer-plugins--datanvim)
  - [A1. Fence-Format autodetektieren statt erraten](#a1-fence-format-autodetektieren-statt-erraten)
  - [A2. `:JSON filter` ist buchstäblich zusammensteckbar](#a2-json-filter-ist-buchstäblich-zusammensteckbar)
  - [A3. Deterministisches JSON-Encoding existiert schon — nur nicht hier](#a3-deterministisches-json-encoding-existiert-schon--nur-nicht-hier)
  - [A4. Register-Scope-Vorbild aus `diff.nvim`](#a4-register-scope-vorbild-aus-diffnvim)
- [4. Richtung B — `data.nvim`/`lib.nvim` → andere Plugins](#4-richtung-b--datanvimlibnvim--andere-plugins)
  - [B1. `sandbox.nvim`: Compose-Datei wird nie geparst](#b1-sandboxnvim-compose-datei-wird-nie-geparst)
  - [B2. Doppelt gebautes „Projekt-JSON-Config mit Allowlist“-Muster](#b2-doppelt-gebautes-projekt-json-config-mit-allowlist-muster)
  - [B3. JSON-Logdateien, die niemand von Hand lesbar macht](#b3-json-logdateien-die-niemand-von-hand-lesbar-macht)
  - [B4. `runtime-analysis.nvim`: REST-Antworten ohne Pretty-Print](#b4-runtime-analysisnvim-rest-antworten-ohne-pretty-print)
- [5. Geprüft, aber kein Fund](#5-geprüft-aber-kein-fund)
- [6. Priorisierte Empfehlung](#6-priorisierte-empfehlung)
- [7. Was hier bewusst nicht gemacht wurde](#7-was-hier-bewusst-nicht-gemacht-wurde)

---

## 0. Methodik

1. `docs/scope.md`, `docs/architecture.md`, `docs/integrations.md` und der
   Quellcode von `data.nvim` gelesen, um den tatsächlichen Ist-Stand zu
   verstehen (nicht nur das README).
2. README.md **aller** 33 genannten Plugins gelesen — jedes hat einen
   „Around it“-Abschnitt, der die meiste Cross-Plugin-Verdrahtung bereits
   selbst dokumentiert. Das ist die Baseline; hier geht es um das, was
   **darüber hinaus** auffällt.
3. Gezielt per `grep` nach `json.decode`/`json.encode`/`yaml` über den
   gesamten `E:\repos`-Baum gesucht (144 bzw. 59 Treffer), um zu sehen, wo
   strukturierte Daten tatsächlich verarbeitet werden — nicht nur, wo es
   plausibel wäre.
4. Die auffälligsten Treffer einzeln gelesen und gegen `data.nvim`s
   Fähigkeiten gespiegelt.

Kein Agent-Rollout nötig — 33 READMEs plus ~10 gezielte Dateien waren mit
direkten Read/Grep-Aufrufen schneller und günstiger als mehrere sequentielle
Subagent-Runden.

---

## 1. Ausgangslage: was `data.nvim` heute ist

`data.nvim` ist bewusst dünn: `pretty`/`compact`/`lines`/`keys`/`sort` für
JSON, YAML, XML im Puffer oder in einer Selektion, plus `:JSON ndjson` und
`:JSON to yaml`/`:YAML to json`. Die eigentliche Decode/Encode-Logik liegt in
`lib.nvim` (`lib.lua.json`, `lib.lua.yaml`, `lib.lua.xml`,
`lib.lua.tables.path_flatten`) — `data.nvim` selbst ist nur Command/Scope/UI
darüber ([architecture.md](E:\repos\data.nvim\docs\architecture.md)).

Zwei Dinge sind in `data.nvim`s eigener `docs/scope.md` bereits als "Does not
(yet)" vermerkt:

1. **Register-Scope** (`--reg=`, Ausgabe in Scratch-Split statt Puffer) —
   designed, nicht gebaut.
2. **Filter-UI** (`:JSON filter`, auf `pickers.refine` aufbauend) — designed,
   nicht gebaut; ein `diff.nvim`-Preview hängt explizit davon ab.

Das ist wichtiger Kontext: die Autorin/der Autor hat die Zielrichtung schon
skizziert. Der Mehrwert dieser Analyse liegt darin, zu zeigen, **wie konkret
buildbar** diese beiden Punkte bereits sind (Abschnitt A2), und zwei weitere
Punkte zu ergänzen, die in der bisherigen Doku noch nicht vorkommen (A1, A3).

---

## 2. Bereits dokumentierte Cross-Links (Kontext, nichts Neues)

Diese stehen schon in `data.nvim`s `docs/scope.md`, hier nur zur
Vollständigkeit aufgeführt, damit klar ist, was **nicht** neu in diesem
Report ist:

| Plugin | Beziehung laut `data.nvim`-Doku |
| --- | --- |
| `casedesk.nvim` | Support-Case-Scaffolding, hat kein eigenes Formatting-Kommando; könnte künftig `data.nvim` aufrufen (nie umgekehrt). |
| `pickers.nvim` | `refine`-Modul ist der geplante Baustein für `:JSON filter`. |
| `color_my_ascii.nvim` | Fenced-Block-Scope, bereits implementiert und funktionsfähig. |

---

## 3. Richtung A — Features anderer Plugins → `data.nvim`

### A1. Fence-Format autodetektieren statt erraten

**Fund:** [`color_my_ascii.nvim/docs/api.md`](E:\repos\color_my_ascii.nvim\docs\api.md)
zeigt, dass `fences.block_at(bufnr, row, opts)` das erkannte `lang` des
Blocks zurückgibt — auch **ohne** `lang`-Filter. `data.nvim`s
[`lua/data/scope/resolve.lua:35-58`](E:\repos\data.nvim\lua\data\scope\resolve.lua)
ruft `block_at` aber immer schon **mit** einem festen `fmt`-Filter auf
(`json`/`yaml`/`xml` je nachdem, welches Kommando gerade läuft) — d.h. der
Nutzer muss vorher wissen, ob der Block unter dem Cursor JSON, YAML oder XML
ist, und das passende `:JSON`/`:YAML`/`:XML` selbst wählen.

**Idee:** Ein optionaler vierter Einstieg (`:Data pretty`/`:Data lines` o.ä.,
oder ein `auto`-Flag auf den bestehenden Kommandos), der `block_at` **ohne**
`lang`-Filter aufruft, das erkannte `lang` auf einen der drei Formatter
mapped und dorthin dispatcht. Kostet keine neue Fence-Erkennung — die liefert
`color_my_ascii` schon.

**Aufwand:** klein. Betrifft nur `scope/resolve.lua` (neue Funktion neben
`fenced_block_scope`) plus eine neue Route in `bindings/usrcmds.lua`.

### A2. `:JSON filter` ist buchstäblich zusammensteckbar

**Fund:** [`pickers.nvim/docs/FEATURES/REFINE.md`](E:\repos\pickers.nvim\docs\FEATURES\REFINE.md)
beschreibt `pickers.refine` als reines Model+UI-Modul **ohne** Picker-Kopplung:
Es nimmt eine flache Item-Liste mit benannten String-Feldern
(`fields = { path = fn, content = fn }`), lässt den Nutzer eine Filter-Stack
aus `path`/`content`-Klauseln bauen, und gibt `h:apply(items)` als gefilterte
Kopie zurück. Es ist bereits Engine-agnostisch genutzt (`replacer.nvim` bindet
es ohne Picker-Engine ein).

`data.nvim` hat mit `lib.lua.tables.path_flatten`
([architecture.md:18-27](E:\repos\data.nvim\docs\architecture.md)) exakt den
Baustein, der eine dekodierte JSON/YAML-Struktur in genau die Form bringt,
die `refine` erwartet: eine Liste von `{path, value}`-Paaren (dieselbe
Funktion, die heute schon `:JSON lines`/`:JSON keys` speist).

**Der Plan aus `scope.md` ist also keine Vision, sondern eine
Drei-Zeilen-Verdrahtung:**

```
decode(text) → path_flatten → { {path=..., value=...}, ... }
             → pickers.refine.new({fields={path=.., value=..}})
             → h:apply(items) → als "lines" rendern
```

`pickers.nvim` müsste dafür nicht mal eine harte Abhängigkeit werden — der
gleiche `pcall`-Soft-Integration-Stil, den `data.nvim` schon für
`color_my_ascii` nutzt, passt hier direkt.

**Aufwand:** mittel. Neue Datei `lua/data/filter/init.lua`, ein `refine`-Call
via `pcall(require, "pickers.refine")`, eine neue `filter`-Subcommand-Route.
Das ist der Baustein, von dem `docs/scope.md` sagt, dass ein
`diff.nvim`-Vorher/Nachher-Preview davon abhängt — mit A2 gebaut, wird A4
relevant.

### A3. Deterministisches JSON-Encoding existiert schon — nur nicht hier

**Fund:** [`documentation.nvim/lua/documentation/core/json.lua`](E:\repos\documentation.nvim\lua\documentation\core\json.lua)
ist ein kompletter, eigenständiger JSON-Encoder mit genau einem Zweck: Keys
werden sortiert und Zahlen plattformunabhängig normalisiert (LuaJIT schreibt
`100`, PUC-Lua 5.3+ schreibt `100.0` — das machte `module_map.json` und
`sarif.lua`-Output nicht reproduzierbar zwischen `nvim --headless` und dem
Standalone-Binary). Der Kommentar dort ist explizit: *"vim.json.encode gives
no ordering guarantee for object keys [...] two runs over an unchanged tree
produced byte-different files"*.

Das ist **exakt** die Lücke, die `data.nvim`s eigene
[`docs/architecture.md:42-56`](E:\repos\data.nvim\docs\architecture.md)
beschreibt: *"Why `sort` isn't actually different from `pretty` yet"* —
weder `lib.lua.json.encode` noch der Decoder erhalten Key-Reihenfolge,
weshalb `:JSON sort` heute ein reiner Alias für `:JSON pretty` ist. Der Text
sagt selbst: *"kept as an explicit, self-documenting route [...] in case an
order-preserving encoder is ever worth adding for its own sake"*.

`documentation.nvim` hat diesen Encoder bereits gebaut — zweimal genutzt
intern (`module_map.json`, SARIF-Output) — aber nur lokal, nicht über
`lib.nvim` geteilt.

**Idee (kein direkter data.nvim-Task, sondern ein `lib.nvim`-Kandidat):**
Diese deterministische Encode-Strategie als `lib.lua.json.encode`-Option
(z.B. `{ deterministic = true }`) upstreamen. Nutzen für `data.nvim`: `:JSON
sort` würde ein echtes, reproduzierbares Sortier-Encoding, keine
Kosmetik-Attrappe mehr. Nutzen für `documentation.nvim`: einen selbst
gepflegten Encoder weniger. Das ist eine Empfehlung **für `lib.nvim`**, aber
mit `data.nvim` als direktem Nutznießer — deshalb hier aufgeführt statt in
Abschnitt B.

**Aufwand:** mittel, liegt aber überwiegend außerhalb von `data.nvim`
(in `lib.nvim`); der `data.nvim`-seitige Teil ist trivial (eine Flag
durchreichen).

### A4. Register-Scope-Vorbild aus `diff.nvim`

**Fund:** `diff.nvim` liest bereits heterogene Quellen (Puffer, Datei, Git-Revision,
URL) und liefert das Ergebnis wahlweise in Split, Datei, Clipboard oder als
Prompt — genau die Zielrichtung von `data.nvim`s eigenem offenen Punkt
"Register scope [...] read from a register, write to a scratch split instead
of the buffer" (`docs/scope.md`, Punkt 1). Kein Code wurde hier 1:1
übernehmbar gefunden (die Quellen-Abstraktion von `diff.nvim` ist auf
Vergleich zweier Seiten zugeschnitten, `data.nvim` braucht nur eine
Quelle/Senke), aber das Ausgabe-Ziel-Muster (`ui.nvim`-Scratch-Split,
Clipboard, Datei) ist im Ökosystem bereits etabliert und ließe sich für
`--reg=` 1:1 wiederverwenden statt neu zu entwerfen.

**Aufwand:** eher „schau dir `diff.nvim`s Output-Sink-Modul an, bevor du
`--reg=` neu entwirfst“ als ein eigenständiger Task.

---

## 4. Richtung B — `data.nvim`/`lib.nvim` → andere Plugins

### B1. `sandbox.nvim`: Compose-Datei wird nie geparst

**Fund:** [`sandbox.nvim/lua/sandbox/util/compose_file.lua`](E:\repos\sandbox.nvim\lua\sandbox\util\compose_file.lua)
findet nur den *Pfad* zu `docker-compose.yml`/`compose.yaml`/etc. — der
Inhalt wird nirgends in `sandbox.nvim` dekodiert (per `grep` über den
gesamten Baum geprüft: kein `yaml.decode`-Aufruf existiert dort). Jede
Service-/Volume-/Network-Liste, die `sandbox.nvim` anzeigen will, muss dafür
`docker compose config --services` o.ä. shellen.

**Idee:** `sandbox.nvim` könnte `lib.lua.yaml.decode` (dieselbe Bibliothek,
auf der `data.nvim`s `:YAML`-Familie steht) direkt auf die gefundene
Compose-Datei anwenden, um z.B. eine Service-Liste für einen Picker zu
gewinnen, **ohne** den Compose-Client aufzurufen (nützlich, wenn nur Podman
ohne `podman-compose` installiert ist, oder für ein schnelles "peek" vor dem
eigentlichen `up`). Kein neuer Dependency — `lib.nvim` ist ohnehin die
gemeinsame Basis beider Plugins.

**Einschränkung:** `lib.lua.yaml` ist laut `data.nvim/docs/scope.md`
bewusst minimal (keine Anchors, kein Flow-Style, keine Block-Scalars) — reale
Compose-Dateien nutzen gelegentlich YAML-Anchors (`&defaults`/`<<: *defaults`)
für wiederverwendete Service-Konfiguration. Das müsste vor einer Umsetzung an
echten Compose-Dateien geprüft werden; für eine reine Service-Namen-Liste
(oberste Ebene der `services:`-Map) dürfte es in den meisten Fällen reichen.

**Aufwand:** klein für eine erste Version (Top-Level-Keys unter `services:`),
mittel falls Anchor-Unterstützung in `lib.lua.yaml` nötig würde.

### B2. Doppelt gebautes „Projekt-JSON-Config mit Allowlist“-Muster

**Fund:** Zwei Plugins reimplementieren unabhängig voneinander dasselbe
Muster — repository-lokale JSON-Config-Datei einlesen, gegen eine Allowlist
filtern, Warnungen für unbekannte bzw. "gehört nicht hierher"-Keys ausgeben:

- [`documentation.nvim/lua/documentation/config/file.lua`](E:\repos\documentation.nvim\lua\documentation\config\file.lua)
  (`.docmap.json`, `REPO_KEYS`-Allowlist, zwei getrennte Warnlisten für
  `host_only` vs. `unknown`)
- [`lsp.nvim/lua/lsp/config/project.lua`](E:\repos\lsp.nvim\lua\lsp\config\project.lua)
  (`.nvim-lsp.json`, `ALLOWED`-Allowlist, dieselbe Grundidee)

Beide begründen JSON explizit gleich ("kein Code-Execution-Risiko wie bei
Lua-Configs"), beide lesen mit `pcall(vim.json.decode, ...)`, beide trennen
zwischen "das ist eine gültige Option, aber deine, nicht die des Repos" und
"das ist gar keine Option".

**Idee:** Kein `data.nvim`-Task, aber ein klarer `lib.nvim`-Kandidat: ein
generisches `lib.nvim.config.repo_file` (Name, Pfad-Auflösung ab Projekt-Root,
Allowlist, zweigeteilte Warnung) würde beiden Konsumenten Code sparen und
jedem künftigen Plugin mit demselben Bedürfnis (auch `data.nvim` selbst,
falls es einmal projekt-lokale Defaults bekommen sollte, z.B. eine
`.data.json` für bevorzugte `sort`-Reihenfolge pro Repo) eine fertige Lösung
geben statt einer dritten Kopie.

**Aufwand:** mittel, in `lib.nvim` (Extraktion aus zwei bestehenden,
funktionierenden Implementierungen — geringes Risiko, da das Verhalten schon
zweimal produktiv verifiziert ist).

### B3. JSON-Logdateien, die niemand von Hand lesbar macht

**Fund:** [`reposcope.nvim/lua/reposcope/utils/metrics.lua:98-150`](E:\repos\reposcope.nvim\lua\reposcope\utils\metrics.lua)
schreibt `request_log.json` als kompaktes JSON-Objekt (`fs_json.write`, ohne
Pretty-Print). `github_stats.nvim` hat ein vergleichbares
Storage-Format (siehe eigene `docs/architecture.md`). Beide sind reine
Maschinen-Artefakte — aber genau die Art Datei, die man beim Debuggen einmal
von Hand aufmacht.

**Idee:** Kein Code-Fund, sondern ein **Doku-Hinweis**: Beide Plugins könnten
in ihrer Troubleshooting-Doku `:JSON pretty` (mit fenced-block- oder
Datei-Scope, siehe A4) als Weg erwähnen, die eigene Logdatei lesbar zu
machen, statt sie extern zu öffnen. Kein Code nötig, nur eine
Doku-Querverweis-Zeile — daher hier nicht umgesetzt (siehe Abschnitt 7), aber
notiert.

### B4. `runtime-analysis.nvim`: REST-Antworten ohne Pretty-Print

**Fund:** [`runtime-analysis.nvim/lua/runtime-analysis/graphql.lua`](E:\repos\runtime-analysis.nvim\lua\runtime-analysis\graphql.lua)
und `runner.lua` bilden einen waschechten HTTP/GraphQL-Request-Runner
(VS-Code-REST-Client-kompatibel) direkt in Neovim. Antworten landen
vermutlich roh im Puffer. Sobald eine Antwort dort sichtbar ist, ist es
exakt der Use-Case, für den `data.nvim` gebaut wurde (`:JSON pretty` auf die
Antwort anwenden). Auch hier: kein Integrationscode nötig, nur ein
Workflow-Hinweis in `runtime-analysis.nvim`s `docs/WORKFLOW.md`, dass eine
Response-Ansicht sich mit `data.nvim` kombinieren lässt, falls installiert.

---

## 5. Geprüft, aber kein Fund

Damit klar ist, was aktiv ausgeschlossen wurde statt übersehen:

- **XML** taucht außerhalb von `data.nvim`/`lib.nvim` in keinem der 33
  Plugins als geparstes Format auf (nur in einer archivierten,
  nicht-relevanten `lua-language-server`-Kopie unter
  `Kurse/FrontendMasters/...`). Keine Cross-Integration in dieser Richtung
  möglich.
- **`dap.nvim`** hat kein VS-Code-`launch.json`-kompatibles Config-Lesen
  (per `grep` bestätigt: kein Treffer für `launch.json`) — kein
  YAML/JSON-Berührungspunkt mit `data.nvim`.
- **`mdview.nvim`** nutzt `json`/`yaml`-Treffer nur in Test-Dateinamen und
  WS-Protokoll-Handling (Selection-Sync-Payloads), nicht als
  Nutzer-sichtbares Datenformat — kein sinnvoller Berührungspunkt.
- **`insights.nvim`**, **`recommender.nvim`**, **`markdown.nvim`**,
  **`cascade.nvim`**, **`emojis.nvim`**, **`hover.nvim`**, **`gopath.nvim`**,
  **`open.nvim`**, **`filetree.nvim`**, **`pdfport.nvim`**, **`images.nvim`**,
  **`media.nvim`**, **`language.nvim`**, **`ui.nvim`**, **`spotlight.nvim`**,
  **`sessions.nvim`**, **`cmdlog.nvim`**, **`buffer-ctx.nvim`** — README plus
  gezielte Grep-Treffer geprüft; keiner hat einen strukturierten
  JSON/YAML/XML-Formatierungs-Bedarf, der über gelegentliches internes
  `vim.json.decode`/`encode` (Config, Cache, IPC) hinausgeht. Das ist der
  erwartete Befund: die meisten dieser Plugins sind UI-/Editor-Feature-Tools,
  keine Daten-Tools.

---

## 6. Priorisierte Empfehlung

| # | Was | Wo | Aufwand | Nutzen |
| --- | --- | --- | --- | --- |
| A2 | `:JSON filter` via `path_flatten` + `pickers.refine` | `data.nvim` | mittel | schließt den größten offenen Punkt aus `docs/scope.md`, schaltet A4 frei |
| A1 | Fence-Format-Autodetect | `data.nvim` | klein | kleiner Komfortgewinn, fast geschenkt |
| B2 | Gemeinsames „Repo-JSON-Config + Allowlist“-Modul | `lib.nvim` | mittel | entfernt echte Code-Duplikation (2 Plugins heute, potenziell mehr künftig) |
| A3 | Deterministisches JSON-Encoding upstreamen | `lib.nvim` (Nutzen für `data.nvim`) | mittel | macht `:JSON sort` zu echtem Feature statt Alias |
| B1 | Compose-YAML-Peek in `sandbox.nvim` | `sandbox.nvim` | klein–mittel | UX-Gewinn dort, kein Risiko für `data.nvim` |
| B3/B4 | Doku-Querverweise auf `:JSON pretty` | `reposcope.nvim`, `github_stats.nvim`, `runtime-analysis.nvim` | trivial | Auffindbarkeit, kein Code |
| A4 | Register-Scope-Sink nach `diff.nvim`-Vorbild | `data.nvim` | mittel, aber später | vervollständigt den zweiten offenen `scope.md`-Punkt |

Empfohlene Reihenfolge, falls umgesetzt werden soll: **A1 → A2 → A4**, da A2
den größten dokumentierten Fehlbetrag schließt und A4 direkt davon abhängt.
B1–B4 sind unabhängig und können parallel oder von anderer Seite (z.B. in
einer eigenen `sandbox.nvim`-Session) angegangen werden.

---

## 7. Was hier bewusst nicht gemacht wurde

- **Kein Code geändert.** Der Auftrag war Analyse; alle oben genannten Punkte
  sind Empfehlungen, keine durchgeführten Refactorings. Vor einer Umsetzung
  von A2/A3/B2 sollte jeweils kurz mit dir abgestimmt werden, ob der
  Zielort (`data.nvim` vs. `lib.nvim`) und der Umfang stimmen.
- **Keine README/Docs-Änderung an den 34 geprüften Plugins.** "Docs
  aktualisieren, wenn es Sinn macht" bezieht sich hier auf begleitende
  Doku zu einer Code-Änderung — da keine gemacht wurde, gäbe es nichts
  akkurat zu dokumentieren; ein spekulativer Doku-Eintrag zu einem noch
  nicht gebauten Feature wäre irreführend.
- **`rules.nvim`, `my.nvim`, `ai.nvim`** wurden zwar im Repo-Verzeichnis
  gefunden (u.a. mit eigener JSON-Reporting-Logik in `rules.nvim`), standen
  aber nicht auf der genannten Plugin-Liste und wurden daher nur am Rand
  (Grep-Treffer) berücksichtigt, nicht vertieft.
