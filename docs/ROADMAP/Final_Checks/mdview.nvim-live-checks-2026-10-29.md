# mdview.nvim — Live-Checks (Stand 2026-10-29)

Was in mdview.nvim gebaut und per Script/Spec abgedeckt ist, wo aber ein Mensch in einem echten
Neovim mit echtem Browser urteilen muss: Scroll-Gefühl, geteilter Relay über zwei Instanzen,
Spotlight-Spiegel. Ist ein Abschnitt durch, die Task mit `done` schließen (oder Bescheid geben).
Ein Befund: unter "Befunde" eine Zeile, daraus wird eine `kind: bug`-Task.

Die Referenz-Checkliste im Plugin liegt in `$REPOS_DIR/mdview.nvim/TESTS/CHECK.md`; Ergebnisse der
Abschnitte 1 und 3 dort ebenfalls eintragen. Ältere Prüfungen zu mdview stehen in
`Checks-Blocker_0610.md` (Abschnitte A und G2) und `PLUGIN_ROADMAPS_TESTPLAN.md`.

**Vorher:**

- Relay aus dem Checkout bauen (der Release v0.4.3 kennt `--shared` und neuere Spotlight-Routen
  nicht): im mdview.nvim-Checkout `npm run build:go` und `npm run build`.
- In der Config (Abschnitt 2 und 3):

```lua
require("mdview").setup({
  dev = {
    binary_path = "<checkout>/native/server/mdview-server", -- unter Windows mit .exe
    web_root = "<checkout>/dist/client",
  },
})
```

- `:checkhealth mdview` ohne Fehler, ein echter Browser (kein Headless).

---

## 1. Scroll-Gefühl: `reverse_scroll` und proportionales Folgen — offen

Task `mdview.nvim/scroll-lag-feel-judgement`. Quelle: `TESTS/CHECK.md` ("Manual test tasks" Punkt
`reverse_scroll`, und `any_file`-Release-Check Fall 2, "Open: whether the lag feels right").
Das geht nur als Urteil eines Menschen, nicht headless. Regler bei Unzufriedenheit:
`transport.inbound_poll_ms` (Default 250).

### 1a. `reverse_scroll` (Browser scrollt, Cursor in Neovim folgt)

```lua
require("mdview").setup({ experimental = { reverse_scroll = true } })
```

- [ ] Eine lange `.md`-Datei (mehrere Bildschirme), `:MDView start`
- [ ] Im Browser ca. eine Minute scrollen (Mausrad, Pfeiltasten, Scrollbar ziehen)
- [ ] Der Neovim-Cursor folgt dem Browser mit etwa 250 ms Verzögerung
- [ ] Urteil: Verzögerung akzeptabel? (ja/nein, Notiz in "Befunde")

### 1b. `any_file` (proportionales Folgen bei Nicht-Markdown)

```lua
require("mdview").setup({ any_file = true })
```

- [ ] Eine lange `.lua`- oder `.py`-Datei öffnen (Fixtures: `TESTS/any_file/sample.lua`,
      `sample.py`, beide höher als ein Bildschirm), `:MDView start`
- [ ] Cursor durch die Datei bewegen (Mitte, Ende, zurück): die Seite folgt proportional
      (Mitte der Datei = ungefähr Mitte der Seite), **kein** Cursorbalken (das ist erwartet)
- [ ] Urteil: Folgen fühlt sich akzeptabel an? (ja/nein, Notiz)

### Falls rot

- Zu träge: `transport.inbound_poll_ms` senken (z. B. 100), nochmal testen, gewählten Wert notieren
  (Task-Akzeptanz: Wert festhalten oder Folge-Task).
- Seite springt falsch oder bewegt sich gar nicht: Dateityp, Position und Browser notieren.

### Danach

- [ ] Ergebnis in `TESTS/CHECK.md` eintragen (Fall 2 des `any_file`-Checks und Punkt
      `reverse_scroll`: "judged ok" bzw. gewählter `inbound_poll_ms`)
- [ ] Task `mdview.nvim/scroll-lag-feel-judgement` mit `done` schließen

---

## 2. Geteilter Relay: zwei nvim-Instanzen, ein Browser-Tab — offen

Task `mdview.nvim/shared-relay-live-pruefen-zwei-nvim-instanzen-echter-browser` (Vorgänger:
`mdview.nvim/mdview-browser-sync-ueber-nvim-instanzen-hinweg`). Headless mit zwei Instanzen gegen
einen echten Relay schon durchgespielt; offen: echter Tab und echtes Focus-Reporting des
Terminals (Terminal: **WezTerm**).

Zusätzlich zur Dev-Config oben:

```lua
require("mdview").setup({ shared_relay = { enabled = true } })
```

Zwei Terminalfenster nebeneinander, in jedem ein Neovim mit einer **anderen** `.md`-Datei
(A in Fenster 1, B in Fenster 2).

- [ ] Fenster 1: `:MDView start`: ein Browser-Tab öffnet sich und zeigt A
- [ ] Fenster 2: `:MDView start`: es öffnet sich **kein** zweiter Tab; der vorhandene Tab zeigt
      jetzt B
- [ ] Fensterwechsel zwischen den Terminals (Klick bzw. Tastenkürzel): der Tab schaltet jeweils
      zwischen A und B um, ohne dass du eine Taste im Editor drückst
- [ ] Im Tab eine Checkbox abhaken: die Änderung landet im Buffer der Instanz, deren Dokument der
      Tab gerade zeigt (Gegenprobe: dort `:e!`/Buffer ansehen, die andere Instanz bleibt
      unverändert)
