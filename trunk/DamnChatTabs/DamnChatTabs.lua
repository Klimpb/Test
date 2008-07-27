local function print(msg)
	DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff33ff99Damn Chat Tabs|r: %s", msg))
end

local function hideTab(self)
	if( self.DCTHide ) then
		self:Hide()
	end
end

SLASH_DAMNTABS1 = "/toggletab"
SlashCmdList["DAMNTABS"] = function(msg)
	local id = tonumber(msg) or 0
	if( id <= 0 or id >= 7 ) then
		print(string.format("Invalid ID entered \"%s\", must be within 1 - 7.", id))
		return
	end

	local frame = getglobal(string.format("ChatFrame%dTab", id))
	if( frame ) then
		DamnChatTabsDB[id] = not DamnChatTabsDB[id]
		
		if( not frame.DCTHooked ) then
			if( frame:GetScript("OnShow") ) then
				frame:HookScript("OnShow", hideTab)
			else
				frame:SetScript("OnShow", hideTab)
			end
		end
		
		frame.DCTHide = DamnChatTabsDB[id]
		frame.DCTHooked = true
		
		if( frame.DCTHide ) then
			print(string.format("Now keeping Chat Frame %d tab from showing.", id))
			frame:Hide()
		else
			print(string.format("No longer keeping Chat Frame %d tab from showing.", id))
		end
	else
		print(string.format("Invalid Chat Frame number entered \"%s\".", id))
	end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addon)
	if( event == "ADDON_LOADED" and addon == "DamnChatTabs" ) then
		DamnChatTabsDB = DamnChatTabsDB or {}
		
		for id, hide in pairs(DamnChatTabsDB) do
			if( hide ) then
				local frame = getglobal(string.format("ChatFrame%dTab", id))
				if( frame ) then
					if( frame:GetScript("OnShow") ) then
						frame:HookScript("OnShow", hideTab)
					else
						frame:SetScript("OnShow", hideTab)
					end
					
					frame.DCTHide = true
					frame.DCTHooked = true
					frame:Hide()
				end
			end
		end
	end
end)