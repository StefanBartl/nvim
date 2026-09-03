# CLI-Tool-Deps: Analyse & Konzept

> Analyse der drei Roadmap-Punkte unter `lib.nvim / deps installer`.
> Quelltext-Stand geprüft am 2026-09-03 gegen `E:\repos\lib.nvim` und alle
> `E:\repos\*.nvim`.

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

## 4. Reihenfolge

1. **B1** (`require_tool`) — größter Nutzen, kleinster Eingriff, macht jeden
   späteren Spec sofort wertvoller.
2. **B3** (Config-Spec + Installations-Doku) — schließt Punkt 2 ab.
3. **B2** (`:Lib deps status`) — schließt den brauchbaren Teil von Punkt 1 ab.
4. **B4** (fünf Specs) — laufende Kleinarbeit, jederzeit einschiebbar.

---

## 5. Was bewusst nicht gemacht wird

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
