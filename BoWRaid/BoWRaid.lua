local Orig_ChatFrame_OnEvent;

local InvitedMember = {};

local FormedRaidInvited = "";
local IsFormedRaid;
local AcceptPartyInvite;

-- Ping responses
local PongResponse = {};
local IsWaitingPong;

-- Timers
local ScheduledEvents = {};
local TimeElapsed = 0;

-- GlobalStrings.lua text changed to regex for matching
local JOINED_PARTY_SEARCH;
local JOINED_RAID_SEARCH;
local CONVERTED_RAID_SEARCH;
local CANNOT_FIND_SEARCH;
local MEMBER_GROUPED_SEARCH;

-- Default configuration
local DefaultConfig;

function BWRaid_OnLoad()
	this:RegisterEvent( "VARIABLES_LOADED" );
	
	this:RegisterEvent( "PARTY_INVITE_REQUEST" );
	
	this:RegisterEvent( "CHAT_MSG_WHISPER" );
	this:RegisterEvent( "CHAT_MSG_ADDON" );
	
	this:RegisterEvent( "CHAT_MSG_SYSTEM" );
	
	SLASH_FORMRAID1 = "/raidform";
	SLASH_FORMRAID2 = "/rf";
	SlashCmdList["FORMRAID"] = BWRaid_FormRaid;
	
	SLASH_BOWRAID1 = "/bowraid";
	SLASH_BOWRAID2 = "/bwraid";
	SLASH_BOWRAID3 = "/bwr";
	SlashCmdList["BOWRAID"] = BWRaid_SlashHandler;
	
	SLASH_RESETBW1 = "/resetbw";
	SLASH_RESETBW2 = "/bwreset";
	SlashCmdList["RESETBW"] = BWRaid_SendResetBW;
	
	SLASH_BWRHELP1 = "/bwradmin";
	SLASH_BWRHELP2 = "/bowraidadmin";
	SLASH_BWRHELP3 = "/bwra";
	SlashCmdList["BWRHELP"] = BWRaid_AdminCommands;
	
	SLASH_BWRPING1 = "/bwping"
	SLASH_BWRPING2 = "/bwrping";
	SlashCmdList["BWRPING"] = BWRaid_SendPing;
	
	SLASH_FRELEASE1 = "/frelease";
	SlashCmdList["FRELEASE"] = BWRaid_SendRelease;
	
	SLASH_FLOGOUT1 = "/flogout";
	SlashCmdList["FLOGOUT"] = BWRaid_SendLogout;
end

function BWRaid_AdminCommands( msg )
	for _, msg in pairs(BWR_ADMIN_CMD) do
		BWRaid_Message( msg, ChatTypeInfo["SYSTEM"] );
	end
end

function BWRaid_HelpCommands( msg )
	for _, msg in pairs(BWR_HELP_CMD) do
		BWRaid_Message( msg, ChatTypeInfo["SYSTEM"] );
	end
end

function BWRaid_SlashHandler( msg )
	if( msg and string.lower( msg ) == "help" ) then
		BWRaid_HelpCommands( msg );
		return;
	end
	
	UIParentLoadAddOn( "SSUI" );
	SSUI:ShowConfig( "bwr" );
end

function BWRaid_Message( msg, color )
	if( color == nil ) then
		color = { r = 1, g = 1, b = 1 };
	end
	
	DEFAULT_CHAT_FRAME:AddMessage( msg, color.r, color.g, color.b );
end

function BWRaid_ParseString( text )
	text = string.gsub( text, "%)", "%%)" );
	text = string.gsub( text, "%(", "%%(" );
	text = string.gsub( text, "%:", "%%:" );

	text = string.gsub( text, "%%d", "([0-9]+)" );
	text = string.gsub( text, "%%s", "(.+)" );
	
	return text;
end


-- Whisper blocking
function BWRaid_ChatFrame_OnEvent( event )
	if( event == "CHAT_MSG_WHISPER" or event == "CHAT_MSG_WHISPER_INFORM" ) then
		if( string.find( arg1, "^%[BW%]" ) ) then
			return;
		end
		
		-- Block messages we send if spam block is on
		if( event == "CHAT_MSG_WHISPER_INFORM" and BWRaid_Config.blockSpam and string.find( arg1, "^%<BWRaid%>" ) ) then
			return
		end
	end
	
	Orig_ChatFrame_OnEvent( event );
end

