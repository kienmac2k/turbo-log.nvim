local Item = require("trouble.item")
local config = require("turbo-log.config")
local detect = require("turbo-log.detect")
local panel_actions = require("turbo-log.panel_actions")
local scope = require("turbo-log.scope")

local M = {}

M.highlights = {
  Message = "TroubleText",
  ItemSource = "Comment",
}

local function action_on_item(action)
  return function(view, ctx)
    panel_actions.run_on_item(ctx.item, action, view)
  end
end

M.config = {
  modes = {
    turbo_logs = {
      desc = "Turbo Console Logs",
      source = "turbo_logs",
      events = {
        "BufEnter",
        "BufWritePost",
        { event = "TextChanged", main = true },
      },
      focus = false,
      auto_preview = true,
      follow = true,
      groups = {
        { "directory" },
        { "filename", format = "{file_icon} {basename} {count}" },
      },
      sort = { "filename", "pos" },
      format = "{text:ts} {pos}",
      win = {
        type = "split",
        position = "bottom",
      },
      keys = {
        d = { action = action_on_item(panel_actions.delete_entry), desc = "Delete log" },
        c = { action = action_on_item(panel_actions.comment_entry), desc = "Comment log" },
        u = { action = action_on_item(panel_actions.uncomment_entry), desc = "Uncomment log" },
        x = { action = action_on_item(panel_actions.correct_entry), desc = "Correct log" },
        ["/"] = {
          action = function(view)
            vim.ui.input({ prompt = "Filter: " }, function(input)
              if input == nil then
                return
              end
              if input == "" then
                view:filter(nil, { del = true, id = "turbo_search" })
              else
                local query = input:lower()
                view:filter({
                  function(item)
                    local text = (item.text or ""):lower()
                    local file = (item.filename or ""):lower()
                    return text:find(query, 1, true) or file:find(query, 1, true)
                  end,
                }, {
                  id = "turbo_search",
                  template = "{hl:Title}Filter:{hl} " .. input,
                })
              end
              view:refresh()
            end)
          end,
          desc = "Filter logs",
        },
      },
    },
  },
}

---@param cb trouble.Source.Callback
---@param _ctx trouble.Source.ctx
function M.get(cb, _ctx)
  local entries = detect.workspace_scan(scope.scan())
  local items = {}

  for _, entry in ipairs(entries) do
    local text = vim.trim(entry.line)
    items[#items + 1] = Item.new({
      source = "turbo_logs",
      filename = entry.path,
      pos = { entry.lnum, 0 },
      text = text,
      item = entry,
    })
  end

  Item.add_id(items)
  Item.add_text(items, { mode = "line" })
  cb(items)
end

function M.register()
  local ok, Sources = pcall(require, "trouble.sources")
  if not ok then
    return false
  end
  if Sources.sources.turbo_logs then
    return true
  end
  Sources.register("turbo_logs", M)
  return true
end

return M
