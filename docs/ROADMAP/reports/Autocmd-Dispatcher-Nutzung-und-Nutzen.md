# `lib.nvim`-Autocmd-Dispatcher — wo er benutzt wird und wo er sich lohnen würde

**Datum der Analyse:** 2026-09-21 · **Letzte Aktualisierung (Umsetzung):** 2026-09-21
**Frage:** Der Dispatcher (`lib.nvim.bindings.autocmd.dispatcher`) ist gebaut und hat
einen produktiven Nutzer. Lohnt sich ein breiterer Einsatz in den anderen Plugins —
und wenn ja, wo, und was würde er dort konkret bringen?

> **Diese Datei ist zugleich die Übergabedatei (Handover).** Wer die Arbeit
> fortsetzt, liest zuerst den Abschnitt „Handover — Stand der Arbeitsliste“ direkt
> darunter und danach §9 (Umsetzungsprotokoll). Die Analyse (§0–§8) bleibt als
> Begründung stehen; wo die Umsetzung sie korrigiert hat, steht das in §9.1.

---

## Handover — Stand der Arbeitsliste

Die Liste besteht aus den Plugins, für die die Analyse (§5) mindestens „maybe“
ergeben hat, plus dem einen offenen Prüfpunkt aus §7. Reihenfolge = Nutzen.

| # | Plugin | Verdikt der Analyse | Ergebnis der Umsetzung | Commits |
|---|---|---|---|---|
| 1 | `mdview.nvim` | **yes** | **Erledigt.** Zwei Commits: (a) `autocmds_registry` abgeschafft, (b) die drei `BufEnter`-Handler hinter einem gemeinsamen Dispatcher (`enter_hub.lua`). Suite 263 → 276 grün. | `2baebfb`, `75ec57e` |
| 2 | `markdown.nvim` | **maybe** | **Migration bewusst nicht gemacht** (Begründung §9.3), stattdessen beim Lesen einen **echten Bug** gefunden und behoben: das Öffnen des TableView-Popups löschte den `FileType`-Autocmd von `setup()`. Regressions-Spec vorhanden. | `7a52855` |
| 3 | `lsp.nvim` (`LspAttach` ×4) | **unchecked** | **Gelesen → no.** Vier voneinander unabhängige Handler, kein gemeinsamer Key, keine Reihenfolge untereinander (§9.4). | — |

**Offen — braucht eine Entscheidung von Stefan** (nichts davon ist begonnen):

1. **Die fünf leeren `lsp.nvim`-Stubs löschen** (Plan in §8). Das kehrt eine
   dokumentierte Entscheidung um (`docs/autocmds.md` nennt sie „deliberate
   placeholders“) — deshalb nicht ohne Rückfrage.
2. **Konzept-Doc `lib.nvim/ROADMAP/autocmd-dispatcher.md` in den Ruhestand schicken**
   und den durchgestrichenen Eintrag in `ROADMAP.md` entfernen (§8).
3. **`my.nvim`: identischer Handler in `breadcrumbs` und `indent_scope`** auf drei
   Events zu einer Funktion zusammenlegen (§5) — ausdrücklich *kein* Dispatcher-Thema,
   nur Duplikat-Abbau.
4. **`markdown.nvim`-Migration doch noch machen?** Nur falls gewünscht; Aufwand und
   Gegenargumente in §9.3.

**Nicht verifiziert:** Die `mdview`-Änderungen sind durch die Headless-Suite
(276 Specs) abgedeckt, aber **nicht in einer echten Session** mit laufendem Relay und
Browser durchgespielt. Ein manueller Smoke-Test (`:MDView start`, zwischen
Markdown-Buffern wechseln unter `browser.behavior = "reuse"` und `"new_tab"`,
`:MDView stop`, erneut starten) steht aus.

---

