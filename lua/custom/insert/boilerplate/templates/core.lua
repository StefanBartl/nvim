---@module 'custom.insert.boilerplate.core'
---@brief Core implementation for boilerplate/template insertion

local notify = require("lib.notify").create("[custom.insert.boilerplate.templates.core]")

local utils = require("custom.insert.boilerplate.templates.utils")
local lua_templates = require("custom.insert.boilerplate.templates.lua")
local nvim_templates = require("custom.insert.boilerplate.templates.nvim")
local html_templates = require("custom.insert.boilerplate.templates.html")
local guard_templates = require("custom.insert.boilerplate.templates.guard")

local M = {}

---@type Custom.Insert.Boilerplate.TemplateRegistry
local registry = {
  ["lua-module"] = {
    category = "lua",
    description = "Complete Lua module skeleton",
    prompts = {
      {
        name = "name",
        prompt = "Module name (empty for auto-detect)",
        default = nil,
        required = false,
      },
    },
  },
  ["lua-class"] = {
    category = "lua",
    description = "Lua class with constructor",
    prompts = {
      {
        name = "class_name",
        prompt = "Class name",
        default = nil,
        required = true,
      },
    },
  },
  ["lua-function"] = {
    category = "lua",
    description = "Annotated function template",
    prompts = nil,
  },
  ["nvim-autocmd"] = {
    category = "nvim",
    description = "Neovim autocommand group",
    prompts = {
      {
        name = "group_name",
        prompt = "Autocommand group name",
        default = nil,
        required = true,
      },
    },
  },
  ["nvim-keymap"] = {
    category = "nvim",
    description = "Neovim keymap with description",
    prompts = nil,
  },
  ["guard-clause"] = {
    category = "guard",
    description = "Early return guard pattern (interactive)",
    prompts = nil,
  },
  ["html-figure"] = {
    category = "html",
    description = "HTML figure with image and caption",
    prompts = {
      {
        name = "id",
        prompt = "Figure ID",
        default = nil,
        required = true,
      },
    },
  },
  ["html-code"] = {
    category = "html",
    description = "HTML code listing with caption",
    prompts = {
      {
        name = "id",
        prompt = "Code listing ID",
        default = nil,
        required = true,
      },
    },
  },
  ["html-quote"] = {
    category = "html",
    description = "HTML blockquote with citation",
    prompts = {
      {
        name = "id",
        prompt = "Quote ID",
        default = nil,
        required = true,
      },
    },
  },
  ["html-formula-table"] = {
    category = "html",
    description = "HTML table for mathematical formulas",
    prompts = {
      {
        name = "id",
        prompt = "Table ID",
        default = nil,
        required = true,
      },
    },
  },
  ["html-aside"] = {
    category = "html",
    description = "HTML aside/note element",
    prompts = {
      {
        name = "id",
        prompt = "Aside ID",
        default = nil,
        required = true,
      },
    },
  },
  ["html-pagination"] = {
    category = "html",
    description = "HTML pagination navigation",
    prompts = {
      {
        name = "id",
        prompt = "Pagination ID",
        default = nil,
        required = true,
      },
    },
  },
  ["html-accordion"] = {
    category = "html",
    description = "HTML collapsible accordion/details",
    prompts = {
      {
        name = "id",
        prompt = "Accordion ID",
        default = nil,
        required = true,
      },
    },
  },
}

---Get template metadata
---@param template Custom.Insert.Boilerplate.Template
---@return Custom.Insert.Boilerplate.TemplateMetadata|nil metadata
function M.get_template_metadata(template)
  return registry[template]
end

---List all available templates
---@return Custom.Insert.Boilerplate.Template[]
function M.list_templates()
  local templates = {}
  for name, _ in pairs(registry) do
    table.insert(templates, name)
  end
  table.sort(templates)
  return templates
end

---List templates by category
---@param category Custom.Insert.Boilerplate.Category
---@return Custom.Insert.Boilerplate.Template[]
function M.list_templates_by_category(category)
  local templates = {}
  for name, meta in pairs(registry) do
    if meta.category == category then
      table.insert(templates, name)
    end
  end
  table.sort(templates)
  return templates
end

---Generate template lines
---@param template Custom.Insert.Boilerplate.Template
---@param args table<string, string>|nil Pre-filled arguments
---@return string[]|nil lines
local function generate_template(template, args)
  local meta = registry[template]
  if not meta then
    return nil
  end

  ---@type table<string, string>|nil
  local values = args or {}

  -- Process prompts if needed
  if meta.prompts and not args then
    values = utils.process_prompts(meta.prompts)
    if not values then
      return nil
    end
  end

  -- Generate template based on category
  if values and meta.category == "lua" then
    if template == "lua-module" then
      return lua_templates.module(values.name)
    elseif template == "lua-class" then
      return lua_templates.class(values.class_name)
    elseif template == "lua-function" then
      return lua_templates.func()
    end
  elseif values and meta.category == "nvim" then
    if template == "nvim-autocmd" then
      return nvim_templates.autocmd(values.group_name)
    elseif template == "nvim-keymap" then
      return nvim_templates.keymap()
    end
  elseif values and meta.category == "html" then
    if template == "html-figure" then
      return html_templates.figure(values.id)
    elseif template == "html-code" then
      return html_templates.code(values.id)
    elseif template == "html-quote" then
      return html_templates.quote(values.id)
    elseif template == "html-formula-table" then
      return html_templates.formula_table(values.id)
    elseif template == "html-aside" then
      return html_templates.aside(values.id)
    elseif template == "html-pagination" then
      return html_templates.pagination(values.id)
    elseif template == "html-accordion" then
      return html_templates.accordion(values.id)
    end
  elseif meta.category == "guard" then
    if template == "guard-clause" then
      return guard_templates.guard_interactive()
    end
  end

  return nil
end

---Insert boilerplate template at cursor
---@param template Custom.Insert.Boilerplate.Template
---@param name string|nil Optional name parameter (legacy support)
---@return boolean success
function M.insert_template(template, name)
  local lines

  -- Legacy support: convert name parameter to args table
  local args = nil
  if name and name ~= "" then
    args = { name = name, class_name = name, group_name = name, id = name }
  end

  lines = generate_template(template, args)

  if not lines then
    notify.error("[custom.insert.boilerplate] Failed to generate template: " .. template)
    return false
  end

  utils.insert_lines_at_cursor(lines)
  return true
end

return M
