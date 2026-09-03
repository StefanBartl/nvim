# CLI-Tool-Deps: Analyse & Konzept

> Analyse der drei Roadmap-Punkte unter `lib.nvim / deps installer`.
> Quelltext-Stand geprüft am 2026-09-03 gegen `E:\repos\lib.nvim` und alle
> `E:\repos\*.nvim`.
>
> **Erledigt am 2026-09-03.** Alle vier Bausteine aus Abschnitt 3 sind
> gebaut, getestet (`LIB_TESTS_OK`), dokumentiert und über neun Repos
> committet und gepusht — siehe Abschnitt 7. Zwei der offenen Punkte haben
> sich beim Bauen aufgelöst:
>
> - **B3s technisches Fragezeichen** — `spec.find` findet die Config ohne
>   Sonderfall, unter dem Namen `nvim`. Kein Code-Eingriff nötig.
> - **B2s Architekturfrage** (generalisieren vs. duplizieren) — keine von
>   beiden: der Merge erzeugt genau die Datenform, die `view.show` schon
>   nimmt, also wird der bestehende Renderer samt `i`/`I`-Keymaps und
>   Live-Streaming unverändert wiederverwendet.
>
> Dazugekommen ist `require_tool.lines()`: die interessantesten
> Fehlermomente melden gar nicht, sondern reichen ihren Fehler nach oben
> durch (Callback, `result.errors`) — dort wäre eine Notification eine
> Doppelmeldung.

---

## 0. Die kurze Antwort vorweg

**Das gewünschte System existiert bereits** — als `lib.nvim.deps`, nicht als
eigenes Plugin. Es deckt Deklaration, Erkennung, `:checkhealth`,
Erst-Start-Popup, Package-Manager-Erkennung, Kommando-Komposition und den
bestätigten Install-Handoff ab. Zehn Plugins sind vollständig daran
angeschlossen.

Ein „eigenes Plugin neu schreiben" wäre daher **keine Weiterentwicklung,
sondern ein Rückschritt** — es würde ein ausgereiftes, getestetes Modul durch
eine zweite, jüngere Implementierung ersetzen.

Die echten Lücken liegen woanders, und sie sind kleiner und konkreter als die
Roadmap-Punkte vermuten lassen. Sie stehen in Abschnitt 3.

---

## 1. Ist-Zustand: was `lib.nvim.deps` bereits kann

