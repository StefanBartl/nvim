---@module 'config.harpoon.usrcmds'
---@brief User command registration: one unified `:Harpoon` verb (built with
--- lib.nvim.bindings.usercmd.composer) plus the flat convenience aliases.
---
--- Unified command:
---   :Harpoon                              open the quick menu (bare form)
---   :Harpoon menu [default|telescope|fzf] open a list UI
---   :Harpoon add [path] [--front] [--permanent]
---                                         add a file (default: current buffer)
---   :Harpoon remove [path]                drop a file from the live list
---   :Harpoon pin [path] [--front]         add + keep as persistent default
---   :Harpoon unpin [path]                 stop treating a file as a default
---   :Harpoon defaults sync                add back any missing default path
---   :Harpoon defaults reset               rebuild the list from the defaults
---   :Harpoon select <n>                   jump to entry n
---   :Harpoon preview <n>                  full-screen preview of entry n
---   :Harpoon debug                        dump the current list
---   :Harpoon health                       run the health check
---
--- Flat aliases kept alongside (same "keep alongside" call as gopath.nvim's
--- compat layer — the two Add* commands are the primary spelling the keymaps
--- and docs use, the rest exist because they predate the verb):
---   :HarpoonAddToList [path]        = :Harpoon add [path] --front
---   :HarpoonAddToListPermanent [p]  = :Harpoon add [path] --front --permanent
---   :HarpoonPin  :HarpoonUnpin  :HarpoonPersistPaths  :HarpoonSetDefaultPaths
---   :HarpoonDebug  :CheckHealthHarpoon

local M = {}

local composer = require("lib.nvim.bindings.usercmd.composer")
local usercmd = require("lib.nvim.bindings.usercmd")
local api = require("config.harpoon.api")

local MENU_KINDS = { "default", "telescope", "fzf" }

---`""` (no argument given) means "current buffer" everywhere below.
---@param s string|nil
---@return string|nil
local function arg_or_nil(s)
  return (type(s) == "string" and s ~= "") and s or nil
end

--------------------------------------------------------------------------------
-- Unified :Harpoon verb
--------------------------------------------------------------------------------

---@return nil
local function register_verb()
  composer.verb("Harpoon", {
    desc = "Harpoon: unified list command",
    default = function()
      api.menu("default")
    end,
    routes = {
      {
        path = { "menu" },
        args = { { name = "kind", type = "STRING", optional = true, enum = MENU_KINDS } },
        desc = "Open a Harpoon list UI (quick menu, telescope or fzf)",
        run = function(ctx)
          api.menu(ctx.args.kind)
        end,
      },

      {
        path = { "add" },
        args = { { name = "path", type = "FILE", optional = true } },
        flags = {
          { name = "front", short = "f", bool = true },
          { name = "permanent", short = "p", bool = true },
        },
        desc = "Add a file to the list (default: current buffer, appended)",
        run = function(ctx)
          api.add(ctx.args.path, {
            front = ctx.flags.front == true,
            permanent = ctx.flags.permanent == true,
          })
        end,
      },

      {
        path = { "remove" },
        args = { { name = "path", type = "PATH", optional = true } },
        desc = "Remove a file from the live list (default: current buffer)",
        run = function(ctx)
          api.remove(ctx.args.path)
        end,
      },

      {
        path = { "pin" },
        args = { { name = "path", type = "FILE", optional = true } },
        flags = { { name = "front", short = "f", bool = true } },
        desc = "Pin a file as a persistent Harpoon default",
        run = function(ctx)
          require("config.harpoon.persist_paths").pin(ctx.args.path, {
            front = ctx.flags.front == true,
          })
        end,
      },

      {
        path = { "unpin" },
        args = { { name = "path", type = "PATH", optional = true } },
        desc = "Remove a file from the persistent Harpoon defaults",
        run = function(ctx)
          api.unpin(ctx.args.path)
        end,
      },

      {
        path = { "defaults", "sync" },
        desc = "Add any missing default path (existing entries untouched)",
        run = api.defaults_sync,
      },

      {
        path = { "defaults", "reset" },
        desc = "Rebuild the list from the default paths, in that exact order",
        run = api.defaults_reset,
      },

      {
        path = { "select" },
        args = { { name = "index", type = "INT" } },
        desc = "Jump to list entry <index>",
        run = function(ctx)
          api.select(ctx.args.index)
        end,
      },

      {
        path = { "preview" },
        args = { { name = "index", type = "INT" } },
        desc = "Full-screen preview of list entry <index> ('q' to close)",
        run = function(ctx)
          api.preview(ctx.args.index)
        end,
      },

      {
        path = { "debug" },
        desc = "Dump the current Harpoon list into a scratch buffer",
        run = api.debug,
      },

      {
        path = { "health" },
        desc = "Run the Harpoon health check",
        run = api.health,
      },
    },
  })
end

--------------------------------------------------------------------------------
-- Flat aliases
--------------------------------------------------------------------------------

---@return nil
local function register_aliases()
  usercmd.create("HarpoonAddToList", function(cmd)
    api.add(arg_or_nil(cmd.args), { front = true })
  end, {
    nargs = "?",
    complete = "file",
    desc = "Harpoon: add a file at the TOP of the list (alias for :Harpoon add --front)",
  })

  usercmd.create("HarpoonAddToListPermanent", function(cmd)
    api.add(arg_or_nil(cmd.args), { front = true, permanent = true })
  end, {
    nargs = "?",
    complete = "file",
    desc = "Harpoon: add a file at the TOP and keep it as a default (alias for :Harpoon add --front --permanent)",
  })

  usercmd.create("HarpoonPin", function(cmd)
    api.pin(arg_or_nil(cmd.args))
  end, {
    nargs = "?",
    complete = "file",
    desc = "Harpoon: pin a file as a persistent default (alias for :Harpoon pin)",
  })

  usercmd.create("HarpoonUnpin", function(cmd)
    api.unpin(arg_or_nil(cmd.args))
  end, {
    nargs = "?",
    complete = "file",
    desc = "Harpoon: drop a file from the persistent defaults (alias for :Harpoon unpin)",
  })

  usercmd.create("HarpoonPersistPaths", api.defaults_sync, {
    desc = "Harpoon: add any missing default path (alias for :Harpoon defaults sync)",
  })

  usercmd.create("HarpoonSetDefaultPaths", api.defaults_reset, {
    desc = "Harpoon: reset the list to the default paths (alias for :Harpoon defaults reset)",
  })

  usercmd.create("HarpoonDebug", api.debug, {
    desc = "Harpoon: dump the current list (alias for :Harpoon debug)",
  })

  usercmd.create("CheckHealthHarpoon", api.health, {
    desc = "Harpoon: run the health check (alias for :Harpoon health)",
  })
end

---@return nil
function M.setup()
  register_verb()
  register_aliases()
end

return M