-- Form raid
function BWRaid_FormRaid( msg )
	if( not msg or msg == "" ) then
		BWRaid_Message( BWR_NO_NAME, ChatTypeInfo["SYSTEM"] );
		return;

	elseif( GetNumRaidMembers() > 0 ) then
		BWRaid_Message( BWR_IN_RAID, ChatTypeInfo["SYSTEM"] );
		return;
	end
	
	local raidOpen;
	local player = msg;
	
	if( string.find( msg, "(.+) (.+)" ) ) then
		_, _, player, raidOpen = string.find( msg, "(.+) (.+)" );
		
		if( raidOpen == "y" or raidOpen == "yes" ) then
			raidOpen = true;
		elseif( raidOpen == "n" or raidOpen == "no" ) then
			raidOpen = false;
		end
	end
	
	IsFormedRaid = true;
	FormedRaidInvited = player;
	
	SendChatMessage( "[BW] ACCEPTINVITE", "WHISPER", nil, player );
	InviteUnit( player );

	if( raidOpen ) then
		SendChatMessage( BWR_RAID_OPEN, "GUILD" );

		if( CanEditMOTD() and GetGuildRosterMOTD() ~= "" and not string.find( GetGuildRosterMOTD(), BWR_RAID_OPEN ) ) then
			GuildSetMOTD( GetGuildRosterMOTD() .. " " .. BWR_RAID_OPEN );
		end
	end
end

-- Reset BW command
function BWRaid_SendResetBW()
	if( GetNumRaidMembers() == 0 ) then
		BWRaid_Message( BWR_NOT_IN_RAID, ChatTypeInfo["SYSTEM"] );
		return;

	elseif( not BWRaid_PlayerHasPermission() ) then
		BWRaid_Message( BWR_NOPERMISSIONS, ChatTypeInfo["SYSTEM"] );
		return;
	end
	
	SendAddonMessage( "BWR", "RESETBW", "RAID" );
end

-- Force release
function BWRaid_SendRelease( msg )
	if( not msg or msg == "" ) then
		BWRaid_Message( BWR_NO_NAME, ChatTypeInfo["SYSTEM"] );
		return;
	
	elseif( GetNumRaidMembers() == 0 ) then
		BWRaid_Message( BWR_NOT_IN_RAID, ChatTypeInfo["SYSTEM"] );
		return;
	
	elseif( not BWRaid_PlayerHasPermission() ) then
		BWRaid_Message( BWR_NOPERMISSIONS, ChatTypeInfo["SYSTEM"] );
		return;
	end
	
	SendChatMessage( BWR_TRIG_RELEASE, "WHISPER", nil, msg );
	BWRaid_Message( string.format( BWR_FORCE_RELEASE_SENT, msg ), ChatTypeInfo["SYSTEM"] );
end

-- Force logout
function BWRaid_SendLogout( msg )
	if( not msg or msg == "" ) then
		BWRaid_Message( BWR_NO_NAME, ChatTypeInfo["SYSTEM"] );
		return;
	
	elseif( GetNumRaidMembers() == 0 ) then
		BWRaid_Message( BWR_NOT_IN_RAID, ChatTypeInfo["SYSTEM"] );
		return;
	
	elseif( not BWRaid_PlayerHasPermission() ) then
		BWRaid_Message( BWR_NOPERMISSIONS, ChatTypeInfo["SYSTEM"] );
		return;
	end
	
	SendChatMessage( BWR_TRIG_LOGOUT, "WHISPER", nil, msg );
	BWRaid_Message( string.format( BWR_FORCE_LOGOUT_SENT, msg ), ChatTypeInfo["SYSTEM"] );
end

-- Timer functions
function BWRaid_ScheduleEvent( functionName, timeDelay, eventName )
	table.insert( ScheduledEvents, { functionName, GetTime() + timeDelay, eventName } );
end

function BWRaid_UnScheduleEvent( functionName, eventName )
	local i=#( ScheduledEvents ), 1, -1 do
		local row = ScheduledEvents[ i ];
		if( row[1] == functionName ) then
			if( ( eventName == nil ) or ( eventName ~= nil and eventName == row[3] ) ) then
				table.remove( ScheduledEvents, i );		
			end
		end
	end
end

function BWRaid_OnUpdate( elapsed )
	TimeElapsed = elapsed + TimeElapsed;
	
	if( TimeElapsed > 0.1 ) then
		TimeElapsed = TimeElapsed - 0.1;
		local currentTime = GetTime();
		
		for i=#( ScheduledEvents ), 1, -1 do
			local row = ScheduledEvents[ i ];
			
			if( row[2] <= currentTime ) then
				table.remove( ScheduledEvents, i );

				if( type( row[1] ) == "function" ) then
					row[1]( row[3] );
				else
					getglobal( row[1] )( row[3] );
				end
			end
		end
	end
end


-- Permission check
function BWRaid_PlayerHasPermission()
	if( IsRaidLeader() or IsRaidOfficer() ) then
		return true;
	end
	
	return false;
end

	
function BWRaid_UserHasPermission( searchName )
	searchName = string.lower( searchName or "" );
	
	for i=1, GetNumRaidMembers() do
		local name, rank = GetRaidRosterInfo( i );
				
		if( string.lower( name ) == searchName and rank > 0 ) then
			return rank;
		end
	end
	
	return false;
end

