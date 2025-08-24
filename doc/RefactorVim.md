Kurzbeschreibung
`refactoring.nvim` bietet AST-basierte Refactorings über Tree-sitter (z. B. „Extract Function/Variable“, „Inline Variable“) sowie Debug-Hilfen („printf/print\_var/cleanup“). Viele Aktionen arbeiten selektionsbasiert: man markiert Code im Visual-Mode und löst die gewünschte Aktion aus. Optional stellt das Telescope-Extension einen Picker bereit.

Voraussetzungen
• Tree-sitter Parser für die jeweilige Sprache installiert/aktiv.
• `plenary.nvim` und optional `telescope.nvim`.
• Unterstützte Sprachen sind u. a. C/C++/Go/Java/JavaScript/TypeScript/Python/Lua (Qualität variiert je nach Sprache).

Workflow (typisch)

1. Im Visual-Mode den relevanten Code markieren.
2. Picker aufrufen (`<leader>rs`) oder direktes Mapping (z. B. `<leader>rx` für „Extract Variable“) benutzen.
3. Falls nötig, Namen bestätigen (z. B. Funktions-/Variablennamen).
4. Prüfen, ob die Änderung korrekt ist (AST-Refactoring ist gut, aber nicht unfehlbar).

Erläuterung der in deinem Snippet genutzten Aktionen
• Inline Variable: Ersetzt Vorkommen einer Variablen durch ihren Ausdruck.
• Extract Block / Extract Block To File: Hebt einen Block in eine neue Funktion an; Variante „To File“ schreibt in eine neue Datei.
• Extract Function / Extract Function To File (visueller Bereich): Hebt die markierte Selektion in eine neue Funktion an.
• Extract Variable (visueller Bereich): Hebt einen Ausdruck in eine neue lokale Variable an.
• Debug printf/print\_var/cleanup: Fügt printf-artige Debug-Zeilen ein bzw. räumt sie wieder auf.

Wichtige Hinweise zu deinem Mapping
• Es gibt doppelte Keybinds: `"<leader>rf"` ist zweimal belegt (einmal normal-mode „Extract Block To File“, einmal visual-mode „Extract Function“). Diese Doppelung ist verwirrend.
• `pick` ist in deinem Ausschnitt nicht definiert; für den Telescope-Picker braucht man eine kleine Hilfsfunktion.
• Ein paar Aktionen erfordern Visual-Mode (Auswahl). In Normal-Mode funktionieren sie nicht sinnvoll.

Empfohlene, bereinigte Keybinds inkl. funktionierendem Picker

```lua
-- inside your plugin spec for ThePrimeagen/refactoring.nvim

-- helper: Telescope picker (visual mode)
local function refactor_pick()
  -- if Telescope extension is available, use it; else fallback to built-in select_refactor
  local ok, tele = pcall(require, "telescope")
  if ok and tele.extensions and tele.extensions.refactoring and tele.extensions.refactoring.refactors then
    tele.extensions.refactoring.refactors()
  else
    require("refactoring").select_refactor()
  end
end

return {
  "ThePrimeagen/refactoring.nvim",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    -- optional:
    -- { "nvim-telescope/telescope.nvim", optional = true },
  },
  keys = {
    { "<leader>r",  "", desc = "+refactor", mode = { "n", "v" } },

    -- Picker (visual selection erforderlich)
    { "<leader>rs", refactor_pick, mode = "v", desc = "Refactor (Picker)" },

    -- Inline Variable (normal & visual)
    { "<leader>ri", function() require("refactoring").refactor("Inline Variable") end,
      mode = { "n", "v" }, desc = "Inline Variable" },

    -- Extract Block / To File (normal mode)
    { "<leader>rb", function() require("refactoring").refactor("Extract Block") end,
      desc = "Extract Block" },
    { "<leader>rB", function() require("refactoring").refactor("Extract Block To File") end,
      desc = "Extract Block To File" },

    -- Extract Function / To File (visual mode)
    { "<leader>rf", function() require("refactoring").refactor("Extract Function") end,
      mode = "v", desc = "Extract Function" },
    { "<leader>rF", function() require("refactoring").refactor("Extract Function To File") end,
      mode = "v", desc = "Extract Function To File" },

    -- Extract Variable (visual mode)
    { "<leader>rx", function() require("refactoring").refactor("Extract Variable") end,
      mode = "v", desc = "Extract Variable" },

    -- Debug helpers
    { "<leader>rP", function() require("refactoring").debug.printf({ below = false }) end,
      desc = "Debug Print (printf)" },
    { "<leader>rp", function() require("refactoring").debug.print_var({ normal = true }) end,
      desc = "Debug Print Variable (normal)" },
    { "<leader>rp", function() require("refactoring").debug.print_var() end,
      mode = "v", desc = "Debug Print Variable (visual)" },
    { "<leader>rc", function() require("refactoring").debug.cleanup({}) end,
      desc = "Debug Cleanup" },
  },
  opts = {
    -- weniger Rückfragen in typisierten Sprachen
    prompt_func_return_type = { go=false, java=false, cpp=false, c=false, h=false, hpp=false, cxx=false },
    prompt_func_param_type  = { go=false, java=false, cpp=false, c=false, h=false, hpp=false, cxx=false },
    printf_statements = {},
    print_var_statements = {},
    show_success_message = true,
  },
  config = function(_, opts)
    require("refactoring").setup(opts)
    -- Lazy load telescope extension, falls vorhanden
    pcall(function()
      require("telescope").load_extension("refactoring")
    end)
  end,
}
```

Tipps für den Einsatz
• Aktionen am zuverlässigsten in sauber parsebarem Code (keine Syntaxfehler) ausführen.
• Bei sprachspezifischen Besonderheiten (z. B. Go/Java) kann das Plugin Typinformationen erfragen; die Optionen oben unterdrücken das für die genannten Sprachen.
• Nach größeren Extracts lohnt sich ein schneller LSP-Format/Lint-Durchlauf.
