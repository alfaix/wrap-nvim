local M = {}

function M.default(value, defaultvalue)
	if value == nil then
		return defaultvalue
	end
	return value
end

function M.defaultopts(opts, defaults, recursive)
	if recursive then
		return vim.tbl_deep_extend("force", defaults, opts or {})
	else
		return vim.tbl_extend("force", defaults, opts or {})
	end
end

function M.is_float(value)
	return math.floor(value) ~= value
end

function M.floor_towards_zero(value)
	return value < 0 and math.ceil(value) or math.floor(value)
end

return M