-- Ping/pong
function BWRaid_SendPing()
	if( GetNumRaidMembers() == 0 ) then
		BWRaid_Message( BWR_NOT_IN_RAID, ChatTypeInfo["SYSTEM"] );
		return;
	
	elseif( not BWRaid_PlayerHasPermission() ) then
		BWRaid_Message( BWR_NOPERMISSIONS, ChatTypeInfo["SYSTEM"] );
		return;
	end
	
	BWRaid_Message( BWR_SENDING_PING, ChatTypeInfo["SYSTEM"] );
	BWOverlay_SortHigh( true );
	BWOverlay_RemoveAll();
	
	-- Add everyone into the raid to the default list
	for i=1, GetNumRaidMembers() do
		local name = UnitName( "raid" .. i );
		
		if( PongResponse[ name ] ) then
			local _, _, aVer, bVer, cVer = string.find( PongResponse[ name ], "([0-9]+)%.([0-9]+)%.([0-9]+)" );
			if( tonumber( cVer ) < 10 ) then
				cVer = "0" .. cVer;
			end

			local sortID = aVer .. "." .. bVer .. cVer;
			
			BWOverlay_UpdateRow( { text = name .. ": " .. PongResponse[ name ], searchOn = name, sortID = tonumber( sortID ) } );
		else
			BWOverlay_AddRow( { text = name .. ": None", sortID = -1 } );		
		end
	end
	
	IsWaitingPong = true;
	BWRaid_ScheduleEvent( "BWRaid_ResetPongWait", 15 );

	SendAddonMessage( "BWR", "PING", "RAID" );
end

function BWRaid_ResetPongWait()
	IsWaitingPong = nil;
end

function BWRaid_VersionResponse( name, version )
	if( IsWaitingPong ) then
		-- Go hack sort!
		local _, _, aVer, bVer, cVer = string.find( version, "([0-9]+)%.([0-9]+)%.([0-9]+)" );
		if( tonumber( cVer ) < 10 ) then
			cVer = "0" .. cVer;
		end
		
		local sortID = aVer .. "." .. bVer .. cVer;
		
		BWOverlay_UpdateRow( { text = name .. ": " .. version, searchOn = name, sortID = tonumber( sortID ) } );
	end
	
	PongResponse[ name ] = version;
end

