if( GetLocale() ~= "deDE" ) then
	return
end

BishopLocals = setmetatable({
}, {__index = BishopLocals})