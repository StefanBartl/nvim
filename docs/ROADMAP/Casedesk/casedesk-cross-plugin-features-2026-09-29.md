# Bericht: Cross-Feature-Kandidaten für casedesk.nvim aus den anderen .nvim-Plugins (2026-09-29)

## Table of content

  - [Auftrag](#auftrag)
  - [A. Bereits integriert (Bestand, zur Einordnung)](#a-bereits-integriert-bestand-zur-einordnung)
  - [B. Konkrete neue Kandidaten (empfohlen, absteigend nach Nutzen)](#b-konkrete-neue-kandidaten-empfohlen-absteigend-nach-nutzen)
    - [1. `ai.nvim` → `:Case ki` ohne Zwischenablage-Umweg](#1-ainvim-case-ki-ohne-zwischenablage-umweg)
    - [2. `hover.nvim` → Vorschau auf `[Log.txt](../assets/Log.txt)`- und Doku-Links](#2-hovernvim-vorschau-auf-logtxtassetslogtxt-und-doku-links)
    - [3. `gitsuite.nvim` → Herkunft einer Case-Datei](#3-gitsuitenvim-herkunft-einer-case-datei)
    - [4. `data.nvim` → `.case.json` direkt als JSON bearbeiten](#4-datanvim-casejson-direkt-als-json-bearbeiten)
    - [5. `insights.nvim` → `:Insights compress` für einen Case-Ordner](#5-insightsnvim-insights-compress-fr-einen-case-ordner)
    - [6. `cmdlog.nvim` → ergänzendes Audit "welche :Case-Kommandos liefen heute"](#6-cmdlognvim-ergnzendes-audit-welche-case-kommandos-liefen-heute)
    - [7. `mdview.nvim` → Summary.md/Reply vor dem Copy-Paste ins SNOW-Ticket gegenchecken](#7-mdviewnvim-summarymdreply-vor-dem-copy-paste-ins-snow-ticket-gegenchecken)
    - [8. `media.nvim` → Standbild aus einem Kunden-Screen-Recording](#8-medianvim-standbild-aus-einem-kunden-screen-recording)
  - [C. Geprüft, nicht empfohlen (mit Begründung)](#c-geprft-nicht-empfohlen-mit-begrndung)
  - [Zusammenfassung](#zusammenfassung)

---

## Auftrag

casedesk.nvim ist das private Werkzeug-Repo für die SAP-Support-Fallarbeit
(Tosca/Tricentis), WKDBook-Tricentis das dazugehörige Dokumentations- und
Wissens-Repo (Cases/, Workflow/Templates, Notes/, Terminologie/, Tosca/) —
beide privat, WKDBook-Tricentis liefert selbst keine Plugin-Features, aber
seinen Inhalt (Markdown-Dateien, `.case.json`-Sidecars, Anhänge, git-Historie)
bearbeiten die Tools.

Frage: Welche der **anderen** eigenen `.nvim`-Plugins könnten mit ihren
**bestehenden** Features die Arbeit **an casedesk** sinnvoll unterstützen —
nicht umgekehrt. casedesk bleibt Konsument, nie Anbieter.

**Methode:** Alle 39 Repos unter `$REPOS_DIR` (Liste vom Nutzer bestätigt)
per README/`@brief`-Docstring gesichtet, gegen casedesk.nvim's tatsächlichen
Workflow gespiegelt (Case-Ordner = Markdown + Anhänge + `.case.json`, git-
getrackt, kein Code — das unterscheidet die Bewertung grundlegend von "welche
Plugins helfen beim *Programmieren*"). `docs/installation.md`/
`docs/around-it.md` in casedesk.nvim selbst waren die Quelle für "bereits
integriert" — nicht neu geraten.

---

## A. Bereits integriert (Bestand, zur Einordnung)

Diese laufen schon als weiche Abhängigkeiten in casedesk.nvim — kein neuer
Vorschlag, nur damit unten klar ist, was schon abgedeckt ist:

| Plugin | Wo in casedesk |
| --- | --- |
| **pickers.nvim** | `:Case files`/`:Case grep`/`:Cases files`/`:Cases livegrep` (diese Session) |
| **spotlight.nvim** | Hervorhebung in Activity Streams |
| **images.nvim** | Anhangs-Vorschau, `:Case ocr` nutzt `images.ocr` |
| **pdfport.nvim** | PDF-Anhänge im Buffer gerendert |
| **replacer.nvim** | Bulk-Edits über die Dateien eines Case |
| **language.nvim** | `:Case reply check`'s Rechtschreibprüfung (`spell_wordlists`) |
| **emojis.nvim** | `:Case reply check`'s Emoji-Zähler ("Emojis N found — press 'c' to remove") |
| **open.nvim** | Links/Ordner öffnen |
| **diff.nvim** | `:Case diff` — zwei Cases' Streams/Lösungen vergleichen |
| **markdown.nvim** | TOC/Heading-Navigation, kein Wiring nötig (jede Case-Datei ist Markdown) |
| **cascade.nvim** | Listen-/Checkbox-Fortsetzung in `Task.md`/`Notes.md` |
| **sessions.nvim** | Eine Session pro Case, `:Case new` legt sie automatisch an |
| **filetree.nvim** | Ordner-Reveal bei `:Case open` |

---

## B. Konkrete neue Kandidaten (empfohlen, absteigend nach Nutzen)

### 1. `ai.nvim` → `:Case ki` ohne Zwischenablage-Umweg

**Ist-Zustand:** `:Case ki` baut den Prompt (Rolle + Policies + Activity
Stream + Fakten-Block), kopiert ihn in die Zwischenablage, der Chat läuft
extern (Browser-Tab), die Antwort wird von Hand zurückkopiert und mit
`:Case ki import` zerlegt (Analyse → Research, Replyentwurf → Replies,
interne Notiz → Notes.md). Drei manuelle Schritte, jedes Mal.

**Vorschlag:** `ai.nvim` (`require("ai").ask(...)`/`.stream(...)`,
provider-agnostisch, `lib.nvim`-basiert) direkt hinter `:Case ki` hängen —
optional, nicht ersetzend: ein Flag oder ein zweiter Verb
(`:Case ki --send` o.ä.), der den gebauten Prompt statt (oder zusätzlich zu)
der Zwischenablage direkt an `ai.stream()` gibt und die Antwort inline in
einem Panel zeigt, bevor sie denselben `ki_import`-Parser durchläuft wie
heute die von Hand eingefügte.

**Warum das passt:** Es ersetzt keinen Mechanismus, es überspringt nur den
Zwischenablage-Umweg — `ki_import`s Drei-Wege-Zerlegung (Analyse/Reply/Notiz)
bleibt exakt gleich, nur die Quelle wechselt von "Zwischenablage" zu "direkte
Antwort". Kein Codepfad in `ki.lua` müsste weg, nur einer dazu.

**Zu bedenken:** Ein Activity Stream enthält Kundennamen/-daten. Der
händische Copy-Paste-Weg lässt bewusst wählen, in welchen externen Chat
eingefügt wird; eine automatisierte Anbindung würde stillschweigend den in
`ai.nvim` konfigurierten Provider nutzen. Sauberer Default: `:Case anonymize`
(existiert schon, PII-Scrub) als Pflichtschritt vor einem automatisierten
Send, nicht nur als Empfehlung.

---

### 2. `hover.nvim` → Vorschau auf `[Log.txt](../assets/Log.txt)`- und Doku-Links

`hover.nvim`s eigene Beschreibung nennt explizit "a markdown link, or a
path" als Trigger — genau die Form, die `:Case insert asset` erzeugt
(`[Log.txt](../assets/Log.txt)`), und genau die docs.tricentis.com-Links,
die `:Case links`/`:Case reply check` prüfen. Cursor auf so einen Link,
Float zeigt Zielinhalt (Bilddatei, PDF-Seite, Markdown-Abschnitt, oder "gibt
es nicht" — laut eigenem Modul-Doc oft die nützlichste Antwort) — ohne den
Buffer zu wechseln.

**Aufwand:** Voraussichtlich null Wiring in casedesk.nvim nötig — `hover.nvim`
ist laut eigenem Anspruch adapter-/kontextagnostisch und braucht keine
Konfiguration pro Zielplugin. Einfach installieren/aktivieren, ausprobieren
ob es die relativen `assets/`-Pfade und `docs.tricentis.com`-URLs schon ohne
Weiteres trifft.

---

### 3. `gitsuite.nvim` → Herkunft einer Case-Datei

Der Case-Baum (`Cases/SAP_Support/Cases/...`) ist Teil des git-getrackten
WKDBook-Tricentis-Repos — `usage.lua`s eigene Dokumentation warnt sogar
explizit davor, Datei-mtimes als Aktivitätssignal zu nehmen, weil `git pull`
sie überschreibt (26 von 27 Cases trugen nach einem Pull dieselbe Sekunde).
`:Case timeline` filtert solche Bulk-Stempel deshalb schon als "Artefakt"
heraus, verliert dabei aber die Information selbst: WER hat diese
Summary.md zuletzt bearbeitet, auf welcher Maschine, wann wirklich (nicht
beim letzten Pull)?

**Vorschlag:** `:Git blame`/`:Git diff history` (gitsuite.nvim hat beides)
auf der aktuellen Case-Datei als zusätzliche Zeile in `:Case info`s
Infocard oder als eigener Menüpunkt — ergänzt `:Case timeline`s
mtime-Rekonstruktion um die echte Versions-Historie, gerade bei
Mehr-Maschinen-Sync (dasselbe Problem, das SESSIONS.md schon für
Buffer-Layout löst, hier für Datei-Historie).

---

### 4. `data.nvim` → `.case.json` direkt als JSON bearbeiten

`.case.json` ist die Sidecar-Datei jedes Case — im Normalfall über `:Case
info`s Edit-Formular gepflegt, aber `data.nvim`s `:JSON pretty --reg=+`
(pretty-print ohne Buffer-Wechsel) oder ein `:JSON`-Filter direkt auf die
Datei wäre die schnellere Route für: ein Feld reparieren, das das Formular
nicht abdeckt, oder eine roh eingefügte JSON-Antwort aus einem
Support-Tool/einer API lesbar machen, bevor sie irgendwo hin kopiert wird.
Punktueller Nutzen, kein Wiring nötig — einfach `:JSON pretty` auf einer
`.case.json` oder einem eingefügten JSON-Blob aufrufen.

---

### 5. `insights.nvim` → `:Insights compress` für einen Case-Ordner

Der einzige Teil von insights.nvim, der nicht code-spezifisch ist:
`:Insights compress` packt einen beliebigen Verzeichnisbaum (tar/zip auf
Unix, `Compress-Archive` unter PowerShell — also nativ unter Windows, ohne
externes Tool). Sinnvoll, um einen ganzen Case-Ordner oder nur `assets/`
vor dem Verschicken/Archivieren zu zippen. Der Rest von insights.nvim
(Symbols, Metrics, Smells, Imports, Tree, Conflicts, Unimported, Devserver)
ist durchweg auf Code-Projekte zugeschnitten und passt nicht — Case-Ordner
sind Markdown + Anhänge, kein Code.

---

### 6. `cmdlog.nvim` → ergänzendes Audit "welche :Case-Kommandos liefen heute"

`:Cmdlog project`/`:Cmdlog stats` protokollieren `:`-Kommandos pro Projekt
mit eigener Statistik — unabhängig von casedesk.nvim's eigenem
`usage.lua`-Journal (das nur *welcher Case* genutzt wurde trackt, nicht
*welches Kommando*). Käme "for free", ohne dass casedesk irgendetwas dafür
tun muss — cmdlog zeichnet ohnehin jedes `:Case ...`/`:Cases ...` auf, sobald
es aktiv ist. Eher nice-to-have als Lücke.

---

### 7. `mdview.nvim` → Summary.md/Reply vor dem Copy-Paste ins SNOW-Ticket gegenchecken

Rendert Markdown live im Browser. SNOW selbst rendert kein Markdown, aber ein
gerenderter Blick auf `Summary.md` oder einen Reply-Entwurf vor dem
Kopieren hilft, Formatierungsfehler (kaputte Listen, falsch verschachtelte
Überschriften) zu sehen, die im rohen Text leicht übersehen werden.
Spekulativ, aber im Zweifel ein einzelner `:MdView`-Aufruf.

---

### 8. `media.nvim` → Standbild aus einem Kunden-Screen-Recording

Falls ein Kunde mal eine Bildschirmaufnahme statt eines Screenshots schickt
(kommt vor, ist aber der Ausnahmefall) — dieselbe Bauart wie `pdfport.nvim`
(ein externes Tool, ein Verb), das schon integriert ist. Niedrige Priorität,
aber billig nachzuziehen, falls der Fall öfter auftritt.

---

## C. Geprüft, nicht empfohlen (mit Begründung)

| Plugin | Warum nicht |
| --- | --- |
| `buffer-ctx.nvim` | Format/Mark + generische Insert/Copy-Snippets — kein erkennbarer Case-spezifischer Mehrwert über `:Case insert` hinaus |
| `reposcope.nvim` | Repos von GitHub/GitLab/Codeberg suchen/klonen — casedesk arbeitet in einem festen Repo, braucht keine neuen |
| `insights.nvim` (Rest) | Symbols/Metrics/Smells/Imports/Tree/Conflicts/Unimported/Devserver — durchweg code-projektspezifisch |
| `documentation.nvim` | Modul-Karten für annotierten Lua-Code — relevant fürs *Warten von casedesk.nvim selbst*, nicht für die Support-Arbeit |
| `rules.nvim` | Check-Engine für Code-Regeln/Waivers — dito, Plugin-Entwicklung, nicht Case-Arbeit |
| `runtime-analysis.nvim` | HTTP-Request-Runner — nur relevant, falls SNOW/SAP Resolve je eine dokumentierte REST-API bekommt, die man direkt anspricht; aktuell rein spekulativ |
| `recommender.nvim` | Lua-Alias-Vorschläge — reines Code-Tooling |
| `lsp.nvim`, `dap.nvim`, `debugging.nvim` | LSP-Setup, Debug-Adapter — keine Berührung mit Markdown-Case-Arbeit |
| `gopath.nvim` | Go-Importpfade — keine Go-Arbeit im Case-Kontext |
| `sandbox.nvim` | Docker/Podman/nerdctl-Orchestrierung — kein Hinweis, dass Cases Container-Reproduktion brauchen |
| `github_stats.nvim` | GitHub-Traffic-Stats — relevant höchstens für casedesk.nvim als OSS-Repo, nicht für die Support-Arbeit |
| `color_my_ascii.nvim` | rein kosmetisch |
| `my.nvim` | reine Editor-Optik/-Verhalten (Highlights, Optionen, Einrückung) — kein Feature-Träger |
| `ui.nvim`, `lib.nvim` | bereits Fundament (Hard Dependencies), keine "neue" Integration möglich/nötig |

---

## Zusammenfassung

Stärkster Einzelvorschlag: **`ai.nvim`** hinter `:Case ki`, weil es einen
bestehenden, dokumentierten Drei-Schritt-Handumweg (kopieren → extern
einfügen → zurückkopieren) auf einen Schritt verkürzt, ohne
`ki_import`s Logik anzufassen. Zweitstärkster: **`hover.nvim`**, weil es
praktisch ohne Wiring auskommt und genau die Link-Form abdeckt, die
`:Case insert asset` schon erzeugt. Der Rest (`gitsuite.nvim`, `data.nvim`,
`insights.nvim compress`, `cmdlog.nvim`, `mdview.nvim`, `media.nvim`) ist
jeweils punktuell nützlich, aber kein Muss.

Keiner der Vorschläge verlangt eine Änderung an bestehenden casedesk.nvim-
Verben — jeder wäre ein zusätzlicher, optionaler Pfad neben dem, was heute
schon funktioniert.

---

