if( GetLocale() ~= "deDE" ) then
	return
end

SSFlagsLocals = setmetatable({
}, {__index = SSFlagsLocals})