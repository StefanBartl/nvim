---@module 'bindings.usrcmds.case.ocr'
--- `:Case ocr` — make the text inside a case's screenshots exist as text.
---
--- A customer sends a screenshot of an exception. The stack trace in it is
--- exactly what identifies the case — and exactly what nothing in casedesk can
--- read, because `attachments.lua` files it under `assets/` as pixels. `:Case
--- grep` misses it, `:Case ki` cannot put it in a prompt, and the only way to
--- use it is to retype it.
---
--- This module runs each image through images.nvim's OCR and writes the result
--- as a Markdown sidecar next to the image (`shot.png` -> `shot.png.ocr.md`).
--- That single choice is what does the work: `query.grep` already walks every
--- `*.md` under a case directory recursively, so the recognised text becomes
--- greppable without a line of change there. The sidecar is an ordinary
--- document — editable, correctable, and carrying a Markdown image link back
--- to its source, so `:Image` shows the screenshot from inside it.
---
--- **What deliberately does NOT read these files.** `similar.lua` ranks cases
--- by TF-IDF over `Summary.md` + `Notes.md`. Feeding OCR text into that corpus
--- would be actively harmful rather than merely unhelpful: TF-IDF weights rare
--- terms highest, and a misrecognised word ("Excepticn", "l0cked") is by
--- construction the rarest term in the whole corpus. Every recognition error
--- would land at maximum weight. The sidecars stay out of it.
---
--- **Soft dependency on images.nvim**, `pcall`'d like every optional plugin
--- here. Without it — or without tesseract behind it — `:Case ocr` reports why
--- and changes nothing.

local config = require("bindings.usrcmds.case.config")
local collect_recursive = require("lib.nvim.fs.collect_recursive")
local write_to_file = require("lib.nvim.fs.write.to_file")
local read = require("lib.nvim.fs.read")

local M = {}

--- Extensions treated as OCR candidates.
---
--- Deliberately narrower than `images.nvim`'s own `extensions` list: SVG is
--- left out because a case attachment is never a vector graphic in practice
--- (customers send screenshots), and including it would mean paying for an
--- ImageMagick conversion on a file class that has never once appeared in this
--- corpus.
---@type table<string, true>
local IMAGE_EXTENSIONS = {
  png = true,
  jpg = true,
  jpeg = true,
  gif = true,
  webp = true,
  bmp = true,
  tif = true,
  tiff = true,
}

--- Suffix appended to the FULL file name, not swapped for its extension:
--- `shot.png` -> `shot.png.ocr.md`. Keeping the extension in the name is what
--- makes `shot.png` and `shot.jpg` produce two sidecars instead of silently
--- overwriting one another, and it keeps a grep hit self-explaining — the path
--- alone says which image the line came from.
local SIDECAR_SUFFIX = ".ocr.md"

---@param path string
---@return string
function M.sidecar_path(path)
  return path .. SIDECAR_SUFFIX
end

