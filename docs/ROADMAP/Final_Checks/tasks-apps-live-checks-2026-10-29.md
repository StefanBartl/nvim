# tasks-desktop / tasks.nvim (App) — Live-Checks (Stand 2026-10-29)

Handläufe für die Tasks-App, die nur auf echten Systemen gehen: sauberes Benutzerkonto, echter Mac,
echter Explorer/Finder, echte Anmeldung. Jeder Abschnitt gehört zu einer Task im `tasks-vault`;
ist er durch, die Task schließen (`done`) oder mir die Ergebnisse geben. Ein Befund: unter
"Falls rot" eine Zeile, daraus wird eine `kind: bug`-Task.

**WICHTIG: Die Apps nicht auf der Workstation verwenden.** Diese Läufe gehören auf den eigenen
Rechner, ein sauberes Zweitkonto bzw. einen Mac. Nur Abschnitt 5 (Runner-Autostart) und die
Install-Probe aus Abschnitt 6 betreffen bewusst die Workstation.

**Vorher (alle Abschnitte):**

- Ein normales, nicht erhöhtes Terminal (nicht aus einer Claude-Sitzung: die Claude-App leitet
  AppData und HKCU um).
- Rolling-Build `latest` von `tasks-desktop` (Pre-Release, nach jedem grünen CI-Lauf von `main`
  neu gebaut): Download und Installation per `install.ps1` (README, Abschnitt "Install from a
  release"):

```powershell
gh release download latest -R WKDSteve/tasks-desktop -p install.ps1 -D $env:TEMP --clobber
$env:GH_TOKEN = (gh auth token); & "$env:TEMP\install.ps1"
```

- `tasks-hub --version` nennt den Commit des Builds; unter Notizen mitschreiben.
- Neovim 0.10+ samt Checkouts von `tasks.nvim` und `lib.nvim` (Engine), bis
  `tasks-app-neovim-buendeln` sie mitliefert.

## Inhalt

1. Hand-Prüfung: Kacheln der Übersicht und Filter im echten Tauri-Fenster
2. `.exe` auf sauberem Benutzerkonto von Hand durchspielen
3. Mac-Test und dmg auf einem echten Mac (Gatekeeper, Entfernen)
4. Ordner des Vaults zeigen (explorer, open, xdg-open)
5. P6a: Ordner-Task in anderen Bereich verschieben, auf macOS
6. Runner-Autostart beim echten Anmelden
7. Verweis: Handarbeit nach dem Umzug

---

## 1. Kacheln der Übersicht und Filter im echten Tauri-Fenster (WebView2)

Task: `tasks-desktop/hand-pruefung-kacheln-der-uebersicht-und-filter-im-echten-ta`
(Tags app, webui, manual; plan `tasks.nvim/tasks-app`).

**Vorbereitung:** Das Tauri-Fenster (WebView2, `dragDropEnabled: false`) gibt es noch nicht:
`crates/tasks-app` fehlt in `tasks-desktop` (Stand `55f05d9`), die Task `tasks-app-tauri-huelle`
(P7) ist offen. Sobald die Hülle steht: App starten, Vault mit ein paar Tasks wählen, Ansicht
"Heute" (Übersicht mit Kacheln) öffnen. Bis dahin läuft derselbe Test nur im Browser
(`tools/dev-hub.ps1`), das ersetzt den Handlauf nicht.

**Kacheln:**

- [ ] Eine Kachel mit der **Maus** ziehen und an anderer Stelle ablegen: die Reihenfolge ändert
      sich, die Meldung "<Kachel> ist jetzt Nummer N von M" erscheint (Tooltip der Kachel:
      "Diese Kachel verschieben: ziehen oder mit den Pfeiltasten hoch und runter")
- [ ] Kachel per **Knopf** "Diese Kachel nach oben" / "nach unten" verschieben: wandert um eine Stelle
- [ ] Kachel per **Pfeiltaste hoch/runter** (Fokus auf dem Griff): wandert um eine Stelle
- [ ] Menü **Ansicht > Anordnung der Kacheln zurücksetzen**: Standardreihenfolge ist zurück
- [ ] Angepasste Reihenfolge, Fenster schließen und neu öffnen: die Reihenfolge bleibt

**Filter:**

- [ ] Filter "mindestens" und "höchstens" setzen (z. B. Priorität; Hinweis im Dialog: 1 ist die
      dringendste, "mindestens 2" nimmt 2 und 3) und einen Zeitraum (z. B. Erinnerungsdatum)
- [ ] Die Chips zeigen "<Feld>: mindestens a" bzw. "höchstens b"; die Zählung "Filter an: X von Y
      Tasks" stimmt
- [ ] Fenster ganz schließen (nicht nur verbergen) und neu starten: dieselben Filter sind noch an

**Falls rot:** notieren, welcher Schritt, ob nur im Tauri-Fenster oder auch im Browser (dann ist
es kein WebView2-Problem), Konsole des Fensters falls erreichbar. Bug-Task.

**Fragen:** Gibt es für das Tauri-Fenster schon einen Weg zu starten (Task `tasks-app-tauri-huelle`
ist offen)? Wenn nein, ist diese Task bis P7 blockiert.

**Danach:** Task mit `done` schließen, sonst Ergebnis in Notizen.

---

## 2. `.exe` auf sauberem Benutzerkonto von Hand durchspielen

Task: `tasks-desktop/tasks-desktop-exe-auf-sauberem-benutzerkonto-von-hand-durchs`
(plan `ALL/native-apps-tauri-huelle-installer-web-variante`, phase installer; nach
`tasks.nvim/tasks-desktop-exe-bei-jedem-commit`).

**Vorbereitung:**

- Neues, lokales Windows-Benutzerkonto (ohne Checkouts, ohne Einstellungen, ohne Neovim), nicht
  die Workstation. Anmelden, Browser.
- `tasks-hub-windows-x86_64.exe` aus dem Pre-Release `latest` in `WKDSteve/tasks-desktop`
  laden (Repo privat: Anmeldung nötig; SHA-256 gegen `SHA256SUMS` prüfen).
- Als Zweitfall später: dasselbe mit installiertem Neovim, aber ohne Checkouts.

**Schritte:**

- [ ] Doppelklick auf `tasks-hub-windows-x86_64.exe` (SmartScreen: "More info", "Run anyway"):
      die Konsole fragt nacheinander nach Vault-Ordner, Installation in den Benutzerordner,
      Autostart und Desktop-Link
- [ ] Der Browser öffnet sich mit dem Pairing-Link
- [ ] Zweiter Doppelklick: fragt **nichts** und öffnet nur das Fenster bzw. einen neuen Link
- [ ] Ohne Neovim und ohne Engine-Checkouts: eine **klare Meldung** (was fehlt); keine Konsole,
      die sich schließt (sie wartet auf Enter)
- [ ] `tasks-hub --version` nennt den Commit; `tasks-hub stop` beendet den Hub
- [ ] Aufräumen: `tasks-hub uninstall`, danach die Datei löschen

**Falls rot:** genaue Meldung, Schritt, Windows-Version notieren; jeder Befund als Bug-Task
(Akzeptanz der Task verlangt das).

**Danach:** Task mit `done` schließen, sonst Ergebnis in Notizen.

---

## 3. Mac-Test und dmg auf einem echten Mac (Gatekeeper, Entfernen)

Task: `tasks-desktop/tasks-desktop-mac-test-und-dmg-auf-einem-echten-mac-gatekeep`
(Kontext und Akzeptanz der Task sind leer).

**Unklar (Fragen, bevor es losgeht):**

- Gibt es überhaupt schon eine `.dmg`? README: "Only Windows is built and tested", keine
  Mac-Archive im Release. Die Planung (`tasks-desktop-installer-als-github-release-...`)
  empfiehlt, die `.dmg` bis zum echten Test wegzulassen. Soll hier also zuerst "Hub aus dem
  Quelltext auf dem Mac bauen" geprüft werden, und die `.dmg` kommt erst mit P7?
- Was zählt als bestanden (Gatekeeper-Hinweis in der README, Entfernen = Programm plus
  Launch-Agent weg)? Bitte Akzeptanz in der Task ergänzen.

**Vorläufiger Ablauf (aus README, Abschnitt Use):**

- [ ] Auf dem Mac: Rust, Node, Neovim 0.10+, Checkouts von `tasks.nvim` und `lib.nvim`;
      `cargo build --release` in `tasks-desktop`
- [ ] `tasks-hub start --open` (Hub im Hintergrund, Browser mit Pairing-Link): Seite lädt
- [ ] Gatekeeper: die selbst gebaute Datei startet ohne Warnung? Eine geladene, unsignierte
      Datei: Meldung notieren und wie man sie freigibt (Rechtsklick > Öffnen)
- [ ] `tasks-hub install --autostart`: Launch-Agent entsteht (`~/Library/LaunchAgents`), Hub
      startet nach Abmelden/Anmelden
- [ ] `tasks-hub uninstall`: Hub gestoppt, Launch-Agent weg, Vault unberührt
- [ ] Falls eine `.dmg` existiert: öffnen, App nach Programme ziehen, starten, Gatekeeper-
      Meldung notieren, Entfernen durch Löschen der App; verbleibende Reste (Launch-Agent,
      Einstellungen) notieren

**Falls rot:** Meldung, macOS-Version, Chip (Intel/Apple Silicon); Bug-Task.

**Danach:** Task mit `done` schließen, sonst Ergebnis in Notizen. Abschnitt 5 lässt sich im
selben Mac-Termin erledigen.

---

## 4. Ordner des Vaults zeigen (explorer, open, xdg-open)

Task: `tasks-desktop/tasks-desktop-ordner-des-vaults-zeigen-explorer-open-xdg-ope`
(Code: `reveal_plan` in `crates/tasks-hub/src/editor.rs`, `POST /api/tasks/vault_reveal`).

**Vorbereitung:** Hub läuft (`tasks-hub start --open`). Bis auf die Tauri-Hülle ist
die Seite im Browser gekoppelt (in `tasks.html` ohne Hub fehlt der Menüpunkt, das ist gewollt).
Zwei Vaults zum Testen: einer mit Leerzeichen im Pfad, einer mit sehr langem Pfad
(über 200 Zeichen).

**Windows (eigener Rechner, nicht Workstation):**

- [ ] Menü **Projekt > Vault-Ordner zeigen** ("Show vault folder"): der Explorer öffnet
      genau den Vault-Ordner (nicht Dokumente oder einen anderen Ordner)
- [ ] Dasselbe mit Leerzeichen im Pfad
- [ ] Dasselbe mit sehr langem Pfad: Ordner geht auf oder die Seite meldet den Grund (kein
      Absturz, kein stilles Nichts)

**Linux:**

- [ ] Mit `xdg-open`: der Dateimanager öffnet den Vault-Ordner
- [ ] Ohne `xdg-open` (z. B. `PATH` ohne): die Seite meldet den Grund, kein Absturz

**macOS (falls ein Mac da ist, gemeinsam mit Abschnitt 3):**

- [ ] `open`: der Finder öffnet den Vault-Ordner

**Falls rot:** Betriebssystem, Pfad (ohne Kundendaten), Meldung der Seite; Bug-Task.

**Danach:** Ergebnis je System in die Notizen der Task, dann `done`.

---

## 5. P6a: Ordner-Task in anderen Bereich verschieben, auf macOS

Task: `tasks.nvim/tasks-app-p6a-ordner-task-in-einen-anderen-bereich-verschieb`
(plan `tasks.nvim/tasks-app`, phase p6a). Windows und Linux sind automatisch geprüft
(`crates/hub-testkit/tests/real_events.rs`); macOS meldet Umbenennungen über FSEvents anders.

**Vorbereitung:** Mac mit Hub (siehe Abschnitt 3) und einem Test-Vault mit einem **Ordner-Task**
(Ordner mit `<slug>.md` und einer Datei daneben) in Bereich A und einem zweiten Bereich B.

**Schritte (Weg 1: in der App):**

- [ ] Ordner-Task im Detail in Bereich B verschieben: die App zeigt ihn **binnen zwei Sekunden**
      unter der neuen Id
- [ ] Die Datei neben der Task-Datei ist mitgewandert (im Finder nachsehen)
- [ ] Undo bringt den Ordner zurück

**Weg 2: aus Neovim bei offener App:**

- [ ] Denselben Ordner in Neovim mit `:Tasks` (move_area) verschieben, während die App offen
      ist: die App folgt ohne Neuladen

**Oder (deckt beides ab):**

- [ ] `cargo test --workspace --locked` mit `TASKS_DESKTOP_REQUIRE_ENGINE=1` auf dem Mac grün

**Falls rot:** welcher Weg, Wartezeit, ob die App die alte Id stehen lässt oder doppelt zeigt;
Bug-Task mit Ausgabe des Tests.

**Danach:** Task mit `done` schließen (oder Ergebnis in Notizen).

---

## 6. Runner-Autostart beim echten Anmelden

Task: `ALL/runner-autostart-beim-anmelden-erproben`. Hintergrund: `:MyPlugins runner autostart on`
(nvim-config `c3864cc97`) legt die geplante Aufgabe "GitHub Runners" an (Auslöser "bei
Anmeldung", Benutzer `bartl`, interaktiv, nicht erhöht; Befehl `pwsh -NoProfile -WindowStyle
Hidden -File ...\runners.ps1 ensure all`). Auf Befehl lief sie am 2026-10-27 (alle elf Runner);
der echte Auslöser ist ungesehen. Hier ist ausdrücklich die Workstation gemeint.

**Vorbereitung:** Offene Arbeit speichern; ein normales PowerShell bereit.

- [ ] Aufgabe vorhanden: `Get-ScheduledTask -TaskName 'GitHub Runners'` (Zustand Ready)
- [ ] Windows **abmelden**, wieder **anmelden**, **zwei Minuten warten**
- [ ] `pwsh $env:NVIM_CONFIG_DIR\scripts\runners.ps1 status all`: alle elf Runner
      `local=running` und `github=online`
- [ ] `pwsh $env:NVIM_CONFIG_DIR\scripts\runners.ps1 check`: Ergebnis `missing: 0`
      (die Runner starten mit dem PATH der Anmeldung: scoop-Shims, cargo; `ensure` warnt, falls
      etwas fehlt)

**Falls rot:** Meldung der Aufgabe in die Notizen der Task:

```powershell
Get-ScheduledTaskInfo -TaskName 'GitHub Runners'
```

(`LastTaskResult`, `LastRunTime`), dazu welche Runner nicht laufen und die Warnzeilen von
`runners.ps1 ensure`.

**Danach:** Task mit `done` schließen.

---

## 7. Verweis: Handarbeit nach dem Umzug

Task: `ALL/handarbeit-nach-umzug-schritt-fuer-schritt` ist selbst schon die Schritt-für-Schritt-
Liste (Abschnitte A bis E mit kopierbaren Befehlen; Spiegel:
`$NVIM_CONFIG_DIR/docs/ROADMAP/HANDARBEIT-NACH-UMZUG.md`). Hier nicht dupliziert. Berührungspunkt
mit diesen Checks: Abschnitt A (Install-Probe der Apps mit Token auf der Workstation, darunter
`tasks-desktop`: `tasks-hub open`; bekannt: `tasks-hub start` endet dort evtl. still mit
`0xE0000027`, dann `tasks-hub serve` im Vordergrund probieren).

- [ ] Reihenfolge-Vorschlag der Task: C (5 Min), B, D, zuletzt A

---

## Nicht aufgenommen

- `ALL/probe-seite-web-variante-workstation`: kein reiner Hand-Test mehr (Status `doing`,
  actor `pair`); die Handläufe sind gemacht, es bleibt nur die Woche ohne Meldung der IT
  (bis 2026-11-04). Läuft in einem anderen Chat.

## Befunde

(hier eintragen: Abschnitt, Schritt, Meldung)
