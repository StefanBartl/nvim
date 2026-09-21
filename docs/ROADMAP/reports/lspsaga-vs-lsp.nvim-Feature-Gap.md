# lspsaga.nvim → lsp.nvim — offene Punkte

**Stand:** 2026-09-21 (nachgezogen nach der Type-/Call-Hierarchy-Messung)

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

**`StefanBartl/nvim`** — diese Config (Doku, Bindings, Schalter)

| SHA | Zeit | Inhalt |
|---|---|---|
| `e9a54ea64` | 11:00 | docs(roadmap): Feature-Gap-Report mit Aufwand/Nutzen angelegt |
| `f08f1edf2` | 16:28 | docs+chore: lspsaga ist aus dem Pack, Binding-Notizen und Reste bereinigt |
| `a2095deeb` | 17:15 | docs(bindings): UiSticky-Blatt ohne die veraltete lspsaga-Erwähnung (Nebenbei-Änderung) |
| `789e08161` | 17:36 | docs(reports): `lsa` ist Normal-only, die Selektion hat `gra` |
| `a4a140f49` | 21:08 | feat(lsp): gitsigns-Hunk-Aktionen in `lsa` als Probe an |
| `a106754b0` | 21:41 | feat(lsp): Implementations-Marker an; Report auf das Offene gekürzt |

Der Commit dieser Aktualisierung (Report + Archiv-Nachtrag) steht direkt darüber im `git log` der Config.
Andere Repos (documentation.nvim, ui.nvim, pickers.nvim, lib.nvim) hatten heute nur CI- und fremde
Arbeit; nichts davon gehört zu dieser Aufgabe.

## Wohin das Erledigte gewandert ist

Alles Umgesetzte (10 Lücken + eigener Winbar-Breadcrumb, lspsaga entfernt, `code_actions.gitsigns` als
Probe an, `implement` an (gemessen), altes `lazy/lspsaga.nvim` gelöscht, lspsaga-Reste in der
Plugin-Roadmap markiert) **und die Type-Hierarchy-Messung** liegt archiviert in
`$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/lsp.nvim/Backlog/FEATURES/lspsaga-vs-lsp.nvim-Feature-Gap_ERLEDIGT.md`
(dort „Nachtrag“ und „Nachtrag 2“). Hier steht nur, was noch zu tun oder zu entscheiden ist.

**Skalen:** Aufwand XS ≤ 30 min · S 30 min–2 h · M 2 h–1 Tag. Nutzen 1–5 (5 = täglich, spart
merklich Zeit). Beides Schätzungen, keine Messungen.

---

## Nach Aufwand / Nutzen

Sortierregel: Nutzen ÷ Aufwand; bei Gleichstand der größere Nutzen zuerst; Punkte, die an eine
Bedingung geknüpft sind, nach den unbedingten. Die Spalte „Wer“ sagt, ob ich es tun kann oder du.