--- Whether a path is one of this module's own sidecars, rather than a case
--- document that happens to live under `assets/`.
---@param path string
---@return boolean
function M.is_sidecar(path)
  return path:sub(-#SIDECAR_SUFFIX) == SIDECAR_SUFFIX
end

--- Every image file under the case's `assets/` tree.
---@param entry Lib.Case.RegistryEntry
---@return string[] paths  absolute, sorted, empty when there is no assets/ folder
function M.images(entry)
  local dir = entry.dir .. "/" .. config.assets_dirname
  local st = vim.uv.fs_stat(dir)
  if not (st and st.type == "directory") then
    return {}
  end

  local out = {}
  for _, path in ipairs(collect_recursive.files(dir)) do
    local ext = vim.fn.fnamemodify(path, ":e"):lower()
    if IMAGE_EXTENSIONS[ext] then
      out[#out + 1] = path
    end
  end
  table.sort(out)
  return out
end

--- Whether an image's sidecar is missing or older than the image itself.
---
--- Comparing mtimes rather than merely testing for existence: `:Image redact`
--- and `:Case normalize` both rewrite attachment files in place, and a sidecar
--- describing the pre-redaction version of a screenshot is worse than none —
--- it would keep the text that was blacked out.
---@param path string image path
---@return boolean
function M.is_stale(path)
  local sidecar = vim.uv.fs_stat(M.sidecar_path(path))
  if not sidecar then
    return true
  end
  local image = vim.uv.fs_stat(path)
  if not image then
    return false
  end
  return (image.mtime and image.mtime.sec or 0) > (sidecar.mtime and sidecar.mtime.sec or 0)
end

--- The sidecar document for one recognition result.
---
--- The image link is relative and sits next to the text on purpose: opening the
--- sidecar and hovering the link is the fastest route back to the screenshot
--- the words came from, and `:Image` resolves a relative link against the
--- buffer's own directory, which is exactly where the image is.
---@param image_path string
---@param text string
---@return string
local function sidecar_content(image_path, text)
  local name = vim.fn.fnamemodify(image_path, ":t")
  return table.concat({
    ("# OCR — %s"):format(name),
    "",
    ("![](%s)"):format(name),
    "",
    ("> Machine-read with tesseract on %s. Recognition errors are possible —"):format(
      os.date("%Y-%m-%d")
    ),
    "> correct this file rather than the image; nothing regenerates it unless",
    "> the image itself changes.",
    "",
    text,
    "",
  }, "\n")
end

--- The recognised text out of a sidecar, without this module's own scaffolding
--- (the H1, the image link, the caveat blockquote).
---
--- A line scan rather than a pattern match on the exact shape `sidecar_content`
--- writes: these files are meant to be corrected by hand, and a hand-edited
--- caveat — one line longer, one line shorter, reworded — would silently break
--- a fixed-shape pattern and feed the scaffolding into the prompt as if it were
--- customer text. Skipping *leading* headings, links and quote lines survives
--- any edit that keeps the file looking like the document it is.
---@param content string
---@return string
function M.body_of(content)
  local lines = vim.split(content:gsub("\r", ""), "\n", { plain = true })
  local first = 1
  for i, line in ipairs(lines) do
    local trimmed = vim.trim(line)
    local scaffolding = trimmed == ""
      or trimmed:sub(1, 1) == "#"
      or trimmed:sub(1, 1) == ">"
      or trimmed:match("^!%[[^%]]*%]%([^%)]*%)$") ~= nil
    if not scaffolding then
      first = i
      break
    end
    first = i + 1
  end
  return table.concat(vim.list_slice(lines, first), "\n")
end

---@class Lib.Case.OcrOpts
---@field force? boolean  Re-read images whose sidecar is already current.
---@field lang?  string   tesseract language code, overriding images.nvim's `ocr.lang` for this run.

---@class Lib.Case.OcrResult
---@field written integer   How many sidecars were written.
---@field skipped integer   How many images already had an up-to-date sidecar.
---@field errors string[]   One entry per failed image, `"<name>: <reason>"`.

--- Run OCR over a case's images and write one sidecar per image.
---
--- Strictly one image at a time. tesseract is CPU-bound and a case can hold two
--- dozen attachments; firing them all at once would peg every core of the
--- machine the user is working on, to finish a background chore no faster than
--- a queue does.
---@param entry Lib.Case.RegistryEntry
---@param opts Lib.Case.OcrOpts|nil
---@param on_done fun(result: Lib.Case.OcrResult)
---@return nil
function M.run(entry, opts, on_done)
  opts = opts or {}
  local result = { written = 0, skipped = 0, errors = {} }

  local ok_images, images = pcall(require, "images.ocr")
  if not ok_images then
    result.errors[#result.errors + 1] =
      "images.nvim is not installed — :Case ocr needs its OCR module"
    return on_done(result)
  end
  if not images.available() then
    result.errors[#result.errors + 1] = "tesseract not found — see :checkhealth images"
    return on_done(result)
  end

  local queue = {}
  for _, path in ipairs(M.images(entry)) do
    if opts.force or M.is_stale(path) then
      queue[#queue + 1] = path
    else
      result.skipped = result.skipped + 1
    end
  end

  local index = 0
  local function step()
    index = index + 1
    local path = queue[index]
    if not path then
      return on_done(result)
    end

    images.run(path, { lang = opts.lang }, function(text, err)
      if not text then
        result.errors[#result.errors + 1] = ("%s: %s"):format(
          vim.fn.fnamemodify(path, ":t"),
          tostring(err)
        )
      else
        local lines = table.concat(images.to_lines(text), "\n")
        local ok_write, werr = write_to_file(M.sidecar_path(path), sidecar_content(path, lines))
        if ok_write then
          result.written = result.written + 1
        else
          result.errors[#result.errors + 1] = ("%s: %s"):format(
            vim.fn.fnamemodify(path, ":t"),
            tostring(werr)
          )
        end
      end
      step()
    end)
  end

  step()
end

--- The `{screenshots}` block for the `:Case ki` prompt: every sidecar this case
--- has, under one heading, or nil when there is none.
---
--- Framed as machine-read rather than quoted as fact, and placed with `{facts}`
--- rather than inside the activity stream: the model has to be able to tell
--- "the customer wrote this" from "a program guessed this from pixels", or it
--- will reason confidently about a misread version number.
---@param entry Lib.Case.RegistryEntry
---@return string|nil
function M.render(entry)
  local blocks = {}
  for _, path in ipairs(M.images(entry)) do
    local content = read(M.sidecar_path(path))
    if content then
      local body = vim.trim(M.body_of(content))
      if body ~= "" then
        blocks[#blocks + 1] = ("### %s\n\n%s"):format(vim.fn.fnamemodify(path, ":t"), body)
      end
    end
  end

  if #blocks == 0 then
    return nil
  end

  return table.concat({
    "## Text aus den Screenshots (maschinell gelesen)",
    "",
    "Per OCR aus den Attachments dieses Cases gelesen, nicht vom Kunden so",
    "geschrieben — Erkennungsfehler sind moeglich. Behandle Versionsnummern,",
    "IDs und Pfade daraus als Hinweis, nicht als Beleg.",
    "",
    table.concat(blocks, "\n\n"),
  }, "\n")
end

return M
