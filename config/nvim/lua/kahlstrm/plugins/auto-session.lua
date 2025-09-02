return {
  'rmagatti/auto-session',
  lazy = false,

  ---enables autocomplete for opts
  ---@module "auto-session"
  ---@type AutoSession.Config
  opts = {
    suppressed_dirs = { '~/', '~/Projects', '~/Downloads', '/' },
    -- log_level = 'debug',
    use_git_branch = true,
    git_auto_restore_on_branch_change = true,
  },
  keys = {
    { '<leader>ss', '<cmd>SessionSearch<CR>', desc = '[S]earch [S]essions' },
  },
}
