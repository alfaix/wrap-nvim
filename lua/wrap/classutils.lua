M = {}

function M.setproptables(cls, getproptable, setproptable)
  if getproptable ~= nil then
    cls.__index = function (obj, property)
			if cls[property] ~= nil then
				return cls[property]
			end
			return getproptable[property](obj)
    end
  end

  if setproptable ~= nil then
    cls.__newindex = function (obj, property, value)
      local setter = setproptable[property]
			if setter then
				setter(obj, value)
			else
				rawset(obj, property, value)
			end
    end
  end
end

local HelperDict = {
	__index = function(obj, key)
		local value = obj._getter(obj.objid, key)
		local fallback_value = obj._fallback(key, value)
		if fallback_value ~= nil then
			return fallback_value
		end
		return value
	end,

	__newindex = function(obj, key, value)
		obj._setter(obj.objid, key, value)
	end
}

function HelperDict:new(id, opts)
	local obj = {
		objid = id,
		_getter = opts.getter,
		_setter = opts.setter,
		_fallback = opts.fallback or function() return nil end
	}
	setmetatable(obj, self)
	return obj
end

M.helper_dict = HelperDict

return M
