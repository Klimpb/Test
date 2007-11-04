if( GetLocale() ~= "deDE" ) then
	return
end

DamnTBLocals = setmetatable({
}, {__index = DamnTBLocals})