if( GetLocale() ~= "deDE" ) then
	return;
end

LootModLocals = setmetatable( {
}, { __index = LootModLocals } );