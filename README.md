# Copy Breadcrumbs Plugin

This plugin copies the breadcrumbs of the python symbol under the cursor to the system clipboard for use with the [unittest](https://docs.python.org/3/library/unittest.html) framework.
For example:
```sh
python -m unittest <copied breadcrumbs>
```
Requires the pyright LSP.

## Installation

To install this plugin with LazyVim, add the following to your configuration (e.g., `lua/plugins/copybreadcrumbs.lua`):

```lua
return {
  {
    "jjvanvuren/copybreadcrumbs.nvim",
    lazy = true,
    ft = { "python" },
    opts = {}
  },
}
```

## Configuration

The plugin can be configured with the following options:
- `keymap` (string): Keymap to copy breadcrumbs. Default is `<leader>cb`.

Example configuration:
```lua
return {
  {
    "jjvanvuren/copybreadcrumbs.nvim",
    lazy = true,
    ft = { "python" },
    opts = { keymap = "<leader>bc" }
  },
}
```

## Usage

Use the command `:CopyBreadcrumbs` or the configured keymap.
