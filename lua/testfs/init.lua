---@module 'testfs'

--[[
lua\testfs\zwei.lua
lua\testfs\util\init.lua
lua\testfs\rem\da.lua
lua\testfs\init.lua
lua\testfs\hehe\puh.lua
lua\testfs\hehe\dada\init.lua
lua\testfs\hehe\com\util.lua
lua\testfs\eins.lua
lua\testfs\drei.lua
]]--

local eins = require("testfs.eins")
local zwei = require("testfs.zwei")
local drei = require("testfs.drei")

local result = eins + zwei + drei

vim.notify("result: " .. result, 2)

local util = require("testfs.util")
local dada = require("testfs.hehe.dada")
local remda = require("testfs.rem.da")
local d = require("testfs.hehe.com.korrekt")
vim.notify(dada .. " " .. remda, 2)

result = util.add(result, eins)
vim.notify(result)
