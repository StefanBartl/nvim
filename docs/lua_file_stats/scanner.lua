---@module 'lua_file_stats.scanner'
-- File system scanner: discovers files and aggregates per-folder stats.

local analyzer = require("lua_file_stats.analyzer")
local utils = require("lua_file_stats.utils")
local M = {}

--- Recursively gather .lua files (Windows `dir` used for parity with original).
---@param dir string
---@return string[]|nil
function M.get_lua_files(dir)
    local files = {}
    local cmd = 'dir "' .. dir .. '" /S /B /A:-D'
    local p = io.popen(cmd)
    if not p then return nil end
    for file in p:lines() do
        if file:match("%.lua$") and not utils.should_ignore(file) then table.insert(files, file) end
    end
    p:close()
    return files
end

--- Scan directory and build folder_summary and total_stats.
---@param root_dir string
---@param total_stats table (will be mutated)
---@return table folder_summary
function M.scan_dir(root_dir, total_stats)
    local files = M.get_lua_files(root_dir)
    if not files then return {} end
    local per_folder = {}

    for _, file in ipairs(files) do
        local stats = analyzer.analyze_file(file)
        local rel_file = file:gsub("\\", "/")
        -- relative path trimming will be handled by caller (cli/printer)
        local folder = rel_file:match("(.+)/") or "."

        if not per_folder[folder] then
            per_folder[folder] = {
                total_lines=0, lines_without_comments=0, comment_lines=0,
                lines_without_annotations=0, annotation_lines=0,
                total_words=0, words_in_comments=0, words_in_annotations=0,
                words_without_comments=0, words_without_annotations=0,
                file_count=0,
                files = {}
            }
        end

        local f = per_folder[folder]
        for k, v in pairs(stats) do f[k] = (f[k] or 0) + v end
        f.file_count = f.file_count + 1
        table.insert(f.files, { rel_file = rel_file, stats = stats })

        for k, v in pairs(stats) do total_stats[k] = (total_stats[k] or 0) + v end
        total_stats.total_files = (total_stats.total_files or 0) + 1
    end

    return per_folder
end

return M
