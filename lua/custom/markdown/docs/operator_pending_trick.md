# Operator Pending "Trick"

Um **den Original-Text in der Mitte zweier Marker wieder einzusetzen**, ohne selbst Text aus Registern zu jonglieren, Schritt für Schritt:

1. **`c`**
   In Visual-Mode bedeutet `c` “change selection”:

   * der selektierte Text wird **gelöscht** (landet im **unnamed register** `"`),
   * Vim wechselt nach **Insert-Mode**.

2. **`pad` tippen**
   Du tippst die vorderen `*…*` (oder `**`), jetzt befindest du dich **in Insert-Mode**, direkt *vor* dem Stellehalter für den alten Inhalt.

3. **`<C-o>P`**
   `<C-o>` führt **genau einen** Normal-Mode-Befehl aus und kehrt dann zurück in den Insert-Mode.
   * Der Normal-Befehl ist **`P`** (“paste before”) → fügt den soeben gelöschten Text aus `"` **zwischen** die Marker ein.
   * Danach bist du automatisch wieder im Insert-Mode (wegen `<C-o>`).

4. **erneut `pad` tippen**
   Jetzt kommen die **hinteren** Marker `*…*`.

5. **`<Esc>gv`**
   `<Esc>` verlässt den Insert-Mode.
   `gv` stellt die **letzte Visual-Selektion** wieder her (reselect). So kannst du die Auswahl noch anpassen oder – wie in deinem Code – im Anschluss die Selektion “nach innen” verschieben.

Der “operator-pending trick” bezieht sich hier auf das **Ausnutzen des Change-Operators `c`** (der ohne Motion in Visual direkt greift) plus **temporären Normal-Mode im Insert-Mode via `<C-o>`**, um **den eben gelöschten Text** gezielt **wieder einzufügen** – genau zwischen die beiden Marker. Das spart eigene Register-Manipulation oder API-Aufrufe.

## `keep_inner_selection`

* `o` im Visual-Mode springt zum **gegenüberliegenden Ende** der Selektion.
* Mit `string.rep("l", count)`/`string.rep("h", count)` verschiebst du die beiden Enden der Auswahl um `count` Zeichen **nach innen**, sodass am Ende **nur der innere Text** (ohne Marker) markiert bleibt:
  * `o l…l` → rechtes Ende nach links (innen)
  * `o h…h` → linkes Ende nach rechts (innen)

## Alternativen

* Wie im Single-Line-Pfad – immer `nvim_buf_get_text`/`nvim_buf_set_text` benutzen (dann brauchst du keinen Insert-Mode-Tanz). Das ist deterministischer, aber etwas mehr Code, insbesondere für mehrzeilige Selektionen.
* Oder: Visual-Bereich via `getpos("'<")/getpos("'>")` lesen, Text aus `@"`/`getreg('"')` holen, selber zusammensetzen, wieder setzen.

---
