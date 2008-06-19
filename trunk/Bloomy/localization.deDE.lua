if( GetLocale() ~= "deDE" ) then
	return
end

BloomyLocals = setmetatable({
}, { __index = BloomyLocals})