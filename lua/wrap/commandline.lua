local Cmdline = {}
local classes = require 'wrap.classutils'

local function nofirstarg(fn) return function(_, ...) return fn(...) end end

local proptable = {
    text = function(_)
        local text = vim.fn.getcmdline()
        if text == "" then return nil end
        return text
    end,
    cmdtype = function(_)
        local typ = vim.fn.getcmdtype()
        if typ == "" then return nil end
        return typ
    end,
    pos = function(_)
        local pos = vim.fn.getcmdpos()
        if pos == 0 then return nil end
        return pos
    end
}

local setproptable = {pos = nofirstarg(vim.fn.setcmdpos)}

function Cmdline:new()
    local obj = {}
    classes.setproptables(self, proptable, setproptable)
    setmetatable(obj, self)
    return obj
end

function Cmdline:set_text(text, pos)
    self._state = {text = text, pos = pos}
    local keys = [[<C-\>ev:lua.require('wrap.commandline')._set_state()<CR>]]
    keys = vim.api.nvim_replace_termcodes(keys, true, true, true)
    vim.api.nvim_feedkeys(keys, "n", false)
end

local _instance = Cmdline:new()

function _instance._set_state()
    local self = _instance
    if self._state.pos ~= nil then vim.fn.setcmdpos(self._state.pos) end
    return self._state.text
end

return _instance
