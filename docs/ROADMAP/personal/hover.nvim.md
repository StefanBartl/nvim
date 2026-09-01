# hover.nvim — Extraktion aus lib.nvim

Handover-Dokument. Stand: **2026-09-01**, Session „lib.nvim hover analysis".

Repo: <https://github.com/StefanBartl/hover.nvim> · lokal `E:/repos/hover.nvim`
Branch: **`main`** — kein Feature-Branch, alles ist gepusht.

---

## Kurzfassung: wo wir stehen

**Phase 1 ist fertig und live.** Das Plugin existiert, ist öffentlich, ist in
die Config eingebunden, markdown.nvim hängt daran, und ein echter Start von
Neovim mit deiner Config liefert einen funktionierenden Hover. Nichts ist
halbfertig liegen geblieben.

**Phase 2 ist noch offen:** `lua/lib/nvim/hover/` liegt *noch in lib.nvim*.
Es wird von niemandem mehr aufgerufen, tut also nichts — aber es ist eine tote
Kopie und gehört gelöscht. Das ist der eine Punkt, an dem hier weitergearbeitet
wird. Details unter [Offene Punkte](#offene-punkte).

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
Einspruch bleibt gültig und ist im README dokumentiert, damit er nicht
vergessen wird:

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

### 3. Sieben Schalter aus **einer** Tabelle

`lua/hover/switches.lua` speist Routen, Completion, `:Hover status` und
`:checkhealth` gleichzeitig. Ein achter Schalter ist ein Tabelleneintrag und
sonst nichts.

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
  Bug steckt **weiterhin in lib.nvims Kopie**, solange die existiert — git und
  stylua behandeln die Datei deshalb als binär.

---

## Was wo geändert wurde

| Repo | Stand | Commit |
| --- | --- | --- |
| **hover.nvim** (neu) | gepusht, `main` | `feat: hover.nvim -- the path/link preview, extracted from lib.nvim` |
| **markdown.nvim** | gepusht, `main` | `bd53428` + `634121f` |
| **nvim-config** | siehe unten | noch zu committen |
| **lib.nvim** | **unberührt** | — |

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
| Specs hover.nvim | **78 grün**, 0 Fehler (bare_path 32, config 15, registry 19, switches 12) |
| Specs markdown.nvim | volle Suite grün, `MARKDOWN_TESTS_OK` |
| `stylua --check` | sauber, beide Repos |
| `luacheck` | 0 warnings / 0 errors in 27 Dateien |
| LuaLS (`scan.sh`, echte injizierte Library) | **0 Befunde**, zweimal gemessen (`LLS-07`) |
| Helptags | 29 Tags aus `doc/hover.txt` |
| Live-Start mit deiner Config | `:Hover` da, mode `auto`, alle Schalter korrekt, rtp → `E:\repos\hover.nvim` |
| Live-Funktionstest | markdown-Source registriert, Bare Path aufgelöst, Link mit `kind=mdlink` gefunden, **Float öffnet** |

Die erste LuaLS-Rohmessung zeigte 121 Befunde — davon 114 `undefined-field`,
also der klassische `LLS-01`-Messfehler (CLI ohne injizierte Library). Mit
`scripts/luals-scan/scan.sh` waren es 7 echte, die alle behoben wurden.

---

## Offene Punkte

### 1. `lua/lib/nvim/hover/` aus lib.nvim löschen  — **der nächste Schritt**

Steht noch da, wird von nichts mehr aufgerufen. Zu tun:

- [ ] `lua/lib/nvim/hover/` löschen (18 Dateien, ~3 950 LOC)
- [ ] `lua/lib/nvim_usrcmds/usrcmds.lua:77` — den `hover.routes()`-Block raus
- [ ] `lua/lib/nvim_usrcmds/init.lua:27` — `hover = true` raus, und das Feld
      aus `@types/init.lua:10`
- [ ] `TESTS/hover_*_spec.lua` (6 Dateien) löschen
- [ ] `README.md` — die drei `:Lib hover`-Zeilen aus der Kommandotabelle
- [ ] `docs/modules.md` — den Hover-Eintrag
- [ ] `lib.nvim.image_preview` **bleibt** — das ist der echte generische
      Helper und die „thin caller"-Rolle, die `wrap_lib()` bei telemetry hatte
- [ ] danach in der Config `hover = false` wieder rausnehmen (der Key
      existiert dann nicht mehr)

Erst danach ist der NUL-Byte-Bug in `preview/media.lua` wirklich weg.

### 2. Bare Paths auf Kommentare/Strings scopen

Die verbleibende Hälfte des Rauschproblems. Konzept steht in
`hover.nvim/docs/ROADMAP.md` samt den zwei Dingen, die vorher zu klären sind
(fail-open, und die Kosten pro `CursorHold` messen statt annehmen).

### 3. Beobachten, ob `manual` der bessere Default ist

Die Config läuft heute auf `auto`. Wenn es weiter nervt, ist der Griff
`:Hover mode manual` plus ein `keymaps.show`-Key — und wenn *das* sich als das
Richtige erweist, gehört es in die Spec statt in eine Sitzung.

### 4. `REL-19`: auf POSIX prüfen

Alles hier ist auf Windows gelaufen. Der Code ist cross-plattform geschrieben
(vom Vorgänger übernommen), aber CI ist der erste POSIX-Lauf — nach dem ersten
Push mal reinschauen.

---

## Was beim Weiterarbeiten zu wissen ist

- **Regelwerk:** `WKDBooks/Development/wkdbook-Lua/Checklists/`, für dieses
  Repo `gates/NEW_PROJECT.md` (einmal durch, `NEW-01`…`NEW-46`),
  `regeln/LUA_NVIM.md` beim Schreiben. `gates/RELEASE.md` steht noch aus.
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
