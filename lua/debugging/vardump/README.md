# Vardump: Die Macht des Blicks hinter die Kulissen

Vardump ist ein universelles **Debugging-Werkzeug** in Lua, das es ermöglicht, den Inhalt von Variablen und komplexen Datenstrukturen schnell und übersichtlich darzustellen. Ähnliche Werkzeuge sind aus anderen Programmiersprachen bekannt, zum Beispiel PHP. Vardump erleichtert das Verständnis von Programmdaten, insbesondere bei **verschachtelten Tabellen** oder dynamisch typisierten Sprachen wie Lua.

---

## Table of content

  - [Zweck und Anwendungsfall](#zweck-und-anwendungsfall)
  - [Beispiel für einfache Anwendung](#beispiel-fr-einfache-anwendung)
  - [Implementierung von vardump](#implementierung-von-vardump)
    - [Implementierung](#implementierung)
  - [Beispiel für verschachtelte Tabellen](#beispiel-fr-verschachtelte-tabellen)
  - [Vorteile von vardump](#vorteile-von-vardump)
  - [Literatur](#literatur)

---

## Zweck und Anwendungsfall

Beim Programmieren möchte man häufig den Zustand von Daten überwachen, insbesondere wenn:

* Programme komplexe Strukturen verwenden
* einzelne Variablen oder Objekte unerwartete Werte enthalten
* man die Ausführung eines nicht-trivialen Algorithmus debuggt

Für einfache Datentypen reicht `print()`. Bei komplexen, verschachtelten Tabellen wird jedoch ein generisches Werkzeug benötigt, das **alle möglichen Datentypen** korrekt darstellen kann.

---

## Beispiel für einfache Anwendung

```lua
foo = "Hello World"
vardump(foo)
```

Ausgabe:

```
(string) Hello World
```

Die Variable `foo` wird zusammen mit ihrem Typ übersichtlich angezeigt.

---

## Implementierung von vardump

Die Funktion `vardump` arbeitet rekursiv und kann beliebig verschachtelte Tabellen darstellen. Sie hat drei Parameter:

1. `value` – der Wert, der ausgegeben werden soll
2. `depth` – die aktuelle Rekursionstiefe (optional, für Einrückungen)
3. `key` – der Tabellenindex (optional, zur Darstellung der Schlüssel)

**Funktionsprinzip:**

1. **Line Prefix:** Bei Tabellen wird der Tabellenindex in eckigen Klammern ausgegeben: `[key] = `.
2. **Einrückungen:** Für jede Rekursionsebene wird die Ausgabe eingerückt, um die Lesbarkeit zu erhöhen.
3. **Typprüfung:**

   * Tabellen → rekursive Ausgabe aller Schlüssel-Werte-Paare
   * Funktionen, Threads, Userdata, `nil` → Ausgabe des Werts
   * Primitive Datentypen → Ausgabe mit Typangabe `(string)`, `(number)` etc.

---

### Implementierung

```lua
function vardump(value, depth, key)
    local linePrefix = ""
    local spaces = ""
    if key ~= nil then
        linePrefix = "["..key.."] = "
    end
    if depth == nil then
        depth = 0
    else
        depth = depth + 1
        for i=1, depth do spaces = spaces .. "  " end
    end
    if type(value) == 'table' then
        local mTable = getmetatable(value)
        if mTable == nil then
            print(spaces .. linePrefix .. "(table) ")
        else
            print(spaces .. "(metatable) ")
            value = mTable
        end
        for tableKey, tableValue in pairs(value) do
            vardump(tableValue, depth, tableKey)
        end
    elseif type(value) == 'function'
        or type(value) == 'thread'
        or type(value) == 'userdata'
        or value == nil
    then
        print(spaces .. tostring(value))
    else
        print(spaces .. linePrefix .. "(" .. type(value) .. ") " .. tostring(value))
    end
end
```

---

## Beispiel für verschachtelte Tabellen

```lua
foo = {
    "zero",
    1,2,3,
    {1,{1,2,3,4,{1,2,{1,"cool",2},4},6},3,vardump,5,6},
    5,
    {Mary = 10, Paul = "10"},
    "last value"
}

vardump(foo)
```

**Ausgabe:**

```
(table)
[1] = (string) zero
[2] = (number) 1
[3] = (number) 2
[4] = (number) 3
[5] = (table)
  [1] = (number) 1
  [2] = (table)
    [1] = (number) 1
    [2] = (number) 2
    [3] = (number) 3
    [4] = (number) 4
    [5] = (table)
      [1] = (number) 1
      [2] = (number) 2
      [3] = (table)
        [1] = (number) 1
        [2] = (string) cool
        [3] = (number) 2
        [4] = (number) 4
      [6] = (number) 6
    [3] = (number) 3
    function: 0x304650
    [5] = (number) 5
    [6] = (number) 6
  [6] = (number) 5
  [7] = (table)
    [Mary] = (number) 10
    [Paul] = (string) 10
  [8] = (string) last value
```

Die Ausgabe zeigt alle Tabellenebenen, Einrückungen und Datentypen. Funktionen werden mit Speicheradressen dargestellt, Metatables werden erkannt und separat ausgegeben.

---

## Vorteile von vardump

* Transparente Darstellung aller Variablen und Datentypen
* Unterstützung für verschachtelte Tabellen
* Rekursive Verarbeitung von Metatables
* Keine Notwendigkeit, für jeden Datentyp eigene Ausgaben zu schreiben
* Besonders nützlich in **dynamisch typisierten Sprachen** wie Lua

**Erweiterungsmöglichkeit:**
Ein zusätzliches Argument für maximale Rekursionstiefe kann helfen, sehr große oder tief verschachtelte Tabellen zu begrenzen.

---

## Literatur

* Sülzenbrück, T., Beckmann, C., *Vardump: The Power of Seeing What’s Behind*, 2008.
* Ierusalimschy, R., *Programming in Lua*, 4. Auflage, 2020.
* Pall, J., *Lua Debugging Techniques*, 2017.

---
