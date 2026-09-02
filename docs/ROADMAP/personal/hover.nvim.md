# hover.nvim — Extraktion aus lib.nvim

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
2026-09-02](#aufträge-aus-der-sitzung-vom-2026-09-02) — sechs Punkte, jeder
schon nachgesehen, damit dort der Befund steht und nicht nur die Frage. Der
größte davon ist eine **Beitrags-API für Nutzer** (D): die gibt es technisch
längst, sie ist nur nirgends als solche angeboten.

---

## Was wir getan haben, und warum

### Die Ausgangsfrage

Zwei Todo-Punkte: „Mittlerweile poppt oft ein Hover auf → checken, was opt-in
sein sollte" und „Zahlt sich ein eigenes Repo mittlerweile aus?"

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

### 1. Das Opt-in-Modell

Zwei Achsen statt „Zieltyp": **wie explizit war das Ziel** (Link-Syntax = der
Autor behauptet etwas; Bare Path = wir raten) und **wie viel sagt die Vorschau,
was nicht schon dasteht** (ein Dateikopf steht nicht im Linktext; Host und
Pfad einer URL schon). Kosten als Stichentscheid. Das Modell **leitet jeden
bestehenden Default korrekt her** und zeigt genau die zwei, die falsch waren.

### 2. `mode`: auto | manual | off

`manual` behält jede Preview und gibt nur den automatischen Auslöser auf. Das
ist die Antwort auf „ich lese gerade ein Dokument aus Links", ohne Klasse für
Klasse entscheiden zu müssen. `:Hover show`, `keymaps.show` und
`show({ force = true })` antworten dann weiterhin **voll**, Web-Links
inklusive.

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

### 4. Die verschärfte Bare-Path-Regel

Eine Endung muss auf der **letzten** Komponente sitzen, und das `./`-Präfix
zählt nicht mehr für sich allein. Das kostet echte True Positives (`~/notes`,
`/etc/hosts`, `lua/lib/nvim` wenn sie nicht existieren) — mit Absicht: es ist
die einzige Preview-Klasse, deren Wert *negativ* wird, wenn sie falsch liegt.

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
| **hover.nvim** (neu) | gepusht, `main` | Extraktion, dann ~25 weitere bis `5bc630f` |
| **markdown.nvim** | gepusht, `main` | `bd53428`, `634121f`, `c61493f` |
| **nvim-config** | gepusht, `main` | `97051225`, `69907c0e`, `af1a8c60`, `7a0027b4`, `4e2cf2c4` |
| **lib.nvim** | gepusht, `main` | `5450dd4` (Hover gelöscht), `556ee50` (safe_api-Typen) |
| **images.nvim** | gepusht, `main` | `b61b347` — stale Verweise auf `markdown.hover` |
| **pdfport.nvim** | gepusht, `main` | `b43fd1c` — dito, plus `docs/install.json` |
| **migrate.nvim** | gepusht, `main` | `efb1ae4` — Position-Preview |
| **reposcope.nvim** | gepusht, `main` | `b4d6eff` — `owner/repo`-Source |
| **documentation.nvim** | gepusht, `main` | `b23ab85` — Modul-Preview |
| **spotlight.nvim** | gepusht, `main` | `23f3f25` — Token-Zähler |

### markdown.nvim

