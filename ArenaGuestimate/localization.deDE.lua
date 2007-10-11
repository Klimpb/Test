if( GetLocale() ~= "deDE" ) then
	return;
end

ArenaGuessLocals = setmetatable( {
}, { __index = ArenaGuessLocals } );