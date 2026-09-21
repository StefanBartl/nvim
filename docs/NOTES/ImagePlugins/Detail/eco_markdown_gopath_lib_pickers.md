# Okosystem-Recherche: markdown.nvim / gopath.nvim / lib.nvim / pickers.nvim (Bild-Bezug)

Stand: read-only Analyse, Repos unter `E:\repos`, `.claude/worktrees` ignoriert. Pfade relativ zum jeweiligen Repo,
`file:line` = Code-Realitaet; "Docs:" = Behauptung aus README/docs. "UNVERIFIED" = nicht per Ausfuehrung/Suche belegt.
Ich habe zusaetzlich (ausserhalb der 4 Repos, nur soweit fuer die Kopplung noetig) in `images.nvim`, `hover.nvim`,
`pdfport.nvim` gelesen; das ist jeweils markiert.

---

## 0. Kurzuebersicht (Tabelle)

| | markdown.nvim | gopath.nvim | lib.nvim | pickers.nvim |
|---|---|---|---|---|
| Zweck | Markdown-Toolkit hinter `:Markdown`; Cursor-Action (`ma`/`mi`/`ml`) oeffnet Link/Bild/URL/Datei | Ein Key -> Datei unter dem Cursor (Symbol, `require`, Pfad, Stacktrace, URL) | Geteilte Lua/Nvim-Helfer-Basis fuer ~30 Plugins | `:Pickers` ueber telescope/fzf-lua/snacks, Scopes+Actions |
| Lua-Dateien / Zeilen | 81 / 15 691 | 77 / 11 117 | 476 / 51 128 (nicht 560) | 75 / 9 727 |
| Commits (erster Commit) | 220 (2026-06-22) | 179 (2025-09-10) | 582 (2026-06-22) | 184 (2026-06-22) |
| Tests | 43 Spec-Dateien, 6 607 Z., CI Linux/Win/macOS (`.github/workflows/ci.yml:14-17`) | 17 Specs in `scripts/ci/specs/` (8 268 Z.) + 6 manuelle Guides in `TESTS/` (`TESTS/README.md:1-13`) | 64 Spec-Dateien, 16 757 Z. | **1** Datei `TESTS/pickers_spec.lua` (4 648 Z., framework-frei) |
| Tags/Versionen | keine (`git tag` leer bei allen vieren) | | `ci-verified`-Branch als CI-Pin, ~30 Konsumenten (`lib.nvim/docs/CONTRIBUTING.md:103-107`) | |
| Status | "Beta" (README:1-3) | Beta | Beta | Beta |
| Bild-Relevanz | mittel: eigener Bild-Handler `mi`, Hover-Quelle, pdfport/images-Weichen | gering: Pfad-/Bildpfad-Aufloesung, oeffnet Bilder NUR extern | mittel (Infrastruktur): `image_preview`, `deps`, `cross.executable`, `net.curl`, `cache` | mittel: Bild/PDF-Vorschau in Picker-Preview via images.nvim |

Zusaetzlich (Aussenseiter, aber im Bild-Datenfluss zentral): **hover.nvim** hostet die Link/Pfad-Hover (Bild, PDF, Video, URL) und
ist die einzige Stelle mit einer echten Registry (siehe 8).

---

## 1. markdown.nvim

### 1.1 Zweck / Groesse / Reife
"Self-contained Markdown toolkit behind one `:Markdown` command" (README:23-26): Headings/Folding, GFM-Tabellen, Links/Refs,
Cursor-Action-Dispatcher. 81 Lua-Dateien, 220 Commits, 43 Specs, CI 3 OS mit `lib.nvim@ci-verified` und `hover.nvim`
(`.github/workflows/ci.yml:29-40`).

### 1.2 Bild-Funktionalitaet (Code-Realitaet)
- **Kein eigener Renderer, kein Inline-Overlay fuer `![](...)`.** Bilder werden nur *auf Tastendruck/Hover* behandelt.
- **Cursor-Action `mi`/`ma`** -> `handler/init.lua:266-269` -> `handler/image.lua`:
  - Zielerkennung: `!%b[]%(...%)` (`handler/image.lua:56`), `<img src=...>` (`:64-65`), sonst ganzer `<figure>`-Block via
    `core/html_links.media_at` (`:40-49,70`). Erfordert kein images.nvim.
  - Remote-URL (`^https?://`, `:73`) -> **immer System-Handler (Browser)**, nie Download/Preview (`:115`).
  - Lokal: `config.image.preview` = `ask|preview|system` (`:17`, DEFAULTS `config/DEFAULTS.lua:240-250`, Block `image = {` ab :247).
    `available()` fragt `lib.nvim.image_preview` (`:120`); ohne Provider -> direkt System-Viewer, kein Prompt (`:120-122`).
    "ask" -> `markdown.util.picker.select({"System app","Preview in Neovim"})` (`:126-136`); Preview -> `lib.nvim.image_preview.preview` (`:98`),
    bei Fehler Fallback auf System-Viewer (`:100-103`).
- **`:Markdown image paste|screenshot`** = duenne pcall-Delegation an `images.paste()`/`images.screenshot()`
  (`commands/image.lua:14-36`); ohne images.nvim nur Warnung (`:22,32`).
- **`:Markdown links show`** (`commands/links.lua`): Live-Bildvorschau NUR wenn `snacks.picker` **und** `images.browse.draw_in_window`
  vorhanden (`:171-173, 184-222, 238-250`); nutzt `images.guard.check` (`:207-208`) und `images.terminal.clear()` (`:221`).
  Sonst normale Auswahl ohne Vorschau. Fest verdrahtet auf snacks (Kommentar `:177-180`: "checked and only works with snacks").
- **Hover (Link-Vorschau)**: `hover/init.lua` registriert bei hover.nvim eine *Source* (mdlink/`<figure>`) und *Previews* (`#heading`,
  `file.md#heading`) via `hover.registry.register("markdown.nvim", ...)` (`hover/init.lua:58-105`). Das eigentliche Bild/PDF-Rendern
  passiert **in hover.nvim** (`hover.nvim/lua/hover/preview/media.lua`, 976 Z.), ueber `lib.nvim.image_preview.detect()` +
  `images.anchor/scale/convert/info` + `pdfport.render_page` (media.lua:299,527, 176-234, 704 — hover.nvim, nicht markdown).
  Config `hover.inline_images = true` (`config/DEFAULTS.lua:213`), `hover.url.fetch=false` (`:225`, Privacy-Default), `hover.office.convert=false` (`:235`).