Reines Require-Pfad-Rename plus Typnamen. `Mkdn.HoverUrlConfig` zeigt jetzt
auf `Hover.LegacyUrlConfig`, nicht auf `Hover.LinksConfig` — bewusst, weil
markdown.nvim weiterhin `url = { hover, fetch }` übergibt und hover.nvim das
normalisiert. Ein Verhaltens-Pin musste mit: `HoverMissing` statt
`LibHoverMissing`. Volle Suite grün (27 Specs).

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
| Specs hover.nvim | **177 grün**, 0 Fehler (bare_git 10, bare_path 48, config 17, registry 49, scope 26, switches 27) |
| Specs der Nachbarn | migrate, reposcope, documentation, spotlight — alle vier grün |
| `stylua --check` / `luacheck` | sauber in jedem berührten Repo |
| LuaLS (`scan.sh`, echte injizierte Library) | **0 Befunde** |
| CI | grün auf **ubuntu-latest und windows-latest** (Run `33604859057`) |
| Helptags | 29 Tags |
| Doku-Beispiele | 23 ```lua-Blöcke laden, die ausführbaren laufen; 32 dokumentierte `:Hover`-Routen sind alle echt |

---

## Was seit der Extraktion passiert ist

Grob chronologisch. Was in `hover.nvim/docs/ROADMAP.md` gelöscht wurde, ist
gebaut — die Datei führt keine erledigten Punkte.

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

### 1. Demo-GIF — **braucht dich**

`REL-09`, der letzte offene Punkt des Release-Gates und der einzige, den ich
nicht erledigen kann: ich kann keine Bildschirmaufnahme machen. Die README
trägt ein ASCII-Modell des Floats, das die Idee erklärt, aber nicht das
Gefühl — und zu zeigen wäre gerade, wie wenig es beim Lesen stört.

### 2. language.nvim — der zweite Kandidat für `on_request`

`on_request` ist gebaut und mit sandbox.nvim einmal durch die volle Strecke
gefahren. Der zweite Wartende ist **language.nvim** (Wort-Nachschlag), und der
ist nicht dasselbe: bei sandbox entscheidet eine billige Textprüfung *vor*
jedem Prozessstart, ob überhaupt etwas gefragt wird — `init.lua:42` wird in
1 ms abgelehnt. Bei einem Wort-Nachschlag ist **jedes Wort ein Wort**; es gibt
keine solche Vorprüfung, also ist auch unter `force` jede Position ein Treffer.

Das ist eher eine Produktfrage als eine technische: soll ein Druck auf
`:Hover show` mitten in Prosa immer ein Wörterbuch aufmachen? Wenn ja, ist die
Integration klein. Wenn nein, braucht es vorher eine Regel dafür, wann ein Wort
nachschlagenswert ist — und die gehört nach language.nvim, nicht hierher.

### 3. insights.nvim braucht erst einen Index

Nicht hier zu lösen. `run_reverse` läuft `scan_cwd_async` — einen vollen
Durchlauf des Arbeitsverzeichnisses — und öffnet einen Scratch-Buffer. Jede
Abfrage scannt neu, es gibt nichts nachzuschlagen. Der Cache-Index gehört in
insights.nvim, und danach ist die Integration klein.

### 4. Beobachten, ob `manual` der bessere Default ist

Die Config läuft auf `auto`. Wenn es weiter nervt, ist der Griff
`:Hover mode manual` plus ein `keymaps.show`-Key — und wenn *das* sich als das
Richtige erweist, gehört es in die Spec statt in eine Sitzung.

Inzwischen gibt es zwei Werkzeuge, die diese Frage schärfer stellen als vorher:
`:Hover why` sagt, warum ein Float *nicht* aufging, und das Positions-Gate hat
die Hälfte des Rauschens ohnehin entfernt. Die Frage könnte sich erledigt
haben.

### 5. Was keine CI prüft

`docs/MANUAL-EVIDENCE.md` führt es: gezeichnete Bilder, rasterisierte
PDF-Seiten, konvertierte Office-Dokumente. Der Office-Pfad ist seit der
Cache-Änderung (`bba2064`, überlebt jetzt die Sitzung) **nicht** mehr von Hand
geprüft, und was daran zu bestätigen wäre, steht dort.

Dazu kommt jetzt der **`on_request`-Pfad**: eine CI hat keinen laufenden
Container-Daemon, also kann keine Maschine bestätigen, dass ein
nachfrage-only-Beitrag am Ende wirklich eine Antwort auf den Schirm bringt.
Genau da saß der Fehler aus `836a15a`. Gemessen am **2026-09-02** gegen eine
laufende Docker-Engine, Tastendruck bis fertiger Float:

| Referenz | Antwort | Dauer | Engine-Aufrufe |
| --- | --- | --- | --- |
| `alpine:edge` | geholt, kein Container | 754 ms | 2 |
| `lazyvim_starter:latest` | geholt, 1 Container | 560 ms | 2 |
| `nginx:1.27-alpine` | nicht geholt | 286 ms | 1 |
| `init.lua:42` | abgelehnt | 1 ms | 0 |

Alle vier antworteten auf dem automatischen Trigger mit `false`. Die 286 ms
sind der Beleg für den zweiten Engine-Aufruf, der nur bei Treffer passiert;
die 1 ms dafür, dass die Namenskollision abgelehnt wird, **bevor** ein Prozess
startet. Vorher lief dieselbe Strecke gegen einen gestoppten Daemon und
erzeugte korrekt Schweigen statt eines selbstbewussten „not pulled“ — der
Fall, den ein Stub nicht so gut prüft wie die kaputte Wirklichkeit.


---

## Aufträge aus der Sitzung vom 2026-09-02

Sechs Punkte, alle noch offen. Was hier steht, ist jeweils schon **nachgesehen**
— die Notiz sagt den Befund, nicht nur die Frage.

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

### B. Die Docs der eingebundenen Plugins durchgehen

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

### D. Eine Beitrags-API für Nutzer — Nutzen/Aufwand

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

### E. Eine Roadmap-Datei unter `docs/ROADMAP/personal/`

Eine Analyse zu Optimierung und neuen Features, geschrieben als eigene Datei
neben dieser hier. **Nicht zu verwechseln** mit `hover.nvim/docs/ROADMAP.md`
— die liegt im Repo, ist an Mitlesende adressiert und führt bewusst keine
erledigten Punkte. Die Datei hier ist die persönliche, längere Fassung.

Abzugrenzen ist beim Schreiben, was in welche der beiden gehört, sonst driften
sie auseinander.

### F. Zoom im Float — Machbarkeit geprüft, die Antwort ist zweigeteilt

Die Idee: mit der Maus in den Hover, Mausrad bzw. `<C-ScrollWheel>` zoomt.

**Für Text geht es nicht, und zwar grundsätzlich.** Die Schriftgröße gehört
dem Terminal-Emulator; Neovim kann sie nicht ändern. „Zoom" könnte für Text
nur heißen: das Float größer machen — das zeigt *mehr*, aber nichts
*größer*. Das ist ein anderes Feature und sollte auch anders heißen.

**Für Bilder geht es wirklich.** Ein Bild wird über images.nvim in eine
Zellfläche gezeichnet; dieselbe Fläche größer angefordert heißt echte
Vergrößerung. Dasselbe gilt für eine rasterisierte PDF-Seite über pdfport.
Das ist der Fall, in dem „Zoom" das Wort trifft.

Zwei technische Voraussetzungen, beide geprüft:

- **Das Float ist `focusable = opts.focusable == true`**, also standardmäßig
  *nicht* fokussierbar (`float.lua:293`). Die Maus kann so nicht hineinklicken.
  Man bräuchte entweder `focusable`, oder — sauberer — `getmousepos()` in
  einer globalen `<ScrollWheelUp>`-Map, um zu erkennen, dass der Zeiger über
  dem Hover steht, ohne den Fokus anzufassen.
- **Ein Scroll-Mechanismus existiert schon** (`bindings/keymaps.lua`):
  `scroll_keys` werden nur installiert, solange ein Float offen ist *und* es
  etwas zu scrollen gibt, und werden beim Schließen wieder eingesammelt.
  Zoom sollte an derselben Stelle andocken statt einen zweiten Weg aufzumachen
  — dieselbe Aufräum-Disziplin ist der Grund, warum die Keymaps dort so
  vorsichtig geschrieben sind.

`mouse` muss beim Nutzer gesetzt sein (`set mouse=a`), sonst kommt gar kein
Rad-Event an. Das ist ein Fall für `:Hover why`.

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