## Inhaltsverzeichnis

  - [0. Verdikt](#0-verdikt)
  - [1. Methode, und was dieser Bericht nicht ist](#1-methode-und-was-dieser-bericht-nicht-ist)
  - [2. Was die Flotte heute registriert](#2-was-die-flotte-heute-registriert)
  - [3. Was der Dispatcher bringt — gemessen](#3-was-der-dispatcher-bringt--gemessen)
    - [3.1 Die Tabelle aus der README, reproduziert](#31-die-tabelle-aus-der-readme-reproduziert)
    - [3.2 N Handler, die *alle* treffen — spart Bündeln Lua-Eintritte?](#32-n-handler-die-alle-treffen--spart-bündeln-lua-eintritte)
    - [3.3 Mit `pattern` wird der Fehlschlag kostenlos](#33-mit-pattern-wird-der-fehlschlag-kostenlos)
  - [4. Einsatz heute](#4-einsatz-heute)
  - [5. Kandidat für Kandidat](#5-kandidat-für-kandidat)
  - [6. Empfehlungen](#6-empfehlungen)
  - [7. Was dieser Bericht nicht geprüft hat](#7-was-dieser-bericht-nicht-geprüft-hat)
  - [8. Verwandte Arbeiten nebenbei](#8-verwandte-arbeiten-nebenbei)
  - [9. Umsetzungsprotokoll](#9-umsetzungsprotokoll)
    - [9.1 Korrekturen an der Analyse](#91-korrekturen-an-der-analyse)
    - [9.2 `mdview.nvim`](#92-mdviewnvim)
    - [9.3 `markdown.nvim`](#93-markdownnvim)
    - [9.4 `lsp.nvim` und `LspAttach`](#94-lspnvim-und-lspattach)
    - [9.5 Prüfen und Reproduzieren](#95-prüfen-und-reproduzieren)

---

## 0. Verdikt

**Behalten, nicht ausrollen.** Der Dispatcher ist es wert, da zu sein, und er hat
einen Ort, an dem er sich klar bezahlt macht (`filetree.nvim`). In der übrigen Flotte
gibt es **einen** weiteren starken Kandidaten (`mdview.nvim`), einen schwachen bis
mäßigen (`markdown.nvim`), und alles andere hat entweder die falsche Form oder würde
nichts gewinnen.

Drei Dinge hat dieser Durchgang festgestellt:

1. **Es gibt kein Geschwindigkeitsargument — auch dort nicht, wo man es erwartet.**
   Ein Bündel Handler, die alle auf dasselbe Event treffen, kostet *nicht* das
   N-fache an Lua-Eintritt — die ~30–45 µs fallen einmal pro Event an, nicht einmal
   pro Handler (§3.2). Bündeln spart bei neun Handlern höchstens ~9 %. Der
   Dispatcher ist also ein Struktur-Werkzeug, nie ein Performance-Werkzeug. (Die
   README sagt das schon in einem Satz; dieser Durchgang hat es neu gemessen und es
   hält.)
2. **Seine eine echte Kostenstelle lässt sich abschalten, und die README sagte nicht
   wie.** `dispatcher.new({ pattern = … })` hält das Event in C gefiltert. Bei einem
   gemeinsamen Pattern kostet ein *Fehlschlag* 1,2 µs statt 44 µs (§3.3). Damit ist
   er für die beiden Kandidaten mit gemeinsamem Pattern nahezu kostenlos. Die README
   dokumentiert es jetzt (§8).
3. **Der Bedarf an einem Per-Buffer-`once` ist außerhalb von `filetree.nvim` nahe
   null.** Ein einziger handgeschriebener Per-Buffer-Guard in der ganzen Flotte (§2).

---

## 1. Methode, und was dieser Bericht nicht ist

Ein Skript ging durch `lua/` in jedem `*.nvim`-Repo unter `E:\repos` plus die
nvim-Config (ohne `.deps`, `.claude`, `TESTS`, `docs`, `spec`) und zog jeden Aufruf
`nvim_create_autocmd(...)` / `<x>.create(...)`, dessen erstes Argument ein echtes
Neovim-Event benennt (die Eventliste stammt aus `getcompletion('', 'event')`, 144
Namen). `.create(` wird nur in Dateien gezählt, die `lib.nvim.bindings.autocmd`
`require`n. Pro Treffer wurden Event(s), `pattern`, `once`, Datei und Zeile
festgehalten. Die Cluster habe ich danach von Hand gelesen.

Es ist eine **heuristische Zählung**, kein Parse:

- Wrapper, die die Eventliste dynamisch bauen, werden übersehen.
- Eine Registrierung mit mehreren Events zählt in der Pro-Event-Tabelle einmal pro
  Event.
- `ui.nvim/lua/ui/kit/*` und `lib.nvim/lua/lib/nvim/ui/kit/*` sind derselbe Code
  (ui.nvim trägt eine eingefrorene Kopie), jede Kit-Registrierung erscheint also
  doppelt.
- Sie sagt, wie *oft* etwas registriert wird, nicht ob die Registrierungen
  langlebig sind. Diese Unterscheidung trifft das Lesen in §5; wo ich eine Stelle
  nicht gelesen habe, steht das dabei.

Das ist kein Performance-Review eines Plugins, und der Bericht ändert keinen Code
(die Umsetzung steht getrennt in §9).

---

## 2. Was die Flotte heute registriert

|                                          |                                          |
|------------------------------------------|------------------------------------------|
| Gescannte Repos (38 Plugins + nvim-Config) |                  **39**                  |
|   Repos mit mindestens einer Registrierung |                  **35**                  |
|           Gefundene Registrierungen      | **300** (Kit-Kopie doppelt, siehe §1)    |
|  … über `lib.nvim.bindings.autocmd`      |                 **273**                  |
|          … über die rohe API             |                  **27**                  |
|           … mit `once = true`            |                  **26**                  |
|         `FileType`-Registrierungen       |   **45** (das Konzept-Doc zählte 17)     |

Häufigste Events: `FileType` 45, `TextChangedI` 27, `CursorMoved` 27, `TextChanged`
26, `BufWipeout` 23, `BufDelete` 20, `WinClosed` 19, `BufEnter` 19, `VimResized` 17,
`VimLeavePre` 15.

`FileType` nach Repo: `lsp.nvim` 14, `nvim-config` 7, `markdown.nvim` 5, `my.nvim` 4,
`cascade.nvim` 3, `color_my_ascii.nvim` 2, je eine in neun weiteren.

Handgebaute Mechanik, die der Dispatcher aufsaugen soll:

- **Spiegel-Registries:** `mdview.nvim` — `mdview.helper.autocmds_registry` wurde in
  **12 Dateien** referenziert. Genau diese „handgeschriebene Liste dessen, was
  registriert ist“ sollten die Records von `lib.nvim.bindings.autocmd` ablösen.
  **→ inzwischen abgeschafft, siehe §9.2.**
- **Per-Buffer-`once`-Guards** (`vim.b[..].…attached/applied/…`): **1** Stelle
  (`pickers.nvim`).

---

## 3. Was der Dispatcher bringt — gemessen

Drei Messungen, alle auf dieser Maschine (Windows 11, LuaJIT, `nvim --clean`), alle
mit dem synthetischen `User`-Event über `nvim_exec_autocmds`. Die absoluten
Mikrosekunden sind Richtwerte; die *Form* ist der Befund. Ein echtes `CursorMoved`
kommt aus C, nicht aus `nvim_exec_autocmds`, die feste Pro-Event-Kostenstelle kann
also abweichen.

---

### 3.1 Die Tabelle aus der README, reproduziert

`scripts/bench_dispatcher.lua` liefert dieselbe Form wie die README: Ein Fehlschlag
kostet pauschal ~50 µs gegen ~2 µs nativ (×28 bei einem Handler, ×2 bei fünfzig), und
Treffer sind unter ~20 Handlern ein Nullsummenspiel, darüber liegt der Dispatcher
vorn. Hier liest die Lua-Eintritts-Kontrolle 45 µs, die README 29 µs — langsamere,
verrauschtere Maschine, gleiche Geschichte.

---

### 3.2 N Handler, die *alle* treffen — spart Bündeln Lua-Eintritte?

Die naheliegende Vermutung: N native Autocmds treten je in Lua ein, der Dispatcher
einmal, also gewinnt er deutlich. Gemessen tut er das nicht. (Das ist derselbe Fall
wie die HIT-Spalte von `scripts/bench_dispatcher.lua`, bei der jedes native Autocmd
dasselbe Pattern trägt; ich habe ihn mit einem eigenen Skript neu hergeleitet, bevor
mir das auffiel. Beide stimmen überein.)

| N Handler | nativ (µs/Event) | Dispatcher (µs/Event) | Verhältnis |
|---:|---:|---:|---:|
| 1  | 43,9 | 45,1 | 1,03 |
| 2  | 45,3 | 44,4 | 0,98 |
| 4  | 47,6 | 44,6 | 0,94 |
| 9  | 49,0 | 44,5 | 0,91 |
| 20 | 55,4 | 47,7 | 0,86 |

Jeder *zusätzliche* native Callback kostet ~0,6 µs. Die 30–45 µs sind eine feste
Pro-Event-Kostenstelle, die egal wie die Handler verdrahtet sind einmal anfällt.
**„Ein Autocmd, viele Handler“ ist also kein Performance-Gewinn**, nicht einmal bei
neun ungefilterten Handlern auf `BufEnter` — es sind höchstens 9 %.

---

### 3.3 Mit `pattern` wird der Fehlschlag kostenlos

Die einzige echte Kostenstelle des Dispatchers ist der Fehlschlag: Er feuert bei
jedem Event und findet nichts. Aber `opts.pattern` wird unverändert an das
darunterliegende Autocmd durchgereicht (Default `"*"`) und kann damit in C
gefiltert werden wie bei einem nativen:

| | µs / Event |
|---|---:|
| kein Autocmd registriert, Fehlschlag | 0,4 |
| Dispatcher, `pattern = "*"`, Fehlschlag | 44,2 |
| Dispatcher, `pattern = "<der Key>"`, **Fehlschlag** | **1,2** |
| Dispatcher, `pattern = "<der Key>"`, Treffer | 42,8 |

Das gilt, sobald *alle* Handler eines Dispatchers ein Pattern teilen. Es war im Typ
deklariert (`Lib.Autocmd.Dispatcher.Opts.pattern`), aber die README erwähnte es nie,
sodass „Fehlschläge treten immer in Lua ein“ wie eine Unbedingtheit las, obwohl es nur
der Default ist. `scripts/bench_dispatcher.lua` hat jetzt eine `disp+pat`-Variante:
der Fehlschlag kostet bei 1 bis 50 Handlern 1,5–1,7 µs, Niveau nativ (nativ selbst
wächst bei 50 Handlern auf 26 µs).

**Netto der drei:** Geschwindigkeit ist mit gemeinsamem Pattern neutral bis leicht
positiv und ohne eines leicht negativ. Die Gründe, ihn zu benutzen, sind Reihenfolge,
eine Registry, einmal berechnete gemeinsame Arbeit und Auf-/Abbau per `owner` —
nie Geschwindigkeit.

---

## 4. Einsatz heute

Ein produktiver Nutzer: **`filetree.nvim`** (`util/bufevents.lua`,
`bindings/autocmds.lua`). Zehn Features teilen sich vier Events (`BufEnter`,
`WinEnter`, `BufWritePost`, `TextChanged`). Das ist die Form, für die der Dispatcher
gebaut wurde:

- Reihenfolge ist eine Zahl (`CWD 10` → `REVEAL 20` → `RENDER 30`) statt
  `pairs()`-Glück;
- `is_tree_buffer()` wird einmal in der Key-Funktion berechnet statt viermal;
- `owner` / `unregister` machen das idempotente `setup()` möglich, das ein
  einfaches Autocmd durch `augroup(clear = true)` gratis hatte;
- das generierte `bindings/autocmd/*.md` listet die Handler unter dem Dispatcher.

Phase 2 des Konzept-Docs (Migration des eigenen `FileType`-Registrys der nvim-Config)
ist so nie passiert: Die Config hat kein eigenes `FileType`-Dispatcher-Modul mehr.
Ihre sieben `FileType`-Registrierungen sind heute unabhängige Features auf
unabhängigen Filetypes.

**Seit 2026-09-21 zweiter Nutzer: `mdview.nvim`** (`bindings/autocmds/enter_hub.lua`,
§9.2).

---

## 5. Kandidat für Kandidat

Skala des Verdikts: **yes** (übernehmen), **maybe** (nur wenn die Datei ohnehin
angefasst wird), **no** (würde nichts gewinnen oder falsches Werkzeug). Die Spalte
„Stand“ ist nach der Umsetzung ergänzt.

| Kandidat | Was da ist | Passung zum Dispatcher | Verdikt | Stand |
|---|---|---|---|---|
| **`mdview.nvim`** `bindings/autocmds/` | 11 Dateien im Ordner, die meisten hängen ihr eigenes Autocmd an, 12 Dateien referenzierten die handgeschriebene `autocmds_registry`; vier `BufEnter`-Handler (`breadcrumbs`, `bufenter`, `buffer_switch`, `preview_tab_sync`), drei davon mit *demselben* `defaults.ft_pattern`; `teardown()` = `detach_all()` + `del_augroup` | Am stärksten. Die Spiegel-Registry ist das, was `dispatcher.registry()` und `owner` ersetzen. Ein gemeinsames `pattern = ft_pattern` hält den Fehlschlag in C (§3.3). Gemischte Events (`CursorMoved`, `CursorMovedI`, `BufWritePost`, `VimLeave`) heißen: nur eine *Teilmenge* der Handler, nicht alle elf | **yes** — etwa eine Sitzung | **erledigt** (§9.2) — mit Korrektur: die Registry fiel wegen der Augroup weg, nicht wegen des Dispatchers |
| **`markdown.nvim`** `bindings/autocmds.lua` | vier `FileType`-Registrierungen in einem `setup()`, alle `pattern = ftpat`, je hinter einem eigenen Feature-Gate, drei davon prüfen zuerst noch `is_md(ev.buf)` | Vier Autocmds werden zu einem, ein gemeinsamer `is_md`-Guard, bedingtes `register()` ist trivial. Der Gewinn ist klein: keine erkennbare Reihenfolge-Bedingung, jede Gruppe ist schon `clear = true` | **maybe** — halbe Sitzung, wenig Wert | **geprüft, Migration nicht gemacht; Bug gefunden und behoben** (§9.3) |
| **`my.nvim`** `hl_config/` | neun `BufEnter`, fünf `BufWinEnter`, vier `CursorMoved`, vier `WinScrolled`-Registrierungen über unabhängige Features | Schwach. Die Features sind unabhängig, entprellt und schalten sich durch Leeren der eigenen Augroup ab. `breadcrumbs` und `indent_scope` registrieren einen *identischen* Handler auf denselben drei Events, was für sich zusammengelegt werden sollte, aber das ist eine Funktion, kein Dispatcher. Kein gemeinsames Prädikat, keine Reihenfolge-Abhängigkeit gefunden. Die Registry-Sicht gibt es schon über die Autocmd-Records | **no** | unverändert |
| **`lsp.nvim`** `FileType` ×14 | fünf sind leere Stubs (`csharp`, `lua`, `c`, `go`, `zig`); der Rest setzt `shiftwidth` / `tabstop` / ein Keymap für **einen** Filetype je | Falsche Form. Ein Handler pro Key, verschiedene Keys, alle nativ pattern-gefiltert — der Mechanismus des Dispatchers (viele Handler pro Key) greift nie. Per-Filetype-Optionen setzt nativ und lazy `after/ftplugin/<ft>.lua` | **no** — stattdessen die Stubs löschen (§8) | Stubs: **offen** (Rückfrage, siehe Handover) |
| **`lsp.nvim`** `LspAttach` ×4 | `bindings/autocmds`, `core/inlay_hints`, `core/lightbulb`, `core/supervisor` | Unbekannt. `LspAttach`-Handler sind der klassische Ort, an dem die Reihenfolge zählt. Ich habe sie nicht gelesen | **ungeprüft** (§7) | **gelesen → no** (§9.4) |
| **`ui.nvim` / `lib.nvim`** Kit `TextChanged` ×6, `VimResized` ×6–8 | eine Registrierung pro Widget (`input`, `picker`, `preview`, `compare`, `toast`, …) | Scheint pro Widget zu sein, angelegt beim Öffnen und entfernt beim Schließen. Ein Dispatcher ist für langlebige Handler. (Nicht zeilenweise gelesen.) Außerdem doppelt gezählt, siehe §1 | **no** | unverändert |
| **`images.nvim`** `WinClosed` ×5 | alle `once = true`, eine pro fensterbezogenem Feature | Pro-Fenster-Einmalhandler sind genau das, wofür das native `once` da ist | **no** | unverändert |
| **`nvim-config`** `FileType` ×7 | `treesitter` ×3, `noice`, `commit_ft`, `markdown_folds`, `auto-center-fexplorer` | Unabhängige Features auf unabhängigen Filetypes, ein Handler pro Key | **no** | unverändert |
| **`hover.nvim`** `CursorMoved` ×4 | Float- / Status-View- / Bindings-Handler | Nicht in der Tiefe gelesen; die Float-Handler sind kurzlebig | **no** (ungeprüft) | unverändert |

Zu beachten: Ein „Cluster“ im rohen Scan ist kein Kandidat. Von den ~15 Clustern mit
vier oder mehr Registrierungen auf einem Event kombiniert nur `mdview.nvim`
*langlebig*, *dasselbe Plugin*, *gemeinsames Pattern* und *handgebaute Buchhaltung*.

---

## 6. Empfehlungen

1. **Keine Verbreitung forcieren.** Der Dispatcher hat einmal ein echtes Problem
   gelöst (filetree), und das ist ein gutes Ergebnis. Das Konzept-Doc sagte schon
   „meistens wird es nicht profitieren“; der Überblick bestätigt das.
2. **`mdview.nvim`s `BufEnter`-Gruppe migrieren, wenn der Ordner das nächste Mal
   angefasst wird.** Sie ersetzt an genau einer Stelle gebauten Code statt eine
   Schicht hinzuzufügen: sie schafft `autocmds_registry` ab (in 12 Dateien
   referenziert) und hält den ft-Filter in C. `pattern = defaults.ft_pattern` und
   `owner` nutzen. Als Teilmenge — die `CursorMoved*` / `BufWritePost` / `VimLeave`-
   Handler bleiben einfache Autocmds. **→ erledigt (§9.2).**
3. **`opts.pattern` in der Dispatcher-README dokumentieren — erledigt** (§8). Ohne das
   übertrieb der Kostenabschnitt der README den Nachteil genau für die Nutzer, die ihn
   am ehesten übernehmen.
4. **Den Pattern-gefilterten Fall in `scripts/bench_dispatcher.lua` ergänzen —
   erledigt** (§8). Ein früher Entwurf dieses Berichts wollte zusätzlich einen Fall
   „N Handler, die alle treffen“; das war falsch — die HIT-Spalte des Skripts ist
   genau dieser Fall.
5. **`lsp.nvim` und `my.nvim` in Ruhe lassen.** Kein Dispatcher dort. Die Stubs von
   `lsp.nvim` sind toter Code, kein Dispatch-Problem.
6. **`markdown.nvim`: nur wenn bequem.** Halbe Sitzung für eine kleine Aufräumarbeit.
   **→ geprüft, nicht gemacht (§9.3); dafür ein echter Bug behoben.**

---

## 7. Was dieser Bericht nicht geprüft hat

Stand nach der Umsetzung; Durchgestrichenes ist erledigt, das Übrige weiter offen.

- ~~**`LspAttach`-Reihenfolge in `lsp.nvim`.**~~ Gelesen, siehe §9.4.
- ~~**Ob die `mdview`-Handler voneinander in der Reihenfolge abhängen.**~~ Geklärt:
  `buffer_switch` liest den Buffer direkt und nie den Snapshot, den `bufenter`
  ablegt — keine Abhängigkeit (§9.2).
- **Langlebig vs. pro Widget** bei den Kit- und `hover.nvim`-Clustern — aus Namen und
  Struktur beurteilt, nicht durch Lesen jeder Stelle. *Weiter offen.*
- **Der Scan ist eine Regex,** Wrapper und dynamisch gebaute Eventlisten werden also
  untergezählt; die Summen sind Untergrenzen. *Weiter offen.*
- **Benchmarks stammen von einer Maschine und einem synthetischen `User`-Event.** Sie
  stützen „es gibt kein Geschwindigkeitsargument“, keine absolute Zahl. *Weiter
  offen.*

---

## 8. Verwandte Arbeiten nebenbei

- **`pattern` dokumentiert, gemessen und getestet — ausgeliefert** (`lib.nvim`
  `b1db5e7`). Neuer README-Abschnitt mit den Zahlen und seinen zwei Grenzen (alle
  Handler müssen das Pattern teilen; es ersetzt nicht `key`), eine `disp+pat`-Variante
  in `scripts/bench_dispatcher.lua` und eine Spec, die sicherstellt, dass ein Event
  außerhalb von `pattern` nie `key` erreicht, in beiden Modi.

- **Per-Handler-`pcall` im Dispatcher — ausgeliefert** (`lib.nvim` `7f67aea`). Die
  Dispatch-Schleife führte Handler ungeschützt aus, sodass ein werfender Handler alle
  nachfolgenden für dieses Event zum Schweigen brachte; in `filetree` heißt das: ein
  fehlerhaftes Feature bringt neun zum Schweigen. Jeder Handler läuft jetzt isoliert
  und wird einmal gemeldet (Dispatcher, Owner, Key, `register()`-Aufrufstelle).
  `once` wird weiterhin *vor* dem Aufruf verbraucht, ein dauerhaft werfender Handler
  wird also einmal pro Buffer gemeldet, nicht pro Event. Die Spec prüft das in beiden
  Modi und scheitert gegen die alte Schleife.
- **Die fünf leeren `lsp.nvim`-Stubs löschen — noch nicht gemacht.** Der Plan:
  `app/csharp`, `scripting/lua`, `systems/{c,go,zig}` entfernen, die Listen
  `scripting` und `systems` samt Helfern aus `lua/lsp/languages/init.lua` streichen,
  die passenden Aliasse aus `@types`, den Stub-Test in
  `TESTS/lsp/languages_spec.lua` sowie die Zeilen und den Absatz „deliberate
  placeholder“ in `docs/autocmds.md`. `docs/autocmds.md` nennt die Stubs derzeit
  „deliberate … placeholders for future QoL additions“, das Löschen kehrt also eine
  dokumentierte Entscheidung um. **Wartet auf Rückfrage.**
- **Das Konzept-Doc in den Ruhestand schicken — noch nicht gemacht.**
  `lib.nvim/ROADMAP/autocmd-dispatcher.md` trägt ein „shipped“-Banner, und der Eintrag
  in `ROADMAP.md` ist durchgestrichen statt entfernt. **Wartet auf Rückfrage.**

---

## 9. Umsetzungsprotokoll

Stand 2026-09-21. Alles unten ist auf `main` des jeweiligen Repos gepusht;
`stylua --check` und `luacheck` sind in beiden Repos sauber.

### 9.1 Korrekturen an der Analyse

Beim Umsetzen sind drei Aussagen des Berichts (§5/§6) präziser geworden:

1. **Die `autocmds_registry` fiel *nicht* wegen des Dispatchers weg.** §5 schrieb, der
   Dispatcher (`registry()` / `owner`) ersetze die Spiegel-Registry. Tatsächlich lagen
   *alle* Session-Autocmds von `mdview` schon in **einer** Augroup (`MdviewAutocmds`),
   und `teardown()` löschte diese Augroup bereits — das entfernt jedes Autocmd darin.
   Die Registry war eine zweite, handgepflegte Liste derselben IDs (und `stop.lua`
   ein dritter Durchlauf darüber). Sie war *unabhängig vom Dispatcher* überflüssig;
   der Dispatcher trägt dazu nichts bei. Er trägt nur die `BufEnter`-Bündelung (§9.2).
2. **`markdown.nvim` hat fünf `FileType`-Handler, nicht vier** (TableView, Refs-
   Baseline, Keymaps, User-Commands, Fold), und deren `is_md`-Nachprüfung ist bei
   `FileType` mit `pattern = ftpat` **wörtlich redundant**: `is_md` prüft exakt
   dieselbe Menge (`md`, `mdx`, `markdown`, `markdown.*`) wie das Pattern.
3. **Von den vier `BufEnter`-Handlern in `mdview` gehören drei in den Dispatcher.**
   `preview_tab_sync` ist global und pattern-los (ein anderes Lebenszyklus-Modell:
   einmal lazy angelegt, nie abgebaut) und bleibt ein einfaches Autocmd.
   `breadcrumbs` liefert nur seine `BufEnter`-*Hälfte* (`CursorMoved`/`CursorMovedI`
   bleiben einfach).

### 9.2 `mdview.nvim`

**Commit `2baebfb` — `autocmds_registry` abgeschafft.**

- `lua/mdview/helper/autocmds_registry.lua` gelöscht; die Aufrufe
  (`register(group, id)`) in neun Dateien entfernt, ebenso das dritte `detach_all()`
  in `bindings/usrcmds/stop.lua`.
- `teardown()` leert die Augroup jetzt **über lib** (`group("MdviewAutocmds", true)`)
  und löscht sie danach. Das vergisst auch lib's eigene Records — das rohe
  `nvim_del_autocmd` der Registry ließ sie stehen, ein gestoppter Session stand also
  weiter in der generierten Bindings-Tabelle.
- `stop.lua` ruft `teardown()` jetzt **unbedingt** auf (vorher nur unter
  `state.is_attached()`). `teardown()` schützt sich selbst über die eigene
  Augroup-ID; und es muss unbedingt sein: ein `attach()`, das auf halbem Weg wirft,
  hat schon Autocmds registriert, erreichte aber nie `set_attached(true)`.
- Neu: `TESTS/nvim/autocmds_lifecycle_spec.lua` (Attach/Teardown als eine Einheit,
  auch lib's Records, Idempotenz, Neustart).

**Commit `75ec57e` — die drei `BufEnter`-Handler hinter einem Dispatcher.**

- Neu: `lua/mdview/bindings/autocmds/enter_hub.lua`. Ein Dispatcher
  (`name = "mdview_bufenter"`, Gruppe `MdviewAutocmds`), `pattern = ft_pattern` — ein
  Buffer außerhalb des Patterns betritt Lua nie. **Key** = „ist der Buffer
  previewable“ (`previewable.is`), **Kontext** = normalisierter Pfad; beides wird
  einmal pro Event berechnet und an alle drei Handler gereicht. Vorher rechneten
  `bufenter` und `buffer_switch` denselben Pfad je einzeln aus.
- Angeschlossen: `bufenter` (Snapshot), `buffer_switch` (`browser.behavior`) und die
  `BufEnter`-Hälfte von `breadcrumbs`. Reihenfolge = Registrierungsreihenfolge =
  die bisherige (`bufenter`, `buffer_switch`, dann `breadcrumbs`). Explizite
  Prioritäten gibt es nicht, weil keine Abhängigkeit besteht (§7).
- **Lebenszyklus:** Der Dispatcher lebt über Sessions hinweg und wird bei `teardown()`
  nur abgehängt (`reset()`: alle Owner `unregister`, dann `detach`), ein Neustart hängt
  dasselbe Objekt wieder an, statt bei jedem Start einen neuen auf lib's Liste der
  lebenden Dispatcher zu stapeln. Ändert sich `ft_pattern` (etwa durch `any_file`
  beim Setup), wird er neu gebaut.
- **Signaturen:** `bufenter.attach()` und `buffer_switch.attach()` nehmen keine
  `group` mehr.
- **Nicht geändert:** `live_push`, `scroll_sync`, `selection_sync`, `vim_leave`,
  die `CursorMoved*`-Hälfte von `breadcrumbs` — je ein Handler pro Event, ein
  Dispatcher fügte nur eine Schicht hinzu.
- Neu/angepasst: `TESTS/nvim/enter_hub_spec.lua` (Reihenfolge, gemeinsamer Pfad,
  Pattern-Filter, previewable-Gate, Listung als *ein* Dispatcher, Reset,
  Wiederanhängen); `autocmds_lifecycle_spec.lua` um „genau **ein** `BufEnter`-Autocmd,
  drei Owner, auch nach Stopp/Start“ erweitert; `pin_spec.lua` hängt
  `buffer_switch` jetzt wie eine Session über den Hub an.
- Docs: `docs/BINDINGS.md`, `doc/mdview.txt`, `docs/FEATURES/MACHINERY.md`,
  `TESTS/README.md`. (`docs/map/*` ist generiert und wurde nicht angefasst.)
- **Ergebnis:** Suite 263 → **276** grün.

**Ehrliche Einordnung des Gewinns:** Er ist klein und rein strukturell — ein Autocmd
statt drei, ein Pfad statt zwei Berechnungen, eine Listung statt drei. Es ist *keine*
Geschwindigkeitsverbesserung (§3), und das Weglassen der Registry (§9.1) ist der
größere Teil der Aufräumarbeit.

### 9.3 `markdown.nvim`

**Gefundener Bug — Commit `7a52855`.** `tableview/renderer.lua` legte den
`BufWriteCmd` des Popups (`:w` schreibt Zeilen zurück) über
`autocmd.group("MarkdownNvimTableView", true)` an. Das ist **dieselbe Gruppe**, in die
`bindings/autocmds.lua` beim `setup()` den `FileType`-Autocmd legt, der TableView-Maps
und -Befehle auf Markdown-Buffern installiert — und `clear = true` leert eine Gruppe.
Bei jedem neu gebauten Popup verschwand der `FileType`-Autocmd; **jeder danach
geöffnete Markdown-Buffer bekam keine TableView-Maps und -Befehle mehr.**

Empirisch bestätigt (Wegwerf-Repro, dieselbe Aufrufform wie der Renderer): 4
`FileType`-Einträge in der Gruppe nach `setup()` (vier Patterns), **0** nach dem
Popup, und ein danach angelegter Markdown-Buffer hatte `:TableViewToggle` nicht.

Fix: eigene Gruppe `MarkdownNvimTableViewPopup`. Neu: `TESTS/tableview_group_spec.lua`
(in `run.lua` und `TESTS/README.md` eingetragen); die Spec **scheitert gegen den alten
Code** (verifiziert durch temporäres Zurücksetzen des Gruppennamens) und ist mit dem
Fix grün.

**Warum die Dispatcher-Migration nicht gemacht wurde.** Nach dem Lesen des Codes
greift keines der vier Struktur-Argumente aus §3.3:

- *Reihenfolge:* Die fünf Handler setzen unterschiedliche Dinge (TableView-Maps,
  Refs-Baseline, Keymaps, User-Commands, Fold-Optionen). Im gelesenen Code ist keine
  Reihenfolge-Bedingung sichtbar. (Ob Keymaps und TableView-Maps je dieselbe `lhs`
  belegen, habe ich nicht Zeile für Zeile verglichen.)
- *Gemeinsame Arbeit:* Es gibt keine — jeder Handler arbeitet nur mit `ev.buf`; das
  `is_md`-Prädikat ist redundant zum Pattern (§9.1) und ginge auch ohne Dispatcher weg.
- *Setup/Teardown per `owner`:* `require("markdown").setup` ist per `_setup_done`
  gegen Wiederholung geschützt, ein idempotentes Re-Setup, das `unregister` bräuchte,
  gibt es nicht.
- *Eine Registry:* Die Gruppennamen (`MarkdownNvimKeymaps`, `…UserCommands`, `…Fold`,
  `…TableView`, `…Refs`) stehen dokumentiert in `docs/BINDINGS.md`,
  `docs/BINDINGS.lua` und vier `docs/FEATURES/*`-Seiten; ein Zusammenlegen wäre
  Doku-Aufwand für eine reine Umbenennung.
- Außerdem nimmt `dispatcher.filetype.new` weder `pattern` noch `name`; man müsste
  `dispatcher.new` direkt nehmen.

Verdikt damit: **no**, außer die `FileType`-Arbeit im Plugin wächst. Falls trotzdem
gewünscht: fünf Handler unter einer Gruppe `MarkdownNvimFileType`, `pattern = ftpat`,
Keys = dieselbe Liste, Reihenfolge wie im `setup()` beibehalten, plus die Doku-Seiten
oben. Aufwand etwa eine halbe Sitzung.

### 9.4 `lsp.nvim` und `LspAttach`

Die vier Handler wurden gelesen:

| Modul | Was der `LspAttach`-Handler tut |
|---|---|
| `bindings/autocmds.lua` | bindet zwei Katalog-Keymaps (`rename`, `goto_type_definition_gr`) buffer-lokal neu, weil Neovim eigene `gr*`-Defaults setzt |
| `core/inlay_hints.lua` | wendet den Toggle-Zustand per `vim.schedule` auf den neu angehängten Buffer an |
| `core/lightbulb.lua` | stößt (falls geplant) die Code-Action-Abfrage an |
| `core/supervisor.lua` | merkt sich Client-ID → Name und Buffer für die Crash-Erholung |

Alle vier sind voneinander unabhängig, jeder gehört einem Modul mit eigener Gruppe und
eigenem Feature-Gate, keiner filtert nach Server (ein Key wäre also degeneriert), und
die einzige Reihenfolge-Anforderung im Code ist „vor dem ersten *Serverstart*
registriert“ (`lsp/init.lua`) — nicht zwischen den vier Handlern. **Verdikt: no.**
`lsp.nvim` ist damit vollständig geprüft; übrig bleibt nur das Löschen der Stubs (§8).

### 9.5 Prüfen und Reproduzieren

`mdview.nvim` (aus `E:\repos\mdview.nvim`):

```sh
nvim --headless -u NONE -i NONE --cmd "set rtp+=.,../lib.nvim" -c "luafile TESTS/nvim/harness.lua" -c "qa!"
stylua --check lua TESTS/nvim
luacheck lua TESTS/nvim
```

Erwartet: `276 passed, 0 failed`.

`markdown.nvim` (aus `E:\repos\markdown.nvim`):

```sh
nvim --headless -u NONE -c "set rtp+=." -c "luafile TESTS/run.lua" -c "qa!"
```

Erwartet: `MARKDOWN_TESTS_OK`.

Manuell (nicht automatisiert, siehe „Nicht verifiziert“ oben): `mdview` in einer echten
Session — Start, Wechsel zwischen Markdown-Buffern unter `reuse` und `new_tab`, Stopp,
Neustart — und in `markdown.nvim` ein TableView-Popup öffnen und danach eine *neue*
Markdown-Datei öffnen (`:TableViewToggle` muss dort existieren).
