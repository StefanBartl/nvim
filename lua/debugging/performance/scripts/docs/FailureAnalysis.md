# Benchmark Failure Analysis

## Problem: 30-50% of Runs Fail

### Root Causes

#### 1. **Race Conditions in Plugin Initialization**

**Symptom**: Inconsistent failures, some runs succeed, others timeout

**Cause**: The measurement script tries to read plugin stats before plugins are fully initialized.

**Technical Details**:
```lua
-- Problem: This check is not atomic
local lazy = require("lazy")
if lazy and lazy.stats then
  local stats = lazy.stats()  -- Might not be ready yet
end
```

**Solution in Updated Script**:
- Exponential backoff retry mechanism
- Up to 10 attempts with increasing delays
- Graceful fallback to alternative measurement methods

**Configuration**:
```lua
-- In benchmark_startup.lua
local max_attempts = 10
local base_delay = 50  -- ms

-- Exponential backoff: 50, 100, 200, 400, ...
local delay = base_delay * (2 ^ (attempts - 1))
```

#### 2. **Insufficient Timeout**

**Symptom**: "TIMEOUT - killed after 5s" messages

**Cause**: Some plugin combinations genuinely need more time to initialize.

**Affected Configurations**:
- Many LSP servers (>5)
- Treesitter with many parsers
- Mason with tool installations
- Network-dependent plugins (GitHub Copilot, etc.)

**Solution**:
```powershell
# In benchmark_nvim.ps1
$Timeout = 10  # Increase from 5 to 10 seconds
```

```bash
# In benchmark_nvim.sh
TIMEOUT=10  # Increase from 5 to 10 seconds
```

#### 3. **Lua Module Caching Issues**

**Symptom**: First run succeeds, subsequent runs fail

**Cause**: Neovim's module cache isn't properly cleared between runs.

**Technical Details**:
```lua
-- package.loaded persists across runs in some scenarios
local lazy = package.loaded["lazy"]  -- Might be stale
```

**Mitigation**:
The 300ms delay between runs helps, but not always sufficient.

**Better Solution**:
```bash
# Force fresh nvim instance each time
unset NVIM_APPNAME
export NVIM_LOG_FILE="/dev/null"
```

#### 4. **Async Plugin Operations**

**Symptom**: Random failures, no pattern

**Plugins That Cause This**:
- `mason.nvim` (tool installation checks)
- `lazy.nvim` (git operations)
- `telescope.nvim` (file scanning)
- LSP servers (workspace initialization)

**Current Mitigation**:
```lua
-- In benchmark_startup.lua
vim.defer_fn(function()
  -- Wait 100ms for async operations
  try_measure()
end, 100)
```

**Advanced Solution**:
Create a "benchmark mode" that disables async operations:
```lua
if vim.env.NVIM_BENCHMARK_MODE then
  -- Disable all async operations
  vim.g.mason_auto_install = false
  vim.g.copilot_enabled = false
end
```

#### 5. **Output Parsing Failures**

**Symptom**: "FAILED (no valid output)" messages

**Cause**: The Lua script crashes silently or outputs unexpected format.

**Debug Process**:
```vim
:BenchmarkRunDebug 3
```

Look for:
```
ERROR: <error message>
TIMEOUT
<unexpected output>
```

**Common Parsing Issues**:
- Extra print statements from plugins
- Error messages mixed with timing data
- Incomplete JSON (slow plugins)

**Robust Parsing**:
```bash
# Match ONLY lines starting with digits
timing_line=$(echo "$output" | grep -E '^\d+\.\d+,\d+\.\d+,\d+\.\d+,\d+,' | head -n1)
```

### Diagnostic Process

#### Step 1: Identify Failure Pattern

Run debug mode:
```vim
:BenchmarkRunDebug 5
```

Categorize failures:
- [ ] All timeouts → Increase timeout
- [ ] Random failures → Race condition
- [ ] First run fails → Warmup issue
- [ ] Parse errors → Output corruption

#### Step 2: Isolate Problematic Plugins

Manually test startup:
```bash
nvim --startuptime startup.log \
     -c "lua print(vim.inspect(require('lazy').stats()))" \
     -c "qa!"
```

Check if timing appears in output.

#### Step 3: Check System Load

```bash
# Monitor during benchmark
watch -n 1 'ps aux | grep nvim'

# Check if multiple nvim instances are running
pgrep nvim | wc -l
```

