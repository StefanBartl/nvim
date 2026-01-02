# watcher_quarantine

Prevents EPERM errors and UI freezes during file operations by temporarily stopping Neo-tree's file watchers and suppressing error notifications.

## Table of content

  - [The Problem](#the-problem)
  - [The Solution: Quarantine System](#the-solution-quarantine-system)
  - [Features](#features)
  - [Quick Start](#quick-start)
  - [API](#api)
    - [Core Functions](#core-functions)
      - [`enter_quarantine(duration_ms, paths?)`](#enter_quarantineduration_ms-paths)
      - [`exit_quarantine()`](#exit_quarantine)
      - [`is_quarantined()`](#is_quarantined)
      - [`is_path_quarantined(path)`](#is_path_quarantinedpath)
      - [`safe_refresh(state_name, callback?)`](#safe_refreshstate_name-callback)
    - [Utility Functions](#utility-functions)
      - [`health_check()`](#health_check)
      - [`restart_watchers()`](#restart_watchers)
  - [Internal State](#internal-state)
  - [EPERM Suppression](#eperm-suppression)
    - [How it works](#how-it-works)
    - [Patterns suppressed](#patterns-suppressed)
    - [What's NOT suppressed](#whats-not-suppressed)
  - [Integration Examples](#integration-examples)
    - [With trash.lua](#with-trashlua)
    - [With copy operation](#with-copy-operation)
    - [With batch operations](#with-batch-operations)
  - [Configuration](#configuration)
    - [Recommended Durations](#recommended-durations)
    - [Platform Considerations](#platform-considerations)
  - [Troubleshooting](#troubleshooting)
    - [Problem: Still getting EPERM](#problem-still-getting-eperm)
    - [Problem: Refresh not happening](#problem-refresh-not-happening)
    - [Problem: Watchers not restarting](#problem-watchers-not-restarting)
    - [Problem: Notifications still showing](#problem-notifications-still-showing)
  - [Performance](#performance)
    - [Memory Usage](#memory-usage)
    - [CPU Usage](#cpu-usage)
  - [Best Practices](#best-practices)
    - [✅ DO](#do)
    - [❌ DON'T](#dont)
  - [Advanced Usage](#advanced-usage)
    - [Custom Retry Logic](#custom-retry-logic)
    - [Per-Operation Durations](#per-operation-durations)
    - [Conditional Quarantine](#conditional-quarantine)
    - [Quarantine Events](#quarantine-events)
  - [Testing](#testing)
  - [Debug Commands](#debug-commands)
  - [See Also](#see-also)
  - [License](#license)
  - [Changelog](#changelog)
    - [v1.0.0 (2024-01)](#v100-2024-01)

---

## The Problem

On Windows (and occasionally other platforms), file operations can trigger EPERM errors:

```
Error: [Neo-tree ERROR] file_event_callback: EPERM: operation not permitted
```

**Why this happens:**
1. File deleted/moved → triggers filesystem event
2. Neo-tree's watcher tries to stat the file
3. Windows hasn't fully released the file handle yet
4. EPERM error → notification spam → UI freeze

**Timeline of the bug:**
```
t=0ms:   User deletes file
t=50ms:  File deleted successfully
t=100ms: safe_refresh() called
t=150ms: Watchers restart, try to stat deleted file
t=151ms: EPERM ERROR (file still locked by Windows)
t=2000ms+: UI freezes while errors accumulate
```

---

## The Solution: Quarantine System

The **quarantine** system solves this by creating a "safe period" where:
- ✅ All file watchers are stopped
- ✅ EPERM notifications are suppressed
- ✅ Refresh waits until filesystem has settled
- ✅ Watchers restart safely after quarantine ends

**Timeline with quarantine:**
```
t=0ms:    enter_quarantine(2000)
t=1ms:    All watchers stopped
t=2ms:    EPERM suppression enabled
t=50ms:   User deletes file
t=100ms:  safe_refresh() called
t=101ms:  Refresh waits (quarantine still active)
t=2000ms: Quarantine expires
t=2001ms: Refresh executes (safe now)
t=2002ms: Watchers restart cleanly
```

---

## Features

* **Auto-Expire**: Quarantine ends automatically after duration
* **Path-Specific**: Can quarantine specific paths instead of global
* **Error Suppression**: Filters EPERM from notifications
* **Async-Safe**: Non-blocking refresh with retry logic
* **Health-Check**: Verify watcher system integrity
* **Manual Override**: Exit quarantine early if needed

---

## Quick Start

```lua
local wq = require("config.neotree.watcher_quarantine")

-- Before file operation
wq.enter_quarantine(1500, { "/path/to/file.txt" })

-- Do your file operation
os.remove("/path/to/file.txt")

-- Safe refresh (waits for quarantine automatically)
wq.safe_refresh("filesystem")

-- Quarantine expires after 1500ms automatically
```

---

## API

### Core Functions

#### `enter_quarantine(duration_ms, paths?)`

Enter quarantine mode: stops watchers and suppresses EPERM.

**Parameters:**
```lua
---@param duration_ms integer Quarantine duration (default: 1500)
---@param paths string[]|nil Optional specific paths to quarantine
```

**Example:**
```lua
-- Global quarantine for 2 seconds
wq.enter_quarantine(2000)

-- Quarantine specific paths
wq.enter_quarantine(1500, { "/path/to/file", "/path/to/dir" })
```

**What it does:**
1. Sets `in_quarantine = true`
2. Calculates `quarantine_until` timestamp
3. Stops all Neo-tree file watchers
4. Patches `vim.notify` to filter EPERM
5. Stores path-specific quarantine times

---

#### `exit_quarantine()`

Exit quarantine early (before auto-expire).

**Example:**
```lua
wq.enter_quarantine(2000)
-- ... operation completes quickly ...
wq.exit_quarantine()  -- No need to wait full 2s
```

**What it does:**
1. Sets `in_quarantine = false`
2. Clears all quarantine timestamps
3. Restores original `vim.notify`
4. Allows normal watcher operation

---

#### `is_quarantined()`

Check if currently in quarantine period.

**Returns:** `boolean`

**Example:**
```lua
if wq.is_quarantined() then
  print("Still in quarantine, waiting...")
else
  print("Safe to refresh")
end
```

**Auto-Expire:**
- Automatically returns `false` after duration
- Cleans up internal state when expired

---

#### `is_path_quarantined(path)`

Check if specific path is quarantined.

**Parameters:**
```lua
---@param path string File/directory path
```

**Returns:** `boolean`

**Example:**
```lua
local path = "/path/to/file.txt"
if wq.is_path_quarantined(path) then
  print("Path still quarantined")
end
```

**Use-Case:** Per-path operations in multi-file scenarios.

---

#### `safe_refresh(state_name, callback?)`

Refresh Neo-tree safely, waiting for quarantine to end.

**Parameters:**
```lua
---@param state_name string Source name (e.g., "filesystem")
---@param callback fun()|nil Optional callback after refresh
```

**Example:**
```lua
-- Simple refresh
wq.safe_refresh("filesystem")

-- With callback
wq.safe_refresh("filesystem", function()
  print("Refresh complete!")
end)
```

**Behavior:**
- If quarantined: waits, retries every 200ms
- If not quarantined: refreshes immediately
- Callback executed after refresh completes

---

### Utility Functions

#### `health_check()`

Verify file watcher system is functional.

**Returns:** `boolean, string|nil`
- `true, nil` if healthy
- `false, reason` if unhealthy

**Example:**
```lua
local healthy, reason = wq.health_check()
if not healthy then
  print("Watchers unhealthy:", reason)
end
```

**Checks:**
- Can require file_watcher module
- Module has required functions
- Functions are callable

---

#### `restart_watchers()`

Manually restart all file watchers.

**Returns:** `boolean, string|nil`
- `true` if restart initiated
- `false, "still in quarantine"` if quarantined

**Example:**
```lua
local ok, err = wq.restart_watchers()
if not ok then
  print("Can't restart:", err)
end
```

**Use-Case:** Recovery from watcher desync issues.

---

## Internal State

```lua
local S = {
  in_quarantine = false,        -- Global quarantine active
  quarantine_until = 0,          -- Timestamp (vim.loop.now())
  suspended_paths = {},          -- { [path] = until_timestamp }
  error_suppressed = false,      -- EPERM filtering active
  original_notify = nil,         -- Backup of vim.notify
}
```

**State Transitions:**

```
[Idle] --enter_quarantine()--> [Quarantined]
       <--exit_quarantine()--

[Quarantined] --auto_expire()--> [Idle]
              --exit_quarantine()--> [Idle]
```

---

## EPERM Suppression

### How it works

```lua
-- Original notify is backed up
S.original_notify = vim.notify

-- Patched version filters EPERM
vim.notify = function(msg, level, opts)
  if S.error_suppressed and type(msg) == "string" then
    -- Match EPERM variants
    if msg:match("EPERM") or
       msg:match("permission denied") or
       msg:match("Operation not permitted") then
      return  -- Suppress!
    end
  end

  -- Pass through non-EPERM messages
  S.original_notify(msg, level, opts)
end
```

### Patterns suppressed

- `"EPERM"`
- `"permission denied"`
- `"Operation not permitted"`

### What's NOT suppressed

- Normal notifications
- Other error types
- Info/Warn messages

---

## Integration Examples

### With trash.lua

```lua
local wq = require("config.neotree.watcher_quarantine")

function delete_file(path)
  -- Enter quarantine
  wq.enter_quarantine(2000, { path })

  -- Close related resources
  close_buffers(path)
  vim.wait(100)

  -- Delete
  local ok = os.remove(path)

  -- Safe refresh (waits automatically)
  wq.safe_refresh("filesystem")

  return ok
end
```

---

### With copy operation

```lua
function safe_copy(src, dest)
  wq.enter_quarantine(1500, { src, dest })

  local ok, err = vim.loop.fs_copyfile(src, dest)

  if ok then
    wq.safe_refresh("filesystem")
  else
    wq.exit_quarantine()  -- Exit early on failure
  end

  return ok, err
end
```

---

### With batch operations

```lua
function batch_delete(paths)
  -- Single quarantine for all paths
  wq.enter_quarantine(2000, paths)

  local results = {}
  for _, path in ipairs(paths) do
    results[path] = os.remove(path)
  end

  -- One refresh for all
  wq.safe_refresh("filesystem")

  return results
end
```

---

## Configuration

### Recommended Durations

| Operation | Duration | Rationale |
|-----------|----------|-----------|
| Delete file | 1500ms | Standard Windows release time |
| Delete directory | 2000ms | More complex, may have watchers |
| Move/Rename | 1500ms | Similar to delete |
| Copy | 1000ms | Source still exists, less risky |
| Create | 1000ms | Simple operation |
| Batch ops | 2000ms | Multiple files need settling |

### Platform Considerations

**Windows:**
- Needs longest durations (1500-2000ms)
- File locks persist longer
- Antivirus can delay release

**Linux/macOS:**
- Can use shorter durations (1000-1500ms)
- Filesystem more responsive
- Still benefits from quarantine (race conditions)

---

## Troubleshooting

### Problem: Still getting EPERM

**Diagnose:**
```lua
-- Check if quarantine is active
print(wq.is_quarantined())

-- Check duration
print(wq.S.quarantine_until - vim.loop.now())
```

**Solutions:**
1. Increase duration: `enter_quarantine(3000)`
2. Check if exiting too early
3. Verify watcher system: `wq.health_check()`

---

### Problem: Refresh not happening

**Diagnose:**
```lua
-- Add debug logging to safe_refresh
local original_refresh = wq.safe_refresh
wq.safe_refresh = function(...)
  print("safe_refresh called")
  return original_refresh(...)
end
```

**Solutions:**
1. Ensure quarantine was entered
2. Check callback isn't nil
3. Verify Neo-tree is loaded

---

### Problem: Watchers not restarting

**Diagnose:**
```lua
local healthy, reason = wq.health_check()
print("Healthy:", healthy, "Reason:", reason)
```

**Solutions:**
1. Manual restart: `wq.restart_watchers()`
2. Exit quarantine: `wq.exit_quarantine()`
3. Reload Neo-tree: `:Lazy reload neo-tree.nvim`

---

### Problem: Notifications still showing

**Diagnose:**
```lua
-- Check suppression state
print("Suppressed:", wq.S.error_suppressed)
print("Original notify:", wq.S.original_notify ~= nil)
```

**Solutions:**
1. Verify quarantine entered: `wq.is_quarantined()`
2. Check patch applied: Should have `original_notify` backup
3. Look for other notify patches (conflict)

---

## Performance

### Memory Usage

```lua
-- State object: ~200 bytes
-- Per-path entry: ~100 bytes
-- Notify patch: ~8 bytes (function reference)

-- Example with 10 quarantined paths:
Total: ~1.2 KB (negligible)
```

### CPU Usage

| Operation | Cost | Notes |
|-----------|------|-------|
| `enter_quarantine()` | ~5ms | Stop watchers + patch notify |
| `is_quarantined()` | <1ms | Simple timestamp check |
| `exit_quarantine()` | ~2ms | Unpatch notify |
| `safe_refresh()` retry | ~1ms | Timestamp check + defer |

**Total overhead:** ~10ms per operation (imperceptible)

---

## Best Practices

### ✅ DO

```lua
-- Use appropriate durations
wq.enter_quarantine(1500)  -- Good for most ops

-- Quarantine before operation
wq.enter_quarantine(2000, { path })
os.remove(path)

-- Use safe_refresh
wq.safe_refresh("filesystem")

-- Let quarantine auto-expire
-- (Don't manually exit unless necessary)

-- Check health periodically
if not wq.health_check() then
  wq.restart_watchers()
end
```

---

### ❌ DON'T

```lua
-- TOO SHORT: Windows needs time
wq.enter_quarantine(100)  -- ❌

-- EXIT TOO EARLY: Let it auto-expire
wq.enter_quarantine(2000)
os.remove(path)
wq.exit_quarantine()  -- ❌ Too early!

-- REFRESH WITHOUT QUARANTINE
os.remove(path)
manager.refresh("filesystem")  -- ❌ EPERM likely!

-- NESTED QUARANTINES
wq.enter_quarantine(2000)
wq.enter_quarantine(1000)  -- ❌ Confusing state

-- MANUAL WATCHER OPERATIONS DURING QUARANTINE
wq.enter_quarantine(2000)
watcher.start()  -- ❌ Defeats purpose!
```

---

## Advanced Usage

### Custom Retry Logic

```lua
local function safe_refresh_with_retries(state_name, max_retries)
  local retries = 0

  local function attempt_refresh()
    if wq.is_quarantined() then
      if retries < max_retries then
        retries = retries + 1
        vim.defer_fn(attempt_refresh, 200)
      else
        vim.notify("Refresh timeout after quarantine", vim.log.levels.WARN)
      end
      return
    end

    -- Refresh now
    local ok, manager = pcall(require, "neo-tree.sources.manager")
    if ok then
      pcall(manager.refresh, state_name)
    end
  end

  vim.defer_fn(attempt_refresh, 100)
end
```

---

### Per-Operation Durations

```lua
local QUARANTINE_DURATIONS = {
  delete = 1500,
  delete_dir = 2000,
  move = 1500,
  copy = 1000,
  create = 1000,
}

local function quarantine_for_operation(op_type, paths)
  local duration = QUARANTINE_DURATIONS[op_type] or 1500
  wq.enter_quarantine(duration, paths)
end
```

---

### Conditional Quarantine

```lua
-- Only quarantine on Windows
local function smart_quarantine(duration, paths)
  if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
    wq.enter_quarantine(duration, paths)
  else
    -- Linux/Mac: shorter or no quarantine
    wq.enter_quarantine(math.floor(duration * 0.5), paths)
  end
end
```

---

### Quarantine Events

```lua
-- Emit custom autocmd events
local function enter_quarantine_with_event(duration, paths)
  wq.enter_quarantine(duration, paths)
  vim.api.nvim_exec_autocmds("User", {
    pattern = "WatcherQuarantineEnter",
    data = { paths = paths, duration = duration }
  })
end

-- Listen for events
vim.api.nvim_create_autocmd("User", {
  pattern = "WatcherQuarantineEnter",
  callback = function(event)
    print("Quarantine entered for:", vim.inspect(event.data.paths))
  end,
})
```

---

## Testing

```lua
describe("watcher_quarantine", function()
  local wq = require("config.neotree.watcher_quarantine")

  before_each(function()
    wq.exit_quarantine()
  end)

  it("enters quarantine", function()
    wq.enter_quarantine(1000)
    assert.is_true(wq.is_quarantined())
  end)

  it("auto-expires", function()
    wq.enter_quarantine(100)
    vim.wait(150)
    assert.is_false(wq.is_quarantined())
  end)

  it("suppresses EPERM", function()
    local notified = false
    local orig_notify = vim.notify

    vim.notify = function(msg, level)
      if msg:match("EPERM") then
        notified = true
      end
    end

    wq.enter_quarantine(1000)
    vim.notify("EPERM: test error", vim.log.levels.ERROR)

    assert.is_false(notified)

    vim.notify = orig_notify
    wq.exit_quarantine()
  end)

  it("allows non-EPERM notifications", function()
    local msg_received = nil
    local orig_notify = vim.notify

    vim.notify = function(msg, level)
      msg_received = msg
    end

    wq.enter_quarantine(1000)
    vim.notify("Normal message", vim.log.levels.INFO)

    assert.equals("Normal message", msg_received)

    vim.notify = orig_notify
    wq.exit_quarantine()
  end)

  it("tracks path-specific quarantine", function()
    local path = "/test/path.txt"
    wq.enter_quarantine(1000, { path })

    assert.is_true(wq.is_path_quarantined(path))
    assert.is_false(wq.is_path_quarantined("/other/path.txt"))
  end)

  it("safe_refresh waits for quarantine", function()
    local refreshed = false

    wq.enter_quarantine(200)

    wq.safe_refresh("filesystem", function()
      refreshed = true
    end)

    -- Should not refresh immediately
    vim.wait(50)
    assert.is_false(refreshed)

    -- Should refresh after quarantine
    vim.wait(300)
    assert.is_true(refreshed)
  end)
end)
```

---

## Debug Commands

Add these to your config:

```lua
vim.api.nvim_create_user_command("WatcherQuarantineStatus", function()
  local wq = require("config.neotree.watcher_quarantine")
  local in_q = wq.is_quarantined()
  local until_time = wq.S.quarantine_until - vim.loop.now()
  local healthy, reason = wq.health_check()

  print(string.format([[
Watcher Quarantine Status:
  Active: %s
  Time remaining: %dms
  Suppressed: %s
  Paths: %d
  Watchers healthy: %s%s
  ]],
    in_q and "YES" or "NO",
    in_q and until_time or 0,
    wq.S.error_suppressed and "YES" or "NO",
    vim.tbl_count(wq.S.suspended_paths),
    healthy and "YES" or "NO",
    reason and ("\n  Reason: " .. reason) or ""
  ))
end, {})

vim.api.nvim_create_user_command("WatcherQuarantineExit", function()
  local wq = require("config.neotree.watcher_quarantine")
  wq.exit_quarantine()
  print("Quarantine exited")
end, {})

vim.api.nvim_create_user_command("WatcherRestart", function()
  local wq = require("config.neotree.watcher_quarantine")
  local ok, err = wq.restart_watchers()
  if ok then
    print("Watchers restarted")
  else
    print("Failed:", err)
  end
end, {})
```

---

## See Also

- [`trash.lua`](../trash.lua) - Main consumer of quarantine
- [`refresh_adapter.lua`](../refresh_adapter.lua) - Quarantine-aware refresh
- [`file_operation_wrapper.lua`](../file_operation_wrapper.lua) - Wrapper for other ops
- [Neo-tree Watchers](https://github.com/nvim-neo-tree/neo-tree.nvim/blob/main/lua/neo-tree/sources/filesystem/lib/file_watcher.lua)

---

## License

Part of personal Neovim configuration.

---

## Changelog

### v1.0.0 (2024-01)
- Initial release
- Global and per-path quarantine
- EPERM suppression
- Async-safe refresh
- Health check utilities

---
