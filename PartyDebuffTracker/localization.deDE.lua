if( GetLocale() ~= "deDE" ) then
	return
end

TrackeryLocals = setmetatable({
}, {__index = TrackeryLocals})