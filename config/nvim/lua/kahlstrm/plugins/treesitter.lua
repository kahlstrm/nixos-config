return {
  -- https://github.com/nvim-treesitter/nvim-treesitter
  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    build = ':TSUpdate',
    main = 'nvim-treesitter',
    init = function()
      local ensure_installed = { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc' }

      vim.api.nvim_create_autocmd('FileType', {
        callback = function(args)
          local max_filesize = 100 * 1024 -- 100 KB
          local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(args.buf))
          if ok and stats and stats.size > max_filesize then
            vim.notify('File larger than 100KB treesitter disabled for performance', vim.log.levels.WARN, { title = 'Treesitter' })
            return
          end
          pcall(vim.treesitter.start)
          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })

      local installed = require('nvim-treesitter.config').get_installed()
      local to_install = vim.iter(ensure_installed)
        :filter(function(p) return not vim.tbl_contains(installed, p) end)
        :totable()
      if #to_install > 0 then
        require('nvim-treesitter').install(to_install)
      end
    end,
  },
  -- https://github.com/nvim-treesitter/nvim-treesitter-context
  {
    'nvim-treesitter/nvim-treesitter-context',
    opts = {
      multiline_threshold = 1,
      max_lines = 5,
      trim_scope = 'inner',
      on_attach = function()
        vim.cmd 'hi TreesitterContextBottom gui=underline guisp=Grey'
      end,
    },
  },
}
