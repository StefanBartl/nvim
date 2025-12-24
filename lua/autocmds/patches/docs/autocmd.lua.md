-- Integration with Lazy.nvim
local group = vim.api.nvim_create_augroup("LocalPluginPatches", { clear = true })

-- Debounce-Timer für LazyUpdate
local lazy_update_timer = nil
local LAZY_UPDATE_DEBOUNCE_MS = 1000

vim.api.nvim_create_autocmd("User", {
  group = group,
  pattern = "LazyUpdate",
  callback = function()
    logger.info("LazyUpdate detected, scheduling patch application")

    -- Cancel existing timer if present
    if lazy_update_timer then
      lazy_update_timer:stop()
      lazy_update_timer:close()
    end

    -- Create new debounced timer
    lazy_update_timer = vim.loop.new_timer()
    lazy_update_timer:start(LAZY_UPDATE_DEBOUNCE_MS, 0, function()
      lazy_update_timer:stop()
      lazy_update_timer:close()
      lazy_update_timer = nil

      vim.schedule(function()
        M.apply_all_async(function(results)
          logger.info("LazyUpdate patch application complete", {
            total = #results,
          })
        end)
      end)
    end)
  end,
  desc = "Auto-apply patches after Lazy.nvim update (debounced)",
})
