if( GetLocale() ~= "deDE" ) then
	return
end

DistWatchLocals = setmetatable({
}, {__index = DistWatchLocals})