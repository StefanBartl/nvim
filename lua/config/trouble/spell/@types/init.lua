---@module 'config.trouble.spell.types'
---@brief Type definitions for the SpellChecker module.

-- ─────────────────────────────────────────────────────────────────────────────
-- vim.spell.check entry
-- ─────────────────────────────────────────────────────────────────────────────

---@alias Cfg.Spell.ErrorType
---| "bad"   # Unknown / misspelled word
---| "rare"  # Rare word
---| "local" # Word only valid in another region
---| "caps"  # Capitalisation error

---@class Cfg.Spell.Entry
---@field [1] string             The misspelled word
---@field [2] Cfg.Spell.ErrorType
---@field [3] integer            Byte-column offset (0-based) within the line

-- ─────────────────────────────────────────────────────────────────────────────
-- Scope
-- ─────────────────────────────────────────────────────────────────────────────

---@alias Cfg.Spell.Scope
---| "buf"  # Current buffer only (default / %)
---| "cwd"  # All text files under the current working directory

-- ─────────────────────────────────────────────────────────────────────────────
-- Config
-- ─────────────────────────────────────────────────────────────────────────────

---@class Cfg.Spell.Opts
---@field severity?    vim.diagnostic.Severity
---@field source?      string
---@field keymap?      string|false   Global toggle keymap  (e.g. "<leader>zs")
---@field keymap_fix?  string|false   Per-buffer: open z= menu then advance
---@field keymap_fix1? string|false   Per-buffer: accept first suggestion, advance
---@field keymap_next? string|false   Per-buffer: jump to next spell error
---@field use_trouble? boolean        Prefer trouble.nvim when available (default true)
---@field qf_title?    string         Title used for the quickfix list

---@class Cfg.Spell.Config
---@field severity    vim.diagnostic.Severity
---@field source      string
---@field keymap      string|false
---@field keymap_fix  string|false
---@field keymap_fix1 string|false
---@field keymap_next string|false
---@field use_trouble boolean
---@field qf_title    string

-- ─────────────────────────────────────────────────────────────────────────────
-- Internal per-buffer state
-- ─────────────────────────────────────────────────────────────────────────────

---@class Cfg.Spell.BufState
---@field spell_was_on   boolean   Value of vim.wo.spell before activation
---@field prev_spelllang string    Value of spelllang before activation
---@field lang           string    Language used for this session

-- ─────────────────────────────────────────────────────────────────────────────
-- vim.Diagnostic subset (avoid undefined-field warnings from the LS)
-- ─────────────────────────────────────────────────────────────────────────────

---@class Cfg.Spell.Diag
---@field bufnr    integer
---@field lnum     integer                   0-based line number
---@field col      integer                   0-based byte column
---@field end_lnum integer
---@field end_col  integer
---@field severity vim.diagnostic.Severity
---@field source   string
---@field message  string
---@field user_data? { word: string, error_type: Cfg.Spell.ErrorType }

-- ─────────────────────────────────────────────────────────────────────────────
-- Public module shape
-- ─────────────────────────────────────────────────────────────────────────────

---@class Cfg.Spell.Module
---@field setup      fun(opts?: Cfg.Spell.Opts): nil
---@field run        fun(lang?: string, scope?: Cfg.Spell.Scope): nil
---@field clear      fun(): nil
---@field refresh    fun(): nil
---@field goto_next  fun(): nil
---@field fix_current fun(): nil
---@field get_config fun(): Cfg.Spell.Config
---@field active_bufs fun(): integer[]

return {}
