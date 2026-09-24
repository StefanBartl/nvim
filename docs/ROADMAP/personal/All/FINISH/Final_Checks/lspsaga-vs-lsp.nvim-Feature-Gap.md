# lspsaga.nvim → lsp.nvim — offene Punkte

**Stand:** 2026-09-22. Alle Punkte aus der Aufwand/Nutzen-Tabelle sind erledigt bis auf Rang 1 (deine
Prüfungen im echten Terminal, A1–A10) — zuletzt Call Hierarchy für Lua: `lsc`/`lsC` fallen in einem
Lua-Buffer ohne antwortenden Client auf `documentation.nvim` zurück (`opts.callhierarchy = true`), gegen
echtes documentation.nvim und echtes lua_ls headless bestätigt. Details zu allem Erledigten (Befunde 1–4,
Rang 2/3 des Reviews, die adversariale Commit-Review, Selbstrekursion, `UiSticky.md`, Hunk-Spannen-Cache,
rust-analyzer, `.d.ts`/`node_modules`-Ausnahme, Call Hierarchy) liegen archiviert, siehe unten.

## Table of content

  - [Commits dieser Arbeit (ohne WKDBooks)](#commits-dieser-arbeit-ohne-wkdbooks)
  - [Wohin das Erledigte gewandert ist](#wohin-das-erledigte-gewandert-ist)
  - [Nach Aufwand / Nutzen](#nach-aufwand--nutzen)
  - [Abschluss: deine Prüfungen im echten Terminal](#abschluss-deine-prüfungen-im-echten-terminal)
  - [Nicht geprüft / Grenzen](#nicht-geprüft--grenzen)

---

## Commits dieser Arbeit (ohne WKDBooks)

Alle auf `main` und `origin/main` der jeweiligen Repos. WKDBooks-Commits (Archiv, Backlog, Tool-Rezepte)
stehen absichtlich nicht hier; sie sind per `git log --grep=lsp.nvim` in `WKDBooks` zu finden.

**`StefanBartl/lsp.nvim`** — der Code

| SHA | Zeit | Inhalt |
|---|---|---|
| `e57684b` | 09:28 | feat(lspsaga): Winbar-Breadcrumb als gerundete, farbige Chips (Vorgeschichte, später ersetzt) |
| `43071c4` | 09:29 | fix(lspsaga): eigene Farben je Chip (Vorgeschichte) |
| `e49fdbe` | 16:25 | **feat: lspsaga ersetzt** durch eigenen Breadcrumb, Peek, Finder, Outline, Type Hierarchy, gitsigns-Aktionen, Implementations-Marker |
| `7028b4e` | 16:30 | test(peek): Temp-Pfade vor dem Vergleich auflösen |
| `8694129` | 16:31 | test(peek): Pfad-Helfer umbenannt, luacheck meldete Shadowing |
| `e6d716d` | 17:34 | fix: Review des Ersatzes, acht Defekte, je einer mit zuerst fehlschlagendem Test |
| `9b60d98` | 23:14 | fix(gitsigns_actions): Force-Stop hinterlässt keinen Zombie-Client mehr; lsp.nvims eigene Clients zählen nicht als Sprachserver (Winbar, `:Lsp stop`/`restart`) |
| `12e4e8e` | 23:20 | fix(gitsigns_actions): Stage/Reset/Preview wirken auf die Selektion, für die sie angeboten wurden |
| `e50e10a` | 23:20 | fix(implement): eine Runde, deren Text sich nach dem Versand geändert hat, zeichnet nichts |
| `8895cd8` | — | fix(actions): `lsh`/`lsH`-Meldung nennt gopls als gemessenen Type-Hierarchy-Server (Rang 2) |
| `dddd97c` | — | docs(navigation): Type-Hierarchy-Fallback nennt Zig, nicht nur vier Sprachen (Fund aus der adversarialen Commit-Review von `8895cd8`) |
| `8d805c1` | — | perf(gitsigns_actions): Hunk-Spannen gecacht, nur bei `GitSignsUpdate` neu berechnet (Rang, jetzt erledigt) |
| `3c1d5fe` | — | docs(navigation): rust-analyzer gemessen — keine Type-Hierarchy-Unterstützung |
| `cfd6e92` | — | perf(implement): `.d.ts`-Dateien und `node_modules` ausgelassen |
| `88ba62f` | — | feat(call_hierarchy): `lsc`/`lsC` fallen für Lua auf documentation.nvim zurück |

CI zu `e50e10a`: grün auf Ubuntu, macOS und Windows, lint und smoke, `ci-verified` veröffentlicht.
CI zu `8895cd8`: grün (2m11s). CI zu `dddd97c`: grün (smoke/lint/3 Plattformen), `ci-verified` veröffentlicht.
CI zu `8d805c1`: grün auf allen drei Plattformen, lint und smoke, `ci-verified` veröffentlicht.
CI zu `3c1d5fe`: grün auf allen drei Plattformen, lint und smoke, `ci-verified` veröffentlicht.
CI zu `cfd6e92`: grün auf allen drei Plattformen, lint und smoke, `ci-verified` veröffentlicht.
CI zu `88ba62f`: grün auf allen drei Plattformen, lint und smoke, `ci-verified` veröffentlicht.

**`StefanBartl/ui.nvim`** — die Statuszeile

| SHA | Zeit | Inhalt |
|---|---|---|
| `d96fe16` | — | fix(statusline): lsp.nvims eigener In-Process-Client zählt in Label und Datei-Icon nicht mehr als Sprachserver (Rang 3, zweite Hälfte von Review-Befund 1) |

CI zu `d96fe16`: grün (1m12s).

**`StefanBartl/nvim`** — diese Config (Doku, Bindings, Schalter)

| SHA | Zeit | Inhalt |
|---|---|---|
| `e9a54ea64` | 11:00 | docs(roadmap): Feature-Gap-Report mit Aufwand/Nutzen angelegt |
| `f08f1edf2` | 16:28 | docs+chore: lspsaga ist aus dem Pack, Binding-Notizen und Reste bereinigt |
| `a2095deeb` | 17:15 | docs(bindings): UiSticky-Blatt ohne die veraltete lspsaga-Erwähnung (Nebenbei-Änderung) |
| `789e08161` | 17:36 | docs(reports): `lsa` ist Normal-only, die Selektion hat `gra` |
| `a4a140f49` | 21:08 | feat(lsp): gitsigns-Hunk-Aktionen in `lsa` als Probe an |
| `a106754b0` | 21:41 | feat(lsp): Implementations-Marker an; Report auf das Offene gekürzt |
| `225dd0ab5` | 22:31 | docs(reports): Report auf das Offene gekürzt, nach Aufwand/Nutzen, Commit-Liste vorn |
| `e47dfbf23` | — | docs(reports): Report nach dem Review der Config-Commits, neue SHAs, offene Punkte neu geordnet |
| `b65670e41` | — | docs(reports): Rang 2/3 erledigt, Aufwand/Nutzen-Tabelle neu nummeriert |
| `092ea0169` | — | docs(reports): zwei fehlende Commit-Zeilen nachgetragen |
| `94bcb6b3d` | — | docs(bindings): UiSticky-Blatt an ui.nvims tatsächliche sanitize/may_touch-Logik angepasst (Rang 3) |

`225dd0ab5` hieß zuerst `138c4a175`: eine andere Sitzung hat den Commit per `--amend` umgeschrieben und
dabei eine Zeile in `docs/ROADMAP/ROADMAP.md` (die Usage-Tabelle) mit hineingenommen. Der Report-Inhalt
ist derselbe. Der Commit dieser Aktualisierung steht direkt darüber im `git log` der Config.
`ui.nvim` bekam mit `d96fe16` echte Arbeit für diese Aufgabe (Rang 3, s. o.). Andere Repos
(documentation.nvim, pickers.nvim, lib.nvim) hatten heute nur CI- und fremde Arbeit; nichts davon gehört
zu dieser Aufgabe.

---

## Wohin das Erledigte gewandert ist

Alles Umgesetzte (10 Lücken + eigener Winbar-Breadcrumb, lspsaga entfernt, `code_actions.gitsigns` als
Probe an, `implement` an (gemessen), altes `lazy/lspsaga.nvim` gelöscht, lspsaga-Reste in der
Plugin-Roadmap markiert), **die Type-Hierarchy-Messung**, **die vier behobenen Review-Befunde**,
**Rang 2/3 (gopls-Meldung, ui.nvim-Statuszeile)**, **die Selbstrekursions-Entscheidung, die
`UiSticky.md`-Korrektur, das Hunk-Spannen-Caching, rust-analyzer gemessen, die `.d.ts`/`node_modules`-
Ausnahme und Call Hierarchy für Lua** liegen archiviert in
`$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/lsp.nvim/Backlog/FEATURES/lspsaga-vs-lsp.nvim-Feature-Gap_ERLEDIGT.md`
(dort „Nachtrag“ bis „Nachtrag 9“). Hier steht nur noch Rang 1, deine eigene Terminal-Prüfung.

**Skalen:** Aufwand XS ≤ 30 min · S 30 min–2 h · M 2 h–1 Tag. Nutzen 1–5 (5 = täglich, spart
merklich Zeit). Beides Schätzungen, keine Messungen.

---

## Nach Aufwand / Nutzen

Sortierregel: Nutzen ÷ Aufwand, mit XS = 15 min, S = 75 min als Mittelwerte; Punkte, die an eine
Bedingung geknüpft sind, nach den unbedingten. Die Spalte „Wer“ sagt, ob ich es tun kann oder du.

| Rang | Punkt | Wer | Repo | Aufwand | Nutzen |
|---|---|---|---|---|---|
| 1 | [**Abschluss: Prüfungen im echten Terminal (A1–A10)**](#abschluss-deine-prüfungen-im-echten-terminal) | du | — | XS–S (~20 min) | 4 |

Alles andere aus dieser Tabelle ist erledigt und archiviert (Nachtrag 4–9, s. u.), zuletzt Call Hierarchy
für Lua. Nur Rang 1 bleibt — deine Prüfungen im echten Fenster, die ich headless nicht abnehmen kann.

---

## Abschluss: deine Prüfungen im echten Terminal

Alles hier ist **committet, gemergt und in Tests oder headless gemessen** — aber nie mit echten Augen
in einem echten Fenster gesehen. Ich kann es nicht abnehmen: in meinem headless-Aufbau bleibt jeder
fzf-lua-Picker bei `0/0`, weil der RPC-Helfer, der fzf die Items füttert, ohne angehängte UI nichts
liefert (auch ein reines `fzf_exec({"a","b"})`), und das Terminal-Panel kann ich nur lesen. Die
Aufgaben sind voneinander unabhängig; die ersten beiden sind die wichtigsten.

**Aufwand XS–S gesamt (~20 min), Nutzen 4** — `lsa` ist ein täglicher Griff.

Test-Datei (beliebige `.ts`, mit tsserver):

```ts
import { readFileSync } from "fs";

export function total(a: number, b: number): number {
  const x = a + 1;
  const y = b * 2;
  const sum = x + y;
  return sum;
}
```

| # | Prüfung | So | Erwartet | Stand |
|---|---|---|---|---|
| A1 | `lsa` im echten fzf-Fenster | Cursor auf Zeile 1, `lsa` | Liste „Code actions>“ mit **Diff-Vorschau** rechts, keine fzf-lua-Warnung zu `register_ui_select`, gewählte Aktion wird angewendet | Picker öffnet headless ohne Warnung (ts_ls liefert 17 Aktionen); Einträge/Vorschau nicht gesehen |
| A2 | `gra` im Visual-Mode | Zeilen 4–6 mit `V2j` markieren, `gra` | Liste passt zur Selektion (u. a. „Extract function“) | Callback läuft im Visual-Mode, `code_action` liest die Selektion; nicht im echten Fenster gesehen |
| A3 | `l` im Visual-Mode wartet nicht mehr | `V`, dann `l`/`j` drücken, `vl`, `vjl` | Selektion wächst sofort, kein Hänger von `timeoutlen` | `mapcheck("l","x")` gemessen (Fix in `e6d716d`); nicht gefühlt |
| A4 | gitsigns-Hunk-Aktionen (Probe) | Zeile in einem geänderten Hunk, `lsa` | „Stage / Reset / Preview Hunk“ in der Liste; „Stage hunk“ stagt wirklich. Auch bei einer **gelöschten** Zeile am Dateianfang/-ende | Gegen echtes gitsigns geprüft; Randfälle per Test; nicht im Alltag |
| A5 | Peek: übernommener Buffer ist gelistet | `lsp` auf einem Symbol, im Float `<C-o>` / `<C-v>` / `<C-x>` / `<C-t>`; danach `:ls` und Tabline/Buffer-Picker | Der Buffer taucht auf | Per Test, Fix in `e6d716d`; nicht von Hand |
| A6 | Implementations-Marker (Probe) | `.ts`-Datei mit `interface Repo {…}` und einer Klasse, die es `implements`, ein paar Sekunden warten | Am Zeilenende des Interfaces `1 impl` (Comment-Farbe); nach einer Änderung an der Klasse aktualisiert es sich. Beim schnellen Tippen kein Ruckeln und **keine Marker auf der falschen Zeile**, auch wenn du im Insert-Mode über dem Interface eine Zeile tippst | Gemessen (siehe Archiv), Veraltungs-Fix `e50e10a` per Spec; nicht im echten Fenster gesehen |
| A7 | Winbar-Trenner | Lua-Datei in einer Funktion öffnen | Trenner `›` sauber (kein `â€º`) zwischen den Chips | Kodierung per Test abgesichert; nicht angesehen |
| A8 | Type Hierarchy im echten Fenster | In einer Go-Datei (gopls) einen Typ, der ein Interface implementiert: `lsh` bzw. `lsH`; danach dieselben Tasten in einer `.ts`-Datei | Go: Picker mit Sub-/Supertypen (gemessen: `Shape` → `Sq`). TS: die Klartext-Meldung, wer es kann, kein „No results“ nach Wartezeit | Beide Antworten gemessen; die Meldung nennt gopls jetzt (`8895cd8`, Spec-Test grün); nicht im echten Fenster gesehen |
| A9 | `gra` über **zwei** Hunks (neu) | In einer getrackten Datei zwei Zeilen an verschiedenen Stellen ändern, beide plus die Zeilen dazwischen mit `V` markieren, `gra`, „gitsigns: Stage hunk“ | Beide geänderten Zeilen sind danach gestaged (`git diff --cached`), unabhängig davon, wo der Cursor stand. Bei Cursor auf einer Zeile *in* einem mehrzeiligen Hunk stagt „Stage hunk“ den **ganzen** Hunk | Gegen echtes gitsigns headless bestätigt (Selektion über Zeilen 2–8, Cursor auf Zeile 9: beide Hunks gestaged; Cursor-Anfrage: ganzer 3-Zeilen-Hunk); nicht im echten fzf-Fenster |
| A10 | Restart, Stop und Winbar in einem Repo (neu) | In einer getrackten `.txt`-Datei: `:LspRestartHere`, `:LspStopHere`; in einer Lua-Datei `:LspRestartHere`; danach `lsa` auf einer geänderten Zeile | `.txt`: „No LSP clients to restart“ / „No LSP clients running“, **keine Winbar**. Lua: „Restarted N/N“ mit N = Anzahl echter Server (nicht N+1), die Winbar bleibt. „gitsigns: Stage hunk“ ist weiter in `lsa` | Headless mit echter Config bestätigt (Winbar leer auf `.txt`/`.json`, Restart/Stop-Meldungen, Force-Stop entfernt den Client und er kommt zurück); nicht von Hand |
| A11 | Call Hierarchy für Lua im echten Fenster (neu) | In einer Lua-Datei dieser Config (`documentation.nvim` mit `opts.callhierarchy = true` installiert, s. Nachtrag 9), Cursor auf einer Funktion, die eine andere aufruft: `lsc` | Kurze „scanning …“-Meldung beim ersten Mal im Projekt, danach das fzf-lua-Fenster mit den Aufrufern (bzw. „No results“, wenn wirklich keiner da ist) | Gegen echtes documentation.nvim und echtes lua_ls headless bestätigt: der Client hängt sich an, `textDocument/prepareCallHierarchy` und `callHierarchy/incomingCalls` liefern die echte Aufrufkette (`M.main` als Aufrufer von `M.helper`); `vim.lsp.buf.incoming_calls()`s Quickfix blieb headless leer (bekannte Grenze ohne echtes Fenster), das fzf-lua-Fenster selbst nicht gesehen |

Wenn A1 oder A2 scheitern: `code_actions.picker = "native"` in `init.lua` als Fallback und den
Befund melden.

---

## Nicht geprüft / Grenzen

- Aufwand- und Nutzen-Werte oben sind Schätzungen auf Basis deines Stacks (Lua, Markdown, TS/Astro; dazu
  C/C++, Java, Go für die Type Hierarchy).
- Der Implementations-Marker wurde nur gegen tsserver gemessen (synthetische Projekte mit 5/20/200
  Interfaces, zwei echte Projekte, dazu jetzt das echte `lib.dom.d.ts`, Nachtrag 8); tsserver-CPU und
  große Monorepos jenseits eines einzelnen 2,3-MB-`.d.ts` bleiben ungemessen; Go/Java/C# nicht.
- Die Type-Hierarchy-Zahlen sind jetzt erledigt (Nachtrag 4, 7). Die Call-Hierarchy-Grundlage (Client
  hängt sich an, liefert für `symbols.walk` einen Aufrufer) stammte aus einer früheren Sitzung und wurde
  **übernommen**; die Schicht selbst (Nachtrag 9) ist gegen echtes documentation.nvim und echtes lua_ls
  headless neu geprüft, inklusive der End-to-End-Antwort von `callHierarchy/incomingCalls`. Nur die
  Aussage zu `calls.lua:425–427` (Selbstkanten absichtlich weggelassen) habe ich im Quelltext nachgelesen,
  nicht erneut ausgeführt.
- Die vier Review-Fixes sind headless mit deiner echten Config und dem echten gitsigns bestätigt (Winbar,
  Restart/Stop, Force-Stop, Staging über eine Selektion), **nicht** in einem echten fzf-Fenster. Für den
  Marker (`e50e10a`) gibt es nur Specs mit einem Stub-Client, keinen Lauf gegen einen echten ts_ls.
- A3–A5 und A7 stammen aus dem Commit `e6d716d`; ich habe nur gelesen, was dort als gemessen bzw. getestet
  steht, nicht jede Aussage selbst neu gemessen.
- `dartls` ist weiterhin nicht gemessen (kein Server installiert).

---

