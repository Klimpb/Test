if( GetLocale() ~= "deDE" ) then
	return
end

AuctionStatLocalss = setmetatable({
}, {__index = AuctionStatLocalss})