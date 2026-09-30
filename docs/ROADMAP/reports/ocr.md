$REPOS_DIR/WKDBook-Tricentis/Cases/SAP_Support/Cases/Open/1201484/assets/fourth/errorlog_OCR.md
$REPOS_DIR/WKDBook-Tricentis/Cases/SAP_Support/Cases/Open/1201484/assets/fourth/errorlog_text_SnippingTool.md
$REPOS_DIR/WKDBook-Tricentis/Cases/SAP_Support/Cases/Open/1201484/assets/fourth/failed_login_errorlog.png


Es gibt **sehr große Unterschiede** in der Qualität und Genauigkeit.

Die Textfunktion von **Snipping Tool** liefert ein fast perfektes Ergebnis, während das Standard-**OCR** viele Fehler enthält und die Zeilenreihenfolge komplett durcheinanderbringt.

### Die wesentlichen Unterschiede im Vergleich:

1. **Vollständigkeit & JSON-Struktur:**
* **Snipping Tool:** Liest jede JSON-Zeile vollständig und korrekt von links nach rechts. Selbst die Timestamps und Parameter sind exakt extrahiert.


* **Standard OCR:** Zerschneidet die Zeilen in Spalten, liest Blöcke vertikal ab und trennt Timestamps, Log-Level und Nachrichten voneinander. Dadurch geht der Zusammenhang komplett verloren.

2. **Zeichenerkennung & Tippfehler:**
* **Snipping Tool:** Erkennt selbst komplexe Hex-Codes (`TraceId`, `SpanId`) und Pfade fehlerfrei (z. B. `c966fdda204eef6df6b771ac579cf710`).


* **Standard OCR:** Verwechselt Zeichen massiv (z. B. `c966fdda...` wird zu `c966Fdda`, Nullen werden als `@` gelesen, wie in `2026-@9-29T16:`, `SpanId` wird als `Sp` abgeschnitten).

3. **Verwendbarkeit für Fehlersuche / Analyse:**
* **Snipping Tool:** Das extrahierte Log lässt sich direkt in einen Editor kopieren, als JSON parsen oder für Skripte weiterverarbeiten.


* **Standard OCR:** Unbrauchbar, da die Zeilenstruktur zerstört ist.

**Fazit:** Das Snipping Tool nutzt ein moderneres, auf Layout und Zeilenfluss optimiertes OCR-Modell. Das Snipping-Tool-Ergebnis entspricht nahezu 1:1 dem Originalbild.
