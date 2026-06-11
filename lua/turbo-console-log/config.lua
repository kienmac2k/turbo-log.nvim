local M = {}

M.defaults = {
  logMessagePrefix = "🚀",
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
  filetypes = {
    javascript = true,
    javascriptreact = true,
    typescript = true,
    typescriptreact = true,
    php = true,
    python = true,
  },
  keymaps = {
    insert = {
      log = { gui = "<D-k><D-l>", fallback = "<leader>vl" },
      info = { gui = "<D-k><D-n>", fallback = "<leader>vn" },
      debug = { gui = "<D-k><D-b>", fallback = "<leader>vb" },
      table = { gui = "<D-k><D-t>", fallback = "<leader>vt" },
      warn = { gui = "<D-k><D-r>", fallback = "<leader>vw" },
      error = { gui = "<D-k><D-e>", fallback = "<leader>ve" },
      custom = { gui = "<D-k><D-k>", fallback = "<leader>vk" },
    },
    bulk = {
      comment = { gui = "<A-S-c>", fallback = "<leader>vC" },
      uncomment = { gui = "<A-S-u>", fallback = "<leader>vU" },
      delete = { gui = "<A-S-d>", fallback = "<leader>vD" },
      correct = { gui = "<A-S-x>", fallback = "<leader>vX" },
    },
    panel = { gui = "<D-k><D-p>", fallback = "<leader>vp" },
    find = { gui = "<D-k><D-f>", fallback = "<leader>vf" },
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
