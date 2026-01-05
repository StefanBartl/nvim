# Replace-Integration in `:Recommender -r` bzw `:Recommender --replace`

Der Recommender unterstützt einen optionalen Replace-Modus, der auf einem
Telescope-basierten `:Replace`-Command beruht.

Da Telescope interaktiv und asynchron arbeitet, existiert kein synchroner
Callback, der signalisiert, wann der Replace-Vorgang abgeschlossen ist.

---

## Lösung

Beim Start eines Replace-Vorgangs registriert der Recommender temporär ein
`WinClosed`-Autocommand, das ausschließlich auf das Schließen eines
`TelescopePrompt`-Fensters reagiert.

Dieses Ereignis dient als Abschluss-Signal. Erst danach wird:

- das ursprüngliche Ziel-Fenster reaktiviert
- der Alias-Text eingefügt

Das Autocommand wird unmittelbar nach Ausführung wieder deregistriert, um
globale Event-Verschmutzung zu vermeiden.

---

## Vorteile

- kein Polling
- keine Timer
- keine Race Conditions
- klar definierter Lebenszyklus
- minimale Eingriffe in das globale Event-System

---
