local Orig_ChatFrame_OnEvent;

local TimeElapsed = 0;
local OpenRaid;

local PlayerJoinedRaid;
local PlayerLeftRaid;

local OPENED_LOOT_WINDOWS = 0;
local CREATED_LOOT_WINDOWS = 0;

local MAX_LOOT_WINDOWS = 6;
local MAX_FRIENDS = 50;

local WatchLoot = {};

local BlockMessages = {};

local FriendOnline;
local FriendOffline;

function BWDKP_OnLoad()
	this:RegisterEvent( "VARIABLES_LOADED" );
	
	this:RegisterEvent( "CHAT_MSG_WHISPER" );
	this:RegisterEvent( "CHAT_MSG_SYSTEM" );
	
	this:RegisterEvent( "LOOT_OPENED" );
	this:RegisterEvent( "LOOT_CLOSED" );	
	
	this:RegisterEvent( "CHAT_MSG_LOOT" );
	
	this:RegisterEvent( "RAID_ROSTER_UPDATE" );
	this:RegisterEvent( "GUILD_ROSTER_UPDATE" );
	
	SLASH_BOWDKP1 = "/dkp";
	SLASH_BOWDKP2 = "/bwdkp";
	SLASH_BOWDKP3 = "/bowdkp";
	SlashCmdList["BOWDKP"] = BWDKP_SlashHandler;
end

function BWDKP_HelpCommands( msg )
	for _, text in pairs( BWD_HELP_COMMANDS ) do
		BWDKP_Message( text, ChatTypeInfo["SYSTEM"] );
	end
end

