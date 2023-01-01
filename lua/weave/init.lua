local M = {}

function M.setup()
  -- To check how long everything takes to setup
  local start_time = vim.loop.hrtime()

  if vim.g.weave_did_setup then
    return vim.notify(
      "weave.nvim has already been set up",
      vim.log.levels.WARN,
      { title = "weave.nvim" }
    )
  end

  vim.g.weave_did_setup= true

  if vim.fn.has("nvim-0.8.0") ~= 1 then
    return vim.notify(
      "Neovim 0.8.0+ required",
      vim.log.levels.ERROR,
      { title = "weave.nvim" }
    )
  end

  print(vim.loop.hrtime() - start_time)
end

return M
