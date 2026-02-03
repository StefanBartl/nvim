---@module 'lsp.languages.webdev.astro.commands'

local M = {}

---@return nil
function M.setup()
  -- Start Astro dev server
  vim.api.nvim_create_user_command("AstroDevStart", function()
    vim.cmd("terminal astro dev")
    vim.cmd("wincmd J")
    vim.cmd("resize 10")
  end, { desc = "Start Astro dev server" })

  -- Stop Astro dev server
  vim.api.nvim_create_user_command("AstroDevStop", function()
    vim.fn.system("pkill -f 'astro dev'")
    vim.notify("Astro dev server stopped")
  end, { desc = "Stop Astro dev server" })

  -- Build Astro project
  vim.api.nvim_create_user_command("AstroBuild", function()
    local output = vim.fn.system("astro build")
    vim.notify(output, vim.log.levels.INFO)
  end, { desc = "Build Astro project" })

  -- Preview production build
  vim.api.nvim_create_user_command("AstroPreview", function()
    vim.cmd("terminal astro preview")
    vim.cmd("wincmd J")
    vim.cmd("resize 10")
  end, { desc = "Preview Astro build" })

  -- Create new component
  vim.api.nvim_create_user_command("AstroNewComponent", function(opts)
    local name = opts.args
    if name == "" then
      name = vim.fn.input("Component name: ")
    end

    if name == "" then
      return
    end

    local path = "src/components/" .. name .. ".astro"
    local template = {
      "---",
      "interface Props {}",
      "",
      "const {} = Astro.props;",
      "---",
      "",
      "<div>",
      "  <!-- Component content -->",
      "</div>",
    }

    vim.fn.writefile(template, path)
    vim.cmd("edit " .. path)
  end, {
    nargs = "?",
    desc = "Create new Astro component",
  })

  -- Create new page
  vim.api.nvim_create_user_command("AstroNewPage", function(opts)
    local name = opts.args
    if name == "" then
      name = vim.fn.input("Page name (e.g., about.astro): ")
    end

    if name == "" then
      return
    end

    if not name:match("%.astro$") then
      name = name .. ".astro"
    end

    local path = "src/pages/" .. name
    local template = {
      "---",
      'import Layout from "@/layouts/Layout.astro";',
      "---",
      "",
      "<Layout title=\"Page\">",
      "  <main>",
      "    <h1>Page Content</h1>",
      "  </main>",
      "</Layout>",
    }

    vim.fn.writefile(template, path)
    vim.cmd("edit " .. path)
  end, {
    nargs = "?",
    desc = "Create new Astro page",
  })

  -- List all components
  vim.api.nvim_create_user_command("AstroListComponents", function()
    require("telescope.builtin").find_files({
      prompt_title = "Astro Components",
      search_dirs = { "src/components" },
      file_ignore_patterns = { "%.test%.", "%.spec%." },
    })
  end, { desc = "List all Astro components" })

  -- Find component usage
  vim.api.nvim_create_user_command("AstroFindUsage", function()
    local component = vim.fn.expand("<cword>")
    require("telescope.builtin").live_grep({
      prompt_title = "Component Usage: " .. component,
      default_text = "<" .. component,
    })
  end, { desc = "Find component usage" })

  -- Check project structure
  vim.api.nvim_create_user_command("AstroCheckStructure", function()
    local required_dirs = {
      "src/components",
      "src/layouts",
      "src/pages",
      "public",
    }

    local missing = {}
    for _, dir in ipairs(required_dirs) do
      if vim.fn.isdirectory(dir) == 0 then
        table.insert(missing, dir)
      end
    end

    if #missing > 0 then
      vim.notify("Missing directories:\n" .. table.concat(missing, "\n"), vim.log.levels.WARN)
    else
      vim.notify("Project structure is valid", vim.log.levels.INFO)
    end
  end, { desc = "Check Astro project structure" })
end

return M
