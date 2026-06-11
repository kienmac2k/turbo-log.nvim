# turbo-log.nvim

A Neovim plugin that replicates the [Turbo Console Log](https://marketplace.visualstudio.com/items?itemName=ChakrounAnas.turbo-console-log) VS Code extension — including log message formatting, bulk operations, and a workspace log panel.

**Supported languages:** JavaScript, TypeScript, JSX/TSX, PHP, Python

## Features

- Insert formatted `console.log` / `info` / `debug` / `table` / `warn` / `error` (and custom) statements from the word or selection under the cursor
- Three-line wrapped log format (matching Turbo Console Log defaults)
- Treesitter-aware context: filename, line number, enclosing class, and function
- Bulk operations in the current buffer: comment, uncomment, delete, and correct all Turbo logs
- Workspace log panel (bottom split via [trouble.nvim](https://github.com/folke/trouble.nvim)) with file grouping, preview, filter, and per-log actions
- Optional workspace grep via [snacks.nvim](https://github.com/folke/snacks.nvim) when available

### Example output

```javascript
console.log("🚀 -----------------------------------------------------🚀");
console.log("🚀 ~ index.tsx:198 ~ ModuleManagement ~ error:", error);
console.log("🚀 -----------------------------------------------------🚀");
```

## Requirements

| Dependency | Required | Purpose |
|---|---|---|
| Neovim ≥ 0.9 | Yes | Lua API, `vim.fs` |
| [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | Yes | Context extraction, target resolution |
| [trouble.nvim](https://github.com/folke/trouble.nvim) | Yes | Log panel UI |
| [ripgrep](https://github.com/BurntSushi/ripgrep) (`rg`) | Yes | Workspace log scan |
| [snacks.nvim](https://github.com/folke/snacks.nvim) | No | `:TurboLogFind` grep picker (falls back to panel) |

## Installation

### lazy.nvim

Add to your plugin spec (e.g. `lua/plugins/turbo-log.lua`):

```lua
return {
  {
    "kienmac2k/turbo-log.nvim",
    main = "turbo-log",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "folke/trouble.nvim",
      "folke/snacks.nvim", -- optional
    },
    opts = {},
    config = function(_, opts)
      require("turbo-log").setup(opts)
    end,
  },
}
```

Then run `:Lazy sync`.

### LazyVim

LazyVim already ships with `trouble.nvim` and `snacks.nvim`. Create `lua/plugins/turbo-log.lua`:

```lua
return {
  {
    "kienmac2k/turbo-log.nvim",
    main = "turbo-log",
    dependencies = { "folke/trouble.nvim" },
    opts = { setup_keymaps = false },
    config = true,
  },
}
```

Add keymaps to `lua/config/keymaps.lua` (LazyVim uses `<leader>c*` for LSP, so Turbo uses `<leader>v*`):

```lua
local turbo_modes = { "n", "x" }
local function turbo()
  return require("turbo-log")
end

vim.keymap.set(turbo_modes, "<leader>vl", function() turbo().insert("log") end, { desc = "Turbo console.log" })
vim.keymap.set(turbo_modes, "<leader>vn", function() turbo().insert("info") end, { desc = "Turbo console.info" })
vim.keymap.set(turbo_modes, "<leader>vb", function() turbo().insert("debug") end, { desc = "Turbo console.debug" })
vim.keymap.set(turbo_modes, "<leader>vt", function() turbo().insert("table") end, { desc = "Turbo console.table" })
vim.keymap.set(turbo_modes, "<leader>vw", function() turbo().insert("warn") end, { desc = "Turbo console.warn" })
vim.keymap.set(turbo_modes, "<leader>ve", function() turbo().insert("error") end, { desc = "Turbo console.error" })
vim.keymap.set(turbo_modes, "<leader>vk", function() turbo().insert("custom") end, { desc = "Turbo custom log" })

vim.keymap.set("n", "<leader>vC", function() turbo().comment_all() end, { desc = "Turbo comment all logs" })
vim.keymap.set("n", "<leader>vU", function() turbo().uncomment_all() end, { desc = "Turbo uncomment all logs" })
vim.keymap.set("n", "<leader>vD", function() turbo().delete_all() end, { desc = "Turbo delete all logs" })
vim.keymap.set("n", "<leader>vX", function() turbo().correct_all() end, { desc = "Turbo correct all logs" })

vim.keymap.set("n", "<leader>vp", function() turbo().panel() end, { desc = "Turbo log panel" })
vim.keymap.set("n", "<leader>vf", function() turbo().find() end, { desc = "Turbo find logs" })
```

## Usage

### Insert a log

Place the cursor on a variable or select an expression, then use a keymap or `:TurboLogInsertLog`.

### Bulk operations (current buffer)

| Action | Default keymap | Command |
|---|---|---|
| Comment all logs | `<leader>vC` | `:TurboLogCommentAll` |
| Uncomment all logs | `<leader>vU` | `:TurboLogUncommentAll` |
| Delete all logs | `<leader>vD` | `:TurboLogDeleteAll` |
| Correct all logs | `<leader>vX` | `:TurboLogCorrectAll` |

### Log panel

Open with `<leader>vp` or `:TurboLogPanel`. Bottom split UI (similar to LazyVim `<leader>xx` diagnostics).

| Key | Action |
|---|---|
| `<CR>` / `l` | Jump to log location |
| `d` | Delete log |
| `c` | Comment log |
| `u` | Uncomment log |
| `x` | Correct log |
| `/` | Filter by text or filename |
| `q` | Close panel |

## Configuration

```lua
require("turbo-log").setup({
  wrapLogMessage = true,
  setup_keymaps = true,
  panel = {
    height = 0.3,
    scope = "git_root", -- "git_root" | "cwd"
  },
})
```

## License

MIT
