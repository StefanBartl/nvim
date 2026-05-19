---@module 'custom.picker_fd_depth.keymaps'
---@brief Interactive key mappings with strict lazy-loading and cancel protections.

local M = {}

--- Enable and register the interactive key mapping.
---@return nil
function M.enable()
  local map = vim.g.__map_helper or require("lib.map")

  map("n", "<leader>fdd", function()
    -- Prompt 1: Request directory depth level upwards
    vim.ui.input({ prompt = "Levels above current CWD (Default: 0): " }, function(input_depth)
      -- Usability Guard: If the user hit <Esc> to abort the input, terminate instantly
      if input_depth == nil then
        return
      end

      local depth = tonumber(input_depth) or 0
      local engines = { "telescope", "fzf" }

      -- Central search execution router
      local function execute_search(choice)
        local engine = choice or "telescope"
        -- Performance: Lazy loading the core logic only when choice is confirmed
        require("custom.picker_fd_depth.core").find_files(depth, engine)
      end

      -- Safe dynamic lookup of your specific framework library path
      local ok, hover_select = pcall(require, "lib.ui.hover_select")

      if ok and hover_select and type(hover_select.open) == "function" then
        -- Utilize your framework's native interface layout
        hover_select.open({
          title = "Select Picker Engine",
          items = engines,
          on_select = function(choice)
            execute_search(choice)
          end,
        })
      else
        -- Fallback safely to standard upstream Neovim core interface if component is missing
        vim.ui.select(engines, {
          prompt = "Select Picker Engine (Default: telescope):",
        }, function(choice)
          execute_search(choice)
        end)
      end
    end)
  end, { desc = "[Picker] Search files across directory depth levels" })
end

return M
