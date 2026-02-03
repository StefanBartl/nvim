---@module 'lsp.languages.webdev.astro.keymaps'

local M = {}

---@return nil
function M.attach()
  local bufnr = vim.api.nvim_get_current_buf()
  if not bufnr or type(bufnr) ~= "number" then
    vim.notify("bufnr in astro keymaps attaching is not valid")
    return
  end

  -- Component-Navigation
  pcall(vim.keymap.set, "n", "gC", function()
    require("telescope.builtin").find_files({
      prompt_title = "Astro Components",
      search_dirs = { "src/components" },
      file_ignore_patterns = { "%.test%.", "%.spec%." },
    })
  end, { buffer = bufnr, desc = "Find Astro Components" })

  -- Layout-Navigation
  pcall(vim.keymap.set, "n", "gL", function()
    require("telescope.builtin").find_files({
      prompt_title = "Astro Layouts",
      search_dirs = { "src/layouts" },
    })
  end, { buffer = bufnr, desc = "Find Astro Layouts" })

  -- Page-Navigation
  pcall(vim.keymap.set, "n", "gP", function()
    require("telescope.builtin").find_files({
      prompt_title = "Astro Pages",
      search_dirs = { "src/pages" },
    })
  end, { buffer = bufnr, desc = "Find Astro Pages" })

  -- Script Block Navigation
  pcall(vim.keymap.set, "n", "<leader>as", function()
    vim.fn.search("^<script", "w")
  end, { buffer = bufnr, desc = "Jump to <script>" })

  -- Style Block Navigation
  pcall(vim.keymap.set, "n", "<leader>ay", function()
    vim.fn.search("^<style", "w")
  end, { buffer = bufnr, desc = "Jump to <style>" })

  -- Template Block Navigation
  pcall(vim.keymap.set, "n", "<leader>at", function()
    vim.fn.search("^---$", "w")
    vim.cmd("normal! j")
  end, { buffer = bufnr, desc = "Jump to template (after frontmatter)" })

  -- Frontmatter Navigation
  pcall(vim.keymap.set, "n", "<leader>af", function()
    vim.fn.cursor(1, 1)
    vim.fn.search("^---$", "c")
  end, { buffer = bufnr, desc = "Jump to frontmatter" })

  -- Toggle between Script/Template/Style
  pcall(vim.keymap.set, "n", "<leader>an", function()
    local line = vim.fn.line(".")
    local total = vim.fn.line("$")

    -- Find next section boundary
    local patterns = { "^<script", "^<style", "^---$" }
    local next_line = total

    for _, pat in ipairs(patterns) do
      vim.fn.cursor(line, 1)
      local found = vim.fn.search(pat, "W")
      if found > 0 and found < next_line then
        next_line = found
      end
    end

    if next_line < total then
      vim.fn.cursor(next_line, 1)
    else
      vim.fn.cursor(1, 1)
    end
  end, { buffer = bufnr, desc = "Next Astro section" })

  -- Import statement navigation
  pcall(vim.keymap.set, "n", "<leader>ai", function()
    vim.fn.search("^import ", "w")
  end, { buffer = bufnr, desc = "Jump to next import" })

  -- Add import statement
  pcall(vim.keymap.set, "n", "<leader>aI", function()
    local component = vim.fn.input("Component name: ")
    if component ~= "" then
      local import_line = string.format('import %s from "@/components/%s.astro";', component, component)

      -- Find frontmatter end
      vim.fn.cursor(1, 1)
      local fm_end = vim.fn.search("^---$", "W", 20)
      if fm_end > 0 then
        vim.fn.append(fm_end - 1, import_line)
      end
    end
  end, { buffer = bufnr, desc = "Add component import" })

  -- Extract to Component
  pcall(vim.keymap.set, "v", "<leader>ax", function()
    local name = vim.fn.input("Component name: ")
    if name == "" then
      return
    end

    -- Get visual selection
    local start_line = vim.fn.line("'<")
    local end_line = vim.fn.line("'>")
    local lines = vim.fn.getline(start_line, end_line)

    -- Create new component file
    local component_path = "src/components/" .. name .. ".astro"
    local content = {
      "---",
      "---",
      "",
      table.concat(lines, "\n"),
    }

    vim.fn.writefile(vim.split(table.concat(content, "\n"), "\n"), component_path)

    -- Replace selection with component usage
    vim.fn.deletebufline(bufnr, start_line, end_line)
    vim.fn.append(start_line - 1, "<" .. name .. " />")

    vim.notify("Created component: " .. component_path)
  end, { buffer = bufnr, desc = "Extract to component" })

  -- Preview in Browser
  pcall(vim.keymap.set, "n", "<leader>ap", function()
    local file = vim.fn.expand("%:p")
    local relative = vim.fn.fnamemodify(file, ":~:.")

    -- Convert file path to URL path
    local url_path = relative:gsub("^src/pages/", ""):gsub("%.astro$", "")
    if url_path:match("index$") then
      url_path = url_path:gsub("index$", "")
    end

    local url = "http://localhost:4321/" .. url_path
    vim.fn.system({"xdg-open", url})  -- Linux
    -- vim.fn.system({"open", url})   -- macOS
  end, { buffer = bufnr, desc = "Preview in browser" })

  -- Format Astro file
  pcall(vim.keymap.set, "n", "<leader>aF", function()
    local ok, conform = pcall(require, "conform")
    if ok then
      conform.format({ bufnr = bufnr, timeout_ms = 2000 })
    else
      vim.lsp.buf.format({ bufnr = bufnr, timeout_ms = 2000 })
    end
  end, { buffer = bufnr, desc = "Format Astro file" })
end

return M
