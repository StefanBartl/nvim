# Testdatei für custom.open (:Open)

Bewege deinen Cursor auf das jeweilige Testobjekt (WORD unter dem Cursor)
oder markiere den Text im Visual Mode und führe den entsprechenden Befehl aus.

==============================================================================
1. BROWSER TARGETS (:Open browser / chrome / firefox / edge / safari)
==============================================================================

--- A) Echte URLs (Sollten direkt im Browser öffnen) ---
https://neovim.io
https://github.com/neovim/neovim
http://example.com

--- B) "www." Heuristik (Sollte automatisch zu https://www.lua.org ergänzt werden) ---
www.lua.org
www.reddit.com

--- C) Suchanfragen (Alles andere -> Google Suche) ---
pcall
neovim-lua-api-tips
wie-funktioniert-ein-custom-user-command-in-lua

==============================================================================
2. FILEMANAGER TARGETS (:Open filemanager)
==============================================================================

--- A) Absolute Pfade (Sollten den Ordner im Explorer/Finder/Nautilus öffnen) ---
/home/
~/Downloads
C:\Users

--- B) Relative Pfade (Je nachdem, wo Neovim gestartet wurde) ---
.
./lua

--- C) Fehlerfall-Test (Sollte eine Warnung ausgeben, da es eine URL ist!) ---
https://neovim.io

==============================================================================
3. NOTEPAD / EDITOR TARGETS (:Open notepad / :Open editor)
==============================================================================

--- A) Normal Mode (Cursor auf das Wort setzen und abschicken) ---
EinLangesWortDasInEinemTemporaerenTextEditorGeffnetWerdenSoll

--- B) Visual Mode (Markiere den folgenden Block komplett und tippe :Open notepad) ---
Dies ist ein mehrzeiliger Text.
Wenn ich diesen im Visual-Mode markiere
und ":Open notepad" aufrufe, sollte ein externer Texteditor
mit genau diesem Inhalt aufploppen!

==============================================================================
4. INTERNAL NEOVIM TARGETS (:Open split / vsplit / tab)
==============================================================================
Hinweis: Erstelle diese Dateien kurz (z.B. mit :w test_config.lua),
damit sie existieren, da das Plugin existierende Pfade verlangt.

--- A) Vertikaler/Horizontaler Split oder neuer Tab ---
test_open_plugin.txt
./init.lua

--- B) Fehlerfall-Test (Sollte abgelehnt werden, da es eine URL ist) ---
https://neovim.io

==============================================================================
5. KEYMAP TESTS (Falls du die Keymaps aus Kapitel 8 geladen hast)
==============================================================================
Setze den Cursor hierhin und drücke:

  -> <leader>ob  (Öffnet die URL im Browser)
  https://neovim.io

  -> <leader>of  (Öffnet das Verzeichnis im Filemanager)
  ~

  -> <leader>os  (Öffnet diese Datei in einem horizontalen Split)
  test_open_plugin.txt
