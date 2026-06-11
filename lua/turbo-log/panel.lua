local config = require("turbo-log.config")
local scope = require("turbo-log.scope")

local M = {}

local MODE = "turbo_logs"

local function trouble()
  return require("trouble")
end

local function has_trouble()
  return pcall(require, "trouble")
end

local function panel_opts()
  local panel = config.get().panel
  local fraction = math.min(panel.height or 0.3, 0.45)
  return {
    mode = MODE,
    focus = false,
    win = {
      type = "split",
      position = "bottom",
      size = math.max(8, math.min(30, math.floor(vim.o.lines * fraction))),
    },
  }
end

function M.open()
  if not has_trouble() then
    vim.notify("turbo-log: trouble.nvim is required for the log panel", vim.log.levels.ERROR)
    return
  end
  trouble().open(panel_opts())
end

function M.close()
  if not has_trouble() then
    return
  end
  trouble().close({ mode = MODE })
end

function M.toggle()
  if not has_trouble() then
    vim.notify("turbo-log: trouble.nvim is required for the log panel", vim.log.levels.ERROR)
    return
  end
  trouble().toggle(panel_opts())
end

function M.find()
  local ok, snacks = pcall(require, "snacks.picker")
  if ok and snacks and snacks.grep then
    snacks.grep({
      pattern = config.get().logMessagePrefix,
      cwd = scope.scan(),
    })
    return
  end

  M.toggle()
end

return M
