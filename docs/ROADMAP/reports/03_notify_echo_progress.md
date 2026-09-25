Um Fortschrittsanzeigen (Progress-Messages) mit nvim_echo zu erstellen, nutzt man die Neovim-Nachrichten-Historie, eine Schleife zur Aktualisierung und die optionale Tabelle opts.
Hier ist ein einfaches, fertiges Lua-Beispiel, das du in deine init.lua kopieren kannst. Es simuliert einen Ladebalken, der sich in der Befehlszeile flüssig aktualisiert, ohne den Verlauf mit Hunderten von Zeilen zu überfluten.
## Code-Beispiel: Animierter Ladebalken

local function starte_fortschritt()
  local schritte = 10
  local zeichen = "█"
  local hintergrund = "░"

  -- Timer starten, um die Anzeige alle 200ms zu aktualisieren
  local timer = vim.loop.new_timer()
  local aktueller_schritt = 0

  timer:start(0, 200, vim.schedule_wrap(function()
    if aktueller_schritt > schritte then
      -- Timer stoppen, wenn fertig
      timer:close()

      -- Abschluss-Nachricht anzeigen
      vim.api.nvim_echo({
        { "✔ Fertig!", "DiagnosticOk" }
      }, true, {})
      return
    end

    -- Balken berechnen
    local geladen = string.rep(zeichen, aktueller_schritt)
    local rest = string.rep(hintergrund, schritte - aktueller_schritt)
    local prozent = math.floor((aktueller_schritt / schritte) * 100)

    -- Fortschritt anzeigen via nvim_echo
    vim.api.nvim_echo({
      { "Lade: ", "WarningMsg" },
      { string.format("[%s%s] %d%%", geladen, rest, prozent), "Normal" }
    }, false, {}) -- history = false, damit die Historie nicht zugemüllt wird

    aktueller_schritt = aktueller_schritt + 1
  end))end
-- Testen mit dem Befehl: :LuaFortschritt
vim.api.nvim_create_user_command("LuaFortschritt", starte_fortschritt, {})

## Die wichtigsten Kniffe für Progress-Messages

* history = false während des Ladens: Setze den zweiten Parameter (history) in der Schleife unbedingt auf false. Dadurch flackert der Text bei jedem Update nur an derselben Stelle auf, anstatt die Historie (:messages) mit Zwischenständen zu füllen.
* history = true am Ende: Erst wenn der Prozess komplett abgeschlossen ist, ruft man nvim_echo einmalig mit true auf, damit das finale Ergebnis dauerhaft im Log bleibt.
* vim.schedule_wrap: Da Fortschritte oft in asynchronen Hintergrund-Prozessen (wie LSP-Servern oder Tree-Sitter) berechnet werden, musst du den nvim_echo-Aufruf mit vim.schedule_wrap absichern. APIs dürfen in Neovim nicht direkt aus rohen Libuv-Threads aufgerufen werden.

Möchtest du dieses Prinzip nutzen, um den Status eines externen Terminal-Befehls (z. B. npm install oder cargo build) anzuzeigen, oder suchst du nach einer Integration für den nativen LSP-Fortschritt ($/progress)?
aber weder print nochnvim_echo
