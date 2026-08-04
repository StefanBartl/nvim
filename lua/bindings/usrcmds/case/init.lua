---@module 'bindings.usrcmds.case'
--- :Case — SAP-Support case scaffolding. Concept: docs/ROADMAP/casedesk/CONCEPT.md
---
--- Registers the CASE argument type (validates + <Tab>-completes against the
--- on-disk registry, normalizing a pasted full SNOW id down to the short
--- number) and one composer verb with a route per workflow step, plus a
--- generated file-verb (:Case summary/research/reply [case]) per blueprint
--- node that declares a `key`.

local composer = require("lib.nvim.usercmd.composer")
local render = require("bindings.usrcmds.case.render")
local registry = require("bindings.usrcmds.case.registry")
local config = require("bindings.usrcmds.case.config")
local blueprint = require("bindings.usrcmds.case.blueprint")
local ui = require("bindings.usrcmds.case.ui")

local M = {}

local function register_case_type()
  composer.register_type("CASE", {
    validate = function(raw)
      local short = render.to_short(raw)
      if not registry.exists(short) then
        return false, nil, ("unknown case: %s"):format(raw)
      end
      return true, short, nil
    end,
    complete = function(arg_lead)
      return registry.complete(render.to_short(arg_lead))
    end,
  })
end

---@return Lib.UserCmd.Composer.RouteSpec[]
local function file_verb_routes()
  local routes = {}
  for _, node in ipairs(blueprint.all_keyed_nodes()) do
    routes[#routes + 1] = {
      path = { node.key },
      args = { { name = "case", type = "CASE", optional = true } },
      desc = ("Open %s of the case"):format(node.path),
      run = function(ctx)
        ui.open_node(node, ctx.args.case)
      end,
    }
  end
  return routes
end

--- One `:Case <verb> [case]` per non-default state (config.states), moving
--- the case into that state — `:Case close`, `:Case reassign`, and whatever
--- a future fourth state adds, all from the same loop. `config.state_verbs`
--- names the imperative command; a state without an entry there falls back
--- to its own lowercased name.
---@return Lib.UserCmd.Composer.RouteSpec[]
local function state_verb_routes()
  local routes = {}
  for _, state in ipairs(config.states) do
    if state ~= config.default_state then
      local verb = config.state_verbs[state] or state:lower()
      routes[#routes + 1] = {
        path = { verb },
        args = { { name = "case", type = "CASE", optional = true } },
        desc = ("Move the case to %s"):format(state),
        run = function(ctx)
          ui.move_state(ctx.args.case, state)
        end,
      }
    end
  end
  return routes
end

--- One `:Cases <field> [pattern]` per config.infocard_fields entry —
--- substring, case-insensitive; empty pattern means "field is set at all".
---@return Lib.UserCmd.Composer.RouteSpec[]
local function filter_routes()
  local routes = {}
  for _, field in ipairs(config.infocard_fields) do
    routes[#routes + 1] = {
      path = { field },
      args = { { name = "pattern", type = "STRING", optional = true } },
      desc = ("Filter cases by %s"):format(field),
      run = function(ctx)
        ui.filter(field, ctx.args.pattern)
      end,
    }
  end
  return routes
end

function M.enable()
  register_case_type()

  local routes = {
    {
      path = { "new" },
      args = { { name = "case", type = "STRING", optional = true } },
      desc = "Scaffold a new case (prompts for missing fields)",
      run = function(ctx)
        ui.new(ctx.args.case)
      end,
    },
    {
      path = { "info" },
      args = { { name = "case", type = "CASE", optional = true } },
      desc = "Short infocard for a case (e edit, o open folder, s summary)",
      run = function(ctx)
        ui.info(ctx.args.case)
      end,
    },
    {
      path = { "open" },
      args = { { name = "case", type = "CASE", optional = true } },
      desc = "Open a case's folder",
      run = function(ctx)
        ui.open_dir(ctx.args.case)
      end,
    },
    {
      path = { "add" },
      args = { { name = "name", type = "STRING" } },
      desc = "Add a markdown file to the current case ('reply' auto-numbers)",
      run = function(ctx)
        ui.add(ctx.args.name, nil)
      end,
    },
    {
      path = { "copy" },
      args = { { name = "src", type = "PATH", optional = true } },
      desc = "Copy a file into the current case",
      run = function(ctx)
        ui.copy(ctx.args.src, nil)
      end,
    },
    {
      path = { "sync" },
      args = { { name = "case", type = "CASE", optional = true } },
      desc = "Add missing blueprint pieces to an existing case",
      run = function(ctx)
        ui.sync(ctx.args.case)
      end,
    },
    {
      path = { "snow" },
      args = { { name = "case", type = "CASE", optional = true } },
      desc = "Open (or copy) the case's ServiceNow ticket id",
      run = function(ctx)
        ui.snow(ctx.args.case)
      end,
    },
  }

  vim.list_extend(routes, file_verb_routes())
  vim.list_extend(routes, state_verb_routes())

  composer.verb("Case", {
    desc = "SAP Support case scaffolding",
    default = function(ctx)
      ui.info(nil)
    end,
    routes = routes,
  })

  local cases_routes = {
    {
      path = { "list" },
      desc = "List every case, grouped by state",
      run = function()
        ui.list_all()
      end,
    },
  }
  vim.list_extend(cases_routes, filter_routes())

  composer.verb("Cases", {
    desc = "Cross-case queries (field filters, listing)",
    default = function()
      ui.list_all()
    end,
    routes = cases_routes,
  })
end

return M
