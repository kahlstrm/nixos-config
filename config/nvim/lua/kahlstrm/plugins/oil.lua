return {
  'stevearc/oil.nvim',
  ---@module 'oil'
  ---@type oil.SetupOpts
  opts = {
    keymaps = {
      ['cd'] = { 'actions.cd', mode = 'n' },
      ['<leader>e'] = { 'actions.close', mode = 'n' },
      ['<C-h>'] = false,
      ['<C-l>'] = false,
      ['<C-r>'] = 'actions.refresh',
    },
  },
  -- Optional dependencies
  -- dependencies = { { 'echasnovski/mini.icons', opts = {} } },
  dependencies = { 'nvim-tree/nvim-web-devicons' }, -- use if prefer nvim-web-devicons
}
