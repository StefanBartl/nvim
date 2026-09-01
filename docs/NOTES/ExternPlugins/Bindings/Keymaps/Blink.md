# blink.cmp — Keymaps

`blink.cmp` ist die aktive Completion-Engine dieser Config. Installiert und
mit einem Preset versorgt wird sie **nicht hier**, sondern von `lsp.nvim`
(`lua/lsp/pack/completion_blink.lua`); diese Config steuert nur einen
`opts`-Fragment-Spec bei, den Lazy darüberlegt
([lua/plugins/completion.lua](../../../../../lua/plugins/completion.lua)).

Warum blink und nicht `nvim-cmp`: `vim.g.lsp_nvim.pack.completion` steht auf
seinem Default `"blink"` (so seit 2026-08-24) — diese Config setzt die Variable
nirgends. Der `nvim-cmp`-Spec resolved damit auf `enabled = false` und ist
nicht einmal installiert. Die Accept-/Dismiss-Keys sind trotzdem **für beide
Engines** definiert, siehe [unten](#wenn-stattdessen-nvim-cmp-aktiv-ist).

---

## Insert-Mode

Preset ist `enter` (aus `vim.g.lsp_nvim.pack.completion_accept`, Default
`"cr"`). `[default]` = aus dem Preset, `[custom]` = in
`plugins/completion.lua` überschrieben/ergänzt.

| Mapping | blink-Command | Aktion | Status |
|---|---|---|---|
| `<CR>` | `accept`, `fallback` | Nimmt den **markierten** Eintrag an — durch `completion.list.selection.preselect` (blink-Default) ist das ab dem Öffnen des Menüs der erste Vorschlag | [custom] |
| `<C-y>` | `select_and_accept`, `fallback` | Wie `<CR>`, wählt aber vorher den obersten Eintrag, falls gar nichts markiert ist | [custom] |
| `<C-x>` | `cancel`, `fallback` | Schließt die Liste und nimmt die `auto_insert`-Vorschau zurück | [custom] |
| `<C-e>` | `cancel`, `fallback` | Dasselbe wie `<C-x>`; blinks eigener Key, bleibt erhalten | [default] |
| `<Tab>` | `select_next`, `snippet_forward`, `fallback` | Nächster Eintrag, sonst Snippet-Sprung vorwärts | [custom] |
| `<S-Tab>` | `select_prev`, `snippet_backward`, `fallback` | Voriger Eintrag, sonst Snippet-Sprung rückwärts | [custom] |
| `<C-n>` / `<C-p>` | `select_next` / `select_prev`, `fallback_to_mappings` | Nächster/voriger Eintrag | [default] |
| `<Down>` / `<Up>` | `select_next` / `select_prev`, `fallback` | Nächster/voriger Eintrag | [default] |
| `<C-space>` | `show`, `show_documentation`, `hide_documentation` | Menü erzwingen, dann Doku-Fenster auf/zu | [default] |
| `<C-b>` / `<C-f>` | `scroll_documentation_up` / `_down` | Doku-Fenster scrollen | [default] |
| `<C-k>` | `show_signature`, `hide_signature`, `fallback` | Signature-Help auf/zu | [default] |

Keines der `[custom]`-Mappings ersetzt einen Preset-Key: `<CR>` wird auf
denselben Wert gepinnt, den `enter` ohnehin liefert, `<C-y>`/`<C-x>` sind
Ergänzungen.

### Warum das die anderen Belegungen nicht frisst

Jede Command-Liste endet auf `fallback`. blinks Commands geben `false` zurück,
wenn kein Menü offen ist — die Liste fällt dann auf `fallback` durch, und das
führt das erste **nicht-blink**-Mapping desselben Keys aus (buffer-lokal vor
global) bzw. reicht den rohen Key durch, wenn es keines gibt. Außerhalb eines
offenen Completion-Menüs ist hier also nichts belegt:

- `<CR>` erreicht weiter das Enter-Mapping von `nvim-autopairs`,
- `<C-y>` bleibt „Zeichen aus der Zeile darüber kopieren" (`i_CTRL-Y`),
- `<C-x>` bleibt Vims eigener ins-completion-Präfix (`i_CTRL-X`).

Gemessen am 2026-09-01 mit einer minimalen headless-Instanz (blink solo, plus
je einem Fremd-Mapping auf `<CR>`/`<C-y>`): bei geschlossenem Menü liefert der
`<C-x>`-Callback `"\24"` (= roher `<C-x>`), `<C-y>` und `<CR>` liefern den
Rumpf des jeweiligen Fremd-Mappings.

Dazu kommt, dass die Maps **buffer-lokal** und erst auf `InsertEnter` gesetzt
werden.

### Wo blink gar nicht erst greift

`blink.cmp.config.enabled()` kombiniert zwei Bedingungen:

- blinks eigene: `buftype ~= "prompt"` und `vim.b.completion ~= false`;
- die aus `lsp.nvim`: `buftype ~= "nofile"`, mit Ausnahme von `dap-repl` und
  `dapui_*`.

Damit sind die Telescope-Prompts außen vor — z. B. das Harpoon-Menü, das im
Insert-Mode selbst `<C-x>` (Split) und `<CR>` (Öffnen) belegt
([Harpoon.md](Harpoon.md)) — und ebenso die Floating-Inputs aus
`lib.nvim.ui.kit`, wo ein akzeptierter Fuzzy-Treffer statt des getippten
Dateinamens ein echter Bug wäre.

---

## Cmdline

Eigenes Preset (`cmdline`), von den Insert-Keys unberührt: `opts.keymap` gilt
nur für den Default-Modus, und `cmdline.keymap.preset` steht nicht auf
`"inherit"`. `<C-x>` ist dort also nicht belegt, `<C-y>` accepted (Preset),
`<Tab>` zeigt/akzeptiert.

---

## Bekannte Eigenheit: `<C-n>` / `<C-p>` [default]

Beide nutzen `fallback_to_mappings` statt `fallback` — bei geschlossenem Menü
wird also nur ein evtl. vorhandenes Fremd-Mapping ausgeführt, der rohe Key
aber **nicht** durchgereicht. Diese Config mappt im Insert-Mode weder `<C-n>`
noch `<C-p>`, folglich ist Vims eingebaute Keyword-Completion
(`i_CTRL-N`/`i_CTRL-P`) dort wirkungslos. Das ist blinks Absicht (die native
Popup-Completion soll dem eigenen Menü nicht in die Quere kommen), kein
Fehler dieser Config — hier nur notiert, weil es dieselbe Frage betrifft.

---

## Wenn stattdessen `nvim-cmp` aktiv ist

`vim.g.lsp_nvim.pack.completion = "cmp"` dreht die beiden `enabled`-Flags um:
lsp.nvims blink-Spec geht aus, und der `nvim-cmp`-Spec — den **NvChad**
mitbringt (`nvchad.plugins`, via `{ import = "nvchad.plugins" }` in
[init.lua](../../../../../init.lua)) — geht an. Damit die drei Keys diesen
Wechsel überleben, definiert `plugins/completion.lua` sie auch in cmps
Vokabular:

| Mapping | cmp-Helper | entspricht blink | Status |
|---|---|---|---|
| `<CR>` | `cmp.mapping.confirm({ behavior = Insert, select = false })` | `accept` | [custom] |
| `<C-y>` | `cmp.mapping.confirm({ behavior = Insert, select = true })` | `select_and_accept` | [custom] |
| `<C-x>` | `cmp.mapping.abort()` | `cancel` | [custom] |

Den Rest der Mapping-Tabelle liefert dann `nvchad.configs.cmp`: `<C-n>`/`<C-p>`
(Auswahl), `<C-d>`/`<C-f>` (Doku scrollen), `<C-Space>` (`complete()`), `<C-e>`
(`close()` — anders als `<C-x>`, das mit `abort()` auch die Vorschau
zurücknimmt) sowie `<Tab>`/`<S-Tab>` mit LuaSnip-Fallback. `<CR>` steht dort
schon auf `confirm{ select = true }`; die Definition hier überschreibt das
bewusst auf `select = false`, damit Enter unter cmp dasselbe tut wie unter
blink: den *markierten* Eintrag nehmen, sonst durchfallen.

Die „nur bei offenem Menü"-Garantie ist dieselbe: `cmp.mapping.confirm` und
`cmp.mapping.abort` rufen intern `fallback()`, wenn nichts zu bestätigen bzw.
abzubrechen ist, und cmps `fallback` führt die Belegung aus, die der Key vor
cmp hatte.

**Nicht verifiziert.** Diese drei Zeilen sind der einzige Teil der Datei, der
nie gelaufen ist — ohne installiertes cmp gibt es nichts, wogegen man sie
ausführen könnte. Sie benutzen deshalb ausschließlich cmps dokumentierte
Mapping-Helper statt selbstgebauter Closures. Wer den Schalter umlegt, sollte
die drei Keys einmal von Hand gegenprüfen.
