# Modifier-Keymaps — Konzept

Stand: 2026-08-29. Status: **umgesetzt** in
`lib.nvim/lua/lib/nvim/bindings/keymap/modifier/` — ausdrücklich **nicht** in
filetree.nvim. Aktivierung:

```lua
require("lib.nvim.bindings.keymap.modifier").setup({ experimental = true })
```

Was gegenüber diesem Konzept anders kam, steht in §7.

Ursprung: ROADMAP.md-Bullet aus Commit `4388c640` (2026-08-26, inzwischen aus
ROADMAP.md entfernt). Dort noch am filetree-Beispiel formuliert, mit dem
Zusatz "aber wenn es möglich wäre, das generell für alle Mappings in allen
Plugins zu setzen, wäre das cool".

---

## 1. Was gebaut werden soll

Zwei Tasten, die **vor** einem beliebigen anderen Mapping gedrückt werden und
dessen *Ergebnis* abgreifen, statt es nur laufen zu lassen:

| Modifier | Wirkung |
| --- | --- |
| `\` | Mapping ausführen, Ergebnis-String **in die Zwischenablage** |
| `\\` | Mapping ausführen, Ergebnis-String **in die Zwischenablage + am Cursor einfügen** |

Beispiel aus der ursprünglichen Notiz: `\[a` statt `[a` in filetree.nvim →
der absolute Pfad der Node landet in der Zwischenablage. `?[a` → zusätzlich
an der Cursorposition eingefügt.

Das filetree-Beispiel ist bewusst als schlechtes Beispiel markiert (der Cursor
steht dabei im Tree, Einfügen ist dort sinnlos, und viele filetree-Mappings
kopieren ohnehin schon). Es beschreibt die *Form*, nicht den Anwendungsfall.
Der Anwendungsfall ist die Verallgemeinerung: **jedes** Mapping in **jedem**
Plugin.

Verwandt, aber getrennt: [`lib.nvim.lastcmd`](../../NOTES/PersonelPlugins/BINDINGS/Keymaps/lib.nvim.md)
ist die dritte Taste derselben Familie — Keymaps, die auf *andere* Keymaps
wirken statt auf den Buffer. Gemeinsamer Name dafür: **Super-Keymaps**.

---

## 2. Der harte Teil: Keymaps haben kein Ergebnis

Die naheliegende Formulierung — "fang das Resultat ab, wenn es ein String ist"
— unterstellt, dass Mappings Resultate zurückgeben. Tun sie nicht. Vim
verwirft den Rückgabewert eines Lua-`rhs` ersatzlos; nur mit `expr = true`
wird er überhaupt gelesen, und dann als *Tastenfolge*, nicht als Datum.

Ein Wrapper um alle Mappings zu legen (der in der Notiz angedachte Weg) löst
das nicht, sondern verschiebt es: der Wrapper kann nur weitergeben, was die
gewrappte Funktion zurückgibt — bei den meisten bestehenden Mappings ist das
`nil`.

**Konsequenz für das Design:** es braucht eine gestufte Auflösung, die von
"kooperiert vollständig" bis "kooperiert gar nicht" reicht, statt einer
einzigen Mechanik.

---

## 3. Mechanik — verifiziert, nicht vermutet

Kein globales Wrappen. Der Modifier ist selbst ein Mapping, das die
*nachfolgenden* Tasten liest und auflöst:

```lua
-- inside the `\` mapping's rhs
local seq = ""
for _ = 1, 8 do
  seq = seq .. vim.fn.keytrans(vim.fn.getcharstr())
  local map = vim.fn.maparg(seq, "n", false, true)
  if type(map) == "table" and next(map) ~= nil then
    return map          -- exact match
  end
  if vim.fn.mapcheck(seq, "n") == "" then
    return nil          -- dead end, nothing is mapped there
  end
end                     -- else: still a prefix, keep reading
```

Das ist dieselbe Auflösungslogik, die `lib.nvim.lastcmd` schon benutzt
(`maparg` = exakt, `mapcheck` = noch Präfix), hier nur über `getcharstr()`
statt über `vim.on_key`. Multi-Key-Mappings wie `[a` funktionieren damit ohne
Sonderfall.

Ist das Mapping aufgelöst, liefert `map.callback` die Lua-Funktion — direkt
aufrufbar, Rückgabewert erfassbar.

### Die vier Tiers

Am 2026-08-29 mit einem Prototyp gegen drei realistische Mapping-Formen
gemessen (Probe-Ergebnis wörtlich):

```
seq=[a   tier=return value             result=C:/repos/lib.nvim/init.lua
seq=[b   tier=observed + register      result=C:/repos/filetree.nvim/lua/node.lua
seq=[c   tier=no capturable result     result=nil
seq=[z   -> unresolved
```

| Tier | Quelle des Strings | Kooperation nötig? |
| --- | --- | --- |
| 1 — deklariert | `keymap.register()`-Eintrag mit eigener `result`-Funktion | ja, einmalig pro Action |
| 2 — Rückgabewert | `map.callback()` gibt einen String zurück | ja, Mapping muss `return` haben |
| 3 — beobachtet | Register `+`/`*`/`"` vor und nach dem Lauf vergleichen | **nein** |
| 4 — ehrlich scheitern | nichts davon greift → Meldung, Mapping lief trotzdem | — |

**Tier 3 ist der eigentliche Fund.** Genau die Mapping-Form, die die
ursprüngliche Notiz als problematisch beschreibt ("viele Mappings kopieren
das Resultat sowieso schon in die Zwischenablage"), ist dadurch *ohne jede
Kooperation* abgreifbar: was das Mapping in die Zwischenablage schreibt, ist
das Ergebnis. Das deckt filetree.nvims `[a`-Familie vollständig ab, ohne dass
filetree.nvim eine Zeile ändern muss.

Tier 4 ist keine Niederlage, sondern Vertrag: `\[c` auf ein Mapping, das nur
den Buffer ändert, führt das Mapping normal aus und sagt, dass es nichts zu
kopieren gab. Verifiziert: der Buffer wurde im Test korrekt mutiert.

---

## 4. Entschieden: `\\` statt `?` — `?` schattet die Rückwärtssuche

`\` ist frei — `mapleader` ist in dieser Config `" "`, der Vim-Default `\` als
Leader also ungenutzt. Global unbelegt, geprüft.

`?` ist **nicht** frei: es ist Vims Rückwärtssuche. Ein globales `?`-Mapping
nimmt die weg. (Die `?`-Vorkommen in `drift.lua`/`case/ui.lua` sind
buffer-lokale Hilfe-Tasten in Floats und stören nicht.)

Die ursprüngliche Notiz war an dieser Stelle selbst unsicher ("`ß[a` oder wenn
`ß` nicht gut geht dann z.B. `?[q`"). Drei Optionen:

| Variante | Kosten |
| --- | --- |
| **`\` + `\\`** (empfohlen) | eine reservierte Taste statt zwei; `\\` wartet `timeoutlen` |
| `\` + `?` | Rückwärtssuche weg (Ersatz nötig, z.B. `g?`) |
| `\` + `<M-\>` | keine Kollision, aber schlechter zu tippen |

Empfehlung `\` + `\\`: die ganze Familie lebt unter *einem* reservierten
Präfix, nichts Eingebautes geht verloren, und ein dritter Modifier später
(`\i` = nur einfügen, `\y` = in ein benanntes Register) kostet keine weitere
Taste. Der `timeoutlen`-Nachteil trifft nur `\\`, nicht `\`.

**Entschieden am 2026-08-29: `\` + `\\`.** Beide Keys sind konfigurierbar
(`opts.copy` / `opts.insert`), die Entscheidung legt nur den Default fest.

---

## 5. Zusatzfeature aus der Notiz: Ziel-Prompt

Aus `4388c640` wörtlich: wenn der Insert-Modifier ausgelöst wird und der
Cursor **nicht** in einem beschreibbaren Buffer steht (genau der filetree-Fall),
soll gefragt werden, in welchen offenen Buffer und in welche Zeilennummer
eingefügt wird.

Bausteine dafür existieren in lib.nvim bereits:

- `lib.nvim.buffer.context` — `is_normal` / `is_processable` beantworten
  "beschreibbar?" ohne eigene Heuristik.
- `lib.nvim.ui.kit.picker` — Buffer-Auswahl.
- `lib.nvim.ui.kit.input` — Zeilennummer.

Kein neuer UI-Code nötig.

---

## 6. Abgrenzung

- **Kein globales Wrappen.** Alle Mappings beim Start umzuhängen wäre teuer,
  bricht bei später registrierten Mappings, verändert `maparg` für alle
  anderen und macht `expr`/buffer-lokale Mappings kaputt.
- **Nicht in filetree.nvim.** Das war nur das Beispiel. Der Ort ist lib.nvim,
  damit es für jedes Plugin gilt — inklusive fremder.
- **Nicht `lib.nvim.dotrepeat`, nicht `lib.nvim.lastcmd`.** Drei verschiedene
  Werkzeuge: `dotrepeat` macht *einen* Callback `.`-wiederholbar, `lastcmd`
  wiederholt den zuletzt gelaufenen Befehl, `modifier` greift das *Ergebnis*
  des nächsten Befehls ab.

## 7. Was bei der Umsetzung anders kam

Entschieden und gebaut am 2026-08-29:

- **`\\` statt `?`** (deine Entscheidung, Variante aus §4). Rückwärtssuche
  bleibt erhalten, die ganze Familie liegt unter einem Präfix.
- **Tier 3 greift auch bei String-rhs-Mappings.** Im Konzept implizit auf
  Lua-Callbacks bezogen — tatsächlich funktioniert es auch für Mappings ohne
  jeden Callback, weil die Ausführung dann über `feedkeys(..., "mx")` läuft und
  die Register-Beobachtung davon unabhängig ist. Deckt also auch alte
  Vimscript-Mappings ab.
- **`expr`-Mappings brauchten einen Sonderfall.** Deren Rückgabewert ist eine
  *Tastenfolge*, kein Ergebnis. Würde man sie wie einen normalen Callback
  aufrufen, käme `ix<Esc>` als vermeintliches "Ergebnis" in der
  Zwischenablage an. Sie werden deshalb gefüttert statt aufgerufen.
- **Tier 1 als eigenes `declare(mode, lhs, fn)`** statt über
  `keymap.register()`. Entkoppelt: fremde Plugins lassen sich deklarieren,
  ohne deren Registrierung anzufassen. Die Anbindung an `register()` bleibt
  möglich, war aber nicht nötig.
- **Nur Normal-Mode.** Die Visual-Frage aus §8 ist damit bewusst offen und
  nicht halb beantwortet.
- **Kein Count.** `\3[a` reicht die 3 nicht an das Ziel durch.

Ein Testfehler ist dabei aufgefallen und behoben: die Tier-3-Assertions prüften
zuerst das `+`-Register, das aber das *Ziel-Mapping selbst* schreibt — der Test
wäre auch ohne jede Capture-Logik grün gewesen. Die Testziele schreiben jetzt
das unbenannte Register, geprüft wird `+`; damit kann nur der Modifier den Wert
dorthin gebracht haben. Gegenprobe: mit deaktiviertem Tier 3 schlägt der Spec
präzise fehl.

## 8. Offene Punkte

- Visual-Mode: soll `\` dort dieselbe Bedeutung haben? (Selektion als
  Ergebnis-String?)
- which-key: `\` als Gruppe anzeigen ist sinnlos, solange das Ziel jedes
  beliebige Mapping sein kann. Vermutlich bewusst keine which-key-Anbindung.
- `:Bindings`-Integration: Tier-1-Registrierungen wären im Keymap-Registry
  sichtbar zu machen, damit `:Bindings browse` zeigt, welche Actions ein
  deklariertes Ergebnis haben.
- Tier 3 bei Mappings, die *mehrere* Register anfassen — welches gewinnt?
