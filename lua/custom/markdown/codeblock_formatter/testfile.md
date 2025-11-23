# Da ist eine Testfile für den `custom.markdown.codeblock_formatter`

## Lua

Hier ist unformatierter Lua Code:

```lua
local M = {}

local api = vim.api
local fn = vim.fn
local uv = vim.loop

M._config = {
  formatters = default_formatters,   notify_level = vim.log.levels.INFO,   prefer_treesitter = true,
  ts_block_node = "fenced_code_block",


  supported_langs = nil,
}

function M.format_range_async(sline, eline)
  local bufnr = api.nvim_get_current_buf()
         if not sline or not eline then
 local mode = vim.fn.mode()    if mode == "v" or mode == "V" or mode == "\22" then
    sline = vim.fn.line("'<")

else

            eline = vim.fn.line("'>")
      slne = vim.fn.line(".")
eline = sline
end
end
```

## Typescript

Hier ist unformatierter Typescript Code:

```ts
const fs = require('fs-extra');
const klaw = require('klaw');
const path = require('path');
const INPUT = path.join(__dirname, '..', 'data', 'input');

stream.on('data', (item) => {
const filePath = item.path;
const timeCreated = item.stats.birthtime.toUTCString();
console.log(filePath);
console.log(timeCreated);
if (item.stats.isFile()) {
const content = fs.readFileSync(filePath).toString();
});}console.log(content);
stream.on('end', () => {
console.log('done');
});
```
