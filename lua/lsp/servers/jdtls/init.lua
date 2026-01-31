---@module 'lsp.servers.jdtls'
--- Eclipse JDT Language Server for Java (Android development).

local notify = require("lib.notify").create("[lsp.servers.jdtls]")

local M = {}

---Find jdtls installation path
---@return string|nil
local function find_jdtls()
  local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
  local candidates = {
    mason_bin .. "/jdtls",
    vim.fn.exepath("jdtls"),
  }

  for _, path in ipairs(candidates) do
    if path ~= "" and (vim.uv or vim.loop).fs_stat(path) then
      return path
    end
  end
  return nil
end

---Detect project root for Java projects
---@param fname string
---@return string|nil
local function java_root_dir(fname)
  local markers = {
    "gradlew",
    "build.gradle",
    "build.gradle.kts",
    "pom.xml",
    "settings.gradle",
    "settings.gradle.kts",
    ".git",
  }

  local dir = vim.fs.dirname(fname)
  return vim.fs.root(dir, markers)
end

---@param shared {capabilities?:table,on_attach?:fun(client,bufnr),on_init?:fun(client,init_result):boolean}|nil
---@param opts { enable?: boolean }|nil
---@return nil
function M.setup(shared, opts)
  shared = shared or {}
  opts = opts or {}

  local jdtls_cmd = find_jdtls()
  if not jdtls_cmd then
    notify.warn("jdtls not found; skipping Java LSP setup")
    return
  end

  if type(vim.lsp.config) ~= "table" then
    return
  end

  local data_dir = vim.fn.stdpath("cache") .. "/jdtls"
  local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
  local workspace_dir = data_dir .. "/" .. project_name

  vim.lsp.config("jdtls", {
    cmd = {
      jdtls_cmd,
      "-data",
      workspace_dir,
    },
    filetypes = { "java" },
    root_dir = java_root_dir,
    capabilities = shared.capabilities,
    on_attach = shared.on_attach,
    on_init = shared.on_init,
    settings = {
      java = {
        signatureHelp = { enabled = true },
        contentProvider = { preferred = "fernflower" },
        completion = {
          favoriteStaticMembers = {
            "org.junit.Assert.*",
            "org.junit.Assume.*",
            "org.junit.jupiter.api.Assertions.*",
            "org.junit.jupiter.api.Assumptions.*",
            "org.junit.jupiter.api.DynamicTest.*",
            "org.mockito.Mockito.*",
            "org.mockito.ArgumentMatchers.*",
          },
        },
        sources = {
          organizeImports = {
            starThreshold = 9999,
            staticStarThreshold = 9999,
          },
        },
        codeGeneration = {
          toString = {
            template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
          },
          useBlocks = true,
        },
        configuration = {
          runtimes = {},
        },
      },
    },
  })

  if opts.enable ~= false then
    pcall(vim.lsp.enable, "jdtls")
  end
end

return M