function BWDKP_SlashHandler( msg )
	if( msg and string.lower( msg ) == "help" or not msg or msg == "" ) then
		BWDKP_HelpCommands( msg );
		return;
	end

	-- Hack
	local commands = {};
	for match in string.gmatch( msg, "%w+" ) do
		table.insert( commands, match );
	end
	
	local command = commands[1];
	local commandArg = commands[2];
	
	table.remove( commands, 2 );
	table.remove( commands, 1 );

	local extraArg = table.concat( commands, " " );
	
	if( command == "start" and commandArg ) then
		if( OpenRaid ) then
			BWDKP_Message( string.format( BWD_RAID_ALREADYOPEN, OpenRaid ), ChatTypeInfo["SYSTEM"] );
			return;
		end

		local factor = tonumber( extraArg ) or 100;
		OpenRaid = commandArg;
		
		BWDKP_Message( string.format( BWD_RAID_STARTED, commandArg, factor ), ChatTypeInfo["SYSTEM"] );
		BWDKP_Raids[ OpenRaid ] = { StartTime = GetTime(), Factor = factor, Raid = {}, Sit = {}, Loot = {}, Friends = {}, Block = {} };
		
		-- Save the friends list
		for i=1, GetNumFriends() do
			BWDKP_Raids[ OpenRaid ]["Friends"][ ( GetFriendInfo( i ) ) ] = true;
		end
		

		-- Friends list warning if we are at or close to max
		if( GetNumFriends() == MAX_FRIENDS ) then
			BWDKP_Message( string.format( BWD_FRIENDS_FULL, MAX_FRIENDS ), { r = 1, g = 0, b = 0 } );
		elseif( GetNumFriends() >= MAX_FRIENDS - 10 ) then
			BWDKP_Message( string.format( BWD_FRIENDS_ALMOSTFULL, GetNumFriends(), MAX_FRIENDS ), { r = 1, g = 0, b = 0 } );
		end
		
		-- Check raid, check sit load guild for sit stuff
		BWDKP_CheckRaid();
		GuildRoster();
		
	elseif( command == "end" or command == "stop" ) then
		if( not OpenRaid ) then
			BWDKP_Message( BWD_RAID_NONEOPEN, ChatTypeInfo["SYSTEM"] );
			return;
		end
		
		BWDKP_CheckRaid();
		BWDKP_CheckSit();
		BWDKP_CheckFriends();
				
		-- Get current friends list
		local FriendsList = {};
		for i=1, GetNumFriends() do
			local name = GetFriendInfo( i );
			FriendsList[ name ] = true;
		end
		
		-- Clean up the friends list
		for name in pairs( BWDKP_Raids[ OpenRaid ].Block ) do
			if( not BWDKP_Raids[ OpenRaid ]["Friends"][ name ] and FriendsList[ name ] ) then
				BWDKP_Config["Block"][ name ] = true;
				RemoveFriend( name, true );
			end
		end
		
		-- Remove the junk friends data
		BWDKP_Raids[ OpenRaid ].Block = nil;
		BWDKP_Raids[ OpenRaid ].Friends = nil;

		local EndTime = GetTime();
		BWDKP_Raids[ OpenRaid ].RunTime = EndTime - BWDKP_Raids[ OpenRaid ].StartTime;		
		BWDKP_Raids[ OpenRaid ].EndTime = EndTime;
		
		-- Change the save format into EndTime-RaidName, this prevents issues if we save
		-- multiple raids of the same name
		BWDKP_Raids[ EndTime .. "-" .. OpenRaid ] = BWDKP_Raids[ OpenRaid ];
		BWDKP_Raids[ OpenRaid ] = nil;
		
		-- Convert the data into advraids and save
		--BWDKP_ConvertRaids();
		
		-- Setup the raid ended message
		BWDKP_Config.message = string.format( BWD_RAID_ENDED, OpenRaid );
		ReloadUI();		
	
	-- Add player record
	elseif( command == "padd" and commandArg ) then
		if( not OpenRaid ) then
			BWDKP_Message( BWD_RAID_NONEOPEN, ChattypeInfo["SYSTEM"] );
			return;
		end
		
		local searchName = string.lower( commandArg );
		local startMinutes = tonumber( extraArg );
		if( not startMinutes or startMinutes < 0 ) then
			startMinutes = 0;
		end
		
		-- Do they already have a record?
		for name, attendance in pairs( BWDKP_Raids[ OpenRaid ].Sit ) do
			if( string.lower( name ) == searchName ) then
				BWDKP_Message( string.format( BWD_PRECORD_EXISTS, name ), ChatTypeInfo["SYSTEM"] );
				return;
			end
		end

		for name, attendance in pairs( BWDKP_Raids[ OpenRaid ].Raid ) do
			if( string.lower( name ) == searchName ) then
				BWDKP_Message( string.format( BWD_PRECORD_EXISTS, name ), ChatTypeInfo["SYSTEM"] );
				return;
			end
		end
		
		
		BWDKP_Raids[ OpenRaid ]["Sit"][ commandArg ] = { LastUpdate = GetTime(), TimeInSit = startMinutes * 60 };
		BWDKP_Message( string.format( BWD_ADDED_RECORD, commandArg, startMinutes, OpenRaid ), ChatTypeInfo["SYSTEM"] );
	
	-- Delete player record
	elseif( command == "pdel" and commandArg ) then
		if( not OpenRaid ) then
			BWDKP_Message( BWD_RAID_NONEOPEN, ChattypeInfo["SYSTEM"] );
			return;
		end
		
		local type;
		local commandArg = string.lower( commandArg );
		
		for name, attendance in pairs( BWDKP_Raids[ OpenRaid ].Sit ) do
			if( string.lower( name ) == commandArg ) then
				BWDKP_Raids[ OpenRaid ]["Sit"][ name ] = nil;
				break;
			end
		end

		for name, attendance in pairs( BWDKP_Raids[ OpenRaid ].Raid ) do
			if( string.lower( name ) == commandarg ) then
				BWDKP_Raids[ OpenRaid ]["Raid"][ name ] = nil;
				break;
			end
		end
		
		BWDKP_Message( string.format( BWD_DELETED_RECORD, commandArg, OpenRaid ), ChatTypeInfo["SYSTEM"] );

	-- Add item awarded
	elseif( command == "iadd" and commandArg ) then
		if( not OpenRaid ) then
			BWDKP_Message( BWD_RAID_NONEOPEN, ChattypeInfo["SYSTEM"] );
			return;
		end
		
		table.insert( BWDKP_Raids[ OpenRaid ].Loot, { Item = extraArg, Winner = commandArg } );		
		BWDKP_Message( string.format( BWD_ADDED_ITEM, extraArg, commandArg, OpenRaid ), ChatTypeInfo["SYSTEM"] );
	
	-- Delete loot awarded
	elseif( command == "idel" and commandArg ) then
		if( not OpenRaid ) then
			BWDKP_Message( BWD_RAID_NONEOPEN, ChattypeInfo["SYSTEM"] );
			return;
		end
		
		commandArg = string.lower( commandArg );
		if( extraArg ) then
			extraArg = string.lower( extraArg );
		end
		
		for i=#( BWDKP_Raids[ OpenRaid ].Loot ), 1, -1 do
			local loot = BWDKP_Raids[ OpenRaid ]["Loot"][ i ];
			if( ( string.lower( loot.Winner ) == commandArg ) and ( not extraArg or ( extraArg and string.lower( loot.Item ) == extraArg ) ) ) then
				BWDKP_Message( string.format( BWD_DELETED_ITEM, loot.Item, loot.Winner ), ChatTypeInfo["SYSTEM"] );
				table.remove( BWDKP_Raids[ OpenRaid ].Loot, i );
			end
		end
	
	elseif( command == "list" and commandArg ) then
		if( not OpenRaid ) then
			BWDKP_Message( BWD_RAID_NONEOPEN, ChatTypeInfo["SYSTEM"] );
			return;
		end

		if( commandArg == "loot" ) then
			if( #( BWDKP_Raids[ OpenRaid ].Loot ) == 0 ) then
				BWDKP_Message( string.format( BWD_ITEM_NOLOOT, OpenRaid ), ChatTypeInfo["SYSTEM"] );
				return;
			end
			
			for _, loot in pairs( BWDKP_Raids[ OpenRaid ].Loot ) do
				local isWaiting;
				if( not loot.isWaiting ) then
					isWaiting = BWD_NO;	
				else
					isWaiting = BWD_YES;
				end
				
				BWDKP_Message( string.format( BWD_ITEM_LIST, loot.Winner, loot.Item, isWaiting ) );
			end
		
		elseif( commandArg == "sit" ) then
			local totalSits = 0;
			
			for name, attendance in pairs( BWDKP_Raids[ OpenRaid ].Sit ) do
				local isOffline;
				if( not attendance.LeftSit ) then
					isOffline = BWD_NO;
				else
					isOffline = BWD_YES;
				end
				
				BWDKP_Message( string.format( BWD_SIT_LIST, name, ( attendance.TimeInSit / 60 ), isOffline ), ChatTypeInfo["SYSTEM"] );			
				totalSits = totalSits + 1;
			end
			
			if( totalSits == 0 ) then
				BWDKP_Message( string.format( BWD_NO_SIT, OpenRaid ), ChatTypeInfo["SYSTEM"] );
				return;
			end
		
		else
			BWDKP_Message( BWD_INVALID_OPTION, ChatTypeInfo["SYSTEM"] );
			return;		
		end
	
	-- Saves a raid, doesn't change anything
	elseif( command == "save" ) then
		BWDKP_Config.message = BWD_DATA_SAVED;
		ReloadUI();
		
	-- Clear all saved data
	elseif( command == "clear" ) then
		-- Clean up the friends list if we're clearing while a raid is open
		if( OpenRaid ) then
			-- Get current friends list
			local FriendsList = {};
			for i=1, GetNumFriends() do
				local name = GetFriendInfo( i );
				FriendsList[ name ] = true;
			end

			for name in pairs( BWDKP_Raids[ OpenRaid ].Block ) do
				if( not BWDKP_Raids[ OpenRaid ]["Friends"][ name ] and FriendsList[ name ] ) then
					BWDKP_Config["Block"][ name ] = true;
					RemoveFriend( name, true );
				end
			end
		end
	
		OpenRaid = nil;
		BWDKP_Raids = {};
		DKP_Raid = {};
		
		BWDKP_Config.message = BWD_DATA_CLEARED;
		ReloadUI();
	end
end

function BWDKP_Message( msg, color )
	if( color == nil ) then
		color = { r = 1, g = 1, b = 1 };
	end
	
	DEFAULT_CHAT_FRAME:AddMessage( msg, color.r, color.g, color.b );
end

function BWDKP_RaidMessage( msg )
	SendChatMessage( msg, "RAID" );
end

function BWDKP_SendWhisper( msg, target )
	SendChatMessage( msg, "WHISPER", nil, target );
end

-- This converts the BoWDKP raids format into the old DKP system so that it can be uploaded using DKP.exe
function BWDKP_ConvertRaids()
	DKP_Raid = { RaidList = {} };
	local ParsedRaids = {};
	
	for raidName, raid in pairs( BWDKP_Raids ) do
		-- Only add raids that we're ended
		if( raid.EndTime ) then
			local _, _, _, _, name = string.find( raidName, "^([0-9]+)%.([0-9]+)%-(.+)" );
			
			if( name ) then
				local parsedRaid = { PlayerList = {}, LootList = {} };

				-- Add the raid info
				parsedRaid.Name = name;
				parsedRaid.EndTime = math.ceil( raid.EndTime );
				parsedRaid.StartTime = math.ceil( raid.StartTime );
				parsedRaid.Factor = raid.Factor;
				parsedRaid.Ended = true;
				
				-- Add sit
				for playerName, attendance in pairs( raid.Sit ) do
					local parsedPlayer = {};
					parsedPlayer.Name = playerName;
					parsedPlayer.Time = math.ceil( attendance.TimeInSit / 60 );
	
					table.insert( parsedRaid.PlayerList, parsedPlayer );
				end
				
				-- Add raid
				for playerName, attendance in pairs( raid.Raid ) do
					local parsedPlayer = {};
					
					-- Add the worthless info so it doesn't break
					parsedPlayer.Race = attendance.Race;
					parsedPlayer.Class = attendance.Class;
					parsedPlayer.Guild = attendance.Guild;
					parsedPlayer.Level = 60;
					parsedPlayer.PvPRank = 0;
					
					--[[
					if( parsedPlayer.Class == BWR_DRAENEI ) then
						parsedPlayer.Class = BWR_HUMAN;
					elseif( parsedPlayer.Class == BWR_BLOODELF ) then
						parsedPlayer.Class = BWR_UNDEAD;
					end
					]]
					
					parsedPlayer.Name = playerName;
					parsedPlayer.Time = math.ceil( attendance.TimeInRaid / 60 );
					
					-- Are they already on from sit?
					for i=#( parsedRaid.PlayerList ), 1, -1 do
						local player = parsedRaid["PlayerList"][ i ];
						if( player.Name == playerName ) then
							parsedPlayer.Time = parsedPlayer.Time + player.Time;
						end
					end
	
					table.insert( parsedRaid.PlayerList, parsedPlayer );
				end
				
				-- Add loot
				for _, loot in pairs( raid.Loot ) do
					table.insert( parsedRaid.LootList, { Name = loot.Winner, Loot = loot.Item, Points = "0" } );
				end
				
				-- Finally add it
				table.insert( ParsedRaids, parsedRaid );
			end
		end
	end
	
	-- HACKS R FUN
	-- We have to run this through VarConverter.class next
	DKP_Raid.RaidList = BWDKP_ConvertTable( ParsedRaids );
end

function BWDKP_ConvertTable( convertTable )
	if( not convertTable ) then
		return nil;
	end
	
	local NewTable = {};
	
	for key, value in pairs( convertTable ) do 
		-- Table value, so go through it and translate those values too
		if( type( value ) == "table" ) then
			-- Number key, so turn it into a string
			if( type( key ) == "number" ) then
				key = tostring( key );
			end
			
			NewTable[ key ] = BWDKP_ConvertTable( value );
		
		-- Number key, non-table value turn the key into a string
		elseif( type( key ) == "number" ) then
			NewTable[ tostring( key ) ] = value;
		
		-- Misc
		else
			NewTable[ key ] = value;
		end
	end
	
	return NewTable;
end

-- Raid tracking and such
function BWDKP_CheckRaid()
	if( not OpenRaid ) then
		return;
	end
	
	-- Make a quick list of the current raid
	local RaidRoster = {};
	for i=1, GetNumRaidMembers() do
		local name, _, _, _, _, _, _, isOnline = GetRaidRosterInfo( i );
		
		-- By only adding the names of people who are online it'll just look like they left the raid to the mod
		if( isOnline ) then
			RaidRoster[ name ] = "raid" .. i;
		end
	end
		
	-- Get current friends list
	local FriendsList = {};
	for i=1, GetNumFriends() do
		local name = GetFriendInfo( i );
		FriendsList[ name ] = true;
	end

	local CurrentTime = GetTime();
	
	-- Were they on the waitlist?
	for name, attendance in pairs( BWDKP_Raids[ OpenRaid ].Sit ) do
		if( RaidRoster[ name ] ) then
			if( not attendance.LeftSit ) then
				attendance.TimeInRaid = ( attendance.TimeInSit or 0 ) + CurrentTime - attendance.LastUpdate;
				attendance.TimeInSit = attendance.TimeInRaid;
			else
				attendance.TimeInRaid = attendance.TimeInSit;
			end
			
			-- Merge attendance if they were in the raid, joined sit then rejoined the raid
			if( BWDKP_Raids[ OpenRaid ]["Raid"][ name ] ) then
				attendance.TimeInRaid = attendance.TimeInRaid + BWDKP_Raids[ OpenRaid ]["Raid"][ name ].TimeInRaid
				attendance.TimeInSit = attendance.TimeInSit or 0 + BWDKP_Raids[ OpenRaid ]["Raid"][ name ].TimeInSit or 0;
			end
			
			attendance.LastUpdate = CurrentTime;
			attendance.LeftSit = nil;
			
			BWDKP_Raids[ OpenRaid ]["Raid"][ name ] = attendance;			
			BWDKP_Raids[ OpenRaid ]["Sit"][ name ] = nil;
			
			-- They joined the raid, no longer need to keep track of them on friends
			if( not BWDKP_Raids[ OpenRaid ]["Friends"][ name ] and FriendsList[ name ] ) then
				BWDKP_Config["Block"][ name ] = true;
				RemoveFriend( name, true );
			end
		end
	end
	
	-- Now check the people currently in the raid
	for name, attendance in pairs( BWDKP_Raids[ OpenRaid ].Raid ) do
		-- Players inside the raid, update the time in raid
		if( RaidRoster[ name ] ) then
			if( not attendance.LeftRaid ) then
				attendance.TimeInRaid = ( attendance.TimeInRaid or 0 ) + CurrentTime - attendance.LastUpdate;
				attendance.LastUpdate = CurrentTime;				
			
			-- Player has just rejoined raid, so start the counter again
			else
				attendance.LastUpdate = CurrentTime;
				attendance.LeftRaid = nil;
			end
			
			BWDKP_Raids[ OpenRaid ]["Raid"][ name ] = attendance;
	
		-- Player left raid, update the time and set that they left
		elseif( not attendance.LeftRaid ) then
			attendance.TimeInRaid = ( attendance.TimeInRaid or 0 ) + CurrentTime - attendance.LastUpdate;
			attendance.LastUpdate = CurrentTime;
			attendance.LeftRaid = true;
			
			BWDKP_Raids[ OpenRaid ]["Raid"][ name ] = attendance;
		end
	end
	
	-- Add everyone whos in the raid but isn't in the logging system yet
	for name, unitid in pairs( RaidRoster ) do
		if( not BWDKP_Raids[ OpenRaid ]["Raid"][ name ] ) then
			BWDKP_Raids[ OpenRaid ]["Raid"][ name ] = { LastUpdate = CurrentTime, Race = UnitRace( unitid ), Class = UnitClass( unitid ), Guild = GetGuildInfo( unitid ) };
		end
	end
end

-- Check friends list for online people, really this isn't used half of the time
function BWDKP_CheckFriends()
	if( not OpenRaid ) then
		return;
	end

	local CurrentTime = GetTime();
	
	for i=1, GetNumFriends() do
		local name, _, _, _, isOnline = GetFriendInfo( i );
		
		if( BWDKP_Raids[ OpenRaid ]["Sit"][ name ] ) then
			local attendance = BWDKP_Raids[ OpenRaid ]["Sit"][ name ];
			
			if( isOnline ) then
				-- They are online and were online last update
				if( not attendance.LeftSit ) then
					attendance.TimeInSit = ( attendance.TimeInSit or 0 ) + CurrentTime - attendance.LastUpdate;
					attendance.LastUpdate = CurrentTime;
				else
					attendance.LastUpdate = CurrentTime;
					attendance.LeftSit = nil;
				end

			-- They've gone offline, update the time in sit and flag it as they left
			elseif( not attendance.LeftSit ) then
				attendance.TimeInSit = ( attendance.TimeInSit or 0 ) + CurrentTime - attendance.LastUpdate;
				attendance.LastUpdate = CurrentTime;
				attendance.LeftSit = true;
			end
			
			BWDKP_Raids[ OpenRaid ]["Sit"][ name ] = attendance;
		end
	end
end

-- Check sit if they are online
function BWDKP_CheckSit()
	if( not OpenRaid ) then
		return;
	end
	
	local CurrentTime = GetTime();
	local AlreadyUpdated = {};
	local FriendsList = {};
	
	-- Check friends list
	for i=1, GetNumFriends() do
		local name = GetFriendInfo( i );
		
		if( name ) then
			FriendsList[ name ] = true;
		end
	end
	
	for i=1, GetNumGuildMembers() do
		local name, _, _, _, _, _, note, _, isOnline = GetGuildRosterInfo( i );
		
		for sitName, attendance in pairs( BWDKP_Raids[ OpenRaid ].Sit ) do
			-- Check if they are on an alt with the character name in a note
			if( ( sitName == name or string.find( note, sitName ) ) and not AlreadyUpdated[ sitName ] ) then
				if( isOnline ) then
					-- They're online and wern't just offline, update time in sit
					if( not attendance.LeftSit ) then
						attendance.TimeInSit = ( attendance.TimeInSit or 0 ) + CurrentTime - attendance.LastUpdate;
						attendance.LastUpdate = CurrentTime;
					else
						attendance.LastUpdate = CurrentTime;
						attendance.LeftSit = nil;
					end
					
				-- They've gone offline, update the time in sit and flag it as they left
				elseif( not attendance.LeftSit ) then
					attendance.TimeInSit = ( attendance.TimeInSit or 0 ) + CurrentTime - attendance.LastUpdate;
					attendance.LastUpdate = CurrentTime;
					attendance.LeftSit = true;
				end
				
				BWDKP_Raids[ OpenRaid ]["Sit"][ sitName ] = attendance;
				AlreadyUpdated[ sitName ] = true;
				
				-- Remove them from the friends list if they are guilded and not saved
				if( not BWDKP_Raids[ OpenRaid ]["Friends"][ sitName ] and FriendsList[ sitName ] ) then
					BWDKP_Config["Block"][ sitName ] = true;
					RemoveFriend( sitName, true );
				end
			end
		end
	end
	
	-- Update anyone that isn't guilded, or doesn't have a guilded alt as offline if they aren't on the friends list
	for name, attendance in pairs( BWDKP_Raids[ OpenRaid ].Sit ) do
		if( not AlreadyUpdated[ name ] and not attendance.LeftSit and not FriendsList[ name ] ) then
			attendance.TimeInSit = ( attendance.TimeInSit or 0 ) + CurrentTime - attendance.LastUpdate;
			attendance.LastUpdate = CurrentTime;
			attendance.LeftSit = true;
			
			BWDKP_Raids[ OpenRaid ]["Sit"][ name ] = attendance;
		end
	end
end

-- Dumps the active raid, only meant for debugging purposes
function BWDKP_Debug()
	local raid = BWDKP_Raids[ OpenRaid ];
	
	if( not raid ) then
		BWDKP_Message( "No open raid found." );
	end
	
	BWDKP_Message( "Start " .. date( "%c", raid.StartTime ) );
	BWDKP_Message( "Current " .. date( "%c", ( raid.EndTime or GetTime() ) ) );
	BWDKP_Message( "Run Time " .. ( raid.RunTime or 0 / 60 ) .. " minutes." );
	
	BWDKP_Message( "In-Raid" );
	for name, attendance in pairs( raid.Raid ) do
		BWDKP_Message( "  " .. name .. ": Last " .. date( "%c", attendance.LastUpdate ) .. " In Raid " .. attendance.TimeInRaid or 0 );
	end

	BWDKP_Message( "On-Sit" );
	for name, attendance in pairs( raid.Sit ) do
		BWDKP_Message( "  " .. name .. ": Last " .. date( "%c", attendance.LastUpdate ) .. " On Sit " .. attendance.TimeInSit or 0 );
	end
	
	BWDKP_Message( "Loot" );
	for _, loot in pairs( raid.Loot ) do
		BWDKP_Message( "  " .. loot.Winner .. ": Item " .. loot.Item .. " / Waiting: " .. tostring( loot.IsWaiting ) );
	end
end

-- Handles the time in raid stuff
function BWDKP_OnUpdate( elapsed )
	if( OpenRaid ) then
		TimeElapsed = TimeElapsed + elapsed;
		
		if( TimeElapsed >= 60 ) then
			BWDKP_CheckRaid();
			GuildRoster();
			
			TimeElapsed = 0;
		end
	end
end

-- Block BoWDKP whispers from being seen as sent
function BWDKP_ChatFrame_OnEvent( event )
	if( event == "CHAT_MSG_WHISPER_INFORM" and string.find( arg1, "%<BoWDKP%>" ) ) then
		return;
	end
	
	-- Are we blocking friend messages
	if( event == "CHAT_MSG_SYSTEM" ) then
		for _, text in pairs( BlockMessages ) do
			local _, _, name = string.find( arg1, text );
			
			-- Are we suppose to unblock them after getting the message?
			if( name and BWDKP_Config["Block"][ name ] ) then
				BWDKP_Config["Block"][ name ] = nil;
				
				if( OpenRaid ) then
					BWDKP_Raids[ OpenRaid ]["Block"][ name ] = nil;
				end
				return;
			end
			
			-- Block them all the time
			if( name and OpenRaid and BWDKP_Raids[ OpenRaid ]["Block"][ name ] ) then
				return;
			end
		end
	end
	
	Orig_ChatFrame_OnEvent( event );
end

-- Show a loot frame
function BWDKP_ShowLoot( itemName, itemLink, rarity )
	if( OPENED_LOOT_WINDOWS >= MAX_LOOT_WINDOWS ) then
		return;
	end
	
	OPENED_LOOT_WINDOWS = OPENED_LOOT_WINDOWS + 1;
	
	local frame = getglobal( "BWDKPLoot" .. OPENED_LOOT_WINDOWS );
	if( not frame ) then
		frame = CreateFrame( "Frame", "BWDKPLoot" .. OPENED_LOOT_WINDOWS, LootFrame, "DKPLootTemplate" );
		frame:SetBackdropColor( 0, 0, 0, 0.70 );
		
		CREATED_LOOT_WINDOWS = CREATED_LOOT_WINDOWS + 1;
	end
		
	if( OPENED_LOOT_WINDOWS == 1 ) then
		frame:SetPoint( "TOPLEFT", "LootFrame", "TOPRIGHT", -65, -13 );
	else
		frame:SetPoint( "TOPLEFT", "BWDKPLoot" .. ( OPENED_LOOT_WINDOWS - 1 ), "TOPLEFT", 0, -75 );
	end
	
	getglobal( frame:GetName() .. "Item" ):SetText( itemLink );
	
	frame.itemName = itemName;
	frame.itemLink = itemLink;
	frame.itemQuality = rarity;
	frame:Show();
end

-- Loot event
function BWDKP_LootWon()
	local parent = this:GetParent();
	local cost = getglobal( parent:GetName() .. "Points" ):GetText();
	if( not cost or cost == "" ) then
		cost = BWD_TBA;
	end
	
	table.insert( WatchLoot, parent.itemName );
	BWDKP_RaidMessage( string.format( BWD_LOOT_WON, getglobal( parent:GetName() .. "Player" ):GetText(), parent.itemLink, cost ) );
end

function BWDKP_LootAnnounce()
	local parent = this:GetParent();
	local cost = getglobal( parent:GetName() .. "Points" ):GetText();
	if( not cost or cost == "" ) then
		cost = BWD_TBA;
	end
	
	BWDKP_RaidMessage( string.format( BWD_LOOT_ANNOUNCE, parent.itemLink, cost ) );
end

function BWDKP_LootLastCall()
	local parent = this:GetParent();
	local cost = getglobal( parent:GetName() .. "Points" ):GetText();
	if( not cost or cost == "" ) then
		cost = BWD_TBA;
	end
	
	BWDKP_RaidMessage( string.format( BWD_LOOT_LASTCALL, parent.itemLink, cost ) );
end

function BWDKP_LootRot()
	local parent = this:GetParent();
	local cost = getglobal( parent:GetName() .. "Points" ):GetText();
	if( not cost or cost == "" ) then
		cost = BWD_TBA;
	end
	
	BWDKP_RaidMessage( string.format( BWD_LOOT_ROT, parent.itemLink, cost ) );
end

function BWDKP_LootDE()
	-- Make sure to remove the watch loot incase the winner changed there mind
	for i=#( WatchLoot ), 1, -1 do
		if( WatchLoot[ i ] == this:GetParent().itemName ) then
			table.remove( WatchLoot, i );
		end
	end
	
	BWDKP_RaidMessage( string.format( BWD_LOOT_DE, this:GetParent().itemLink ) );
end

function BWDKP_HideAllManagement()
	for i=1, CREATED_LOOT_WINDOWS do
		local frame = getglobal( "BWDKPLoot" .. i );
		
		getglobal( frame:GetName() .. "Points" ):SetText( "" );
		getglobal( frame:GetName() .. "Player" ):SetText( "" );
		
		frame.itemLink = nil;
		frame.itemName = nil;
		frame.itemQuality = nil;
		frame:Hide();
	end
end

function BWDKP_DisplayLootMangement()
	BWDKP_HideAllManagement();
	
	OPENED_LOOT_WINDOWS = 0;
	for i=1, GetNumLootItems() do
		local _, itemName, _, rarity = GetLootSlotInfo( i );
		
		if( rarity >= 4 and itemName ~= "" ) then
			BWDKP_ShowLoot( itemName, GetLootSlotLink( i ), rarity );
		end
	end
end

-- Award an item to somebody
function BWDKP_ItemAwarded( itemName, winner )
	if( not OpenRaid or not itemName or not winner ) then
		return;
	end
	
	-- Is this a quest item?
	for _, loot in pairs( BWD_QUEST_ITEMS ) do
		if( loot.item == itemName ) then

			-- Find the players class
			local winnerClass;
			for i=1, GetNumRaidMembers() do
				local name, _, _, _, _, class = GetRaidRosterInfo( i );
				if( name == winner ) then
					winnerClass = class;
					break;
				end
			end
			
			-- No class found
			if( not winnerClass ) then
				BWDKP_Message( string.format( BWD_LOOT_NO_CLASS, winner, itemName ), { r = 1, g = 0, b = 0 } );
				return;
			end
			
			-- Now find the set
			local itemSet, itemFormat;
			
			for _, set in pairs( BWD_ITEM_SETS ) do
				if( set.class == winnerClass and set.tier == loot.tier ) then
					itemSet = set.set;
					itemFormat = ( set.format or "%set %item" );
					break;
				end
			end
			
			-- No set found
			if( not itemSet ) then
				BWDKP_Message( string.format( BWD_LOOT_NO_SET, itemName, winner ), { r = 1, g = 0, b = 0 } );
				return;
			end
			
			-- Item has only one type, so we can record it now
			if( not loot.IsMulti ) then
				local itemType;
				if( loot.type[ winnerClass ] ) then
					itemType = loot.type[ winnerClass ]
				else
					itemType = loot.type.ALL;
				end

				if( not itemType ) then
					BWDKP_Message( string.format( BWD_LOOT_NO_TYPE, itemName, winner ), { r = 1, g = 0, b = 0 } );
					return;
				end
				
				local realName = string.gsub( string.gsub( itemFormat, "%%item", itemType ), "%%set", itemSet );
				
				table.insert( BWDKP_Raids[ OpenRaid ].Loot, { Item = realName, Winner = winner } );
			else
				local itemTypes = {};
				for type, _ in pairs( loot.type ) do
					table.insert( itemTypes, type );
				end
				
				-- Setup the default item incase they don't respond
				local itemType;
				if( loot.type[ loot.defaultType ][ winnerClass ] ) then
					itemType = loot.type[ loot.defaultType ][ winnerClass ]
				else
					itemType = loot.type[ loot.defaultType ].ALL;
				end
				
				if( not itemType ) then
					BWDKP_Message( string.format( BWD_LOOT_NO_TYPE, itemName, winner ), { r = 1, g = 0, b = 0 } );
					return;
				end
			
				local realName = string.gsub( string.gsub( itemFormat, "%%item", itemType ), "%%set", itemSet );
				
				-- Alright, make a list of the possible items if they whisper the type back
				local items = {};
				for _, type in pairs( itemTypes ) do
					if( loot.type[ type ][ winnerClass ] ) then
						items[ type ] = string.gsub( string.gsub( itemFormat, "%%item", loot.type[ type ][ winnerClass ] ), "%%set", itemSet );					
					else
						items[ type ] = string.gsub( string.gsub( itemFormat, "%%item", loot.type[ type ].ALL ), "%%set", itemSet );
					end
				end
				
				-- This means that if they havn't chosen it uses the default one, but if they end up whispering we can change it
				table.insert( BWDKP_Raids[ OpenRaid ].Loot, { Item = realName, Winner = winner, IsWaiting = true, PossibleItems = items } );
				
				-- Now send the whisper
				BWDKP_SendWhisper( string.format( BWD_REQUEST_TYPE, itemName, #( itemTypes ), table.concat( itemTypes, ", " ) ), winner );
				BWDKP_SendWhisper( string.format( BWD_REQUEST_NOTE, loot.defaultType ), winner );
			end
			return;
		end
	end
	
	-- Nope, just add it
	table.insert( BWDKP_Raids[ OpenRaid ].Loot, { Item = itemName, Winner = winner } );
end

-- Parses GlobalStrings
function BWDKP_ParseString( txt )
	txt = string.gsub( txt, "%%s", "(.+)" );
	txt = string.gsub( txt, "%[", "%%[" );
	txt = string.gsub( txt, "%]", "%%]" );
	
	return txt;
end

-- Friend handling
function BWDKP_AddFriend( name, isAuto )
	if( isAuto ) then
		return;
	end
	
	-- They added a new friend manually, remove any blocks
	-- add them to the friends list of an open raid
	BWDKP_Config["Block"][ name ] = nil;
	if( OpenRaid ) then
		BWDKP_Raids[ OpenRaid ]["Friends"][ name ] = true;
		BWDKP_Raids[ OpenRaid ]["Block"][ name ] = nil;
	end
end

function BWDKP_RemoveFriend( friend, isAuto )
	if( isAuto ) then
		return;
	end
	
	local name;
	-- Removed by index, turn it into a name
	if( type( friend ) == "number" ) then
		name = ( GetFriendInfo( friend ) );	
	else
		name = friend;
	end
	
	-- Friend removed from the list, clear any blocks and remove it from the friend list
	if( name ) then
		BWDKP_Config["Block"][ name ] = nil;
		if( OpenRaid ) then
			BWDKP_Raids[ OpenRaid ]["Friends"][ name ] = nil;
			BWDKP_Raids[ OpenRaid ]["Block"][ name ] = nil;
		end
	end
end

-- Event handler
function BWDKP_OnEvent( event )
	if( event == "VARIABLES_LOADED" ) then
		if( not BWDKP_Raids ) then
			BWDKP_Raids = {};		
		end
		
		if( not BWDKP_Config ) then
			BWDKP_Config = { Block = {} };
		
		elseif( not BWDKP_Config["Block"] ) then
			BWDKP_Config["Block"] = {};
		end
		
		-- Check for an open raid
		for name, raid in pairs( BWDKP_Raids ) do
			if( raid.StartTime and not raid.EndTime ) then
				OpenRaid = name
				
				BWDKP_Message( string.format( BWD_RAID_RUNNING, OpenRaid ), { r = 1, g = 0, b = 0 } );
				UIErrorsFrame:AddMessage( string.format( BWD_RAID_RUNNING, OpenRaid ), ChatTypeInfo["SYSTEM"].r, ChatTypeInfo["SYSTEM"].g, ChatTypeInfo["SYSTEM"].b, 1 );
				
				BWDKP_CheckFriends();
				break;
			end
		end
		
		Orig_ChatFrame_OnEvent = ChatFrame_OnEvent;
		ChatFrame_OnEvent = BWDKP_ChatFrame_OnEvent;
		
		PlayerJoinedRaid = BWDKP_ParseString( ERR_RAID_MEMBER_ADDED_S );
		PlayerLeftRaid = BWDKP_ParseString( ERR_RAID_MEMBER_REMOVED_S );		

		BlockMessages = {	BWDKP_ParseString( ERR_FRIEND_ONLINE_SS ),
					BWDKP_ParseString( ERR_FRIEND_REMOVED_S ),
					BWDKP_ParseString( ERR_FRIEND_ADDED_S ),
					BWDKP_ParseString( ERR_FRIEND_ALREADY_S ),
					BWDKP_ParseString( ERR_FRIEND_OFFLINE_S ) };
		
		FriendOnline = BWDKP_ParseString( ERR_FRIEND_ONLINE_SS );
		FriendOffline = BWDKP_ParseString( ERR_FRIEND_OFFLINE_S );
		
		-- Do we have a message to show?
		if( BWDKP_Config.message ) then
			UIErrorsFrame:AddMessage( BWDKP_Config.message, ChatTypeInfo["SYSTEM"].r, ChatTypeInfo["SYSTEM"].g, ChatTypeInfo["SYSTEM"].b, 1 );
			BWDKP_Config.message = nil;
		end
		
		-- Hook friends functions for things added in the middle of the raid
		hooksecurefunc( "AddFriend", BWDKP_AddFriend );
		hooksecurefunc( "RemoveFriend", BWDKP_RemoveFriend );
		
	-- Hide/shows the loot announce window
	elseif( event == "LOOT_OPENED" and OpenRaid ) then
		BWDKP_DisplayLootMangement();
	elseif( event == "LOOT_CLOSED" and OpenRaid ) then
		BWDKP_HideAllManagement();
	
	-- Somebody looted, add them to the list
	elseif( event == "CHAT_MSG_LOOT" and OpenRaid and #( WatchLoot ) > 0 ) then
		for i=#( WatchLoot ), 1, -1 do
			local itemName = WatchLoot[ i ];
			if( string.find( arg1, itemName ) ) then
				local ItemWinner;
				if( string.find( arg1, BWD_OTHER_REC_LOOT ) ) then
					_, _, ItemWinner = string.find( arg1, BWD_OTHER_REC_LOOT );				
				elseif( string.find( arg1, BWD_YOU_REC_LOOT ) ) then
					ItemWinner = UnitName( "player" );
				end
				
				if( ItemWinner ) then
					BWDKP_ItemAwarded( itemName, ItemWinner );
					table.remove( WatchLoot, i );
				end
			end
		end
		
	
	-- Check for raid join/leave/player join/player left and friend status changes
	elseif( event == "CHAT_MSG_SYSTEM" ) then
		if( arg1 == ERR_RAID_YOU_JOINED or arg1 == ERR_RAID_YOU_LEFT or string.find( arg1, PlayerJoinedRaid ) or string.find( arg1, PlayerLeftRaid ) ) then
			BWDKP_CheckRaid();
		
		-- Update friends list
		elseif( string.find( arg1, FriendOnline ) or string.find( arg1, FriendOffline ) ) then
			BWDKP_CheckFriends();
		end
	
	-- Roster updated, check everyone on sit
	elseif( event == "GUILD_ROSTER_UPDATE" and OpenRaid ) then
		BWDKP_CheckSit();			

	-- Whisper triggers
	elseif( event == "CHAT_MSG_WHISPER" ) then
		if( arg1 == BWD_SIT ) then
			-- Do we even have a raid open?
			if( OpenRaid ) then
				-- Dont re-add them if they are already on sit or in the raid
				if( not BWDKP_Raids[ OpenRaid ]["Sit"][ arg2 ] ) then
					BWDKP_SendWhisper( string.format( BWD_ADDED_SIT, OpenRaid ), arg2 );
					
					BWDKP_Message( string.format( BWD_ADDED_TO_SIT, arg2, OpenRaid ), ChatTypeInfo["SYSTEM"] );
					BWDKP_Raids[ OpenRaid ]["Sit"][ arg2 ] = { LastUpdate = GetTime(), TimeInSit = 0 };
					
					-- Make sure they aren't guilded using the last requested info
					-- not supposed to be 100% accurate
					for i=1, GetNumGuildMembers() do
						local name = GetGuildRosterInfo( i );
						if( name == arg2 ) then
							return;
						end
					end
					
					-- Add to friends list
					BWDKP_Raids[ OpenRaid ]["Block"][ arg2 ] = true;
					if( BWDKP_Raids[ OpenRaid ]["Friends"][ arg2 ] ) then
						BWDKP_Config["Block"][ arg2 ] = true;
					end

					AddFriend( arg2, true );
				else
					BWDKP_SendWhisper( string.format( BWD_ALREADY_SAT, OpenRaid ), arg2 );
				end
			else
				BWDKP_SendWhisper( BWD_NO_RAID_OPEN, arg2 );
			end
		
		
		--[[
		elseif( arg1 == BWD_UNSIT ) then
			if( OpenRaid ) then
				if( BWDKP_Raids[ OpenRaid ]["Sit"][ arg2 ] ) then
					local CurrentTime = GetTime();
					
					local sitAttendance = BWDKP_Raids[ OpenRaid ]["Sit"][ arg2 ];
					local raidAttendance = BWDKP_Raids[ OpenRaid ]["Raid"][ arg2 ];
					
					if( not sitAttendance.LeftSit ) then
						sitAttendance.TimeInRaid = ( sitAttendance.TimeInSit or 0 ) + CurrentTime - sitAttendance.LastUpdate;
						sitAttendance.TimeInSit = attendance.TimeInRaid;
					else
						sitAttendance.TimeInRaid = sitAttendance.TimeInSit;
					end
					
					-- They have an attendance record in raid, merge it
					if( raidAttendance ) then
						sitAttendance.TimeInRaid = sitAttendance.TimeInRaid + raidAttendance.TimeInRaid
						sitAttendance.TimeInSit = ( sitAttendance.TimeInSit or 0 ) + ( raidAttendance.TimeInSit or 0 );
					end
					
					sitAttendance.LastUpdate = CurrentTime;
					sitAttendance.LeftSit = nil;
					
					BWDKP_Raids[ OpenRaid ]["Sit"][ arg2 ] = nil;
					BWDKP_Raids[ OpenRaid ]["Raid"][ arg2 ] = sitAttendance;
					
					BWDKP_SendWhisper( string.format( BWD_WHISPER_REMOVEDSIT, OpenRaid ), arg2 );
				else
					BWDKP_SendWhisper( string.format( BWD_WHISPER_NOSIT, OpenRaid ), arg2 );
				end
			else
				BWDKP_SendWhisper( BWD_NO_RAID_OPEN, arg2 );
			end
		]]
		
		elseif( arg1 == BWD_RAIDSTATUS and OpenRaid ) then
			BWDKP_SendWhisper( string.format( BWD_WHISPER_RAIDSTATUS, GetNumRaidMembers(), MAX_RAID_MEMBERS, OpenRaid ), arg2 );
			
		elseif( OpenRaid ) then
			local msg = string.lower( arg1 );
			
			-- Check if it's a trigger
			for _, trigger in pairs( BWD_WHISPER_TYPES ) do
				-- Alright, it's a trigger check if they have any pending items
				if( trigger == msg ) then
					for id, loot in pairs( BWDKP_Raids[ OpenRaid ].Loot ) do
						-- Okay, found a winner!
						if( loot.Winner == arg2 and loot.IsWaiting ) then
							local itemName = loot.PossibleItems[ trigger ];

							loot.Item = itemName;
							loot.IsWaiting = nil;
							loot.PossibleItems = nil;
								
							BWDKP_Raids[ OpenRaid ].Loot[ id ] = loot;
							
							BWDKP_Message( string.format( BWD_ITEM_CONFIRMED, arg2, itemName ), ChatTypeInfo["SYSTEM"] );
							BWDKP_SendWhisper( string.format( BWD_WHISPER_ITEMCONFIRMED, itemName, trigger ), arg2 );
							return;
						end
					end
					
					-- Nope, no record
					BWDKP_SendWhisper( BWD_WHISPER_NORECORD, arg2 );
				end
			end		
		end
	end
end