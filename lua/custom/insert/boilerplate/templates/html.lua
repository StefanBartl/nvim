---@module 'custom.insert.boilerplate.templates.html'
---@brief HTML template generators

local M = {}

---Generate HTML figure template
---@param id string Figure ID
---@return string[]
function M.figure(id)
  return {
    string.format('<figure style="text-align:center;" id="#fig-tbl-%s">', id),
    '  <img src="" alt="">',
    "  <figcaption></figcaption>",
    "</figure>",
  }
end

---Generate HTML code listing template
---@param id string Code listing ID
---@return string[]
function M.code(id)
  return {
    string.format('<figure id="#code-%s">', id),
    '  <pre><code class="">',
    "",
    "  </code></pre>",
    "  <figcaption><strong>Listing:</strong> </figcaption>",
    "</figure>",
  }
end

---Generate HTML quote template
---@param id string Quote ID
---@return string[]
function M.quote(id)
  return {
    string.format('<figure id="#quote-%s">', id),
    '  <blockquote style="border-left: 4px solid #ddd; padding-left: 1em; margin: 1em 0; font-style: italic;">',
    "    ",
    "  </blockquote>",
    '  <figcaption style="text-align: right;">— </figcaption>',
    "</figure>",
  }
end

---Generate HTML formula table template
---@param id string Table ID
---@return string[]
function M.formula_table(id)
  return {
    string.format('<figure id="#tbl-formula-%s">', id),
    '  <table style="border-collapse: collapse; width: 100%;">',
    "    <caption><strong>Formeln:</strong> </caption>",
    "    <thead>",
    "      <tr>",
    '        <th style="border: 1px solid #ddd; padding: 8px;">Name</th>',
    '        <th style="border: 1px solid #ddd; padding: 8px;">Formula</th>',
    '        <th style="border: 1px solid #ddd; padding: 8px;">Variables</th>',
    "      </tr>",
    "    </thead>",
    "    <tbody>",
    "      <tr>",
    '        <td style="border: 1px solid #ddd; padding: 8px;"></td>',
    '        <td style="border: 1px solid #ddd; padding: 8px;">$  $</td>',
    '        <td style="border: 1px solid #ddd; padding: 8px;"></td>',
    "      </tr>",
    "    </tbody>",
    "  </table>",
    "</figure>",
  }
end

---Generate HTML aside template
---@param id string Aside ID
---@return string[]
function M.aside(id)
  return {
    string.format('<aside id="#aside-%s" style="border-left: 3px solid #ddd; padding-left: 1em; margin: 1em 0;">', id),
    "  <strong>Note:</strong> ",
    "</aside>",
  }
end

---Generate HTML pagination template
---@param id string Pagination ID
---@return string[]
function M.pagination(id)
  return {
    string.format('<nav id="#pagination-%s" style="text-align: center; margin: 2em 0;">', id),
    '  <a href="#" style="padding: 0.5em 1em; margin: 0 0.2em; border: 1px solid #ddd; text-decoration: none;">← Previous</a>',
    '  <a href="#" style="padding: 0.5em 1em; margin: 0 0.2em; border: 1px solid #ddd; text-decoration: none;">Next →</a>',
    "</nav>",
  }
end

---Generate HTML accordion template
---@param id string Accordion ID
---@return string[]
function M.accordion(id)
  return {
    string.format('<details id="#accordion-%s" style="border: 1px solid #ddd; border-radius: 4px; padding: 0.5em 1em; margin: 0.5em 0;">', id),
    '  <summary style="cursor: pointer; font-weight: bold; user-select: none;">',
    "    ",
    "  </summary>",
    '  <div style="margin-top: 1em;">',
    "    ",
    "  </div>",
    "</details>",
  }
end

return M
