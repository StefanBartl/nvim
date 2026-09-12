<!--
  README-Template für StefanBartls *.nvim-Plugins — Fassung 3 (2026-09-12).

  Ersetzt Fassung 2 (TEMPLATES/README-NVIM-PLUGIN/README.template.md,
  2026-09-07). Fassung 2 hatte für jedes Plugin ~12 Level-2-Abschnitte, von
  denen die meisten (Requirements, Installation, Quickstart, What you get,
  Integrations, Statusline, Health check, Contributing) den vollen Inhalt
  direkt im README ausformulierten. Ergebnis: das Root-README war selbst schon
  fast die Doku, nicht der Wegweiser zu ihr — und einige READMEs (ui.nvim allen
  voran) sind daraus in einen Diary-Stil abgerutscht: Fortschritts-Prosa
  ("Schritt 3 tat X, Schritt 4 schloss die Lücke Y"), die ins Root-README
  gehört wie ein Commit-Log, aber nicht wie eine Visitenkarte für jemanden, der
  das Plugin zum ersten Mal sieht.

  Fassung 3 zieht die Grenze neu: das Root-README ist praktisch nur noch ein
  Inhaltsverzeichnis in die echte Doku unter docs/. Referenztabellen,
  Architektur-Begründungen, Coupling-Zahlen, Roadmaps — alles das lebt in
  docs/*.md und wird von hier aus nur verlinkt, mit einem Halbsatz was die
  Seite beantwortet. Was im README bleibt: Titel, Art, Badges, ein kurzer
  Pitch, das Inhaltsverzeichnis in die Doku, und die Lizenz.

  Benutzung: Datei kopieren nach <plugin>.nvim/README.md, alle {{...}}-
  Platzhalter ersetzen, diesen Kommentarblock entfernen, nicht zutreffende
  optionale Abschnitte löschen statt leer stehen zu lassen.
-->

<!-- OPTIONAL, nur wenn das Repo tatsächlich noch nicht stabil ist. -->
> **Beta stage — active development.** This repository is past its first shape and in
> active use, but the surface is not frozen: breaking changes are still possible. Pin a
> commit or tag if you depend on it.

# {{name}}.nvim

<!--
  ASCII-Art, Figlet-Stil, Font "ANSI Shadow" (Blockstil, bevorzugt) oder
  "Standard"/"Slant" (dünn, für sehr kurze Namen ebenfalls üblich). Immer nur
  den Namen VOR dem Punkt rendern ("UI", "FILEOPS", "MARKDOWN") — ".nvim"
  kommt als eigene, rechtsbündige Zeile darunter, nie in dieselbe Figlet-Zeile
  gequetscht. Zwei-Wort-Renderings wie "UI NVIM" in einem Block sehen aus wie
  Zeichensalat, weil der Font zwischen den beiden Wörtern nicht genug Abstand
  lässt (Negativbeispiel: ui.nvim vor 2026-09-12, "UI" und "NVIM" liefen ohne
  Trennung ineinander).

  PFLICHTPRÜFUNG: die Art muss den Plugin-Namen buchstabieren. Nicht von Hand
  gegenlesen — dünne Figlet-Schriften (Slant/Standard/Small) verschmelzen
  Glyphen durch Smushing so, dass ein falscher Buchstabe beim Überfliegen
  nicht auffällt (reale Funde: "CILEOPS" für fileops.nvim, "openbuim" für
  open.nvim, "lspovim" für lsp.nvim, "plfpotawim" für pdfport.nvim,
  "spotliaht" für spotlight.nvim — die verlorene Unterlänge eines "g" durch
  eine Tagline direkt unter der Art). Stattdessen rendern und diffen:

  ```bash
  pip install pyfiglet
  python -c "import pyfiglet; print(pyfiglet.figlet_format('NAME', font='ansi_shadow'))"
  ```

  Zeile für Zeile gegen die Art im README halten. Bei Namen mit Unterlängen
  (g/j/p/q/y) prüfen, dass darunter nichts anderes steht (keine Tagline, kein
  Text) — die Unterlänge braucht die Leerzeile.
-->
```
{{ascii-art}}
                                               .nvim
```

<!--
  Badge-Reihenfolge: License → Neovim → Lua → Status → (Platform) → (CI).
  Neovim-Mindestversion im Badge muss mit der in docs/requirements.md
  genannten übereinstimmen. Platform-Badge nur wenn tatsächlich cross-platform
  getestet, CI-Badge nur wenn ein GitHub-Actions-Workflow existiert.
-->
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Neovim](https://img.shields.io/badge/Neovim-0.10%2B-57A143?logo=neovim&logoColor=white)](https://neovim.io)
[![Lua](https://img.shields.io/badge/Lua-5.1%2FLuaJIT-2C2D72?logo=lua&logoColor=white)](https://www.lua.org)
![Status](https://img.shields.io/badge/status-beta-orange)

<!--
  Intro: EIN Satz, der als Elevator-Pitch für sich allein steht, danach
  höchstens ein zweiter Satz Kontext. Sagt was das Plugin JETZT tut, nicht was
  es einmal tun soll — Zukunftspläne gehören in den Status-Blockquote oben
  oder nach docs/ROADMAP.md, nicht in den Pitch. Kein Bild/keine Metapher, die
  sich selbst im nächsten Halbsatz widerspricht (Negativbeispiel ui.nvim vor
  2026-09-12: "The frame around the window [...] — which it does not do yet,
  because it is still standing on one." liest sich wie eine Selbstkorrektur
  mitten im ersten Satz, nicht wie eine Beschreibung). Wenn der Satz nicht
  ohne Nebensatz-Verrenkung auskommt, ist er zu kompliziert für die erste
  Zeile — kürzen, nicht verschachteln.
-->
{{One-sentence pitch. At most one more short sentence of context.}}

---

## Documentation

<!--
  Der einzige inhaltliche Abschnitt außer Titel/Art/Badges/Pitch und Lizenz.
  Volle Referenz (Requirements, Installation, Quickstart, Config-Optionen mit
  Defaults, Commands, Health-Check-Details, Contributing-Ablauf, Architektur-
  Begründungen) steht NICHT hier, sondern in docs/ — hier nur der Link plus
  ein Halbsatz, welche Frage die Seite beantwortet. Gruppen sind ein
  Vorschlag, keine Pflicht: umbenennen, zusammenlegen oder weglassen, wenn es
  für das Plugin sinnvoller ist. Reihenfolge innerhalb einer Gruppe frei.

  Links auf eigene docs/-Dateien: relativ (docs/foo.md). Links auf andere
  Repos (Schwesterplugins, lib.nvim, externe Tools): volle GitHub-URL. Siehe
  Begründung unten unter "Warum relative Links für docs/".
-->
Start at [docs/README.md](docs/README.md) — what's where, and which question
each page answers.

**The Basics**

- [Requirements](docs/requirements.md) — Neovim version, required plugins and CLI tools.
- [Installation](docs/installation.md) — plugin managers and load-trigger variants.
- [Quickstart](docs/quickstart.md) — the first thing to run after installing.

**Configuration**

- [What you get with the defaults](docs/what-you-get.md) — the 5–8 things that matter on day one.
- [All options](docs/configuration.md) — every `setup()` option and its default.
- [Commands](docs/commands.md) / [Bindings cheatsheet](docs/BINDINGS.md)

**The Rest**

<!-- Nur die Zeilen behalten, die für dieses Plugin wirklich existieren. -->
- [Around it](docs/around-it.md) — how this plugin's scope differs from its siblings in the collection.
- [What it does and what not](docs/scope.md)
- [Why it does it that way](docs/architecture.md)
- [Health check](docs/health.md) — what `:checkhealth {{name}}` reports, line by line.
- [Cross-platform notes](docs/cross-platform.md)
- [Contributing](docs/CONTRIBUTING.md)
- [Feedback](https://github.com/StefanBartl/{{name}}.nvim/issues)

`:help {{name}}` is the same reference inside the editor.

---

## License

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

{{name}}.nvim is released under the [MIT License](https://opensource.org/licenses/MIT).

<!--
  ====================================================================
  Offene Entscheidungen / Diskussion — beim Kopieren in ein echtes
  README entfernen. Hier nur festgehalten, weil Fassung 3 frisch ist.
  ====================================================================

  1. Relative Links vs. volle GitHub-URLs für docs/-Seiten:
     Bewusst RELATIV geblieben (docs/foo.md), nicht auf volle
     https://github.com/StefanBartl/{{name}}.nvim/blob/main/docs/foo.md
     umgestellt. Gründe:
       - GitHub löst relative Links im Repo-Kontext korrekt auf — kein
         Nachteil dort.
       - Wer das README lokal liest (images.nvim/hover.nvim im Editor,
         ein Checkout im Dateimanager, der geklonte Ordner im
         Plugin-Manager-Cache unter lazy/{{name}}.nvim/), bekommt einen
         Link, der sofort und ohne Netzwerk auf die lokale Datei zeigt.
         Eine volle GitHub-URL öffnet in diesem Fall immer einen Browser.
       - Volle URLs binden den Kontonamen/Branch fest in die Datei ein;
         bei einem Fork, Mirror oder Rename bricht der Link, ein
         relativer nicht.
       - Der Fall, in dem volle URLs tatsächlich Vorteile haben —
         Registries wie npm/PyPI, die ein README ohne Repo-Kontext
         rendern, oder ein Link, der auf einen GESPERRTEN Tag/Branch
         zeigen soll statt auf `main` — trifft auf Neovim-Plugins nicht
         zu: es gibt keine solche Registry, und docs/ zieht mit jedem
         Commit im selben Repo mit.
     Volle GitHub-URLs bleiben reserviert für: Schwesterplugins
     (StefanBartl/andere.nvim), lib.nvim, externe Tools/Projekte,
     GitHub Issues/Discussions/Actions.

  2. Kein eigener "## Table of contents"-Abschnitt mehr:
     Fassung 2 hatte einen. Fassung 3 lässt ihn weg, weil das README
     jetzt selbst schon fast nur Titel + Pitch + EIN Link-Abschnitt +
     Lizenz ist — ein Inhaltsverzeichnis für ein Inhaltsverzeichnis ist
     doppelte Struktur ohne Nutzen. Sollte ein Plugin doch wieder mehr
     eigene Prosa-Abschnitte brauchen (z. B. weil "Around it" als
     eigener sichtbarer Abschnitt bevorzugt wird, siehe Punkt 3), kommt
     der ToC zurück, sobald es wieder mehr als ~4 Top-Level-Abschnitte
     gibt.

  3. "Around it", "Contributing", "Feedback" sind jetzt Links in der
     Doku-Liste statt eigene Abschnitte. Bei Plugins, wo die Abgrenzung
     zu einem Schwesterplugin oft zu Verwechslung führt (Beispiel:
     mdview.nvim vs. markdown.nvim), kann "Around it" trotzdem als
     eigener kurzer Blockquote-Abschnitt direkt nach dem Pitch stehen,
     wenn das dem Leser schneller sagt, ob er im richtigen Repo ist. Im
     Zweifel: in der Doku-Liste lassen, das ist der schlankere Default.

  4. Stimme/Ton: keine Selbstwidersprüche im Pitch (Punkt oben), keine
     Fortschritts-Prosa ("Schritt 3 tat X") im README — das ist
     Commit-/Changelog-Material und gehört, wenn überhaupt, nach
     docs/ROADMAP.md. Ein README beschreibt einen Zustand, kein
     Tagebuch.
-->
