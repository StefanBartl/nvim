# lib/tables README

| Name             | Module                | Signature                                             | Description                                              |
| ---------------- | --------------------- | ----------------------------------------------------- | -------------------------------------------------------- |
| is_table         | lib.tables.core       | is_table(t: any): boolean                             | Test for table.                                          |
| is_array         | lib.tables.core       | is_array(t: table): boolean                           | Heuristic: 1..#t are present; rejects extra sparse keys. |
| shallow_copy     | lib.tables.core       | shallow_copy(t: T): T                                 | One-level copy.                                          |
| deep_copy        | lib.tables.core       | deep_copy(t: T): T                                    | Deep copy with cycle handling.                           |
| keys             | lib.tables.core       | keys(t: table): string[]                              | Collect string keys.                                     |
| values           | lib.tables.core       | values(t: table): any[]                               | Collect values.                                          |
| invert_set       | lib.tables.core       | invert_set(list: string[]): table<string,true>        | Build membership set from list.                          |
| pick             | lib.tables.core       | pick(t: table, pick_keys: string[]): table            | New table with only given keys.                          |
| omit             | lib.tables.core       | omit(t: table, omit_keys: string[]): table            | New table without given keys.                            |
| merge_shallow    | lib.tables.core       | merge_shallow(dst: table, src: table): table          | Overwrite keys from src into dst.                        |
| merge_deep       | lib.tables.core       | merge_deep(dst: table, src: table): table             | Recursive merge of nested tables.                        |
| dedup_list       | lib.tables.core       | dedup_list(list: any[]): any[]                        | Remove duplicates preserving order.                      |
| slice            | lib.tables.core       | slice(list: T[], i: integer, j?: integer): T[]        | Python-like slicing with negative indices.               |
| unique_push      | lib.tables.core       | unique_push(list: T[], v: T): boolean                 | Push only if not already present.                        |
| binary_search    | lib.tables.core       | binary_search(list: T[], cmp, x: T): integer, boolean | Lower-bound index and found flag.                        |
| group_by         | lib.tables.core       | group_by(list: T[], key: fun(T):K): table<K,T[]>      | Group items by derived key.                              |
| partition        | lib.tables.core       | partition(list: T[], pred): T[], T[]                  | Split list into pass/fail by predicate.                  |
| count_by         | lib.tables.core       | count_by(list: T[], key): table<K,integer>            | Frequency map by derived key.                            |
| map              | lib.tables.functional | map(list: T[], fn): U[]                               | Transform each element.                                  |
| filter           | lib.tables.functional | filter(list: T[], pred): T[]                          | Keep elements passing pred.                              |
| reduce           | lib.tables.functional | reduce(list: T[], init: U, fn): U                     | Fold left over list.                                     |
| find             | lib.tables.functional | find(list: T[], pred): T|nil                          | First element passing pred.                              |
| any              | lib.tables.functional | any(list: T[], pred): boolean                         | True if any element passes pred.                         |
| all              | lib.tables.functional | all(list: T[], pred): boolean                         | True if all elements pass pred.                          |
| flat_map         | lib.tables.functional | flat_map(list: T[], fn: fun(T):U): U[]                | Map then flatten one level.                              |
| ensure_list      | lib.tables.safe       | ensure_list(list?: T[]): T[]                          | Return list or empty table.                              |
| ensure_table     | lib.tables.safe       | ensure_table(t?: table): table                        | Return table or empty table.                             |
| push             | lib.tables.safe       | push(list: any[], v: any): integer                    | Append and return new length.                            |
| pop              | lib.tables.safe       | pop(list: any[]): any|nil                             | Pop last element if present.                             |
| insert_at        | lib.tables.safe       | insert_at(list: any[], idx: integer, v: any): boolean | Insert at 1-based index.                                 |
| remove_at        | lib.tables.safe       | remove_at(list: any[], idx: integer): boolean         | Remove at 1-based index.                                 |
| snapshot_shallow | lib.tables.safe       | snapshot_shallow(t: table): table                     | Shallow snapshot (copy) for iteration.                   |
| safe_ipairs      | lib.tables.safe       | safe_ipairs(list: T[]): iterator                      | Snapshot length and iterate 1..#list safely.             |

## Usage

```lua
local T  = require("lib.tables.core")
local Fn = require("lib.tables.functional")
local Sf = require("lib.tables.safe")

-- Merging settings with defaults
local defaults = { a = 1, nested = { x = 1, y = 2 } }
local user     = { a = 3, nested = { y = 9 } }
local cfg = T.deep_copy(defaults)
T.merge_deep(cfg, user)
-- cfg = { a = 3, nested = { x = 1, y = 9 } }

-- Grouping and counting
local people = {
  { name = "Ada", team = "red" },
  { name = "Bob", team = "blue" },
  { name = "Eve", team = "red" },
}
local by_team = T.group_by(people, function(p) return p.team end)
-- by_team.red -> { Ada, Eve }

local counts = T.count_by(people, function(p) return p.team end)
-- counts = { red = 2, blue = 1 }

-- Functional transforms
local names = Fn.map(people, function(p) return p.name end)              -- {"Ada","Bob","Eve"}
local reds  = Fn.filter(people, function(p) return p.team == "red" end)  -- only red team
local any_red = Fn.any(people, function(p) return p.team == "red" end)   -- true

-- Slicing and unique push
local list = { "a", "b", "b", "c" }
local uniq = T.dedup_list(list)            -- {"a","b","c"}
local mid  = T.slice(list, 2, -1)          -- {"b","b","c"}
T.unique_push(list, "c")                   -- false (already present)

-- Safe mutations under iteration
local snapshot = Sf.snapshot_shallow(by_team)
for k, v in pairs(snapshot) do
  -- mutate by_team safely while iterating snapshot
end

-- Binary search over sorted arrays
local sorted = { 2, 4, 6, 8 }
local idx, found = T.binary_search(sorted, function(a, b) return a < b end, 5)
-- idx = 3 (insert position), found = false
```

## Design notes

* Functional helpers return new arrays; they never mutate the input.
* Core merge functions mutate the destination on purpose for performance; deep_copy first if you need persistence.
* safe_ipairs snapshots the length to avoid missing or duplicate elements when the list is mutated during iteration.
* binary_search uses a comparator consistent with the array’s ordering; the returned index is suitable for ordered insertion.
* slice accepts negative indices relative to the end (Python-like); out-of-range indices are clamped.

---
