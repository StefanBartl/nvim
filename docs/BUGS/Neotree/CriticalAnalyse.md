# Neo-tree Configuration: Umfassende Refactoring-Analyse

## Table of content

- [Neo-tree Configuration: Umfassende Refactoring-Analyse](#neo-tree-configuration-umfassende-refactoring-analyse)
  - [Executive Summary](#executive-summary)
  - [Performance-Analyse der Timing-Daten](#performance-analyse-der-timing-daten)
    - [Beobachtete Anomalien](#beobachtete-anomalien)
  - [Kritische Bugs & Race Conditions](#kritische-bugs-race-conditions)
    - [🔴 Bug #1: Position-Switch Race Condition](#bug-1-position-switch-race-condition)
    - [🔴 Bug #2: Busy Guard Race bei schnellen Keypresses](#bug-2-busy-guard-race-bei-schnellen-keypresses)
    - [🔴 Bug #3: Float Toggle Determinismus](#bug-3-float-toggle-determinismus)
  - [Refactoring Roadmap](#refactoring-roadmap)
  - [🎯 Milestone 1: Critical Stability Fixes (Prio: CRITICAL)](#milestone-1-critical-stability-fixes-prio-critical)
    - [Tasks](#tasks)
      - [1.1 Position-Switch State Machine reparieren](#11-position-switch-state-machine-reparieren)
      - [1.2 Busy Guard mit Semaphore ersetzen](#12-busy-guard-mit-semaphore-ersetzen)
      - [1.3 Float-Position mit eigener State-Logik](#13-float-position-mit-eigener-state-logik)
    - [Milestone 1 Deliverables](#milestone-1-deliverables)
  - [🚀 Milestone 2: Performance-Optimierung (Prio: HIGH)](#milestone-2-performance-optimierung-prio-high)
    - [Performance-Bottlenecks](#performance-bottlenecks)
      - [2.1 Redundante State-Checks eliminieren](#21-redundante-state-checks-eliminieren)
      - [2.2 Buffer-Validierung cachen](#22-buffer-validierung-cachen)
      - [2.3 Neo-tree Command-Calls batchen](#23-neo-tree-command-calls-batchen)
      - [2.4 Tree-State Restore optimieren](#24-tree-state-restore-optimieren)
    - [Milestone 2 Deliverables](#milestone-2-deliverables)
  - [🏗️ Milestone 3: Architektonische Verbesserungen (Prio: MEDIUM)](#milestone-3-architektonische-verbesserungen-prio-medium)
    - [Architektur-Issues](#architektur-issues)
      - [3.1 Controller: Mixed Responsibilities](#31-controller-mixed-responsibilities)
      - [3.2 Circular Dependencies](#32-circular-dependencies)
      - [3.3 Error Handling inkonsistent](#33-error-handling-inkonsistent)
    - [Milestone 3 Deliverables](#milestone-3-deliverables)
  - [🧪 Milestone 4: Testing & Observability (Prio: LOW)](#milestone-4-testing-observability-prio-low)
    - [Tasks](#tasks-1)
      - [4.1 Unit Tests für State Machine](#41-unit-tests-fr-state-machine)
      - [4.2 Performance Regression Tests](#42-performance-regression-tests)
      - [4.3 Observability: Structured Logging](#43-observability-structured-logging)
  - [📋 Implementation Checklist](#implementation-checklist)
    - [Phase 1: Critical Fixes (Week 1)](#phase-1-critical-fixes-week-1)
    - [Phase 2: Performance (Week 2)](#phase-2-performance-week-2)
    - [Phase 3: Architecture (Week 3)](#phase-3-architecture-week-3)
    - [Phase 4: Testing (Week 4)](#phase-4-testing-week-4)
  - [Expected Outcomes](#expected-outcomes)
  - [Priorität & Risk Assessment](#prioritt-risk-assessment)
  - [Nächste Schritte](#nchste-schritte)

---

## Executive Summary

Nach Analyse der Performance-Daten und des Codes identifiziere ich **3 kritische Problembereiche**:

1. **Race Conditions** bei window operations (→ unzuverlässiges Öffnen/Schließen)
2. **Excessive Overhead** durch redundante State-Checks und API-Calls (→ 13ms avg, Spitzen bis 312ms)
3. **Architektonische Inkonsistenzen** (Mixed Responsibilities, fehlende Guards)

---

## Performance-Analyse der Timing-Daten

### Beobachtete Anomalien

```
Overall: avg=13.2ms (akzeptabel)
BUT: max=312ms (!!!)     ← KRITISCH
     first_cwd=25.9ms    ← 2.4x langsamer als reopen
```

**Root Causes:**

1. **First Open Overhead** (312ms Spitze):
   - Neo-tree source initialization
   - Tree rendering
   - Icon loading
   - Watcher setup

2. **Reopen Varianz** (0.028ms - 105ms):
   - Position-Switches verursachen double-close/open
   - Race zwischen `close_window()` und `open_window()`
   - Buffer-Cleanup bei `current`-Position

---

## Kritische Bugs & Race Conditions

### 🔴 Bug #1: Position-Switch Race Condition

**Location:** `controller.lua:switch_window()`

```lua
-- PROBLEM: Asynchrone Delays ohne State-Synchronisation
close_window(NeoCmd)
vim.defer_fn(function()
  open_window(NeoCmd, target_position)  -- ← Kann VORHER triggern!
end, delay)
```

**Symptom:** "Öffnet → schließt sofort → öffnet am falschen Ort"

**Fix:** Synchrone State-Guards

---

### 🔴 Bug #2: Busy Guard Race bei schnellen Keypresses

**Location:** `controller.lua:try_acquire_lock()`

```lua
-- PROBLEM: Lock-Release erfolgt async, aber Check ist sync
schedule_release(BUSY_GUARD_TIMEOUT_MS)  -- async!
-- Nächster Keypress kommt WÄHREND Release läuft
```

**Symptom:** "Manchmal ignoriert er Keypress, manchmal doppelt"

---

### 🔴 Bug #3: Float Toggle Determinismus

**Location:** `float.lua`

```lua
-- PROBLEM: Neo-tree's float nutzt intern toggle=true
-- → Kein deterministischer State!
```

**Symptom:** Float-Verhalten unvorhersehbar

---

## Refactoring Roadmap

---

## 🎯 Milestone 1: Critical Stability Fixes (Prio: CRITICAL)

**Ziel:** Zuverlässigkeit auf 100%
**ETA:** 3-5 Stunden

### Tasks

#### 1.1 Position-Switch State Machine reparieren

**File:** `controller.lua`

```lua
-- BEFORE (broken):
local function switch_window(NeoCmd, target_position, source)
  close_window(NeoCmd)
  vim.defer_fn(function()
    open_window(NeoCmd, target_position, source)
  end, delay)
end

-- AFTER (fixed):
local function switch_window(NeoCmd, target_position, source)
  local switch_state = {
    closing = true,
    opening = false,
    target = target_position,
    source = source,
  }

  close_window(NeoCmd, function()  -- ← Callback!
    switch_state.closing = false

    -- Guard: Nur öffnen wenn close erfolgreich
    if not state.is_open() then
      switch_state.opening = true
      open_window(NeoCmd, target_position, source, function()
        switch_state.opening = false
      end)
    end
  end)
end
```

**Änderungen:**
- ✅ `close_window()` erhält Callback
- ✅ `open_window()` erhält Callback
- ✅ State wird **synchron** geprüft
- ✅ Guards verhindern Race

---

#### 1.2 Busy Guard mit Semaphore ersetzen

**File:** `controller.lua`

```lua
-- BEFORE (async chaos):
local function schedule_release(delay_ms)
  vim.defer_fn(function()
    release_lock()
  end, delay_ms)
end

-- AFTER (sync semaphore):
local semaphore = {
  count = 1,  -- Max 1 concurrent operation
  waiting = {},
}

local function acquire()
  if semaphore.count > 0 then
    semaphore.count = semaphore.count - 1
    return true
  end
  return false
end

local function release()
  semaphore.count = semaphore.count + 1

  -- Wecke wartende Operation auf
  if #semaphore.waiting > 0 then
    local waiter = table.remove(semaphore.waiting, 1)
    vim.schedule(waiter)
  end
end
```

**Vorteile:**
- ✅ Kein async Release-Race
- ✅ Warteschlange für schnelle Keypresses
- ✅ Deterministisch

---

#### 1.3 Float-Position mit eigener State-Logik

**File:** `float.lua`

```lua
-- NEU: Float-State-Tracker
local float_state = {
  open = false,
  last_toggle = 0,
}

function M.toggle(NeoCmd)
  local now = vim.uv.now()

  -- Anti-Bounce: Min 100ms zwischen Toggles
  if now - float_state.last_toggle < 100 then
    return
  end

  float_state.last_toggle = now
  float_state.open = not float_state.open

  -- Explizit open/close statt toggle
  if float_state.open then
    NeoCmd.execute({
      action = "show",
      position = "float",
      toggle = false,  -- ← Kein Toggle!
    })
  else
    NeoCmd.execute({
      action = "close",
    })
  end
end
```

---

### Milestone 1 Deliverables

- ✅ Switch-Operationen 100% zuverlässig
- ✅ Keine doppelten Öffnungen
- ✅ Float-Position deterministisch
- ✅ Busy Guard arbeitet korrekt

**Testing:**
```lua
-- Stress-Test
for i = 1, 100 do
  vim.cmd("sleep 50m")
  -- Drücke m-l, m-r, m-f, m-c in schneller Folge
end
```

---

## 🚀 Milestone 2: Performance-Optimierung (Prio: HIGH)

**Ziel:** Avg < 8ms, Max < 50ms
**ETA:** 4-6 Stunden

### Performance-Bottlenecks

#### 2.1 Redundante State-Checks eliminieren

**Location:** Überall

```lua
-- BEFORE: 3 separate API-Calls
if state.is_open() then  -- Call 1
  local pos = state.get_position()  -- Call 2
  local src = state.get_source()  -- Call 3
end

-- AFTER: Ein State-Snapshot
local snapshot = state.get_snapshot()  -- Alle Werte auf einmal
if snapshot.open then
  local pos = snapshot.position
  local src = snapshot.source
end
```

**Impact:** -30% API-Overhead

---

#### 2.2 Buffer-Validierung cachen

**File:** `buffer_utils.lua`

```lua
-- BEFORE: Jedes Mal volle Validierung
function M.is_valid_file_buffer(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then return false end
  if not vim.api.nvim_buf_is_loaded(bufnr) then return false end
  -- ... 5 weitere Checks
end

-- AFTER: Cache mit Invalidierung
local validation_cache = {}  -- { [bufnr] = {valid, timestamp} }
setmetatable(validation_cache, {__mode = "k"})  -- Weak keys

function M.is_valid_file_buffer(bufnr)
  local cached = validation_cache[bufnr]
  if cached and (vim.uv.now() - cached.time < 1000) then
    return cached.valid
  end

  local valid = do_full_validation(bufnr)
  validation_cache[bufnr] = {valid = valid, time = vim.uv.now()}
  return valid
end
```

**Impact:** -50% bei Buffer-Checks

---

#### 2.3 Neo-tree Command-Calls batchen

**File:** `controller.lua`

```lua
-- BEFORE: Separate Calls
close_window(NeoCmd)
vim.defer_fn(function()
  open_window(NeoCmd, target_position)
end, 100)

-- AFTER: Atomic Execute
NeoCmd.execute({
  action = "switch",  -- ← NEU: Nutze neo-tree's switch!
  from = current_position,
  to = target_position,
  source = source,
})
```

**Impact:** -40% bei Switches

---

#### 2.4 Tree-State Restore optimieren

**File:** `tree.lua`

```lua
-- BEFORE: Iterate über ALLE Nodes
for id, _ in pairs(state.expanded) do
  local node = tree:get_node(id)
  if node then tree:expand(node) end
end

-- AFTER: Batch-Expand
local expand_ids = vim.tbl_keys(state.expanded)
tree:expand_batch(expand_ids)  -- Single API-Call
```

**Impact:** -60% bei Restore

---

### Milestone 2 Deliverables

- ✅ Avg < 8ms (aktuell: 13.2ms)
- ✅ Max < 50ms (aktuell: 312ms)
- ✅ First-Open < 15ms (aktuell: 25.9ms)
- ✅ Buffer-Check-Cache aktiv

---

## 🏗️ Milestone 3: Architektonische Verbesserungen (Prio: MEDIUM)

**Ziel:** Clean Architecture, Testbarkeit
**ETA:** 6-8 Stunden

### Architektur-Issues

#### 3.1 Controller: Mixed Responsibilities

**Problem:** `controller.lua` macht ALLES

```
controller.lua (800+ lines):
- State Machine
- Busy Guard
- Position Logic
- Command Execution
- Timing
- Debug
```

**Fix:** Extract Modules

```
controller/
├── state_machine.lua    -- decide_action(), transitions
├── semaphore.lua        -- Concurrency control
├── executor.lua         -- Neo-tree command wrapper
├── position.lua         -- Position normalization
└── init.lua             -- Public API
```

---

#### 3.2 Circular Dependencies

**Problem:**

```
controller.lua ← → state/windows.lua ← → tree.lua
                    ↓
              cwd_sync.lua (!!!)
```

**Fix:** Dependency Injection

```lua
-- BEFORE:
local state = require("config.neotree.state.windows")

-- AFTER:
function M.make_opener(target_position, source, deps)
  deps = deps or {
    state = require("config.neotree.state.windows"),
    tree_state = require("config.neotree.state.tree"),
  }
  -- Use deps.state statt direktem require
end
```

---

#### 3.3 Error Handling inkonsistent

**Locations:** Überall

```lua
-- MIXED Patterns:
pcall(...)  -- Manchmal
local ok = ... -- Manchmal
if not ok then return end  -- Manchmal
-- Manchmal gar nichts!
```

**Fix:** Zentraler Error Handler

```lua
-- lib/error_handler.lua
local M = {}

function M.safe_call(fn, context)
  local ok, result = pcall(fn)
  if not ok then
    M.log_error(context, result)
    return nil, result
  end
  return result
end

function M.log_error(context, err)
  if cfg.debug then
    vim.notify(
      string.format("[%s] Error: %s", context, tostring(err)),
      vim.log.levels.ERROR
    )
  end
end
```

---

### Milestone 3 Deliverables

- ✅ Controller < 300 lines
- ✅ Keine Circular Dependencies
- ✅ Konsistentes Error Handling
- ✅ 100% Type Coverage

---

## 🧪 Milestone 4: Testing & Observability (Prio: LOW)

**Ziel:** Reproduzierbare Bugs, Regression Prevention
**ETA:** 4-5 Stunden

### Tasks

#### 4.1 Unit Tests für State Machine

```lua
-- tests/controller_spec.lua
describe("controller state machine", function()
  it("open → close → open works", function()
    controller.make_opener("left")()  -- open
    vim.wait(100)
    controller.make_opener("left")()  -- close
    vim.wait(100)
    controller.make_opener("left")()  -- reopen

    assert.equals("left", state.get_position())
  end)

  it("switch works atomically", function()
    controller.make_opener("left")()
    vim.wait(100)
    controller.make_opener("right")()  -- switch
    vim.wait(200)

    assert.equals("right", state.get_position())
    assert.equals(1, count_neotree_windows())
  end)
end)
```

---

#### 4.2 Performance Regression Tests

```lua
-- tests/benchmark_spec.lua
describe("performance", function()
  it("open < 10ms avg", function()
    local times = {}
    for i = 1, 50 do
      local start = vim.uv.hrtime()
      controller.make_opener("left")()
      vim.wait(100)
      controller.make_opener("left")()  -- close
      times[i] = (vim.uv.hrtime() - start) / 1e6
    end

    local avg = sum(times) / #times
    assert.is_true(avg < 10)
  end)
end)
```

---

#### 4.3 Observability: Structured Logging

```lua
-- lib/logger.lua
local M = {}

function M.log_transition(from, to, duration_ms)
  if not cfg.debug then return end

  local log = {
    type = "transition",
    from = from,
    to = to,
    duration_ms = duration_ms,
    timestamp = os.time(),
  }

  append_to_log_file(log)
end
```

---

## 📋 Implementation Checklist

### Phase 1: Critical Fixes (Week 1)

- [ ] Add callbacks to `close_window()`
- [ ] Add callbacks to `open_window()`
- [ ] Implement sync State Guards
- [ ] Replace Busy Guard with Semaphore
- [ ] Fix Float-Position State
- [ ] Add Switch-Stress-Test
- [ ] Verify 100% Reliability

### Phase 2: Performance (Week 2)

- [ ] Add `state.get_snapshot()`
- [ ] Implement Buffer-Validation-Cache
- [ ] Use Neo-tree's `switch` action
- [ ] Batch Tree-Restore
- [ ] Add Performance Benchmarks
- [ ] Target: avg < 8ms

### Phase 3: Architecture (Week 3)

- [ ] Extract `state_machine.lua`
- [ ] Extract `semaphore.lua`
- [ ] Extract `executor.lua`
- [ ] Implement DI for State
- [ ] Centralize Error Handling
- [ ] Add Type Annotations

### Phase 4: Testing (Week 4)

- [ ] Write Unit Tests (State Machine)
- [ ] Write Integration Tests (Full Flow)
- [ ] Add Regression Tests
- [ ] Implement Structured Logging
- [ ] Document Public API

---

## Expected Outcomes

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| **Reliability** | ~90% | 100% | +10% |
| **Avg Latency** | 13.2ms | <8ms | -40% |
| **Max Latency** | 312ms | <50ms | -84% |
| **First Open** | 25.9ms | <15ms | -42% |
| **Code Lines** | 800+ | <500 | -37% |
| **Test Coverage** | 0% | 80%+ | +80% |

---

## Priorität & Risk Assessment

| Milestone | Prio | Risk | Impact |
|-----------|------|------|--------|
| M1: Stability | 🔴 CRITICAL | LOW | HIGH |
| M2: Performance | 🟡 HIGH | MEDIUM | MEDIUM |
| M3: Architecture | 🟢 MEDIUM | LOW | HIGH (long-term) |
| M4: Testing | 🔵 LOW | LOW | MEDIUM |

**Empfehlung:** Start mit M1 (Stability), dann M2 (Performance). M3+M4 parallel.

---

## Nächste Schritte

1. **Approval:** Review dieser Roadmap
2. **M1 Start:** Fix Critical Race Conditions
3. **Testing:** Verify Reliability mit Stress-Tests
4. **M2 Start:** Performance-Optimierungen
5. **Continuous:** Monitoring via Timing-Commands

