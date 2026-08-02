# `spotlight.nvim` — Konzept

## Table of content

- [`spotlight.nvim` — Konzept](#spotlightnvim--konzept)
  - [Table of content](#table-of-content)
  - [Problem](#problem)
  - [Idee in einem Satz](#idee-in-einem-satz)
  - [Warum kein Bordmittel](#warum-kein-bordmittel)
  - [Kernmodell](#kernmodell)
  - [Technische Kernentscheidung: `matchadd()` statt Extmarks](#technische-kernentscheidung-matchadd-statt-extmarks)
  - [Tier 1 — Kern](#tier-1--kern)
  - [Tier 2 — Log-Komfort](#tier-2--log-komfort)
  - [Bewusst nicht](#bewusst-nicht)
  - [Persistenz](#persistenz)
    - [Konfiguration (User-Setup)](#konfiguration-user-setup)
    - [Per-Datei-Override (Usercommand)](#per-datei-override-usercommand)
    - [Datenmodell](#datenmodell)
  - [Farben](#farben)
  - [Struktur](#struktur)
  - [Abgrenzung zu buffer-ctx.nvim](#abgrenzung-zu-buffer-ctxnvim)
  - [Keymaps](#keymaps)
  - [Offene Punkte](#offene-punkte)

---

## Problem

Beim Log-Lesen entdeckst du eine Request-ID, PID, IP oder einen Fehlercode und
willst **alle weiteren Vorkommen sofort sehen** — mehrere Token gleichzeitig,
in unterscheidbaren Farben, dauerhaft (übersteht Suchen, Scrollen,
Fensterwechsel).

## Idee in einem Satz

Ein Plugin, das beliebig viele Wörter/Zahlen/Tokens per Tastendruck dauerhaft
und farblich unterscheidbar hervorhebt — persistiert pro Projekt, mit
Ausnahmeregelung pro Datei.

## Warum kein Bordmittel

- `*` / `hlsearch`: nur ein Token gleichzeitig, kollidiert mit der echten Suche.
- `matchadd()` / `:match` direkt genutzt: fensterlokal — ein Split verliert die
  Markierung; `:match` hat nur 3 Slots, keine Verwaltung/Liste/Persistenz.

## Kernmodell

Ein *Spotlight* = `{ pattern, farb-slot, id }`. Eine Liste davon, global aktiv
für die laufende Session.

## Technische Kernentscheidung: `matchadd()` statt Extmarks

Die Entscheidung, die über die Performance bei großen Logs bestimmt:

- **Extmarks** müssten den Buffer scannen, um Positionen zu setzen →
  O(Dateigröße) bei jeder Änderung. Bei einem 200-MB-Log unbrauchbar.
- **`matchadd()`** übergibt das *Muster* an Vims Renderer. Der wertet nur
  sichtbare Zeilen aus, in C, ohne Lua pro Tastendruck. **Kosten unabhängig
  von der Dateigröße** — kein Neuscannen bei Textänderung, weil Muster statt
  Positionen gespeichert werden.
- Preis: fensterlokal → pro Fenster neu anwenden via `BufWinEnter`/`WinNew`.
  Etwa 30 Zeilen Buchhaltung (`win → {spotlight_id → match_id}`).
- Bonus: `priority` steuerbar, also bewusst über oder unter `hlsearch`.

Konsequenz: Trefferzahlen **nicht** dauerhaft mitrechnen, sondern nur
on-demand beim Öffnen der Liste — sonst wäre der Performance-Vorteil wieder
weg.

## Tier 1 — Kern

1. **Toggle unter Cursor** (normal) / **Auswahl** (visual)
2. **Auto-Farbe** aus Palette, round-robin
3. **Alle löschen**
4. **Liste** (`kit.select`, `respect_override` nicht nötig — reines internes
   Werkzeug): Farbfeld + Muster + Trefferzahl → springen / entfernen
5. **Nächstes/voriges Vorkommen**
6. **Persistenz pro Projekt**, Default an (siehe [Persistenz](#persistenz))

Zum Token-Erfassen: `<cword>` reicht für Logs nicht (UUIDs, `192.168.1.1`,
`0x1f4a`, Timestamps). Daher ein kleiner Resolver mit konfigurierbarer
Musterliste in Prioritätsreihenfolge, Fallback `<cword>`. Visuelle Auswahl
wird literal escaped übernommen.

## Tier 2 — Log-Komfort

7. **Quickfix-Filter**: alle Zeilen mit Treffer → Quickfix ("zeig mir nur die
   Zeilen mit dieser Request-ID"). Bleibt Tier 2: der Kernnutzen (Hervorhebung)
   ist mit Tier 1 vollständig abgedeckt, Quickfix ist echtes Komfort-Feature
   obendrauf, kein Blocker für einen nutzbaren ersten Wurf.
8. **Trefferzahl** in der Liste (on-demand berechnet)

## Bewusst nicht

Regex-Modus, Scope pro Buffer/Filetype, Auto-Regeln (`ERROR`/`WARN`
automatisch), Export/Import von Sets. Hält Tier 1+2 bei ~6–8 Befehlen statt
20. Nachrüstbar, wenn sich echter Bedarf zeigt.

## Persistenz

Default: **an**. Zwei unabhängige Stellschrauben — global (User-Config) und
pro Datei (Usercommand) — decken beide Richtungen ab: wer das Feature meist
nicht will, kann es global abschalten und gezielt pro Datei einschalten;
Default-Nutzer können umgekehrt gezielt eine einzelne Datei ausnehmen.

### Konfiguration (User-Setup)

```lua
require("spotlight").setup({
  persist = {
    default = true, -- global default; user kann hier auch false setzen,
                     -- um das Verhalten komplett umzudrehen (opt-in statt opt-out)
  },
})
```

### Per-Datei-Override (Usercommand)

```
:Spotlight persist off   " für die aktuelle Datei: nicht speichern/wiederherstellen
:Spotlight persist on    " für die aktuelle Datei: zurück auf globalen Default
:Spotlight persist status
```

Die Ausnahme wird über den Dateipfad (relativ zum Projekt-Root) erfasst, nicht
über die Buffer-Nummer — überlebt also Neuöffnen derselben Datei.

### Datenmodell

Die Ausnahme bezieht sich nicht auf "in welchen Dateien kommt das Pattern
vor" (mehrdeutig — ein Pattern kann in beliebig vielen Dateien matchen),
sondern auf den **Erstellungskontext**: In welcher Datei war der Cursor, als
das Spotlight per Toggle angelegt wurde. Ein in einer ausgenommenen Datei
erstelltes Spotlight wirkt die restliche Session ganz normal überall (Matches
in jedem Fenster/jeder Datei) — es wird nur beim Speichern übersprungen.

`lib.nvim.store.project`, Key `spotlight/state`:

```lua
{
  spotlights = {
    { pattern = "...", hl = "Spotlight3", origin_file = "logs/app.log" },
    ...
  },
  persist_exceptions = { ["logs/app-2026-07-27.log"] = false }, -- Datei → override
}
```

Speichern debounced (`lib.nvim.debounce`), Laden bei `VimEnter`. Beim
Speichern wird pro Spotlight `origin_file` gegen `persist_exceptions`
(mit Fallback auf den globalen `persist.default`) geprüft; Spotlights mit
effektivem "nicht persistieren" werden aus dem geschriebenen Snapshot
ausgelassen, bleiben aber für den Rest der laufenden Session aktiv.

## Farben

8 Gruppen `Spotlight1..8`, jeweils explizit bg **und** fg, damit der Kontrast
in hell wie dunkel garantiert ist; überschreibbar, Neudefinition bei
`ColorScheme` — dasselbe Muster wie in `wkdoptions`.

**Synergie:** Die kürzlich ergänzten „rich items" in `kit.select`
(`item.lines` mit Per-Span-Highlights) sind exakt das, was die Liste braucht —
farbiges Swatch pro Zeile ohne eigenen Rendering-Code.

## Struktur

Analog `cascade.nvim`/`emojis.nvim`:

```
lua/spotlight/
  init.lua        setup/teardown
  config/         DEFAULTS + validate
  core/           registry · palette · match (matchadd-Buchhaltung)
  cursor.lua      Token-Resolver
  ui/list.lua     kit.select-Liste
  nav.lua         next/prev
  persist.lua     store.project + persist_exceptions
  bindings/       keymaps + usercmds (composer)
  health.lua
  @types/
```

## Abgrenzung zu buffer-ctx.nvim

`buffer-ctx.nvim`s `:Mark` markiert **Zeilen** (Signcolumn, Yank). Hier geht es
um **Token-Vorkommen** über den ganzen Buffer/alle Fenster — anderes Concern,
daher eigenes Plugin statt Feature dort.

## Keymaps

Prefix `<leader>m` (kollisionsfrei geprüft gegen die bestehende
`<leader>m*`-Gruppe — Notes-Picker etc. — in der nvim-Config; `<leader>mc`
ist dort bereits belegt):

- `<leader>mk` — Toggle Spotlight unter Cursor / Auswahl
- `<leader>mK` — Liste öffnen
- `<leader>mn` — nächstes Vorkommen
- `<leader>mp` — voriges Vorkommen

Kein eigener Top-Level-Keymap für "alle löschen" — lebt als Aktion in der
Liste (`<leader>mK`), spart einen Keymap und vermeidet die Kollision mit dem
bereits belegten `<leader>mc`.

## Offene Punkte

Keine mehr offen — alle drei Punkte aus der vorherigen Fassung wurden
entschieden (siehe [Persistenz](#persistenz), [Tier 2](#tier-2--log-komfort),
[Keymaps](#keymaps)).
