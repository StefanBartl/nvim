---@module 'bindings.usrcmds.bindings_explorer.repo'
--- The fourth drift axis' one primitive: "is this literal written anywhere in
--- that source tree?" — a plain string search over a checkout's `.lua`/`.vim`
--- files, with no live session involved.
---
--- **Why this exists at all.** `drift.lua`'s live axis can only judge a
--- documented binding whose owning plugin is already loaded in THIS session
--- (its module doc, point 4). Everything else is reported as "skipped", which
--- is honest but empty: in a normal session that is the large majority of the
--- personal plugins, so most of the corpus is never actually checked by
--- anything. Reading the plugin's own checkout answers those, because a
--- checkout is on disk whether or not lazy.nvim ever got around to loading it.
---
--- **Deliberately weaker than the live axis, and not a replacement for it.**
--- `nvim_get_keymap` answers "is this registered"; a grep answers "does this
--- string appear in the source". The second is a proxy for the first and gets
--- it wrong in both directions:
---   - false negative: an lhs assembled at runtime (`prefix .. "v"`, a key
---     read from a user config table) is genuinely registered and simply not
---     greppable. This is the known cost, and `drift.lua` labels the section
---     with it rather than pretending the axis is authoritative.
---   - false positive (i.e. a real drift silently accepted): the literal
---     appears in a comment, a test fixture, or the plugin's own README-in-
---     Lua. Accepted on purpose — the whole module's stance is that a missed
---     finding is cheaper than a wrong one.
---
--- **Only quoted occurrences count.** Both things this looks for — a keymap
--- lhs and a user command name — are always written as string literals at
--- their registration site (`vim.keymap.set("n", "<leader>iv", …)`,
--- `composer.verb("Images", …)`, `["<leader>iv"] = …`). Searching for the
--- bare word instead was measurably useless for commands: `:Images`
--- case-folded matches "images" in every second line of images.nvim, so
--- every command would count as found and the axis would report nothing ever.
---
--- **Only `.lua`/`.vim`.** A plugin's own `doc/`, `README.md` and cheatsheets
--- describe the same bindings this corpus documents; matching them would mean
--- confirming documentation against documentation. Restricting to source
--- extensions excludes them without needing a path-based exception list.

local collect_recursive = require("lib.nvim.fs.collect_recursive")
local read = require("lib.nvim.fs.read")

local M = {}

--- Extensions read into a tree's haystack. Everything else — docs, images,
--- lockfiles, the generated JSON artifacts documentation.nvim writes — is
--- skipped, see the module doc.
local SOURCE_EXT = { lua = true, vim = true }

--- Directory names pruned whole. `.git` alone is worth several times the
--- source tree of a plugin this size, and packed objects would be read as
--- binary noise into the haystack.
local PRUNE_DIRS = { [".git"] = true, ["node_modules"] = true, ["target"] = true }

--- Files above this are not registration sites; they are generated data
--- (a bundled lockfile, a vendored blob) and would dominate the haystack.
local MAX_FILE_BYTES = 1024 * 1024

---@class Bindings.Repo.Tree
---@field text string      # every source file of the tree, concatenated
---@field lower string|nil # lazily built lowercase copy, for ignore_case lookups
---@field files integer    # how many files went in, 0 meaning "cannot answer"

---@type table<string, Bindings.Repo.Tree>
local cache = {}

--- Drop every indexed tree. A `:Bindings check` run is a snapshot, and a
--- second run after editing a plugin must not answer from the first one's
--- copy — `drift.lua` calls this once per run, and tests call it between
--- fixtures.
---@return nil
function M.reset()
  cache = {}
end

---@param path string
---@return boolean
local function is_source(path)
  local ext = path:match("%.([%w_]+)$")
  return ext ~= nil and SOURCE_EXT[ext:lower()] == true
end

---@param abs string
---@param is_dir boolean
---@return boolean
local function prune(abs, is_dir)
  if is_dir then
    return PRUNE_DIRS[vim.fs.basename(abs)] == true
  end
  return not is_source(abs)
end

--- Read `dir`'s source files once, concatenated into one string.
---
--- One string rather than a per-file table on purpose: every lookup here is
--- "does this appear anywhere in the tree" and never "where", so the file
--- boundaries carry no information a caller could use, and a single
--- `string.find(…, plain)` over one buffer is what makes checking a few
--- hundred documented rows against 20-odd checkouts finish in the time a
--- report is allowed to take.
---@param dir string
---@return Bindings.Repo.Tree
local function index(dir)
  local cached = cache[dir]
  if cached then
    return cached
  end

  local ok, files = pcall(collect_recursive.files, dir, { ignore = prune })
  local chunks, count = {}, 0
  if ok then
    for _, path in ipairs(files) do
      local stat = vim.uv.fs_stat(path)
      if stat and (stat.size or 0) <= MAX_FILE_BYTES then
        local content = read(path)
        if content then
          count = count + 1
          chunks[#chunks + 1] = content
        end
      end
    end
  end

  -- Joined with a newline so a match can never straddle two files' bytes.
  local tree = { text = table.concat(chunks, "\n"), files = count }
  cache[dir] = tree
  return tree
end

---@param tree Bindings.Repo.Tree
---@return string
local function lowered(tree)
  if not tree.lower then
    tree.lower = tree.text:lower()
  end
  return tree.lower
end

--- Whether `literal` appears as a quoted string somewhere in `dir`'s source.
---
--- Returns `nil`, not `false`, when the tree yielded no readable source file
--- at all (a path that is not a checkout, an unreadable directory, a plugin
--- vendored without Lua). "I found nothing" and "I could not look" are
--- different claims, and reporting the second as the first would turn one
--- unreadable directory into a documented binding's worth of false findings
--- per row — the same distinction `source.lua` draws for its artifact.
---@param dir string Absolute path to a local checkout.
---@param literal string Searched as `"literal"` and `'literal'`, never bare.
---@param opts? { ignore_case?: boolean } Case-insensitive for key notation
---(`<Leader>` and `<leader>` are the same key); leave off for command names,
---where folding case makes a capitalized command name match ordinary prose.
---@return boolean|nil
function M.mentions(dir, literal, opts)
  if type(dir) ~= "string" or dir == "" or type(literal) ~= "string" or literal == "" then
    return nil
  end

  local tree = index(dir)
  if tree.files == 0 then
    return nil
  end

  local ignore_case = opts ~= nil and opts.ignore_case == true
  local hay = ignore_case and lowered(tree) or tree.text
  local needle = ignore_case and literal:lower() or literal

  return hay:find('"' .. needle .. '"', 1, true) ~= nil
    or hay:find("'" .. needle .. "'", 1, true) ~= nil
end

return M
