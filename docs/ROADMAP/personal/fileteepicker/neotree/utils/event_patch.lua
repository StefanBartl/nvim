---@module 'config.neotree.utils.event_patch'
---@brief Patch Neo-tree's fs_watch callbacks to handle EPERM gracefully

local M = {}

---@type table<string, function>
local original_callbacks = {}

---@type boolean
local patched = false

---Wrap a single watcher callback with EPERM handling
---@param original function Original callback
---@param path string Path being watched
---@return function wrapped Wrapped callback
---@diagnostic disable-next-line: unused-local
local function wrap_callback(original, path)
  return function(err, fname)
    -- If there's already an error from libuv, handle it
    if err then
      -- Suppress EPERM/permission errors silently
      if err:match("EPERM") or
         err:match("permission denied") or
         err:match("EACCES") then
        -- Silent suppression during file operations
        return
      end

      -- Re-throw other errors to original handler
      return original(err, fname)
    end

    -- For successful events, wrap in pcall to catch fs_stat EPERM
    local ok, result = pcall(original, err, fname)

    if not ok then
      local error_msg = tostring(result)

      -- Suppress EPERM errors from fs_stat during deletion
      if error_msg:match("EPERM") or
         error_msg:match("permission denied") or
         error_msg:match("EACCES") then
        -- File was deleted during watch - this is expected
        return nil
      end

      -- Re-throw other errors
      error(result)
    end

    return result
  end
end

---Patch all active fs_watch watchers
---@return boolean success
function M.patch()
  if patched then
    return true
  end

  local ok, fs_watch = pcall(require, "neo-tree.sources.filesystem.lib.fs_watch")
  if not ok or not fs_watch then
    return false
  end

  -- Access internal watchers table (it's exposed as local in the module)
  -- We need to hook into watch_folder to wrap new callbacks
  local original_watch_folder = fs_watch.watch_folder
  if not original_watch_folder then
    return false
  end

  -- Replace watch_folder to wrap callbacks
  fs_watch.watch_folder = function(path, callback)
    -- Wrap the callback before passing to original
    local wrapped_callback = wrap_callback(callback, path)

    -- Store original for potential restoration
    if not original_callbacks[path] then
      original_callbacks[path] = callback
    end

    -- Call original with wrapped callback
    return original_watch_folder(path, wrapped_callback)
  end

  patched = true
  return true
end

---Restore original watch_folder function
---@return boolean success
function M.unpatch()
  if not patched then
    return false
  end

  local ok, fs_watch = pcall(require, "neo-tree.sources.filesystem.lib.fs_watch")
  if not ok or not fs_watch then
    return false
  end

  -- We can't easily unpatch individual watchers, but we can stop all
  -- and let them be recreated naturally
  if fs_watch.stop_watching then
    fs_watch.stop_watching()
  end

  original_callbacks = {}
  patched = false

  return true
end

---Check if currently patched
---@return boolean
function M.is_patched()
  return patched
end

---Alternative approach: Monkey-patch the Watcher:start method
---This intercepts at a lower level
---@return boolean success
function M.patch_watcher_start()
  local ok, fs_watch = pcall(require, "neo-tree.sources.filesystem.lib.fs_watch")
  if not ok or not fs_watch then
    return false
  end

  -- Access the Watcher class (it's local but referenced in watch_folder return)
  -- We need to patch through a created watcher instance
  local test_watcher = fs_watch.watch_folder("/tmp", function() end)
  if not test_watcher then
    return false
  end

  -- Get the metatable to access the class
  local Watcher = getmetatable(test_watcher)
  if not Watcher or not Watcher.start then
    return false
  end

  -- Store original start method
  local original_start = Watcher.start

  -- Replace with wrapped version
  Watcher.start = function(self, path)
    -- Wrap the callback stored in self
    local original_callback = self.callback

    self.callback = function(err, fname)
      if err then
        if err:match("EPERM") or err:match("EACCES") then
          return -- Silent suppression
        end
        return original_callback(err, fname)
      end

      local ok_call, result = pcall(original_callback, err, fname)
      if not ok_call then
        local error_msg = tostring(result)
        if error_msg:match("EPERM") or error_msg:match("EACCES") then
          return -- Silent suppression
        end
        error(result)
      end

      return result
    end

    -- Call original start with wrapped callback
    return original_start(self, path)
  end

  -- Clean up test watcher
  if test_watcher.stop then
    test_watcher:stop()
  end

  return true
end

return M
