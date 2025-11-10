---@module 'config.snacks.mappings'
---@brief Keymaps for custom Snacks dashboard with safe dispatcher

local M = {}

---@return (string|function|table)[]
M.keys = function()
    ---@param mod string
    ---@param fn string
    ---@param ... any
    ---@return boolean ok
    local function safe_call(mod, fn, ...)
        local ok_mod, M = pcall(require, "snacks." .. mod)
        if not ok_mod or type(M[fn]) ~= "function" then
            vim.notify(string.format("[snacks] missing %s.%s()", mod, fn), vim.log.levels.WARN)
            return false
        end
        local ok_fn, err = pcall(M[fn], ...)
        if not ok_fn then
            vim.notify(string.format("[snacks] %s.%s(): %s", mod, fn, tostring(err)), vim.log.levels.ERROR)
            return false
        end
        return true
    end

    ---@type (string|function|table)[]
    local maps = { [11] = false }

    maps[1]  = { "<leader>ud", function() safe_call("debug", "open") end, desc = "Snacks Debug: Open Inspector" }
    maps[2]  = { "<leader>uD", function() safe_call("debug", "toggle") end, desc = "Snacks Debug: Toggle Overlay" }
    maps[3]  = { "<leader>uf", function() safe_call("dim", "toggle") end, desc = "Snacks Dim: Toggle Focus Scope" }
    maps[4]  = { "<leader>ps", function() safe_call("profiler", "start") end, desc = "Snacks Profiler: Start" }
    maps[5]  = { "<leader>pS", function() safe_call("profiler", "stop") end, desc = "Snacks Profiler: Stop" }
    maps[6]  = { "<leader>pr", function() safe_call("profiler", "report") end, desc = "Snacks Profiler: Report" }
    maps[7]  = { "<leader>uq", function() safe_call("quickfile", "disable") end, desc = "Snacks Quickfile: Disable (session)" }
    maps[8]  = { "]s", function() safe_call("scope", "jump_next") end, desc = "Snacks Scope: Next" }
    maps[9]  = { "[s", function() safe_call("scope", "jump_prev") end, desc = "Snacks Scope: Prev" }
    maps[10] = { "<leader>ns", function() safe_call("scratch", "open") end, desc = "Snacks Scratch: Open" }
    maps[11] = { "<leader>nS", function() safe_call("scratch", "new") end, desc = "Snacks Scratch: New" }

    return maps
end

return M