- **Escalate** (`hover/init.lua:176-224`): Bild -> `images.zen.open(path)` (`:201-206`, pcall), PDF -> `handler.file.open_pdf`, md -> mdview.
- **PDF**: `handler/file.lua:107-121` — mit pdfport Prompt "System app / pdfport (new buffer)", sonst System. `:Markdown export pdf` delegiert an pdfport (`commands/export.lua:14-32`).
- **Math/Mermaid: nicht vorhanden.** `grep mermaid|latex|katex` in `lua/` -> keine Treffer; einziger Mermaid-Treffer ist ein Diagramm in `docs/map/overview.md`.
- **Captions**: `docs/image-captions.md` beschreibt 3 Wege; `<figure>`-Aufloesung ist real implementiert (`core/html_links.lua`, `TARGET_ATTR` `:44-52`,
  `figure_at`/`media_at`). images.nvim ruft genau diese Funktionen (siehe 1.4 / 8).
- **Ohne images.nvim**: alles funktioniert weiter (System-Viewer / Metadaten-Hover). Bewusst so (README:51 "All of the above are soft").

### 1.3 Externe CLI-Tools
- **`rg`** fuer Rueckwaerts-Referenzsuche: `core/file_refs.lua:112-128` (arg-list, `--fixed-strings`, `--`-Terminator), sync `:250` (`vim.system(...):wait()` **ohne Timeout**)
  und async `:289`; Fallback exhaustiver Glob wenn rg fehlt/abbricht (`:250-256`). rg-Probe wird in Intervallen neu geprueft (`:60`).
  Deklariert in `docs/install.json` (optional).
- **System-Opener** `util/platform.lua:47-96`: (1) `vim.ui.open` (`:53`), (2) `lib.nvim.cross.open_default` (`:62`), (3) **argv**-Fallback
  `explorer.exe`/`open`/`xdg-open` (`:75-96`, detach). Kein Shell-String; expliziter Kommentar zu `&`-Truncation bei `cmd /c start` (`:75-80`).
- Sonst nichts: kein magick/pdftoppm/curl in markdown.nvim selbst (Grep `vim.system|jobstart|io.popen` -> nur file_refs + platform).
- Docs (`docs/installation.md`): "No other external tools are required".

### 1.4 "Image-Suite"-relevante Features
- Link/Ziel-Aufloesung: `util/path.lua` (308 Z.) — Buffer-Dir dann cwd, `.`/`..`-Collapse, Windows-Laufwerke; **das ist der Resolver, den images.nvim
  per pcall mitnutzt** (`images.nvim/lua/images/resolve.lua:102-106`). `core/link_scan.lua` + `core/html_links.lua` sind der Link-Scanner,
  den images.nvim ebenfalls nutzt (`resolve.lua:51-58` `links_in_line`, `:202-206` `figure_at`).
  => **images.nvim haengt (soft) an markdown.nvim; markdown.nvim haengt (soft) an images.nvim: zyklische Soft-Kopplung.**
- Tote-Link-Diagnostik (`core/link_diagnostics.lua`): Datei-Existenz fuer relative Ziele, ausdruecklich keine Netzpruefung (`:14-19`, `is_external`).
- Datei verschoben/geloescht -> Referenzen finden/umschreiben: `M.find_references`, `M.retarget` (`init.lua:103-124`), `core/link_delete.lua:212`.
  Fuer Bild-Assets (Bild loeschen/verschieben -> Links reparieren) direkt wiederverwendbar.
- `commands/links.lua` `is_image_target` mit **eigener** Extension-Liste `{png,jpg,jpeg,gif,webp,bmp,svg}` (`:142-155`), bewusst "nicht aus images.nvim-Config".
- `handler/init.lua:30-40, 173-178`: Endungsliste `open.external_extensions` (DEFAULTS `:256-298`) entscheidet System-App vs `:edit`.

### 1.5 Sicherheit
- **Command-Substitution-Fix**: `util/path.lua:39-51` — bewusst NICHT `vim.fn.expand` (Backtick-Span = Shell-Ausfuehrung); nutzt `lib.nvim.cross.fs.expand_path`
  bzw. Inline-Fallback (`:36,49-64`). Beleg im Kommentar: "confirmed, the directory appeared". Gleicher Fix in images.nvim (`resolve.lua:108-117`).
- URL-Schema-Allowlist **nur `http(s)`** fuer den URL-Handler (`handler/url.lua:19-22`, `handler/init.lua:196-198`), Dateien -> System-Opener/`:edit` mit `fnameescape` (`handler/init.lua:180`).
- Alles arg-list; `platform.open` bypasst `'shell'` (`util/platform.lua:69-71`).
- **Schwaeche (Code-Realitaet):** Default `open.external_extensions` enthaelt `exe`, `msi`, `dmg`, `app` (`config/DEFAULTS.lua:295-298`), und
  `handler/file.lua:162-170` oeffnet jede existierende Datei per System-Handler (bei Bare-Path-Fallback auch ohne Endungsliste). Ein Link auf `x.exe`
  + `ma` fuehrt sie aus (Nutzer-initiiert, aber ohne Rueckfrage). Kein Groessen-/Zeitlimit fuer Bilder (Preview liegt bei images.nvim/hover).
- Kein Pfad-Traversal-Check (by design: Links duerfen ausserhalb zeigen); `lib.nvim.fs.is_subpath` wird von **keinem** der vier Plugins dafuer genutzt (Grep leer).
- Hover-Privacy: Netzabruf per Default aus (`hover.url.fetch=false`, `config/DEFAULTS.lua:220-226`).

### 1.6 Performance
- Lazy: `plugin/markdown.lua` nur Guard-Flag; Requires meist in Funktionskoerpern (z.B. `handler/image.lua:98,120`); FileType-Scope (`bindings/autocmds.lua:58-…`).
- Async rg (`file_refs.lua:289`) mit Fallback; hover-Debounce/LRU/Async-Guards liegen in hover.nvim (Docs `docs/hover.md:374-382`).
- Bare-Path-Hover nur wenn Datei existiert (`config/DEFAULTS.lua:199-204`).
- Sync `find_references` blockiert bis rg fertig (kein Timeout, `file_refs.lua:250`).

### 1.7 lib.nvim-Nutzung vs. eigene Duplikate
Distinct lib-Module: 29 (`grep "lib\.(nvim|lua)\."`); 33 harte `require`, 10 `pcall(require, "lib...")`.
Top: `lib.nvim.cross.*` (20), `bindings.*` (11), `fs.*` (5), `image_preview` (2), `deps` (2).
- Doku sagt "lib.nvim is the one real dependency" (README:52-53, `docs/installation.md` Requirements). Code: harte Pflicht
  (`bindings/autocmds.lua:12 require("lib.nvim.bindings.autocmd")`), **aber** viele Module tragen tote Soft-Fallbacks mit
  ("soft dependency" Kommentare): `util/notify.lua:16-40`, `util/clipboard.lua`, `util/progress.lua:15-28` ("hard dependency ... this submodule optional"),
  `util/path.lua:36-64` (Inline-Nachbau von expand_path/separators/collapse), `util/platform.lua:19-46`.
  => Doppelter Code, weil man lib nicht als Pflicht behandelt, obwohl es Pflicht ist.
