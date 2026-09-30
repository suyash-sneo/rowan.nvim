local M = {}

M.subcommands = {
  on = {
    desc = 'Treat this buffer as a rowan note',
    run = function()
      vim.bo.filetype = 'rowan'
    end,
  },
  off = {
    desc = 'Back to plain text',
    run = function()
      vim.bo.filetype = 'text'
    end,
  },
  renumber = {
    desc = 'Renumber [n] references by first use',
    run = function()
      require('rowan.ref').renumber()
    end,
  },
  keys = {
    desc = 'Show all rowan keys',
    run = function()
      require('rowan.cheatsheet').open()
    end,
  },
}

function M.names()
  local names = vim.tbl_keys(M.subcommands)
  table.sort(names)
  return names
end

function M.complete(arglead)
  return vim.tbl_filter(function(name)
    return vim.startswith(name, arglead)
  end, M.names())
end

function M.run(name)
  local sub = M.subcommands[name or 'on']
  if not sub then
    vim.notify('Rowan: unknown subcommand ' .. name, vim.log.levels.ERROR)
    return
  end
  sub.run()
end

return M
