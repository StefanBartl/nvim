# lspsaga.nvim → lsp.nvim — offene Punkte

**Stand:** 2026-09-21

Alles Umgesetzte (10 Lücken + eigener Winbar-Breadcrumb, lspsaga entfernt, `code_actions.gitsigns` als
Probe an, `implement` an (gemessen), altes `lazy/lspsaga.nvim` gelöscht, lspsaga-Reste in der
Plugin-Roadmap markiert) ist archiviert in
`$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/lsp.nvim/Backlog/FEATURES/lspsaga-vs-lsp.nvim-Feature-Gap_ERLEDIGT.md`
(Code: `StefanBartl/lsp.nvim` `e49fdbe` + `e6d716d`, auf `main` und `origin/main`).
Hier steht nur, was noch zu tun oder zu entscheiden ist.

**Skalen:** Aufwand XS ≤ 30 min · S 30 min–2 h · M 2 h–1 Tag. Nutzen 1–5 (5 = täglich, spart
merklich Zeit). Beides Schätzungen, keine Messungen.

---

## Nach Aufwand / Nutzen

Reihenfolge = was man zuerst tun sollte (viel Nutzen für wenig Aufwand oben). Der Abschluss-Task steht
zuletzt und blockiert nichts: er braucht dein echtes Terminal und ist von 1 unabhängig.

| Rang | Punkt | Art | Aufwand | Nutzen |
|---|---|---|---|---|
| 1 | [Type Hierarchy an clangd/jdtls/dartls prüfen](#1-type-hierarchy-an-anderen-servern) | Prüfen | S | 1 |
| A | [**Abschluss: deine Prüfungen im echten Terminal**](#abschluss-deine-prüfungen-im-echten-terminal) | Prüfen (nur du) | XS–S | 4 |

1 erst, wenn ein solcher Server überhaupt im Alltag ist.

---

## Die Punkte

### 1. Type Hierarchy an anderen Servern

lua_ls, marksman und ts_ls liefern sie nicht (gemessen); `lsh`/`lsH` antworten dort mit einem Hinweis,
wer sie kann. Dass `clangd`, `jdtls` und `dartls` sie liefern, stammt aus Wissen über die Server, nicht
aus einer Abfrage (clangd ist über Mason installiert):

```lua
vim.lsp.get_clients()[1].server_capabilities.typeHierarchyProvider
```

- Erst relevant, wenn einer dieser Server tatsächlich im Alltag läuft. Sonst verwerfen.
- **Aufwand S (Server installieren), Nutzen 1.**

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

Wenn A1 oder A2 scheitern: `code_actions.picker = "native"` in `init.lua` als Fallback und den
Befund melden.

---

## Nicht geprüft / Grenzen

- Aufwand- und Nutzen-Werte oben sind Schätzungen auf Basis deines Stacks (Lua, Markdown, TS/Astro).
- Der Implementations-Marker wurde nur gegen tsserver gemessen (synthetische Projekte mit 5/20/200
  Interfaces, zwei echte Projekte); tsserver-CPU und große Monorepos nicht.
- A3–A5 und A7 stammen aus dem Commit `e6d716d`; ich habe nur gelesen, was dort als gemessen bzw. getestet
  steht, nicht jede Aussage selbst neu gemessen.