- **Eigene Opener-Kette** (`util/platform.lua`) parallel zu `lib.nvim.cross.open_default` (`cross/open_default/init.lua:1-137`), das laut eigenem Kommentar
  aus "three independent copies" upgestreamt wurde und markdown.nvim's Version explizit als unvollstaendig (kein WSL) nennt (`open_default/init.lua:14-17`).
  markdown ruft `open_default` nur als 2. Stufe nach `vim.ui.open`.
- Eigene Extension-Listen (`commands/links.lua:142`, `DEFAULTS.lua:256`), eigene Bild-Regexe (`handler/image.lua:56,64`), eigener `picker`-Wrapper
  (`util/picker.lua`, 141 Z., `ui.kit` -> `vim.ui.select`), eigener Cache-Dir `stdpath("cache")/markdown` (`tableview/views/browser_session.lua:31`).
- KEIN eigener Terminal-/Protokoll-Detect (Grep `wezterm|TERM_PROGRAM|kitty|osc` -> 0 Treffer) — delegiert komplett an images.nvim/lib.image_preview.

### 1.7b Docs-vs-Code-Abweichungen
- `docs/WORKFLOW.md:132` nennt `require("markdown.util.image_preview").detect()`; **das Modul existiert nicht** (richtig: `lib.nvim.image_preview`).
- `handler/image.lua:10-12` und `config/DEFAULTS.lua:240-245` sagen "snacks.nvim or image.nvim" — images.nvim (der tatsaechlich bevorzugte Provider,
  `lib image_preview/init.lua:42-45`) fehlt im Kommentar. `docs/installation.md` nennt es korrekt.
- `:checkhealth markdown` prueft keinen Bild-Provider (`health.lua`, Grep leer) — Docs sagen das offen (`WORKFLOW.md:134-136`), korrekt.

### 1.8 Erweiterungspunkte / Kopplung
- Kein `User`-Autocmd (Grep `nvim_exec_autocmds|"User"` in markdown/lua leer).
- Oeffentliche API-Fassade `init.lua:80-124`: `handle_cursor_action`, `hover*`, `find_references(_async)`, `retarget`, `actions.*`; Module `markdown.core.link_scan`,
  `core.html_links`, `util.path` sind de facto Public API fuer images.nvim (Vertrag steht nur in images-Kommentaren).
- Registry-Beitrag: `hover.registry.register("markdown.nvim", { sources, previews })` (`hover/init.lua:64`) — markdown ist Beitragender, nicht Host.
- Subset-Installation: ohne hover/pdfport/images/mdview/ui.nvim laeuft alles (alle via `pcall`: `hover/init.lua:36-40`, `handler/file.lua:108`,
  `commands/image.lua:14`, `hover/init.lua:201`). **Aber**: `markdown.hover.escalate` ruft `require("hover.classify")` OHNE pcall (`hover/init.lua:190`,
  nach einem `lib()`-Check auf `hover` in `:177`) und `markdown/hover/section.lua:26` `require("hover.preview.text")` hart — nur erreichbar wenn hover.nvim da ist (UNVERIFIED ob jeder Pfad geschuetzt ist).
  lib.nvim ist Pflicht.

---

## 2. gopath.nvim

### 2.1 Zweck / Groesse / Reife
"One key, and you are at the file the cursor is pointing at" (README:24-28): mehrphasige Pipeline (Help -> URL strict -> Env-Var -> filetoken ->
linepath -> LSP/Treesitter/builtin je Sprache -> URL loose -> filetoken-Fallback -> `<cfile>`; `resolve.lua:1-16`). 77 Dateien, 179 Commits (seit 2025-09), 17 CI-Specs
(`scripts/ci/specs`) + manuelle Guides; CI vorhanden.

### 2.2 Bild-Funktionalitaet (Code-Realitaet)
- **gopath rendert keine Bilder und ruft images.nvim NICHT auf** (Grep `images` in `lua/`: nur pdfport-Treffer).
- Bildpfad unter Cursor wird aufgeloest (Endung in `EXTERNAL_EXTENSIONS`: png/jpg/gif/bmp/tiff/webp/ico/svg, `external/helpers/detector.lua:9-20`) und dann
  **immer an den System-Viewer** uebergeben (`open/init.lua:62-79` -> `external.open`). Kein Hook, um stattdessen images.nvim (`:Image show`/zen) zu rufen;
  einzige Konfig: `external.extensions` (additiv), `external.enable` (`config/DEFAULTS.lua:44-58`).
- Fehlende Bild/PDF-Datei -> Fehler statt Create-Angebot (`open/init.lua:70-74`).
- **PDF**: mit pdfport -> Chooser System/Buffer/Float/Terminal ueber `ui.kit.select` (`external/pdf.lua:22-31,84-119`); ohne pdfport/ohne ui.nvim -> System-Viewer
  (`pdf.lua:98-101`). Fehler in pdfport -> Fallback System-App (`pdf.lua:77-82`).
- **Umgekehrt: images.nvim benutzt gopath** als 3. Schritt von `under_cursor` (`images.nvim/lua/images/resolve.lua:172-184`, pcall `gopath.resolve.resolve_at_cursor`,
  akzeptiert nur `res.exists` + Bild-Endung). hover.nvim nutzt es fuer "truncated paths" (`bare_path.lua via_gopath`, Docs `docs/FEATURES/INTEGRATIONS.md`).
- Remote-Bild-URLs: `kind="url"` -> Browser (`open/init.lua:41-45`), nie Download. Math/Mermaid: nicht relevant.

### 2.3 Externe CLI-Tools
- Opener-Kette (`external/helpers/opener.lua`): (1) `open_nvim` (open.nvim, soft, `pcall(require,"open_nvim")` `:14-25`, Aufruf `:161-168`) ->
  (2) `lib.nvim.cross.open_default` (`:27-38,140-152`) -> (3) minimaler argv-Fallback `open`/`xdg-open`/`explorer.exe` (`:59-115`). Immer argv, nie Shell.
  Bewusst `vim.system` statt `jobstart(detach=true)` wegen Windows-DETACHED_PROCESS-Bug (`:83-93`).
- Reveal: `lib.nvim.cross.reveal_in_fm` + Fallback (`external/helpers/revealer.lua:16-66`).
- **`fd`/`fdfind`/`rg`**: `truncated/finder.lua:14-19` (`detect_tool`), `vim.system(cmd,{text=true})` + `:wait()` **ohne Timeout** (`:52-54`).
  **Aber**: `finder.find` (sync, fd/rg) hat keinen Aufrufer in `lua/` (nur `scripts/ci/specs/truncated_spec.lua`); Produktivpfad ist `finder.find_async`
  = rein libuv-`fs_scandir` ohne externes Tool (`tailsearch.lua:360,472`, `finder.lua:162-200`). Docs/health behaupten Nutzung
  (`docs/install.json` "Fastest live filesystem search…", `health.lua:64-69`) -> **Doku-vs-Code-Abweichung** (Tools faktisch unbenutzt; UNVERIFIED nur fuer dynamische Aufrufe).
