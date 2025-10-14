# lib/strings README

| Name              | Module               | Signature                                                       | Description                                                                      |
| ----------------- | -------------------- | --------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| trim              | lib.strings.core     | trim(s: any): string                                            | Remove leading/trailing ASCII whitespace (returns empty string for non-strings). |
| starts_with       | lib.strings.core     | starts_with(s: string, prefix: string): boolean                 | Test whether s begins with prefix.                                               |
| ends_with         | lib.strings.core     | ends_with(s: string, suffix: string): boolean                   | Test whether s ends with suffix.                                                 |
| contains          | lib.strings.core     | contains(s: string, needle: string): boolean                    | Plain substring test (no patterns).                                              |
| split             | lib.strings.core     | split(s: string, sep: string): string[]                         | Split by plain separator sep.                                                    |
| join              | lib.strings.core     | join(parts: string[], sep: string): string                      | Join parts with sep.                                                             |
| replace_all       | lib.strings.core     | replace_all(s: string, from: string, to: string): string        | Replace all plain occurrences of from with to.                                   |
| normalize_ws      | lib.strings.core     | normalize_ws(s: string): string                                 | Collapse runs of whitespace to single spaces and trim.                           |
| capitalize        | lib.strings.core     | capitalize(s: string): string                                   | Uppercase first letter only.                                                     |
| uncapitalize      | lib.strings.core     | uncapitalize(s: string): string                                 | Lowercase first letter only.                                                     |
| slugify           | lib.strings.core     | slugify(s: string): string                                      | Lowercase; remove non-word chars; collapse spaces to dashes.                     |
| kebab_case        | lib.strings.core     | kebab_case(s: string): string                                   | Convert to kebab-case; handles spaces/underscores/camel-case.                    |
| snake_case        | lib.strings.core     | snake_case(s: string): string                                   | Convert to snake_case; handles spaces/dashes/camel-case.                         |
| camel_case        | lib.strings.core     | camel_case(s: string): string                                   | Convert words to lowerCamelCase.                                                 |
| pad_start         | lib.strings.core     | pad_start(s: string, width: integer): string                    | Left-pad with spaces to width.                                                   |
| pad_end           | lib.strings.core     | pad_end(s: string, width: integer): string                      | Right-pad with spaces to width.                                                  |
| pad_center        | lib.strings.core     | pad_center(s: string, width: integer): string                   | Center-pad with spaces to width.                                                 |
| indent            | lib.strings.core     | indent(s: string, n: integer): string                           | Indent every line by n spaces.                                                   |
| dedent            | lib.strings.core     | dedent(s: string): string                                       | Remove common minimal leading spaces across lines.                               |
| is_empty_or_space | lib.strings.core     | is_empty_or_space(s: any): boolean                              | True when not a string or only whitespace.                                       |
| escape_lua_magic  | lib.strings.patterns | escape_lua_magic(s: string): string                             | Escape Lua pattern magic chars.                                                  |
| find_plain        | lib.strings.patterns | find_plain(s: string, needle: string): integer|nil, integer|nil | Plain find; returns start, finish or nil.                                        |
| replace_plain     | lib.strings.patterns | replace_plain(s: string, from: string, to: string): string      | Plain replace (no patterns).                                                     |
| surround          | lib.strings.patterns | surround(s: string, left: string, right: string): string        | Surround s with left/right.                                                      |

## Usage

```lua
local S = require("lib.strings.core")
local P = require("lib.strings.patterns")

-- Basic sanitation
local title = "   Hello  World   "
title = S.normalize_ws(title)          -- "Hello World"
title = S.kebab_case(title)            -- "hello-world"

-- Safe plain replacement
local out = S.replace_all("a.b.c", ".", "/")      -- "a/b/c"
-- When dealing with Lua patterns, escape first:
local pat = P.escape_lua_magic(".")
local safe = (("a.b.c"):gsub(pat, "/"))           -- "a/b/c"

-- Padding for table-like UIs
local head = S.pad_end("id", 6) .. S.pad_end("name", 12)  -- "id    name        "

-- Multiline helpers
local block = [[
    line one
      line two
]]
local compact = S.dedent(block)        -- leading margin removed
local indented = S.indent(compact, 2)  -- 2-space indent

-- Case transforms
S.camel_case("hello world")            -- "helloWorld"
S.snake_case("Hello-World x")          -- "hello_world_x"
S.slugify("Ä Funny Title!")            -- " funny-title" (non-ASCII stripped)
```

## Notes

* All functions are pure and avoid Lua pattern semantics unless you explicitly use the patterns module.
* split/join/replace_all are plain-string based; they do not interpret Lua patterns and thus are safe for user-input separators.
* kebab_case/snake_case/camel_case include a simple camel-split heuristic using frontier patterns; they are locale-agnostic.
* pad_* operate on byte length (#s), not display width; for wide chars one can integrate a width function later if needed.

---
