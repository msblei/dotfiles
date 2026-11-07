-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information

-- Iterate over all Lua files in the plugins directory and load them
local plugins_dir = vim.fs.joinpath(vim.fn.stdpath 'config', 'lua', 'custom', 'plugins')
for file_name, type in vim.fs.dir(plugins_dir, { follow = true }) do
  if (type == 'file' or type == 'link') and file_name:match '%.lua$' and file_name ~= 'init.lua' then
    local module = file_name:gsub('%.lua$', '')
    require('custom.plugins.' .. module)
  end
end
vim.pack.add {
  { src = 'https://github.com/nvim-lua/plenary.nvim' },
  { src = 'https://github.com/kdheepak/lazygit.nvim' },
}

vim.keymap.set('n', '<leader>gg', '<cmd>LazyGit<cr>', { desc = '[G]it [G]UI (lazygit)' })
vim.api.nvim_create_autocmd('TermClose', {
  pattern = '*lazygit*',
  callback = function()
    pcall(function()
      local events = require 'neo-tree.events'
      events.fire_event(events.GIT_EVENT)
    end)
    pcall(function()
      require('gitsigns').refresh()
    end)
  end,
})
vim.api.nvim_create_autocmd('VimEnter', {
  callback = function()
    vim.cmd 'Neotree show'
  end,
})
vim.keymap.set('n', '<leader>sF', function()
  require('telescope.builtin').find_files { hidden = true, no_ignore = true }
end, { desc = '[S]earch all [F]iles (incl. ignored)' })
vim.cmd.colorscheme 'tokyonight-moon'
vim.keymap.set('n', '«', '<Cmd>Neotree reveal<CR>', { desc = 'NeoTree reveal', silent = true })
require('conform').setup {
  formatters_by_ft = {
    json = { 'prettier' },
    jsonc = { 'prettier' },
    javascript = { 'prettier' },
    typescript = { 'prettier' },
    javascriptreact = { 'prettier' },
    typescriptreact = { 'prettier' },
    css = { 'prettier' },
    html = { 'prettier' },
  },
}
-- to auto refresh opened file
vim.opt.autoread = true

vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold' }, {
  callback = function()
    if vim.fn.mode() == 'n' then
      vim.cmd 'checktime'
    end
  end,
})
