if( GetLocale() ~= "deDE" ) then
	return;
end

ArenaIgnoreLocals = setmetatable( {
}, { __index = ArenaIgnoreLocals } );