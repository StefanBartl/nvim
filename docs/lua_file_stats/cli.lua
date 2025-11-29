---@module 'lua_file_stats.cli'
---CLI entry point for lua_file_stats project.
---entrypoint wires scanner/printer; cli is top-level and no other module requires it.

-- compute script_dir (where this file lives)
local source = debug.getinfo(1, "S").source
local script_dir = source:match("^@?(.*[\\/])") or "./"
script_dir = script_dir:gsub("\\", "/")

-- module root is parent (docs/)
local parent_dir = script_dir .. "../"
parent_dir = parent_dir:gsub("\\", "/")

-- 
-- We add patterns so that:
-- 1) require("lua_file_stats.compute") --> parent_dir .. "?.lua"  (-> "docs/lua_file_stats/compute.lua")
-- 2) require("lua_file_stats.compute") --> parent_dir .. "?/init.lua" (if module is a folder with init.lua)
-- 3) also add script_dir fallback for requires like require("compute") if needed
package.path = parent_dir .. "?.lua;" .. parent_dir .. "?/init.lua;" .. script_dir .. "?.lua;" .. package.path

-- require modules (scanner/printer are independent and do not require cli)
local compute = require("lua_file_stats.compute")
local analyzer = require("lua_file_stats.analyzer")
local scanner = require("lua_file_stats.scanner")
local printer = require("lua_file_stats.printer")

local M = {}

-- Aggregates for results
M.folder_summary = {}
M.total_stats = {
    total_files = 0,
    total_lines = 0,
    lines_without_comments = 0,
    comment_lines = 0,
    lines_without_annotations = 0,
    annotation_lines = 0,
    blank_lines = 0,
    total_words = 0,
    words_in_comments = 0,
    words_in_annotations = 0,
    words_without_comments = 0,
    words_without_annotations = 0,
    words_in_blank = 0
}

-- Output mode settings (default: both numbers and percents)
M.percent_mode = "both" -- "both" | "percent" | "numbers"
M.fields_to_print = { "files", "folders", "summary" } -- which tables to print by default
M.single_file_path = nil

-- Top-N settings and top-only flags
M.top_n = 25
M.top_n_specified = false
M.only_top_files_lines = false
M.only_top_files_words = false
M.only_top_folders_lines = false
M.only_top_folders_words = false

local unpack = table.unpack or unpack

-- Parse args (simple)
local args = { unpack(arg) } -- CLI args
local root_dir = "."
for _, a in ipairs(args) do
    if a == "--reverse" then M.reverse_order = true
    elseif a == "--percent-only" or a == "--percentage-only" then M.percent_mode = "percent"
    elseif a == "--numbers-only" then M.percent_mode = "numbers"
    elseif a:match("^%-%-fields=") then
        M.fields_to_print = {}
        local val = a:sub(10)
        for f in val:gmatch("([^,]+)") do table.insert(M.fields_to_print, f) end
    elseif a:match("^%-%-file=") then
        M.single_file_path = a:sub(9)
    elseif a:match("^%-%-colwidth=") then
        M.col_width = tonumber(a:sub(12)) or M.col_width
    elseif a:match("^%-%-top=") then
        M.top_n = tonumber(a:sub(7)) or M.top_n
        M.top_n_specified = true
    elseif not a:match("^%-") then
        root_dir = a
    end
end

-- Column formatting defaults
M.col_width = M.col_width or 7
for _, a in ipairs(arg) do
    if a:match("^%-%-colwidth=") then M.col_width = tonumber(a:sub(12)) or M.col_width end
end

-- Single-file quick path
if M.single_file_path then
    local stats = analyzer.analyze_file(M.single_file_path)
    local folder_summary = { ["."] = { files = { { rel_file = M.single_file_path, stats = stats } }, file_count = 1 } }
    local cfg = { col_width = M.col_width, percent_mode = M.percent_mode, fields_to_print = M.fields_to_print, top_n = M.top_n }
    printer.print_file_stats(folder_summary, stats, cfg)
    printer.print_text_summary(stats)
    os.exit(0)
end

-- Normal multi-file flow
M.folder_summary = scanner.scan_dir(root_dir, M.total_stats) or {}

local cfg = { col_width = M.col_width, percent_mode = M.percent_mode, fields_to_print = M.fields_to_print, top_n = M.top_n }

if M.reverse_order then
    printer.print_total_summary(M.total_stats, cfg)
    printer.print_folder_summary(M.folder_summary, M.total_stats, cfg)
    printer.print_file_stats(M.folder_summary, M.total_stats, cfg)
else
    printer.print_file_stats(M.folder_summary, M.total_stats, cfg)
    printer.print_folder_summary(M.folder_summary, M.total_stats, cfg)
    printer.print_total_summary(M.total_stats, cfg)
end

printer.print_text_summary(M.total_stats)

return {
    -- exported for potential programmatic use
    scan = function(dir) return scanner.scan_dir(dir, M.total_stats) end,
    analyze = analyzer.analyze_file,
    compute = compute.compute_percentages,
    print = printer
}
