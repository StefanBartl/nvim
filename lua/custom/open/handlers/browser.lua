---@module 'custom.open.handlers.browser'
---@brief Handlers that open a URL in various browsers.
---@description
--- Registered handlers: browser, chrome, chromium, firefox, edge, safari.
--- Non-URL text is treated as a web search query (Google) automatically.
--- Platform-specific launch commands are selected at run time.

local notify  = require("lib.nvim.notify").create("[custom.open.handlers.browser]")
local platform = require("custom.open.platform")
local util     = require("custom.open.util")

local M = {}

local SEARCH_BASE = "https://www.google.com/search?q="

-- ---------------------------------------------------------------------------
-- Internal helpers
-- ---------------------------------------------------------------------------

---Normalise text to a URL: pass URLs through, search everything else.
---@param ctx Custom.Open.Context
---@return string url
local function to_url(ctx)
  local text = ctx.text

  if ctx.is_url then
    -- Already a URL; add scheme if it starts with www.
    if text:match("^www%.") then
      return "https://" .. text
    end
    return text
  end

  if ctx.is_path then
    -- Local file — use file:// scheme.
    local expanded = vim.fn.expand(text)
    return "file://" .. expanded
  end

  -- Plain text → search query.
  return SEARCH_BASE .. util.url_encode(text)
end

---Build the command vector for the system-default browser.
---@param url string
---@param plat Custom.Open.Platform
---@return string[]
local function default_browser_cmd(url, plat)
  if plat.is_win then
    return { "cmd.exe", "/C", "start", "", url }
  elseif plat.is_wsl then
    -- wslview (wslu) is the canonical WSL browser launcher.
    if vim.fn.executable("wslview") == 1 then
      return { "wslview", url }
    end
    -- Fallback: Windows start via cmd.exe.
    return { "cmd.exe", "/C", "start", "", url }
  elseif plat.is_mac then
    return { "open", url }
  else
    return { "xdg-open", url }
  end
end

---Build the command vector for a named browser.
---@param url      string
---@param plat     Custom.Open.Platform
---@param linux_candidates  string[]   Candidate executable names on Linux
---@param mac_app           string     macOS application name for `open -a`
---@param win_token         string     Token passed to `cmd.exe /C start`
---@return string[]|nil cmd, string|nil err
local function named_browser_cmd(url, plat, linux_candidates, mac_app, win_token)
  if plat.is_win then
    return { "cmd.exe", "/C", "start", win_token, url }, nil
  elseif plat.is_wsl then
    -- Prefer native Linux browser first (if installed), then Windows via WSL.
    local exec = util.find_exec(linux_candidates)
    if exec then
      return { exec, url }, nil
    end
    return { "cmd.exe", "/C", "start", win_token, url }, nil
  elseif plat.is_mac then
    return { "open", "-a", mac_app, url }, nil
  else
    local exec = util.find_exec(linux_candidates)
    if not exec then
      return nil, string.format(
        "None of the candidates found on PATH: %s",
        table.concat(linux_candidates, ", ")
      )
    end
    return { exec, url }, nil
  end
end

---Create a browser handler using named_browser_cmd.
---@param key              string
---@param desc             string
---@param linux_candidates string[]
---@param mac_app          string
---@param win_token        string
---@return Custom.Open.Handler
local function make_named_handler(key, desc, linux_candidates, mac_app, win_token)
  return {
    key  = key,
    desc = desc,
    run  = function(ctx)
      local url  = to_url(ctx)
      local plat = platform.get()
      local cmd, err = named_browser_cmd(url, plat, linux_candidates, mac_app, win_token)
      if not cmd then
        notify.error(string.format("[custom.open.%s] %s", key, err))
        return false
      end
      local ok = util.run_detached(cmd, key)
      if ok then
        notify.info(string.format("[custom.open.%s] %s", key, url))
      end
      return ok
    end,
  }
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

---Register all browser handlers via the provided function.
---@param register_fn fun(h: Custom.Open.Handler): boolean
function M.register_all(register_fn)
  -- System default browser -----------------------------------------------
  register_fn({
    key  = "browser",
    desc = "Open in the system default browser",
    run  = function(ctx)
      local url  = to_url(ctx)
      local plat = platform.get()
      local cmd  = default_browser_cmd(url, plat)
      local ok   = util.run_detached(cmd, "browser")
      if ok then
        notify.info("[custom.open.browser] " .. url)
      end
      return ok
    end,
  })

  -- Google Chrome / Chromium ---------------------------------------------
  register_fn(make_named_handler(
    "chrome",
    "Open in Google Chrome",
    { "google-chrome", "google-chrome-stable", "chromium", "chromium-browser" },
    "Google Chrome",
    "chrome"
  ))

  register_fn(make_named_handler(
    "chromium",
    "Open in Chromium",
    { "chromium", "chromium-browser", "google-chrome" },
    "Chromium",
    "chrome"
  ))

  -- Mozilla Firefox ------------------------------------------------------
  register_fn(make_named_handler(
    "firefox",
    "Open in Mozilla Firefox",
    { "firefox", "firefox-esr" },
    "Firefox",
    "firefox"
  ))

  -- Microsoft Edge -------------------------------------------------------
  register_fn(make_named_handler(
    "edge",
    "Open in Microsoft Edge",
    { "microsoft-edge", "microsoft-edge-stable", "microsoft-edge-dev" },
    "Microsoft Edge",
    "msedge"
  ))

  -- Safari (macOS only) --------------------------------------------------
  register_fn({
    key  = "safari",
    desc = "Open in Safari (macOS only)",
    run  = function(ctx)
      local plat = platform.get()
      if not plat.is_mac then
        notify.warn("[custom.open.safari] Safari is only available on macOS")
        return false
      end
      local url = to_url(ctx)
      local ok  = util.run_detached({ "open", "-a", "Safari", url }, "safari")
      if ok then
        notify.info("[custom.open.safari] " .. url)
      end
      return ok
    end,
  })
end

return M
