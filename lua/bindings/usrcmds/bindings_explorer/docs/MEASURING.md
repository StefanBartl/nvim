# bindings-explorer — Messen, und was dabei schiefgeht

`FEATURES.md` beschreibt, was die Routen tun. Diese Datei beschreibt, wie man
sie **misst**, und trägt die Zahlen, auf die sich Entscheidungen berufen haben.

Sie existiert, weil dieselben fünf Fehler in drei aufeinanderfolgenden
Sessions gemacht wurden — zwei davon zweimal. Jeder einzelne erzeugt Zahlen,
die plausibel aussehen und falsch sind, und aus zwei davon wurde bereits in
geschriebene Berichte zitiert.

---

## Table of content

- [Der eine Satz, der am meisten spart](#der-eine-satz-der-am-meisten-spart)
- [Die fünf Fallen](#die-fünf-fallen)
- [Ein Mess-Skript, das stimmt](#ein-mess-skript-das-stimmt)
- [Gemessene Stände](#gemessene-stände)
- [Was ein Befund nicht ist](#was-ein-befund-nicht-ist)

---

## Der eine Satz, der am meisten spart

**Interaktiv gemessen ist richtig, headless gemessen ist es erst nach drei
Vorkehrungen.** Wer eine Zahl nur einmal braucht, tippt `:Bindings check` im
laufenden Editor und ist fertig. Alles unten gilt für den headless-Fall, den
man nimmt, weil er reproduzierbar und skriptbar ist.

---

## Die fünf Fallen

### 1. Ohne `UIReady` misst man einen halb gestarteten Editor

Diese Config registriert ihre Commands und Keymaps in
`startup.on("UIReady", …)`, und `UIReady` ist VimEnter plus ein
`vim.schedule`. Ein `nvim --headless -c "luafile …"` führt sein Skript
**vor** VimEnter aus: `bindings.usrcmds` und `bindings.mappings` werden nie
geladen, und alles, was sie gebunden hätten, meldet der Check als
dokumentiert-und-nicht-registriert.

Gemessen am 2026-09-02, derselbe Lauf ohne und mit geladener Phase:

| | Phase ausstehend | Phase gelaufen |
| --- | ---: | ---: |
| Befunde gesamt | 200 | **111** |
| `keymap-not-live` | 137 | **52** |
| `usercmd-not-live` | 9 | **1** |

**89 der 200 Befunde waren die Messung, nicht der Korpus.** Interaktiv sieht
man das nie — wer `:Bindings check` im Editor aufruft, hat die Phase längst
hinter sich. Deshalb ist es unbemerkt in jeden headless geschriebenen Bericht
gewandert, aus dem danach zitiert wurde.

Seither sagen `check` und `report` es selbst: `drift.describe` setzt die
Warnung ganz nach oben, `report.render` in den Lauf-Kopf und als Blockquote
über die Zahlen, die sie entwertet. Beide fragen `startup.pending()` per
`pcall`. Vor jeder eigenen Messung:

```lua
require("bindings.usrcmds")
require("bindings.mappings").setup()
local st = require("startup")
for _, m in ipairs(st.marks) do
  if m.label == "usrcmds" or m.label == "mappings" then m.at = m.at or st.elapsed() end
end
```

### 2. `vim.loader` cacht Modulname → Datei auf den Haupt-Checkout

Wer Code aus einem Worktree messen will: **ein `rtp`-Prepend reicht nicht**,
und `vim.loader.reset()` auch nicht — danach kommt weiter die Kopie des
Haupt-Checkouts. Nur über `package.preload` + `loadfile`:

```lua
for _, n in ipairs({ "config", "records", "source", "repo", "drift", "report", "status" }) do
  local mod = "bindings.usrcmds.bindings_explorer." .. n
  package.loaded[mod] = nil
  package.preload[mod] = assert(loadfile(WT .. "/lua/bindings/usrcmds/bindings_explorer/" .. n .. ".lua"))
end
```

### 3. Der Korpus kommt aus `stdpath("config")`, nicht aus dem Worktree

`docs/NOTES/**` wird über `vim.fn.stdpath("config")` gelesen, also aus dem
**Haupt-Checkout**. Solange Doku-Änderungen nur im Worktree liegen, misst ein
`:Bindings check` den alten Stand. Zwei Auswege: `config.roots` im Messskript
umbiegen, oder vorher pushen und im Haupt-Checkout pullen. Das Zweite ist
weniger fehleranfällig und der Grund, warum die Doku-Commits dieser Arbeit
vor der jeweiligen Gegenprobe liegen.

### 4. `(cond) and nil or x` kollabiert in Lua — und hat schon zweimal zugeschlagen

`and nil` lässt den ganzen Ausdruck in den `or`-Zweig fallen. Beide Male sah
das Ergebnis nach einem Befund aus und war ein Messfehler:

* Im Produktivcode erzeugte `(scope == "all") and nil or scope` den Wert
  `corpus_scope = "all"`, der auf keine Korpus-Wurzel passt — die
  dokumentierte Seite meldete still null Befunde, **54 statt 432**.
* In einem Probe-Skript machte `dir and repo.mentions(dir, name) or nil` aus
  jedem sauberen „nicht gefunden" ein „konnte nicht nachsehen" und ließ 15
  von 16 Commands wie ungeprüft aussehen.

Immer ein explizites `if`. Der Produktivcode trägt an beiden Stellen einen
Kommentar, der das erklärt.

### 5. `f.notation` ist die Vergleichsform, nicht die Anzeigeform

`keymap-not-live`-Befunde tragen die **rohe Byte-Form**, die `normalize_lhs`
erzeugt hat — das ist ihr Zweck, `nvim_get_keymap`s `.lhsraw` wird dagegen
verglichen. Ein eigener Dump, der `f.notation` direkt druckt, liest rohe
Termcodes (`\x80kD`, `<80><fc>^H-`). `drift.describe` rendert korrekt über
`vim.fn.keytrans`; ein Messskript muss dasselbe tun. Einmal beinahe als
Werkzeugfehler gemeldet, war keiner.

---

## Ein Mess-Skript, das stimmt

Die Reihenfolge ist nicht beliebig — Falle 2 muss vor jedem `require` der
Module stehen, Falle 1 vor dem `drift.check`.

```lua
-- 1. Worktree-Code, falls gemessen werden soll, was noch nicht gepusht ist.
-- 2. UIReady nachholen.
-- 3. drift.check, Zeit nehmen, nach `kind` zählen.
-- 4. Beim Ausgeben von `notation` durch vim.fn.keytrans schicken.
```

Zwei Bequemlichkeiten, die es inzwischen gibt und die ein eigenes Skript oft
überflüssig machen:

* **`:Bindings report`** schreibt denselben Lauf als Markdown-Datei, samt
  Laufkopf und Startphasen-Warnung. `:Bindings report repo`, `… extern`,
  `… all`, `out=<pfad>` wie bei `check`.
* **`:Bindings status`** zeigt Korpusgröße, aufgelöste Checkouts und
  ausstehende Startphasen, ohne einen ganzen Lauf zu bezahlen.

---

## Gemessene Stände

Alle Zahlen vom **2026-09-02**, headless mit geladener `UIReady`-Phase, gegen
den echten Bestand dieser Config.

### `:Bindings check` (Scope `personal`)

| | vor dem Fallback | nach dem Fallback |
| --- | ---: | ---: |
| Befunde gesamt | 53 | **1** |
| `keymap-not-live` | 52 | **0** |
| `usercmd-not-live` | 1 | 1 |
| Laufzeit (warm) | 149 ms | 550 ms |

Der eine verbliebene Befund ist `:LibLogger`, das sich selbst als lazy
registriert dokumentiert (`drift.lua`s Moduldoc Punkt 5) — ein bestätigter
Nicht-Befund. Nachgemessen: der Quelltext-Fallback würde ihn **nicht**
unterdrücken, weil `LibLogger` in lib.nvim nirgends als Quoted-Literal steht.
Die Achse behält also ihre eine ehrliche Meldung.

### `:Bindings check extern`

| | vor dem Fallback | nach dem Fallback |
| --- | ---: | ---: |
| Befunde gesamt | 379 | **154** |
| `keymap-not-live` | 309 | 84 |
| `usercmd-not-live` | 16 | 16 |
| `usercmd-undocumented` | 54 | 54 |

Exakt additiv zum personal-Scope: 1 + 154 = 155 = `:Bindings check all`.

### Was in den verbliebenen 154 steckt

Von Hand nachgemessen, mit den Plugin-Verzeichnissen manuell aufgelöst — die
Zahlen begründen die offenen Punkte im Handover:

| Gruppe | n | Befund der Durchsicht |
| --- | ---: | --- |
| `keymap-not-live` | 84 | 66 stünden als Quoted-Literal im Baum des Plugins, 2 nur roh; **16 blieben**, davon 13 reine Notationsdifferenzen |
| `usercmd-not-live` | 16 | **13 sind Wrapper dieser Config selbst**, im extern-Korpus dokumentiert und dort als `[custom]` markiert; 1 im Plugin; 2 unquoted Vimscript |
| `usercmd-undocumented` | 54 | 11 hätten schon ein Sheet, dem nur Zeilen fehlen; 4 sind Neovims eigene; ~20 sind lazy-`cmd`-Stubs; 19 gehören Plugins ohne Sheet |

### Die Kostenmessung, die den Default begründet hat

`check` ohne Quelltext-Fallback 149 ms, mit 550 ms — ein Checkout wird erst
indiziert, nachdem eine Taste dieses Plugins gefehlt hat. Die opt-in-Achse
`:Bindings check repo` liest dagegen ~30 Repos auf Verdacht: 940 ms, 2861
Quelldateien, 28 MiB Zwischenspeicher, am Ende des Laufs freigegeben. Das ist
der ganze Grund, warum das eine Default ist und das andere nicht.

---

## Was ein Befund nicht ist

Drei Klassen, die korrekt gemeldet werden und trotzdem kein Problem sind. Wer
eine Zahl senken will, muss zuerst wissen, welche davon er vor sich hat.

1. **Buffer-lokal, UI nicht offen.** Die Taste ist registriert, sobald das
   Fenster existiert. Der Quelltext-Fallback fängt das heute ab; wo er nicht
   antworten kann, greift das Pro-Tabellen-Verdikt „not verifiable from here".
2. **Lazy, noch nicht ausgelöst.** Ein Command, dessen Cheatsheet eine
   „Registered when"-Spalte hat, ist verdächtig, bevor man das Feature einmal
   benutzt hat. `:LibLogger` ist der dokumentierte Beispielfall.
3. **Notation statt Drift.** Der Korpus und die Quelle schreiben dieselbe
   Taste verschieden: Telescope `<A-c>` gegen `<M-c>`, cmdlog `ctrl-f` in
   fzf-lua-Notation, VisualMulti mit dem Leader `\\` im Key. 13 der 16
   verbliebenen extern-Keymaps sind genau das.

Und einmal umgekehrt, damit der Preis der Grep-Achse nicht bloß behauptet
ist: **`cmdlog.nvim`s `ctrl-t` ist tot und fällt trotzdem nicht auf.** Das
Literal steht zufällig in `lua/config/fzf/init.lua` dieser Config, wo es
`file_tabedit` bindet — der Grep kann die beiden nicht unterscheiden. Ein
verpasster Fund ist billiger als ein falscher, aber er ist nicht gratis.
