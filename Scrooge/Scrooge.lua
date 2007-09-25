local Orig_GetAddOnMetadata = GetAddOnMetadata
GetAddOnMetadata = function(name, field, ...)
	if( field and field == "X-Donate" ) then
		return nil
	end

	return Orig_GetAddOnMetadata(name, field, ...)
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function()
	-- Kill the default Rock donation link
	if( LibStub and LibStub.libs["LibRockConfig-1.0"] ) then
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
end)