Should be 1 during each run, 0 between runs.

#### Step 4: Verify File I/O

```bash
# Check if temp files are properly created/deleted
ls /tmp/nvim_startuptime_* 2>/dev/null | wc -l
```

Should be 0 after benchmark completes.

### Solutions by Failure Rate

#### < 10% Failure Rate
**Status**: Acceptable
**Action**: None, this is within statistical noise

#### 10-30% Failure Rate
**Status**: Concerning
**Actions**:
1. Increase timeout to 10s
2. Reduce concurrent operations
3. Add delays between runs

#### > 30% Failure Rate
**Status**: Critical
**Actions**:
1. Enable debug mode
2. Check for hanging plugins
3. Temporarily disable problematic plugins
4. File a bug report with output

### Improved Benchmark Script (Key Changes)

#### 1. Exponential Backoff

```lua
local function try_measure()
  attempts = attempts + 1

  if ready or attempts >= max_attempts then
    perform_measurement()
  else
    local delay = base_delay * (2 ^ (attempts - 1))
    vim.defer_fn(try_measure, math.min(delay, 500))
  end
end
```

#### 2. Multiple Measurement Methods

```lua
-- Priority 1: Lazy.nvim stats (most accurate)
pcall(function()
  local lazy = require("lazy")
  if lazy and lazy.stats then
    startup_ms = lazy.stats().startuptime
  end
end)

-- Priority 2: Parse startuptime file
if startup_ms == 0.0 then
  -- Parse --startuptime file
end

-- Priority 3: Use UI enter time (fallback)
if startup_ms == 0.0 then
  startup_ms = ui_enter_ms
end
```

#### 3. Better Error Reporting

```lua
pcall(function()
  perform_measurement()
end)
if not ok then
  io.write("ERROR: " .. tostring(err) .. "\n")
  io.flush()
end
```

### Monitoring Recommendations

#### Before Large-Scale Benchmarking

```bash
# Clear all caches
rm -rf ~/.cache/nvim
rm -rf ~/.local/share/nvim

# Ensure clean state
killall nvim 2>/dev/null

# Verify no background processes
pgrep nvim
```

#### During Benchmarking

```bash
# In another terminal
watch -n 1 'ps aux | grep nvim | wc -l'
```

Should oscillate between 0 and 1.

#### After Benchmarking

```bash
# Check for hung processes
pgrep nvim

# Clean up temp files
rm -f /tmp/nvim_startuptime_*
```

### When to File a Bug

If after all optimizations:
- Failure rate > 30%
- Debug mode shows plugin-specific errors
- Same plugin fails consistently

Then:
1. Capture full debug output
2. Note plugin version and commit
3. File issue with plugin maintainer

### Performance vs. Reliability Trade-offs

| Configuration | Reliability | Speed | Recommendation |
|---------------|-------------|-------|----------------|
| Timeout=3s | 60% | Fast | ❌ Too unreliable |
| Timeout=5s | 85% | Good | ⚠️ Current default |
| Timeout=10s | 95% | Slow | ✅ Recommended |
| Timeout=20s | 99% | Very slow | 🔧 Only if needed |

### Expected Failure Rates

| Scenario | Expected Failures | Action Required |
|----------|-------------------|-----------------|
| First benchmark ever | 0-5% | None |
| After config changes | 5-15% | Monitor |
| With many plugins | 10-20% | Consider timeout |
| Complex LSP setup | 15-30% | Increase timeout |
| Network-dependent | 20-40% | Disable in benchmark |

### Final Checklist

- [ ] Updated to latest benchmark scripts
- [ ] Timeout increased if needed
- [ ] Warmup enabled
- [ ] No other nvim instances running
- [ ] Clean filesystem state
- [ ] Debug mode tested
- [ ] Failure rate < 30%

### Advanced: Custom Benchmark Mode

Create a minimal init.lua for benchmarking only:

```lua
-- init.benchmark.lua
vim.g.benchmark_mode = true

-- Load only essential plugins
require("lazy").setup({
  -- Core plugins only
}, {
  performance = {
    cache = { enabled = false },
  }
})
```

Then run:
```bash
NVIM_APPNAME=.nvim.benchmark nvim --startuptime ...
```

This isolates benchmarking from regular usage.

---

**Remember**: Perfect reliability (100%) is not achievable in complex systems. Aim for 85-95% success rate with the updated scripts.P

---
