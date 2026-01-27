
```lua
-- In init.lua hinzufügen:
require("benchmarks").setup()

-- Dann in Neovim:
:BenchAll                            -- Alles
:BenchAutocmdsBaseline               -- Nur Baseline
:BenchPhase0                         -- Nur Tests

-- Oder programmierbar:
local results = require("benchmarks").run_all()
print(vim.inspect(results))
```

```vim
:lua require("benchmarks.autocmds.phase0_tests").run_all()
```
