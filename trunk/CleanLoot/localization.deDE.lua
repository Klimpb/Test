if( GetLocale() ~= "deDE" ) then
	return;
end

CleanLootLocals = setmetatable( {
}, { __index = CleanLootLocals } );