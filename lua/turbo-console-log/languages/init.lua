local javascript = require("turbo-console-log.languages.javascript")
local php = require("turbo-console-log.languages.php")
local python = require("turbo-console-log.languages.python")

local M = {}

local langs = { javascript, php, python }

function M.for_filetype(ft)
  for _, lang in ipairs(langs) do
    for _, lft in ipairs(lang.filetypes) do
      if lft == ft then
        return lang
      end
    end
  end
  return nil
end

function M.all_filetypes()
  local fts = {}
  for _, lang in ipairs(langs) do
    vim.list_extend(fts, lang.filetypes)
  end
  return fts
end

return M
