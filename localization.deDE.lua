if( GetLocale() ~= "deDE" ) then
	return;
end

HonestLocals = setmetatable( {
}, { __index = HonestLocals } );