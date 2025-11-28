---@module 'lua_file_stats.cli'
-- CLI entry point. This script can be executed with `lua path/to/cli.lua [root_dir] [flags]`.
-- It wires up modules, parses arguments and runs scan/print.

-- Ensure module path includes the sibling 'lua_file_stats' directory (the modules live there).
local source = debug.getinfo(1, "S").source
local script_dir = source:match("^@?(.*[\\/])") or "./"
-- Add possible module search paths (folder and subfolder).
package.path = script_dir .. "?.lua;" .. script_dir .. "lua_file_stats/?.lua;" .. package.path

local utils = require("lua_file_stats.utils")
local compute = require("lua_file_stats.compute")
local analyzer = require("lua_file_stats.analyzer")
local scanner = require("lua_file_stats.scanner")
local printer = require("lua_file_stats.printer")

-- default globals / config
local total_stats = {
    total_files = 0, total_lines = 0, lines_without_comments = 0, comment_lines = 0,
    lines_without_annotations = 0, annotation_lines = 0,
    total_words = 0, words_in_comments = 0, words_in_annotations = 0,
    words_without_comments = 0, words_without_annotations = 0
}

local folder_summary = {}
local percent_mode = "both"
local fields_to_print = { "files", "folders", "summary" }
local single_file_path = nil
local col_width = 7
local reverse_order = false

-- Parse args (simple)
local args = { unpack(arg) } -- CLI args
local root_dir = "."
for _, a in ipairs(args) do
    if a == "--reverse" then reverse_order = true
    elseif a == "--percent-only" or a == "--percentage-only" then percent_mode = "percent"
    elseif a == "--numbers-only" then percent_mode = "numbers"
    elseif a:match("^%-%-fields=") then
        fields_to_print = {}
        local val = a:sub(10)
        for f in val:gmatch("([^,]+)") do table.insert(fields_to_print, f) end
    elseif a:match("^%-%-file=") then
        single_file_path = a:sub(9)
    elseif a:match("^%-%-colwidth=") then
        col_width = tonumber(a:sub(12)) or col_width
    elseif not a:match("^%-") then
        root_dir = a
    end
end

-- Provide format_value function based on percent_mode
local function format_value(number, perc)
    if percent_mode == "both" then
        return string.format("%d (%.1f%%)", utils.safe_number(number), utils.safe_number(perc))
    elseif percent_mode == "percent" then
        return string.format("%.1f%%", utils.safe_number(perc))
    else
        return string.format("%d", utils.safe_number(number))
    end
end

-- expose printer config
printer.col_width = col_width

-- If single file mode: analyze only that file and print file table (no folder/total)
if single_file_path then
    local stats = analyzer.analyze_file(single_file_path)
    folder_summary = { ["."] = { files = { { rel_file = single_file_path, stats = stats } }, file_count = 1 } }
    printer.print_file_stats(folder_summary, format_value, col_width, 60)
    printer.print_text_summary(stats)
    os.exit(0)
end

-- Normal multi-file flow
folder_summary = scanner.scan_dir(root_dir, total_stats)

if reverse_order then
    printer.print_total_summary(total_stats, format_value, col_width)
    printer.print_folder_summary(folder_summary, format_value, col_width, 40)
    printer.print_file_stats(folder_summary, format_value, col_width, 60)
else
    printer.print_file_stats(folder_summary, format_value, col_width, 60)
    printer.print_folder_summary(folder_summary, format_value, col_width, 40)
    printer.print_total_summary(total_stats, format_value, col_width)
end

printer.print_text_summary(total_stats)

return {
    -- exported for potential programmatic use
    scan = function(dir) return scanner.scan_dir(dir, total_stats) end,
    analyze = analyzer.analyze_file,
    compute = compute.compute_percentages,
    print = printer
}
