return {
  { -- You can easily change to a different colorscheme.
    -- Change the name of the colorscheme plugin below, and then
    -- change the command in the config to whatever the name of that colorscheme is.
    --
    -- If you want to see what colorschemes are already installed, you can use `:Telescope colorscheme`.
    'ellisonleao/gruvbox.nvim',
    priority = 1000, -- Make sure to load this before all the other start plugins.
    init = function()
      -- Load the colorscheme here.
      -- Like many other themes, this one has different styles, and you could load
      vim.o.background = 'dark'
      vim.cmd.colorscheme 'gruvbox'
    end,
    opts = {
      transparent_mode = true,
    },
  },
  {
    'folke/tokyonight.nvim',
    priority = 1000,
    opts = { transparent = true, styles = {
      sidebars = 'transparent',
      floats = 'transparent',
    } },
  },
}
