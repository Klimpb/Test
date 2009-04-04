local IS_31000
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addon)
	if( addon == "DamnQuestWatch" ) then
		self:UnregisterEvent("ADDON_LOADED")
	
		local functName
		if( select(4, GetBuildInfo()) >= 30100 ) then
			IS_31000 = true
			functName = "WatchFrame_Update"		
		else
			functName = "QuestWatch_Update"	
		end
	
		hooksecurefunc(functName, function()
			for i=1, GetNumQuestWatches() do
				local questID = GetQuestIndexForWatch(i)
				if( questID ) then
					local numObjectives = GetNumQuestLeaderBoards(questID)
					if( numObjectives > 0 ) then
						local completed = 0
						for j=1, GetNumQuestLeaderBoards(questID) do
							if( select(3, GetQuestLogLeaderBoard(j, questID)) ) then
								completed = completed + 1
							end
						end

						if( numObjectives == completed ) then
							RemoveQuestWatch(questID)
							if( not IS_31000 ) then
								QuestWatch_Update()
							end
							
							--DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99QuestWatch|r: " .. GetQuestLogTitle(questID) .. " completed.")
						end
					end
				end
			end
		end)
	end
end)