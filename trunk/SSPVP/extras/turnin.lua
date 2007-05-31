TurnIn = SSPVP:NewModule( "SSPVP-TurnIn" );
local Orig_GossipClicks = {};

function TurnIn:Enable()
	self:RegisterEvent( "QUEST_PROGRESS" );
	self:RegisterEvent( "QUEST_COMPLETE" );
	self:RegisterEvent( "GOSSIP_SHOW" );
end

function TurnIn:Disable()
	self:UnregisterAllEvents();
end

function TurnIn:GossipOnClick()
	if( IsAltKeyDown() ) then
		local quest;
		for i=#( SSPVP.db.profile.quests ), 1, -1 do
			quest = SSPVP.db.profile.quests[i];
			
			if( string.lower( quest.name ) == this:GetText() or string.find( string.lower( quest.name ), string.lower( this:GetText() ) ) ) then
				SSPVP:Print( string.format( SSPVPLocals["Removed the quest '%s...' from auto complete."], string.trim( string.sub( this:GetText(), 0, 15 ) ) ) );
				table.remove( SSPVP.db.profile.quests, i );
				return;
			end
		end

		SSPVP:Print( string.format( SSPVPLocals["Added the quest '%s...' to the skip list, hold ALT and click the text again to remove it."], string.trim( string.sub( this:GetText(), 0, 15 ) ) ) );
		
		-- If it's not a quest, it can't have any item recruitments
		for id, gossip in pairs( { GetGossipOptions() } ) do
			if( ( select( 1, gossip ) ) == this:GetText() ) then
				table.insert( SSPVP.db.profile.quests, { name = this:GetText(), type = "manual", noItems = true } );
				return;
			end
		end
		
			table.insert( SSPVP.db.profile.quests, { name = this:GetText(), type = "manual", checkItems = true } );
		return;
	end

	if( Orig_GossipClicks[ this:GetName() ] ) then
		Orig_GossipClicks[ this:GetName() ]()
	end
end


function TurnIn:GOSSIP_SHOW()
	if( not SSPVP.db.profile.turnin.enabled ) then
		return;
	end
	
	local button;
	for i=1, GossipFrame.buttonIndex do
		button = getglobal( "GossipTitleButton" .. i );

		if( not button.SSHooked ) then
			Orig_GossipClicks[ button:GetName() ] = button:GetScript( "OnClick" );

			button:SetScript( "OnClick", self.GossipOnClick );
			button.SSHooked = true;
		end

		-- Disable auto turn in if shift key is down
		if( button:GetText() and not IsShiftKeyDown() ) then
			if( self:IsAutoQuest( button:GetText() ) and self:IsHighestQuest( button:GetText() ) ) then
				if( button.type == "Available" ) then
					SelectGossipAvailableQuest( i );
				elseif( button.type == "Active" ) then
					SelectGossipActiveQuest( i );
				else
					SelectGossipOption( i );
				end
			end
		end
	end
end

function TurnIn:QUEST_PROGRESS()
	if( not SSPVP.db.profile.turnin.enabled ) then
		return;
	end

	if( GetNumQuestItems() > 0 ) then
		local questTitle = string.lower( GetTitleText() );
		local itemLink, itemid, required;
		
		for id, quest in pairs( SSPVP.db.profile.quests ) do
			if( quest.checkItems and ( questTitle == string.lower( quest.name ) or string.find( questTitle, string.lower( quest.name ) ) ) ) then
				local items;
				
				for i=1, GetNumQuestItems() do
					itemLink = GetQuestItemLink( "required", i );
					
					if( itemLink ) then
						_, itemid = string.match( itemLink, "|c(.+)|Hitem:([0-9]+):(.+)|h%[(.+)%]|h|r" );
						_, _, required = GetQuestItemInfo( "required", i );
						
						itemid = tonumber( itemid );
						
						if( itemid and itemid > 0 ) then
							if( not items ) then
								items = {};
							end

							items[ itemid ] = required;
						end
					end
				end
				
				SSPVP.db.profile.quests[ id ].item = items;
				SSPVP.db.profile.quests[ id ].checkItems = nil;
			end
		end
	end

	if( IsQuestCompletable() and self:IsAutoQuest( GetTitleText() ) ) then
		QuestFrameCompleteButton:Click();
	end
end

function TurnIn:QUEST_COMPLETE()
	if( SSPVP.db.profile.turnin.enabled and IsQuestCompletable() and self:IsAutoQuest( GetTitleText() ) ) then
		QuestFrameCompleteQuestButton:Click();
	end
end

function TurnIn:IsAutoQuest( name )
	if( not name ) then
		return nil;
	end
	
	name = string.lower( name );
	
	local required, found;
	for _, quest in pairs( SSPVP.db.profile.quests ) do
		if( not SSPVP.db.profile.turnin[ quest.type ] and ( name == string.lower( quest.name ) or string.find( name, string.lower( quest.name ) ) ) ) then
			if( quest.item ) then
				required = 0;
				found = 0;
				
				for itemid, quantity in pairs( quest.item ) do
					required = required + 1;
					
					if( GetItemCount( itemid ) >= quantity ) then
						found = found + 1;
					end
				end
				
				if( found >= required ) then
					return true;
				end
				
			else
				return true;
			end
		end
	end
	
	return nil;
end

function TurnIn:IsHighestQuest( name )
	if( not name ) then
		return nil;
	end
	
	name = string.lower( name );
	
	local questID = 0;
	
	for id, quest in pairs( SSPVP.db.profile.quests ) do
		if( not SSPVP.db.profile.turnin[ quest.type ] and ( name == string.lower( quest.name ) or string.find( name, string.lower( quest.name ) ) ) ) then
			if( quest.noItems ) then
				return true;
			elseif( quest.item ) then
				highest = quest.item;
				questID = id;
				break;
			else
				return nil;
			end
		end
	end
	
	local required, found;
	for id, quest in pairs( SSPVP.db.profile.quests ) do
		if( id ~= questID and not SSPVP.db.profile.turnin[ quest.type ] and quest.item ) then
			required = 0;
			found = 0;
			
			for itemid, quantity in pairs( quest.item ) do
				required = required + 1;
				if( highest[ itemid ] and quantity >= highest[ itemid ] and GetItemCount( itemid ) >= quantity ) then
					found = found + 1;	
				end
				
				if( found >= required ) then
					return nil;
				end
			end
		end
	end
	
	return true;
end