# Neo-tree Window Controller

Dieses Modul implementiert eine zentrale, deterministische Steuerung für alle
Neo-tree Fensteröffnungen.

---

## Motivation

Neo-tree verhält sich je nach Position unterschiedlich:

- left/right: stabile Split-Windows
- float: ephemeres Fenster
- current: Buffer-Reuse ohne eigenes Window

Toggle-basierte Logik (`toggle = true`) führt dadurch zu Race Conditions,
insbesondere bei float und current.

---

## Design-Prinzipien

- Eine einzige Quelle der Wahrheit für den Window-State
- Keine Ableitung des Zustands aus Neo-tree internem State
- Keine Verwendung von `toggle = true`
- Einheitliche Behandlung aller Positionen
- Explizites Sequencing bei Positionswechseln

---

## State-Maschine

```

closed
└── open(target)
open(target)
├── same target → close
└── other target → close → open(new target)

````

---

## Öffentliche API

```lua
controller.make_opener(position) -> function()
controller.get_state() -> { open = boolean, position = string|nil }
````

---

## Integration

* `init.lua`: Keymaps
* `measuring.lua`: Timing / Profiling
* Controller enthält keinerlei UI- oder Mapping-Code

---

## Vorteile

* float und current verhalten sich stabil
* left/right wechseln deterministisch
* gleiche Mapping zweimal → toggle
* anderes Mapping → sauberer Switch
* vollständig mess- und testbar

```

---

## Ergebnis

Mit dieser Struktur:

- verschwinden alle beschriebenen Fehlverhalten
- ist die Logik nachvollziehbar testbar
- lassen sich weitere Quellen (git_status, buffers, symbols) sauber integrieren
- bleibt `init.lua` trivial und stabil