-- Event handler
function BWRaid_OnEvent( event )
	if( event == "VARIABLES_LOADED" ) then
		BWRaid_LoadDefaultConfig();
		
		if( not BWRaid_Config ) then
			BWRaid_Config = DefaultConfig;
		end

		if( BWRaid_Config.version ~= BWRVersion ) then
			-- 1.3.x version from an old 1.2.x or 1.1.x
			if( string.sub( BWRVersion, 0, 3 ) == "1.3" and BWRaid_Config.general == nil ) then
				BWRaid_Config = DefaultConfig;
			
			-- 1.3.x -> 1.3.5
			elseif( BWRaid_Config.buff.position ) then
				BWRaid_Config.buff.position = nil;

				BWRaid_Config.buff.enableBuff = nil;	
				BWRaid_Config.buff.enableDebuff = nil;
				BWRaid_Config.buff.enableHOT = nil;
			
			-- 1.3.x -> 1.3.9
			elseif( BWRaid_Config.alert.backgroundColor ) then
				BWRaid_Config.alert.backgroundColor = nil;
			
			-- 1.3.x/1.4.1 -> 1.4.2
			elseif( BWRaid_Config.general.clicks ) then
				BWRaid_Config.general.clicks = nil;
				
			end
			
			-- Check configuration for any changes
			for key, value in pairs( DefaultConfig ) do
				if( BWRaid_Config[ key ] == nil or ( BWRaid_Config[ key ] and type( BWRaid_Config[ key ] ) ~= type( value ) ) ) then
					BWRaid_Config[ key ] = value;
				elseif( type( value ) == "table" ) then
					for subKey, subValue in pairs( value ) do
						if( BWRaid_Config[ key ][ subKey ] == nil or ( BWRaid_Config[ key ][ subKey ] and type( BWRaid_Config[ key ][ subKey ] ) ~= type( subValue ) ) ) then
							BWRaid_Config[ key ][ subKey ] = subValue;
						end
					end
				end
			end
			
			UIErrorsFrame:AddMessage( string.format( BWR_CONFIG_UPDATED, BWRVersion ), ChatTypeInfo["SYSTEM"].r, ChatTypeInfo["SYSTEM"].g, ChatTypeInfo["SYSTEM"].b, 1 );
		end
		
		-- We're we logged out by a request?
		if( BWRaid_Config.general.logoutRequest ) then
			UIErrorsFrame:AddMessage( string.format( BWR_FORCE_LOGGED, BWRaid_Config.general.logoutRequest ), ChatTypeInfo["SYSTEM"].r, ChatTypeInfo["SYSTEM"].g, ChatTypeInfo["SYSTEM"].b, 1 );
			BWRaid_Config.general.logoutRequest = nil;
		end
		
		-- Used for checking if configuration needs upgrading
		BWRaid_Config.version = BWRVersion;
				
		-- Hook
		Orig_ChatFrame_OnEvent = ChatFrame_OnEvent;
		ChatFrame_OnEvent = BWRaid_ChatFrame_OnEvent;
		
		-- Parse localization strings
		JOINED_PARTY_SEARCH = BWRaid_ParseString( JOINED_PARTY );
		JOINED_RAID_SEARCH = BWRaid_ParseString( ERR_RAID_MEMBER_ADDED_S );
		CONVERTED_RAID_SEARCH = BWRaid_ParseString( ERR_RAID_YOU_JOINED );
		CANNOT_FIND_SEARCH = BWRaid_ParseString( ERR_BAD_PLAYER_NAME_S );
		INVITE_DECLINED_SEARCH = BWRaid_ParseString( ERR_DECLINE_GROUP_S );
		MEMBER_GROUPED_SEARCH = BWRaid_ParseString( ERR_ALREADY_IN_GROUP_S );
		
		-- For click casting
		ClickCastFrames = ClickCastFrames or {};
		
		-- Hide the minimap icon
		BWRaid_HideMinimapButton()
	
	-- System message parsing (cleaner way of handling these would be nice)
	elseif( event == "CHAT_MSG_SYSTEM" ) then
		
		-- Error whisper if the person who asks for an invite is grouped
		if( BWRaid_Config.autoInvite and string.find( arg1, MEMBER_GROUPED_SEARCH ) ) then
			local _, _, name = string.find( arg1, MEMBER_GROUPED_SEARCH );
			
			if( InvitedMember[ name ] ) then
				SendChatMessage( BWR_YOU_ARE_GROUPED, "WHISPER", nil, name );
				InvitedMember[ name ] = nil;
			end
		end
		
		if( IsFormedRaid ) then
			-- Invite declined, reset formed status
			if( string.find( arg1, INVITE_DECLINED_SEARCH ) ) then
				local _, _, name = string.find( arg1, INVITE_DECLINED_SEARCH );

				if( string.lower( name ) == string.lower( FormedRaidInvited ) ) then
					IsFormedRaid = nil;
					FormedRaidInvited = "";
				end

			-- Can't find the player, reset formed status
			elseif( string.find( arg1, CANNOT_FIND_SEARCH ) ) then
				local _, _, name = string.find( arg1, CANNOT_FIND_SEARCH );

				if( string.lower( name ) == string.lower( FormedRaidInvited ) ) then
					IsFormedRaid = nil;
					FormedRaidInvited = "";
				end
			
			-- Formed player accepted the invite, convert to raid
			elseif( string.find( arg1, JOINED_PARTY_SEARCH ) ) then
				local _, _, name = string.find( arg1, JOINED_PARTY_SEARCH );

				if( string.lower( name ) == string.lower( FormedRaidInvited ) and IsPartyLeader() ) then
					ConvertToRaid();
				end
			
			-- Raids been converted, set the formed person to assist and change to loot to FFA
			elseif( string.find( arg1, CONVERTED_RAID_SEARCH ) ) then
				if( IsRaidLeader() ) then
					PromoteToAssistant( FormedRaidInvited );
					SetLootMethod( "freeforall" );
				end

				IsFormedRaid = nil;
				FormedRaidInvited = "";
			end
		end
	
	-- It's an autoinvite, accept it and hide the window
	elseif( event == "PARTY_INVITE_REQUEST" and AcceptPartyInvite ) then
		AcceptGroup();
		StaticPopup_Hide( "PARTY_INVITE" );
		
		AcceptPartyInvite = nil;
		
	elseif( event == "CHAT_MSG_WHISPER" ) then
				
		-- Leader request		
		if( BWRaid_Config.general.autoLeader and arg1 == BWR_TRIG_LEADER and ( IsPartyLeader() or IsRaidLeader() ) ) then
			PromoteToLeader( arg2 );
		
		-- Assist request
		elseif( BWRaid_Config.general.autoLeader and ( arg1 == BWR_TRIG_ASSIST or arg1 == BWR_TRIG_ASSISTANT ) and IsRaidLeader() ) then
			PromoteToAssistant( arg2 );			
		
		-- Auto invite
		elseif( BWRaid_Config.general.autoInvite and arg1 == BWR_TRIG_INVITE and ( IsPartyLeader() or IsRaidOfficer() or IsRaidLeader() or ( GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 ) ) ) then
		
			if( GetNumRaidMembers() == MAX_RAID_MEMBERS ) then
				SendChatMessage( BWR_PARTY_FULL, "WHISPER", nil, arg2 );
			elseif( GetNumRaidMembers() == 0 and GetNumPartyMembers() == MAX_PARTY_MEMBERS ) then
				SendChatMessage( BWR_PARTY_FULL, "WHISPER", nil, arg2 );
			end

			InviteUnit( arg2 );
			InvitedMember[ arg2 ] = true;
		
		-- Logout
		elseif( arg1 == BWR_TRIG_LOGOUT and BWRaid_UserHasPermission( arg2 ) ) then
			BWRaid_Config.general.logoutRequest = arg2;
			BWRaid_Message( string.format( BWR_LOGOUT_REQUESTED, arg2 ), ChatTypeInfo["SYSTEM"] );
			
			SendChatMessage( BWR_LOGOUT_RECEIVED, "WHISPER", nil, arg2 );
		
			Logout();
			
		-- Release
		elseif( arg1 == BWR_TRIG_RELEASE and BWRaid_UserHasPermission( arg2 ) ) then
			BWRaid_Message( string.format( BWR_RELEASE_REQUESTED, arg2 ), ChatTypeInfo["SYSTEM"] );
			SendChatMessage( BWR_RELEASE_RECEIVED, "WHISPER", nil, arg2 );

			RepopMe();

		-- Accept invite
		elseif( arg1 == BWR_TRIG_ACCEPTINVITE ) then
			AcceptPartyInvite = true;
		end
		
	
	elseif( event == "CHAT_MSG_ADDON" and arg1 == "BWR" ) then
		local command, data;
		
		if( string.find( arg2, ":" ) ) then
			command = string.gsub( arg2, "(.+)%:(.+)", "%1" );
			data = string.gsub( arg2, "([a-zA-Z0-9]+)%:(.+)", "%2" );
			
			command = string.trim( command );
			data = string.trim( data );
		else
			command = string.trim( arg2 );	
		end
		
		-- Reset BW
		if( command == "RESETBW" and IsAddOnLoaded( "BigWigs" ) and BWRaid_UserHasPermission( arg4 ) ) then
			BWRaid_Message( string.format( BWR_BW_RESET, arg4 ), ChatTypeInfo["SYSTEM"] );
			BigWigsOptions:OnClick();
		
		-- Pong, version response
		elseif( command == "PONG" ) then
			BWRaid_VersionResponse( arg4, data );
			
		-- Version ping
		elseif( command == "PING" ) then
			SendAddonMessage( "BWR", "PONG:" .. BWRVersion, "RAID" );
		end
	end
