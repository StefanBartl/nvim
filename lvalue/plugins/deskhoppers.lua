return {
    "akinsho/toggleterm.nvim",
    config = function()
      require("toggleterm").setup {
        size = 20,
        open_mapping = [[<c-\>]],
        direction = "horizontal",
        persist_size = true,
      }
  
      -- Funktion zum Starten von Backend und Frontend
      local function start_container_workflow(term)
        if term == "backend" then
          vim.cmd("TermExec cmd='docker exec -it deskhoppers-backend-1 sh -c \"cd /workspace/packages/backend && exec sh\"'")
        elseif term == "frontend" then
          vim.cmd("TermExec cmd='docker exec -it deskhoppers-frontend-1 sh -c \"cd /workspace/packages/frontend && exec sh\"'")
        else
          vim.notify("Invalid container specified!", vim.log.levels.ERROR)
        end
      end

    -- Docker Compose starten
    vim.api.nvim_set_keymap(
        "n",
        "<leader>da",
        ":TermExec cmd='cd ~/GitRepo/deskhoppers && docker compose up -d'<CR>",
        { noremap = true, silent = true, desc = "Start Docker Compose" }
    )
  
      -- Backend-Workflow
      vim.api.nvim_set_keymap(
        "n",
        "<leader>db",
        ":lua start_container_workflow('backend')<CR>",
        { noremap = true, silent = true, desc = "Toggle Backend Terminal" }
      )
  
      -- Frontend-Workflow
      vim.api.nvim_set_keymap(
        "n",
        "<leader>dc",
        ":lua start_container_workflow('frontend')<CR>",
        { noremap = true, silent = true, desc = "Toggle Frontend Terminal" }
      )

    end,
  }
  