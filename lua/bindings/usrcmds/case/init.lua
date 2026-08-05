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

--- Shared by every filter-shaped route (`:Cases <field>`, `:Cases find`,
--- `:Cases grep`): `--exact`/`-e` narrows substring to full-string equality,
--- `--re`/`-r` switches to a (case-sensitive) Lua pattern — see
--- query.lua's `matches()` for why the two can't both fold case the same way.
local MATCH_FLAGS = {
  { name = "exact", short = "e", bool = true },
  { name = "re", short = "r", bool = true },
}

--- One `:Cases <field> [pattern] [--exact|-e] [--re|-r]` per
--- config.infocard_fields entry — substring, case-insensitive by default;
--- empty pattern means "field is set at all".
---@return Lib.UserCmd.Composer.RouteSpec[]
local function filter_routes()
  local routes = {}
  for _, field in ipairs(config.infocard_fields) do
    routes[#routes + 1] = {
      path = { field },
      args = { { name = "pattern", type = "STRING", optional = true } },
      flags = MATCH_FLAGS,
      desc = ("Filter cases by %s"):format(field),
      run = function(ctx)
        ui.filter(field, ctx.args.pattern, ctx.flags)
      end,
    }
  end
  return routes
end

--- `:Cases find company=Scan year=2026 [--exact|-e] [--re|-r]` —
--- AND-combination across several fields at once, via composer's `kv`
--- grammar (bare `key=value`, no dashes). Every `config.infocard_fields`
--- entry is a possible key; `ctx.kv` only carries the ones actually passed.
---@return Lib.UserCmd.Composer.RouteSpec
local function find_route()
  local kv_specs = {}
  for _, field in ipairs(config.infocard_fields) do
    kv_specs[#kv_specs + 1] = { key = field, type = "STRING" }
  end
  return {
    path = { "find" },
    kv = kv_specs,
    flags = MATCH_FLAGS,
    desc = "Filter cases by multiple fields at once (field=pattern field=pattern ...)",
    run = function(ctx)
      ui.filter_many(ctx.kv, ctx.flags)
    end,
  }
end

--- `:Cases grep <pattern> [--re|-r]` — full-text search over every case's
--- markdown files.
---@return Lib.UserCmd.Composer.RouteSpec
local function grep_route()
  return {
    path = { "grep" },
    args = { { name = "pattern", type = "STRING" } },
    flags = { { name = "re", short = "r", bool = true } },
    desc = "Full-text search across every case's markdown files",
    run = function(ctx)
      ui.grep(ctx.args.pattern, ctx.flags)
    end,
  }
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
      args = {
        { name = "name", type = "STRING" },
        { name = "suffix", type = "STRING", optional = true },
      },
      desc = "Add a markdown file ('reply [suffix]' auto-numbers, e.g. :Case add reply AskForPDF)",
      run = function(ctx)
        ui.add(ctx.args.name, ctx.args.suffix, nil)
      end,
    },
    {
      path = { "activity" },
      args = { { name = "case", type = "CASE", optional = true } },
      desc = "Paste the clipboard (a SNOW Activity Stream) into a new Research/ file",
      run = function(ctx)
        ui.activity(ctx.args.case)
      end,
    },
    {
      path = { "similar" },
      args = {
        { name = "case", type = "CASE", optional = true },
        { name = "n", type = "STRING", optional = true },
      },
      desc = "Past cases with similar title/Summary wording (TF-IDF, no AI)",
      run = function(ctx)
        ui.similar(ctx.args.case, ctx.args.n)
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
    {
      path = { "recent" },
      args = { { name = "n", type = "STRING", optional = true } },
      desc = "Most recently touched cases first",
      run = function(ctx)
        ui.recent(ctx.args.n)
      end,
    },
    {
      path = { "stats" },
      desc = "Counts by state / company / year",
      run = function()
        ui.stats()
      end,
    },
    {
      path = { "stale" },
      args = { { name = "days", type = "STRING", optional = true } },
      desc = "Open cases untouched for at least N days (default 7)",
      run = function(ctx)
        ui.stale(ctx.args.days)
      end,
    },
    {
      path = { "doctor" },
      desc = "Report bestand naming inconsistencies (read-only)",
      run = function()
        ui.doctor()
      end,
    },
    {
      path = { "normalize" },
      desc = "Fix bestand naming inconsistencies found by doctor (dry-run + confirm)",
      run = function()
        ui.normalize()
      end,
    },
    find_route(),
    grep_route(),
    {
      path = { "linkcheck" },
      args = { { name = "case", type = "CASE", optional = true } },
      desc = "Check docs.tricentis.com links for dead pages (optionally one case)",
      run = function(ctx)
        ui.linkcheck(ctx.args.case)
      end,
    },
    {
      path = { "pickers" },
      desc = "Discovery menu: attachments, links, cases without .case.json",
      run = function()
        ui.pickers()
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
