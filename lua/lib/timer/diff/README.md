# `lib.time.diff` – Zeitmessung mit Checkpoint-Tracking

## Übersicht

Das `lib.time.diff`-Modul bietet eine einfache, präzise Methode zur Messung von Zeitintervallen in Lua-Code. Es nutzt `vim.uv.hrtime()` für Nanosekundenpräzision (Standard) und ermöglicht mehrere Messpunkte innerhalb eines Zeitraums.

Jeder Aufruf von `require("lib.time.diff")` erzeugt eine unabhängige Timer-Instanz mit eigenem Zustand.

**Standard-Einheit:** Nanosekunden (ns). Alle Methoden können optional eine andere Einheit (`"ms"`, `"us"`, `"s"`) akzeptieren.

---

## Installation

Das Modul liegt unter `lua/lib/time/diff/init.lua`. Man importiert es wie gewohnt:

```lua
local diff = require("lib.time.diff")
```

---

## Grundlegende Verwendung

### 1. Timer starten

```lua
local diff = require("lib.time.diff")
diff.start()  -- Startet die Zeitmessung
```

Der Timer startet automatisch beim Erstellen der Instanz. `start()` kann verwendet werden, um den Timer zurückzusetzen.

---

### 2. Checkpoints setzen

```lua
-- Code-Block 1 (Standard: Nanosekunden)
local first_diff = diff.check()
print("Erster Check:", first_diff, "ns")

-- Code-Block 2 (explizit Millisekunden)
local second_diff = diff.check("ms")
print("Zweiter Check:", second_diff, "ms")

-- Code-Block 3 (Mikrosekunden)
local third_diff = diff.check("us")
print("Dritter Check:", third_diff, "us")
```

Jeder Aufruf von `check()` gibt die verstrichene Zeit seit `start()` zurück.

**Verfügbare Einheiten:**
- `"ns"` – Nanosekunden (Standard)
- `"us"` – Mikrosekunden
- `"ms"` – Millisekunden
- `"s"` – Sekunden

---

### 3. Gesamtzeit abrufen

```lua
-- Standard: Nanosekunden
local total = diff.result()
print("Gesamtzeit:", total, "ns")

-- Explizit Millisekunden
local total_ms = diff.result("ms")
print("Gesamtzeit:", total_ms, "ms")
```

Alternativ kann man die letzte Checkpoint-Zeit direkt verwenden:

```lua
print("Total:", diff.last)  -- Immer in Nanosekunden
```

---

### 4. Intervalle zwischen Checkpoints

Man berechnet Differenzen direkt:

```lua
local delta = third_diff - first_diff
print("Zeit zwischen erstem und drittem Check:", delta, "ns")
```

Oder mit dynamischen Properties:

```lua
print("Delta:", diff.third - diff.first, "ns")
```

---

## Dynamische Properties für Checkpoints

Das Modul erzeugt automatisch Properties für alle vorhandenen Checkpoints:

| Property      | Bedeutung                                    |
|---------------|----------------------------------------------|
| `diff.first`  | Erster Checkpoint (falls vorhanden)          |
| `diff.second` | Zweiter Checkpoint (falls vorhanden)         |
| `diff.third`  | Dritter Checkpoint (falls vorhanden)         |
| `diff.fourth` | Vierter Checkpoint (falls vorhanden)         |
| ...           | Bis `tenth` (zehnter Checkpoint)             |
| `diff.last`   | Letzter Checkpoint (immer vorhanden wenn >0) |

**Wichtig:** Properties geben immer Werte in **Nanosekunden** zurück.

Beispiel:

```lua
local diff = require("lib.time.diff")

diff.check()  -- Erster Checkpoint
diff.check()  -- Zweiter Checkpoint

print(diff.first)   -- Erster Checkpoint in ns
print(diff.second)  -- Zweiter Checkpoint in ns
print(diff.last)    -- Letzter Checkpoint in ns (gleich wie second)

-- Wenn nur ein Checkpoint existiert:
local diff2 = require("lib.time.diff")
diff2.check()
print(diff2.first)  -- Funktioniert
print(diff2.second) -- nil (nicht vorhanden)
```

