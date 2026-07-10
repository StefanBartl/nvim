# `lib.nvim.ui.kit`

## Table of content

  - [Intro](#intro)
  - [Zu deinen konkreten Punkten](#zu-deinen-konkreten-punkten)
  - [Offene Entscheidungen (§14, mit Empfehlung)](#offene-entscheidungen-14-mit-empfehlung)

---

## Intro

Ein Modul **`lib.nvim.ui.kit`** in vier Schichten, jede für sich nutzbar:

1. **Theme / Presets (A)** — das Herzstück. Ein Theme ist eine Token-Tabelle (Border-Stärke, Farben/Highlights, Padding, zindex, Dimensionen). Presets (`minimal`/`rounded`/`solid`/`double`/`ascii`) unterscheiden sich genau in Rahmen + Farben. Der User kann per `setup({ presets = {...} })` eigene Presets registrieren **oder** pro Aufruf einzelne Optionen überschreiben. Highlights **linken** standardmäßig auf `NormalFloat`/`FloatBorder`/`PmenuSel` usw. → sieht in jedem Colorscheme richtig aus.
2. **Surface (B)** — ein *einzelnes* themed Float mit Handle (`:close()`, `:set_lines()`, …). Baut auf deinem vorhandenen [`make_scratch`](lua/lib/nvim/window/make_scratch.lua), [`nice_quit`](lua/lib/nvim/window/nice_quit.lua), [`ui.hl`](lua/lib/nvim/ui/hl/init.lua) — nichts wird neu erfunden.
3. **Layout (C)** — genau deine „3 Fenster, die perfekt aneinander liegen"-Lösung: deklarative Region-Spec → fertige `nvim_open_win`-Geometrie, `gap = 0`, resize-fest. Reine Mathematik → gut testbar.
4. **Components (D)** — `kit.popup({ type = ... })`: `note`, `select`, `prompt` (wie in deiner Skizze) **plus** vorgeschlagen: `toast`, `input`, `menu`, `progress`, `confirm` und ein `picker`-Scaffold.

---

## Zu deinen konkreten Punkten

- **Button-Confirm** (h/l zwischen Buttons, Enter bestätigt): vollständig durchdesignt (§9), aber als **teuerste Komponente in Phase 4** eingeplant. Slottet als `answer_type = "confirm", layout = "buttons"` in dieselbe API. Kann auch in einer separaten Session gebaut und via `confirmations.type` in filetree.nvim eingebunden werden — genau wie du es vorgeschlagen hast.
- **hover_select bleibt**: Phase 1 delegiert `type = "select"` an dein bestehendes hover_select (0 Breaking-Changes für die ~10 Call-Sites). Erst später native Implementierung, dann hover_select als dünner Shim → API bleibt stabil.
- **Registrierung** (dein Muss): der Plan schreibt vor, jedes Feature in `init.lua`/Aggregator (metatable+lazy+eager), `@types/all_functions.lua` und `doc/lib.nvim.txt` einzutragen — Abschnitt §12.
- **Cross-Platform**: alles nur `nvim_open_win`/Highlights; einziger echter Punkt sind Unicode-Border-Glyphen → als `ascii`-Preset gelöst.

---

## Offene Entscheidungen

1. **Name** — Empfehlung `ui.kit`  - andre Ideen?
2. **Native select jetzt oder später** — erst delegieren, Phase 3 nativ; Aber klares Ziel -> auf DAuer soll hover_select auch darin aufgehen

---

