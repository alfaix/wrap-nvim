local Window = {}
local classes = require 'wrap.classutils'
local utils = require 'wrap.utils'

-- if local option returns this value, return the global value instead
local _unset_local_option = {scrolloff = -1}

local function withid(fn)
  return function(window, ...) return fn(window.winid, ...) end
end

-- property name = function(winid) -> result
local proptable = {
  active = function(win) return win == Window:this() end,
  config = withid(vim.api.nvim_win_get_config),
  options = function(win)
    win.options = classes.helper_dict:new(win.winid, {
      getter = vim.api.nvim_win_get_option,
      setter = vim.api.nvim_win_set_option,
      fallback = function(key, localvalue)
        if _unset_local_option[key] == localvalue then
          return vim.api.nvim_get_option_value(key, {scope = "global"})
        end
      end
    })
    return win.options
  end,

  buffer = function(win)
    local Buffer = require 'wrap.buffer'
    return Buffer:new(vim.api.nvim_win_get_buf(win.winid))
  end,

  height = withid(vim.api.nvim_win_get_height),
  width = withid(vim.api.nvim_win_get_width),
  topline = function(win) return vim.fn.line("w0", win.winid) end,
  bottomline = function(win) return vim.fn.line("w$", win.winid) end,
  winline = function(win) return win:run_inside(vim.fn.winline) end,
  cursor = function(win)
    -- everything is 1-indexed
    local r, c = unpack(vim.api.nvim_win_get_cursor(win.winid))
    return {r, c + 1}
  end,
  type = withid(vim.fn.win_gettype),
  numlines = function(win) return win.getlinenr("$") end
}

local setproptable = {
  config = withid(vim.api.nvim_win_set_config),
  buffer = function(win, buf)
    if type(buf) == type({}) then buf = buf.bufid end
    vim.api.nvim_win_set_buf(win.winid, buf)
  end,

  vheight = withid(vim.api.nvim_win_set_height),
  vwidth = withid(vim.api.nvim_win_set_width),

  cursor = withid(vim.api.nvim_win_set_cursor)
}

function Window:__eq(other)
  return (self.winid == other.winid or
             (self.winid == 0 and other.winid == Window:current().winid) or
             (other.winid == 0 and self.winid == Window:current().winid))
end

function Window:new(winid)
  assert(type(winid) == type(0) and winid >= 0,
         "winid must be a non-negative integer")
  local obj = {winid = winid}
  classes.setproptables(self, proptable, setproptable)
  setmetatable(obj, self)
  return obj
end

function Window:current() return Window:new(vim.fn.win_getid()) end

function Window:this() return Window:new(0) end

-- Lists all windows of type `typ` on `tabpage`.
-- Returns: Array (table) of Window-s that passed the filter
function Window:list(tabpage, typ)
  assert(typ == nil or type(typ) == type(""),
         "Expected type to be string, got " .. type(typ) .. " instead")

  local winids
  if tabpage == nil then
    winids = vim.api.nvim_list_wins()
  else
    assert(type(tabpage) == type(0) and tabpage >= 0,
           "Tabpage must be nil or a non-negative integer")
    winids = vim.api.nvim_tabpage_list_wins(tabpage)
  end

  local popup_windows = {}
  for _, winid in pairs(winids) do
    local win = Window:new(winid)
    if typ == nil or win.type == typ then
      popup_windows[#popup_windows + 1] = win
    end
  end

  return popup_windows
end

function Window:exists() return vim.api.nvim_win_is_valid(self.winid) end

function Window:close(force) vim.api.nvim_win_close(self.winid, force) end

function Window:run_inside(fn)
  if self.active then
    return fn()
  else
    return vim.api.nvim_win_call(self.winid, fn)
  end
end

function Window:command_inside(command, opts)
  local defaults = {output = false}
  opts = utils.defaultopts(opts, defaults)
  if type(command) == type("") then
    command = vim.api.nvim_parse_cmd(command, {})
  end
  return self:run_inside(function() return vim.api.nvim_cmd(command, opts) end)
end

function Window:scroll(nlines, opts)
  local defaults = {with_cursor = true, ms_per_line = 6, smooth = "auto"}
  opts = utils.defaultopts(opts, defaults)
  if utils.is_float(nlines) then
    -- floor rounds towards negative infinity - we want +-0.5 to be the same
    nlines = utils.floor_towards_zero(nlines * self.height)
  end
  require'wrap.scrolling'.do_scroll(self, nlines, opts)
end

function Window:feedkeys(keys, opts)
  self:run_inside(function() require 'wrap.nvim':feedkeys(keys, opts) end)
end

function Window:feednormal(keys, opts)
  self:run_inside(function() require 'wrap.nvim':feednormal(keys, opts) end)
end

function Window:activate() vim.fn.win_gotoid(self.winid) end

return Window
