local Nvim = {}
local classes = require 'wrap.classutils'
local utils = require 'wrap.utils'

local function nofirstarg(fn) return function(_, ...) return fn(...) end end
local proptable = {
    options = function(nvim)
        nvim.options = classes.helper_dict:new(0, {
            getter = vim.api.nvim_get_option,
            setter = vim.api.nvim_set_option
        })
        return nvim.options
    end,
    mode = nofirstarg(vim.api.nvim_get_mode)
}
local setproptable = {}

function Nvim:new()
    local obj = {}
    classes.setproptables(self, proptable, setproptable)
    setmetatable(obj, self)
    return obj
end

function Nvim:feednormal(keys, opts)
    local defaults = {remap = false, replace_special = true}
    opts = utils.defaultopts(opts, defaults)
    if opts.replace_special then
        keys = vim.api.nvim_replace_termcodes(keys, true, true, true)
    end
    vim.api.nvim_cmd({cmd = "normal", bang = not opts.remap, args = {keys}},
                     {output = false})
end

function Nvim:feedkeys(keys, opts)
    local defaults = {replace_special = true, mode = "n"}
    opts = utils.defaultopts(opts, defaults)
    if opts.replace_special then
        keys = vim.api.nvim_replace_termcodes(keys, true, true, true)
    end
    -- nvim_feedkeys' does NOT escape keys the way you think it does
    -- https://github.com/neovim/neovim/issues/12297
    vim.api.nvim_feedkeys(keys, opts.mode, false)
end

local _instance = Nvim:new()
_instance.commandline = require 'wrap.commandline'

return _instance