- Keine Timeouts sonst; kein magick/curl.

### 2.4 "Image-Suite"-relevante Features
- Beste Pfad-Aufloesung im Oekosystem: Truncated-Tails (`...nvim/init.lua:42`), `:line:col`, Env-Vars (`env_path.lua`), rtp/`&path`/package.path
  (`util/path.lua:1-25`), Alternate-Files (`alternate/`), Stacktrace-Zeilen. Fuer "go-to-image" wertvoll, weil Nutzer Bildpfade oft aus `:messages`/Logs kopieren.
- Zwei Vertragsregeln fuer Aufrufer (Docs `docs/FEATURES/INTEGRATIONS.md`): `kind=="url"` -> Aufrufer soll ablehnen; `exists` muss geprueft werden. Ergebnisform ist der Vertrag.
- `create_on_missing` mit Bestaetigung (`create.lua`, default confirm, `:235`) — fuer Bilder deaktiviert (siehe oben).

### 2.5 Sicherheit
- URL: **Scheme-Allowlist** `DEFAULT_SCHEMES` (`util/url.lua:26-…`: http, https, ftp, ftps, sftp, ssh, file, git, irc, ircs, magnet, news, gopher, rsync + `mailto` `:208`), erweiterbar
  via `url.schemes`. Deutlich breiter als markdown (nur http/https). Loose-URLs (Bare Host) nur nach allen Datei-Resolvern und mit konservativer TLD-Liste (ohne `sh`,`py`,`md`, `util/url.lua:8-19` Kommentar).
- Alle Spawns arg-list; keine `vim.fn.expand`-Aufrufe auf Buffer-Text (nur `<cfile>`, `resolve.lua:158`). `vim.cmd.edit(fnameescape(...))` (`open/init.lua:106-108`).
- **Default-Extension-Liste enthaelt `exe`, `dmg`, `app`** (`detector.lua:49-51`) -> System-Open ohne Rueckfrage (Nutzer-initiiert).
- **Verifizierter Bug (Windows, nur ohne open.nvim):** Weil gopath's Schemes (`ssh://`, `sftp://`, `file://`, `magnet:`, `mailto:`) an `lib.nvim.cross.open_default` gehen, das
  nur `http(s)://`, `ftp://`, `www.` als URL erkennt (`open_default/init.lua:29-33`) und alles andere als Pfad behandelt (`windows_target` `:57-66`), werden sie verstuemmelt.
  Ich habe die identische Logik headless in Nvim 0.12 nachgestellt: `ssh://host/x -> ssh:\\host\x`, `mailto:a@b.de -> C:\...\Temp\mailto:a@b.de`,
  `file:///C:/x.txt -> file:\\\C:\x.txt`, `https://x.y/?a=1&b=2` unveraendert. (Nachbau der Funktion, nicht Ende-zu-Ende durch gopath; `expand_path` fuer diese Eingaben ohne Effekt.)
  markdown.nvim ist nicht betroffen (nutzt zuerst `vim.ui.open`, und erlaubt nur http(s)).
- Kein Traversal-/Groessenlimit-Konzept (nicht relevant, Nutzer navigiert bewusst).

### 2.6 Performance
- Asynchroner, begrenzt-paralleler Dateiindex (`fs_scandir`, `max_concurrency=16`, `truncated/cache.lua:63-66,272`), In-Memory + JSON-Disk-Cache pro Roots-Fingerprint
  (`cache.lua:34-58,101-110`, `stdpath("cache")/gopath_fs_cache_<hash>.json`), Auto-Refresh, Ausschluss `.git/node_modules/...` (`:68-85`).
- rtp-Namensindex mit TTL 30 s (`@types/config.lua:83`, `util/path.lua`). `resolve_cached` blockiert nie.
- **Gemessene Latenz-Doku**: LSP-`buf_request_sync` wartet 200 ms ohne Client -> Fix "frage zuerst ob Client attached" (`providers/lsp.lua:40-64`, Docs INTEGRATIONS.md).
  Aufrufer hover.nvim gated CursorHold-Aufrufe darum.
- Lazy Requires (`registry.lua` laedt aber alle Resolver-Module eager beim Require, `:19-45`).

### 2.7 lib.nvim-Nutzung vs. Duplikate
Distinct lib-Module: 25; 22 harte require, 12 pcall. Top: bindings (8), fs (7), cross (5), `lib.lua.tables` (5), strings (3), notify (2), frecency (1).
- Ehrlich dokumentiert: "lib.nvim is a hard dependency ... this module more defensive" (`util/cross.lua:10-24`); trotzdem Soft-Fallbacks in `util/log.lua:22-30`,
  `opener.lua:27-38`, `revealer.lua:16-27`, `create.lua:37-…`.
