# hover.nvim — Extraktion aus lib.nvim

## Table of content

  - [Intro](#intro)
  - [Kurzfassung: wo wir stehen](#kurzfassung-wo-wir-stehen)
  - [Was wir getan haben, und warum](#was-wir-getan-haben-und-warum)
    - [Die Ausgangsfrage](#die-ausgangsfrage)
    - [Der Befund zum Rauschen](#der-befund-zum-rauschen)
    - [Die Repo-Frage](#die-repo-frage)
  - [Der Namensentscheid, und was daran offen bleibt](#der-namensentscheid-und-was-daran-offen-bleibt)
  - [Was im Plugin neu ist (nicht nur umgezogen)](#was-im-plugin-neu-ist-nicht-nur-umgezogen)
    - [1. Das Opt-in-Modell](#1-das-opt-in-modell)
    - [2. `mode`: auto | manual | off](#2-mode-auto-manual-off)
    - [3. Schalter aus **einer** Tabelle](#3-schalter-aus-einer-tabelle)
    - [4. Die verschärfte Bare-Path-Regel](#4-die-verschrfte-bare-path-regel)
    - [5. Kleineres](#5-kleineres)
  - [Was wo geändert wurde](#was-wo-gendert-wurde)
    - [markdown.nvim](#markdownnvim)
    - [nvim-config](#nvim-config)
  - [Verifikation (alles tatsächlich gelaufen)](#verifikation-alles-tatschlich-gelaufen)
  - [Was seit der Extraktion passiert ist](#was-seit-der-extraktion-passiert-ist)
    - [Gebaut](#gebaut)
    - [Drei Messungen, die alle der Intuition widersprachen](#drei-messungen-die-alle-der-intuition-widersprachen)
    - [Dieselbe Bug-Klasse dreimal](#dieselbe-bug-klasse-dreimal)
    - [Und eine vierte Klasse: eine Funktion, zwei Fragen](#und-eine-vierte-klasse-eine-funktion-zwei-fragen)
  - [Offene Punkte](#offene-punkte)
    - [1. Demo-GIF — **braucht dich**](#1-demo-gif-braucht-dich)
    - [2. Fünf Aufträge liegen in fremden Repos](#2-fnf-auftrge-liegen-in-fremden-repos)
    - [3. Beobachten, ob `manual` der bessere Default ist](#3-beobachten-ob-manual-der-bessere-default-ist)
    - [4. Was keine CI prüft](#4-was-keine-ci-prft)
  - [Aufträge aus der Sitzung vom 2026-09-02](#auftrge-aus-der-sitzung-vom-2026-09-02)
    - [A. Die BINDINGS-Notes für hover.nvim nachziehen — **erledigt 2026-09-02**](#a-die-bindings-notes-fr-hovernvim-nachziehen-erledigt-2026-09-02)
    - [B. Die Docs der eingebundenen Plugins durchgehen — **erledigt 2026-09-02**](#b-die-docs-der-eingebundenen-plugins-durchgehen-erledigt-2026-09-02)
    - [C. Die README von hover.nvim — **erledigt 2026-09-02** (`a57d390`)](#c-die-readme-von-hovernvim-erledigt-2026-09-02-a57d390)
    - [D. Eine Beitrags-API für Nutzer — **erledigt 2026-09-02** (`c374d5e`)](#d-eine-beitrags-api-fr-nutzer-erledigt-2026-09-02-c374d5e)
    - [E. Eine Roadmap-Datei unter `docs/ROADMAP/personal/` — **erledigt 2026-09-02**](#e-eine-roadmap-datei-unter-docsroadmappersonal-erledigt-2026-09-02)
    - [F. Zoom im Float — **eingegrenzt 2026-09-02, Tasten gebaut (`204d083`)**](#f-zoom-im-float-eingegrenzt-2026-09-02-tasten-gebaut-204d083)
    - [G. Ein Spec, das die Doku gegen die Quelle prüft — **erledigt 2026-09-02** (`4e1760f`)](#g-ein-spec-das-die-doku-gegen-die-quelle-prft-erledigt-2026-09-02-4e1760f)
    - [H. Eine `:checkhealth`-Zeile für `contribute` — **erledigt 2026-09-02** (`aca73fa`)](#h-eine-checkhealth-zeile-fr-contribute-erledigt-2026-09-02-aca73fa)
    - [I. Die Messung für 2.5 — gelaufen, und die Antwort ist **nein**](#i-die-messung-fr-25-gelaufen-und-die-antwort-ist-nein)
      - [Was die Struktur schon sagt, ohne Messung](#was-die-struktur-schon-sagt-ohne-messung)
      - [Messung 1 — wie oft wiederholt sich der Schlüssel?](#messung-1-wie-oft-wiederholt-sich-der-schlssel)
      - [Messung 2 — was kostet ein Ask? Und damit war die Häufigkeit egal](#messung-2-was-kostet-ein-ask-und-damit-war-die-hufigkeit-egal)
      - [Was dabei herausfiel: ein Auftrag für documentation.nvim](#was-dabei-herausfiel-ein-auftrag-fr-documentationnvim)
      - [Wo die Messwerkzeuge liegen](#wo-die-messwerkzeuge-liegen)
    - [J. Die `on_request`-Messung — gelaufen, und sie hat drei Dinge gefunden (`b7c4c45`, `e62f5e9`)](#j-die-on_request-messung-gelaufen-und-sie-hat-drei-dinge-gefunden-b7c4c45-e62f5e9)
      - [Fund 1: die Engine-Erkennung wählt hier `podman`, und der antwortet nicht](#fund-1-die-engine-erkennung-whlt-hier-podman-und-der-antwortet-nicht)
      - [Fund 2: `MANUAL-EVIDENCE.md` hatte vier Zeilen und sagte dreimal „drei"](#fund-2-manual-evidencemd-hatte-vier-zeilen-und-sagte-dreimal-drei)
      - [Fund 3: die LuaLS-Messung flackert](#fund-3-die-luals-messung-flackert)
  - [Was beim Weiterarbeiten zu wissen ist](#was-beim-weiterarbeiten-zu-wissen-ist)

---

## Intro

Handover-Dokument. Stand: **2026-09-02**. Angelegt in der Session
„lib.nvim hover analysis"; seither fortgeschrieben.

Die Extraktion, die diesem Dokument den Titel gibt, ist abgeschlossen. Was
seither dazugekommen ist, steht unter
[Was seit der Extraktion passiert ist](#was-seit-der-extraktion-passiert-ist).

Repo: <https://github.com/StefanBartl/hover.nvim> · lokal `E:/repos/hover.nvim`
Branch: **`main`** — kein Feature-Branch, alles ist gepusht.

---

## Kurzfassung: wo wir stehen

**Die Extraktion ist abgeschlossen und aufgeräumt.** Das Plugin ist
öffentlich, in der Config, CI grün auf Ubuntu *und* Windows.
`lua/lib/nvim/hover/` ist aus lib.nvim gelöscht (`5450dd4`), samt Specs,
Routen, Options-Feld und Doku — und damit auch das NUL-Byte in
`preview/media.lua`.

**Beide Gates sind durch.** `RELEASE.md`: 29 von 32 erfüllt, drei begründete
Ausnahmen, ein offener 🟢-Punkt (Demo-GIF — braucht dich, ich kann nicht
aufnehmen). `REVIEW.md`: grün, ein behobener Befund (`LUA-61/62`).

**Das Plugin kann heute deutlich mehr als nach der Extraktion.** Position-
Previews, `:Hover why`, `:Hover pin`, Zeilen und Ranges (`init.lua:42`,
`file.lua:10-20`), Git-Objekte, `gf` zum Öffnen, ein Schalter-Chooser über
lib.nvims UI-Kit. Und **fünf** Nachbarplugins steuern jetzt etwas bei.

**Der letzte Framework-Mangel ist weg.** Ein Beitrag kann seit `731bbe2`
sagen, dass seine eigene Antwort teuer ist (`on_request`), und wird dann nur
auf ausdrückliche Nachfrage gefragt. Das war der Blocker für sandbox.nvim,
das jetzt verdrahtet ist — und beim echten Verdrahten fiel auf, dass das
Feature selbst nie erreichbar war (`836a15a`, siehe unten).

**Offen ist wenig, und das Meiste davon bewusst.** Details unter
[Offene Punkte](#offene-punkte).

**Was als Nächstes ansteht**, steht unter [Aufträge aus der Sitzung vom
2026-09-02](#aufträge-aus-der-sitzung-vom-2026-09-02) — inzwischen **A bis J,
alle abgeschlossen**. Die sechs der Ursprungssitzung: A, B, C, D und E gebaut
bzw. geschrieben, F entschieden statt gebaut — **Zoom nur für Bilder**,
PDF-Seiten optional, Text gar nicht. In den Folgesitzungen dazu: **G** (das
Spec, das die Doku gegen die Quelle prüft), **H** (`:checkhealth` sagt, wer
registriert hat), **I** (2.5 gemessen und abgelehnt) und **J** (der
`on_request`-Pfad gegen eine echte Engine, mit drei Funden).

**Die Doku hat jetzt denselben Mechanismus wie der Code.** Seit `4e1760f`
prüft `TESTS/docs_spec.lua` die Listen der Dokumente gegen die Quelle, die
sie beschreiben — die Klasse, die an einem Tag viermal die Doku und dreimal
den Code getroffen hat, fällt ab jetzt beim Testlauf auf. Drei Funde beim
Einbau, alle behoben; inzwischen **dreizehn** Prüfungen — `204d083` brachte
zwei Tastentabellen dazu, `b7c4c45` zwei weitere für
`docs/MANUAL-EVIDENCE.md`, das als einziges Dokument außerhalb der Reichweite
lag und prompt gedriftet war.

**Zoom für Bilder ist gebaut** (`204d083`): `+` und `-`, geliehen nur, solange
ein Hover mit Bild offen ist. Offen bleiben Mausrad und scharfer PDF-Zoom,
beide in `docs/ROADMAP.md`. Siehe [F](#f-zoom-im-float--eingegrenzt-2026-09-02-tasten-gebaut-204d083).

**Ein eigener Hover braucht seit `c374d5e` kein Plugin mehr.** `setup` nimmt
ein Feld `contribute`, und zwar genau die Tabelle, die `register` nimmt — die
Einstiegshürde ist damit eine Funktion statt eines Repos.

---

## Was wir getan haben, und warum

---

### Die Ausgangsfrage

Zwei Todo-Punkte: „Mittlerweile poppt oft ein Hover auf → checken, was opt-in
sein sollte" und „Zahlt sich ein eigenes Repo mittlerweile aus?"

---

### Der Befund zum Rauschen

Drei getrennte Ursachen, nicht eine:

1. **Der Auslöser feuert öfter als „Cursor bewegt".** `updatetime = 200` +
   `delay_ms = 250` = ~450 ms nach jeder Pause, und `CursorHold` feuert nach
   *jedem* Tastendruck gefolgt von Ruhe, Cursorbewegung oder nicht.
2. **Die Opt-in-Grenze lag am falschen Ort.** Das Argument „documentation is
   made of links" war nur auf `http(s)` angewandt. Gemessen in lib.nvims
   `docs/modules.md`: **104 Links, davon 2 http.** Der Schalter schwieg 2, die
   anderen 102 waren das Volumen.
3. **Die 3-Segment-Regel für Bare Paths produzierte rote ✗ auf Prosa.**
   Verifiziert durch Nachbau der Heuristik: `2026/09/01`, `github.com/user/repo`,
   `./components/Button` (jeder erweiterungslose JS-Import), `TODO/FIXME/DONE`,
   `read/write/execute`, `key/value/pair`, `a/b/c` — alle als „kaputter Pfad"
   markiert.

---

### Die Repo-Frage

Beantwortet **nicht** nach Gefühl, sondern nach deiner eigenen Regel in
`documentation.nvim/docs/ECOSYSTEM.md`:

> „it does not fit lib.nvim (a library of helpers, not a place for a feature
> with its own UI, state and history)"

Der Hover trifft 3 von 3: UI (4× `nvim_open_win`, global geliehene Keymaps,
eigene Highlight-Gruppen), State (LRU, `_open`, `_suppressed`, `_generation`,
Session-Schalter, On-Disk-Cache), History (Scroll-Offset/Seite, Fetch-Cache).

Dazu: 3 949 LOC = 8,3 % von lib.nvim, drittgrößtes Modul, in **vier Tagen**
entstanden. Einziges Modul, das gleichzeitig Fenster öffnet, Autocmds
installiert **und** `:Lib`-Routen mitbringt. Einziges, das vier
Geschwister-Plugins namentlich kennt. Einziges, das ein Plugin-Host ist.

Kosten: die gesamte lib.nvim-Oberfläche waren **neun Module generischer
Infrastruktur mit null lib.nvim-spezifischer Kopplung** — kein `wrap_lib()`-
Äquivalent. Präzedenzfall zweimal gelaufen: `lib.nvim.docmap` →
documentation.nvim, `lib.nvim.telemetry` (2 915 LOC) → runtime-analysis.nvim
(`71032e1`, 2026-08-03).

---

## Der Namensentscheid, und was daran offen bleibt

Du hast `hover.nvim` gewählt, nachdem ich Einspruch erhoben hatte. Der
Einspruch stand zunächst im README; **auf deine Anweisung ist er dort und im
Vimdoc entfernt** — im Repo steht jetzt nirgends mehr etwas über den fremden
Repo-Namen. Er lebt nur noch hier, damit er nicht ganz verloren geht:

`lewis6991/hover.nvim` existiert und ist verbreitet. Die *Repo*-Namen
kollidieren nicht, die **Lua-Modulwurzel schon**: beide liefern `lua/hover/`,
und wer beide installiert, bekommt still das, was früher auf der
`runtimepath` liegt. Für ein öffentliches Plugin ist das ein echter Defekt,
kein Schönheitsfehler.

**Falls das je umbenannt werden soll**, ist der Aufwand heute noch klein und
wächst mit jedem Konsumenten: Verzeichnis `lua/hover/` → `lua/<neu>/`, ein
`sed` über die Require-Pfade, der `Hover.`-Typnamensraum, `:Hover` → `:<Neu>`,
`vim.g.hover_disable`, die drei Highlight-Gruppen, markdown.nvims fünf
Require-Zeilen, die Config-Spec. Kandidaten waren `pathhover.nvim` und
`hoverport.nvim` (Anschluss an `pdfport`).

---

## Was im Plugin neu ist (nicht nur umgezogen)

Der Umzug war „a rename rather than a rewrite" — Previews, Float,
Klassifikation, Registry und beide Placement-Invarianten sind unverändert
übernommen. Neu ist das, was der Umzug der richtige Moment war, **einmal statt
zweimal** zu schreiben:

---

### 1. Das Opt-in-Modell

Zwei Achsen statt „Zieltyp": **wie explizit war das Ziel** (Link-Syntax = der
Autor behauptet etwas; Bare Path = wir raten) und **wie viel sagt die Vorschau,
was nicht schon dasteht** (ein Dateikopf steht nicht im Linktext; Host und
Pfad einer URL schon). Kosten als Stichentscheid. Das Modell **leitet jeden
bestehenden Default korrekt her** und zeigt genau die zwei, die falsch waren.

---

### 2. `mode`: auto | manual | off

`manual` behält jede Preview und gibt nur den automatischen Auslöser auf. Das
ist die Antwort auf „ich lese gerade ein Dokument aus Links", ohne Klasse für
Klasse entscheiden zu müssen. `:Hover show`, `keymaps.show` und
`show({ force = true })` antworten dann weiterhin **voll**, Web-Links
inklusive.

---

### 3. Schalter aus **einer** Tabelle

`lua/hover/switches.lua` speist Routen, Completion, `:Hover status` und
`:checkhealth` gleichzeitig. Damals sieben, heute neun.

**Der Anspruch "ein weiterer Schalter ist ein Tabelleneintrag und sonst
nichts" stimmte nicht.** Zwei Konsumenten lasen die Tabelle gar nicht, sondern
fuehrten eigene Listen -- und der achte und der neunte Schalter haben je einen
davon aufgedeckt. Siehe [Dieselbe Bug-Klasse
dreimal](#dieselbe-bug-klasse-dreimal). Jetzt stimmt er.

Implikation läuft **nur nach oben**: `fetch` → `web` → `links`. Nach unten
antwortet die Leseseite (`config.web_enabled()` ist
`links_enabled() and links.web`), so dass `:Hover links off` Web-Links
stummschaltet, ohne ihr Flag zu löschen.

---

### 4. Die verschärfte Bare-Path-Regel

Eine Endung muss auf der **letzten** Komponente sitzen, und das `./`-Präfix
zählt nicht mehr für sich allein. Das kostet echte True Positives (`~/notes`,
`/etc/hosts`, `lua/lib/nvim` wenn sie nicht existieren) — mit Absicht: es ist
die einzige Preview-Klasse, deren Wert *negativ* wird, wenn sie falsch liegt.

---

### 5. Kleineres

- `trigger = { "cursor" }` — `CursorMoved` + eigener Debounce, erbt
  `updatetime` nicht mehr. Nicht Default (Begründung in `docs/ROADMAP.md`).
- `keymaps.show`, default `false`.
- `:checkhealth hover` mit einem Check pro Soft-Dependency, der nach dem
  tatsächlich aufgerufenen Entry Point fragt statt nur nach dem Modul.
- **Gefundener Altbestand-Bug:** `preview/media.lua:376` enthielt ein **rohes
  NUL-Byte** im Quelltext (Cache-Key-Separator). Jetzt als `"\0"`-Escape. Der
  Bug steckte danach nur noch in lib.nvims Kopie, wo git und stylua die Datei
  deshalb als binär behandelten — **mit `5450dd4` ist die Kopie gelöscht und
  in `lua/` findet sich kein NUL-Byte mehr.**

---

## Was wo geändert wurde

| Repo | Stand | Commit |
| --- | --- | --- |
| **hover.nvim** (neu) | `main` bis `e62f5e9`, **alles gepusht** | Extraktion, dann ~40 bis `e62f5e9` |
| **markdown.nvim** | gepusht, `main` | `bd53428`, `634121f`, `c61493f` |
| **nvim-config** | `main`, **alles gepusht** (zuletzt `9eab27f4`) | `97051225`, `69907c0e`, `af1a8c60`, `7a0027b4`, `4e2cf2c4`, `b98eac26`, `ab92f427` |
| **lib.nvim** | gepusht, `main` | `5450dd4` (Hover gelöscht), `556ee50` (safe_api-Typen) |
| **images.nvim** | gepusht, `main` | `b61b347` — stale Verweise auf `markdown.hover` |
| **pdfport.nvim** | gepusht, `main` | `b43fd1c` — dito, plus `docs/install.json` |
| **migrate.nvim** | gepusht, `main` | `efb1ae4` — Position-Preview |
| **reposcope.nvim** | gepusht, `main` | `b4d6eff` — `owner/repo`-Source |
| **documentation.nvim** | gepusht, `main` | `b23ab85` — Modul-Preview |
| **spotlight.nvim** | gepusht, `main` | `23f3f25` — Token-Zähler |
| **sandbox.nvim** | gepusht, `main` | `3647a17` — Container-Image, nur auf Nachfrage (`on_request`) |

---

### markdown.nvim

Reines Require-Pfad-Rename plus Typnamen. `Mkdn.HoverUrlConfig` zeigt jetzt
auf `Hover.LegacyUrlConfig`, nicht auf `Hover.LinksConfig` — bewusst, weil
markdown.nvim weiterhin `url = { hover, fetch }` übergibt und hover.nvim das
normalisiert. Ein Verhaltens-Pin musste mit: `HoverMissing` statt
`LibHoverMissing`. Volle Suite grün (27 Specs).

---

### nvim-config

- `lua/plugins/personal/init.lua`: `require("lib.nvim.hover").enable()` raus,
  eigene `StefanBartl/hover.nvim`-Spec rein (`lazy = false`, `priority = 900`),
  `hover.nvim` in die github_stats-Repo-Liste.
- `lib.nvim_usrcmds.setup({ hover = false })` — die `:Lib hover …`-Routen
  wären sonst eine tote Schalteroberfläche.
- `docs/NOTES/PersonelPlugins/BINDINGS/{Usercmds,Keymaps,Autocmds}/hover.nvim.md`
  angelegt.

Aufgelöst wird das Plugin über `lua/plugins/personal/source.lua:92`
(`spec.dir = local_dev(name)`), also direkt aus `E:/repos/hover.nvim` — **kein
`:Lazy sync` nötig**.

---

## Verifikation (alles tatsächlich gelaufen)

| Prüfung | Ergebnis |
| --- | --- |
| Specs hover.nvim | **229 grün**, 0 Fehler (bare_git 10, bare_path 48, config 17, **docs 13**, **registry 71**, scope 26, switches 30, zoom 14), gemessen 2026-09-02 nach `e62f5e9` |
| Specs der Nachbarn | migrate, reposcope, documentation, spotlight — alle vier grün |
| `stylua --check` / `luacheck` | sauber in jedem berührten Repo |
| LuaLS (`scan.sh`, echte injizierte Library) | **0 Befunde**, zuletzt `post-f` (`e62f5e9`) auf dem Haupt-Checkout; davor `post-b` (`3e12c9f`), `post-c` (`4e1760f`), `zoom-pre`, `zoom-post2` (`65ba8dd`), `post-d` (`aca73fa`). Zwei Läufe fanden etwas: **einmal +2** (siehe unten) und **`post-e` einmal +1 auf unangetastetem Quelltext**, das `post-e2` auf identischem Baum nicht reproduzierte — der Scan flackert, siehe [J / Fund 3](#fund-3-die-luals-messung-flackert) |
| CI | grün auf **ubuntu-latest und windows-latest** (Run `33604859057`) |
| Helptags | 30 Tags (`hover-contribute` kam mit `c374d5e` dazu) |
| Doku-Beispiele | 23 ```lua-Blöcke laden, die ausführbaren laufen; 32 dokumentierte `:Hover`-Routen sind alle echt |

---

## Was seit der Extraktion passiert ist

Grob chronologisch. Was in `hover.nvim/docs/ROADMAP.md` gelöscht wurde, ist
gebaut — die Datei führt keine erledigten Punkte.

---

### Gebaut

- **Positions-Gate** (`b2b4b2c`) — Bare Paths werden in Code nicht mehr
  gesucht, nur in Kommentaren und Strings. Die Regel ist *umgekehrt* zu dem,
  was die Roadmap vorschlug, und das ist der Kern: „nur in Kommentaren und
  Strings erlauben" setzt voraus, dass Prosa-Buffer keinen Parser haben —
  markdown, gitcommit und rst haben aber einen.
- **Position-Previews** (`1b4cc8d`) — dritte Beitragsart neben `sources` und
  `previews`, für Aussagen über einen *Ort* statt über ein Ziel. War der
  Blocker für vier Plugins.
- **`init.lua:42` und `file.lua:10-20`** (`75f960e`, `4f83f2f`)
- **`:Hover why`** (`d07ee32`) — welches der sieben Gatter abgelehnt hat.
- **`:Hover pin`** (`8d26756`) — ein Float dem Cursor aus der Hand nehmen.
- **Git-Objekt unter dem Cursor** (`4cad7dc`) — nur auf `:Hover show`.
- **`gf` öffnet, was der Float zeigt** (`f2e0788`) — geroutet durch open.nvim.
- **`:Hover status` als Auswahl** (`144c405`) — lib.nvims UI-Kit.
- **`on_request`** (`731bbe2`) — ein Beitrag darf sagen, dass seine Antwort
  teuer ist, und wird dann nur bei `:Hover show` gefragt. Entschieden wurde
  die **Tabellenform** (`{ fn = …, on_request = true }`), nicht eine vierte
  Beitragsart: das Flag gilt für `sources` und `positions` identisch, und ein
  Paar `sources_on_request`/`positions_on_request` hätte von Hand in Schritt
  gehalten werden müssen — genau die Bug-Klasse, die dieses Repo dreimal
  getroffen hat.
- **Fünf Nachbarplugins verdrahtet** — migrate (veraltete API auf dieser
  Zeile), reposcope (`owner/repo` → gecachter README), documentation (was ist
  dieses Modul), spotlight (wie oft kommt dieser Token vor), sandbox
  (`nginx:1.27-alpine` — geholt? wie groß? läuft was davon?, nur auf
  Nachfrage).
- **`contribute` in `setup()`** (`c374d5e`) — ein eigener Hover ohne Plugin
  drumherum: dasselbe Tabellenformat, das `register` nimmt, registriert unter
  dem Namen `"user"`. Die API war immer öffentlich; angeboten wurde sie nie.
- **Der Hauptschalter schlägt jetzt `force`** (`3e12c9f`) — `mode = "off"` und
  `vim.g.hover_disable` galten für jede ausdrückliche Route nicht, also auch
  nicht für die Keymap eines Hosts. Ein Veto, das ein Tastendruck aushebelt,
  ist keines. Details unter [B](#b-die-docs-der-eingebundenen-plugins-durchgehen--erledigt-2026-09-02).

---

### Drei Messungen, die alle der Intuition widersprachen

Das ist das Muster dieser Sitzungen und der Grund, warum in `hover.nvim`
nichts ohne Zahl optimiert wird:

1. **Ein Bare Path, der nicht existiert, kostete 13,2 ms** — pro Trigger, in
   genau der Population, die das Plugin einlädt. Die alte Zahl (~3 µs) war
   über eine Quelldatei genommen, in der fast jede Position Prosa ist. Jetzt
   58,6 µs (`75f960e`), **225×**. Und die Lösung war *nicht* „billiger
   Resolver zuerst": gopath beantwortet alles, was es kann, unter 500 µs —
   teuer sind nur die Fehlschläge.
2. **Das Treesitter-Gate ist 80× teurer als das Token-Gate davor**, nicht
   billiger. Es ist nur tragbar, weil das Token-Gate 99,8 % vorher wegwirft.
   Die Roadmap wollte es umgekehrt anordnen.
3. **Ein Git-Spawn kostet 41 ms, ein Docker-Spawn 230 ms, Podman 490 ms** —
   Fehlgriff wie Treffer. Das hat entschieden, dass die Git-Klasse nur auf
   ausdrückliche Nachfrage antwortet und sandbox.nvim gar nicht geht.

---

### Dieselbe Bug-Klasse dreimal

**Jede Stelle, die eine Liste von Schaltern von Hand führt, fällt irgendwann
hinter die Tabelle zurück, ohne dass etwas fehlschlägt.** Dreimal getroffen:

- `usrcmds.route_path` (`ac50599`) — ein neuer Schalter landete auf oberster
  Ebene statt unter seinem Elternteil.
- `switches.effective` (`144c405`) — ein neuer Schalter las sich als dauerhaft
  aus; `:Hover status` und `:checkhealth` logen beide.
- `preview/office.lua` (`a5531e5`) — das Badge nannte `:Lib hover office on`,
  einen Befehl, den es nicht mehr gab.

Alle drei sind jetzt abgeleitet statt aufgezählt, und die Specs dagegen sind
über `switches.names()` geschrieben statt über eine Liste, damit ein zehnter
Schalter ab seiner Deklaration mitgedeckt ist. **Wenn eine vierte solche
Stelle auftaucht, ist das der erste Verdacht.**

**Die vierte Stelle ist am 2026-09-02 aufgetaucht — in der Doku.** Die
Namensliste von `hover.set()` im Vimdoc führte sieben von neun Schaltern
(`code` und `positions` fehlten), und in `docs/INTEGRATIONS.md` und
`docs/ROADMAP.md` standen vier handgezählte Zahlen, die alle hinter der
Wirklichkeit lagen. Dieselbe Klasse, eine Stufe schlechter: in Code deckt
irgendwann eine Spec sie auf, in Doku merkt es niemand. Behoben in `c374d5e`
und `15837dd`, wo es ging durch Streichen der Zahl — Details unter
[E](#e-eine-roadmap-datei-unter-docsroadmappersonal--erledigt-2026-09-02).

**Seit `4e1760f` deckt sie auch in der Doku eine Spec auf.**
`TESTS/docs_spec.lua` fragt neun Behauptungen der Dokumente gegen die Quelle
ab — Schalternamen, jede ausgeschriebene Schalterzahl, jede `:Hover`-Route in
beide Richtungen, die beanspruchbaren Zieltypen, die Augroups und die
Highlight-Gruppen. Damit ist das erste Mal *derselbe* Mechanismus hinter der
Doku wie hinter dem Code: eine Liste, die von Hand geführt wird, fällt beim
nächsten `scripts/test.sh` auf. Details unter [G](#g-ein-spec-das-die-doku-gegen-die-quelle-prüft--erledigt-2026-09-02-4e1760f).

---

### Und eine vierte Klasse: eine Funktion, zwei Fragen

`has_positions()` beantwortet **eine** Frage: „soll für diesen Buffer
überhaupt ein `CursorHold` installiert werden?". Ein `on_request`-Beitrag
zählt dafür bewusst nicht — ein Trigger, der aufwacht, niemanden fragt und
wieder einschläft, ist reine Kosten.

`show_position` benutzte dieselbe Funktion als Vorab-Wächter, **vor** der
`force`-Prüfung. Damit lehnte ein Buffer, dessen einziger Beitrag
nachfrage-only war, auf beiden Wegen ab: automatisch richtig, ausdrücklich aus
Versehen. Das Feature aus `731bbe2` war nie erreichbar.

Zwei Dinge daran sind das Lernstück:

- **Gefunden nur durch echtes Verdrahten.** Die Registry-Specs riefen
  `position_at` direkt — unterhalb des Wächters. Erst der Weg über
  `hover.show` kreuzt ihn, und erst sandbox.nvim ging diesen Weg. Ein Feature,
  das nur seine eigene Unit-Spec hat, ist nicht bewiesen.
- **Der Fix darf die andere Frage nicht mitverkaufen.** Erreichbarkeit
  dadurch zu kaufen, dass der Trigger doch installiert wird, hätte den Grund
  für `on_request` beseitigt. Eine der vier neuen Specs hält genau das fest.

Behoben in `836a15a`, mit Sabotage-Test: der alte Code lässt zwei der vier
neuen Fälle fallen.

---

## Offene Punkte

Die vier Punkte, die hier standen, sind erledigt; was an ihnen gelernt wurde,
steht unter [Was seit der Extraktion passiert
ist](#was-seit-der-extraktion-passiert-ist). Was übrig ist:

---

### 1. Demo-GIF — **braucht dich**

`REL-09`, der letzte offene Punkt des Release-Gates und der einzige, den ich
nicht erledigen kann: ich kann keine Bildschirmaufnahme machen. Die README
trägt ein ASCII-Modell des Floats, das die Idee erklärt, aber nicht das
Gefühl — und zu zeigen wäre gerade, wie wenig es beim Lesen stört.

---

### 2. Fünf Aufträge liegen in fremden Repos

Die Liste steht **einmal**, in
[Roadmap Abschnitt 4](./hover.nvim-roadmap.md#4-aufträge-die-woanders-liegen):
gopath.nvim, documentation.nvim, language.nvim, bindings-explorer.nvim,
insights.nvim. Jeder Eintrag dort nennt Adressat, Messung und Umgehung. Ein
sechster, **sandbox.nvim, ist am 2026-09-02 erledigt** (`deb45bc`) und steht
dort durchgestrichen mit dem Befund. Hier steht nur, was dort nicht hingehört,
weil es die *Begründung* ist und nicht der Auftrag:

**Warum `on_request` bei language.nvim nicht dasselbe ist wie bei sandbox.**
Bei sandbox entscheidet eine billige Textprüfung *vor* jedem Prozessstart, ob
überhaupt gefragt wird — `init.lua:42` wird in unter 1 ms abgelehnt, weil die
letzte Namenskomponente eine Endung trägt. Bei einem Wort-Nachschlag ist
**jedes Wort ein Wort**; es gibt keine solche Vorprüfung, also ist auch unter
`force` jede Position ein Treffer. Der Mechanismus überträgt sich, die
Sparsamkeit nicht — und deshalb ist das dort eine Produktfrage („soll `:Hover
show` mitten in Prosa immer ein Wörterbuch aufmachen?") und keine technische.

---

### 3. Beobachten, ob `manual` der bessere Default ist

Die Config läuft auf `auto`. Wenn es weiter nervt, ist der Griff
`:Hover mode manual` plus ein `keymaps.show`-Key — und wenn *das* sich als das
Richtige erweist, gehört es in die Spec statt in eine Sitzung.

Inzwischen gibt es zwei Werkzeuge, die diese Frage schärfer stellen als vorher:
`:Hover why` sagt, warum ein Float *nicht* aufging, und das Positions-Gate hat
die Hälfte des Rauschens ohnehin entfernt. Die Frage könnte sich erledigt
haben.

---

### 4. Was keine CI prüft

`hover.nvim/docs/MANUAL-EVIDENCE.md` führt es, seit `b7c4c45` **fünf** Zeilen:
gezeichnetes Bild, gezoomtes Bild, rasterisierte PDF-Seite, konvertiertes
Office-Dokument, `on_request`-Beitrag. Die Datei deckt damit nicht mehr nur
ab, was ein Terminal zum **Zeichnen** braucht, sondern auch, was einen
**Daemon zum Antworten** braucht. Zahlen, Maschine und Wiederholungsanleitung
stehen dort, nicht mehr hier — das ist die Drift-Regel, und diese Tabelle war
zwei Sitzungen lang ihre Ausnahme.

Was davon **offen** ist:

- **Der Office-Pfad**, seit der Cache-Änderung (`bba2064`, überlebt jetzt die
  Sitzung) nicht mehr von Hand geprüft. Braucht dich: was zu bestätigen wäre,
  steht in der Zeile dort.
- **Das Demo-GIF**, siehe Punkt 1.

Der `on_request`-Pfad ist **zu** (`b7c4c45`, Einzelheiten unter
[J](#j-die-on_request-messung-gelaufen-und-sie-hat-drei-dinge-gefunden-b7c4c45-e62f5e9)):
gemessen gegen Docker Engine 29.5.3, und der Lauf ist mit
`scripts/onrequest_probe.lua` wiederholbar statt jedes Mal neu gebaut.

---

## Aufträge aus der Sitzung vom 2026-09-02

Ursprünglich sechs Punkte, **alle abgeschlossen**: A, B, C, D, E erledigt, F
entschieden statt gebaut (nur Bilder, siehe dort). Was hier steht, ist jeweils
schon **nachgesehen** — die Notiz sagt den Befund, nicht nur die Frage.

**G bis J kamen in den Folgesitzungen desselben Tages dazu** — nicht aus
dieser Liste, sondern aus der [persönlichen
Roadmap](hover.nvim-roadmap.md), die seit E daneben liegt:
[G](#g-ein-spec-das-die-doku-gegen-die-quelle-prüft--erledigt-2026-09-02-4e1760f)
(das Doku-Spec, Voraussetzung dafür, dass alles Obige dokumentiert *bleibt*),
[H](#h-eine-checkhealth-zeile-für-contribute--erledigt-2026-09-02-aca73fa)
(`:checkhealth` sagt, wer registriert hat),
[I](#i-die-messung-für-25--gelaufen-und-die-antwort-ist-nein) (2.5 gemessen
und abgelehnt) und
[J](#j-die-on_request-messung-gelaufen-und-sie-hat-drei-dinge-gefunden-b7c4c45-e62f5e9)
(der `on_request`-Pfad gegen eine echte Engine). **Zehn Buchstaben, keiner
offen.**

---

### A. Die BINDINGS-Notes für hover.nvim nachziehen — **erledigt 2026-09-02**

**Die drei Dateien existierten, waren aber veraltet.**

```
docs/NOTES/PersonelPlugins/BINDINGS/{Keymaps,Usercmds,Autocmds}/hover.nvim.md
```

Die Usercmds-Datei führt sieben Routen (`show`, `toggle`, `status`, `links`,
`links off`, `mode auto`, `paths code`). Tatsächlich gibt es außerdem
mindestens `why`, `pin`, `positions`, `positions off`, `office`, `office on`,
`images`, `paths missing`, `mode` und `off` — plus neun Schalter
(`links, web, fetch, paths, missing, code, positions, images, office`).

Zu beachten:

- **Format ist vorgeschrieben:** `docs/NOTES/BINDINGS-FORMAT.md` — Titel,
  `Source:`-Zeile, Intro, Haupttabelle mit eigener Überschrift über *jeder*
  Tabelle, `## which-key`, `## Notes`, `## Changelog`.
- **Es gibt einen Parser dafür.** `bindings-explorer.nvim` liest genau diese
  Tabellen (`records.lua` → `drift.lua`). Nach dem Schreiben also
  `:Bindings check` laufen lassen — das ist die Drift-Erkennung, und sie ist
  der eigentliche Zweck der Formatpflicht.
- Die Schalter sollten **abgeleitet** aufgeschrieben werden, nicht abgetippt:
  `switches.names()` ist die Quelle, und dieses Repo ist dreimal daran
  gescheitert, so eine Liste von Hand zu führen (siehe [Dieselbe Bug-Klasse
  dreimal](#dieselbe-bug-klasse-dreimal)).

**Was tatsächlich fehlte**, gegen `composer.document("Hover")` abgeglichen:

- **Usercmds:** `:Hover why`, `:Hover pin`, `:Hover positions` fehlten ganz;
  die Datei führte 7 von 15 Aufrufen und nannte neun Schalter „acht".
- **Keymaps:** `open_keys` (`gf`) fehlte — seit `f2e0788` geliehen und die
  einzige geliehene Taste, die ein Vim-Builtin verdrängt.
- **Autocmds:** die Regel „nichts, was antworten könnte" hatte eine dritte
  Frage bekommen (Position-Previews); der Changelog-Eintrag behauptete
  ausdrücklich das Gegenteil. Dazu `hide_unless_pinned()` statt `hide()` und
  der `mouse`-Trigger.

**Und ein Befund, der über hover.nvim hinausgeht:**

> `:Bindings check` deckt diese Tabelle **nicht** ab, sieht aber so aus, als
> täte es das. Gemessen: eine Zeile aus der Tabelle gelöscht, und sowohl
> `:Bindings check hover.nvim` als auch der volle Lauf melden *keine Drift*.
> hover.nvim war dabei geladen — es steht nicht unter „skipped".
>
> Der Grund: verglichen wird gegen `nvim_get_commands({})`, und dort stehen
> nur **Kommandos oberster Ebene**. Dieses Plugin registriert genau eines,
> `Hover`; alle fünfzehn Zeilen fallen darauf zusammen, es existiert, beide
> Richtungen bestehen trivial.
>
> Das betrifft **jedes** Plugin auf `usercmd.composer` — also die halbe
> Personal-Sammlung. Ein bestehender Check auf einer verrotteten Tabelle ist
> schlechter als gar keiner, deshalb gehört das als Task nach
> bindings-explorer. Maßgeblich ist bis dahin `composer.document("<Verb>")`
> (schreibt eine **Datei** mit dem Namen des Kommandos und gibt `true`
> zurück — nicht den Text).

---

### B. Die Docs der eingebundenen Plugins durchgehen — **erledigt 2026-09-02**

**images.nvim, markdown.nvim, pdfport.nvim, gopath.nvim** — jeweils prüfen, ob
ihre eigene Doku erwähnt, was sie zum Hover beitragen, und ob das noch stimmt.

Anlass: in `b61b347`, `b43fd1c` und `c61493f` wurden dort bereits veraltete
Verweise korrigiert, aber nur die, die beim Umbenennen auffielen. Nicht geprüft
ist, ob die vier eine *inhaltlich* aktuelle Beschreibung ihres Hover-Anteils
haben — z. B. dass pdfport seit `:Hover office on` auch `.docx`/`.xlsx`/`.pptx`
über LibreOffice liefert, oder dass gopath vor Vims eigenem `<cfile>` gefragt
wird.

Die fünf über die Registry angebundenen (migrate, reposcope, documentation,
spotlight, sandbox) haben jeweils ein eigenes `docs/hover.md` und sind aktuell
— die sind in dieser Runde entstanden.

**Durchgegangen, und jedes der vier hatte etwas:**

- **pdfport.nvim** (`7445ea5`) — dreimal der falsche Konsument. `render_page()`
  stand als „used by images.nvim to show PDF pages as images"; images.nvim ruft
  es **nie**, sein einziger pdfport-Aufruf geht in die Gegenrichtung
  (`convert.lua` → `create()`, Bild *zu* PDF). Und `create()` stand als „how
  lib.nvim's hover previews a `.docx`" — mit Link auf lib.nvim, das seit
  `5450dd4` keinen Hover mehr hat. `docs/FEATURES/PRODUCERS.md` hatte es
  richtig, woran die README-Fassung auffiel.
- **gopath.nvim** (`c9faf86`) — **erwähnte den Hover nirgends.** Zwei Repos
  rufen `resolve_at_cursor` von außen (hover.nvim, images.nvim), und keine
  Seite sagte das. Das ist die Richtung, die weh tut: ein falsches „✗ no such
  file" sieht aus wie ein Resolver-Urteil und ist keines, also landen die
  Bugreports dort. Neu: `docs/FEATURES/INTEGRATIONS.md`, verlinkt aus beiden
  Indizes, samt der 13,2-ms-Messung als Auftrag (siehe unten).
- **images.nvim** (`e58cd64`) — nannte die falschen APIs als Zeichenweg
  (`images.info` + `images.scale.fit_cells` „to draw the picture"; die messen
  und rechnen, gezeichnet wird mit `images.anchor.draw`, um einen Tick
  verzögert). Dazu fehlte `gf` in der Tastenliste des Floats — die eine
  geliehene Taste, die ein Vim-Builtin verdrängt.
- **markdown.nvim** (`289bbcf`) — `docs/hover.md` war inhaltlich aktuell (es
  benennt hover.nvim als Framework und führt sogar die Vor-Umzug-Schreibweisen
  auf). Eine Aussage war falsch geworden, allerdings erst durch `3e12c9f`:
  „`hover()` ignores the `enabled` flag, so it works as a keymap even with the
  automatic hover switched off".

**Und der eigentliche Fund war in hover.nvim selbst** — er kam nur zustande,
weil ich für markdown.nvim nachgesehen habe, ob diese Aussage stimmt:

`show()` übersprang die Modus-Prüfung, sobald `force` gesetzt war. Gemessen
gegen ein echtes Neovim: `mode = "off"` plus `show({ force = true })` → `true`,
`vim.g.hover_disable` plus `force` → `true`. Drei Doku-Aussagen sagen das
Gegenteil, und die dritte ist die schlimme: `vim.g.hover_disable` existiert,
damit ein Leser einen Hover ablehnen kann, den ein **Host** eingeschaltet hat
— und jede ausdrückliche Route übergibt `force`, markdown.nvims Keymap
eingeschlossen. Das Veto wurde also von genau dem Plugin ausgehebelt, gegen
das es gerichtet ist. Dazu meldete `:Hover why` „mode: off" als Grund, während
`:Hover show` auf derselben Position ein Float öffnete.

Behoben in `3e12c9f` mit drei Specs (die zwei negativen fallen gegen die alte
Zeile). `manual` ist unberührt — das ist der Modus, den die alte Formulierung
eigentlich meinte.

**Zwei weitere Stellen in hover.nvim** (`87a1017`), beim selben Durchgang:
zwei Augroups hießen noch `MarkdownHoverDismiss` und `MarkdownNvimHoverMedia`,
mit `desc`-Strings, die markdown.nvim als Eigentümer nannten — sichtbar in
`:autocmd`. Sie sind auch der Grund, warum `docs/BINDINGS.md` und die
BINDINGS-Notes „zwei Augroups" führten: eine Suche nach `Hover` in der Quelle
fand sie nicht. Es sind vier. Beide Tabellen korrigiert (`ee826ea5` in der
Config).

---

### C. Die README von hover.nvim — **erledigt 2026-09-02** (`a57d390`)

**a) Struktur gegen die Geschwister.** Die Grundform stimmt bereits
(Inhaltsverzeichnis → Fähigkeiten → Quickstart → Integrations → Configuration →
Documentation). Zwei Abschnitte fehlen, die spotlight.nvim und
documentation.nvim beide haben:

- **`## Installation`** — hover verweist nur in einer Zeile auf
  `docs/installation.md`; die Geschwister haben den Block in der README.
- **`## Health`** — `lua/hover/health.lua` existiert, `:checkhealth hover`
  wird viermal im Fließtext erwähnt, hat aber keine eigene Überschrift.

`## License` fehlt bewusst (`REL-28`, keine Lizenzdatei) — das ist kein Befund.

**b) Die Integrations-Tabelle ist veraltet.** Sie existiert und hat die vier
Spalten (Plugin / was es allein ist / was es zum Hover beiträgt / ohne es),
aber sie ist vor den fünf Verdrahtungen geschrieben worden:

- **reposcope.nvim steht dort als „*planned*"** — ist seit `b4d6eff` verdrahtet.
- **migrate, documentation, spotlight, sandbox fehlen ganz.**
- Die Tabelle „Die zwei Türen" nennt als Registry-Ankömmling nur
  markdown.nvim; es sind inzwischen sechs.

Dazu der ausdrückliche Wunsch: die Tabelle soll die eigenen Plugins nicht nur
auflisten, sondern **empfehlen** — also sagen, was der Leser gewinnt, wenn er
sie installiert, nicht nur was er ohne sie verliert.

**Umgesetzt in `a57d390`:** reposcope-Zeile korrigiert, fünf Zeilen ergänzt,
die Türen-Tabelle nennt jetzt alle sechs Registry-Ankömmlinge, ein
Abschnitt „Worth installing alongside it" vor der Tabelle, und ein
`## Health`-Abschnitt (der Healthcheck hat vier Sektionen, weil „der Hover
tut nichts" vier Ursachen hat, die von außen gleich aussehen). sandbox.nvim
zusätzlich in beide Tabellen von `docs/INTEGRATIONS.md`.

**Zur Strukturfrage revidiert:** `## Installation` fehlt *nicht* wirklich —
`## Quickstart` ist faktisch dieser Abschnitt, und images.nvim nennt ihn
genauso. Es gibt hier keine einheitliche Geschwister-Konvention, also war das
kein Befund. `## Health` war einer und ist behoben.

---

### D. Eine Beitrags-API für Nutzer — **erledigt 2026-09-02** (`c374d5e`)

**Der Befund: die API gibt es schon, sie ist nur nicht als Nutzer-API
gedacht.** `require("hover.registry").register(name, contribution)` ist ein
öffentliches Modul und funktioniert aus einer `init.lua` genauso wie aus einem
Plugin. `enable(opts)` nimmt dagegen **nur** Konfiguration — Beiträge gehen
ausschließlich über die Registry.

Was tatsächlich fehlt, ist klein:

1. **Ein Durchreichen in `enable()`** — `sources`/`positions`/`previews` als
   Options-Feld, das intern `register("user", …)` ruft. Damit steht das
   Feature dort, wo ein Nutzer es sucht: in seiner eigenen Setup-Tabelle.
2. **Ein Doku-Abschnitt aus Nutzersicht.** `docs/INTEGRATIONS.md` ist an
   Plugin-Autoren adressiert („Contributing from a plugin"). Derselbe
   Mechanismus als „so baust du dir einen eigenen Hover" ist ein anderer Text,
   kein anderer Code.

**Aufwand:** klein — ein Options-Feld, ein `register`-Aufruf, ein Spec, ein
Doku-Abschnitt. **Nutzen:** groß, weil es die Einstiegshürde von „schreib ein
Plugin" auf „schreib eine Funktion" senkt. **Empfehlung: bauen.** Der einzige
Entwurfspunkt ist, ob `enable()` bei wiederholtem Aufruf die Nutzerbeiträge
ersetzt — `register` tut das bereits pro Name, also fällt das von selbst
richtig aus.


**Umgesetzt in `c374d5e`.** `setup`/`enable` nehmen ein Feld `contribute`, und
es nimmt *genau* die Tabelle, die `register` nimmt — `sources`, `previews`,
`positions` und die `{ fn = …, on_request = true }`-Form eingeschlossen.
Bewusst kein zweiter Mechanismus: ein Vertrag zu lernen, einer zu
dokumentieren. Registriert wird unter dem Namen `"user"`.

Zwei Eigenschaften waren beim Bauen wichtiger als das Feld selbst, und beide
sind Spec-gedeckt:

- **Es landet nicht in der Options-Tabelle.** Funktionen sind keine
  Konfiguration, und `config.setup` mergt Listen per Index — zwei
  aufeinanderfolgende `contribute`-Listen würden sich verschränken statt zu
  ersetzen. Genau die Klasse, für die `replace_key_lists` existiert.
- **Die Tabelle des Aufrufers wird nicht verändert.** Das Feld wird aus einer
  flachen Kopie entfernt, nicht in der übergebenen Tabelle gelöscht — ein Host
  reicht seine eigene lebende Config durch (markdown.nvim tut das).

`enable()` läuft jetzt über `M.setup` statt direkt über `config.setup`. Damit
bleibt „akzeptiert dieselben Optionen wie `setup`" wahr, und die Registrierung
passiert *vor* `autocmds.enable()`, das entscheidet, ob ein Buffer überhaupt
einen Trigger bekommt.

Sechs Specs, drei davon gegen das, was **nicht** passieren darf. Dazu ein Lauf
gegen ein echtes Neovim über `enable()`, weil die Specs über `setup()` gehen
und die Doku `enable()` zeigt.

Der Entwurfspunkt von oben ist so ausgefallen wie vermutet: `register` ersetzt
pro Name, also ersetzt ein zweiter `setup()` den Nutzerbeitrag von selbst. Was
daraus *neu* folgt und dokumentiert gehörte: ein Plugin darf dieses Feld nicht
benutzen, weil alle Nutzer-Beiträge sich den einen Namen `"user"` teilen und
zwei Aufrufer einander damit still löschen würden.

---

### E. Eine Roadmap-Datei unter `docs/ROADMAP/personal/` — **erledigt 2026-09-02**

Eine Analyse zu Optimierung und neuen Features, geschrieben als eigene Datei
neben dieser hier. **Nicht zu verwechseln** mit `hover.nvim/docs/ROADMAP.md`
— die liegt im Repo, ist an Mitlesende adressiert und führt bewusst keine
erledigten Punkte. Die Datei hier ist die persönliche, längere Fassung.

Abzugrenzen ist beim Schreiben, was in welche der beiden gehört, sonst driften
sie auseinander.

**Die Repo-Roadmap war selbst gedriftet — behoben in `f01511f`**, bevor etwas
Neues danebengelegt wird. Drei Falschaussagen, alle aus derselben Wurzel
(sandbox ist verdrahtet, `on_request` existiert):

- „**Four** of the candidates […] are built" — es sind fünf.
- Der Abschnitt „`sandbox.nvim` — the image under the cursor" stand noch als
  *offen* („What is left is on sandbox.nvim's side […] and the registration
  itself") und stellte eine Frage, die das Verdrahten längst beantwortet
  hatte: `nginx:1.27` und `init.lua:42` sind dieselbe Form, und die
  Registrierungsreihenfolge entscheide es. Sie tut es — in 1 ms.
- Der `language.nvim`-Eintrag behauptete, „behind `:Hover show` only" sei per
  Source **nicht** ausdrückbar. Genau das ist `on_request`. Der Eintrag nennt
  jetzt, was wirklich offen ist: nicht der Mechanismus, sondern die
  Produktfrage — sandbox kommt mit `on_request` durch, weil eine billige
  Textprüfung die meisten Positionen vor jedem Prozessstart ablehnt, und ein
  Wort-Nachschlag hat keine solche Vorprüfung.

Die Datei hat die Regel „ein Konzept, das ausgeliefert wird, wird gelöscht
statt abgehakt" — der sandbox-Abschnitt ist deshalb gelöscht, nicht
umgeschrieben. **Zoom für Bilder** steht jetzt unter `## Features` daneben, in
der Fassung für Mitlesende (kürzer als F hier, und ohne die Messungen).

**Dieselbe Drift eine Ebene tiefer.** `docs/INTEGRATIONS.md` trug vier
handgezählte Zahlen, die keine mehr stimmte: „one of five plugins", „adding a
sixth contributor", „the four that arrive through the registry" über einer
Tabelle mit sechs Zeilen, und ein Abschnitt überschrieben „markdown.nvim — the
only registry contributor today". Dazu im Vimdoc die Namensliste von
`hover.set()`: **sieben von neun Schaltern**, `code` und `positions` fehlten.

Das ist **der vierte Treffer der Bug-Klasse aus [Dieselbe Bug-Klasse
dreimal](#dieselbe-bug-klasse-dreimal) — und der erste in Doku statt in
Code**, wo nichts fehlschlägt und keine Spec ihn merken kann. Korrigiert in
`c374d5e` und `15837dd`, wo möglich durch **Streichen der Zahl** statt
Hochzählen; die Vimdoc-Zeile nennt jetzt `switches.names()` als Quelle, damit
der nächste Leser nachsehen kann statt zu glauben.

**Geschrieben:** [hover.nvim-roadmap.md](./hover.nvim-roadmap.md). §1 ist die
Abgrenzung, um die es hier ging, mit einer Regel gegen genau diese Drift:
*jeder Punkt lebt in genau einer der beiden Dateien* — wird etwas
veröffentlichungsreif, wandert er ins Repo und hinterlässt hier eine Zeile mit
Commit, statt kopiert zu werden.

Inhaltlich vier Bauvorschläge in Reihenfolge (Doku-Spec gegen die Quelle,
Zoom, eine Health-Zeile für `contribute`, ein Memo für Position-Previews —
letzteres ausdrücklich als **ungemessen** markiert), die offenen Messungen,
die Aufträge in fremden Repos, und was ich geprüft und verworfen habe. Der
erste Vorschlag ist die Konsequenz aus den vier Zahlen oben: ein Spec, das die
Schalterliste im Vimdoc und die Routentabellen gegen die Quelle prüft, weil
diese Klasse im Code dreimal und in der Doku viermal zugeschlagen hat.

---

### F. Zoom im Float — **eingegrenzt 2026-09-02, Tasten gebaut (`204d083`)**

> **Die Tastenhälfte steht.** `+` und `-` sind geliehen, solange ein Hover mit
> Bild offen ist; ein Schritt skaliert die Fläche um 1,25. Offen und in
> `docs/ROADMAP.md` verblieben sind das **Mausrad** und der **scharfe
> PDF-Zoom**. Was unten steht, ist die Voranalyse — sie hat gestimmt, mit
> einer Ausnahme, und für die beiden offenen Hälften gilt sie unverändert.
>
> **Zwei Dinge waren beim Bauen anders als hier vermutet.**
>
> 1. **Die Leih-Bedingung ist `content.canvas`, nicht `content.image_path`.**
>    Unten stand `image_path` als „naheliegend". `canvas` ist richtiger: es
>    ist genau das, was der Zoom *ändert*, und es deckt die rasterisierte
>    PDF-Seite mit ab, ohne dass ein zweiter Fall nötig wäre.
> 2. **Die PDF-Kollision, die unten die Reihenfolge begründet, gibt es
>    nicht.** Sie galt für die *Scroll*-Tasten — Zoom hat eigene, also
>    kollidiert nichts. PDF-Seiten zoomen seit `204d083` mit, gratis und
>    unscharf. „Bilder zuerst" war trotzdem die richtige Reihenfolge, nur
>    nicht aus dem hier genannten Grund.
>
> **Und eine Zahl, die vor dem Bauen gemessen wurde und die Bauform bestimmt
> hat.** 1200×675-Bild, Defaults 80×20, echtes Neovim, 2026-09-02:
>
> | Terminal | Schritte hinein | Bildfläche |
> | --- | --- | --- |
> | 210×55 | fünf | 71×20 → 181×51 Zellen |
> | 80×24 | **keiner** | 20 Zeilen sind bereits `lines - 4` |
>
> Daraus folgt: **keine Zoom-Grenze im Code.** Jede Zahl wäre auf einem der
> beiden Terminals falsch. Ein Schritt, der nichts ändert, wird
> zurückgenommen — dasselbe Idiom, mit dem `scroll` das Ende eines PDFs
> behandelt —, und der Pegel bleibt genau dort stehen, wo der Schirm aufhört.

Die Idee: mit der Maus in den Hover, Mausrad bzw. `<C-ScrollWheel>` zoomt.

**Der Umfang ist entschieden.** Gewollt sind **Bilder und Screenshots**.
PDF-Seiten, wenn es sich ergibt — **nicht zwingend**. Text fällt damit weg,
und das trifft sich, denn dort ginge es ohnehin nicht:

**Für Text geht es nicht, und zwar grundsätzlich.** Die Schriftgröße gehört
dem Terminal-Emulator; Neovim kann sie nicht ändern. „Zoom" könnte für Text
nur heißen: das Float größer machen — das zeigt *mehr*, aber nichts
*größer*. Das ist ein anderes Feature und sollte auch anders heißen.

**Für Bilder geht es wirklich.** Ein Bild wird über images.nvim in eine
Zellfläche gezeichnet; dieselbe Fläche größer angefordert heißt echte
Vergrößerung. Das ist der Fall, in dem „Zoom" das Wort trifft.

**Wo es andockt** (am Code nachgesehen, nicht geschätzt):

- **Die Fläche entsteht in `canvas_cells`** (`preview/media.lua:196`). Sie
  klemmt auf `opts.max_width` / `opts.max_lines` und den Bildschirm. Ein Zoom
  ist genau das Anheben dieser beiden Schranken für *diese eine* Vorschau —
  kein neuer Zeichenweg, und das Letterboxing über `images.scale.fit_cells`
  bleibt unangetastet.
- **Das Wiederanfordern gibt es schon.** `M.scroll(delta)` (`init.lua:841`)
  setzt `preview_opts.page` und lässt den Previewer erneut laufen; `_open`
  (`init.lua:503`) hält den Zustand dazu (`target`, `bufnr`, `offset`,
  `page`). Ein Zoomfaktor gehört an dieselbe Stelle: `_open.zoom` →
  `preview_opts` → `canvas_cells`. Kein zweiter Weg neben dem bestehenden.

**Und genau hier liegt die Arbeit, nicht beim Zeichnen:** die geliehenen
Tasten decken ausgerechnet den gewollten Fall nicht ab.

- **Für ein Bild wird heute gar keine Taste geliehen.** `keys.borrow`
  (`bindings/keymaps.lua:111`) installiert die Scroll-Tasten nur für Inhalte
  mit `content.scroll` — und ein Bild hat das nicht (`canvas_for` gibt
  `lines`, `canvas`, `image_path` zurück, sonst nichts). Das ist Absicht und
  im Modulkopf begründet: „Scrolling an image […] is meaningless". Zoom
  braucht dort eine **eigene** Leih-Bedingung, naheliegend
  `content.image_path ~= nil`.
- **Bei PDFs ist es umgekehrt:** dort *sind* die Scroll-Tasten geliehen, aber
  sie blättern. Zoom müsste sich dort andere Tasten nehmen, sonst kollidiert
  er mit dem Blättern. **Das** ist der Grund, warum „Bilder zuerst, PDF
  optional" die richtige Reihenfolge ist — nicht der Zeichenweg, der ist
  derselbe.

**Was PDFs kosten würden, falls doch.** Eine Seite ist nach
`pdfport.render_page` ein PNG und nimmt ab da denselben Weg wie jedes Bild —
`M.canvas_for` ist genau dafür öffentlich. Ein *unscharfer* Zoom fällt also
gratis mit ab: dasselbe PNG in eine größere Fläche. Ein *scharfer* wäre ein
zweites Rastern; `render_page` nimmt dafür `opts.dpi` (Default 216), hover
übergibt heute `nil`. Dagegen steht der Seiten-Cache: sein Schlüssel ist
`Pfad\0mtime\0Seite` (`media.lua:371`), **ohne DPI** — zwei Auflösungen
derselben Seite würden einander überschreiben. Mehr ist es nicht: ein DPI im
Schlüssel, ein DPI im Aufruf. Office-Dokumente hängen mit dran, sie *sind* an
dieser Stelle PDFs.

**Zur Maus zwei Voraussetzungen, beide geprüft:**

- **Das Float ist `focusable = opts.focusable == true`**, also standardmäßig
  *nicht* fokussierbar (`float.lua:293`). Die Maus kann so nicht hineinklicken.
  Man bräuchte entweder `focusable`, oder — sauberer — `getmousepos()` in
  einer globalen `<ScrollWheelUp>`-Map, um zu erkennen, dass der Zeiger über
  dem Hover steht, ohne den Fokus anzufassen.
- **`mouse` muss beim Nutzer gesetzt sein** (`set mouse=a`), sonst kommt gar
  kein Rad-Event an. Das ist ein Fall für `:Hover why`.

Beides gilt nur fürs Rad. Ein Tastenpaar (`+`/`-`) über dieselbe Leihe wie
`scroll_keys` hat **keine** dieser Voraussetzungen und ist außerdem die
kleinere Änderung — sinnvoll als erster Schritt, das Mausrad als zweiter.

---

### G. Ein Spec, das die Doku gegen die Quelle prüft — **erledigt 2026-09-02** (`4e1760f`)

Nicht aus der Auftragsliste, sondern Punkt 2.1 der persönlichen Roadmap — dort
als „als Erstes" empfohlen, weil die Klasse an einem Tag viermal die Doku und
dreimal den Code getroffen hat. `TESTS/docs_spec.lua`, neun Prüfungen:

| Prüfung | Quelle |
| --- | --- |
| Schalternamen im Vimdoc bei `hover.set()`, in Reihenfolge | `switches.names()` |
| jede ausgeschriebene Schalterzahl in *jedem* Dokument | `#switches.names()` |
| die Schalter-Zeile der README: Zahl und jeder Name als Routenpfad | `switches.spec().implies` |
| jede `:Hover`-Route, in beide Richtungen, in allen drei Tabellen (README, Vimdoc, `docs/BINDINGS.md`) | `usrcmds.routes()` |
| die beanspruchbaren Zieltypen im Vimdoc | die deklarierte Union `Hover.Target.type` |
| diese Union gegen die Dispatch-Kette | `build()` in `init.lua` |
| die Augroup-Tabelle | `autocmd.group("Hover…")` in der Quelle |
| die Highlight-Tabelle, **als Paare** | `HL_DEFAULTS` in `float.lua` |

Die Highlight-Prüfung vergleicht Name *und* Ziel: eine Tabelle kann alle drei
Gruppen führen und eine davon auf die falsche Farbe zeigen lassen.

**Bewusst außen vor: die Integrations-Tabellen.** Sie beschreiben fremde
Plugins; ein Spec dafür müsste alle sechs laden und prüfte dann die
Installation dieser Maschine statt das Dokument. Das bleibt eine menschliche
Behauptung.

**Drei Funde, alle behoben:**

- **`doc/hover.txt` nannte neun beanspruchbare Zieltypen, es sind zehn.**
  `registry.preview_for(target.type)` läuft *vor* der Dispatch-Kette, für
  jedes Ziel — `git` eingeschlossen. Ein Plugin kann eine Git-Objekt-ID
  genauso beanspruchen, wie markdown.nvim `anchor` beansprucht; die Doku sagte
  ihm, es ginge nicht.
- **`docs/INTEGRATIONS.md` schrieb `:Hover off`.** Den Befehl gibt es nicht —
  es ist `:Hover mode off`. Genau die Sorte, die `preview/office.lua` schon
  einmal hatte (`:Lib hover office on`).
- **`docs/installation.md`: „the mode and all seven switches"** — auf der
  Seite, die `:Hover status` erklärt. Es sind neun.

**Sabotage-Test gelaufen:** acht der neun fallen gegen die Dokumente, wie sie
vor diesem Commit standen; die neunte gegen einen Typ, der in die Union
aufgenommen wird, ohne einen Zweig zu bekommen, der ihn zeigt.

**Was das nicht kann.** Es prüft Mengen und Zahlen, keine Sätze. Ob eine
Beschreibung *stimmt*, sagt es nicht — dafür gibt es die Runde durch die Docs.
Es sagt nur, dass keine Liste hinter der Quelle zurückfällt, und das ist die
Hälfte, die von allein passiert.

---

### H. Eine `:checkhealth`-Zeile für `contribute` — **erledigt 2026-09-02** (`aca73fa`)

Punkt 2.3 der persönlichen Roadmap, und dort mit einem Vorbehalt versehen:
*„bauen, sobald `contribute` das erste Mal wirklich benutzt wird"*. Der ist
**nicht** eingetreten — gebaut auf Ansage, nicht auf Bedarf, und das gehört
hierher, weil die Hausregel sonst still umgangen wäre.

Was die Vermutung trug, hat der Einbau allerdings bestätigt und zwei Specs
halten es jetzt fest: `has_sources()` ist die Funktion, die auf die Frage „ist
meiner registriert?" zu antworten *scheint*, und sie antwortet **in beide
Richtungen falsch**.

| Lage | `has_sources()` | was gilt |
| --- | --- | --- |
| Der Beitrag ist ein Position-Preview | `false` | ist registriert |
| Der eigene Beitrag kam nie an, markdown.nvim ist installiert | `true` | ist *nicht* registriert |

Beides sind genau die Lesarten, die jemand als Defekt des Plugins meldet, und
deshalb stehen sie als Assertions da, nicht als Kommentar.

**Der Accessor: `registry.contributors()`.** Es gab bewusst keine
Introspektion im Modul — eine ohne Konsumenten wäre Ballast. Drei
Entscheidungen, die keine Formsache sind:

- **Zahlen, nicht die Funktionen.** Die Frage braucht Ankunft und Menge. Gäbe
  der Accessor die Callables heraus, wäre er ein zweiter Weg, sie
  aufzurufen — *außerhalb* des `pcall`, der verhindert, dass ein kaputter
  Beitrag den Hover für alle anderen mitnimmt.
- **Nach Namen sortiert.** Zwei der drei gelesenen Listen sind Arrays, die
  dritte (`previews`) ist nach Zieltyp verschlüsselt, und `pairs` hat keine
  stabile Reihenfolge. Ein Health-Report, der zwischen zwei Läufen auf
  derselben Konfiguration umsortiert, lässt sich nicht mit sich selbst
  vergleichen — und das ist das meiste, wofür ein Health-Report da ist.
- **`on_request` wird mitgezählt**, über beide Arten hinweg. Registriert,
  korrekt und trotzdem still auf dem automatischen Trigger: genau der Zustand,
  den jemand als „geht nicht" meldet.

**Die Ausgabe** unter *optional contributors*:

```
registry: markdown.nvim -- 2 sources, 2 previews
registry: user -- 2 position previews (1 asked only on `:Hover show`)
```

Leer bleibt es ein `info`, kein `warn`: keine Contributors installiert ist die
unterstützte Konfiguration, und bare paths, bare URLs und Git-Objekt-IDs sind
eingebaut.

**Sieben Specs, zwei davon sabotage-getestet** (Hausregel): ohne das
`table.sort` fällt der Sortier-Spec, ohne die `on_request`-Zählung auf den
Sources fällt der Zähl-Spec.

**Ein Fund nebenbei, in `@types`:** die Beschreibung von `Hover.SourceFn` hatte
sich gelöst und saß auf `Hover.OnRequest`, dessen eigener Text ohne Leerzeile
direkt darunter weiterlief. Zurück an den Alias gehängt, den sie beschreibt.
Kein LuaLS-Befund — ein Doc-Kommentar an der falschen Klasse ist genau die
Sorte, die nur beim Lesen auffällt.

**Gemessen nach dem Commit:** LuaLS-Pass `post-d` auf dem Haupt-Checkout,
**0 Befunde**, Delta `+0` gegen `post-c`. Suite 227 grün, luacheck 0/0.

---

### I. Die Messung für 2.5 — gelaufen, und die Antwort ist **nein**

Punkt 2.5 (ein Memo über `(bufnr, row, col, changedtick)` für Position-Previews)
stand unter „erst zählen, dann entscheiden". Gezählt ist jetzt. **Das Memo
gehört nicht gebaut**, und der Grund ist nicht die Häufigkeit, sondern der
Preis: die Häufigkeitsfrage hat sich durch die zweite Messung erledigt.

**Sitzung am 2026-09-02 unterbrochen** — die Messungen sind vollständig, die
Einarbeitung in `hover.nvim-roadmap.md` ist gemacht, nichts hängt halb.

---

#### Was die Struktur schon sagt, ohne Messung

`position_at` wird in `show_position` **vor** jeder Unterdrückungsprüfung
aufgerufen und `_open` wird gar nicht gelesen. Ein offenes Float, das die
Antwort gerade zeigt, verhindert also nicht, dass alle Beiträge erneut gefragt
werden. Einzige Ausnahme: ein **gepinntes** Float — `M.show` steigt bei
`_open.pinned` aus, bevor irgendetwas gefragt wird.

---

#### Messung 1 — wie oft wiederholt sich der Schlüssel?

Echtes Neovim über RPC, `updatetime = 200` (was `lua/options.lua` setzt),
hover auf Defaults, eine Sonde als Position-Beitrag, die immer `nil`
zurückgibt und nur zählt. **Ein Ask pro Tastendruck-und-Ruhe, ausnahmslos** —
`+asks` war bei allen 16 Gesten genau 1, ob der Cursor sich bewegt hat oder
nicht.

| | Gesten |
| --- | --- |
| **wiederholen den Schlüssel** | `<Esc>`, `<Esc>` nochmal, `zz`, `:` + `<Esc>`, `0h` in Spalte 0, `j` in der letzten Zeile, `<C-e>` |
| **wiederholen einen *früher* gesehenen** | `h` nach `l`, `b` nach `w` — ein Memo der Größe 1 verpasst die, ein LRU nicht |
| **neuer Schlüssel** | `j`, `l`, `G`, `w`, `x`, `u` (`changedtick` springt korrekt) |

`asks=16 distinct=7 repeats=9 (56,2 %) consecutive=7 same_row=11`

**Die 56 % sind nicht die Sitzungshäufigkeit** — der Gestenmix ist meiner, nicht
der eines Menschen. Was der Lauf hart zeigt: die Wiederholung ist real und
völlig ungebremst, und *welche* Gesten sie erzeugen.

Der Nebenbefund `same_row = 11` gegen `repeats = 9`: ein rein zeilenweiser
Schlüssel träfe öfter — und wäre **falsch**, weil drei der vier ausgelieferten
Beiträge spaltenabhängig sind (documentation: der dotted Modulname unter dem
Cursor, spotlight: das Token, sandbox: der Image-Name). Die Spalte im
Schlüssel ist richtig.

---

#### Messung 2 — was kostet ein Ask? Und damit war die Häufigkeit egal

1202-Zeilen-Lua-Buffer, 1396 abgetastete Positionen, die drei echten
Position-Beiträge dieser Maschine, alle ablehnend (die Ablehnung *ist* die
Population, gleiche Begründung wie bei gopath):

| registriert | pro Ask |
| --- | --- |
| nichts | 0,0 µs |
| spotlight.nvim | 1,0 µs |
| migrate.nvim | 2,4 µs |
| **documentation.nvim** | **24,2 µs** |
| alle drei | **26,3 µs** |

Bei `updatetime = 200` sind das höchstens fünf Asks pro Sekunde: **~132 µs/s,
also 0,013 % eines Kerns.** Zum Vergleich der Maßstab, der in diesem Repo
gilt: ein fehlschlagendes `gopath.resolve_at_cursor` kostet 13,2 ms — das
**500-fache der gesamten Pipeline**. Ein Memo spart hiervon bestenfalls die
Hälfte und handelt sich dafür genau die Fehlerfläche ein, die 2.5 selbst
benennt: ein veralteter Eintrag wäre eine *falsche* Antwort, keine alte.

**Ein methodischer Fehler, der fast durchgegangen wäre.** Der erste Durchlauf
tastete Spalte 0 ab und ergab 3,7 µs — schmeichelhaft um den Faktor 7, und aus
einem Grund, der mit der Pipeline nichts zu tun hat: Spalte 0 einer Lua-Datei
ist Einrückung, `token_at` und `dotted_at` lehnen auf Whitespace sofort ab, und
`find_map` wird nie erreicht. Gemessen wird jetzt zwei Zeichen im ersten Wort
und zusätzlich in jedem dotted Namen — dort, wo ein Cursor tatsächlich steht.

---

#### Was dabei herausfiel: ein Auftrag für documentation.nvim

**92 % der Kosten der gesamten Position-Pipeline liegen in einem Beitrag**, und
zwar an einer Stelle, die ihn nichts kosten müsste. `find_map(start)` in
`documentation/lua/documentation/hover.lua:54` läuft bis zu **24
Verzeichnisebenen** mit je einem `uv.fs_stat` nach `docs/map/module_map.json`
— **ohne negativen Cache**. `_maps[path]` (Zeile 112) merkt sich nur
*erfolgreiche* Ladungen. In jedem Projekt ohne generierte Map — hover.nvim
selbst ist eines — zahlt damit jeder einzelne Ask den vollen Aufstieg.

Gleiche Form wie der gopath-Befund: **die Kosten sitzen im Beitrag, und die
Reparatur gehört dorthin.** Ein negativer Cache pro Startverzeichnis, und die
Pipeline liegt bei ~2 µs. Steht als Auftrag in `hover.nvim-roadmap.md`
Abschnitt 4.

---

#### Wo die Messwerkzeuge liegen

`nvim/scripts/hover-position-probe/` — nach dem Vorbild von
`scripts/luals-scan/` im Config-Repo, weil eine Messsonde kein Plugin-Feature
ist:

| Datei | wofür |
| --- | --- |
| `position_probe.lua` | der Zähl-Beitrag; `install()`, `line()`, `report()` |
| `init.lua` + `drive.py` | die skriptgesteuerte Sitzung über RPC (Client braucht `--headless`, sonst kommen Terminal-Escapes statt des Ergebnisses zurück) |
| `cost.lua`, `cost2.lua` | die Kostenmessung, gesamt und je Beitrag |
| `cost.txt`, `cost2.txt` | die Ausgaben oben |

**Was offen bleibt und keinen Blocker darstellt:** die echte
Sitzungshäufigkeit. Die Sonde läuft in einer echten Sitzung mit
`require("position_probe").install()` und berichtet mit `.report()`. Für die
Entscheidung zu 2.5 wird sie nicht mehr gebraucht — bei 26 µs pro Ask ändert
keine Häufigkeit das Ergebnis.

---

### J. Die `on_request`-Messung — gelaufen, und sie hat drei Dinge gefunden (`b7c4c45`, `e62f5e9`)

Die letzte der drei offenen Messungen aus Abschnitt 3, die **nicht** dich
braucht. Sie war am 2026-09-02 schon einmal gelaufen, aber ad hoc und nur ins
Handover geschrieben; im Repo kannte `docs/MANUAL-EVIDENCE.md` den Pfad gar
nicht. Jetzt ist sie ein Skript, und die Zeile steht dort, wo sie hingehört.

**Was gebaut ist:** `hover.nvim/scripts/onrequest_probe.lua`. Vier Referenzen
in einem Buffer, jede zweimal gefragt — einmal auf dem automatischen Trigger,
einmal erzwungen —, und der Float wird **zurückgelesen** statt dem Rückgabewert
geglaubt. Genau in dieser Lücke saß `836a15a`. Abhängigkeiten wie in
`scripts/minimal_init.lua`: Env-Var, `.deps/<name>`, oder Nachbarverzeichnis.

```bash
LIB_NVIM_DIR=E:/repos/lib.nvim SANDBOX_NVIM_DIR=E:/repos/sandbox.nvim \
  nvim --clean --headless -l scripts/onrequest_probe.lua docker
```

**Gemessen am 2026-09-02 gegen Docker Engine 29.5.3**, Tastendruck bis
fertiger Float:

| Referenz | Antwort | erzwungen | Engine-Aufrufe |
| --- | --- | --- | --- |
| `alpine:edge` | geholt, kein Container | 566 ms | 2 |
| `lazyvim_starter:latest` | geholt, 1 Container | 558 ms | 2 |
| `nginx:1.27-alpine` | nicht geholt | 294 ms | 1 |
| `init.lua:42` | abgelehnt | 0 ms | 0 |

Alle vier blieben auf dem automatischen Trigger still. Das reproduziert die
Erstmessung (754/560/286/1 ms) in Form und Größenordnung; die Streuung nach
unten ist ein warmer Docker-Daemon, kein anderer Pfad.

---

#### Fund 1: die Engine-Erkennung wählt hier `podman`, und der antwortet nicht

**Ohne Argument** benutzt die Sonde sandbox.nvims eigene Erkennung — und die
wählt auf dieser Maschine `podman`. `podman.exe` liegt auf dem PATH (Podman
Desktop), aber die Linux-VM läuft nicht:

```
Cannot connect to Podman ... try `podman machine init` and `podman machine start`
```

`sandbox.engine_utils.get_engine()` fragt nur `has_exec("podman")` und nimmt
den ersten Treffer in der Reihenfolge podman → docker → nerdctl. **Ob die
Engine antworten kann, wird nie gefragt.** Ergebnis in deiner echten Config:
jede Zeile lehnt nach ~370 ms ab, still, während eine funktionierende
Docker-Engine mit vier Images danebensteht.

Das ist dieselbe Form wie `836a15a` — registriert, in allen Specs grün, auf der
Maschine stumm — nur liegt die Ursache diesmal in sandbox.nvim. Der Auftrag
steht in [Abschnitt 4 der Roadmap](./hover.nvim-roadmap.md#4-auftrge-die-woanders-liegen).
In hover.nvims Doku steht davon nur der Satz, den ein Leser braucht: *prüf,
welche Engine gewählt wurde, bevor du den Hover verdächtigst.*

**Sofort-Abhilfe, falls es stört:** `:Sandbox engine set docker` setzt
`vim.g.sandbox_engine` für die Sitzung; dauerhaft `opts.engine = "docker"` in
der lazy-Spec von sandbox.nvim.

---

#### Fund 2: `MANUAL-EVIDENCE.md` hatte vier Zeilen und sagte dreimal „drei"

Beim Eintragen aufgefallen: `204d083` hatte die Zoom-Zeile ergänzt, aber
`README.md` sagte weiter „the three things no CI can check", und die
Evidenzdatei selbst zweimal „three". Vierte Wiederholung derselben Klasse, die
`docs_spec.lua` überhaupt erst gebaut hat — **in dem einen Dokument, das
außerhalb seiner Reichweite lag**.

Deshalb prüft der Spec die Datei jetzt gegen ihre **eigenen zwei Regeln**:

1. Jede Zeile trägt die Felder, die `## How to read a row` für eine Zeile
   nennt. Die Feldnamen werden aus dieser Legende *gelesen*, nicht im Spec
   wiederholt — eine zweite Kopie der Definition wäre genau der Fehler, gegen
   den die Datei geschrieben ist.
2. Jede ausgeschriebene Zahl dieser Zeilen, in jedem Dokument, stimmt mit der
   Anzahl überein. Zwei Formulierungen an zwei Stellen: „one of the five paths
   above" und „the five things no CI can check".

Beide sabotage-getestet (Hausregel): „four paths" statt „five" lässt Prüfung 2
fallen, ein entferntes `**Checked**` lässt Prüfung 1 fallen. `claimed_switch_counts`
heißt jetzt `claimed_counts(text, noun)` — derselbe Fenster-Suchlauf, zweiter
Aufrufer.

Es sind jetzt **fünf** Zeilen: gezeichnetes Bild, gezoomtes Bild, PDF-Seite,
Office-Dokument, `on_request`-Beitrag. Der Rahmensatz der Datei ist mitgezogen:
sie deckt nicht mehr nur ab, was ein Terminal zum Zeichnen braucht, sondern
auch, was einen **Daemon zum Antworten** braucht.

---

#### Fund 3: die LuaLS-Messung flackert

Der Pass nach dem Commit (`post-e`) meldete **1 Befund** — `cast-local-type` in
`TESTS/switches_spec.lua:492`, einer Datei, die der Commit nicht anfasst und
die seit `3e12c9f` unverändert ist, also vor den drei Nullpässen `post-b`,
`post-c`, `post-d`. Zweiter Lauf auf identischem Baum (`post-e2`): **0**.

Also **nicht deterministisch**: derselbe Quelltext, einmal in fünf Läufen ein
Befund. Das ist schlimmer als ein stehender Befund, weil dieser Scan als
Regressionssignal gelesen wird und ein `+1` die nächste Sitzung auf die Suche
nach einer Änderung schickt, die es nicht gab.

Festgenagelt mit `---@type any` auf dem Abstieg durch die Defaults (`e62f5e9`)
— der Abstieg beginnt bei `Hover.Config` und führt hinaus, und genau das ist,
was die Regel meint; nur kam die Inferenz nur manchmal dort an. Danach
`post-f`: **0 Befunde**.

**Für die nächste Lesung wichtig:** die Regel „0 Befunde, Delta +0" ist ab
jetzt mit einem Vorbehalt zu lesen. Ein einzelner `+1` ist kein Beweis; ein
zweiter Lauf auf demselben Baum kostet eine Minute und entscheidet.

---

**Verifikation:** Suite 8 Dateien / 0 Fehler, `stylua --check` sauber,
`luacheck` 0/0 über 32 Dateien, LuaLS `post-f` 0 Befunde auf dem
Haupt-Checkout. Sonde in beiden Modi gelaufen.

---

## Was beim Weiterarbeiten zu wissen ist

- **Regelwerk:** `WKDBooks/Development/wkdbook-Lua/Checklists/`, für dieses
  Repo `gates/NEW_PROJECT.md` (einmal durch, `NEW-01`…`NEW-46`),
  `regeln/LUA_NVIM.md` beim Schreiben. **`gates/RELEASE.md` und
  `gates/REVIEW.md` sind beide durch** — 29/32 bzw. grün.
- **Commits ohne KI-Co-Author** — steht so in `NEW_PROJECT.md` und ist hier so
  gehalten.
- **Keine Lizenzdatei** (`NEW-06`, `REL-28`) — bewusst keine angelegt, auch
  wenn pdfport/gopath welche haben.
- **stylua-Stil:** `collapse_simple_statement = "Never"`, wie lib.nvim. Nicht
  wie markdown.nvim (`"Always"`) — der übernommene Code ist in lib.nvims Stil
  geschrieben, und eine Extraktion ist der falsche Moment, den ganzen
  Quelltext umzuformatieren.
- **LuaLS messen:** `REPOS_DIR=E:/repos bash scripts/luals-scan/scan.sh <pass>
  hover.nvim`, dann `python scripts/luals-scan/compare.py <pass>`. Die nackte
  `lua-language-server --check`-Zahl ist wertlos (`LLS-01`).
- **Der Scan sieht `TESTS/` mit, und das ist nicht theoretisch.** Am
  2026-09-02 kam `zoom-post` mit **+2** zurück, beide Befunde im neuen
  `docs_spec.lua`: ein `local`, das mit `Hover.Config` typisiert war und beim
  ersten Pfadschritt aufhörte es zu sein, und ein `vim.islist` auf einem Wert
  aus `pairs(DEFAULTS)`, der auch ein String sein kann. Die Suite war grün,
  stylua sauber, CI grün — **nur der Scan hat es gesehen** (behoben in
  `65ba8dd`). Ein Spec ist Code, und nach dem Schreiben eines gehört ein Lauf
  dazu, nicht nur nach einer Änderung an `lua/`.
- **Tests:** `LIB_NVIM_DIR=E:/repos/lib.nvim
  PLENARY_DIR=C:/Users/bartl/AppData/Local/nvim-data/lazy/plenary.nvim
  bash scripts/test.sh`
- **Git-Bash-Falle:** headless nvim mit einem `/tmp/...`-Pfad **hängt still**,
  statt zu scheitern. Windows-Pfade verwenden. (Steht auch in
  `scripts/luals-scan/scan.sh`.)
- **luals-scan liegt in der Config**, nicht im Plugin-Repo:
  `nvim/scripts/luals-scan/`. Und: **nicht den Worktree scannen** — die
  injizierte Library kommt vom Haupt-Checkout, dieselben `Hover.*`-Klassen
  also zweimal, Ergebnis ~100 unechte `duplicate-doc-field`. Erst den
  Haupt-Checkout nachziehen, dann den scannen.
- **Ein voller Config-Start headless hängt still.** Auch mit Windows-Pfaden.
  Isoliert prüfen (`-u NONE` plus `set rtp+=`) oder interaktiv.
- **Vor dem Bauen messen.** Drei Messungen in diesem Repo haben der Intuition
  widersprochen, die sie prüfen sollten; zweimal war die naheliegende Lösung
  die falsche. Die Zahlen stehen in den Modulköpfen von `hover.scope` und
  `hover.bare_path`, nicht in Commit-Messages, damit sie beim Ändern des
  Codes gelesen werden.

---

