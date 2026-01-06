---@module 'custom.insert.filepath.@types'

---@alias Custom.Insert.FilePath.Mode
---| "cwd"      -- Relative to current working directory
---| "abs"      -- Absolute path
---| "absolute" -- Absolute path (alias)

---@alias Custom.Insert.FilePath.Format
---| "system"  -- System-native separator
---| "win"     -- Windows backslash
---| "windows" -- Windows backslash (alias)
---| "unix"    -- Unix forward slash
---| "linux"   -- Unix forward slash (alias)
---| "lua"     -- Lua module path (dots, no extension)

---@class Custom.Insert.FilePath.Options
---@field mode Custom.Insert.FilePath.Mode Path calculation mode
---@field format Custom.Insert.FilePath.Format Output format
---@field depth integer|nil Folder depth (0 = filename only, nil = full path)

---@class Custom.Insert.FilePath.API
---@field insert_path fun(opts: Custom.Insert.FilePath.Options): boolean Insert path at cursor

return {}
