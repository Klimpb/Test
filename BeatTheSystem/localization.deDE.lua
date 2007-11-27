if( GetLocale() ~= "deDE" ) then
	return;
end

BTSLocals = setmetatable( {
}, { __index = BTSLocals } );