Quelle: `E:\repos\lib.nvim\lua\lib\nvim\deps\` (9 Module + README).

| Baustein | Leistet |
|---|---|
| `deps.spec` | Parst `docs/install.json` bzw. `docs/INSTALL.md`; findet den Spec **jedes** Plugins — über `runtimepath` *und* lazy.nvims Registry |
| `deps.detect` | „Ist das Tool da?" — inkl. `bin_alternatives` (`gs` / `gswin64c`) |
| `deps.health` | `:checkhealth`-Zeilen; `report_for("plugin")` = Einzeiler im Plugin-Health |
| `deps.pm` | 9 Package-Manager, OS-Präferenzordnung, WSL-Sonderfall, `sudo`-Prefix |
| `deps.install` | Reiner Plan (`present`/`missing`/`installable`/`unsupported`) + bestätigter Handoff |
| `deps.view` | Popup-Report mit `i` (einzeln), `I` (alles), Inline-Install mit Live-Ausgabe |
| `deps.first_run` | Popup **einmal jemals**, persistiert; `vim.g`-Opt-outs |

**Verdrahtung ist vollständig, nicht halb:** Alle 10 Plugins mit Spec rufen
*sowohl* `show_once()` in `setup()` *als auch* `report_for()` in ihrer
`health.lua` auf — `filetree`, `gopath`, `images`, `insights`, `language`,
`mdview`, `pdfport`, `pickers`, `replacer`, `runtime-analysis`.

Bemerkenswerte Details, die schon durchdacht sind:

- **Nichts installiert ohne Rückfrage.** Bei Managern mit Root-Bedarf wird an
  ein echtes Terminal übergeben, Kommando *getippt, nicht abgeschickt* — damit
  ein `sudo`-Prompt an einer Stelle landet, an der er beantwortet werden kann.
- **Kein `-y` / `--noconfirm`.** Die Rückfrage des Package-Managers bleibt.
- **`why` ist Pflichtfeld** und wird validiert — ein Tool ohne Begründung
  fällt beim Parsen durch.

---

## 2. Bewertung der drei Roadmap-Punkte

### Punkt 1 — „eigenes Plugin mit lazy installer neu schreiben"

**Nicht neu bauen.** Der Wunsch dahinter — *„bei der Plugin-Installation
werden gleich die CLI-Tools mitbehandelt"* — ist zu ~80 % erfüllt. Was von der
Formulierung tatsächlich noch offen ist, sind zwei Timing-/Übersichtsfragen:

**a) Das Erst-Start-Popup kommt bei lazy-geladenen Plugins zu spät.**
`show_once()` hängt an `setup()` des Plugins. Bei `lazy = true` läuft `setup()`
erst, wenn das Plugin zum ersten Mal *getriggert* wird — das kann Wochen nach
der Installation sein. `lib.nvim`s eigenes README nennt die Messgröße aus
diesem Setup: **120 Plugins konfiguriert, 44 beim Start geladen, 76 ausstehend.**
Für die Mehrzahl der Plugins ist „bei der ersten Initialisierung" also nicht
„kurz nach der Installation".

**b) Es gibt keine aggregierte Sicht.**
`:Lib deps show` ohne Argument nennt heute nur *Namen* von Plugins mit Spec —
nicht, **was insgesamt fehlt**. Genau das wäre aber die Ansicht für „ich habe
die Config gerade auf einer neuen Maschine ausgerollt": eine Liste, ein
Kommando, fertig.

### Punkt 2 — „tesseract gehört installiert, Notiz in nvim install doc"

**Plugin-seitig erledigt, und zwar gründlich.** `images.nvim/docs/install.json`
deklariert tesseract mit `why`, neun `pkg`-Einträgen und dem Hinweis auf den
UB-Mannheim-Installer. `images.nvim/lua/images/ocr.lua` sucht sogar zusätzlich
in den Standard-Installationspfaden unter Windows — weil dieser Installer
„Add to PATH" nicht setzt und „installiert" und „erreichbar" dort regelmäßig
auseinanderfallen.

**Was fehlt, ist die Config-Ebene:**

1. **Die nvim-Config hat überhaupt keine Installations-Doku.** Kein
   `README.md`, kein `docs/installation.md`. Es gibt also keinen Ort, an dem
   die Notiz stehen *könnte*.
2. **Die Config ist selbst Tool-Konsument, steht aber außerhalb des Systems.**
   `lua/bindings/usrcmds/case/ocr.lua` (casedesk, `:Case ocr`) benutzt
   tesseract. Die Config hat keinen eigenen Spec und taucht in `:Lib deps show`
   nicht auf. Ihre Fehlermeldung ist immerhin die beste im ganzen Bestand:
   `"tesseract not found — see :checkhealth images"` — sie verweist auf das
   Health eines *fremden* Plugins, weil sie kein eigenes hat.

### Punkt 3 — „Wie wird dem User angezeigt, wenn ein Tool fehlt?"

**Das ist der eigentlich interessante Befund.** Es gibt drei Kanäle —
`:checkhealth`, Erst-Start-Popup, `:Lib deps show` — und **alle drei sind
vorausschauend**. Sie beantworten „was könnte ich brauchen?".

Der Moment, in dem es den User tatsächlich trifft, ist ein anderer: **ein
Befehl schlägt fehl.** Und genau diesen Moment bedient das deps-System nicht.
Was dort heute passiert, ist von Plugin zu Plugin verschieden:

| Plugin | Meldung bei fehlendem Tool | Spec? |
|---|---|---|
| `casedesk` (Config) | `tesseract not found — see :checkhealth images` | nein |
| `diff.nvim` | `curl executable not found on PATH` | nein |
| `language.nvim` | `curl not found` | **ja** |

Die dritte Zeile ist die aufschlussreiche: `language.nvim` *hat* einen Spec mit
einem `why` und neun `pkg`-Einträgen für curl — und sagt im Fehlerfall
trotzdem nur „curl not found". Das gesamte Wissen liegt bereit und wird genau
dann nicht benutzt, wenn es gebraucht wird.

**Zusätzlich: 11 Plugins prüfen Executables zur Laufzeit, ohne einen Spec zu
haben** — `debugging`, `diff`, `documentation`, `emojis`, `fileops`, `hover`,
`lsp`, `markdown`, `open`, `reposcope`, `sandbox`.

Das heißt aber *nicht*, dass alle 11 einen Spec brauchen. Triage:

| Kategorie | Tools | Spec sinnvoll? |
|---|---|---|
| **Echte optionale Tools** | `curl` (diff), `rg` (markdown, lsp), `lua-language-server` (documentation), `pdftoppm` + `soffice` (hover), `wslview` (open) | **ja** |
| OS-inhärent / Plattformwahl | `git`, `pwsh`/`powershell`, `explorer.exe`, `wsl` | nein — nicht „installierbar" im gemeinten Sinn |
| Mason-Territorium | `jdtls`, `omnisharp`, `dart`, `flutter`, `kotlin-language-server`, `sourcekit-lsp`, `eslint_d`, `prettier`, `mvn`, `dotnet`, `java` (lsp.nvim) | nein — Mason ist dafür zuständig, doppelte Zuständigkeit wäre schlimmer als keine |

Realistisch sind es also **fünf Plugins**, nicht elf.

---

## 3. Konzept

Vier Bausteine, nach Nutzen pro Aufwand sortiert. Jeder ist einzeln
lieferbar; keiner setzt einen anderen voraus.

### B1 — `deps.require_tool()`: der Fehlermoment (höchster Nutzen)

Ein Aufruf, der im Moment des Scheiterns das nutzt, was der Spec ohnehin schon
weiß.

```lua
-- statt: notify.error("curl not found")
local ok = require("lib.nvim.deps").require_tool("language.nvim", "curl")
if not ok then return end
```

Erzeugt bei fehlendem Tool eine Meldung, die den `why`-Text aus dem Spec
enthält, den passenden Install-Befehl für *diesen* Host nennt (über
`deps.pm`, das existiert) und einen direkten Weg zum bestätigten Install
anbietet — statt einer Sackgasse.

Wichtig für die Umsetzung:

- **Rein additiv.** Kein bestehender Aufrufer muss geändert werden; die
  Umstellung geht Plugin für Plugin.
- **Nicht schwatzhaft.** Pro Session und Tool höchstens einmal, sonst wird
  eine Schleife über 200 Dateien zur Notification-Lawine.
- **Kein Spec vorhanden → normale Fehlermeldung.** Der Aufruf muss auch dann
  funktionieren, wenn das Plugin (noch) nichts deklariert.
- **Fällt in `deps` und nirgendwo sonst hin.** Es ist dieselbe Frage wie
  `detect` sie stellt, nur zu einem anderen Zeitpunkt.

*Aufwand: klein.* Alle Zutaten (`spec`, `detect`, `pm`, `install`) existieren.

### B2 — Aggregierte Übersicht: `:Lib deps status`

Was `:Lib deps show <plugin>` für ein Plugin tut, für **alle** auf einmal:

```
lib.nvim deps — 10 Plugins mit Spec, 3 Tools fehlen

  tesseract   images.nvim              OCR (:Image ocr, :Case ocr)
  chafa       images.nvim              Inline-Bilder ohne Kitty-Protokoll
  soffice     hover.nvim               Office-Dokumente im Hover

  I  alles Fehlende installieren    i  Tool unter dem Cursor