| Rang | Punkt | Wer | Repo | Aufwand | Nutzen |
|---|---|---|---|---|---|
| 1 | [**Abschluss: Prüfungen im echten Terminal (A1–A8)**](#abschluss-deine-prüfungen-im-echten-terminal) | du | — | XS–S (~15 min) | 4 |
| 2 | [`lsh`/`lsH`-Meldung: gopls nennen, gemessene Server](#2-lshlsh-meldung-gopls-nennen) | ich | lsp.nvim | XS | 2 |
| 3 | [Call Hierarchy für Lua: dünne, lazy Schicht in lsp.nvim](#3-call-hierarchy-für-lua-dünne-lazy-schicht) | ich | lsp.nvim | S | 3 |
| 4 | [Selbstrekursion bei „outgoing“ zeigen?](#4-selbstrekursion-bei-outgoing) | Entscheidung | documentation.nvim | XS | 1 |
| 5 | [rust-analyzer installieren und Type Hierarchy messen](#5-rust-analyzer-messen) | du (Ja nötig) | — | XS | 1 |

Rang 1 kommt zuerst, weil es das Billigste und Nützlichste ist und alles andere Umgesetzte erst danach
„wirklich“ als abgenommen gilt. Rang 2 hängt teilweise an Rang 1 (A8 zeigt die Meldung im echten
Fenster). Rang 5 nur, wenn Rust im Alltag ist.

---

## Die Punkte

### 2. `lsh`/`lsH`-Meldung: gopls nennen

**Messstand (echte Anfragen an die installierten Server, letzte Sitzung, nicht neu gemessen):**

| Server | Type Hierarchy | Echte Antwort |
|---|---|---|
| clangd | ja | Supertypen von `Derived` = `Base` |
| gopls | **ja** | Subtypen von `Shape` = `Sq` |
| jdtls | ja | Supertypen von `Sq` = `Shape` |
| ts_ls, vtsls, lua_ls, zls, pylsp | nein | — |
| rust-analyzer | nicht gemessen | nicht installiert (nur die rustup-Verknüpfung ohne Komponente) |

Neu gegenüber der Annahme im Report: **gopls kann es.** Die Meldung von `lsh`/`lsH` nennt aber nur
„clangd, jdtls, dartls“ (aus Wissen über die Server, nicht gemessen — `dartls` ist weiter ungemessen).
Für deine Sprachen (C/C++, Java, Go) ist Type Hierarchy sinnvoll, für TS und Lua nicht, weil deren Server
sie nicht liefern. Die Tasten gibt es schon und sie prüfen vorher die Fähigkeit; es fehlt nur der Text.

Stellen:

- `lua/lsp/bindings/actions.lua:752` (Doc-Kommentar) und `:762` (Meldung)
- `lua/lsp/config/KEYMAPS.lua:469` (Kommentar)
- `docs/FEATURES/NAVIGATION.md:149`
- `TESTS/lsp/navigation_features_spec.lua:344` — prüft nur, dass die Meldung `clangd` enthält; bleibt
  grün, sollte aber um `gopls` ergänzt werden

Vorschlag: „clangd, gopls, jdtls“ als gemessen nennen, `dartls` mit dem Zusatz „laut Server-Doku“ oder
streichen. Danach `lsh`/`lsH` einmal in einer Go-Datei im echten Fenster sehen (= A8).

**Aufwand XS, Nutzen 2.**

---

### 3. Call Hierarchy für Lua: dünne, lazy Schicht

**Ausgangslage.** lua_ls hat keine Call Hierarchy. documentation.nvim kann sie mit `opts.callhierarchy = true`:
ein zweiter, schmaler LSP-Client in-process, gestützt auf die Aufrufkarte aus `install()`
(`docs/call_hierarchy.md`). In deiner Config ist das **aus** (`grep callhierarchy lua/` ohne Treffer), und
documentation.nvim lädt nur auf Kommandos (`cmd = { "DocMap", … }`).

**Gemessen (letzte Sitzung, headless):**

- Der Client hängt sich an, meldet `supports_method("textDocument/prepareCallHierarchy") = true`, und
  fzf-lua behandelt ihn wie einen normalen Server.
- In `lsp.nvim/lua/lsp` liefert er für `symbols.walk` genau einen Aufrufer, `M.candidates` in
  `implement.lua` — stimmt mit `rg` überein.
- **Kosten:** `install()` brauchte ~2 s (Scan). Beim Start jedes Lua-Buffers spürbar.
- **Grenze:** er deckt nur das gescannte `source`-Verzeichnis ab, also ein Plugin oder eine Config auf einmal.

**Entschiedene Architektur:** Client und Aufrufkarte **bleiben in documentation.nvim.** Grund (deine
Frage, und dein Verständnis stimmt): der Client ist ohne documentation.nvim gar nicht lauffähig, weil er
auf dessen IR aus dem Modul-Scan sitzt. Nach lsp.nvim zu verschieben hieße, documentation.nvim trotzdem zu
brauchen oder dessen Scanner zu kopieren — beides schlechter. Umgekehrt ist es sauber: lsp.nvim bekommt
nur eine **kleine, optionale Schicht**, die documentation.nvim per `pcall` anstößt.

**Entwurf der Schicht:**

1. Erster `lsc`/`lsC` in einem Lua-Buffer, für den kein Client `prepareCallHierarchy` beantwortet.
2. `pcall(require, "documentation")`; ist es nicht da, eine Klartext-Meldung („Call Hierarchy für Lua
   braucht documentation.nvim mit `opts.callhierarchy`“) statt „No results“.
3. Ist es da: documentation.nvim laden (es ist lazy — `require("lazy").load({ plugins = … })` bzw. der
   Weg, den seine Doku vorsieht), `install()` mit `callhierarchy = true` für die Wurzel des Buffers, warten,
   dann den Picker öffnen. Die ~2 s fallen **einmal pro Projekt** an, nicht beim Start.
4. Kein Eingriff, solange kein Lua-Buffer `lsc`/`lsC` drückt.

**Offen dabei (vor dem Bauen klären):**

- **Welche Wurzel als `source`?** Genau eine Config/ein Plugin wird gescannt. `lua/`-Wurzel des Buffers vs.
  Git-Root vs. das vorhandene Root-Erkennen in lsp.nvim. (In WKDBooks liegt
  `lsp.nvim/NOTES/HANDOVER-headless-root-detection.md`; ich habe sie nicht gelesen, ob sie hier passt, ist
  ungeprüft.)
- Was, wenn der Buffer in einem anderen Plugin liegt als das zuvor Gescannte (zweite `install()`, Wechsel
  des Handles)?
- **Test mit documentation.nvim-Stub** in `lsp.nvim/TESTS/`: lsp.nvims CI holt documentation.nvim nicht
  (kein Treffer in `.github/workflows/`); mit einem Stub bekommt die CI keine echte Abhängigkeit.

**Aufwand S, Nutzen 3** — nur für Lua, dort aber dein Hauptfall.

---

### 4. Selbstrekursion bei „outgoing“

In der Messung fehlte bei `symbols.walk` die Selbstrekursion unter „outgoing“ (0). **Das ist Absicht,
nicht Fehler:** `documentation.nvim/lua/documentation/core/calls.lua:425–427` lässt Selbstkanten beim
Aufbau des Graphen weg („Direct recursion … tells the reader nothing a self-loop on a diagram would not
obscure“, und `:516` verlässt sich darauf für die Zyklenfreiheit). Diese Regel gilt für das Diagramm.

Offen ist nur, ob die **LSP-Antwort** die Rekursion trotzdem zeigen soll (clangd/gopls tun es). Das wäre
ein Sonderweg im Client, der den Guard von `:516` nicht verletzen darf.

- Empfehlung: so lassen. Wer eine Rekursion sucht, findet sie im Quelltext schneller als in der Hierarchie.
- **Aufwand XS (nur Entscheidung), Nutzen 1.** Verwerfen ist legitim.

---

### 5. rust-analyzer messen

rust-analyzer ist nicht installiert, nur die rustup-Verknüpfung ohne Komponente. Ob er Type Hierarchy
liefert, ist deshalb ungemessen. Installieren wäre:

```bash
rustup component add rust-analyzer
```

Das ändere ich nur mit deinem Ja. Nur relevant, wenn Rust im Alltag ist — sonst verwerfen.

**Aufwand XS, Nutzen 1.**

---

## Abschluss: deine Prüfungen im echten Terminal

Alles hier ist **committet, gemergt und in Tests oder headless gemessen** — aber nie mit echten Augen
in einem echten Fenster gesehen. Ich kann es nicht abnehmen: in meinem headless-Aufbau bleibt jeder
fzf-lua-Picker bei `0/0`, weil der RPC-Helfer, der fzf die Items füttert, ohne angehängte UI nichts
liefert (auch ein reines `fzf_exec({"a","b"})`), und das Terminal-Panel kann ich nur lesen. Die
Aufgaben sind voneinander unabhängig; die ersten beiden sind die wichtigsten.

**Aufwand XS–S gesamt (~15 min), Nutzen 4** — `lsa` ist ein täglicher Griff.

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
| A6 | Implementations-Marker (Probe) | `.ts`-Datei mit `interface Repo {…}` und einer Klasse, die es `implements`, ein paar Sekunden warten | Am Zeilenende des Interfaces `1 impl` (Comment-Farbe); nach einer Änderung an der Klasse aktualisiert es sich. Beim schnellen Tippen kein Ruckeln | Gemessen (siehe Archiv): Kosten vernachlässigbar, an echtem ts_ls gezeichnet; nicht im echten Fenster gesehen |
| A7 | Winbar-Trenner | Lua-Datei in einer Funktion öffnen | Trenner `›` sauber (kein `â€º`) zwischen den Chips | Kodierung per Test abgesichert; nicht angesehen |
| A8 | Type Hierarchy im echten Fenster (neu) | In einer Go-Datei (gopls) einen Typ, der ein Interface implementiert: `lsh` bzw. `lsH`; danach dieselben Tasten in einer `.ts`-Datei | Go: Picker mit Sub-/Supertypen (gemessen: `Shape` → `Sq`). TS: die Klartext-Meldung, wer es kann, kein „No results“ nach Wartezeit | Beide Antworten gemessen; die Meldung nennt gopls noch nicht (siehe Rang 2); nicht im echten Fenster gesehen |

Wenn A1 oder A2 scheitern: `code_actions.picker = "native"` in `init.lua` als Fallback und den
Befund melden.

---

## Nicht geprüft / Grenzen

- Aufwand- und Nutzen-Werte oben sind Schätzungen auf Basis deines Stacks (Lua, Markdown, TS/Astro; dazu
  C/C++, Java, Go für die Type Hierarchy).
- Der Implementations-Marker wurde nur gegen tsserver gemessen (synthetische Projekte mit 5/20/200
  Interfaces, zwei echte Projekte); tsserver-CPU und große Monorepos nicht; Go/Java/C# nicht.
- Die Type-/Call-Hierarchy-Zahlen in Rang 2–4 stammen aus der letzten Sitzung, die vor dem Schreiben
  dieses Dokuments endete. Ich habe sie hier **übernommen, nicht neu gemessen**; nur die Aussage zu
  `calls.lua:425–427` (Selbstkanten absichtlich weggelassen) habe ich im Quelltext nachgelesen.
- A3–A5 und A7 stammen aus dem Commit `e6d716d`; ich habe nur gelesen, was dort als gemessen bzw. getestet
  steht, nicht jede Aussage selbst neu gemessen.
- `dartls` ist weiterhin nicht gemessen (kein Server installiert).