- [ ] Erste Instanz mit `:qa` beenden: Tab bleibt offen und zeigt weiter das Dokument der zweiten
- [ ] Zweite Instanz beenden: der Tab schließt sich nach ca. 2 s (Relay endet nach der letzten
      Instanz; im Taskmanager kein `mdview-server` mehr)
- [ ] Neu starten, **dieselbe Datei** in beiden Instanzen öffnen: der Tab und die Rückschreibungen
      folgen der jeweils fokussierten Instanz

### Falls rot

- Zweiter Tab öffnet sich: Inhalt von `stdpath("state")/mdview/relay.json` notieren, ob die
  erste Instanz `--shared` kennt (`dev.binary_path` wirklich gesetzt?).
- Tab schaltet beim Fensterwechsel nicht um: Terminal und Version notieren, ob Focus-Reporting
  funktioniert (`:autocmd FocusGained` zeigt, ob Neovim das Event bekommt).
- Checkbox landet in der falschen Instanz: beide Dateien, den fokussierten Zustand und Zeitpunkt
  notieren.

### Danach

- [ ] Ergebnisse in der Task-Notiz festhalten, Task
      `mdview.nvim/shared-relay-live-pruefen-zwei-nvim-instanzen-echter-browser` mit `done`
      schließen

---

## 3. Spotlight-Spiegel in echtem Neovim und Browser — offen

Task `mdview.nvim/spotlight-mirror-live-check`. Quelle: `TESTS/CHECK.md`, Abschnitt "Spotlight
mirror (`browser.spotlight_sync`) — manual check". Ende-zu-Ende per Script schon verifiziert (Lua,
Relay, Tab); offen ist das Urteil im langlaufenden Editor.

**Voraussetzung:** spotlight.nvim installiert, Relay aus dem Checkout (neuer als v0.3.0, siehe
`mdview.nvim/release-relay-spotlight-route`). Testdokument: eine `.md`, in der ein Token mehrfach
vorkommt: im Absatz, als `inline code`, in einem Codeblock, in einer Tabellenzelle. Außerdem eine
sehr große `.md` mit einem sehr häufigen Token (Abschnitt "Deckel").

### Markieren und Latenz

- [ ] `:MDView start`, Cursor auf das Token, `:Spotlight toggle`: alle Vorkommen sind im Browser
      binnen ca. 1 s markiert, in **derselben Farbe** wie in Neovim; eine andere Groß-/Kleinschreibung
      des Tokens ist **nicht** markiert
- [ ] Teil eines Wortes visuell markieren und togglen: Teilstrings in längeren Wörtern werden
      mitmarkiert (keine Wortgrenzen); ein ganzes Wort togglen: nur ganze Wörter
- [ ] Buffer bearbeiten, sodass die Vorschau neu rendert: die Markierungen bleiben

### Entfernen, Wechseln

- [ ] Spotlight entfernen: Markierung verschwindet im Browser
- [ ] `:Spotlight clear`: alles verschwindet
- [ ] `:Spotlight sets switch`: die Vorschau folgt dem Wechsel, der letzte in einem Schritt ohne
      Flackern

### Farbschema

- [ ] `:colorscheme <anderes>`: die Farben im Browser wechseln mit
- [ ] `:set background=light` (und zurück): die Farben im Browser folgen
- [ ] Browser-Tab neu laden: die Markierungen sind sofort wieder da

### Ein/Aus

- [ ] `:MDView spotlight off`: Markierungen im offenen Tab verschwinden; `:MDView spotlight on`:
      sie kommen zurück
- [ ] Mit `browser.spotlight_sync = false` wird nie etwas markiert

### Deckel bei großem Dokument

- [ ] Große `.md` mit einem sehr häufigen Token (mehr Vorkommen als
      `browser.spotlight_max_matches`, Default 500), `:Spotlight toggle`: die Seite bleibt
      bedienbar (Scrollen, Tippen ohne Ruckeln), nur so viele Treffer wie erlaubt sind markiert,
      `:MDView weblogs` meldet, dass der Spotlight gedeckelt wurde

### Ohne spotlight.nvim

- [ ] Optional: spotlight.nvim deaktivieren, `:MDView start` und alles andere läuft ohne Fehler;
      `:checkhealth mdview` führt es als optionalen Begleiter

### Falls rot

- Treffer fehlen/falsche Farbe: Token, Textstelle (Absatz/Code/Tabelle), Farbschema notieren.
- Latenz deutlich über 1 s: Dokumentgröße, Browser, Relay-Version (`:MDView` Status) notieren.
- Seite hängt bei großem Dokument: Anzahl Treffer und Dokumentgröße notieren.

### Danach

- [ ] Ergebnis in `TESTS/CHECK.md` (Abschnitt "Spotlight mirror") eintragen
- [ ] Task `mdview.nvim/spotlight-mirror-live-check` mit `done` schließen

---

## Offene Fragen

- Abschnitt 2: beantwortet (2026-10-29): Terminal ist **WezTerm** (Focus-Reporting im WezTerm prüfen).
- Abschnitt 3: Die Task nennt "a relay newer than v0.3.0", `README` nennt "v0.4.0 or newer", die
  Doku zu `shared_relay` "newer than v0.4.3". Reicht der Checkout-Build für beides (Annahme: ja)?

---

## Befunde

<!-- eine Zeile pro Befund: Abschnitt, was passiert ist, was erwartet war -->
