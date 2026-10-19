---@brief `scripts/strip_coauthor/repin.lua` — translate old SHAs to the rewritten ones after `rewrite`.
---@description
--- `rewrite` writes `<repo>.map.json` (old -> new SHA) next to each bundle. This reads those maps and
--- rewrites, in the tracked text files of every repository, the places that name an old SHA:
---
---   * `<repo>@<sha>` references (7 to 40 hex digits; the abbreviation keeps its length),
---   * `engine.lock` (`commit` / `lib_commit`, resolved through `repo` / `lib_repo`).
---
--- Dry run by default (reports counts per file and writes nothing); `--apply` writes. Files are read
--- and written byte for byte, so line endings stay as they are. Only references to a repository that
--- has a map are touched; everything else, including a reference that is not an old SHA of that
--- repository, is left alone. Run it AFTER `rewrite` and BEFORE the push, then commit the result
--- per repository.
---
---     STRIP_BACKUP_DIR=E:/repos-backup/strip-coauthor-2026-10-19 REPOS_DIR=E:/repos \
---       STRIP_COAUTHOR_ARGS="[--apply]" nvim -n -i NONE --headless -u NONE -l scripts/strip_coauthor/repin.lua

local script_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")
local gitx = dofile(script_dir .. "/git.lua")

local M = {}

---@alias StripCoauthor.Index table<string, table<string, string[]>> repo -> first 7 hex -> old SHAs

---Index the maps by repository and by the first 7 characters of the old SHA.
---@param maps table<string, table<string, string>> repo -> (old -> new)
---@return StripCoauthor.Index
function M.index(maps)
  local index = {}
  for repo, map in pairs(maps) do
    index[repo] = {}
    for old in pairs(map) do
      local key = old:sub(1, 7)
      index[repo][key] = index[repo][key] or {}
      table.insert(index[repo][key], old)
    end
  end
  return index
end

---The new SHA for `sha` (an abbreviation of an old one) in `repo`, cut to the same length; nil when
---it is not an old SHA of that repository. An abbreviation that fits two old SHAs is refused (nil).
---@param maps table<string, table<string, string>>
---@param index StripCoauthor.Index
---@param repo string
---@param sha string
---@return string|nil
function M.translate(maps, index, repo, sha)
  sha = sha:lower()
  if #sha < 7 or not index[repo] then
    return nil
  end
  local found
  for _, old in ipairs(index[repo][sha:sub(1, 7)] or {}) do
    if vim.startswith(old, sha) then
      if found then
        return nil
      end
      found = old
    end
  end
  return found and maps[repo][found]:sub(1, #sha) or nil
end

---Translate every `repo@sha` in `text`; returns the new text and the number of replacements.
---@param text string
---@param maps table<string, table<string, string>>
---@param index StripCoauthor.Index
---@return string text
---@return integer count
function M.translate_text(text, maps, index)
  local count = 0
  local result = text:gsub("([%w._-]+)@(%x+)()", function(repo, sha, after)
    -- `abc@deadbeefg`: the run of hex digits is part of a longer word, not a SHA.
    if text:sub(after, after):match("[%w_]") or #sha > 40 then
      return nil
    end
    local new = M.translate(maps, index, repo, sha)
    if not new then
      return nil
    end
    count = count + 1
    return repo .. "@" .. new
  end)
  return result, count
end

---Translate the `commit =` / `lib_commit =` lines of an `engine.lock`.
---@param text string
---@param maps table<string, table<string, string>>
---@param index StripCoauthor.Index
---@return string text
---@return integer count
function M.translate_lock(text, maps, index)
  local count = 0
  local own, lib
  local out = {}
  for line in (text .. "\n"):gmatch("(.-)\n") do
    local key, value = line:match("^([%w_]+)%s*=%s*(.-)%s*$")
    if key == "repo" then
      own = value:match("([^/]+)$")
    elseif key == "lib_repo" then
      lib = value:match("([^/]+)$")
    elseif key == "commit" or key == "lib_commit" then
      local new = M.translate(maps, index, key == "commit" and own or lib, value)
      if new then
        line = line:gsub(value, new, 1)
        count = count + 1
      end
    end
    out[#out + 1] = line
  end
  -- `(text .. "\n"):gmatch` yields one empty tail line for a text that ends in a newline.
  return table.concat(out, "\n"):gsub("\n$", text:sub(-1) == "\n" and "\n" or ""), count
end

-- Command line --------------------------------------------------------------------------------

local function main()
  local args = vim.split(vim.env.STRIP_COAUTHOR_ARGS or "", "%s+", { trimempty = true })
  local apply = vim.tbl_contains(args, "--apply")

  local backup = vim.env.STRIP_BACKUP_DIR
  if not backup or backup == "" then
    io.stdout:write("ERROR: STRIP_BACKUP_DIR names the folder with the <repo>.map.json files\n")
    os.exit(2)
  end

  local maps = {}
  for name, kind in vim.fs.dir(backup) do
    local repo = kind == "file" and name:match("^(.+)%.map%.json$")
    if repo then
      local decoded = vim.json.decode(table.concat(vim.fn.readfile(backup .. "/" .. name), "\n"))
      maps[repo] = decoded.map
    end
  end
  if vim.tbl_isempty(maps) then
    io.stdout:write("ERROR: no <repo>.map.json in " .. backup .. "\n")
    os.exit(2)
  end
  local index = M.index(maps)

  local files, total, touched = 0, 0, 0
  for _, repo in ipairs(gitx.repos(gitx.resolve_base_dir(nil))) do
    local listed = vim
      .system(
        { "git", "-C", repo.path, "grep", "-I", "-l", "-E", "@[0-9a-f]{7,40}|commit *=", "--", "." },
        { text = true }
      )
      :wait()
    for _, file in ipairs(vim.split(listed.stdout or "", "\n", { trimempty = true })) do
      local path = repo.path .. "/" .. file
      local handle = io.open(path, "rb")
      if handle then
        local text = handle:read("*a")
        handle:close()
        local new, count
        if file:match("engine%.lock$") then
          new, count = M.translate_lock(text, maps, index)
        else
          new, count = M.translate_text(text, maps, index)
        end
        if count > 0 then
          files = files + 1
          total = total + count
          io.stdout:write(("  %5d  %s/%s\n"):format(count, repo.name, file))
          if apply then
            local out = assert(io.open(path, "wb"))
            out:write(new)
            out:close()
            touched = touched + 1
          end
        end
      end
    end
  end
  io.stdout:write(
    ("%d Ersetzung(en) in %d Datei(en)%s\n"):format(
      total,
      files,
      apply and (", %d geschrieben"):format(touched) or " (Dry-Run, --apply schreibt)"
    )
  )
  io.stdout:flush()
  os.exit(0)
end

if vim.env.STRIP_REPIN_AS_MODULE == "1" then
  return M
end
return main()
