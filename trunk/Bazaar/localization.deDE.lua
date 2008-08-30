if( GetLocale() ~= "deDE" ) then
	return
end

BazaarLocals = setmetatable({
}, {__index = BazaarLocals})