---

## Ausgabe aller Checkpoints

### Standard-Format

```lua
-- Standard: Nanosekunden
print(diff.results())
-- Ausgabe: "Check 1: 12345678ns | Check 2: 23456789ns | ... | Total: 45678901ns"

-- Explizit Millisekunden
print(diff.results("ms"))
-- Ausgabe: "Check 1: 12.345ms | Check 2: 23.456ms | ... | Total: 45.678ms"
```

Oder mit Metatable-Magie:

```lua
print(diff())        -- Standard: Nanosekunden
print(diff("ms"))    -- Explizit Millisekunden
```

### Formatierte Tabelle

Für bessere Lesbarkeit in `:messages` oder Notify-Fenstern:

```lua
-- Standard: Nanosekunden
print(diff.pretty())

-- Explizit Millisekunden
print(diff.pretty("ms"))
```

Beispielausgabe (Millisekunden):

```
┌────────┬─────────────────┬─────────────────┐
│ Index  │  Elapsed (ms)  │   Delta (ms)   │
├────────┼─────────────────┼─────────────────┤
│      1 │       12.345    │       12.345    │
│      2 │       23.456    │       11.111    │
│      3 │       45.678    │       22.222    │
├────────┴─────────────────┴─────────────────┤
│ Total:     45.678ms                        │
└──────────────────────────────────────────────┘
```

---

## Iterator-Unterstützung

Man kann sequenziell durch alle Checkpoints iterieren:

### Einfacher Iterator (nur Zahlenwerte)

```lua
diff.reset_iterator()  -- Zum Anfang zurückspringen

while true do
  local t = diff.next()  -- Standard: ns
  if not t then break end
  print("Nächster Checkpoint:", t, "ns")
end
```

### Iterator mit Custom-Label

```lua
-- Label setzen
diff.reset_iterator("Checkpoint")

while true do
  local output = diff.next(nil, "ms")  -- Mit Einheit
  if not output then break end
  print(output)  -- "Checkpoint 12.345ms"
end
```

### Iterator mit Label und Index

```lua
-- Label und Index-Anzeige aktivieren
diff.reset_iterator("Checkpoint", true)

while true do
  local output = diff.next(nil, "ms")
  if not output then break end
  print(output)  -- "Checkpoint 1: 12.345ms"
end
```

### Iterator mit Override-Label

```lua
diff.reset_iterator("Checkpoint", true)

-- Erstes next() mit Standard-Label
print(diff.next(nil, "ms"))  -- "Checkpoint 1: 12.345ms"

-- Zweites next() mit Override-Label
print(diff.next("Custom", "ms"))  -- "Custom 2: 23.456ms"

-- Drittes next() wieder mit Standard-Label
print(diff.next(nil, "ms"))  -- "Checkpoint 3: 45.678ms"
```

---

## Mehrere unabhängige Timer

Jeder `require`-Aufruf erzeugt eine neue Instanz:

```lua
local timer1 = require("lib.time.diff")
local timer2 = require("lib.time.diff")

timer1.start()
-- ... Code ...
timer1.check()

timer2.start()
-- ... anderer Code ...
timer2.check()

print(timer1.result())  -- Unabhängig von timer2
print(timer2.result())
```

---

## API-Referenz

### Methoden

