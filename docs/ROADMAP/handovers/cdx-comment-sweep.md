# Handover — CDX-Kommentar-Sweep über nvim-config + alle Plugins

## Table of content

  - [Ziel](#ziel)
  - [Vorgehen (User-Entscheidungen)](#vorgehen-user-entscheidungen)
  - [Der `--- CDX:`-Tag](#der----cdx-tag)
  - [Wohin welches Wissen](#wohin-welches-wissen)
  - [Fortschritt](#fortschritt)
  - [Relocation-Log](#relocation-log)
  - [Wiederkehrende Fund-Muster](#wiederkehrende-fund-muster)

---

## Ziel

Jede Datei in der nvim-config und in allen 31 Plugin-Repos durchgehen. Im
Source-Code soll in den Kommentaren **nur stehen, was für genau diesen Platz
wichtig ist**. Alles andere:

- **Auffällig, aber Urteilssache** → `--- CDX:`-Tag setzen (nicht sofort fixen)
- **Klarer Fehler / Redundanz / Sprachverstoß** → direkt fixen
- **Wichtiges Wissen, das nicht in den Source gehört** (Design-Begründung,
  Messwerte, Neovim-/Lua-Mechanik) → **direkt umziehen** in Plugin-`docs/`
  bzw. WKDBooks, dann im Code nur ein Ein-Zeilen-Pointer

## Vorgehen (User-Entscheidungen)

- **Kalibrier-Häppchen zuerst:** ein Bereich komplett nach meinem Urteil, dann
  User-Review + Kalibrierung, dann Rest. Erstes Häppchen: `lua/autocmds/`.
- **Direkt umziehen:** Wissen wandert gleich in die Ziel-Datei, Commit/Push
  auch in die WKDBooks. Handover verweist dann nur noch drauf.
- Nie mehr als 1 Agent gleichzeitig. Antworten deutsch, Code/Kommentare englisch.
- Nach jedem Häppchen: stylua/luacheck (falls vorhanden), commit, push auf `main`.
- Keine Claude-Co-Authorschaft in Commits.

## Der `--- CDX:`-Tag

Format: `--- CDX: <kurze Beschreibung des Funds>` (englisch), an der auffälligen
Stelle. Bestehende eigene Marker des Users (`-- FIX:`, `-- AUDIT:`,
`-- SUPERSEDED:`) bleiben als solche erhalten, werden aber ins Englische
übersetzt, wenn sie deutsch sind.

## Wohin welches Wissen

Alle drei WKDBooks-Ziele liegen im **selben Repo** `StefanBartl/WKDBooks`
(`E:/repos/WKDBooks/`), ein Commit deckt alle ab.

| Wissensart | Ziel |
| --- | --- |
| Plugin-spezifische Design-Begründung, Messwerte, „warum so gebaut" | `E:/repos/WKDBooks/Development/wkdbook-myplugins/<plugin>.nvim/NOTES/` **oder** das Plugin-eigene `docs/` |
| Neovim-Mechanik (Event-Timing, API-Eigenheiten, `on_key`, `:split`-Semantik …) | `E:/repos/WKDBooks/Development/wkdbook-Neovim/MyNotes/` |
| Lua-/LuaLS-Mechanik | `E:/repos/WKDBooks/Development/wkdbook-Lua/` (passende Unterordner: `LuaLanguageServer/`, `Async/`, …) |
| Nicht-`vim.health`-relevante Config-Interna | nvim-config `docs/` |

wkdbook-Neovim/MyNotes-Stil: deutsch, informell, Emoji-Header erlaubt,
verknüpft das Allgemeinwissen mit dem konkreten Auslöser-Fall.

---

## Fortschritt

### Häppchen 1 — `lua/autocmds/` (16 Dateien)

**Status: erledigt, wartet auf User-Kalibrierung.**

Direkt gefixt:
- 4× `defaults.lua`: `-- AUDIT: Optionen beschreiben` (deutsch) → `--- CDX:` englisch
- `general/defaults.lua`: `enable = true, -- Disabled by default` — Widerspruch entschärft
- `init.lua`: 2 deutsche `AUDIT/FIX`-Marker → englische `CDX:`; die 6-Zeilen-
  `SUPERSEDED:`-Einzeiler-Wüste bei `no_name_guard` auf 4 knappe Zeilen
- `git/init.lua`: deutscher `FIX:` → englischer `CDX:`
- `auto-center-fexplorer.lua`: 27-Zeilen-Header (mit falschen `require`-Pfaden
  `auto-center-explorer`, deutschen Wörtern) → 11 Zeilen; `on_key`-Kommentar
  7 → 5 Zeilen
- `explorer-singleton.lua`: Header-Absatz raus, der den Inline-Kommentar
  wörtlich doppelte; „Known imprecision" 9 → 6 Zeilen; Inline-WinEnter-Kommentar
  7 → 4 Zeilen; **0 Code-Änderungen**
- `text/init.lua` + `terminals/init.lua`: 6× `-- Description:`-Zeilen raus
  (doppelten `desc =`); doppeltes `autocmd_lib`/`Autocmd`-Local zusammengelegt
- `text/init.lua`: Smart-Quotes → ASCII

`--- CDX:` gesetzt (Urteilssache, nicht gefixt):
- `general/helpers.lua:44` `M.snorm_pattern` — toter Code (nirgends aufgerufen,
  „markdown"-Default sieht nach Copy-Paste aus). Löschen?
- 4× `defaults.lua` — Felder undokumentiert
- `init.lua` — Submodul-Setup-Calls in eigene Module; `no_name_guard` nach
  filetree.nvim migrieren (Liste 1)
- `git/init.lua:38` — true/false/nil-Branches wegstrukturieren

Umgezogen: siehe [Relocation-Log](#relocation-log).

stylua ok. luacheck: nur die 106 vorbestehenden `vim`-global-Warnungen
(kein `.luacheckrc` in diesem Kontext), 0 errors, nichts von mir verursacht.

### Danach offen

nvim-config: `lua/` hat 359 Lua-Dateien. Grobe Bereiche in Reihenfolge-Vorschlag:
`lua/config/` (~100, groß: harpoon/neotest/neotree-Subsysteme), `lua/bindings/`,
`lua/plugins/`, `lua/startup/`, `lua/wkdoptions/`, `lua/themes/`, `lua/nvchad/` +
`lua/wkdnvchad/`, `lua/@types/`, `after/`, `init.lua`, `scripts/`.

Danach die 31 Plugin-Repos (Liste unten), repo-für-repo, je 1 Agent möglich.

<details><summary>Plugin-Liste</summary>

buffer-ctx, cascade, casedesk, cmdlog, color_my_ascii, dap, debugging, diff,
documentation, emojis, fileops, filetree, github_stats, gopath, hover, images,
insights, language, lib, lsp, markdown, mdview, open, pdfport, pickers,
recommender, replacer, reposcope, runtime-analysis, sandbox, sessions, spotlight
(alle unter `C:/repos` bzw. `E:/repos`). Nativ zusätzlich: docmap-desktop.

</details>

---

## Relocation-Log

Format: `Quelle → Ziel — was`

- `lua/autocmds/explorer-singleton.smoke.lua` (+ `explorer-singleton.lua` Header)
  → `wkdbook-Neovim/MyNotes/WinEnter-frisches-Fenster-Timing.md` (neu) — die
  Mechanik „`WinEnter` sieht bei frisch erstellten/gesplitteten Fenstern kurz
  den Buffer des Vorgängerfensters; `:split` klont erst den fokussierten
  Buffer". Stand vorher als ~12-Zeilen-Kommentar 2× im Code, jetzt 3-Zeilen-
  Pointer auf die Note. Commit in `StefanBartl/WKDBooks`.

---

## Wiederkehrende Fund-Muster

Aus Häppchen 1, als Kalibrier-Referenz für die nächsten Bereiche:

1. **Deutsch in englischen Kommentaren** — v.a. eigene `AUDIT:`/`FIX:`-Marker
   und einzelne Wörter (`Debounce-Verzögerung`). → übersetzt.
2. **`-- Description:`-Zeilen, die `desc = "…"` doppeln** — direkt darüber steht
   schon eine `-- N) …`-Sektionsüberschrift, darunter das `desc`-Feld. Die
   mittlere Zeile trägt nichts bei. → entfernt.
3. **Header-Kommentar dupliziert Inline-Kommentar** — dieselbe Begründung
   einmal im `---@module`-Block und nochmal an der Code-Stelle. → Header-Version
   raus, Inline bleibt (dort gehört sie hin).
4. **Falsche `require`-Pfade in USAGE-Beispielen** — Modulname im Doc-Block
   weicht vom echten Rückgabepfad ab. → korrigiert.
5. **Kommentar widerspricht dem Code** — `enable = true, -- Disabled by default`.
   → Kommentar an den Code angepasst.
6. **Neovim-Mechanik-Tutorial im Kommentar** — `keytrans() converts raw
   terminal bytes to a readable name …`, `:split` klont den fokussierten Buffer
   … . Allgemeinwissen, nicht ortsgebunden. → gekürzt auf den ortsrelevanten
   Kern, Rest ins Relocation-Log / nach wkdbook-Neovim.
7. **Undokumentierte Config-Felder** — `defaults.lua`-Tabellen ohne
   Feld-Beschreibungen, teils schon vom User als `AUDIT: Optionen beschreiben`
   markiert. → als `--- CDX:` belassen (Beschreiben ist eigene Aufgabe).
