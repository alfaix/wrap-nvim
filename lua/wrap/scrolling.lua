local config = require'wrap.config'
local M = {}

local function should_smooth(opts)
	if not opts.smooth then
		return false
	end
	if opts.smooth == true then
			if not config.HAS_NEOSCROLL then
				error("neoscroll.nvim dependency is required for smooth scrolling")
			end
			return true
	end

	return config.HAS_NEOSCROLL
end

local function instant_scroll(window, nlines, opts)
	local command = ""
	-- order matters, g* first, C-* second
	if nlines < 0 then
		if opts.with_cursor then
			command = command .. "gk"
		end
		command = tostring(math.abs(nlines)) .. "<C-Y>"
	else
		if opts.with_cursor then
			command = command .. "gj"
		end
		command = tostring(nlines) .. "<C-E>"
	end
	window:feednormal(command)
end

function M.do_scroll(window, nlines, opts)
	if nlines == 0 then return end
	local smooth = should_smooth(opts)
	if smooth then
		local neoscroll = require'neoscroll'
		neoscroll.scroll_win(
			window.winid, nlines, opts.with_cursor, opts.ms_per_line * math.abs(nlines)
		)
	else
		instant_scroll(window, nlines, opts)
	end
end

return M
