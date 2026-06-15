---@module 'custom.format.enum_lines.@types'
---@brief Type definitions for the line-enumeration formatter.

-- ─────────────────────────────────────────────────────────────────────────────
-- Numbering style
-- ─────────────────────────────────────────────────────────────────────────────

---Controls how the running counter is rendered before each token.
---
---Examples (sep defaults to ". "):
---  "decimal" → "1. foo  2. bar"
---  "alpha"   → "a. foo  b. bar"
---  "ALPHA"   → "A. foo  B. bar"
---  "roman"   → "i. foo  ii. bar"
---  "ROMAN"   → "I. foo  II. bar"
---
---@alias Custom.Format.EnumLines.Style
---| "decimal"  # 1. 2. 3. … (default)
---| "alpha"    # a. b. c. …
---| "ALPHA"    # A. B. C. …
---| "roman"    # i. ii. iii. …
---| "ROMAN"    # I. II. III. …

-- ─────────────────────────────────────────────────────────────────────────────
-- Options  (passed to the public API and the command handler)
-- ─────────────────────────────────────────────────────────────────────────────

---All fields are optional; sensible defaults are applied by the core.
---
---@class Custom.Format.EnumLines.Opts
---
---@field style?   Custom.Format.EnumLines.Style
--- Numbering style (default: "decimal").
---
---@field sep?     string
--- String placed between the counter and the token text (default: ". ").
--- E.g. pass ") " for "1) foo", or ": " for "1: foo".
---
---@field start?   integer
--- Counter value for the first token (default: 1).
--- Useful when continuing a list: start=4 → "4. foo  5. bar".
---
---@field inline?  boolean
--- true  → all labelled tokens are joined on **one** output line (default when
---         the entire selection lives on a single line).
--- false → each labelled token goes on its **own** output line.
--- When nil the core decides automatically based on the input shape.

-- ─────────────────────────────────────────────────────────────────────────────
-- Internal result
-- ─────────────────────────────────────────────────────────────────────────────

---Return value of `M.enumerate` (pure function, no side-effects).
---
---@class Custom.Format.EnumLines.Result
---@field ok     boolean    true when enumeration succeeded
---@field lines  string[]   output lines ready to write back to the buffer
---@field count  integer    number of tokens that were numbered
---@field err?   string     human-readable error (only present when ok = false)

return {}