| Methode                         | Parameter                        | Rückgabe         | Beschreibung                                      |
|---------------------------------|----------------------------------|------------------|---------------------------------------------------|
| `start()`                       | -                                | `nil`            | Startet oder setzt den Timer zurück               |
| `check(unit?)`                  | `"ns"\|"us"\|"ms"\|"s"`          | `number`         | Setzt Checkpoint, gibt Zeit seit Start zurück     |
| `result(unit?)`                 | `"ns"\|"us"\|"ms"\|"s"`          | `number\|nil`    | Gibt Gesamtzeit zurück (letzter Checkpoint)       |
| `get(idx, unit?)`               | `integer, "ns"\|"us"\|"ms"\|"s"` | `number\|nil`    | Gibt Zeit für Checkpoint `idx` zurück             |
| `next(label?, unit?)`           | `string?, "ns"\|"us"\|"ms"\|"s"` | `string\|number\|nil` | Gibt nächsten Checkpoint zurück (Iterator) |
| `reset_iterator(label?, show?)` | `string?, boolean`               | `nil`            | Setzt Iterator zurück, optional mit Label/Index   |
| `results(unit?)`                | `"ns"\|"us"\|"ms"\|"s"`          | `string`         | Erzeugt Zusammenfassung aller Checkpoints         |
| `pretty(unit?)`                 | `"ns"\|"us"\|"ms"\|"s"`          | `string`         | Erzeugt formatierte Tabelle                       |

### Dynamische Properties

| Property       | Typ             | Beschreibung                  |
|----------------|-----------------|-------------------------------|
| `first`        | `number\|nil`   | Erster Checkpoint (ns)        |
| `second`       | `number\|nil`   | Zweiter Checkpoint (ns)       |
| `third`        | `number\|nil`   | Dritter Checkpoint (ns)       |
| `fourth`-`tenth` | `number\|nil` | Vierter bis zehnter Checkpoint (ns) |
| `last`         | `number\|nil`   | Letzter Checkpoint (ns)       |

**Wichtig:** Properties geben immer Werte in Nanosekunden zurück, unabhängig von der bei `check()` gewählten Einheit.

---

## Fehlerbehandlung

Falls `check()` aufgerufen wird, ohne vorher `start()` zu nutzen:

```lua
local diff = require("lib.time.diff")
-- start() wird automatisch aufgerufen, aber bei manuellem Reset:
diff.start()
diff.check()  -- OK
```

Falls eine ungültige Einheit übergeben wird:

```lua
diff.check("invalid")  -- Fehler: "Invalid unit: invalid"
```

---

## Beispiel: Benchmark einer Funktion

```lua
local diff = require("lib.time.diff")

diff.start()

-- Code-Block 1
for i = 1, 1000000 do
  math.sqrt(i)
end
local t1 = diff.check("ms")

-- Code-Block 2
for i = 1, 1000000 do
  math.sin(i)
end
local t2 = diff.check("ms")

print(diff.pretty("ms"))
print("Differenz:", t2 - t1, "ms")

-- Oder mit Properties
print("Delta:", diff.second - diff.first, "ns")  -- Properties sind in ns!
```

## Beispiel: Iterator mit Labels

```lua
local diff = require("lib.time.diff")

-- Drei Checkpoints setzen
for i = 1, 3 do
  vim.fn.sleep(100)
  diff.check()
end

-- Iterator mit Label und Index
diff.reset_iterator("Messung", true)

while true do
  local output = diff.next(nil, "ms")
  if not output then break end
  print(output)
  -- Ausgabe:
  -- "Messung 1: 100.123ms"
  -- "Messung 2: 200.456ms"
  -- "Messung 3: 300.789ms"
end
```

---

## Technische Details

- **Präzision**: Nanosekunden (via `vim.uv.hrtime()`)
- **Standard-Einheit**: Nanosekunden (ns)
- **Verfügbare Einheiten**: `"ns"`, `"us"`, `"ms"`, `"s"`
- **Rückgabewerte**: Gleitkommazahl
- **Properties**: Immer in Nanosekunden
- **Metatable**: Unterstützt `__call` und `__tostring` für direkten Aufruf
- **Unabhängigkeit**: Jede Instanz hat eigenen Zustand
- **Dynamische Properties**: Bis zu 10 benannte Checkpoints (`first` bis `tenth`) + `last`

---

## Lizenz

Dieses Modul ist Teil der `lib.*`-Bibliothek und folgt den Projektrichtlinien.
