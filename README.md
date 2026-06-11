# turbo-log.nvim

A Neovim plugin that replicates the [Turbo Console Log](https://marketplace.visualstudio.com/items?itemName=ChakrounAnas.turbo-console-log) VS Code extension — including log message formatting, bulk operations, and a workspace log panel.

**Supported languages:** JavaScript, TypeScript, JSX/TSX, PHP, Python, C#

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
    config = true,
  },
}
```

Default keymaps are registered on setup (`setup_keymaps = true`). On LazyVim, `<leader>T*` avoids `<leader>c*` (LSP/code) and `<leader>t*` (testing).

## Keymaps

Registered automatically when `setup_keymaps` is `true` (default). Works in normal and visual mode for insert bindings.

| Action | Keymap | Command |
|---|---|---|
| Insert log | `<leader>Tl` | `:TurboLogInsertLog` |
| Insert info | `<leader>Ti` | `:TurboLogInsertInfo` |
| Insert debug | `<leader>Td` | `:TurboLogInsertDebug` |
| Insert table | `<leader>Tt` | `:TurboLogInsertTable` |
| Insert warn | `<leader>Tw` | `:TurboLogInsertWarn` |
| Insert error | `<leader>Te` | `:TurboLogInsertError` |
| Insert custom | `<leader>Tc` | `:TurboLogInsertCustom` |
| Comment all logs | `<leader>TC` | `:TurboLogCommentAll` |
| Uncomment all logs | `<leader>TU` | `:TurboLogUncommentAll` |
| Delete all logs | `<leader>TD` | `:TurboLogDeleteAll` |
| Correct all logs | `<leader>TX` | `:TurboLogCorrectAll` |
| Log panel | `<leader>Tp` | `:TurboLogPanel` |
| Find logs | `<leader>Tf` | `:TurboLogFind` |

On macOS, GUI chords are also set when available (e.g. `<D-k><D-l>` for log). Terminal fallbacks use the `<leader>T*` bindings above.

Set `setup_keymaps = false` and map `require("turbo-log")` yourself if you prefer custom bindings.

## Usage

### Insert a log

Place the cursor on a variable or select an expression, then use a keymap or `:TurboLogInsertLog`.

### Log panel

Open with `<leader>Tp` or `:TurboLogPanel`. Bottom split UI (similar to LazyVim `<leader>xx` diagnostics).

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
  setup_keymaps = true, -- default; registers <leader>T* keymaps
  keymaps = {
    insert = {
      log = { fallback = "<leader>Tl" },
      info = { fallback = "<leader>Ti" },
      -- override any binding; gui = "<D-k><D-l>" on macOS
    },
  },
  panel = {
    height = 0.3,
    scope = "git_root", -- "git_root" | "cwd"
  },
})
```

## License

MIT
