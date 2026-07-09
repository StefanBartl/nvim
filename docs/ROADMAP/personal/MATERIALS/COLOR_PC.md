# color_my_ascii check

## commands

`:lua local f = io.open("docs/ROADMAP/personal/MATERIALS/COLOR_PC.md", "a") if f then f:write(vim.inspect(require('color_my_ascii').fences.list_blocks(0, {lines="none"})) .. "\n") f:close() end`

`:lua local f = io.open("docs/ROADMAP/personal/MATERIALS/COLOR_PC.md", "a") if f then f:write(tostring(#require('color_my_ascii').fences.list_blocks(0, {lines="none"})) .. "\n") f:close() end`

`:lua local f = io.open("docs/ROADMAP/personal/MATERIALS/COLOR_PC.md", "a") if f then f:write(vim.inspect(require('color_my_ascii').fences.list_blocks(0, {lines="none"})) .. "\n") f:close() end`

---

## :lua vim.print(require('color_my_ascii').fences.list_blocks(0, {lines="none"}))

{ {
    close_row = 22,
    content_end = 22,
    content_start = 10,
    end_line = 22,
    fence_char = "`",
    fence_len = 3,
    fence_line = "```markdown",
    is_ascii = false,
    lang = "markdown",
    open_row = 9,
    start_line = 9
  }, {
    close_row = 40,
    content_end = 40,
    content_start = 28,
    end_line = 40,
    fence_char = "`",
    fence_len = 3,
    fence_line = "```markdown",
    is_ascii = false,
    lang = "markdown",
    open_row = 27,
    start_line = 27
  }, {
    close_row = 57,
    content_end = 57,
    content_start = 45,
    end_line = 57,
    fence_char = "`",
    fence_len = 3,
    fence_line = "```markdown",
    is_ascii = false,
    lang = "markdown",
    open_row = 44,
    start_line = 44
  } }

---

## :lua print(#require('color_my_ascii').fences.list_blocks(0, {lines="none"}))

3

---

## :lua print(vim.inspect(require('color_my_ascii').fences.list_blocks(0, {lines="none"})))

21:43:54 msg_show.lua_print   print(vim.inspect(require('color_my_ascii').fences.list_blocks(0, {lines="none"}))) { {
    close_row = 22,
    content_end = 22,
    content_start = 10,
    end_line = 22,
    fence_char = "`",
    fence_len = 3,
    fence_line = "```markdown",
    is_ascii = false,
    lang = "markdown",
    open_row = 9,
    start_line = 9
  }, {
    close_row = 40,
    content_end = 40,
    content_start = 28,
    end_line = 40,
    fence_char = "`",
    fence_len = 3,
    fence_line = "```markdown",
    is_ascii = false,
    lang = "markdown",
    open_row = 27,
    start_line = 27
  }, {
    close_row = 57,
    content_end = 57,
    content_start = 45,
    end_line = 57,
    fence_char = "`",
    fence_len = 3,
    fence_line = "```markdown",
    is_ascii = false,
    lang = "markdown",
    open_row = 44,
    start_line = 44
  } }

---

