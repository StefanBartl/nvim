Ich schaue mir zuerst die drei relevanten Codebasen an: `language.nvim`, `images.nvim` und deine nvim-Config (bindings\_explorer).



Interessant: `images.nvim` hat bereits `ocr.lua` und `pdf.lua`. Ich schaue mir die Kern-APIs beider Plugins an.



Relevanter Fund: es gibt bereits `case/ocr.lua` in deiner Config und ein `pdfport.nvim` Repo. Ich schaue mir das an.



Das Ökosystem wird klar. Jetzt `lib.nvim` (geteilte Infrastruktur) und `pdfport.nvim` (bestehende Extraktions-Architektur mit Backend-Chain).



Ich habe jetzt das vollständige Bild. Zwei wichtige Funde vorab, bevor ich das Konzept schreibe:



1\. \*\*OCR ist bereits fertig\*\* — `images.nvim/lua/images/ocr.lua` (tesseract), inklusive Konsument `:Case ocr`, der Sidecars `shot.png.ocr.md` schreibt. Nicht `bindings\_explorer` (das ist ein Keymap-Explorer).

2\. \*\*PDF-Extraktion ist bereits fertig\*\* — `pdfport.nvim` mit 7 Backends, Fallback-Chain, Cache, Registry. Das ist zugleich die beste Architektur-Vorlage.



Die echte Lücke ist Audio/Video. Ich schreibe das Konzept.



Konzept steht. Jetzt committen und nach `main` pushen.



Konzept ist geschrieben, committet und auf `main` gepusht: \[docs/ROADMAP/MEDIA-TO-TEXT.md](docs/ROADMAP/MEDIA-TO-TEXT.md) (Commit `5446f3c`).



\## Zwei Funde, die deine Annahmen korrigieren



\*\*OCR ist schon fertig.\*\* Nicht im `bindings\_explorer` (das ist ein Keymap-Explorer, kein OCR), sondern in \[images.nvim/lua/images/ocr.lua](E:/repos/images.nvim/lua/images/ocr.lua) — tesseract, async, mit `to\_lines()`. Und es hat schon einen produktiven Konsumenten: `:Case ocr` schreibt `shot.png.ocr.md`-Sidecars, die `:Case grep` ohne eine Zeile Änderung findet.



\*\*PDF-Extraktion ist auch fertig\*\* — `pdfport.nvim`, 7 Backends inkl. tesseract-Fallback, Registry, Fallback-Chain, Cross-Session-Cache. Das ist zugleich die beste Architektur-Vorlage im ganzen Ökosystem.



\*\*Die echte Lücke ist genau eine: Audio/Video.\*\* Kein ffmpeg, kein whisper, kein Zeitstempel-Datenmodell — nirgends.



\## Deine Frage: passt es in language.nvim?



\*\*Für die Extraktion: nein, zu weiter Stretch.\*\* Jeder öffentliche Einstiegspunkt hier ist buffer-gebunden (`run\_region(target, {bufnr, sr, sc, er, ec})`). Medien-Extraktion bringt Modell-Downloads im GB-Bereich, Minuten-Jobs, Zwischen-WAVs, mtime-Cache — nichts davon teilt eine Zeile mit spell/translate. Und der Präzedenzfall ist schon geschrieben: `images/ocr.lua` hat einen Abschnitt \*"Why this is not an interface to language.nvim"\*.



\*\*Für die Konsumtion: ja, und es ist kein Feigenblatt.\*\* Der SRT/VTT-Filter gehört wirklich hierher. `translate.filter.translatable\_ranges()` beantwortet für Code schon exakt dieselbe Frage — \*welche Zeilen sind Prosa?\* Bei einem Untertitel darf nur die Textzeile übersetzt werden; übersetzt du `00:00:04,120 --> 00:00:07,300`, ist die Datei kaputt. Das ist die Domäne dieses Plugins.



Der saubere Schnitt liegt ohnehin in der Sache: whisper `--task translate` kann \*\*nur nach Englisch\*\*. DE, FR, ZH gehen zwangsläufig über language.nvim.



\## Der Vorschlag



Neues `media.nvim`, gebaut nach pdfport-Muster — zwei Hälften: Transkription (eigener Kern, weil heimatlos) + Hub (Dashboard, delegiert Bild → `images.ocr`, PDF → `pdfport.extract`). Deshalb `media` und nicht `transcribe`: ein Dashboard über alle drei Typen braucht einen Ort, der alle drei kennen darf, ohne dass eines der drei die anderen zur Pflicht macht.



Kernstück ist `:Media text \[path]` — ein Verb, beliebige Mediendatei, Text im Buffer.



Phasen: 0) Transkription lauffähig · 1) Segmente → SRT/VTT + Kind-Dispatch · 2) Dashboard · 3) language.nvim (Subtitle-Filter + `srt`/`vtt` in `files.extensions`) · 4) Zusammenfassung via ollama/claude (Code dafür liegt in pdfport).



Phase 3 ist klein und unabhängig — sie macht heruntergeladene Untertiteldateien schon übersetzbar, bevor `media.nvim` existiert.



\## Offene Entscheidungen (Abschnitt 9 im Dokument)



Name (`media.nvim` vs `transcribe.nvim`), Default-Engine (`whisper\_cpp` wegen Windows vs `faster\_whisper` wegen Tempo), Sidecar-Format.



\*\*README bewusst nicht angefasst\*\* — das Dokument beschreibt Ungebautes, ein Link im README würde Features versprechen, die es nicht gibt. Sobald Phase 3 landet, gehört es unter `docs/FEATURES/TRANSLATE.md`.

