local config = require("turbo-log.config")

local M = {}

local function delimiter_spaced(delimiter)
  return string.format(" %s ", delimiter)
end

local function select_quote(quote, var)
  if quote == "`" and var:find("[%[%]]") then
    return '"'
  end
  return quote
end

function M.build_message_parts(opts, ctx, var, log_line)
  local parts = {}
  local delim = delimiter_spaced(opts.delimiterInsideMessage)

  if opts.logMessagePrefix and opts.logMessagePrefix ~= "" then
    parts[#parts + 1] = opts.logMessagePrefix
    parts[#parts + 1] = delim
  end

  if opts.includeFilename or opts.includeLineNum then
    local file_part = opts.includeFilename and ctx.filename or ""
    local line_part = opts.includeLineNum and log_line and (":" .. tostring(log_line)) or ""
    parts[#parts + 1] = file_part .. line_part
    parts[#parts + 1] = delim
  end

  if opts.insertEnclosingClass and ctx.class_name and ctx.class_name ~= "" then
    parts[#parts + 1] = ctx.class_name
    parts[#parts + 1] = delim
  end

  if opts.insertEnclosingFunction and ctx.function_name and ctx.function_name ~= "" then
    parts[#parts + 1] = ctx.function_name
    parts[#parts + 1] = delim
  end

  parts[#parts + 1] = var
  parts[#parts + 1] = opts.logMessageSuffix

  return table.concat(parts, "")
end

function M.build_js_line(method, var, ctx, log_line)
  local opts = config.get()
  local quote = select_quote(opts.quote, var)
  local message = M.build_message_parts(opts, ctx, var, log_line)
  local semicolon = opts.addSemicolonInTheEnd and ";" or ""
  local log_fn = method == "custom" and ("console." .. opts.logFunction) or ("console." .. method)

  if method == "table" then
    return string.format("%s(%s%s%s, %s)%s", log_fn, quote, message, quote, var, semicolon)
  end

  return string.format("%s(%s%s%s, %s)%s", log_fn, quote, message, quote, var, semicolon)
end

function M.build_php_line(method, var, ctx, log_line)
  local opts = config.get()
  local quote = select_quote(opts.quote, var)
  local message = M.build_message_parts(opts, ctx, var, log_line)
  local semicolon = opts.addSemicolonInTheEnd and ";" or ""

  local fn = ({
    log = "error_log",
    info = "error_log",
    debug = "var_dump",
    table = "print_r",
    warn = "error_log",
    error = "error_log",
    custom = opts.logFunction or "error_log",
  })[method] or "error_log"

  if fn == "var_dump" then
    return string.format("%s(%s)%s", fn, var, semicolon)
  end
  if fn == "print_r" then
    return string.format("%s(%s, true)%s", fn, var, semicolon)
  end

  return string.format('%s(%s%s%s . print_r(%s, true))%s', fn, quote, message, quote, var, semicolon)
end

local function python_log_fn(method)
  local opts = config.get()
  local logger = opts.pythonLogger or "logging"
  if method == "custom" then
    return logger .. "." .. (opts.logFunction or "info")
  end
  local level = ({
    log = "info",
    info = "info",
    debug = "debug",
    warn = "warning",
    error = "error",
  })[method] or "info"
  return logger .. "." .. level
end

local function escape_py_format(message)
  return (message:gsub("%%", "%%%%"))
end

function M.build_python_line(method, var, ctx, log_line)
  local opts = config.get()
  local quote = select_quote(opts.quote, var)
  local message = escape_py_format(M.build_message_parts(opts, ctx, var, log_line))

  if method == "table" then
    local fn = python_log_fn("log")
    return string.format('%s("%%s\\n%%s", "%s", __import__("pprint").pformat(%s))', fn, message, var)
  end

  local fn = python_log_fn(method)
  if quote == '"' then
    return string.format('%s("%%s %%r", "%s", %s)', fn, message, var)
  elseif quote == "'" then
    return string.format("%s('%%s %%r', '%s', %s)", fn, message, var)
  end
  return string.format('%s("%%s %%r", %s%s%s, %s)', fn, quote, message, quote, var)
end

local function js_log_fn(method)
  local opts = config.get()
  if method == "custom" then
    return "console." .. opts.logFunction
  end
  return "console." .. method
end

local function escape_csharp_interp(message)
  return (message:gsub("{", "{{"):gsub("}", "}}"))
end

local function csharp_log_fn(method)
  local opts = config.get()
  if method == "custom" then
    local fn = opts.logFunction or "WriteLine"
    if fn:find("%.") then
      return fn
    end
    return "Console." .. fn
  end
  local fns = {
    log = "Console.WriteLine",
    info = "Console.WriteLine",
    debug = "System.Diagnostics.Debug.WriteLine",
    warn = "Console.WriteLine",
    error = "Console.Error.WriteLine",
  }
  return fns[method] or "Console.WriteLine"
end

function M.build_csharp_line(method, var, ctx, log_line)
  local opts = config.get()
  local message = escape_csharp_interp(M.build_message_parts(opts, ctx, var, log_line))
  local fn = csharp_log_fn(method)
  local semicolon = ";"

  if method == "table" then
    return string.format(
      '%s($"%s\\n{System.Text.Json.JsonSerializer.Serialize(%s)}")%s',
      fn,
      message,
      var,
      semicolon
    )
  end

  return string.format('%s($"%s {%s}")%s', fn, message, var, semicolon)
end

function M.build_separator_line(method, content_line, ft)
  local opts = config.get()
  local quote = select_quote(opts.quote, "")
  local semicolon = opts.addSemicolonInTheEnd and ";" or ""
  local offset = opts.wrapOffset or 16
  local dash_count = math.max(1, #content_line - offset)
  local inner = string.format("%s %s%s", opts.logMessagePrefix, string.rep("-", dash_count), opts.logMessagePrefix)

  if ft == "python" then
    local fn = python_log_fn(method == "table" and "log" or method)
    if quote == '"' then
      return string.format('%s("%%s", "%s")', fn, escape_py_format(inner))
    end
    return string.format("%s('%%s', '%s')", fn, escape_py_format(inner))
  end

  if ft == "php" then
    return string.format('error_log("%s");', inner)
  end

  if ft == "cs" or ft == "csharp" then
    local fn = csharp_log_fn(method == "table" and "log" or method)
    return string.format('%s($"%s")%s', fn, escape_csharp_interp(inner), ";")
  end

  return string.format("%s(%s%s%s)%s", js_log_fn(method), quote, inner, quote, semicolon)
end

local function is_csharp(ft)
  return ft == "cs" or ft == "csharp"
end

function M.build_lines(method, var, ctx, log_line, ft)
  local content
  if ft == "python" then
    content = M.build_python_line(method, var, ctx, log_line)
  elseif ft == "php" then
    content = M.build_php_line(method, var, ctx, log_line)
  elseif is_csharp(ft) then
    content = M.build_csharp_line(method, var, ctx, log_line)
  else
    content = M.build_js_line(method, var, ctx, log_line)
  end

  local opts = config.get()
  if not opts.wrapLogMessage then
    return { content }
  end

  local separator = M.build_separator_line(method, content, ft)
  return { separator, content, separator }
end

return M
