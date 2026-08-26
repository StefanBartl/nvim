# FFI/C-Kandidaten — Analyse

Roadmap-Task: *"Module/Funktionen identifizieren, die von FFI/C profitieren
würden (Startup, Runtime-Analysis, Docmap), und Umsetzung vorschlagen."*

**Ergebnis: kein Kandidat, der es rechtfertigt.** Docmap ist der einzige Ort mit
genug CPU-gebundener Lua-Arbeit, um überhaupt darüber zu reden — und selbst dort
ist der richtige nächste Schritt ein Profil, kein C-Port. Begründung unten, mit
Messwerten (2026-08-26).

---

## Was FFI eigentlich kann, und was nicht

Der wichtigste Punkt vorweg, weil er die halbe Frage beantwortet:

> **`ffi` macht Lua-Code nicht schneller.** Es erlaubt Lua, C-Funktionen zu
> rufen und C-Datenstrukturen zu benutzen.

Ein Gewinn entsteht also nur, wenn man einen Algorithmus **nach C verschiebt**
und ein kompiliertes Artefakt ausliefert. Für diese Plugins heißt das:

- ein Build-Schritt (das „clone und es läuft" ist weg)
- Artefakte pro Plattform × Architektur
- eine Release-Pipeline, die sie baut und verteilt

Das ist kein theoretischer Einwand: `mdview.nvim` macht genau das (Go-Relay +
Rust/WASM, aus GitHub Releases geladen). Der Preis ist also bekannt — und dort
gerechtfertigt, weil die Arbeit echt schwer ist (Markdown-Rendering,
Sanitizing, ein WebSocket-Server). Die Frage ist, ob irgendwo sonst eine
vergleichbar schwere, abgeschlossene Rechenlast liegt.

---

## Startup

**Nein, und zwar eindeutig.** Gemessen (siehe `Merged_Finished.md`, Abschnitt
Performance): von ~1300 ms gingen ~660 ms an lazy.nvim (Plugins laden = Datei-
I/O + Lua-Parsing, beides Neovims eigenes C) und der Rest an Phasen, deren
größte Posten Prozess-Spawns und Modul-Ladezeiten sind — nicht Rechnung.

Die drei Fixes dieser Runde bestätigen das von der anderen Seite: neo-tree lazy
laden (−250 ms), eine fehlschlagende `executable()`-Probe verschieben (−44 ms),
trouble lazy laden (−60 ms). Alles Vermeiden von Arbeit, nichts, das schneller
gerechnet werden müsste. Da ist kein C-Kandidat, weil da kein Rechnen ist.

## Runtime-Analysis

**Nein, und FFI wäre hier sogar kontraproduktiv.** Die Telemetrie zählt
Funktionsaufrufe, indem sie Funktionen wrappt und pro Aufruf einen Zähler in
einer Lua-Tabelle erhöht. Die Kosten sind der Wrapper-Overhead pro Aufruf —
und ein Übergang über die Lua/C-Grenze kostet **mehr** als ein
Tabellen-Increment, das LuaJIT wegoptimiert. Man würde die eine Sache, die hier
heiß ist, langsamer machen.

## Docmap

**Der einzige Ort mit echter CPU-gebundener Lua-Arbeit — und trotzdem nein.**

Gemessen an `documentation.nvim` selbst (135 Lua-Dateien, 2,0 MB Quelltext):

| | Zeit |
| --- | --- |
| Dateien nur lesen | **17,8 ms** |
| Lesen + vollständiges Treesitter-Parsing | **193 ms** |
| Kompletter `scripts/gen_map.lua` | **4133 ms** |

Also: ~0,2 s Lesen und Parsen, **~3,9 s Lua-Arbeit** — IR bauen, Call-Graph,
Coverage, Rendering. Das ist tatsächlich rechenlastig, und es ist der einzige
Ort in diesem Ökosystem, für den das gilt.

Trotzdem spricht dagegen:

1. **Es ist keine interaktive Operation.** `gen_map` läuft manuell oder in CI.
   4 s sind lästig, aber sie blockieren niemanden beim Tippen. Der Nutzen einer
   Beschleunigung ist entsprechend klein.
2. **„FFI hinzufügen" gibt es hier nicht.** Der Kern von documentation.nvim
   *ist* der IR-Builder. Ihn nach C zu verschieben heißt, das Plugin zu
   portieren, nicht es zu ergänzen — und das gegen ein Plugin, dessen
   Alleinstellungsmerkmal Determinismus und Byte-Vergleichbarkeit ist.
3. **Vor C kommt Algorithmik.** 3,9 s für 2 MB Quelltext sind ~2 ms/KB. Ob das
   nah am Möglichen liegt oder ob irgendwo ein O(n²) steckt, ist nicht
   gemessen. Ein Profil kostet einen Nachmittag, ein C-Port Wochen — und wenn
   das Profil eine quadratische Stelle findet, ist der C-Port danach sowieso
   unnötig.

---

## Wann man diese Antwort neu stellen sollte

Damit das „nein" nicht dauerhaft gilt, ohne dass es jemand prüft. Ein
FFI/C-Kandidat wäre etwas, das **alle drei** Eigenschaften hat:

- **interaktiv**, also im Weg des Nutzers (nicht CI, nicht manuell),
- **CPU-gebunden in Lua**, gemessen — nicht I/O, nicht Prozess-Spawn, nicht
  Modul-Laden,
- **abgeschlossen genug**, um als Funktion mit klarer Signatur nach C zu
  wandern, ohne das halbe Plugin mitzunehmen.

Konkret einzelne Dinge, die das eines Tages werden könnten:

- Ein Live-Linter/Analyzer, der bei jedem `TextChanged` über den ganzen Puffer
  läuft (heute macht das keines der Plugins).
- Diff/Merge auf großen Dateien, falls `diff.nvim` je über Vims eingebautes
  `vim.diff` hinausgeht — `vim.diff` ist bereits C.
- Bildverarbeitung in `images.nvim`, falls dort je skaliert/konvertiert wird
  statt ein externes Tool zu rufen. Aktuell wird gerufen, was richtig ist.

## Zwischenschritte, die vor FFI kommen

Falls doch mal etwas zu langsam ist, in dieser Reihenfolge:

1. **Messen** — welcher Anteil ist überhaupt Lua-Rechenzeit (die Tabelle oben
   ist die Vorlage: nur lesen, lesen+parsen, alles).
2. **Algorithmik** — quadratische Stellen, wiederholte Arbeit, fehlendes Memo.
3. **Vorhandenes C benutzen** — `vim.treesitter`, `vim.diff`, `vim.json`,
   `vim.base64`, `vim.iter`, `vim.uv` sind alle nativ. Ein Lua-Nachbau davon
   ist der häufigere Fehler als ein fehlendes FFI.
4. **Arbeit verschieben statt beschleunigen** — lazy, cache, asynchron. Die
   drei Startup-Fixes dieser Runde waren alle von dieser Sorte.
5. **Ein externes Tool rufen**, wie `pdfport` (pdftotext) und `mdview` (Go/Rust)
   es tun. Das kostet eine Dependency, aber keinen Build-Schritt im Plugin.
6. **Erst dann** eine native Bibliothek mit FFI-Binding.