```

Deckt den Roadmap-Wunsch „bei der Initialisierung gleich die CLI-Tools
mitbehandeln" für den Fall ab, der wirklich wehtut: **neue Maschine, Config
frisch ausgerollt.** Ein Kommando statt zehn `:Lib deps show`-Aufrufen.

Löst außerdem das Lazy-Timing-Problem aus Punkt 1a *ohne* an lazy.nvim-Interna
zu hängen: `spec.find` liest lazys Registry bereits und findet damit auch die
76 noch nicht geladenen Plugins.

Ein Tool, das mehrere Plugins wollen (`curl`: diff + language), gehört
zusammengefasst und mit beiden Herkünften gezeigt — sonst steht dieselbe Zeile
doppelt da.

*Aufwand: klein bis mittel.* `view.render` und `install.plan` liefern die
Bausteine; neu ist im Wesentlichen das Zusammenführen über Plugins hinweg.

### B3 — Die Config als eigener deps-Konsument

Die nvim-Config bekommt, was jedes Plugin schon hat:

1. **`docs/install.json` in der Config** mit den Tools, die die Config selbst
   benutzt — allen voran tesseract für `:Case ocr`. Das System kann fremde
   Specs bereits über `runtimepath` finden, die Config *ist* auf
   `runtimepath` — es sollte also ohne Änderung an `spec.find` gehen.
2. **`docs/installation.md` in der Config anlegen.** Der Ort, den Punkt 2
   verlangt und den es noch nicht gibt: was außerhalb von Neovim installiert
   sein muss, damit diese Config vollständig funktioniert — mit dem Verweis
   auf `:Lib deps status` als lebende, immer aktuelle Fassung.

Damit erledigt sich Punkt 2 vollständig, und die Krücke „see `:checkhealth
images`" in `case/ocr.lua` kann durch `require_tool` aus B1 ersetzt werden.

*Aufwand: klein.* Überwiegend Schreibarbeit, kaum Code.

### B4 — Specs für die fünf echten Kandidaten nachziehen

`diff.nvim` (curl), `markdown.nvim` (rg), `documentation.nvim`
(lua-language-server), `hover.nvim` (pdftoppm, soffice), `open.nvim` (wslview).
Je Plugin: `docs/install.json`, `report_for()` im Health, `show_once()` im
Setup — das eingespielte Dreier-Muster, dem schon 10 Plugins folgen. Ab B1
zusätzlich `require_tool` an der Stelle, wo heute die nackte Fehlermeldung
steht.

**`lsp.nvim` bleibt bewusst außen vor.** Seine Executable-Prüfungen sind
LSP-Server, für die Mason zuständig ist. Zwei Systeme, die dasselbe Tool
installieren wollen, sind schlimmer als eines, das es nicht tut.

*Aufwand: pro Plugin klein, in Summe mittel.* Gut häppchenweise machbar.

---

## 4. Aufwand je Baustein

**Einheit:** „Sitzung" = eine zusammenhängende Arbeitseinheit mit mir, inkl.
Tests und Doku. Keine Personenstunden — die Zahl sagt, wie oft du dich
hinsetzen musst, nicht wie lange du tippst.

**Kalibrierung** (gemessen, nicht geschätzt): Das gesamte `deps`-System sind
**1813 LOC Modulcode + 1004 LOC Tests**. Verhältnis Test:Code ≈ 0,55:1 — das
ist der Maßstab, an dem die Positionen unten hängen. Referenz-Einzelmodule:
`health` 122, `first_run` 160, `install` 187, `pm` 206, `spec` 373, `view` 384.

| Baustein | Neuer Code | Tests | Sitzungen | Risiko |
|---|---|---|---|---|
| **B1** `require_tool` | ~120–160 | ~80–120 | **1** | gering |
| **B2** `:Lib deps status` | ~230–330 | ~150 | **2–3** | mittel |
| **B3** Config-Spec + Doku | ~80 JSON + ~150 MD | — | **1–2** | eine offene Frage |
| **B4** fünf Specs | ~25 JSON je Plugin | — | **0,5–1 je Plugin** | gering |

### B1 — die klarste Position

Alle Zutaten existieren (`spec`, `detect`, `pm`, `install`); neu ist nur das
Zusammenführen plus Meldungsformat und Session-Dedup. Vergleichsgröße ist
`health.lua` mit 122 LOC.

**Der Kern ist ohne eine einzige geänderte Call-Site fertig und nutzbar.**
Die Umstellung der Aufrufer ist danach 1–3 Zeilen pro Stelle und beliebig
verteilbar — quer über alle Plugins sind es realistisch **~15–20 echte
Fehlermoment-Stellen**, nicht die 65 Executable-Prüfungen, die eine naive
Zählung liefert (siehe unten).

Offen sind zwei *Design*-Entscheidungen, keine technischen Hürden: wie fein
dedupliziert wird (pro Tool? pro Plugin+Tool? pro Session?) und was passiert,
wenn das Plugin gar keinen Spec hat.

### B2 — die größte Position

Der Grund liegt in `view.lua`: es ist plugin-zentriert gebaut
(`render(plugin_name, result, opts, ui)`) und lässt sich für eine
Multi-Plugin-Ansicht nicht direkt wiederverwenden. Daraus folgt die
Hauptfrage, und sie ist eine Architektur-, keine Fleißfrage:

- **generalisieren** — sauberer, berührt aber 384 LOC getesteten Code
- **daneben bauen** — risikoärmer, erzeugt aber Duplikation bei Keymaps und
  Inline-Install

Hinzu kommt Zusammenführungslogik, die es bisher nirgends gibt: ein Tool, das
mehrere Plugins wollen (`curl`: diff + language), darf nicht doppelt
erscheinen, muss aber beide Herkünfte zeigen.

### B3 — überwiegend Schreibarbeit, mit einer offenen Frage

Die Config benutzt mehr CLI-Tools als der Roadmap-Punkt vermuten lässt.
Gemessen: **pandoc, bat, win32yank, wl-copy / wl-paste, nvr, zsh** — plus
tesseract, das nur deshalb nicht in dieser Liste auftaucht, weil casedesk es
über `images.nvim` aufruft. Realistisch 5–8 Spec-Einträge.

Die eigentliche Arbeit ist nicht das Tippen, sondern pro Tool ein ehrliches
`why` und eine **`pkg`-Map über neun Package-Manager** zu verifizieren.

**Offene technische Frage — vor dem Start zu klären:** ob `spec.find` die
Config überhaupt findet und unter welchem Namen sie dann in `:Lib deps show`
auftaucht. Die Config liegt auf `runtimepath`, ist aber kein Plugin mit
Repo-Namen. Falls das nicht aufgeht, braucht `spec.find` einen Sonderfall —
dann verschiebt sich B3 von „Schreibarbeit" zu „Schreibarbeit plus kleiner
Code-Eingriff".

### B4 — beliebig stückelbar

Pro Plugin: `docs/install.json` (Referenzgrößen im Bestand: 20 Zeilen bei
`language`/`mdview`/`replacer`, 33 bei `filetree`), eine Zeile `show_once`,
eine Zeile `report_for`, ein README-Absatz. Das Muster liegt zehnmal vor.
Auch hier dominiert die `pkg`-Map-Recherche den Aufwand, nicht der Code.

**Zwei Nachträge nebenbei entdeckt** (Vergleich „gemeldet" gegen
„deklariert"): `insights.nvim` meldet fehlendes `fd`, hat es aber nicht im
Spec; `language.nvim` dasselbe mit `node`. Zwei Kleinstergänzungen, je ein
Eintrag.

*(`fzf-lua` taucht in mehreren dieser Meldungen ebenfalls auf, gehört aber
**nicht** in einen Spec — es ist ein Neovim-Plugin, kein CLI-Tool. Das CLI
`fzf` ist bei `pickers.nvim` korrekt deklariert.)*

### Warum die naive Zählung dreimal zu hoch liegt

Die zehn Spec-Plugins enthalten **65 Executable-Prüfungen** außerhalb ihrer
`health.lua`. Das ist *nicht* der B1-Umfang, denn die große Mehrheit sind
**Fallback-Auswahlen**, keine Fehlermomente — `filetree.nvim` fragt
nacheinander `trash` / `gio` / `trash-put`, um zu entscheiden *welches* Tool
es benutzt; `mdview.nvim` prüft `curl`, um zwischen zwei Wegen zu wählen. Dort
fehlt nichts, dort wird gewählt, und `require_tool` hat da nichts zu suchen.

Nur wo tatsächlich abgebrochen und gemeldet wird, ist B1 die Antwort.

---

## 5. Reihenfolge

1. **B1** (`require_tool`) — größter Nutzen, kleinster Eingriff, macht jeden
   späteren Spec sofort wertvoller.
2. **B3** (Config-Spec + Installations-Doku) — schließt Punkt 2 ab.
3. **B2** (`:Lib deps status`) — schließt den brauchbaren Teil von Punkt 1 ab.
4. **B4** (fünf Specs) — laufende Kleinarbeit, jederzeit einschiebbar.

---

## 6. Was bewusst nicht gemacht wird

- **Kein neues Plugin.** `lib.nvim.deps` ist der richtige Ort: es ist die
  Ebene, auf der alle Plugins ohnehin schon aufsetzen. Ein separates Plugin
  bräuchte eine eigene Installation, um Installationen zu verwalten.
- **Kein `build`-Hook in den lazy-Specs.** Ein `build`-Kommando läuft ohne
  Rückfrage bei jedem Update — das bricht die Regel, an der das ganze
  bestehende Design hängt („nichts installiert, ohne vorher zu fragen"). B2
  erreicht dasselbe Ziel, ohne diese Regel aufzugeben.
- **Keine automatische Installation.** Auch nicht optional-abschaltbar. Der
  bestehende Weg (zeigen → fragen → Terminal) ist die richtige Antwort auf
  Package-Manager, die Root brauchen und interaktiv nachfragen.
- **Kein Spec für `git`, `pwsh`, `wsl`.** Wer diese nicht hat, hat kein
  fehlendes optionales Tool, sondern ein anderes Betriebssystem.
- **Keine Mason-Konkurrenz.** Siehe B4.

---

## 7. Auslieferung (2026-09-03)

Neun Repos, je ein Commit, alle auf `main` gepusht.

| Repo | Commit | Baustein |
|---|---|---|
| `lib.nvim` | `b8c75ea` | **B1 + B2** — `deps.require_tool`, `deps.status`, `:Lib deps status`, `:Lib deps install` ohne Argument |
| `nvim` (Config) | siehe unten | **B3** — `docs/install.json`, `docs/installation.md`, `require_tool` in casedesk |
| `diff.nvim` | `5111a9d` | **B4** — curl, inkl. `require_tool.lines` im URL-Fetcher |
| `markdown.nvim` | `b5561c9` | **B4** — rg |
| `documentation.nvim` | `289802e` | **B4** — lua-language-server |
| `hover.nvim` | `0e63b0d` | **B4** — soffice, pdftoppm |
| `open.nvim` | `d992f91` | **B4** — wslview |
| `language.nvim` | `2552468` | Nachtrag — node, `require_tool` im Thesaurus, README-Korrektur |
| `insights.nvim` | `8fd7e14` | Nachtrag — siehe „fd" unten |

### Verifiziert, nicht behauptet

- `nvim --headless -u NONE -l TESTS/run.lua` in `lib.nvim` → `LIB_TESTS_OK`,
  inklusive der neuen Abschnitte für `status` und `require_tool`.
- `spec.find("nvim")` findet `C:\Users\bartl\AppData\Local\nvim\docs\install.json`
  — **B3s offene technische Frage ist damit beantwortet**, ohne Sonderfall.
- `status.collect()` über alle Repos: **16 Plugins mit Spec, 27 verschiedene
  Tools, 0 Lesefehler.** Der Merge über mehrere Deklaranten stimmt
  (`curl` → 5 Plugins, `rg` → 6, `tesseract` → images + pdfport + Config).

### Drei Abweichungen von der Planung

**1. `fd` bei `insights.nvim` bekommt *keinen* Spec-Eintrag.**
Abschnitt 4 hatte „eine Kleinstergänzung, ein Eintrag" angenommen. Der
Quelltext sagt etwas anderes: `fd` wird nirgends aufgerufen, und der
Health-Check gab das selbst zu („optional; not used currently"). Ein
Spec-Eintrag bräuchte ein `why` — es gibt keins, das wahr wäre. Also die
tote Prüfung entfernt statt eine tote Deklaration angelegt.

**2. `language.nvim`: die README behauptete mehr, als der Spec hält.**
Sie nannte `trans` und die Spell-/Grammar-CLIs als „deklariert" — deklariert
sind aber nur `curl` und (neu) `node`. Korrigiert. `trans`, `cspell`,
`codespell`, `typos` bleiben bewusst außen vor: zwei davon leben in npm bzw.
cargo, und der Spec spricht nur die neun OS-Package-Manager. **Offener
Punkt**, kein erledigter.

**3. Die Tool-Tabelle in `docs/installation.md` war unvollständig.**
Gegen die echten `status.collect()`-Daten korrigiert und um den Hinweis
ergänzt, dass `:Lib deps status` die maßgebliche, lebende Fassung ist.

### Was offen bleibt

- **Die vier Provider-CLIs von `language.nvim`** (siehe Abweichung 2). Die
  Frage dahinter ist größer als ein Spec-Eintrag: soll `deps.pm` npm / pip /
  cargo lernen? Solange nicht, ist „nicht deklariert" die ehrlichere Antwort
  als eine `pkg`-Map mit zwei Einträgen.
- **`docs/installation.md` hat keinen eingehenden Link.** Die Config hat
  keine `README.md` und keinen Doku-Index — der konventionelle Pfad ist die
  einzige Fundstelle. Genau der Befundtyp „verwaistes Dokument" aus dem
  `LAST_CDX_TASKS`-Handover (Ü3); dort gehört er auch hin, nicht hierher.
- **Die Umstellung weiterer Call-Sites auf `require_tool`** ist bewusst
  nicht flächendeckend gemacht. Umgestellt sind die vier echten
  Fehlermomente (`diff` URL-Fetch, `language` Thesaurus, casedesk `export`
  und `ocr`). Der Rest der 65 Executable-Prüfungen sind Fallback-Auswahlen,
  wo nichts fehlt, sondern gewählt wird — siehe Abschnitt 4, letzter Absatz.
