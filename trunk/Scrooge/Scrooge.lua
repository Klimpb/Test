local Orig_GetAddOnMetadata = GetAddOnMetadata
GetAddOnMetadata = function(name, field, ...)
	if( field and field == "X-Donate" ) then
		return nil
	end
	
	return Orig_GetAddOnMetadata(name, field, ...)
end

local blank = function() end
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function()
	if( LibStub and Rock and ( not Rock.hooked or Rock.hooked ~= LibStub.minors["LibRock-1.0"] ) ) then
		OpenDonationFrame = blank

		Rock.hooked = LibStub.minors["LibRock-1.0"]
		Rock.donate = nil
	end
end)