# `mdview.nvim`

- Usrcmds: `MDView**` zu `:MDView [options]` wechseln
- Gibt es eine Möglichkeit, das hauptfeaturea anzubieten ohne einen server zu starten?
- API schaffen, mit der man...
  - MDView als nvim prozess in einen terminal als background prozess starten kann, also zb `nvim +MDView --background "C:\TEST.md"` undd ann startet je anch weiteren optionen ddas markdown file im broeser tab oder als eigenständiger prozess wo nur nvim und mdview installiert sind in der nvim instanz (zum besseren separieren)
  - Wenn möglich: mdview als experiemntal standalone schreiben, wäre cool wenn man das auch cross platform hinbeokmmen wprde. lua müsste ja passen und go spielt uns auch un die hände, beide werden ja schon verednet auch wasm ist gut. schau dir das mal an ud schreibe einkonzept
  - beide möglichkeiten sollen auch vom einem nvim sinstanz aus gestartet were nkann, also als usrcmd mit der man dann das gleicheeben in einen neuen instanz ausführt...

## Table of content

  - [FINISH](#finish)
  - [Workflow Doc](#workflow-doc)
  - [Bugs](#bugs)

---

## FINISH

- Alle features durchgehjen und die perform,anteste, ideale DEFAULT config zusammenstellen

---

## Workflow Doc

Szenario: In nvim eine markdown file offen, dann `MDViewStart`:
  1. Was passiert dann genau?
2. Was passiert, damit die file das erste Mal im Browser aufgebaut wird?
  3. Was assiert, wenn sich die Datei ändert? Wie wird gesynced (Prozess)?
  4. Welche Protkolle machen wann was?
Zusätzlich anhand von praxis use cases die jeweiligen Prozesse beschreiben, also zb.: Welcher Prozess läuft bei den einzelnen usercommands ab?

---

## Bugs

nvim/logs/debuglog ausschalten und als switch implementieren

---

