local M = {}

local SymbolKind = vim.lsp.protocol.SymbolKind
local wanted_kinds = { [SymbolKind.Class] = true, [SymbolKind.Method] = true, [SymbolKind.Function] = true }

-- Recursively build the dotted path of the class/method/function enclosing the 0-based line
local function find_symbol(symbols, line)
  for _, symbol in ipairs(symbols or {}) do
    local range = symbol.range
    if wanted_kinds[symbol.kind] and range and range.start.line <= line and line <= range["end"].line then
      local child = find_symbol(symbol.children, line)
      return child and (symbol.name .. "." .. child) or symbol.name
    end
  end
end

local function copy_breadcrumbs()
  local bufnr = vim.api.nvim_get_current_buf()
  local client = vim.lsp.get_clients({ bufnr = bufnr, name = "pyright" })[1]
  if not client then
    vim.notify("Pyright is not active", vim.log.levels.WARN)
    return
  end

  local relative_file = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":~:.")
  -- Convert the path to Python module format
  local python_module = relative_file:gsub("/", "."):gsub("%.py$", "")
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1] - 1
  local params = { textDocument = vim.lsp.util.make_text_document_params(bufnr) }

  client:request("textDocument/documentSymbol", params, function(err, result)
    if err or not result then
      vim.notify("Failed to fetch symbols", vim.log.levels.ERROR)
      return
    end

    local symbol_path = find_symbol(result, cursor_line)
    if not symbol_path then
      vim.notify("No symbol found under cursor", vim.log.levels.WARN)
      return
    end

    local full_location = python_module .. "." .. symbol_path
    vim.fn.setreg("+", full_location) -- Copy to system clipboard
    vim.notify("Copied to clipboard: " .. full_location, vim.log.levels.INFO)
  end, bufnr)
end

function M.setup(opts)
  local keymap = (opts or {}).keymap or "<leader>cb"

  vim.api.nvim_create_user_command("CopyBreadcrumbs", copy_breadcrumbs, {})
  vim.keymap.set("n", keymap, copy_breadcrumbs, { desc = "Copy Python Breadcrumbs" })
end

return M
