---@diagnostic disable: assign-type-mismatch
-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

vim.pack.add {
  { src = 'https://github.com/nvim-neo-tree/neo-tree.nvim', version = vim.version.range '*' },
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/MunifTanjim/nui.nvim',
}

vim.keymap.set('n', '\\', '<Cmd>Neotree reveal<CR>', { desc = 'NeoTree reveal', silent = true })
require('neo-tree').setup {
  filesystem = {
    use_libuv_file_watcher = true,
    window = {
      mappings = {
        ['«'] = 'close_window',
        ['<space>'] = 'none',
        ['<esc>'] = {
          function() vim.cmd 'wincmd l' end,
          desc = 'Back to editor',
        },
        ['o'] = {
          function(state)
            local node = state.tree:get_node()
            if not node then return end
            local path = node:get_id()
            local lower_path = path:lower()

            -- Image and video extensions to open in Preview/QuickTime
            if
              lower_path:match '%.jpg$'
              or lower_path:match '%.jpeg$'
              or lower_path:match '%.png$'
              or lower_path:match '%.gif$'
              or lower_path:match '%.webp$'
              or lower_path:match '%.mp4$'
              or lower_path:match '%.mov$'
              or lower_path:match '%.quicktime$'
            then
              vim.fn.system { 'open', path }
            else
              -- For other files, open them in the editor
              vim.cmd('edit ' .. path)
            end
          end,
          desc = 'Open file / image in Preview',
        },
        ['Y'] = {
          function(state)
            local node = state.tree:get_node()
            if not node then return end
            local name = vim.fn.fnamemodify(node:get_id(), ':t')
            vim.fn.setreg('+', name)
            vim.notify('Copied: ' .. name)
          end,
          desc = 'Copy filename',
        },
        ['gy'] = {
          function(state)
            local node = state.tree:get_node()
            if not node then return end
            local path = node:get_id()
            vim.fn.setreg('+', path)
            vim.notify('Copied: ' .. path)
          end,
          desc = 'Copy full path',
        },
      },
    },
    filtered_items = {
      visible = true,
      hide_dotfiles = false,
      hide_gitignored = false,
    },
  },
}
