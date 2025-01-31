local M = {}

local function copy_breadcrumbs()
  local lsp_clients = vim.lsp.get_clients({ bufnr = 0 }) -- Limit to the current buffer
  local pyright_active = false

  for _, client in ipairs(lsp_clients) do
    if client.name == "pyright" then
      pyright_active = true
      break
    end
  end

  if not pyright_active then
    vim.notify("Pyright is not active", vim.log.levels.WARN)
    return
  end

  local current_file = vim.fn.expand("%:p") -- Full path to the file
  local relative_file = vim.fn.fnamemodify(current_file, ":~:.") -- Get the relative path

  -- Convert the path to Python module format
  local python_module = relative_file:gsub("/", "."):gsub("%.py$", "")

  local params = vim.lsp.util.make_position_params()

  vim.lsp.buf_request(0, "textDocument/documentSymbol", params, function(err, result, _, _)
    if err or not result then
      vim.notify("Failed to fetch symbols", vim.log.levels.ERROR)
      return
    end

    local cursor_pos = params.position

    -- Function to recursively search for the symbol under the cursor
    local function find_symbol(symbols)
      for _, symbol in ipairs(symbols) do
        -- Only interested in classes, methods and functions
        if symbol.range and symbol.name and (symbol.kind == 5 or symbol.kind == 6 or symbol.kind == 12) then
          local start = symbol.range.start
          local stop = symbol.range["end"]

          if cursor_pos.line >= start.line and cursor_pos.line <= stop.line then
            if symbol.children then
              -- Recursively search children for methods inside classes
              local child_symbol = find_symbol(symbol.children)
              if child_symbol then
                return symbol.name .. "." .. child_symbol
              end
            end
            return symbol.name
          end
        end
      end
      return nil
    end

    local symbol_path = find_symbol(result)

    if not symbol_path then
      vim.notify("No symbol found under cursor", vim.log.levels.WARN)
      return
    end

    local full_location = string.format("%s.%s", python_module, symbol_path)
    vim.fn.setreg("+", full_location) -- Copy to system clipboard
    vim.notify("Copied to clipboard: " .. full_location, vim.log.levels.INFO)
  end)
end

function M.setup(opts)
  opts = opts or {}
  opts.keymap = opts.keymap or "<leader>cb"

  vim.api.nvim_create_user_command("CopyBreadcrumbs", copy_breadcrumbs, {})

  vim.keymap.set(
    "n",
    opts.keymap,
    ":CopyBreadcrumbs<CR>",
    { noremap = true, silent = true, desc = "Copy Python Breadcrumbs" }
  )
end

return M
