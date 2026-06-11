local M = {}

M.defaults = {
  logMessagePrefix = "🚀🚀🚀",
  logMessageSuffix = ":",
  delimiterInsideMessage = "~",
  quote = '"',
  includeFilename = true,
  includeLineNum = true,
  insertEnclosingClass = true,
  insertEnclosingFunction = true,
  addSemicolonInTheEnd = false,
  wrapLogMessage = true,
  wrapOffset = 16,
  insertEmptyLineBeforeLogMessage = false,
  insertEmptyLineAfterLogMessage = false,
  logFunction = "log",
  pythonLogger = "logging",
  pythonAutoSetup = true,
  filetypes = {
    javascript = true,
    javascriptreact = true,
    typescript = true,
    typescriptreact = true,
    php = true,
    python = true,
    cs = true,
    csharp = true,
  },
  keymaps = {
    insert = {
      log = { gui = "<D-k><D-l>", fallback = "<leader>Tl" },
      info = { gui = "<D-k><D-i>", fallback = "<leader>Ti" },
      debug = { gui = "<D-k><D-b>", fallback = "<leader>Td" },
      table = { gui = "<D-k><D-t>", fallback = "<leader>Tt" },
      warn = { gui = "<D-k><D-r>", fallback = "<leader>Tw" },
      error = { gui = "<D-k><D-e>", fallback = "<leader>Te" },
      custom = { gui = "<D-k><D-k>", fallback = "<leader>Tc" },
    },
    bulk = {
      comment = { gui = "<A-S-c>", fallback = "<leader>TC" },
      uncomment = { gui = "<A-S-u>", fallback = "<leader>TU" },
      delete = { gui = "<A-S-d>", fallback = "<leader>TD" },
      correct = { gui = "<A-S-x>", fallback = "<leader>TX" },
    },
    panel = { gui = "<D-k><D-p>", fallback = "<leader>Tp" },
    find = { gui = "<D-k><D-f>", fallback = "<leader>Tf" },
  },
  panel = {
    height = 0.3,
    scope = "git_root",
    excluded_dirs = { ".git", "node_modules", "dist", "build", "coverage", ".next", ".turbo", "__pycache__", "vendor" },
  },
  setup_keymaps = true,
}

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
  return M.options
end

function M.get()
  return M.options or M.defaults
end

return M
