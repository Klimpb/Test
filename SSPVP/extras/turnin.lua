local TurnIn = SSPVP:NewModule("SSPVP-TurnIn")
local Orig_GossipClicks = {}

function TurnIn:Enable()
	self:RegisterEvent("QUEST_PROGRESS")
	self:RegisterEvent("QUEST_COMPLETE")
	self:RegisterEvent("GOSSIP_SHOW")
end

function TurnIn:Disable()
	self:UnregisterAllEvents()
end

-- Auto skip gossip
function TurnIn:GossipOnClick()
	-- Adding a new skip
	if( IsAltKeyDown() ) then
		-- If it already exists, remove it
		local quest
		for i=#(SSPVP.db.profile.quests), 1, -1 do
			quest = SSPVP.db.profile.quests[i]
			
			if( string.lower(quest.name) == self:GetText() or string.match(string.lower(quest.name), string.lower(self:GetText())) ) then
				SSPVP:Print(string.format(SSPVPLocals["Removed the quest '%s...' from auto complete."], string.trim(string.sub(self:GetText(), 0, 15))))
				table.remove(SSPVP.db.profile.quests, i)
				return
			end
		end
		
		-- Nope, add it
		SSPVP:Print(string.format(SSPVPLocals["Added the quest '%s...' to the skip list, hold ALT and click the text again to remove it."], string.trim(string.sub(self:GetText(), 0, 15))))

		-- If it's not a quest, it can't have any item requirements
		for id, gossip in pairs({GetGossipOptions()}) do
			if( ( select(1, gossip) ) == self:GetText() ) then
				table.insert(SSPVP.db.profile.quests, {name = self:GetText(), type = "manual", noItems = true})
				return
			end
		end
		
		-- It's a quest, so 99% chance it'll have item requirements
		table.insert(SSPVP.db.profile.quests, {name = self:GetText(), type = "manual", checkItems = true})
		return
	end
	
	if( Orig_GossipClicks[self:GetName()] ) then
		Orig_GossipClicks[self:GetName()]()
	end
end

-- Check if we need to auto skip
function TurnIn:GOSSIP_SHOW()
	if( not SSPVP.db.profile.turnin.enabled ) then
		return
	end
	
	local button
	for i=1, GossipFrame.buttonIndex do
		button = getglobal("GossipTitleButton" .. i)
		
		-- Got to know when we want to add/remove
		if( not button.SSHooked ) then
			Orig_GossipClicks[button:GetName()] = button:GetScript("OnClick")

			button:SetScript("OnClick", self.GossipOnClick)
			button.SSHooked = true
		end

		-- Disable auto turn in if shift key is down
		if( button:GetText() and not IsShiftKeyDown() ) then
			-- Make sure it's a quest we want to skip, and that it's the highest one
			-- So for things like Alterac Valley crystal turn ins
			-- will choose the one with 5 crystals not 1 if need be
			if( self:IsAutoQuest(button:GetText()) and self:IsHighestQuest(button:GetText()) ) then
				if( button.type == "Available" ) then
					SelectGossipAvailableQuest(i)
				elseif( button.type == "Active" ) then
					SelectGossipActiveQuest(i)
				else
					SelectGossipOption(i)
				end
			end
		end
	end
end

-- Figure out if we need to auto skip this too!
function TurnIn:QUEST_PROGRESS()
	if( not SSPVP.db.profile.turnin.enabled ) then
		return
	end
	
	-- It's got items, do we need to scan them?
	if( GetNumQuestItems() > 0 ) then
		local questTitle = string.lower(GetTitleText())
		
		for id, quest in pairs(SSPVP.db.profile.quests) do
			-- Yup need to scan
			if( quest.checkItems and ( questTitle == string.lower(quest.name) or string.match(questTitle, string.lower(quest.name)) ) ) then
				local items
				
				-- Store how many we need, and the itemid for next time
				-- technically, due to this way you have to complete the quest
				-- yourself the first time, but thats better then storing quest info
				-- for every quest in-game
				for i=1, GetNumQuestItems() do
					local itemLink = GetQuestItemLink("required", i)
					
					if( itemLink ) then
						local _, itemid = string.match(itemLink, "|c(.+)|Hitem:([0-9]+):(.+)|h%[(.+)%]|h|r")
						local _, _, required = GetQuestItemInfo("required", i)
						
						itemid = tonumber(itemid)
						
						if( itemid and itemid > 0 ) then
							if( not items ) then
								items = {}
							end

							items[itemid] = required
						end
					end
				end
				
				quest.item = items
				quest.checkItems = nil
			end
		end
	end
	
	-- Alright! Complete
	if( IsQuestCompletable() and self:IsAutoQuest(GetTitleText()) ) then
		QuestFrameCompleteButton:Click()
	end
end

-- Zzz
function TurnIn:QUEST_COMPLETE()
	if( SSPVP.db.profile.turnin.enabled and IsQuestCompletable() and self:IsAutoQuest(GetTitleText()) ) then
		QuestFrameCompleteQuestButton:Click()
	end
end

-- Figure out if it's an auto turn in quest
-- and if we can actually complete it
function TurnIn:IsAutoQuest(name)
	if( not name ) then
		return nil
	end
	
	name = string.lower(name)
	
	for _, quest in pairs(SSPVP.db.profile.quests) do
		if( not SSPVP.db.profile.turnin[quest.type] and ( name == string.lower(quest.name) or string.match(name, string.lower(quest.name)) ) ) then
			if( quest.item ) then
				local required = 0
				local found = 0
				
				for itemid, quantity in pairs(quest.item) do
					required = required + 1
					
					if( GetItemCount(itemid) >= quantity ) then
						found = found + 1
					end
				end
				
				if( found >= required ) then
					return true
				end
				
			else
				return true
			end
		end
	end
	
	return nil
end

-- Find out if it's the highest turn in quest available
function TurnIn:IsHighestQuest(name)
	if( not name ) then
		return nil
	end
	
	name = string.lower(name)
	
	local questID = 0
	
	for id, quest in pairs(SSPVP.db.profile.quests) do
		if( not SSPVP.db.profile.turnin[quest.type] and ( name == string.lower(quest.name) or string.match(name, string.lower(quest.name)) ) ) then
			if( quest.noItems ) then
				return true
			elseif( quest.item ) then
				highest = quest.item
				questID = id
				break
			else
				return nil
			end
		end
	end
	
	for id, quest in pairs(SSPVP.db.profile.quests) do
		if( id ~= questID and not SSPVP.db.profile.turnin[quest.type ] and quest.item ) then
			local required = 0
			local found = 0
			
			for itemid, quantity in pairs(quest.item) do
				required = required + 1
				if( highest[itemid] and quantity >= highest[itemid] and GetItemCount(itemid) >= quantity ) then
					found = found + 1	
				end
				
				if( found >= required ) then
					return nil
				end
			end
		end
	end
	
	return true
end