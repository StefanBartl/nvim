# hover-select

hover-select ist ein kleines, modulares Neovim-Hilfsmodul zur Anzeige und Auswahl von Einträgen in einem schwebenden Fenster relativ zur Cursorposition. Es ist bewusst minimal gehalten und eignet sich als Baustein für eigene Plugins oder interne Tools.

## Table of content

  - [Motivation](#motivation)
  - [Funktionen](#funktionen)
  - [Modulaufbau](#modulaufbau)
  - [Typunterstützung](#typuntersttzung)
  - [Konfiguration](#konfiguration)
  - [Bedienung](#bedienung)
  - [Einsatzgebiet](#einsatzgebiet)

---

## Motivation

Nicht jede Auswahl in Neovim erfordert ein umfangreiches Framework wie Telescope oder fzf. Oft wird lediglich eine kompakte, kontextnahe Liste benötigt, aus der ein Eintrag gewählt werden kann. hover-select deckt genau diesen Anwendungsfall ab.

---

## Funktionen

* schwebendes Auswahlfenster relativ zum Cursor, Fenster oder Editor
* Anzeige einer einfachen String-Liste
* Callback-Funktion bei Auswahl
* klare vertikale Navigation ohne horizontale Ablenkung
* automatische Berechnung von Fenstergröße und Begrenzungen
* sauberes Ressourcen-Management über Autocommands
* eigene Hervorhebung der aktuell ausgewählten Zeile

---

## Modulaufbau

Das Modul ist in mehrere logisch getrennte Teile gegliedert:

* lib.hover_select.buffer
  Verantwortlich für Buffer-Erstellung, Inhalt und Buffer-Optionen

* lib.hover_select.window
  Fenstererstellung, Größenberechnung und Aufräumlogik

* lib.hover_select.navigation
  Definition der Keymaps für Navigation, Auswahl und Schließen

* lib.hover_select.highlight
  Verwaltung der Highlight-Gruppen für die Cursorzeile

* lib.hover_select.config
  Zentrale Default-Werte für Buffer, Fenster und Layout

* lib.hover_select.@types
  EmmyLua-Typen für Optionen und internen Zustand

---

## Typunterstützung

Über EmmyLua-Annotationen werden unter anderem folgende Typen bereitgestellt:

* HoverSelectOptions
  Konfigurationsstruktur für Items, Callback und UI-Optionen

* HoverSelectState
  Interner Zustand mit Buffer-, Window-Referenzen und Item-Liste

Diese Typen verbessern die Arbeit mit LuaLS deutlich.

---

## Konfiguration

Standardmäßig werden folgende Aspekte vorkonfiguriert:

* Buffer als temporärer nofile-Buffer
* minimales Floating Window mit Rahmen
* deaktivierte Zeilennummern und horizontales Wrapping
* definierte Minimal- und Maximalgrößen für das Fenster

Eigene Optionen können jederzeit ergänzt oder überschrieben werden.

---

## Bedienung

* Navigation ausschließlich vertikal
* Auswahl mit Enter oder Doppelklick
* Abbrechen mit Escape oder q
* horizontale Cursorbewegungen sind deaktiviert, um Fehlbedienung zu vermeiden

---

## Einsatzgebiet

hover-select eignet sich besonders für:

* eigene Neovim-Plugins
* interne Developer-Tools
* kleine, kontextabhängige Auswahlmenüs
* Situationen, in denen maximale Kontrolle über Buffer und Window erforderlich ist

---