- **Duplikate:** eigene OS-Erkennung (`opener.lua:41-52`, `revealer.lua:38-49`) trotz `lib.nvim.cross.platform`; eigener minimaler Opener parallel zu lib+open.nvim;
  eigene `short_hash` (Kommentar: lib's store/project ist privat, `truncated/cache.lua:22-33`); eigener JSON-Disk-Cache statt `lib.nvim.cache.disk`;
  eigene fd/rg-Erkennung (`finder.lua:14-19`, statt `lib.nvim.cross.executable.find`); eigene `EXTERNAL_EXTENSIONS`-Liste (`detector.lua:9-60`).
- **Gutes Gegenbeispiel:** Frecency-Heuristik wurde aus pickers nach `lib.nvim.frecency` extrahiert und von gopath+pickers geteilt (`pickers/smart/frecency.lua:14-25`; `alternate/frecency.lua`).
- Kein eigener Terminal-Detect.

### 2.8 Erweiterungspunkte / Kopplung
- **`custom_resolvers`** je Filetype (Tabelle oder Modulname-String, `registry.lua:69-103`, `@types/config.lua:74-77`) — Nutzer-Erweiterung, laeuft VOR den eingebauten.
- Oeffentliche API `require("gopath.resolve").resolve_at_cursor()` -> `{kind,path,exists,...}` (Konsumenten: images.nvim, hover.nvim).
- Kein `User`-Autocmd, keine Registry fuer *Opener* (kein "open image with X"-Hook).
- Soft: open.nvim, pdfport, ui.nvim, filetree.nvim, treesitter, LSP. Hart: lib.nvim. Subset-Install (gopath+lib allein) funktioniert.

---

## 3. lib.nvim

### 3.1 Zweck / Groesse / Reife
"One tested base under a whole set of plugins" (README:22-25), **keine Drittabhaengigkeiten**, "Every StefanBartl/*.nvim plugin depends on this one. The direction never reverses" (README:43-44).
476 Lua-Dateien, 51 128 Zeilen, 582 Commits, 64 Specs (16 757 Z.), Doku pro Modul (`docs/MODULE_AUDIT.md` prueft Vollstaendigkeit), `ci-verified`-Branch.

### 3.2 Bild-Funktionalitaet
Nur **ein** Bild-Modul: `lua/lib/nvim/image_preview/init.lua` (215 Z.)
- `detect()` -> `"images.nvim" | "snacks" | "image.nvim" | nil`, Reihenfolge images.nvim -> snacks -> image.nvim (`:41-58`); Begruendung im Kopf (`:9-14`):
  snacks/image.nvim sprechen nur Kitty-Protokoll, das nativ-Windows-Nvim in WezTerm nie zeichnet.
- `preview(path)` oeffnet zentriertes Float (80 %, `:69-81`) und zeichnet je Provider: images.nvim via `images.browse.draw_in_window` + `images.guard.check` (`:128-155`),
  snacks via `:edit` (`:157-172`), image.nvim via `image.from_file`+`render` (`:174-212`); Cleanup `images.terminal.clear()` (`:151`), `WinClosed`-Autocmd (`:106-115`), `q`/`<Esc>` (`:100-102`).
- **Konsumenten:** markdown `handler/image.lua:98,120`; hover.nvim `preview/media.lua:299,527`, `float.lua`, `shot.lua`, `video.lua` (hover.nvim); pdfport (nur Kommentar,
  `pdfport/platform/init.lua:107`); `.deps`-Kopie in runtime-analysis.nvim. gopath und pickers rufen es **nicht** (pickers geht direkt an `images.integrations.picker`).
- **Kein Terminal-/Protokoll-Detect:** `terminal/init.lua` bietet nur `escape`, `is_terminal_buf`, `delete_terminal_buf`, `is_kitty()` (Env `KITTY_LISTEN_ON`/`$TERM`, `:13-55`).
  Grep `wezterm|TERM_PROGRAM|sixel|OSC 1337|XTVERSION` in `lib/` -> 0 Treffer. Env-Sniffing liegt stattdessen dupliziert in `pdfport/platform/init.lua:110-116` und images.nvim (`guard.lua`).
- **Keine Bild-Verarbeitung** (kein magick/pdftoppm/ffmpeg/tesseract im Code; nur als Deps-Beispiele).
- `lib.nvim.ui.kit.compare` ist explizit fuer images.nvims Bildvergleich gebaut aber bewusst bildagnostisch (`ui/kit/compare.lua:1-8`).
- **Widerspruch Docs vs Code:** README:43-44 "nothing here may require any of them" vs. `image_preview` (pcall auf `images`, `images.guard`, `images.browse`, `images.terminal`; ein
  hartes `require("image")` nur im image.nvim-Zweig `:175`). Es ist Soft-Kopplung, aber Richtung lib -> Consumer existiert.
- `docs/MODULE_AUDIT.md:341-347` (Stand?) sagt "no README" fuer image_preview; README existiert inzwischen (`image_preview/README.md`) -> Audit-Text veraltet.

### 3.3 Externe CLI-Tools (Infrastruktur)
- **`cross.executable`** (`cross/executable/init.lua`): `exists/path/find/mason_bin`, **memoisiert** (`:47-79`), Begruendung: `vim.fn.executable` kostet auf Windows ms (AV-Filter, `:9-14`); `clear()`.
- **`cross.run_argv`**: argv ohne Shell, `run_blocking(_captured)` (`:8-70`, `vim.system():wait()` **ohne Timeout**), `run_async_captured` mit `stop()` (`:88-121`).
  **`cross.run`**: Shell-String-Runner (`sh -lc` / powershell, `run/init.lua:9-19`) — Injektionsrisiko wenn Nutzerdaten eingebettet; nur `run_detached(argv)` ist argv (`:159-185`).
- **`cross.run.env`** (`spawn_env`): baut vollstaendigen PATH + Keyring-Variablen fuer Kindprozesse (`docs/guides/subprocess-env.md`); pickers nutzt es (`smart/search.lua:28`, `engines/snacks.lua:35`).
- **`cross.open_default`** (137 Z.): Windows `explorer.exe`, WSL `wslpath`, macOS `open`, Linux `xdg-open`; Absolutpfad+Backslash fuer explorer (`:41-66`); Bug bei Nicht-http-Schemes, siehe 2.5.
- **`net.curl`** (661 Z.): argv-Builder; Credentials nie in argv sondern per `-K -` stdin-Config (`:170-185`), `--max-filesize` (`:193-196`), Timeouts via `vim.system(timeout=)` (`:399,437,461...`),
  `download`/`download_blocking` mit Default 5 min / 512 MiB (`:496-505`). **Kein `-L`, kein `--proto`-Restrict** (Kommentar `:335-337`).
  images.nvim bringt trotzdem eigenen curl/wget-Aufruf mit (`images.nvim/lua/images/remote.lua:96-113`: `curl -fsSL --max-time --max-filesize -o`, wget `-Q`) -> Duplikat.
- **`deps`** (`deps/README.md`): `docs/install.json`/`INSTALL.md` je Plugin, `health.report`, `show_once` (First-Run-Popup), `require_tool` (Fehlermoment), `pm` (9 Paketmanager),
  `install` mit Bestaetigung (tippt Befehl ins Terminal, fuehrt nie selbst aus, `README:9-13`), **`status`: alle Tools ueber alle Plugins gemergt** (`deps/status.lua:1-40`, `:Lib deps status`).

### 3.4 "Image-Suite"-relevant / Sicherheit
- **Sicherheit in lib:** `fs.is_subpath` (mit `realpath`-Option, 8.3-Kurznamen/Symlinks, `fs/is_subpath/init.lua:1-40`), `fs.normkey`, `cache.disk` sichert korrupte JSON als `.corrupt`
  statt Datenverlust (`cache/disk.lua:37-60`), `curl`-Credential-Isolation, `cross.fs.expand_path` als sichere Alternative zu `vim.fn.expand` (`cross/fs/expand_path/init.lua`, Env/`~`, kein Backtick).
  **`is_subpath` wird von markdown/gopath/pickers nicht genutzt** (Grep).
- Cache: `cache.disk` = **JSON**-Namespace-Datei `stdpath("cache")/lib.nvim/cache/<ns>.json` mit TTL (`disk.lua:24-33`) — **nicht** fuer Binaerdateien geeignet;
  `cache.memory` = TTL/changedtick-Namespaces (`memory.lua:1-48`, images.nvim nutzt es: `images/info.lua:36`). Ein Binaer-Dateicache (gerasterte PDF-Seiten, heruntergeladene Bilder) fehlt in lib.

### 3.5 Performance-Muster
- Memoisierung (executable), `cache.memory` mit changedtick, `run_async_captured` als Antwort auf "groesste Quelle von UI-Freezes" (`run_argv/init.lua:72-87`), `debounce/`,
  `fs.scan_cached`, async-directory-walk-Guide.
- Viele Konsumenten aber benutzen weiter die blockierenden Varianten (pickers `smart/search.lua:142,165` `:wait(timeout)` mit 3 s Default, `:107`).

### 3.6 Kopplung / Subset
- Alle 4 Plugins (+ images.nvim, 17 Module) haengen hart an lib. Distinct genutzte lib-Module: markdown 29, gopath 25, pickers 20, images 17. Haeufigste: `notify` (40 Verwendungen),
  `bindings.autocmd` (22), `cross.fs.expand_path` (18), `cross.executable` (18), `bindings.usercmd.composer` (9), `bindings.keymap` (7), `cross.platform.*`, `deps`, `window.make_scratch`, `cache.memory`.
- Konsequenz fuer Suite: "images.nvim + lib" ist minimal lauffaehig; alles andere ist pcall-soft.
- Keine Versionen/Tags -> Feature-Detection "by shape" in Konsumenten (pickers `integrations/images/init.lua:71-87,127-133`; gopath `create.lua:37-80` "older checkout").
  Deshalb `ci-verified`.

---

## 4. pickers.nvim

### 4.1 Zweck / Groesse / Reife
"One `:Pickers` command over telescope.nvim, fzf-lua and snacks.nvim" (README:23-26), Grammatik `:Pickers <scope> <action>`. 75 Dateien, 9 727 Z., 184 Commits,
**Tests: 1 Datei** (`TESTS/pickers_spec.lua`, ~689 Assertions-artige Zeilen laut `grep -c`, UNVERIFIED wie viele echte Faelle). Dünnste Testabdeckung der vier bei aehnlicher Groesse.

### 4.2 Bild-Funktionalitaet (sauberste Integration der vier)
- `lua/pickers/integrations/images/init.lua` (214 Z.) + `adapters/snacks.lua` (117) + `adapters/telescope.lua` (124).
- **Einseitig, weich, "by shape"**: `pcall(require,"images.integrations.picker")`; Vertrag = `available/is_image/preview` (Pflicht, `:76-87`) plus optional `is_previewable/is_pdf`
  (Fallback auf `is_image` wenn aelteres images.nvim, `:127-133`), `clear`. images.nvim exportiert diese (`images.nvim/lua/images/integrations/picker.lua:91-244`: available, is_image, is_pdf, is_previewable, extensions, clear, preview).
- **Drei Gates in fester Reihenfolge** (`:40-51`): `cfg.images.enabled` (Opt-out, DEFAULTS `config/DEFAULTS.lua:222-224`), images.nvim vorhanden, Terminal kann zeichnen (`images.available()` strikt — "an empty preview window is worse than the text preview").
- **Generation-Ticket** verhindert, dass ein veralteter `on_done/on_ready`-Callback ein neueres Preview ueberschreibt (`:147-200`).
- **PDF-Vorschau (Seite 1)** ohne dass pickers PDFs kennt: `is_previewable`/`is_pdf` -> Wartezustand "rendering the page…" (`adapters/snacks.lua:96-98`, `telescope.lua:99-101`), `on_ready` raeumt Placeholder vor dem Zeichnen ab.
- Engine-Abdeckung: snacks voll (`pick_files`, `smart`, `pick_item`; `engines/snacks.lua:93,119,183,227`), telescope voll fuer Datei-Picker (`engines/telescope.lua:153,281`; `smart` behaelt Grep-Previewer, dokumentiert),
  **fzf-lua nicht** (kein per-call-Hook; verweist auf fzf-lua `previewers.builtin.extensions` chafa/viu, `docs/FEATURES/IMAGES.md:79-100`). `live_grep` nicht verdrahtet.
- **Bestaetigen (`<CR>`) auf einem Bild** oeffnet weiterhin als Buffer (kein `images.show`/zen-Action): Grep `images\.` in `lua/pickers` findet nur `integrations/` + `health.lua`.
- Ohne images.nvim: Engine-eigene Previewer wie zuvor; `:checkhealth pickers` unterscheidet 4 Zustaende (`health.lua:172-215`).
- Nichts zu Remote-URLs/Math/Mermaid/Inline-Markdown.

### 4.3 Externe CLI-Tools
- `fd`/`fdfind` (Dirs/Files, `engines/snacks.lua:46,262-…` `vim.system` async mit `spawn_env.apply`), `rg` (Grep, smart), `fzf` (Engine), `gh` (`sources/github.lua:84-104`, async), PowerShell `Get-PSDrive`/`df` (`sources/drives.lua:22-46`).
  Alles arg-list.
- `smart/search.lua:127-165`: `vim.system(cmd, spawn_env.apply{cwd,text}):wait(timeout)` — **blockiert Main-Loop bis `timeout` (Default 3000 ms)**, dokumentiert als bewusste Entscheidung ("fast and the engines debounce", `:7`); Fehlerklassifikation Signal/Exitcode (`:88-106`).
- Windows: PowerShell/`explorer` spezifika in `drives.lua`, `lib.nvim.cross.platform.is_wsl/is_windows` (`drives.lua:68-82`).
- Deklariert in `docs/install.json` (rg, fd, fzf), `lib.nvim.deps.health` in `health.lua:243-247`.

### 4.4 "Image-Suite"-relevante Features
- Datei-Picker/`smart`-Ranking mit Frecency (`lib.nvim.frecency` `smart/frecency.lua:93`), Scopes (`cwd`, `repos`, `system`, `drives`, Collections, `browse/` fuer Verzeichnisnavigation).
- Fuer eine Suite: "browse images" ist ueber `:Pickers cwd files` + images-Preview bereits abgedeckt (Docs `IMAGES.md:12-19`); Galerie/Raster nicht (das macht images.nvim `:Image gallery` UNVERIFIED-Detail beim anderen Agenten).

### 4.5 Sicherheit
- Nur argv; `vim.cmd("edit " .. fnameescape(...))` (`entry_actions/create_file.lua:37`); Pfade werden ueber `lib.nvim.cross.fs.expand_path` expandiert (`actions/dir.lua:21-27`, `config/init.lua:5`).
- `gh`-JSON-URLs -> `vim.ui.open` (`sources/github.lua:9`) ohne Schema-Check (UNVERIFIED ob `url` immer https von gh).
- Keine Groessenlimits/Traversal-Checks (fuer Picker unnoetig; Preview-Groesse liegt bei images.nvim/Engine, telescope `filesize_limit` wird respektiert `adapters/telescope.lua:11-15`).

### 4.6 Performance
- Preview nur fuer die aktuelle Selektion, Ticket-Guard, Engine-Default-Fallback ohne Flackern (Rueckgabe `false` *vor* dem Zeichnen, `init.lua:150-153`).
- Resolve **pro Picker** statt gecacht (`engines/snacks.lua:60-68`), weil Terminal/Config sich zwischen Pickern aendern.
- `lib.nvim.cache.memory`-Namespace fuer Laufwerksliste (`sources/drives.lua:60`), `when_loaded` per `User`-Autocmd `LazyLoad` (`engines/when_loaded.lua:72`).
- Debounce liegt bei den Engines.

### 4.7 lib.nvim-Nutzung vs. Duplikate
Distinct lib-Module: 20; 48 harte require (davon `lib.nvim.notify` 27x), 6 pcall. Docs: "lib.nvim and one picker engine are the real dependencies" (README:43-44) — deckt sich mit dem Code.
- **fd/fdfind-Erkennung fuenffach kopiert:** `engines/fzf.lua:56-57`, `engines/snacks.lua:46-47`, `engines/telescope.lua:32-33`, `sources/system.lua:24-25`, `smart/search.lua:34-36`
  — obwohl `lib.nvim.cross.executable.find({"fd","fdfind"})` (memoisiert) existiert. Gleiches Muster in gopath `finder.lua:14-19`.
- Kein eigener Terminal-Detect, kein eigenes PDF, kein eigener Preview-Float (Preview liegt komplett in den Engines/images.nvim) — hier ist Duplikation minimal.

### 4.8 Erweiterungspunkte / Kopplung
- Config: `collections` (Nutzer-Scopes, `config/DEFAULTS.lua:18`), `builtins`-Registry (intern), `keys.*`, `tabs.groups`; Engines sind **intern**, nicht als Plugin-API erweiterbar (`engines/init.lua`).
- `plugin_spec()`-Builder fuer Engine-Ownership (`plugin_spec.lua`); `User LazyLoad` nur konsumiert.
- Keine eigene Registry fuer Preview-Provider: der Vertrag ist images.nvim's 3-Funktionen-Surface (`images.integrations.picker`).
- Subset: pickers + lib + eine Engine laeuft; images.nvim/pdfport/ui.nvim weich. (`ui.nvim`: create-file/system-search-Prompts haben **keinen** Fallback, `docs/installation.md` Requirements.)

---

## 5. Was lib.nvim bietet (und was tatsaechlich genutzt wird)

| Baustein | lib-Modul | Genutzt von | Anmerkung |
|---|---|---|---|
| Bild-Preview-Provider-Detect + Float | `lib.nvim.image_preview` | markdown (`handler/image.lua`), hover.nvim | gopath/pickers nicht; images.nvim wird bevorzugt (`:41-45`) |
| Tool-Erkennung (memoisiert) | `cross.executable` | images.nvim (18x, `blocks.lua:229`, `convert.lua:77`…), pickers (nein!), gopath (nein!) | pickers/gopath erkennen fd/rg selbst |
| Tool-Deklaration/Health/Install | `deps` + `docs/install.json` | alle 4 + images/hover/pdfport (install.json vorhanden) | `:Lib deps status` = suite-weite Werkzeugsicht (`deps/status.lua`) |
| Opener | `cross.open_default`, `reveal_in_fm` | gopath (Stufe 2), markdown (Stufe 2) | eigene Ketten in beiden zusaetzlich |
| Prozess (argv) | `cross.run_argv`, `cross.run.env` | pickers (`env`, `drives`), sonst `vim.system` direkt | kein Timeout-Parameter in `run_argv` |
| HTTP/Download | `net.curl` | nicht von images.nvim (`remote.lua` eigener Aufruf), nicht von markdown/gopath/pickers | hover.nvim URL-Fetch: UNVERIFIED |
| Cache JSON+TTL / Memory | `cache.disk`, `cache.memory` | pickers (frecency, drives), images (`info.lua:36`) | Binaercache fehlt; gopath hat eigenen JSON-Cache |
| Frecency | `lib.nvim.frecency` | pickers + gopath | Musterbeispiel fuer erfolgreiches Upstreamen |
| Notify/Bindings/Composer | `notify`, `bindings.*` | alle | hart |
| Pfad/Sicherheit | `cross.fs.expand_path`, `fs.is_subpath`, `normkey` | expand_path: alle; is_subpath: keiner | |
| Terminal-Protokoll-Detect | **fehlt** (nur `terminal.is_kitty`) | - | dupliziert in images.nvim/pdfport (`platform/init.lua:110-116`)/hover/media.nvim |

## 6. Duplikate ausserhalb von lib (kritisch fuer die Bundle-Frage)

1. **System-Opener**: markdown `util/platform.lua` (3-stufig), gopath `external/helpers/opener.lua` (open.nvim -> lib -> minimal), lib `cross/open_default` (Upstream), open.nvim `handlers/default.lua`.
   lib nennt es selbst "three independent copies" (`open_default/init.lua:14-17`). Ergebnis: 3 Kopien mit unterschiedlicher WSL/URL-Semantik -> der Windows-Schema-Bug (2.5) betrifft nur einen Pfad.
2. **Bild-/Medien-Endungslisten**: markdown `commands/links.lua:142` + `DEFAULTS.lua:256-298`; gopath `detector.lua:9-60`; hover `classify.lua:22`; images.nvim `config.extensions`
   (Fallback-Kopie `resolve.lua:32`). pickers delegiert korrekt (`integrations/images/init.lua:108-116` "images.nvim's own configured extension list").
3. **fd/fdfind/rg-Erkennung**: pickers x5, gopath x1 (siehe 4.7).
4. **PDF-Chooser**: markdown `handler/file.lua:107-121` (System/pdfport-buffer, 2 Optionen, `markdown.util.picker`) vs gopath `external/pdf.lua` (4 Modi, `ui.kit.select`) — zwei UIs fuer dasselbe pdfport-Oeffnen.
5. **Preview-Float/Zeichnen**: markdown `commands/links.lua:184-222` (snacks + `images.browse.draw_in_window`), lib `image_preview/init.lua:66-155` (eigenes 80 %-Float), hover.nvim `preview/media.lua` (eigene Geometrie + `images.anchor`),
   pickers-Adapter (Fensterbox vom Picker) — vier Wege, die alle letztlich `images.browse.draw_in_window`/`images.anchor` rufen.
6. **Terminal-Erkennung**: nicht in lib; in images.nvim/pdfport/hover/media.nvim je ein eigenes Env-Sniffing.
7. **Download/curl**: `lib.nvim.net.curl.download` (Timeout+max_bytes) vs images.nvim `remote.lua:96-113` eigener curl/wget-Aufruf.
8. **Disk-Cache-Verzeichnisse**: markdown `stdpath("cache")/markdown`, gopath `gopath_fs_cache_*.json`, lib `lib.nvim/cache/`, images.nvim (eigene remote/pdf-Caches, beim anderen Agenten) — kein gemeinsamer Cache-Root.
9. **Pfad-Resolver**: markdown `util/path.lua` (Referenz), gopath `util/path.lua`, images.nvim ruft markdown's per pcall und hat eigenen Fallback (`resolve.lua:97-131`) — mit Inline-Kopie des Sicherheitsfixes.
10. **Soft-Fallback-Klone von lib** in markdown/gopath, obwohl lib hart erforderlich ist (1.7, 2.7).

## 7. Sicherheit — Zusammenfassung ueber die vier

| Aspekt | markdown | gopath | lib | pickers |
|---|---|---|---|---|
| Arg-list statt Shell | ja | ja | `run_argv`/`net.curl` ja; `cross.run` = Shell-String | ja |
| URL-Scheme-Allowlist | nur http(s) | 14 Schemes + mailto, erweiterbar | `open_default`: nur http/ftp/www erkannt (Bug bei anderen) | keine (gh-URL) |
| Command-Substitution-Schutz | ja (`util/path.lua:39-51`) | `<cfile>` only | `expand_path` sicher | expand_path |
| Traversal/`is_subpath` | nein | nein | vorhanden, ungenutzt | nein |
| Groessen-/Zeitlimits | rg ohne Timeout | fd/rg sync ohne Timeout (toter Code) | `net.curl` ja, `run_argv` nein | `:wait(3000)` |
| Executables auto-oeffnen | `exe/msi/dmg/app` in Default-Liste | `exe/dmg/app` in Default-Liste | - | - |
| Privacy | Hover-Fetch aus | - | curl-Credentials via stdin | - |

## 8. Erweiterungspunkte fuer eine Suite und Kopplungs-Wirkung

**Was es real gibt:**
- `hover.registry.register(name,{sources,previews,positions})` (hover.nvim `registry.lua:96`), Inversion "Plugins registrieren sich in der Bibliothek" (Kopf `:1-40`) — einziges echtes Registry-Modell; markdown ist Beitragender.
- `images.integrations.picker` (Surface fuer pickers, by-shape-Check), `images.browse.draw_in_window`/`images.guard`/`images.terminal`/`images.zen`/`images.anchor` als **de-facto Public API**, die markdown, lib, hover direkt (pcall) aufrufen —
  ohne dokumentierten Vertrag/Versionsnummer.
- `gopath.resolve.resolve_at_cursor` (dokumentierter Vertrag `INTEGRATIONS.md`), gopath `custom_resolvers`.
- markdown `core.link_scan`/`core.html_links`/`util.path` als geteilter Scanner/Resolver (Vertrag nur implizit).
- `lib.nvim.deps` (`docs/install.json` je Plugin, `:Lib deps status/install`) = bereits vorhandene suite-weite Werkzeug-Aggregation.
- **Kein einziges `User`-Autocmd-Event** in markdown/gopath/pickers (nur pickers *konsumiert* `LazyLoad`); lib kennt nur `buf_win_tab/capture` (`:105`) und `nvim_usrcmds/autocmds.lua:35`. Keine Events wie `ImagesShown` o.ae.
- Kein Opener-Hook in gopath (Bild -> nur System-App), kein Provider-Hook in pickers, kein Handler-Registry in markdown (Handler fest in `handler/init.lua`).

**Kopplung / Teilinstallation:**
- Hart: lib.nvim (alle). Jede Bild-Verbindung ist `pcall`: markdown->images/pdfport/hover, gopath->pdfport/open.nvim, pickers->images, lib->images, images->markdown/gopath.
- **Zyklus (weich):** markdown <-> images.nvim (images nutzt `markdown.core.link_scan/html_links/util.path`; markdown nutzt `images.*`); gopath <- images/hover. Bei Teilinstallation faellt jeweils die Gegenrichtung
  auf eingebaute Naeherung zurueck (images `resolve.lua:60-72`), d.h. **kein Crash, aber Funktionsverlust** (z.B. keine `<figure>`-Aufloesung ohne markdown.nvim).
- "hover" ist implizit ein 5.: markdown-Hover = hover.nvim + markdown-Source + images-Zeichnen + pdfport-Raster + gopath-Pfade. Ein Bundle muss diese 5er-Kette beruecksichtigen.
- Versions-/Kompatibilitaets-Steuerung: keine Tags, nur `ci-verified`-Branch (lib) und "by shape"-Feature-Checks; ein Bundle koennte hier einen gepruften Kompatibilitaetssatz einfrieren.
- Doku-Schuld, die ein Bundle sichtbar macht: veraltete Providerlisten (markdown DEFAULTS), falscher Modulname (`WORKFLOW.md:132`), fd/rg-Deklaration in gopath ohne produktiven Nutzer.

## 9. Wichtigste Befunde (Kernaussagen)

1. Keines der vier Plugins hat einen eigenen Bild-Renderer; **images.nvim ist der einzige Renderer**, die anderen sind Adapter (markdown-Handler/Links, lib `image_preview`, pickers-Integration, hover). gopath ist eine Ausnahme: es kennt Bilder nur als "extern oeffnen".
2. Die Integrationsqualitaet ist ungleich: **pickers** (klarer 3-Funktionen-Vertrag, Generation-Ticket, health-Zustandsdifferenzierung, dokumentierte Luecken) ist das Vorbild; **markdown** verwendet 5 verschiedene images-Einstiegspunkte ohne Vertrag; **gopath** hat keinen Hook.
3. lib.nvim hat die Infrastruktur (`deps`, `executable`, `net.curl`, `open_default`, `frecency`), aber keinen Terminal-Protokoll-Detect und keinen Binaer-Cache; Duplikate entstehen genau dort und in Opener/Extension-Listen.
4. Zwei verifizierte Auffaelligkeiten: (a) `lib.cross.open_default` verstuemmelt auf nativem Windows `ssh://`, `sftp://`, `file://`, `mailto:`, `magnet:` (reproduziert per Nachbau, betrifft gopath ohne open.nvim); (b) gopath's fd/rg sind deklariert aber im Produktivpfad ungenutzt.
5. Sicherheitsniveau insgesamt gut (argv, Command-Substitution-Fix, curl-Credentials via stdin, Privacy-Defaults), Luecken: Default-Listen enthalten ausfuehrbare Endungen, `is_subpath` ungenutzt, blockierende `:wait()` ohne/mit 3 s Timeout.

## 10. UNVERIFIED / Grenzen
- Ob `hover.classify`/`hover.preview.text`-Requires in markdown (`hover/init.lua:190`, `hover/section.lua:26`) in jedem Pfad durch die `lib()`/registry-Gates geschuetzt sind, nicht Zeile fuer Zeile durchverfolgt.
- Reihenfolge-Verhalten bei Doppel-Klick-Keymap (images yieldet, wenn markdown zuerst mappt, `images/bindings/keymaps.lua:65-90`; Gegenrichtung nicht getestet).
- pickers-Testfaelle: nur Zeilenzaehlung, keine Ausfuehrung der Suites.
- hover.nvim URL-Fetch nutzt evtl. lib `net.curl` — nicht geprueft.
- Keine Tests/Plugins gestartet; einzige Ausfuehrung: kleiner Nvim-Headless-Nachbau von `windows_target` (Scratchpad, keine Repo-Aenderung).
