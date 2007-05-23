local AV = SSPVP:NewModule( "SSPVP-AV" );
AV.activeIn = "av";

local L = SSPVPLocals;
local abbrevByName = {};
local flavorItems = {};
local dataSent = {};
local timers = {};

function AV:Initialize()
	self:RegisterMessage( "SS_QUEUEAV_REQ", "SyncQueue" );
	self:RegisterMessage( "SS_CANCELAV_REQ", "ClearSyncOverlay" );
	self:RegisterMessage( "SS_QUEUECD_DATA", "SyncOverlay" );
	
	SSPVP.cmd:RegisterSlashHandler( L["sync <count> - Starts an Alterac Valley sync queue count down."], "sync (%d+)", self.StartAVSync );
	SSPVP.cmd:RegisterSlashHandler( L["cancel - Cancels a running sync count down."], "cancel", self.CancelSync );

	SSOverlay:AddCategory( "av", L["Timers"], nil, AV, "PrintAllTimers" );
	SSOverlay:AddCategory( "avitems", L["Item Tracker"] );
	
	for abbrev, name in pairs( L["AVNodes"] ) do
		abbrevByName[ name ] = abbrev;
	end
	
	table.insert( flavorItems, { text = L["Armor Scraps"], id = 17422, type = "armor" } );
	
	if( UnitFactionGroup( "player" ) == "Alliance" ) then
		table.insert( flavorItems, { text = L["Storm Crystals"], id = 17423, type = "crystal" } );
		table.insert( flavorItems, { text = L["Soldiers Medal"], id = 17502, type = "medal" } );
		table.insert( flavorItems, { text = L["Lieutenants Medal"], id = 17503, type = "medal" } );
		table.insert( flavorItems, { text = L["Commanders Medal"], id = 17504, type = "medal" } );

	elseif( UnitFactionGroup( "player" ) == "Horde" ) then
		table.insert( flavorItems, { text = L["Soldiers Blood"], id = 17306, type = "crystal" } );
		table.insert( flavorItems, { text = L["Soldiers Flesh"], id = 17326, type = "medal" } );
		table.insert( flavorItems, { text = L["Lieutenants Flesh"], id = 17327, type = "medal" } );
		table.insert( flavorItems, { text = L["Commanders Flesh"], id = 17328, type = "medal" } );
	end
end

function AV:EnableModule()
	self:RegisterEvent( "CHAT_MSG_MONSTER_YELL", "ParseYell" );
	self:RegisterEvent( "CHAT_MSG_BG_SYSTEM_HORDE", "ParseHorde" );
	self:RegisterEvent( "CHAT_MSG_BG_SYSTEM_ALLIANCE", "ParseAlliance" );
	self:RegisterEvent( "CHAT_MSG_PARTY", "ParseQueueMsg" );
	self:RegisterEvent( "CHAT_MSG_RAID", "ParseQueueMsg" );

	self:RegisterMessage( "SS_AVTIMERS_REQ", "ResponseDelay" );
	self:RegisterMessage( "SS_AVTIMERS_DATA", "ParseSync" );

	PVPSync:SendMessage( "AVTIMERS" );
	
	for _, item in pairs( flavorItems ) do
		if( SSPVP.db.profile.av[ item.type ] ) then
			SSOverlay:UpdateItem( "avitems", item.text .. ": %d", item.id );
		end
	end
end

function AV:DisableModule()
	timers = {};
	dataSent = {};

	self:UnregisterAllMessages();
	self:UnregisterAllEvents();
	
	SSOverlay:RemoveCategory( "av" );
	SSOverlay:RemoveCategory( "avitems" );
end

function AV:Reload()
	if( SSPVP:IsPlayerIn( "av" ) ) then
		if( not SSPVP.db.profile.av.enabled ) then
			SSPVP:UnregisterTimer( "IntervalMessage" );		
		end
		
		SSOverlay:RemoveCategory( "avitems" );

		for _, item in pairs( flavorItems ) do
			if( SSPVP.db.profile.av[ item.type ] ) then
				SSOverlay:UpdateItem( "avitems", item.text .. ": %d", item.id );
			end
		end
		
		PVPSync:SendMessage( "AVTIMERS" );
	end
end

function AV:PrintAllTimers()
	for name, timer in pairs( timers ) do
		SSPVP:MessageTimer( name, timer.endTime, timer.faction );
	end
end

function AV:SyncOverlay( event, seconds )
	SSOverlay:UpdateTimer( "av", L["Sync Queueing: %s"], seconds );
end

function AV:ClearSyncOverlay()
	if( SSPVP.db.profile.av.blocked ) then
		SSPVP:Print( L["Alterac Valley sync queue has been canceled!"] );
	end
	
	SSOverlay:RemoveRow( "timer", "av", L["Sync Queueing: %s"] );
