local L = {
	["DONATE"] = "Donate",
	["GIVE_DONATE"] = "Give donation",
}


-- Kill the donate field
local Orig_GetAddOnMetadata = GetAddOnMetadata
GetAddOnMetadata = function(name, field, ...)
	if( field and field == "X-Donate" ) then
		return nil
	end

	return Orig_GetAddOnMetadata(name, field, ...)
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addon)
	if( not LibStub ) then
		return
	end
	
	-- Kill the default Rock donation link
	-- along with any donate links injected into Rock
	if( LibStub.libs["LibRockConfig-1.0"] ) then
		LibStub.libs["LibRockConfig-1.0"].rockOptions.args.donate = nil
		
		for addon, rows in pairs(LibStub.libs["LibRockConfig-1.0"].data) do
			if( rows.extraArgs ) then
				for k, row in pairs(rows.extraArgs) do
					if( k == "donate" ) then
						LibStub.libs["LibRockConfig-1.0"].data[addon].extraArgs[k] = nil;
					end
				end
			end
		end
	end
	
	-- Kill the donate field from Ace2 addons
	if( LibStub.libs["AceAddon-2.0"] ) then
		for addon, data in pairs(LibStub.libs["AceAddon-2.0"].addons) do
			data.donate = nil
		end
	end
end)