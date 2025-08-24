---@module 'plugins.test'
--- Plugins curently in test phase

---@type LazyPluginSpec[]
return {


  {
    'andymass/vim-matchup',
    init = function()
    -- Disable parenthesis highlight only
    vim.g.matchup_matchparen_enabled = 0    -- no MatchParen highlight
    vim.g.matchup_matchparen_deferred = 0   -- no delayed flashes
    vim.g.matchup_matchparen_offscreen = {} -- no offscreen popup

    require('match-up').setup({ treesitter = { stopline = 500 } })
  end,
  }

}
