---@module 'lua_file_stats.scanner'
---File system scanner: discovers files and aggregates per-folder stats.
---scanner is independent of cli/printer; it returns per-folder table and mutates supplied total_stats.

local analyzer = require("lua_file_stats.analyzer")
local utils = require("lua_file_stats.utils")
local M = {}

--- Recursively gather .lua files. Uses platform 'dir' for Windows; fallback to 'find' if available.
---attempts to be cross-platform by probing command availability.
---@param dir string
---@return string[]|nil
local function get_lua_files(dir)
    local files = {}
    if not dir or dir == "" then dir = "." end

    -- Try Windows dir first (msys/mingw environment)
    local ok, p = pcall(io.popen, 'dir "' .. dir .. '" /S /B /A:-D')
    if not ok or not p then
        -- Fallback to Unix find
        ok, p = pcall(io.popen, 'find "' .. dir .. '" -type f -name "*.lua" 2>/dev/null')
        if not ok or not p then return nil end
    end

    for file in p:lines() do
        if file:match("%.lua$") and not utils.should_ignore(file) then table.insert(files, file) end
    end
    p:close()
    return files
end

--- Scan directory and build folder_summary and update total_stats.
---returns per_folder table; caller assigns results where needed.
---@param root_dir string
---@param total_stats table (will be mutated)
---@return table|nil folder_summary
function M.scan_dir(root_dir, total_stats)
    local files = get_lua_files(root_dir)
    if not files then return nil end
    local per_folder = {}

    total_stats = total_stats or {}
    total_stats.total_files = total_stats.total_files or 0
    total_stats.total_lines = total_stats.total_lines or 0
    total_stats.lines_without_comments = total_stats.lines_without_comments or 0
    total_stats.comment_lines = total_stats.comment_lines or 0
    total_stats.lines_without_annotations = total_stats.lines_without_annotations or 0
    total_stats.annotation_lines = total_stats.annotation_lines or 0
    total_stats.blank_lines = total_stats.blank_lines or 0
    total_stats.total_words = total_stats.total_words or 0
    total_stats.words_in_comments = total_stats.words_in_comments or 0
    total_stats.words_in_annotations = total_stats.words_in_annotations or 0
    total_stats.words_without_comments = total_stats.words_without_comments or 0
    total_stats.words_without_annotations = total_stats.words_without_annotations or 0
    total_stats.words_in_blank = total_stats.words_in_blank or 0

    for _, file in ipairs(files) do
        local stats = analyzer.analyze_file(file)
        local rel_file = utils.relative_path(file)
        local folder = rel_file:match("(.+)/") or "."

        if not per_folder[folder] then
            per_folder[folder] = {
                total_lines = 0, lines_without_comments = 0, comment_lines = 0,
                lines_without_annotations = 0, annotation_lines = 0, blank_lines = 0,
                total_words = 0, words_in_comments = 0, words_in_annotations = 0,
                words_without_comments = 0, words_without_annotations = 0, words_in_blank = 0,
                file_count = 0, files = {}
            }
        end

        local f = per_folder[folder]
        for k, v in pairs(stats) do
            if type(v) == "number" then
                if f[k] == nil then f[k] = v else f[k] = f[k] + v end
            else
                f[k] = v
            end
        end
        f.file_count = f.file_count + 1
        table.insert(f.files, { rel_file = rel_file, stats = stats })

        -- update totals
        for k, v in pairs(stats) do
            if type(v) == "number" then
                if total_stats[k] == nil then total_stats[k] = v else total_stats[k] = total_stats[k] + v end
            else
                total_stats[k] = v
            end
        end
        total_stats.total_files = total_stats.total_files + 1
    end

    return per_folder
end

return M
