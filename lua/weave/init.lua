local M = {}

local create_color_window = function(hl, groups)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, #hl, false, {hl})

  local win = vim.api.nvim_open_win(buf, false, {
      relative='cursor', style='minimal', border='rounded', row=1, col=-3, width=#hl, height=1
  })

  vim.api.nvim_buf_set_option(buf, "modifiable", true)
  vim.api.nvim_win_set_option(win, "sidescrolloff", 0)

  vim.api.nvim_set_current_win(win)

  vim.api.nvim_buf_set_keymap(buf, 'n', 'k', "<CMD>lua require('weave').increment()<CR>", {})
  vim.api.nvim_buf_set_keymap(buf, 'n', 'j', "<CMD>lua require('weave').decrement()<CR>", {})
  vim.api.nvim_buf_set_keymap(buf, 'n', 'q', "<CMD>close<CR>", {silent = true})
  vim.api.nvim_buf_set_keymap(buf, 'n', '<esc>', "<CMD>close<CR>", {silent = true})

  vim.api.nvim_create_autocmd({"TextChanged", "TextChangedI"}, {buffer = buf, callback = function()
    hl = vim.api.nvim_get_current_line()
    for _, g in pairs(groups) do
      vim.api.nvim_set_hl(0, g, {fg = hl})
    end
  end})

  vim.api.nvim_create_autocmd({"BufLeave"}, {buffer = buf, callback = function()
    vim.api.nvim_win_close(win, true)
    vim.api.nvim_buf_delete(buf, {force = true})
  end})
end
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
