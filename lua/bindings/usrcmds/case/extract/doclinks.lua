---@module 'bindings.usrcmds.case.extract.doclinks'
--- EXTRACTION.md §6: compares every `docs.tricentis.com/tosca-<version>/`
--- link found in a case (Activity Streams + Replies) against the
--- customer's actual Tosca version, flagging a mismatch. Worked example
--- that motivated this (§6): a customer running 25.1.2/25.1.7 was pointed
--- at `tosca-2026.1` docs in a stream reply, caught only by a human
--- reading closely — a live doc link pointing at the wrong product
--- version is worse than a dead one, because the customer follows it.

local collect_recursive = require("lib.nvim.fs.collect_recursive")
local read = require("lib.nvim.fs.read")
local stream = require("bindings.usrcmds.case.extract.stream")

local M = {}

--- Doc-link URLs only ever carry `<4-digit-year>.<minor>` (`tosca-2025.1`,
--- never a patch digit — confirmed against real links elsewhere in the
--- bestand), while a Tosca version can be `25.1.7` (2-digit year) OR
--- `2026.1` (4-digit year, no patch — EXTRACTION.md §2's "Testsuite-
--- Version bricht das X.Y.Z-Schema"). Normalizing both to the doc-link's
--- own shape is what makes the comparison meaningful; comparing raw
--- strings would flag `25.1.7` against `tosca-2025.1` as a false mismatch
--- on every single case.
---@param v string|nil  e.g. "25.1.7", "2026.1", "24.2.1"
---@return string|nil  "<4-digit-year>.<minor>", e.g. "2025.1"
function M.normalize_version(v)
  if not v then
    return nil
  end
  local y2, minor = v:match("^(%d%d)%.(%d+)")
  if y2 then
    return "20" .. y2 .. "." .. minor
  end
  local y4, minor4 = v:match("^(%d%d%d%d)%.(%d+)")
  if y4 then
    return y4 .. "." .. minor4
  end
  return nil
end

--- Best-known Tosca version for this case, normalized to doc-link form,
--- most reliable source first: `.case.json`'s own `tosca_version` if a
--- human confirmed it (`:Case info`'s edit form) — otherwise the
--- support-info header (`detect.tosca_version`, the same exactly-
--- positioned anchor `:Case versions`'s digest relies on) — otherwise the
--- newest Activity Stream's Commander version (`extract.stream`, prose,
--- the least structured of the three), the same last-resort fallback
--- `:Case versions server` uses for the server version specifically
--- (which has no more-reliable source at all).
---@param case_dir string
---@param meta_tosca_version string|nil
---@return string|nil version
---@return string|nil source  human-readable, for the report
function M.resolve_customer_version(case_dir, meta_tosca_version)
  local from_meta = M.normalize_version(meta_tosca_version)
  if from_meta then
    return from_meta, ".case.json"
  end

  local detect = require("bindings.usrcmds.case.detect")
  local from_supportinfo = M.normalize_version(detect.tosca_version(case_dir))
  if from_supportinfo then
    return from_supportinfo, "ToscaSupportInfo"
  end

  local stream_path = stream.find(case_dir)
  if stream_path then
    local content = read(stream_path)
    if content then
      local commander = stream.versions_in_text(content).commander
      local from_stream = M.normalize_version(commander)
      if from_stream then
        return from_stream, vim.fn.fnamemodify(stream_path, ":t")
      end
    end
  end
  return nil, nil
end

---@class Lib.Case.DocLink
---@field url string
---@field version string  as it appeared in the URL, e.g. "2025.1"
---@field file string  relative path within the case dir

--- Every `docs.tricentis.com/tosca-<version>/` link found across a case's
--- Activity Streams and `Replies/*`, deduplicated by (url, file) — the raw
--- material both `M.check` (below) and EXTRACTION.md §7's Faktenblock
--- (`extract.facts`) build on. Factored out of `M.check` so both can reuse
--- the same scan instead of walking the case twice.
---@param case_dir string
---@return Lib.Case.DocLink[]
function M.all_links(case_dir)
  local scan_files = {}
  for _, f in ipairs(collect_recursive.files(case_dir .. "/Research")) do
    if f:match("_ActivityStream%.md$") then
      scan_files[#scan_files + 1] = f
    end
  end
  vim.list_extend(scan_files, collect_recursive.files(case_dir .. "/Replies"))

  local out, seen = {}, {}
  for _, path in ipairs(scan_files) do
    local content = read(path)
    if content then
      for _, link in ipairs(stream.doc_links(content)) do
        local key = link.url .. "|" .. path
        if not seen[key] then
          seen[key] = true
          out[#out + 1] = { url = link.url, version = link.version, file = path:sub(#case_dir + 2) }
        end
      end
    end
  end
  return out
end

---@class Lib.Case.DocLinkMismatch
---@field url string
---@field found_version string  as it appeared in the URL, e.g. "2025.1"
---@field file string  relative path within the case dir

--- Every link from `M.all_links` whose version doesn't match the
--- customer's own.
---@param case_dir string
---@param meta_tosca_version string|nil
---@return Lib.Case.DocLinkMismatch[] mismatches
---@return string|nil customer_version
---@return string|nil customer_source
function M.check(case_dir, meta_tosca_version)
  local customer_version, source = M.resolve_customer_version(case_dir, meta_tosca_version)
  local mismatches = {}
  if not customer_version then
    return mismatches, nil, nil
  end

  for _, link in ipairs(M.all_links(case_dir)) do
    local norm = M.normalize_version(link.version)
    if norm and norm ~= customer_version then
      mismatches[#mismatches + 1] =
        { url = link.url, found_version = link.version, file = link.file }
    end
  end

  return mismatches, customer_version, source
end

return M
