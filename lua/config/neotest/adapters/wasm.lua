---@module 'config.neotest.adapters.wasm'
---@brief Neotest adapter configuration for WebAssembly testing (via JavaScript/Rust)

local M = {}

--- Detect WebAssembly test environment
---@return string|nil env "js", "rust", or nil
local function detect_environment()
  local cwd = (vim.uv or vim.loop).cwd() or vim.fn.getcwd()

  -- Check for Rust Wasm project
  if vim.fn.filereadable(cwd .. "/Cargo.toml") == 1 then
    local ok, lines = pcall(vim.fn.readfile, cwd .. "/Cargo.toml")
    if ok and lines then
      for i = 1, #lines do
        if lines[i]:match("wasm%-bindgen") or lines[i]:match("wasm%-pack") then
          return "rust"
        end
      end
    end
  end

  -- Check for JavaScript Wasm project
  if vim.fn.filereadable(cwd .. "/package.json") == 1 then
    return "js"
  end

  return nil
end

--- Initialize WebAssembly test adapter
---@return table|nil adapter Neotest adapter instance or nil on failure
local function create_adapter()
  local env = detect_environment()

  if env == "rust" then
    -- Use Rust adapter for wasm-pack projects
    local ok, rust_adapter = pcall(require, "neotest-rust")
    if ok then
      return rust_adapter({
        args = { "--no-capture", "--target", "wasm32-unknown-unknown" },
      })
    end
  elseif env == "js" then
    -- Use Jest/Vitest for JavaScript Wasm projects
    local ok, jest = pcall(require, "neotest-jest")
    if ok then
      return jest({
        jestCommand = "npm test --",
        env = { CI = "true" },
      })
    end
  end

  return nil
end

---@type table|nil
M.adapter = create_adapter()

---@type string[]
M.test_patterns = {
  "%.test%.wasm%.js$",
  "%.spec%.wasm%.js$",
  "wasm_.*_test%.rs$",
}

--- Check if file is a WebAssembly test file
---@param filepath string
---@return boolean
function M.is_test_file(filepath)
  if not filepath or filepath == "" then
    return false
  end

  for i = 1, #M.test_patterns do
    if filepath:match(M.test_patterns[i]) then
      return true
    end
  end

  return false
end

--- WebAssembly testing note
---@return string
function M.get_note()
  return "WebAssembly testing via wasm-pack (Rust) or JavaScript test runners"
end

return M
