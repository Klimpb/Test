local function questWatch_Updated()
	for i=1, GetNumQuestWatches() do
		local questID = GetQuestIndexForWatch(i)
		if( questID ) then
			local numObjectives = GetNumQuestLeaderBoards(questID)
		
			if ( numObjectives > 0 ) then
				local objsCompleted = 0
				for j=1, GetNumQuestLeaderBoards(questID) do
					if( select(3, GetQuestLogLeaderBoard(j, questID)) ) then
						objsCompleted = objsCompleted + 1
					end
				end
		
				
				if( numObjectives == objsCompleted ) then
					RemoveQuestWatch(questID)
					QuestWatch_Update()
					
					--DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99QuestWatch|r: " .. GetQuestLogTitle(questID) .. " completed.")
				end
			end
		end
	end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addon)
	if( addon == "DamnQuestWatch" ) then
		hooksecurefunc("QuestWatch_Update", questWatch_Updated)
	end
end)