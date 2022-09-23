local Buffer = {}

-- nvim complains if colstop is larger than this
Buffer.MAX_INDEX = math.pow(2, 31) - 2

local classes = require 'wrap.classutils'

local function withid(fn)
  return function(buffer, ...) return fn(buffer.bufid, ...) end
end

local Text = {}
function Text:new(buffer)
  local obj = {bufid = buffer.bufid}
  setmetatable(obj, self)
  return obj
end

-- 2 cases:
-- 1. full lines - rows are end-exclusive, keep them that way
-- 2. partial lines - rows are end-inclusive, columns are end-exclusive, must be always end-exclusive
-- All is 1-indexed to be consistent with vim.fn.line(). We want 0-indexed to
-- forward it to nvim API.
local function _convpos(pos)
  pos = pos or {}
  if pos.start and pos.stop and pos.start >= pos.stop then return nil end
  local colstart, colstop
  if pos.colstart then
    colstart = math.max(0, pos.colstart - 1)
  else
    colstart = 0
  end

  if pos.colstop then
    colstop = math.max(0, pos.colstop - 1)
  else
    colstop = Buffer.MAX_INDEX
  end

  local start, stop
  if pos.start then
    start = math.max(0, pos.start - 1)
  else
    start = 0
  end

  if pos.stop and pos.stop ~= Buffer.MAX_INDEX then
    if colstart == 0 and colstop == Buffer.MAX_INDEX then
      stop = math.max(0, pos.stop - 1)
    else
      stop = math.max(0, pos.stop - 2)
    end
  else
    stop = Buffer.MAX_INDEX
  end
  return {start = start, stop = stop, colstart = colstart, colstop = colstop}
end

-- Returns a list of lines corresponding to positions `pos`
-- param pos: a table with the following fields:
--   - start: the line number to start from (inclusive)
--   - stop: the line number to stop at (exclusive)
--   - colstart: the column number to start from (inclusive)
--   - colstop: the column number to stop at (exclusive)
-- All fields are 1-indexed to be consistent with vim.fn.line().
-- If either start or colstart are missing, they are set to 1.
-- If either stop or colstop are missing, they are set to Buffer.MAX_INDEX.

function Text:slice(pos, strict)
  pos = _convpos(pos)
  if pos == nil then return {} end
  if pos.colstart == 0 and pos.colstop == Buffer.MAX_INDEX then
    return vim.api.nvim_buf_get_lines(self.bufid, pos.start, pos.stop,
                                      strict or false)
  else
    return vim.api.nvim_buf_get_text(self.bufid, pos.start, pos.colstart,
                                     pos.stop, pos.colstop, {})
  end
end

function Text:__index(idx)
  local cls = getmetatable(self)
  if cls[idx] ~= nil then return cls[idx] end
  if type(idx) == type(0) then
    local line = self:slice({start = idx, stop = idx + 1})
    if #line ~= 1 then error("Line " .. idx .. " not found") end
    return line[1]
  end
end

local proptable = {
  text = function(buf) return Text:new(buf) end,
  numlines = withid(vim.api.nvim_buf_line_count),
  active = function(buf) return buf == Buffer:this() end,
  options = function(buf)
    buf.options = classes.helper_dict:new(buf.bufid, {
      getter = vim.api.nvim_buf_get_option,
      setter = vim.api.nvim_buf_set_option
    })
    return buf.options
  end,
  vars = function(buf)
    buf.vars = classes.helper_dict:new(buf.bufid, {
      getter = function(bufid, varname)
        local ok, result = pcall(vim.api.nvim_buf_get_var, bufid, varname)
        if not ok then
          return nil
        else
          return result
        end
      end,
      setter = vim.api.nvim_buf_set_var
    })
    return buf.vars
  end,
  window = function(buf)
    local Window = require 'wrap.window'
    return Window:new(vim.fn.bufwinid(buf.bufid))
  end,
  name = withid(vim.api.nvim_buf_get_name),
  valid = withid(vim.api.nvim_buf_is_valid),
  loaded = withid(vim.api.nvim_buf_is_loaded),
  uri = withid(vim.uri_from_bufnr)
}

function Buffer:__eq(other)
  return (self.bufid == other.bufid or
             (self.bufid == 0 and other.bufid == Buffer:current().bufid) or
             (other.bufid == 0 and self.bufid == Buffer:current().bufid))
end

function Buffer:create(listed, scratch)
  return Buffer:new(vim.api.nvim_create_buf(listed, scratch))
end

function Buffer:new(bufid)
  assert(type(bufid) == type(0) and bufid >= 0,
         "bufid must not be non-negative number")
  local obj = {bufid = bufid}
  classes.setproptables(self, proptable)
  setmetatable(obj, self)
  return obj
end

function Buffer:current() return Buffer:new(vim.api.nvim_get_current_buf()) end

function Buffer:this() return Buffer:new(0) end

function Buffer:run_inside(fn)
  if self.active then
    return fn()
  else
    return vim.api.nvim_buf_call(self.bufid, fn)
  end

end

return Buffer
