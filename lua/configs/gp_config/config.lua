---@module 'configs.gp_config.config'

---@type table
local M = {
  openai_api_key = os.getenv("OPENAI_API_KEY"),

  providers = {
    openai = {
      disable = false,
      endpoint = "https://api.openai.com/v1/chat/completions",
      secret = os.getenv("OPENAI_API_KEY"),
    },
    anthropic = {
      disable = true,
      endpoint = "https://api.anthropic.com/v1/messages",
      secret = os.getenv("ANTHROPIC_API_KEY"),
    },
  },

  agents = {
    {
      name = "MiniHigh",
      provider = "openai",
      model = { model = "gpt-4-1-mini" },
      system_prompt = "You're a helpful coding assistant.",
      chat = true,
      command = true,
    },
  },
}

-- Load optional hooks without crashing if file is missing
---@type table
local extra_hooks = {}
do
  local ok, mod = pcall(require, "configs.gp_config.hooks.buffer_new_chat")
  if ok and type(mod) == "table" then
    extra_hooks = mod
  end
end

M.hooks = vim.tbl_extend("force", {}, extra_hooks)

return M
