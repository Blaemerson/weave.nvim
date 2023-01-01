local M = {}

M._start = 0

function M.get_hl_groups()
  local inspect = vim.inspect_pos()
  local semantic_tokens = inspect["semantic_tokens"]
  local syntax = inspect["syntax"]
  local ts = inspect["treesitter"]

  local groups = {}
  for i = 1, #syntax, 1 do
    table.insert(groups, '@'..syntax[i]['type'] or nil)
  end
  for i = 1, #semantic_tokens, 1 do
    table.insert(groups, '@'..semantic_tokens[i]['type'] or nil)
  end
  for i = 1, #ts, 1 do
    table.insert(groups, ts[i]['hl_group'] or nil)
  end
  return groups
end

function M.get_most_specific_group()
  local groups = M.get_hl_groups()

  local match = nil
  for _, g in pairs(groups) do
    local index = string.find(g, '.', 1, true)
    if index then
      -- match = g:sub(1, index-1)
      match = g
      break
    end
  end

  return match or groups[1]
end

function M.decrement()
  local col = vim.fn.col "."
  local line = vim.api.nvim_get_current_line()
  local ch = string.sub(line, col, col)
  if ch == 'a' then
    -- bump down to 9
    ch = '9'
  elseif ch == '0' or ch == '#' then
    -- do nothing
  else
    -- it's a number
    ch = string.char(string.byte(ch) - 1)
  end
  vim.api.nvim_set_current_line(line:sub(1, col-1) .. ch .. line:sub(col+1))

  -- because nvim_set_current_line doesn't throw this event apparently
  vim.cmd.doautocmd("TextChanged")
end

function M.increment()
  local col = vim.fn.col "."
  local line = vim.api.nvim_get_current_line()
  local ch = string.sub(line, col, col)
  if ch == '9' then
    -- bump up to a
    ch = 'a'
  elseif ch == 'f' or ch == '#' then
    -- do nothing
  else
    -- it's a number
    ch = string.char(string.byte(ch) + 1)
  end
  vim.api.nvim_set_current_line(line:sub(1, col-1) .. ch .. line:sub(col+1))

  -- because nvim_set_current_line doesn't throw this event apparently
  vim.cmd.doautocmd("TextChanged")
end

local convert_to_hex = function(hl_group, attribute)
  vim.pretty_print(string.format("#%x", vim.api.nvim_get_hl_by_name(hl_group, true)[attribute]))
  return string.format("#%x", vim.api.nvim_get_hl_by_name(hl_group, true)[attribute])
end

local create_color_window = function(hl, group)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, #hl, false, {hl})

  local win = vim.api.nvim_open_win(buf, false, {
      relative='cursor', style='minimal', border='rounded', row=-3, col=-4, width=#hl, height=1
  })

  vim.api.nvim_buf_set_option(buf, "modifiable", true)
  vim.api.nvim_win_set_option(win, "sidescrolloff", 0)

  vim.api.nvim_set_current_win(win)

  vim.api.nvim_buf_set_keymap(buf, 'n', 'k', "<CMD>lua require('weave').increment()<CR>", {})
  vim.api.nvim_buf_set_keymap(buf, 'n', 'j', "<CMD>lua require('weave').decrement()<CR>", {})
  vim.api.nvim_buf_set_keymap(buf, 'n', 'q', "<CMD>close<CR>", {silent = true})
  vim.api.nvim_buf_set_keymap(buf, 'n', '<esc>', "<CMD>close<CR>", {silent = true})

  local attr = vim.api.nvim_get_hl_by_name(group, true)

  vim.api.nvim_create_autocmd({"TextChanged", "TextChangedI"}, {buffer = buf, callback = function()
    hl = vim.api.nvim_get_current_line()
    attr['fg'] = hl
    vim.api.nvim_set_hl(0, group, attr)
  end})

  vim.api.nvim_create_autocmd({"BufLeave"}, {buffer = buf, callback = function()
    vim.api.nvim_win_close(win, true)
    vim.api.nvim_buf_delete(buf, {force = true})
  end})
end


function M.toggle_attr(attr)
  local group = M.get_most_specific_group()
  -- local group = M.get_nested_groups(groups)
  -- print(group)
  local hl = vim.api.nvim_get_hl_by_name(group, true)
  hl[attr] = not hl[attr]
  vim.api.nvim_set_hl(0, group, hl)
end

function M.set_color()
  local hl_group = M.get_most_specific_group()

  local old_color = convert_to_hex(hl_group, "foreground")

  create_color_window(old_color, hl_group)
end

local setup_commands = function()
  vim.api.nvim_create_user_command("WeaveGetGroups", "lua vim.pretty_print(require('weave').get_hl_groups())", {})
  vim.api.nvim_create_user_command("WeaveSetColor", "lua require('weave').set_color()", {})
  vim.api.nvim_create_user_command("WeaveToggleBold", "lua require('weave').toggle_attr('bold')", {})
  vim.api.nvim_create_user_command("WeaveToggleItalic", "lua require('weave').toggle_attr('italic')", {})
  vim.api.nvim_create_user_command("WeaveToggleUnderline", "lua require('weave').toggle_attr('underline')", {})
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

  setup_commands()

  print(vim.loop.hrtime() - start_time)
end

return M
