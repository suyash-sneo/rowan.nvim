local plenary = vim.env.PLENARY_DIR or vim.fn.stdpath('data') .. '/plugged/plenary.nvim'
vim.opt.rtp:prepend(plenary)
vim.opt.rtp:prepend('.')
vim.cmd('runtime plugin/plenary.vim')
