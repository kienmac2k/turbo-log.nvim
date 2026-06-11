local config = require("turbo-log.config")
local insert = require("turbo-log.insert")
local bulk = require("turbo-log.bulk")
local panel = require("turbo-log.panel")
local M = {}

local function map_pair(_keys, lhs_gui, lhs_fallback, fn, desc)
  local modes = { "n", "x" }
  if lhs_gui then
    vim.keymap.set(modes, lhs_gui, fn, { desc = desc .. " (GUI)", silent = true })
  end
  if lhs_fallback then
    vim.keymap.set(modes, lhs_fallback, fn, { desc = desc, silent = true })
  end
end

local function map_insert_pair(binding, method, desc)
  if binding.gui then
    vim.keymap.set("n", binding.gui, function()
      insert.insert(method)
    end, { desc = desc .. " (GUI)", silent = true })
    vim.keymap.set("x", binding.gui, function()
      insert.insert(method, { from_visual = true })
    end, { desc = desc .. " (GUI)", silent = true })
  end
  if binding.fallback then
    vim.keymap.set("n", binding.fallback, function()
      insert.insert(method)
    end, { desc = desc, silent = true })
    vim.keymap.set("x", binding.fallback, function()
      insert.insert(method, { from_visual = true })
    end, { desc = desc, silent = true })
  end
end

local function setup_keymaps()
  local km = config.get().keymaps

  local insert_methods = {
    { key = "log", method = "log", desc = "Turbo insert console.log" },
    { key = "info", method = "info", desc = "Turbo insert console.info" },
    { key = "debug", method = "debug", desc = "Turbo insert console.debug" },
    { key = "table", method = "table", desc = "Turbo insert console.table" },
    { key = "warn", method = "warn", desc = "Turbo insert console.warn" },
    { key = "error", method = "error", desc = "Turbo insert console.error" },
    { key = "custom", method = "custom", desc = "Turbo insert custom log" },
  }

  for _, item in ipairs(insert_methods) do
    local binding = km.insert[item.key]
    map_insert_pair(binding, item.method, item.desc)
  end

  local bulk_ops = {
    { key = "comment", fn = bulk.comment_all, desc = "Turbo comment all logs" },
    { key = "uncomment", fn = bulk.uncomment_all, desc = "Turbo uncomment all logs" },
    { key = "delete", fn = bulk.delete_all, desc = "Turbo delete all logs" },
    { key = "correct", fn = bulk.correct_all, desc = "Turbo correct all logs" },
  }

  for _, item in ipairs(bulk_ops) do
    local binding = km.bulk[item.key]
    map_pair(binding, binding.gui, binding.fallback, item.fn, item.desc)
  end

  if km.panel then
    map_pair(km.panel, km.panel.gui, km.panel.fallback, panel.toggle, "Turbo log panel")
  end
  if km.find then
    map_pair(km.find, km.find.gui, km.find.fallback, panel.find, "Turbo find logs")
  end
end

local function setup_commands()
  local methods = { "log", "info", "debug", "table", "warn", "error", "custom" }
  for _, method in ipairs(methods) do
    vim.api.nvim_create_user_command("TurboLogInsert" .. method:sub(1, 1):upper() .. method:sub(2), function()
      insert.insert(method)
    end, {})
  end

  vim.api.nvim_create_user_command("TurboLogCommentAll", bulk.comment_all, {})
  vim.api.nvim_create_user_command("TurboLogUncommentAll", bulk.uncomment_all, {})
  vim.api.nvim_create_user_command("TurboLogDeleteAll", bulk.delete_all, {})
  vim.api.nvim_create_user_command("TurboLogCorrectAll", bulk.correct_all, {})
  vim.api.nvim_create_user_command("TurboLogPanel", panel.toggle, {})
  vim.api.nvim_create_user_command("TurboLogFind", panel.find, {})
end

function M.setup(opts)
  config.setup(opts)
  require("turbo-log.trouble_source").register()
  setup_commands()
  if config.get().setup_keymaps then
    setup_keymaps()
  end
end

function M.insert(method)
  insert.insert(method)
end

M.comment_all = bulk.comment_all
M.uncomment_all = bulk.uncomment_all
M.delete_all = bulk.delete_all
M.correct_all = bulk.correct_all
M.panel = panel.toggle
M.find = panel.find

return M
