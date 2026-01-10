# FIX: bugs

## Table of content

  - [Important Bugs](#important-bugs)
    - [LSP](#lsp)
  - [neotree-fs-refactor](#neotree-fs-refactor)

---

## Critical Bugs

- github stats

---

## Important

1. `config.neotree.keymaps.filetree`: FIX debuggen
2. In `leader fc` froß un dkleinscheribung deaktivieren. Soll wie in live grep funktieren, nur mit files.
3. comment funktion bugged, wenn ich

```lua
  ["<CR>"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      -- 1) Safely get the current node
      local node = state.current_node
      if not node then
        return
      end

      -- 2) Check if we're in a valid Neo-tree window
      local current_win = vim.api.nvim_get_current_win()
      local buf = vim.api.nvim_win_get_buf(current_win)
      local is_neotree_win = vim.bo[buf].filetype == "neo-tree"
      if not is_neotree_win then
        vim.notify("Neo-tree: Not in a Neo-tree window", vim.log.levels.WARN)
        return
      end

      -- 3) Clean up any safe preview (if open)
      safe_hide_preview(state)

      -- 4) Expand/collapse directories safely
      -- If the node is a directory or has children and is collapsed, toggle it
      if node.type == "directory" or (node.has_children and not node.is_expanded) then
        state.commands.toggle_node(state)
        return
      end

      -- 5) Normal open: prefer window-picker if present
      if pcall(require, "window-picker") then
        local ok = pcall(state.commands.open_with_window_picker, state)
        if not ok then
          pcall(state.commands.open, state)
        end
      else
        pcall(state.commands.open, state)
      end
    end,
    desc = "Safe expand / collapse nodes and open files",
  },
```

mit multiline kommentiere, bekomme ich:

```lua
  -- ["<CR>"] = {
    -- ---@param state Cfg.NeoTree.State
    -- function(state)
      1) Safely get the current node
      -- local node = state.current_node
      -- if not node then
        -- return
      -- end

      2) Check if we're in a valid Neo-tree window
      -- local current_win = vim.api.nvim_get_current_win()
      -- local buf = vim.api.nvim_win_get_buf(current_win)
      -- local is_neotree_win = vim.bo[buf].filetype == "neo-tree"
      -- if not is_neotree_win then
        -- vim.notify("Neo-tree: Not in a Neo-tree window", vim.log.levels.WARN)
        -- return
      -- end

      3) Clean up any safe preview (if open)
      -- safe_hide_preview(state)

      4) Expand/collapse directories safely
      If the node is a directory or has children and is collapsed, toggle it
      -- if node.type == "directory" or (node.has_children and not node.is_expanded) then
        -- state.commands.toggle_node(state)
        -- return
      -- end

      5) Normal open: prefer window-picker if present
      -- if pcall(require, "window-picker") then
        -- local ok = pcall(state.commands.open_with_window_picker, state)
        -- if not ok then
          -- pcall(state.commands.open, state)
        -- end
      -- else
        -- pcall(state.commands.open, state)
      -- end
    -- end,
    -- desc = "Safe expand / collapse nodes and open files",
  -- },
```

--> daher die kommentare werden wieder auskoemmtniert, was natürlich nicht korrekt ist

---

## Normal

---

## Normal Bugs

---


## Long View

---

## Notes

### Legende

Severity:
* CRITICAL – blockiert Editor oder führt zu Datenverlust
* IMPORTANT – stark störend, aber mit Workaround
* NORMAL – reproduzierbar, aber begrenzt
* LOW – kosmetisch oder selten

Status:
* OPEN – bekannt, ungelöst
* WIP – Analyse oder Fix in Arbeit
* AUDIT: Fix angewendet, in Beobachtung
* FIXED – gelöst, wartet auf Cleanup
* WONTFIX – bewusst nicht gelöst
* UPSTREAM – Bug liegt in externem Plugin

---

###  __TITEL__ (Template)

Modul:
Kurzbeschreibung:
Status:
Reproduzierbar:
Plattform:
Detaildokument:
Fehlermeldung?:

```vim

```

---

## Long view

---


## Notes

###  __TITEL__ (Template)

Modul:
Kurzbeschreibung:
Status:
Reproduzierbar:
Plattform:
Detaildokument:
Fehlermeldung?:

```vim

```

---

### Legende

Severity:
* CRITICAL – blockiert Editor oder führt zu Datenverlust
* IMPORTANT – stark störend, aber mit Workaround
* NORMAL – reproduzierbar, aber begrenzt
* LOW – kosmetisch oder selten

Status:
* OPEN – bekannt, ungelöst
* WIP – Analyse oder Fix in Arbeit
* AUDIT: Fix angewendet, in Beobachtung
* FIXED – gelöst, wartet auf Cleanup
* WONTFIX – bewusst nicht gelöst
* UPSTREAM – Bug liegt in externem Plugin

---