end

function AV:SyncQueue()
	if( ( GetBattlefieldInfo() ) == L["Alterac Valley"] ) then
		SSPVP:Print( string.format( L["You have been queued for Alterac Valley by %s."], arg4 ) );

		JoinBattlefield( 0 );
		HideUIPanel( BattlefieldFrame );
	end
end

function AV:SendTimers()
	local send = {};
	local currentTime = GetTime();
	local faction, seconds;

	for name, timer in pairs( timers ) do
		-- We've already seen the data sent, ignore it.
		if( not dataSent[ name ] ) then
			if( timer.faction == "Alliance" ) then
				faction = "A";
			elseif( timer.faction == "Horde" ) then
				faction = "H";
			end
			
			seconds = math.floor( timer.endTime - currentTime );
			if( seconds > 0 ) then
				table.insert( send, abbrevByName[ name ] .. ":" .. faction .. ":" .. seconds );
			end
		end
	end
	
	if( #( send ) > 0 ) then
		PVPSync:SendMessage( "AVTIMERS:TIME:T:" .. GetTime() .. "," .. table.concat( send, "," ) );
	end
end

function AV:ResponseDelay()
	if( not SSPVP.db.profile.av.timers ) then
		return;
	end

	dataSent = {};
	SSPVP:RegisterTimer( self, "SendTimers", math.random( 10 ) );
end

function AV:ParseSync( event, ... )
	if( not SSPVP.db.profile.av.timers ) then
		return;
	end

	local abbrev, factionAbbrev, seconds, name;
	
	for i=1, select( "#", ... ) do
		abbrev, factionAbbrev, seconds = string.split( ":", ( select( i, ... ) ) );
	
		seconds = tonumber( seconds );
		
		-- Invalid data sent, stop parsing
		if( not abbrev or not factionAbbrev or not seconds or seconds < 0 ) then
			return;
		end
	
		if( i > 1 ) then
			-- Invalid abbrev or time received, stop parsing.
			if( not L["AVNodes"][ abbrev ] ) then
				return;
			end
			
			name = L["AVNodes"][ abbrev ];
			
			-- We've seen the data sent, ignore it if we ever send it ourself
			dataSent[ name ] = true;
			
			-- We don't have an active timer, so it's okay to add a new one
			if( not timers[ name ] ) then
				local faction;
				if( factionAbbrev == "A" ) then
					faction = "Alliance";	
				elseif( factionAbbrev == "H" ) then
					faction = "Horde";	
				end
				
				-- Gods have a specific text that we don't store, so check for them quickly
				if( abbrev == "IVUS") then
					SSOverlay:UpdateTimer( "av", L["Ivus the Forest Lord Moving: %s"], seconds, SSOverlay:GetFactionColor( faction ) );
				elseif( abbrev == "LOKH" ) then
					SSOverlay:UpdateTimer( "av", L["Lokholar the Ice Lord Moving: %s"], seconds, SSOverlay:GetFactionColor( faction ) );
				else
					SSOverlay:UpdateTimer( "av", name .. ": %s", seconds, SSOverlay:GetFactionColor( faction ) );
					self:StartIntervalAlerts( name, faction, seconds );
				end

				SSOverlay:AddOnClick( "timer", "av", name .. ": %s", SSPVP, "PrintTimer", name, GetTime() + seconds, faction );
				timers[ name ] = { faction = faction, endTime = GetTime() + seconds }
			end
		end
	end
end

local Orig_ChatFrame_OnEvent = ChatFrame_OnEvent;
function ChatFrame_OnEvent( event )
	if( event == "CHAT_MSG_MONSTER_YELL" ) then
		if( arg2 == L["Herald"] ) then
			if( string.find( arg1, L["Alliance"] ) ) then
				SSPVP:Message( arg1, SSOverlay:GetFactionColor( "Alliance" ) );
				return;
				
			elseif( string.find( arg1, L["Horde"] ) ) then
				SSPVP:Message( arg1, SSOverlay:GetFactionColor( "Horde" ) );
				return;
			end
			
		elseif( arg2 == L["Vanndar Stormpike"] ) then
			if( string.find( arg1, L["Soldiers of Stormpike, your General is under attack"] ) ) then
				SSPVP:Message( L["The Horde have engaged Vanndar Stormpike."], SSOverlay:GetFactionColor( "Horde" ) );
				return;
			
			elseif( string.find( arg1, L["Why don't ya try again"] ) ) then
				SSPVP:Message( L["The Horde have reset Vanndar Stormpike."], SSOverlay:GetFactionColor( "Horde" ) );
				return;

			elseif( string.find( arg1, L["You'll never get me out of me"] ) ) then
				return;
			end
		
		elseif( arg2 == L["Drek'Thar"] ) then
			if( string.find( arg1, L["Stormpike filth!"] ) ) then
				SSPVP:Message( L["The Alliance have engaged Drek'Thar."], SSOverlay:GetFactionColor( "Alliance" ) );
				return;
				
			elseif( string.find( arg1, L["You seek to draw the General of the Frostwolf"] ) ) then
				SSPVP:Message( L["The Alliance have reset Drek'Thar."], SSOverlay:GetFactionColor( "Alliance" ) );
				return;

			elseif( string.find( arg1, L["Stormpike weaklings"] ) ) then
				return;
			end
			
		elseif( arg2 == L["Captain Balinda Stonehearth"] ) then
			if( string.find( arg1, L["Begone, uncouth scum!"] ) ) then
				SSPVP:Message( L["The Horde have engaged Captain Balinda Stonehearth."], SSOverlay:GetFactionColor( "Horde" ) );
				return;
			
			elseif( string.find( arg1, L["Filthy Frostwolf cowards"] ) ) then
				SSPVP:Message( L["The Horde have reset Captain Balinda Stonehearth."], SSOverlay:GetFactionColor( "Horde" ) );
				return;
			end
		
		elseif( arg2 == L["Captain Galvangar"] ) then
			if( string.find( arg1, L["Your kind has no place in Alterac Valley"] ) ) then
				SSPVP:Message( L["The Alliance have engaged Captain Galvangar."], SSOverlay:GetFactionColor( "Alliance" ) );
				return;
				
			elseif( string.find( arg1, L["I'll never fall for that, fool!"] ) ) then
				SSPVP:Message( L["The Alliance have reset Captain Galvangar."], SSOverlay:GetFactionColor( "Alliance" ) );
				return;
			end
		
		elseif( string.find( arg2, L["(.+) Warmaster"] ) or string.find( arg2, L["(.+) Marshal"] ) ) then
			return;
		end
	end
	
	Orig_ChatFrame_OnEvent( event );
end

function AV:StartIntervalAlerts( name, faction, secondsLeft )
	if( not SSPVP.db.profile.av.enabled or SSPVP.db.profile.av.interval < 30 ) then
		return;
	end
	
	secondsLeft = math.floor( secondsLeft );

	for seconds=1, secondsLeft -1 do
		if( seconds <= 120 and SSPVP.db.profile.av.speed > 0 ) then
			interval = math.floor( SSPVP.db.profile.av.interval * SSPVP.db.profile.av.speed );
		else
			interval = SSPVP.db.profile.av.interval;
		end

		if( mod( seconds, interval ) == 0 ) then
			SSPVP:RegisterTimer( self, "IntervalMessage", secondsLeft - seconds, name, faction, seconds );
		end
	end
end

function AV:IntervalMessage( name, faction, seconds )
	if( timers[ name ] ) then
		SSPVP:Message( string.format( L["%s will be captured by the %s in %s!"], name, L[ faction ], string.trim( string.lower( SecondsToTime( seconds ) ) ) ), SSOverlay:GetFactionColor( faction ) );
	end
end

function AV:ParseQueueMsg( event, msg, from )
	if( string.sub( msg, 0, 4 ) ~= "[SS]" ) then
		return;
	end
	
	if( string.find( msg, L["Queueing for Alterac Valley in ([0-9]+) seconds"] ) ) then
		local _, _, seconds = string.find( msg, L["Queueing for Alterac Valley in ([0-9]+) seconds"] );
		
		self:SyncOverlay( event, tonumber( seconds ) );
	elseif( string.find( msg, L["Sync queue count down has been"] ) ) then
		self:ClearSyncOverlay();
	end
end

function AV:ParseYell( event, msg, from )
	if( not SSPVP.db.profile.av.timers ) then
		return;
	end
	
	if( from == L["Herald"] ) then
		local faction;
		if( string.find( msg, L["Alliance"] ) ) then
			faction = "Alliance";
		elseif( string.find( msg, L["Horde"] ) ) then
			faction = "Horde";
		end

		if( string.find( msg, L["(.+) is under attack!"] ) ) then
			local _, _, name = string.find( msg, L["(.+) is under attack!"] );
			name = string.gsub( name, "^" .. L["The"], "" );
			name = string.trim( name );
			
			timers[ name ] = { faction = faction, endTime = GetTime() + 300 }
			self:StartIntervalAlerts( name, faction, 300 );

			SSOverlay:UpdateTimer( "av", name .. ": %s", 300, SSOverlay:GetFactionColor( faction ) );
			SSOverlay:AddOnClick( "timer", "av", name .. ": %s", SSPVP, "PrintTimer", name, GetTime() + 300, faction );

		elseif( string.find( msg, L["(.+) was taken by the"] ) ) then
			local _, _, name = string.find( msg, L["(.+) was taken by the"] );
			name = string.gsub( name, "^" .. L["The"], "" );
			name = string.trim( name );
			
			timers[ name ] = nil;
			SSOverlay:RemoveRow( "timer", "av", name .. ": %s" );
		elseif( string.find( msg, L["(.+) was destroyed by the"] ) ) then
			local _, _, name = string.find( msg, L["(.+) was destroyed by the"] );
			name = string.trim( string.gsub( name, "^" .. L["The"], "" ) );
			name = string.trim( name );
			
			timers[ name ] = nil;
			SSOverlay:RemoveRow( "timer", "av", name .. ": %s" );
		end
	
	elseif( from == L["Ivus the Forest Lord"] and string.find( arg1, L["Wicked, wicked, mortals"] ) ) then
		timers[ L["Ivus the Forest Lord"] ] = { faction = "Alliance", endTime = GetTime() + 600 };

		SSOverlay:UpdateTimer( "av", "timer", L["Ivus the Forest Lord Moving: %s"], 600, SSOverlay:GetFactionColor( "Horde" ) );
		SSOverlay:AddOnClick( "timer", "av", L["Ivus the Forest Lord Moving: %s"], SSPVP, "PrintTimer", name, GetTime() + 600, faction );

	elseif( from == L["Lokholar the Ice Lord"] and string.find( arg1, L["WHO DARES SUMMON LOKHOLA"] ) ) then
		timers[ L["Lokholar the Ice Lord"] ] = { faction = "Horde", endTime = GetTime() + 600 };

		SSOverlay:UpdateTimer( "av", "timer", L["Lokholar the Ice Lord Moving: %s"], 600, SSOverlay:GetFactionColor( "Horde" ) );
		SSOverlay:AddOnClick( "timer", "av", L["Lokholar the Ice Lord Moving: %s"], SSPVP, "PrintTimer", name, GetTime() + 600, faction );
	end
end

function AV:ParseHorde( event, msg )
	if( string.find( msg, L["claims the (.+) graveyard!"] ) ) then
		SSOverlay:UpdateTimer( "av", L["Snowfall Graveyard"] .. ": %s", 300, SSOverlay:GetFactionColor( "Horde" ) );
		SSOverlay:AddOnClick( "timer", "av", L["Snowfall Graveyard"] .. ": %s", SSPVP, "PrintTimer", name, GetTime() + 600, "Horde" );

		self:StartIntervalAlerts( L["Snowfall Graveyard"], "Horde", 300 );
	end
end

function AV:ParseAlliance( event, msg )
	if( string.find( msg, L["claims the (.+) graveyard!"] ) ) then
		SSOverlay:UpdateTimer( "av", L["Snowfall Graveyard"] .. ": %s", 300, SSOverlay:GetFactionColor( "Alliance" ) );
		SSOverlay:AddOnClick( "timer", "av", L["Snowfall Graveyard"] .. ": %s", SSPVP, "PrintTimer", name, GetTime() + 300, "Alliance" );

		self:StartIntervalAlerts( L["Snowfall Graveyard"], "Alliance", 300 );
	end
end


-- Slash Commands
function AV:QueueAV()
	SSPVP:AutoMessage( L["Queued for Alterac Valley!"] );
	PVPSync:SendMessage( "QUEUEAV", "RAID" );

	-- For SSPVP 2.x.x
	SendAddonMessage( "SSAV", "QUEUEAV", "RAID" );
end

function AV.CancelSync()
	if( ( GetNumRaidMembers() == 0 and not IsPartyLeader() ) or ( GetNumRaidMembers() > 0 and not IsRaidLeader() ) ) then
		SSPVP:Print( L["You must be party or raid leader to perform this action."] );
		return;
	end

	SSPVP:AutoMessage( L["Alterac Valley sync queue has been canceled!"] );
	SSPVP:UnregisterTimer( "QueueAV" );
	SSPVP:UnregisterTimer( "AutoMessage" );
	
	PVPSync:SendMessage( "CANCELAV", "RAID" );
end

function AV.StartAVSync( seconds )
	if( ( GetNumRaidMembers() == 0 and not IsPartyLeader() ) or ( GetNumRaidMembers() > 0 and not IsRaidLeader() ) ) then
		SSPVP:Print( L["You must be party or raid leader to perform this action."] );
		return;
	end
	
	SSPVP:AutoMessage( string.format( L["Queue for Alterac Valley in %d seconds."], seconds ) );
	
	for i=seconds - 1, 1, -1 do
		SSPVP:RegisterTimer( SSPVP, "AutoMessage", seconds - i, string.format( L["Queueing in %d second(s)."], i ) );
	end

	SSPVP:RegisterTimer( AV, "QueueAV", seconds );
	PVPSync:SendMessage( "QUEUECD:" .. seconds, "RAID" );
end