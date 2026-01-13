# Ziel

Einfache, reproduzierbare Testdateien für nvim-dap und nvim-dap-ui, jeweils mit typischen Fehlern, an denen man Breakpoints, Step-In/Over, Stacktraces, Variablen-Scopes und Fehlerkorrekturen testen kann.

---

## Table of content

- [Ziel](#ziel)
  - [Lua – Laufzeitfehler, Nil-Zugriff, Logikfehler](#lua-laufzeitfehler-nil-zugriff-logikfehler)
    - [Fehlerhafte Version: `lua_dap_test.lua`](#fehlerhafte-version-lua_dap_testlua)
    - [Was man debuggen kann](#was-man-debuggen-kann)
    - [Korrigierte Version (relevantste Änderungen)](#korrigierte-version-relevantste-nderungen)
  - [JavaScript (Node.js) – Asynchroner Fehler, falsche Annahmen](#javascript-nodejs-asynchroner-fehler-falsche-annahmen)
    - [Fehlerhafte Version: `js_dap_test.js`](#fehlerhafte-version-js_dap_testjs)
    - [Was man debuggen kann](#was-man-debuggen-kann-1)
    - [Korrigierte Version](#korrigierte-version)
  - [Go – Panic, falsche Fehlerbehandlung](#go-panic-falsche-fehlerbehandlung)
    - [Fehlerhafte Version: `go_dap_test.go`](#fehlerhafte-version-go_dap_testgo)
    - [Was man debuggen kann](#was-man-debuggen-kann-2)
    - [Korrigierte Version](#korrigierte-version-1)
  - [Empfohlene Debug-Szenarien in nvim-dap-ui](#empfohlene-debug-szenarien-in-nvim-dap-ui)
  - [Hinweise für Adapter](#hinweise-fr-adapter)

---

## Lua – Laufzeitfehler, Nil-Zugriff, Logikfehler

### Fehlerhafte Version: `lua_dap_test.lua`

```lua
---@module 'dap_test.lua'
--- Simple Lua program to test nvim-dap with runtime and logic errors.

-- =========================================
-- Intentional mistakes:
-- 1. Accessing a nil field
-- 2. Off-by-one error in loop
-- =========================================

---@class User
---@field name string
---@field age number

---@type User[]
local users = {
  { name = "Alice", age = 30 },
  { name = "Bob", age = 25 },
}

---@param list User[]
---@return number
local function average_age(list)
  local sum = 0

  -- Intentional off-by-one error: should be <= #list
  for i = 1, #list + 1 do
    -- Intentional nil access when i == #list + 1
    sum = sum + list[i].age
  end

  return sum / #list
end

local avg = average_age(users)

-- Intentional nil field access
print("Average age is: " .. avg.value)
```

### Was man debuggen kann

```
Breakpoint 1: inside average_age
- Beobachtung von i, list[i]
- Stacktrace beim nil-Zugriff
```

### Korrigierte Version (relevantste Änderungen)

```lua
for i = 1, #list do
  sum = sum + list[i].age
end

print("Average age is: " .. avg)
```

---

## JavaScript (Node.js) – Asynchroner Fehler, falsche Annahmen

### Fehlerhafte Version: `js_dap_test.js`

```javascript
/**
 * Simple Node.js script to test nvim-dap.
 * Intentional issues:
 * 1. Promise rejection not handled
 * 2. Type assumption error
 */

function fetchUser(id) {
  return new Promise((resolve, reject) => {
    if (id !== 1) {
      reject(new Error("User not found"));
    }
    resolve({ name: "Alice", age: 30 });
  });
}

async function main() {
  const user = await fetchUser(2);

  // Intentional logic error: assuming age is a string
  const nextYearAge = user.age + "1";

  console.log("Next year age:", nextYearAge);
}

main();
```

### Was man debuggen kann

```
Breakpoint:
- vor await fetchUser
- nach await (Promise rejection)
- Variable user (undefined)
```

### Korrigierte Version

```javascript
async function main() {
  try {
    const user = await fetchUser(1);

    const nextYearAge = user.age + 1;
    console.log("Next year age:", nextYearAge);
  } catch (err) {
    console.error("Error:", err.message);
  }
}
```

---

## Go – Panic, falsche Fehlerbehandlung

### Fehlerhafte Version: `go_dap_test.go`

```go
// Package main provides a simple Go program for dap testing.
package main

import "fmt"

// divide performs integer division.
// Intentional issue: division by zero panic.
func divide(a, b int) int {
	return a / b
}

func main() {
	values := []int{10, 5, 0}

	for i := 0; i <= len(values); i++ {
		result := divide(100, values[i])
		fmt.Println("Result:", result)
	}
}
```

### Was man debuggen kann

```
Breakpoint:
- divide()
- Loop condition (i, len(values))
- Panic: index out of range
- Panic: divide by zero
```

### Korrigierte Version

```go
func divide(a, b int) (int, error) {
	if b == 0 {
		return 0, fmt.Errorf("division by zero")
	}
	return a / b, nil
}

func main() {
	values := []int{10, 5, 0}

	for i := 0; i < len(values); i++ {
		result, err := divide(100, values[i])
		if err != nil {
			fmt.Println("Error:", err)
			continue
		}
		fmt.Println("Result:", result)
	}
}
```

---

## Empfohlene Debug-Szenarien in nvim-dap-ui

```
1. Breakpoint + Continue
2. Step Over (Logikfehler)
3. Step Into (Funktionsaufrufe)
4. Watch-Ausdrücke:
   - Lua: i, list[i], sum
   - JS: user, nextYearAge
   - Go: i, values[i], err
5. Call Stack & Scopes vergleichen vor/nach Fix
```

---

## Hinweise für Adapter

```
Lua:
- Adapter: local-lua-debugger / nlua
- Start via nvim --listen / dap.attach

JavaScript:
- Adapter: vscode-js-debug
- type: node
- request: launch

Go:
- Adapter: delve (dlv)
- request: launch
```

Wenn gewünscht, können im nächsten Schritt vollständige `dap.lua`-Konfigurationen inklusive `dapui.setup()` und Keymaps erstellt werden.

