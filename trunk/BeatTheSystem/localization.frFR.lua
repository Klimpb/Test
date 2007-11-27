if( GetLocale() ~= "frFR" ) then
	return;
end

ArenaIgnoreLocals = setmetatable( {

}, { __index = ArenaIgnoreLocals } );

