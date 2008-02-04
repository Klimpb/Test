if( GetLocale() ~= "deDE" ) then
	return
end

AlchemyStatLocals = setmetatable({
}, {__index = AlchemyStatLocals})