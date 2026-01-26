# Benchmarking-Strategie

## Table of content

- [Benchmarking-Strategie](#benchmarking-strategie)
  - [Baseline (vor Refactoring)](#baseline-vor-refactoring)
  - [A/B-Test](#ab-test)
- [Risiken & Mitigationen](#risiken-mitigationen)
- [Success Metrics](#success-metrics)
- [Fazit](#fazit)

---

## Baseline (vor Refactoring)

```lua
-- bench/baseline.lua
local iterations = 1000
local start = vim.loop.hrtime()

for i = 1, iterations do
  vim.cmd("doautocmd CursorMoved")
end

local elapsed = (vim.loop.hrtime() - start) / 1e6
print(string.format("%.2fms/event", elapsed / iterations))
```

## A/B-Test

```lua
-- bench/compare.lua
local old = require("autocmds.events.hot_path.cursor_moved_old")
local new = require("autocmds.events.hot_path.cursor_moved")

local function bench(fn, name)
  local start = vim.loop.hrtime()
  for i = 1, 1000 do
    fn()
  end
  local elapsed = (vim.loop.hrtime() - start) / 1e6
  print(string.format("%s: %.2fms/event", name, elapsed / 1000))
end

bench(old, "Old")
bench(new, "New")
```

---

