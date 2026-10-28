-- TESTS/dialogs_spec.lua -- the questions of :MyPlugins, :MyNative and :Execute ask through lib.nvim.ui.dialog: a
-- yes/no through `dialog.yesno` (the callback is the dialog's), a list through `dialog.choose` where a dismissal (0)
-- is the harmless first answer.

return function(H)
  local eq = H.eq
  local dialog = require("lib.nvim.ui.dialog")
  local orig = { yesno = dialog.yesno, choose = dialog.choose }

  local good, failure = pcall(function()
    local seen
    dialog.yesno = function(question, label, cb)
      seen = { question, label, cb }
    end
    local got = {}
    require("bindings.usrcmds.plugin_repos.confirm").yesno("Uninstall x?", "uninstall", function(yes)
      got[#got + 1] = yes
    end)
    eq({ seen[1], seen[2] }, { "Uninstall x?", "uninstall" }, "the question and the label reach the dialog")
    seen[3](true)
    seen[3](false)
    eq(got, { true, false }, "the answers come back as booleans")

    local call
    dialog.choose = function(question, choices, default, cb)
      call = { question = question, choices = choices, default = default, cb = cb }
    end
    local execute = require("bindings.usrcmds.execute")
    local picked = {}
    execute.ask("Run it?", { "Cancel", "Run" }, function(index)
      picked[#picked + 1] = index
    end)
    eq(call.default, 1, "the harmless answer (Cancel) is focused")
    call.cb(2)
    call.cb(0)
    eq(picked, { 2, 1 }, "a dismissal is the first (harmless) answer")
  end)
  dialog.yesno, dialog.choose = orig.yesno, orig.choose
  assert(good, failure)
end
