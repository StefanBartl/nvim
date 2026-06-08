---@module 'config.gp_config.config'

---@type table
local M = {
  openai_api_key = os.getenv("OPENAI_API_KEY"),

  default_chat_agent = "Ollama_Qwen_Chat",
  default_command_agent = "Ollama_Qwen_Cmd",

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
    -- 1. Neuen lokalen Ollama Provider hinzufügen
    ollama = {
      disable = false,
      endpoint = "http://localhost:11434/api/chat",
      secret = "dummy_key", -- Ollama braucht keinen Key, gp.nvim verlangt hier aber einen String
    },
  },

  agents = {
    {
      name = "ChatGPT3-5",
      disable = true,
    },
    {
      name = "MiniHigh",
      provider = "openai",
      model = { model = "gpt-4-1-mini" },
      system_prompt = "You're a helpful coding assistant.",
      chat = true,
      command = true,
    },
    {
      name = "GTP5",
      provider = "openai",
      model = { model = "gpt-5" },
      system_prompt = "Du bist Senior-Developer und und gehst ganz genau auf Thematiken und erklärst den wissenschaftlichen Kontext.",
      chat = true,
      command = false,
    },
    -- 2. Lokalen Qwen Chat-Agenten hinzufügen
    {
      name = "Ollama_Qwen_Chat",
      provider = "ollama",
      -- WICHTIG: Direkt als String definieren, wenn der native Endpoint genutzt wird:
      model = "qwen2.5-coder:7b",
      system_prompt = "Du bist ein lokaler KI-Assistent. Antworte präzise...",
      chat = true,
      command = false,
    },
    {
      name = "Ollama_Qwen_Cmd",
      provider = "ollama",
      -- WICHTIG: Auch hier direkt als String:
      model = "qwen2.5-coder:7b",
      system_prompt = "Du bist ein präziser Code-Generierungs-Agent...",
      chat = false,
      command = true,
    },
  },
}

-- Load optional hooks without crashing if file is missing
---@type table
local extra_hooks = {}
do
  local ok, mod = pcall(require, "config.gp_config.hooks.buffer_new_chat")
  if ok and type(mod) == "table" then
    extra_hooks = mod
  end
end

M.hooks = vim.tbl_extend("force", {}, extra_hooks)

return M
