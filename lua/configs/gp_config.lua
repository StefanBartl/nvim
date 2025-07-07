---@module 'configs.gp'
---@type table
return {
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
      model = {
        model = "gpt-4-1-mini",
      },
      system_prompt = "You're a helpful coding assistant.",
      chat = true,
      command = true,
    },
  },
}
