# Vim `[range]` Notationen (für z. B. :substitute, :delete, :write …)

Mit `[range]` kann man gezielt **einen oder mehrere Zeilenbereiche** angeben, auf die ein Befehl wirkt. Gültig in Befehlen wie `:s`, `:d`, `:w`, `:y`, `:m`, `:t`, `:!`, `:g`, `:v` etc.

---

## Grundstruktur

```vim
:[start],[end]{command}
```

Wenn `[end]` fehlt, wird nur eine Zeile verwendet. Ohne Range wirkt der Befehl nur auf die aktuelle Zeile.

---

## 1. Absolute Zeilennummern

```vim
:10s/foo/bar/g      " Zeile 10
:5,10s/foo/bar/g    " Zeilen 5 bis 10
:1,$s/foo/bar/g     " Von erster bis letzter Zeile
```

| Zeichen | Bedeutung           |
| ------- | ------------------- |
| `1`     | erste Zeile         |
| `$`     | letzte Zeile        |
| `N`     | Zeile N (z. B. `3`) |

---

## 2. Relative Zeilen

```vim
:.      " aktuelle Zeile
:-2     " zwei Zeilen vorher
:+3     " drei Zeilen nachher
```

```vim
:.,+2d  " löscht aktuelle + zwei weitere Zeilen (insgesamt 3)
:.-1s/foo/bar/  " eine Zeile vor der aktuellen ersetzen
```

---

## 3. Markierungen

```vim
:'a     " Zeile der Markierung a
:'<     " Anfang visueller Auswahl
:'>     " Ende visueller Auswahl
```

```vim
:'<,'>s/foo/bar/g  " Ersetze in visuell markiertem Bereich
:'a,'bs/foo/bar/   " Bereich von Markierung a bis b
```

---

## 4. Suchmuster als Zeilenreferenz

```vim
:/TODO/        " erste Zeile mit „TODO“ (vorwärts)
:?FIXME?       " erste Zeile mit „FIXME“ (rückwärts)
```

```vim
:/Start/,/End/d     " löscht von Zeile mit „Start“ bis „End“
:/foo/,+3s/bar/baz/ " Ersetze in Zeile mit „foo“ + 3 Folgezeilen
```

---

## 5. Kombinationen

```vim
:.,/End/s/foo/bar/   " von aktueller Zeile bis Zeile mit „End“
:'<,/END/yank        " von visuellem Start bis Suchmatch „END“
```

---

## 6. Prozent `%`

```vim
:%s/foo/bar/g
```

| Symbol            | Bedeutung     |
| ----------------- | ------------- |
| `%`               | gesamte Datei |
| entspricht `:1,$` |               |

---

## 7. `+` und `-` Kombinationen

```vim
:.,+5s/foo/bar/   " ab aktueller Zeile + 5 Zeilen
:.-2,+3s/foo/bar/ " von -2 bis +3 ab aktueller Zeile
```

---

## Weitere Beispiele

```vim
:10,20y a         " kopiere Zeilen 10–20 in Register a
:.,$d             " lösche von aktueller bis letzter Zeile
:/start/,/end/>   " Shift nach rechts im Bereich
```

---

## Zusammenfassung

| Range      | Beschreibung                      |
| ---------- | --------------------------------- |
| `N`        | Zeile N                           |
| `1,$`      | ganze Datei                       |
| `.`        | aktuelle Zeile                    |
| `'a`       | Markierung a                      |
| `'<,'>`    | Visuelle Auswahl                  |
| `/foo/`    | erste Zeile mit „foo“             |
| `?bar?`    | erste Zeile mit „bar“ (rückwärts) |
| `+N`, `-N` | relative Zeilen verschoben um N   |

---

## Tipp

Man kann eigene Makros oder Lua-Funktionen schreiben, die mit `vim.fn.getpos("'<")` und `vim.fn.line(".")` dynamisch Ranges erzeugen.

---