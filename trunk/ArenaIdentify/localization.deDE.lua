if( GetLocale() ~= "deDE" ) then
	return
end

ArenaIdentLocals = setmetatable({
}, { __index = ArenaIdentLocals})