end

-- Reload raid/assist frames
function BWRaid_ReloadFrames()
	BWFrames_ReloadFrames();
	BWAssist_ReloadFrames();
end

function BWRaid_PaddingChanged()
	local value = SSUI_GetVariable( this.varInfo.type, this.varInfo.var );
	
	if( value <= 0 ) then
		SSUI_SetVariable( this.varInfo.type, this.varInfo.var, 0 );
	elseif( value > 7 ) then
		SSUI_SetVariable( this.varInfo.type, this.varInfo.var, 7 );
	end
	
	BWFrames_ReloadFrames();
end

-- Hide the world icon on the minimap
function BWRaid_HideMinimapButton()
	if( BWRaid_Config.general.hideIcon ) then
		MiniMapWorldMapButton:Hide();
	else
		MiniMapWorldMapButton:Show();
	end
end

-- UI
function BoWRaid_LoadUI()
	SSUI:RegisterUI( "bwr", { defaultTab = "BWGeneralConfig", title = BWR_BOWRAID .. " " .. BWRVersion, get = "BWRaid_GetVariable", set = "BWRaid_SetVariable" } );
	SSUI:RegisterTab( "bwr", "BWGeneralConfig", BWR_TAB_GENERAL, 1 );
	SSUI:RegisterTab( "bwr", "BWAssistConfig", BWR_TAB_ASSIST, 2 );
	SSUI:RegisterTab( "bwr", "BWFrameConfig", BWR_TAB_FRAME, 3 );
	SSUI:RegisterTab( "bwr", "BWRaidConfig", BWR_TAB_RAID, 4 );
	SSUI:RegisterTab( "bwr", "BWHealthConfig", BWR_TAB_HEALTH, 5 );
	SSUI:RegisterTab( "bwr", "BWBuffConfig", BWR_TAB_BUFF, 6 );
	SSUI:RegisterTab( "bwr", "BWRangeConfig", BWR_TAB_RANGE, 7 );
	SSUI:RegisterTab( "bwr", "BWAlertConfig", BWR_TAB_ALERT, 8 );
	SSUI:RegisterTab( "bwr", "BWFrameGroups", BWR_TAB_GROUPS, 9 );
	SSUI:RegisterTab( "bwr", "BWFrameClasses", BWR_TAB_CLASSES, 10 );
	
	local UIList = {
		-- General
		{ text = BWR_UI_AUTOLEADER, tooltip = BWR_UI_AUTOLEADER_TT, type = "check", var = { "general", "autoLeader" }, parent = "BWGeneralConfig" },
		{ text = BWR_UI_AUTOINVITE, tooltip = BWR_UI_AUTOINVITE_TT, type = "check", var = { "general", "autoInvite" }, parent = "BWGeneralConfig" },
		{ text = BWR_UI_BLOCKSPAM, tooltip = BWR_UI_BLOCKSPAM_TT, type = "check", var = { "general", "blockSpam" }, parent = "BWGeneralConfig" },
		{ text = BWR_UI_HIDEWORLDMAP, tooltip = BWR_UI_HIDEWORLDMAP_TT, OnChange = "BWRaid_HideMinimapButton", type = "check", var = { "general", "hideIcon" }, parent = "BWGeneralConfig" },

		-- Assist frame
		{ text = BWR_UI_ENABLEASSIST, type = "check", OnChange = "BWAssist_ReloadFrames", var = { "assist", "enable" }, parent = "BWAssistConfig" },
		{ text = BWR_UI_ENABLEMATARGET, type = "check", OnChange = "BWAssist_ReloadFrames", points = { "LEFT", "LEFT", 00, -30 }, var = { "assist", "MATargets" }, parent = "BWAssistConfig" },
		{ text = BWR_UI_ENABLEMATARGETTARGET, type = "check", OnChange = "BWAssist_ReloadFrames", points = { "LEFT", "LEFT", 00, -30 }, var = { "assist", "MATargetsTarget" }, parent = "BWAssistConfig" },
		
		-- Frame
		{ text = BWR_UI_LOCKFRAME, tooltip = BWR_UI_LOCKFRAME_TT, type = "check", var = { "frame", "locked" }, parent = "BWFrameConfig" },
		{ text = BWR_UI_BGCOLOR, type = "color", OnChange = "BWRaid_ReloadFrames", var = { "frame", "backgroundColor" }, parent = "BWFrameConfig" },
		{ text = BWR_UI_BORDERCOLOR, OnChange = "BWRaid_ReloadFrames",  type = "color", var = { "frame", "borderColor" }, parent = "BWFrameConfig" },
		{ text = BWR_UI_BGOPACITY, showValue = true, isPercent = true, OnChange = "BWRaid_ReloadFrames", type = "slider", var = { "frame", "backgroundOpacity" }, parent = "BWFrameConfig" },
		{ text = BWR_UI_BORDEROPACITY, showValue = true, isPercent = true,  OnChange = "BWRaid_ReloadFrames", type = "slider", var = { "frame", "borderOpacity" }, parent = "BWFrameConfig" },
		{ text = BWR_UI_FRAMESCALE, showValue = true, isPercent = true, OnChange = "BWRaid_ReloadFrames", minValue = 0.0, maxValue = 1.0, valueStep = 0.01, type = "slider", var = { "frame", "scale" }, parent = "BWFrameConfig" },
		
		-- Raid frame
		{ text = BWR_UI_ENABLEFRAME, tooltip = BWR_UI_ENABLEFRAME_TT, type = "check", OnChange = "BWFrames_ReloadFrames", var = { "raid", "enable" }, parent = "BWRaidConfig" },
		{ text = BWR_UI_SHOWRANK, tooltip = BWR_UI_SHOWRANK_TT, OnChange = "BWFrames_ReloadFrames", type = "check", var = { "raid", "showRank" }, parent = "BWRaidConfig" },
		{ text = BWR_UI_SHOWCOUNT, tooltip = BWR_UI_SHOWCOUNT_TT, OnChange = "BWFrames_ReloadFrames", type = "check", var = { "raid", "showCount" }, parent = "BWRaidConfig" },
		{ text = BWR_UI_GROUPCLASS, tooltip = BWR_UI_GROUPCLASS_TT, type = "check", OnChange = "BWFrames_ReloadFrames", var = { "raid", "groupClass" }, parent = "BWRaidConfig" },
		{ text = BWR_UI_GROUPRAID, tooltip = BWR_UI_GROUPRAID_TT, type = "check", OnChange = "BWFrames_ReloadFrames", var = { "raid", "groupRaid" }, parent = "BWRaidConfig" },
		{ text = BWR_UI_ROWS, tooltip = BWR_UI_ROWS_TT, onChange ="BWFrames_ReloadFrames", type = "input", forceType = "int", var = { "raid", "rows" }, parent = "BWRaidConfig" },
		{ text = BWR_UI_PADDING, tooltip = BWR_UI_PADDING_TT, onChange ="BWRaid_PaddingChanged", type = "input", width = 30, forceType = "int", var = { "raid", "padding" }, parent = "BWRaidConfig" },
		
		-- Bars
		{ text = BWR_UI_HEALTHONLY, tooltip = BWR_UI_HEALTHONLY_TT, OnChange = "BWFrames_ReloadFrames", type = "check", var = { "raid", "healthOnly" }, parent = "BWHealthConfig" },
		{ text = BWR_UI_LARGERHEALTHONLY, tooltip = BWR_UI_LARGERHEALTHONLY_TT, OnChange = "BWFrames_ReloadFrames", type = "check", var = { "raid", "largeHealth" }, parent = "BWHealthConfig" },
		{ text = BWR_UI_HEALTHCOLOR, type = "color", OnChange = "BWFrames_UpdateHealthType", var = { "raid", "healthColor" }, parent = "BWHealthConfig" },
		{ text = BWR_UI_FRAMESTYLE, tooltip = BWR_UI_FRAMESTYLE_TT, type = "dropdown", OnChange = "BWFrames_ReloadFrames", list = { { "default", BWR_UI_DEFAULT }, { "blizzard", BWR_UI_BLIZZARD } }, var = { "raid", "style" }, parent = "BWHealthConfig" },
		{ text = BWR_UI_HEALTHDISPLAY, tooltip = BWR_UI_HEALTHDISPLAY_TT, type = "dropdown", OnChange = "BWFrames_UpdateHealthType", list = { { "none", BWR_UI_NONE }, { "lost", BWR_UI_HEALTHLOST }, { "percent", BWR_UI_HEALTHPERCENT }, { "crt", BWR_UI_HEALTHCRT }, { "crttl", BWR_UI_HEALTHCRTTL } }, var = { "raid", "healthType" }, parent = "BWHealthConfig" },
		
		-- Range check
		{ text = BWR_UI_ENABLERANGE, tooltip = BWR_UI_ENABLERANGE_TT, type = "check", OnChange = "BWFrames_SetRangeConfig", var = { "range", "enable" }, parent = "BWRangeConfig" },
		{ text = BWR_UI_RANGETYPE, tooltip = BWR_UI_RANGETYPE_TT, type = "dropdown", OnChange = "BWFrames_SetRangeConfig", list = { { "heal", BWR_UI_HEAL }, { "decurse", BWR_UI_DECURSE } }, var = { "range", "type" }, parent = "BWRangeConfig" },
		
		-- Buffs
		{ text = BWR_UI_BUFFTYPE_LEFT, tooltip = BWR_UI_BUFFTYPE_LEFT_TT, type = "dropdown", OnChange = "BWFrames_ReloadBuffs", list = { { "none", BWR_UI_NONE }, { "buff", BWR_UI_BUFF }, { "debuff", BWR_UI_DEBUFF }, { "hot", BWR_UI_HOT } }, var = { "buff", "leftType" }, parent = "BWBuffConfig" },
		{ text = BWR_UI_BUFFTYPE_RIGHT, tooltip = BWR_UI_BUFFTYPE_RIGHT_TT, type = "dropdown", OnChange = "BWFrames_ReloadBuffs", list = { { "none", BWR_UI_NONE }, { "buff", BWR_UI_BUFF }, { "debuff", BWR_UI_DEBUFF }, { "hot", BWR_UI_HOT } }, var = { "buff", "rightType" }, parent = "BWBuffConfig" },
		{ text = BWR_UI_SHOWCURABLE, tooltip = BWR_UI_SHOWREMOVABLE_TT, type = "check", OnChange = "BWFrames_ReloadBuffs", var = { "buff", "showCurable" }, parent = "BWBuffConfig" },
		{ text = BWR_UI_SHOWCASTABLE, tooltip = BWR_UI_SHOWCASTABLE_TT, type = "check", OnChange = "BWFrames_ReloadBuffs", var = { "buff", "showCastable" }, parent = "BWBuffConfig" },
		{ text = BWR_UI_SHOWUNIQUE, tooltip = BWR_UI_SHOWUNIQUE_TT, type = "check", OnChange = "BWFrames_ReloadBuffs", var = { "buff", "showUnique" }, parent = "BWBuffConfig" },
		
		-- Alerts
		{ text = BWR_UI_ALERTENABLE, type = "check", OnChange = "BWFrames_ReloadFrames", var = { "alert", "enable" }, parent = "BWAlertConfig" },
		{ text = BWR_UI_CURECOLOR, tooltip = BWR_UI_CURECOLOR_TT, type = "color", onChange ="BWFrames_ReloadFrames", var = { "alert", "cureColor" }, parent = "BWAlertConfig" },
		{ text = BWR_UI_HPCOLOR, tooltip = BWR_UI_HPCOLOR_TT, type = "color", onChange ="BWFrames_ReloadFrames", var = { "alert", "hpColor" }, parent = "BWAlertConfig" },
		{ text = BWR_UI_ALERTCURE, tooltip = BWR_UI_ALERTCURE_TT, OnChange = "BWFrames_ReloadFrames", type = "check", var = { "alert", "curable" }, parent = "BWAlertConfig" },
		{ text = BWR_UI_DEBUFFCOLOR, tooltip = BWR_UI_DEBUFFCOLOR_TT, OnChange = "BWFrames_ReloadFrames", type = "check", var = { "alert", "colorDebuff" }, parent = "BWAlertConfig" },
		{ text = BWR_UI_ALERTDEBUFF, tooltip = BWR_UI_ALERTDEBUFF_TT, OnChange = "BWFrames_ReloadFrames", type = "check", var = { "alert", "debuff" }, parent = "BWAlertConfig" },
		{ text = BWR_UI_ALERTHP, tooltip = BWR_UI_ALERTHP_TT, onChange ="BWFrames_ReloadFrames", type = "input", width = 30, forceType = "int", var = { "alert", "health" }, parent = "BWAlertConfig" },
	};
	
	-- Move these both to multi select dropdowns later
	-- Now add the show class/group stuff
	for i=1, NUM_RAID_GROUPS do
		local data = { text = string.format( BWR_UI_SHOWGROUP, i ), type = "check", OnChange = "BWFrames_ReloadFrames", var = { "group", i }, parent = "BWFrameGroups" };
		table.insert( UIList, data );
	end

	-- Annd now classes
	for i, class in pairs( BWF_CLASSES ) do
		local data = { text = string.format( BWR_UI_SHOWCLASS, class.class ), type = "check", OnChange = "BWFrames_ReloadFrames", var = { "class", class.unloc }, parent = "BWFrameClasses" };
		table.insert( UIList, data );
	end
	
	-- Add everything	
	for _, list in pairs( UIList ) do
		SSUI:RegisterElement( "bwr", list );
	end
