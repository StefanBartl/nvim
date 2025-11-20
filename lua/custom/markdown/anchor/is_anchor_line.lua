---@module 'custom.markdown.handler.anchor'
--- Detect Markdown anchor links robustly.
--- Supports standard Markdown link syntax, image links, and common inline anchor patterns.
--- According to the CommonMark spec, anchors appear in:
---   * Markdown links: [text](#anchor)
---   * Image links: ![alt](#anchor)
---   * Some HTML elements may allow fragment identifiers, but Markdown parsers typically do not treat them as anchors unless they follow the above syntax.

---@param line string
---@return boolean
return function(line)
  if not line or line == "" then
    return false
  end

  -- Markdown link: [text](#anchor)
  -- Markdown image link: ![alt](#anchor)
  -- This regex matches a parenthesis containing a hash, optionally preceded by anything,
  -- but we avoid matching URLs that start with http(s)://...
  -- Captures: (#anchor) but not (http://example#anchor)
  local anchor = line:match("%((#[^)]+)%)")
  if anchor then
    -- verify it does not contain a protocol prefix (avoid http://#fragment)
    if not anchor:match("^#") then
      return false
    end
    return true
  end

  -- fallback: check for inline hash-style references in plain text (rare, but sometimes used)
  -- e.g., <a id="anchor">...</a> is valid HTML, but Markdown does not treat it as a link
  -- Therefore, we do not attempt to detect arbitrary HTML fragment identifiers here.

  return false
end
