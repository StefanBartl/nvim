---@module 'bindings.usrcmds.execute'
---@brief `:Execute` -- run the text you point at (a selection, a `code` span, a fenced block, a line).
---@description
--- Text in a buffer is often a command: a note that says `` `:set wrap` ``, a README block with
--- `git status`, a line of Lua. `:Execute` takes that text, works out what it is and runs it, shows it in
--- the command line first, or copies it.
---
---   :Execute [how] [--from=<where>] [--as=<kind>] [--yes]       (with a range: the selected text)
---   :Execute! [how] ...                                         (the bang runs it at once)
---
--- `how` (what happens, `<Tab>` completes it; default `cmdline`, with a bang `run`):
---
---   cmdline    type it into the command line, do not run it: edit it, press <CR>
---   run        run it, show the output as a message
---   split | vsplit | tab | float    run it, show the output in a scratch buffer / floating window
---   clipboard  copy the command text, do not run it
---   result     run it, copy the output to the + register
---
--- `--from` (the text): `auto` (the default: selection, else the `code` span under the cursor, else the
--- fenced block, else the line), `selection`, `backtick`, `line`, `fence`, `clipboard`.
---
--- `--as` (the kind): `auto` (the default), `ex`, `lua`, `shell`. `auto` reads the fence language or the first
--- character: `!cmd` and `$ cmd` are shell, `:cmd` is Ex, the rest is Ex.
---
--- Shell commands, an Ex shell filter (`:r !`, `:%!`, `:terminal`) and Lua that names a shell entry point
--- ask `[R]un / [C]ancel` before they run; `--yes` skips the question. `cmdline` and `clipboard` never run
--- anything.
---
--- Mappings (`bindings.mappings.execute`): `<leader>x` is `:Execute`, `<leader>X` is `:Execute!`, in Normal and
--- Visual mode.
---
--- Key responsibilities:
---  - `execute`: the whole flow for one invocation (`source` -> `kind` -> `sink`), callable from Lua
---  - `enable`: registers the `:Execute` verb with the composer from lib.nvim
---
--- Not its job: finding the text (`execute.source`), classifying it (`execute.kind`), running it and
--- showing the result (`execute.sink`).

local composer = require("lib.nvim.bindings.usercmd.composer")
local notify = require("lib.nvim.notify").create("[Execute]")

local kind = require("bindings.usrcmds.execute.kind")
local sink = require("bindings.usrcmds.execute.sink")
local source = require("bindings.usrcmds.execute.source")

local M = {}

---One invocation.
---@class Execute.Opts
---@field how? Execute.How     default: "cmdline", or "run" with `bang`
---@field from? Execute.From   default "auto"
---@field as? Execute.As       default "auto"
---@field bang? boolean        `:Execute!`
---@field yes? boolean         skip the question before a risky plan
---@field range? Execute.Range `ctx.range` of the command

---Ask before a plan that reaches outside the editor runs. A seam: specs replace it.
---@param plan Execute.Plan
---@return boolean run
function M.confirm(plan)
  local msg = "This leaves the editor. Run it?\n\n" .. plan.display
  return vim.fn.confirm(msg, "&Run\n&Cancel", 2) == 1
end

---What `how` is when the user did not name one.
---@param bang boolean|nil
---@return Execute.How
function M.default_how(bang)
  return bang and "run" or "cmdline"
end

---Do what one `:Execute` asks for.
---@param opts? Execute.Opts
---@return nil
function M.execute(opts)
  opts = opts or {}
  local src, serr = source.get({ from = opts.from, range = opts.range })
  if not src then
    notify.warn(serr or "nothing to execute")
    return
  end
  local plan, perr = kind.build(src.lines, opts.as, src.lang)
  if not plan then
    notify.warn(perr or "nothing to execute")
    return
  end
  local how = opts.how or M.default_how(opts.bang)

  if how == "cmdline" then
    local text, terr = kind.cmdline_text(plan)
    if not text then
      notify.warn(terr or "cannot put it into the command line")
      return
    end
    sink.to_cmdline(text)
    return
  end
  if how == "clipboard" then
    sink.copy_command(plan)
    return
  end

  if plan.risky and not opts.yes and not M.confirm(plan) then
    notify.info("Cancelled")
    return
  end
  sink.run(plan, function(res)
    sink.deliver(how, res, plan)
  end)
end

---Register `:Execute` and `:Execute!`. Safe to call twice.
---@return nil
function M.enable()
  composer.verb("Execute", {
    desc = "Run the text under the cursor / in the selection: an `inline code` span, a fenced block or a line",
    routes = {
      {
        path = {},
        bang = true,
        range = true,
        desc = "Run Ex, Lua or shell text from the buffer; without a bang it is typed into the command line first",
        args = {
          {
            name = "how",
            type = "STRING",
            optional = true,
            enum = sink.HOW,
            enum_desc = sink.HOW_DESC,
            desc = "What happens with it (default: cmdline; with a bang: run)",
          },
        },
        flags = {
          {
            name = "from",
            type = "STRING",
            enum = source.FROM,
            enum_desc = source.FROM_DESC,
            desc = "Where the text comes from (default: auto)",
          },
          {
            name = "as",
            type = "STRING",
            enum = kind.AS,
            enum_desc = kind.AS_DESC,
            desc = "What the text is (default: auto)",
          },
          {
            name = "yes",
            bool = true,
            desc = "Do not ask before a shell command or another plan that leaves the editor",
          },
        },
        run = function(ctx)
          M.execute({
            how = ctx.args.how,
            from = ctx.flags.from,
            as = ctx.flags.as,
            yes = ctx.flags.yes,
            bang = ctx.bang,
            range = ctx.range,
          })
        end,
      },
    },
  })
end

return M
