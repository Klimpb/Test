-- Kill the donate field
local Orig_GetAddOnMetadata = GetAddOnMetadata
GetAddOnMetadata = function(name, field, ...)
	if( field and field == "X-Donate" ) then
		return nil
	end

	return Orig_GetAddOnMetadata(name, field, ...)
end

local function print(msg)
	DEFAULT_CHAT_FRAME:AddMessage(msg)
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addon)
	if( addon == "Scrooge" ) then
		SLASH_SCROOGE1 = "/scrooge"
		SlashCmdList["SCROOGE"] = function()
			local name = GetAddOnInfo(1)		
			if( name != "Scrooge" ) then
				print("Scrooge wasn't the first addon that loaded, while this usually isn't a requirement you may see donation buttons still.")
				print("If you want to be 100% sure that donation buttons are killed, you will need to go into the toc file for ".. name)
				print("If you see a line that says \"OptionalDeps\" then add \", Scrooge\" at the end of it and do a /console reloadui")
				print("If you do not see that line, then just add \"## OptionalDeps: Scrooge\" below \"## Title\"")
			else
				print("Scrooge is the first addon that loaded, you shouldn't see any pesky donate links!")
			end
		end	
	end

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