end

function BWRaid_LoadDefaultConfig()
	DefaultConfig = {};
	
	-- General
	DefaultConfig.general = {};
	
	DefaultConfig.general.blockSpam = true;
	DefaultConfig.general.autoInvite = true;
	DefaultConfig.general.autoLeader = true;
		
	DefaultConfig.general.hideIcon = false;
	
	-- Frame
	DefaultConfig.frame = {};
	
	DefaultConfig.frame.scale = 0.70;
	DefaultConfig.frame.locked = false;
	
	DefaultConfig.frame.backgroundColor = { r = 0, g = 0, b = 0 };
	DefaultConfig.frame.borderColor = { r = 0, g = 0, b = 0 };
	
	DefaultConfig.frame.backgroundOpacity = 0.5;
	DefaultConfig.frame.borderOpacity = 1.0;
	
	-- Raid frame
	DefaultConfig.raid = {};
	DefaultConfig.raid.enable = true;
	
	DefaultConfig.raid.smoothColor = true;
	
	DefaultConfig.raid.corrupt = false;
	DefaultConfig.raid.showRank = false;
	DefaultConfig.raid.showCount = false;
	DefaultConfig.raid.rows = 2;
	
	DefaultConfig.raid.groupClass = false;
	DefaultConfig.raid.groupRaid = false;
	
	DefaultConfig.raid.healthOnly = true;
	DefaultConfig.raid.largerHealth = false;
	
	DefaultConfig.raid.healthColor = { r = 1, g = 1, b = 1 };
	DefaultConfig.raid.healthType = "none";
	
	DefaultConfig.raid.style = "default";
	
	DefaultConfig.raid.padding = 7;
	
	-- Range
	DefaultConfig.range = {};
	
	DefaultConfig.range.enable = false;
	DefaultConfig.range.type = "heal";
	
	-- Buff
	DefaultConfig.buff = {};
	
	DefaultConfig.buff.leftType = "none";
	DefaultConfig.buff.rightType = "none";
	
	DefaultConfig.buff.showCastable = false;
	DefaultConfig.buff.showCurable = false;
	
	DefaultConfig.buff.showUnique = false;
	
	-- Alerts
	DefaultConfig.alert = {};
	DefaultConfig.alert.enable = false;
	
	DefaultConfig.alert.debuff = false;
	DefaultConfig.alert.colorDebuff = false;
	
	DefaultConfig.alert.cureColor = { r = 1, g = 0, b = 0 };
	DefaultConfig.alert.hpColor = { r = 1, g = 0, b = 0 };
	
	DefaultConfig.alert.curable = false;
	DefaultConfig.alert.health = 0;
	
	-- Main assist
	DefaultConfig.assist = {};
	DefaultConfig.assist.enable = true;
	DefaultConfig.assist.MATarget = true;
	DefaultConfig.assist.MATargetsTarget = true;
	DefaultConfig.assist.list = {};
	
	-- What group/class frames are enabled
	DefaultConfig.group = {};
	DefaultConfig.class = {};
	
	-- List of all our frames positions
	DefaultConfig.positions = {};
end

function BWRaid_GetVariable( vars )
	if( vars and vars[2] == nil ) then
		return BWRaid_Config[ vars[1] ];
	elseif( vars and vars[2] ) then
		return BWRaid_Config[ vars[1] ][ vars[2] ];	
	end
	
	return nil;
end

function BWRaid_SetVariable( vars, value )
	if( vars[2] == nil ) then
		BWRaid_Config[ vars[1] ] = value;
	elseif( vars[2] ) then
		BWRaid_Config[ vars[1] ][ vars[2] ] = value;
	end
end
