# `bcdedit /set testsigning on`

Mit dem Befehl `bcdedit /set testsigning on` hast du den **Test-Modus (Test Signing Mode)** des Windows-Kernels aktiviert.

## Table of content

  - [Was wurde genau gemacht?](#was-wurde-genau-gemacht)
  - [Welche Gefahren birgt das?](#welche-gefahren-birgt-das)
  - [Kannst du erst mal so weiterlaufen lassen?](#kannst-du-erst-mal-so-weiterlaufen-lassen)
  - [Wann und wie solltest du das zurücksetzen?](#wann-und-wie-solltest-du-das-zurcksetzen)

---

## Was wurde genau gemacht?

Standardmäßig verlangt Windows, dass jeder Kernel-Treiber (also Software, die tief im System direkt mit der Hardware spricht, wie `toupcam.sys`) von Microsoft offiziell zertifiziert und signiert wurde.

Durch diesen Befehl hast du dem Windows-Bootloader (BCD = Boot Configuration Data) mitgeteilt: *„Erlaube das Laden von Treibern, die mit Test-Zertifikaten signiert oder veraltet sind.“*
Das umgeht die strenge Driver Policy und erlaubt es deinem alten ToupTek-Treiber, sich fehlerfrei in den Kernel einzuhängen.

---

## Welche Gefahren birgt das?

Der Test-Modus ist primär für Entwickler gedacht, die eigene Treiber testen. Er schwächt die Systemsicherheit an einer sensiblen Stelle ab:

* **Open-Door für ungeprüfte Kernel-Software:** Da der Kernel nun weniger wählerisch bei Signaturen ist, könnten theoretisch auch bösartige Programme (Rootkits oder schlecht programmierte Malware), die sich als Treiber tarnen, leichter auf die unterste Systemebene vordringen.
* **Stabilität:** Nicht von Microsoft abgenommene Kernel-Treiber sind oft der Hauptgrund für Bluescreens (BSOD – *Blue Screen of Death*), falls der Treiber fehlerhaft ist oder Speicherlecks hat.

---

## Kannst du erst mal so weiterlaufen lassen?

**Ja, absolut.** Wenn dein PC kein hochsensibles Firmen-Notebook oder ein extrem kritischer Online-Banking-PC ist, kannst du das im Alltag problemlos so betreiben.

Millionen von Entwicklern, Moddern und Retro-Gamer (die alte Hardware oder spezielle Peripherie nutzen) lassen Windows dauerhaft im Test-Modus laufen, ohne dass etwas passiert. Solange du nicht wahllos dubiose .sys-Treiber aus dem Internet installierst, ist das Risiko überschaubar.

---

## Wann und wie solltest du das zurücksetzen?

Du solltest den Test-Modus nur dann wieder ausschalten, wenn du die Kamera gerade nicht benötigst und die maximale Systemsicherheit wiederherstellen willst.

Wenn du den Test-Modus irgendwann abschaltest (`bcdedit /set testsigning off`), wird die ToupCam allerdings sofort wieder aufhören zu funktionieren, bis ToupTek einen modernen, offiziell signierten Treiber nachreicht.

---

