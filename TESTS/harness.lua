-- TESTS/harness.lua -- tiny assertion and temp-dir helpers shared by the specs.
-- Returned to each spec by TESTS/run.lua. Same shape as lib.nvim's TESTS/harness.lua
-- (`return function(H)` specs), so a spec can move between the two suites.

local uv = vim.uv or vim.loop

local H = {}

--- Assert equality; tables are compared deeply. Raises on mismatch.
---@param actual any
---@param expected any
---@param msg? string
function H.eq(actual, expected, msg)
  local same
  if type(actual) == "table" and type(expected) == "table" then
    same = vim.deep_equal(actual, expected)
  else
    same = actual == expected
  end
  if not same then
    error(
      ("FAIL %s: expected %s, got %s"):format(msg or "", vim.inspect(expected), vim.inspect(actual)),
      2
    )
  end
end

--- Assert a truthy value.
---@param v any
---@param msg? string
function H.ok(v, msg)
  if not v then
    error(("FAIL %s: expected truthy, got %s"):format(msg or "", vim.inspect(v)), 2)
  end
end

--- Assert that a string contains a plain substring.
---@param haystack string
---@param needle string
---@param msg? string
function H.has(haystack, needle, msg)
  if type(haystack) ~= "string" or not haystack:find(needle, 1, true) then
    error(
      ("FAIL %s: expected to find %s in %s"):format(
        msg or "",
        vim.inspect(needle),
        vim.inspect(haystack)
      ),
      2
    )
  end
end

--- Assert that a string does not contain a plain substring.
---@param haystack string
---@param needle string
---@param msg? string
function H.lacks(haystack, needle, msg)
  if type(haystack) == "string" and haystack:find(needle, 1, true) then
    error(
      ("FAIL %s: expected NOT to find %s in %s"):format(
        msg or "",
        vim.inspect(needle),
        vim.inspect(haystack)
      ),
      2
    )
  end
end

--- A fresh empty directory (forward slashes), removed by `H.cleanup()`.
---@return string
function H.tmpdir()
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir, "p")
  dir = dir:gsub("\\", "/")
  H._dirs = H._dirs or {}
  H._dirs[#H._dirs + 1] = dir
  return dir
end

--- Remove every directory `H.tmpdir()` made.
function H.cleanup()
  for _, dir in ipairs(H._dirs or {}) do
    vim.fn.delete(dir, "rf")
  end
  H._dirs = {}
end

--- Write `content` byte for byte (creating parent directories).
---@param path string
---@param content string
function H.write(path, content)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  local f = assert(io.open(path, "wb"))
  f:write(content)
  f:close()
end

--- Read a file byte for byte; nil when it does not exist.
---@param path string
---@return string|nil
function H.read(path)
  local f = io.open(path, "rb")
  if not f then
    return nil
  end
  local s = f:read("*a")
  f:close()
  return s
end

---@param path string
---@return boolean
function H.exists(path)
  return uv.fs_stat(path) ~= nil
end

--- Swap LF for CRLF.
---@param s string
---@return string
function H.crlf(s)
  return (s:gsub("\n", "\r\n"))
end

--- Check the shape of the positional-argument texts of a composer verb, as lib.nvim's option float
--- shows them: the `desc` of the argument, else the one of its type (`register_type`); one line,
--- no closing full stop, 12 to 80 characters. An `enum_desc` may only name values the argument has,
--- and is one line too. A built-in type (`DIR`, `PATH` ...) explains itself, so an argument with
--- neither text is skipped here -- `help.undocumented(verb, { args = true })` is what asks for one.
---@param verb string  A verb already registered with the composer
---@return integer seen  How many argument texts were looked at
function H.check_arg_texts(verb)
  local composer = require("lib.nvim.bindings.usercmd.composer")
  local argtypes = require("lib.nvim.bindings.usercmd.composer.argtypes")
  local handle = composer.registry()[verb]
  H.ok(handle ~= nil, ":" .. verb .. " is registered through the composer")

  local seen = 0
  for _, route in ipairs(handle:spec().routes or {}) do
    for _, arg in ipairs(route.args or {}) do
      local label = ("%s %s <%s>"):format(verb, table.concat(route.path, " "), arg.name)
      local def = arg.type and argtypes.get(arg.type) or nil
      local text = arg.desc or (def and def.desc)
      if text ~= nil then
        H.ok(type(text) == "string" and text ~= "", label .. ": the text is a string")
        H.ok(not text:find("[\r\n]"), label .. ": the text is one line")
        H.ok(not text:find("%.$"), label .. ": the text has no closing full stop")
        H.ok(#text >= 12 and #text <= 80, label .. ": the text is 12 to 80 characters long")
        seen = seen + 1
      end
      for value, value_text in pairs(arg.enum_desc or {}) do
        H.ok(
          vim.tbl_contains(arg.enum or arg.values or {}, value),
          label .. ": enum_desc names '" .. value .. "', which is not one of its values"
        )
        H.ok(
          type(value_text) == "string"
            and not value_text:find("%.$")
            and not value_text:find("[\r\n]"),
          label .. ": enum_desc '" .. value .. "' is one line without a closing full stop"
        )
      end
    end
  end
  return seen
end

return H
