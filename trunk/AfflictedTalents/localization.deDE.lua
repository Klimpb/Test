if( GetLocale() ~= "deDE" ) then
	return
end

AfflictedTalentsLocals = setmetatable({
}, { __index = AfflictedTalentsLocals})