local RaidRoster = {};
local TimeElapsed = 0;

local MAX_MAIN_ASSISTS = 10;

local QueueAssistUpdate;

function BWAssist_OnLoad()
	this:RegisterEvent( "VARIABLES_LOADED" );
	this:RegisterEvent( "CHAT_MSG_ADDON" );
	this:RegisterEvent( "PLAYER_ENTERING_WORLD" );
	this:RegisterEvent( "RAID_ROSTER_UPDATE" );

	SLASH_ASSISTMA1 = "/ma";
	SLASH_ASSISTMA2 = "/mainassist";
	SlashCmdList["ASSISTMA"] = BWAssist_Assist;
	
	SLASH_LISTMA1 = "/listma";
	SLASH_LISTMA2 = "/lma";
	SlashCmdList["LISTMA"] = BWAssist_ListAssist;
	
	SLASH_SETASSIST1 = "/setma";
	SLASH_SETASSIST2 = "/sma";
	SlashCmdList["SETASSIST"] = BWAssist_SendSetAssist;
	
	SLASH_CLEARASSIST1 = "/clearma";
	SLASH_CLEARASSIST2 = "/removema";
	SLASH_CLEARASSIST3 = "/rma";
	SLASH_CLEARASSIST4 = "/cma";
	SlashCmdList["CLEARASSIST"] = BWAssist_ClearAssist;
end

-- Assist functions
function BWAssist_ListAssist()
	local foundAssist;
	
	for i=1, MAX_MAIN_ASSISTS do
		if( BWRaid_Config.assist.list[ i ] ) then
			local diff = GetTime() - ( BWRaid_Config.assist.list[ i ].time or 0 );
			
			if( diff > 0 and BWRaid_Config.assist.list[ i ].time > 0 ) then
				BWRaid_Message( string.format( BWA_ASSIST_NAME_DATE, i, BWRaid_Config.assist.list[ i ].name, string.lower( SecondsToTime( diff ) ) ) );
			else
				BWRaid_Message( string.format( BWA_ASSIST_NAME_NODATE, i, BWRaid_Config.assist.list[ i ].name ) );
			end
			
			foundAssist = true;
		end
	end

	if( not foundAssist ) then
		BWRaid_Message( BWA_LIST_NO_ASSISTS, ChatTypeInfo["SYSTEM"] );
	end
end

-- Sends a clear assist request
function BWAssist_ClearAssist( msg )
	if( not BWRaid_PlayerHasPermission() ) then
		BWRaid_Message( BWA_NOPERMISSIONS, ChatTypeInfo["SYSTEM"] );
		return;
	elseif( InCombatLockdown() ) then
		BWRaid_Message( BWA_INCOMBAT, ChatTypeInfo["SYSTEM"] );
		return;
	end

	
	if( not msg or msg == "" ) then
		SendAddonMessage( "BWR", "CLEARASSIST", "RAID" );
	else
		SendAddonMessage( "BWR", "CLEARMULTIASSIST:" .. msg, "RAID" );
	end
end

-- Attempts to assist a target
function BWAssist_Assist( msg )
	if( true == true ) then
		BWRaid_Message( "/ma is currently disabled and needs to be updated to 2.0 still. You can manually click on the assist frames, or make an /assist <name> macro." );
		return;
	end
	
	
	local assistNum = 1;
	if( msg and msg ~= "" ) then
		assistNum = tonumber( msg );
	end
	
	if( not BWRaid_Config.assist.list[ assistNum ] ) then
		UIErrorsFrame:AddMessage( string.format( BWA_NO_ASSIST_SET, assistNum ), 1.0, 0.1, 0.1, 1.0 );
		return;
	end
	
	AssistByName( BWRaid_Config.assist.list[ assistNum ].name );
end

-- Sends an assist set
function BWAssist_SendSetAssist( msg )
	if( msg == nil or msg == "" ) then
		BWRaid_Message( BWA_NOASSIST, ChatTypeInfo["SYSTEM"] );
		return;
	elseif( not BWRaid_PlayerHasPermission() ) then
		BWRaid_Message( BWA_NOPERMISSIONS, ChatTypeInfo["SYSTEM"] );
		return;
	elseif( InCombatLockdown() ) then
		BWRaid_Message( BWA_INCOMBAT, ChatTypeInfo["SYSTEM"] );
		return;
	end
	
	local text;
	if( string.find( msg, " " ) ) then
		local _, _, num, name = string.find( msg, "([0-9]+) (.+)" );
		num = tonumber( num );
		
		if( not num or num <= 0 or num > MAX_MAIN_ASSISTS ) then
			BWRaid_Message( string.format( BWR_INVALID_NUM, MAX_MAIN_ASSISTS ), ChatTypeInfo["SYSTEM"] );
			return;
		else
			SendAddonMessage( "BWR", "SETMULTIASSIST:" .. num .. "," .. name, "RAID" );
		end
	else
		SendAddonMessage( "BWR", "SETMULTIASSIST:1," .. msg, "RAID" );
	end
end

--[[
Orig_SendAddonMessage = SendAddonMessage;
function SendAddonMessage( prefix, msg, chann )
	if( prefix == "BWR" and chann == "RAID" ) then
		chann = "BATTLEGROUND";
	end
	
	Orig_SendAddonMessage( prefix, msg, chann );
end
]]
-- Creates all the frames
function BWAssist_CreateFrames()
	for i=1, MAX_MAIN_ASSISTS do
		local frame = getglobal( "BWAssistRow" .. i );

		-- Check if the row doesn't exist
		if( not frame ) then
			local parent;
			if( i == 1 ) then
				parent = BWAssist;			
			else
				parent = getglobal( "BWAssistRow" .. i - 1 );
			end
			
			frame = CreateFrame( "Button", "BWAssistRow" .. i, parent, "SecureUnitButtonTemplate,BWAssistMemberTemplate" );
			ToTFrame = CreateFrame( "Button", "BWAssistRow" .. i .. "Target", getglobal( "BWAssistRow" .. i ), "SecureUnitButtonTemplate,BWAssistMemberTemplate" );
			ToTTFrame = CreateFrame( "Button", "BWAssistRow" .. i .. "TargetTarget", getglobal( "BWAssistRow" .. i ), "SecureUnitButtonTemplate,BWAssistMemberTemplate" );
			
			frame.dontColor = true;
			ToTFrame.dontColor = true;
			ToTTFrame.dontColor = true;
			
			if( i == 1 ) then
				frame:SetPoint( "TOPLEFT", parent, "TOPLEFT", 0, -6 );
				ToTFrame:SetPoint( "TOPLEFT", parent, "TOPLEFT", 100, -6 );
				ToTTFrame:SetPoint( "TOPLEFT", parent, "TOPLEFT", 200, -6 );
			else
				frame:SetPoint( "TOPLEFT", parent, "TOPLEFT", 0, -27 );
				ToTFrame:SetPoint( "TOPLEFT", parent, "TOPLEFT", 100, -27 );
				ToTTFrame:SetPoint( "TOPLEFT", parent, "TOPLEFT", 200, -27 );
			end
			
			ClickCastFrames[ frame ] = true;
			ClickCastFrames[ ToTFrame ] = true;
			ClickCastFrames[ ToTTFrame ] = true;
		end
	end
end

-- Updates assist
function BWAssist_UpdateAssists()
	-- Combat restrictions apply, queue for when we're OOC
	if( InCombatLockdown() ) then
		QueueAssistUpdate = true;
		return;
	end

	BWAssist_CreateFrames();

	-- Update all the assists that are in the raid
	local index = 1;
	for _, assist in pairs( BWRaid_Config.assist.list ) do
		local row = getglobal( "BWAssistRow" .. index );
		
		if( assist ) then
			-- Is he in the raid?
			for id, raid in pairs( RaidRoster ) do
				if( string.lower( raid.name ) == string.lower( assist.name ) ) then
					row.unit = raid.unit;
					row:Show();

					getglobal( row:GetName() .. "Name" ):SetText( raid.name );

					BWFrames_UpdateHealthBar( raid.unit, row );
					
					-- Add attributes so we can use the frame
					BWFrames_SetAttribute( row, "type", "target" );
					BWFrames_SetAttribute( row, "unit", raid.unit );
					
					local MATarget, MATargetTarget;
					
					-- ToTT enabled, ToT disabled, so show ToTT in the ToT area
					if( BWRaid_Config.assist.MATargetsTarget and not BWRaid_Config.assist.MATargets ) then
						MATarget = raid.unit .. "targettarget";
					
					-- ToT enabled, ToTT disabled so show the in normal ToT area
					elseif( BWRaid_Config.assist.MATargets and not BWRaid_Config.assist.MATargetsTarget ) then
						MATarget = raid.unit .. "target";
					
					-- Both are on, show in the default areas
					elseif( BWRaid_Config.assist.MATargets and BWRaid_Config.assist.MATargetsTarget ) then
						MATarget = raid.unit .. "target";
						MATargetTarget = raid.unit .. "targettarget";
					end
					
					-- For targetting
					BWFrames_SetAttribute( getglobal( row:GetName() .. "Target" ), "type", "target" );
					BWFrames_SetAttribute( getglobal( row:GetName() .. "Target" ), "unit", MATarget );					

					BWFrames_SetAttribute( getglobal( row:GetName() .. "TargetTarget" ), "type", "target" );
					BWFrames_SetAttribute( getglobal( row:GetName() .. "TargetTarget" ), "unit", MATargetTarget );
					
					-- Used for mouseover stuff
					getglobal( row:GetName() .. "Target" ).unit = MATarget;
					getglobal( row:GetName() .. "TargetTarget" ).unit = MATargetTarget;

					index = index + 1;
					break;
				end
			end
		end
	end
	
	for i=index, MAX_MAIN_ASSISTS do
		local row = getglobal( "BWAssistRow" .. i );
		
		BWFrames_SetAttribute( getglobal( row:GetName() .. "TargetTarget" ), "unit", nil );
		BWFrames_SetAttribute( getglobal( row:GetName() .. "Target" ), "unit", nil );					
		BWFrames_SetAttribute( row, "unit", nil );

		row.unit = nil;
		row:Hide();
	end

	BWAssist_UpdateSize();
end

-- Updates the main assists targets and targets target
function BWAssist_UpdateAssistTargets()
	for i=1, MAX_MAIN_ASSISTS do
		local row = getglobal( "BWAssistRow" .. i );
		local ToTFrame = getglobal( row:GetName() .. "Target" );
		local ToTTFrame = getglobal( row:GetName() .. "TargetTarget" );
		
		-- MA Target
		if( ToTFrame:GetAttribute( "unit" ) ) then
			
			if( UnitExists( ToTFrame:GetAttribute( "unit" ) ) ) then
				BWFrames_UpdateHealthBar( ToTFrame:GetAttribute( "unit" ), ToTFrame );

				getglobal( ToTFrame:GetName() .. "Name" ):SetText( UnitName( ToTFrame:GetAttribute( "unit" ) ) );
				getglobal( ToTFrame:GetName() .. "HealthBar" ):Show();
				getglobal( ToTFrame:GetName() .. "HealthTexture" ):Show();
			else
				getglobal( ToTFrame:GetName() .. "Name" ):SetText( BWA_NONE );
				getglobal( ToTFrame:GetName() .. "HealthBar" ):Hide();
				getglobal( ToTFrame:GetName() .. "HealthTexture" ):Hide();
			end
						
			ToTFrame:Show();
		else
			getglobal( row:GetName() .. "Target" ):Hide();
		end
		
		-- MA Target Target
		if( ToTTFrame:GetAttribute( "unit" ) ) then
			if( UnitExists( ToTTFrame:GetAttribute( "unit" ) ) ) then
				BWFrames_UpdateHealthBar( ToTTFrame:GetAttribute( "unit" ), ToTTFrame );
				
				getglobal( ToTTFrame:GetName() .. "Name" ):SetText( UnitName( ToTTFrame:GetAttribute( "unit" ) ) );
				getglobal( ToTTFrame:GetName() .. "HealthBar" ):Show();
				getglobal( ToTTFrame:GetName() .. "HealthTexture" ):Show();
			else
				getglobal( ToTTFrame:GetName() .. "Name" ):SetText( BWA_NONE );
				getglobal( ToTTFrame:GetName() .. "HealthBar" ):Hide();
				getglobal( ToTTFrame:GetName() .. "HealthTexture" ):Hide();
			end
			
			ToTTFrame:Show();
		else
			getglobal( row:GetName() .. "TargetTarget" ):Hide();
		end
				
	end	
end

-- Updates raid roster cache
function BWAssist_UpdateRaidRoster()
	RaidRoster = {};

	-- Create all the frames
	for i=1, GetNumRaidMembers() do
		local name, rank, subgroup, _, class, unlocClass, _, online, isDead = GetRaidRosterInfo( i );

		table.insert( RaidRoster, { name = name, rank = rank, subgroup = subgroup, class = class, online = online, isDead = isDead, unit = "raid" .. i } );
	end
end

-- Updates MAToT and MAToTT
function BWAssist_OnUpdate( elapsed )
	TimeElapsed = TimeElapsed + elapsed;
	
	if( TimeElapsed > 0.1 ) then
		TimeElapsed = TimeElapsed - 0.1;
		BWAssist_UpdateAssistTargets();
	end
end

-- Update width/height
function BWAssist_UpdateSize()
	if( BWRaid_Config.assist.MATargets and BWRaid_Config.assist.MATargetsTarget ) then
		BWAssist:SetWidth( 307 );
	elseif( BWRaid_Config.assist.MATargets or BWRaid_Config.assist.MATargetsTarget ) then
		BWAssist:SetWidth( 207 );	
	else
		BWAssist:SetWidth( 107 );
	end
	
	local rows = 1;
	for i=1, MAX_MAIN_ASSISTS do
		if( getglobal( "BWAssistRow" .. i ):GetAttribute( "unit" ) ) then
			rows = rows + 1;
		end
	end
	
	if( rows > 1 ) then
		BWAssist:SetHeight( 20 + ( 24 * ( rows - 1 ) ) );
		BWFrames_Show( BWAssist );
	else
		BWFrames_Hide( BWAssist );
	end
end

-- Reload frames
function BWAssist_ReloadFrames()
	BWAssist.frameid = "assist";
	BWAssist:SetScale( BWRaid_Config.frame.scale );
	BWAssist:SetBackdropColor( BWRaid_Config.frame.backgroundColor.r, BWRaid_Config.frame.backgroundColor.g, BWRaid_Config.frame.backgroundColor.b, BWRaid_Config.frame.backgroundOpacity );
	BWAssist:SetBackdropBorderColor( BWRaid_Config.frame.borderColor.r, BWRaid_Config.frame.borderColor.g, BWRaid_Config.frame.borderColor.b, BWRaid_Config.frame.borderOpacity );
	
	-- Position
	if( BWRaid_Config.positions["assist"] ) then
		BWAssist:SetPoint( "TOPLEFT", nil, "BOTTOMLEFT", BWRaid_Config.positions["assist"].x, BWRaid_Config.positions["assist"].y );	
	else
		BWAssist:SetPoint( "TOPLEFT", nil, "TOPLEFT", 600, -300 );		
	end
	
	if( not BWRaid_Config.assist.enable ) then
		BWFrames_Hide( BWAssist );
		return;
	end
	
	BWAssist_UpdateAssists();
end

-- Set an assist
function BWAssist_SetAssist( name, num, setTime )
	BWRaid_Config.assist.list[ num ] = { name = name, time = ( setTime or GetTime() ) };
	BWAssist_ReloadFrames();
end

-- Remove a specific assist
function BWAssist_RemoveAssist( num )
	BWRaid_Config.assist.list[ num ] = nil;
	BWAssist_ReloadFrames();
end

-- Remove all assists
function BWAssist_RemoveAllAssists()
	BWRaid_Config.assist.list = {};
	BWAssist_ReloadFrames();
end

function BWAssist_OnEvent( event )
	if( event == "VARIABLES_LOADED" ) then
		local killTime = GetTime() - 86400;
		
		for id, assist in pairs( BWRaid_Config.assist.list ) do
			if( assist and assist.time <= killTime ) then
				BWRaid_Config.assist.list[ id ] = nil;
			end
		end
		
	elseif( event == "PLAYER_REGEN_ENABLED" and QueueAssistUpdate ) then
		QueueAssistUpdate = nil;

		BWAssist_UpdateRaidRoster();
		BWAssist_UpdateAssists();
		
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
		
		-- Set main assist
		if( command == "SETMULTIASSIST" and BWRaid_UserHasPermission( arg4 ) ) then
			local assistNum = string.gsub( data, "([0-9]+),(.+)", "%1" );
			local assistName = string.gsub( data, "([0-9]+),(.+)", "%2" );
			assistNum = tonumber( assistNum );
			
			if( assistNum and assistNum > 0 and assistName and assistNum <= MAX_MAIN_ASSISTS ) then
				BWAssist_SetAssist( assistName, assistNum );
				BWRaid_Message( string.format( BWA_ASSISTSET, assistNum, assistName, arg4 ), ChatTypeInfo["SYSTEM"] );
			end
		
		-- Clear a specific main assist
		elseif( command == "CLEARMULTIASSIST" and BWRaid_UserHasPermission( arg4 ) ) then
			data = tonumber( data );
			
			if( data and data > 0 and data <= MAX_MAIN_ASSISTS ) then
				BWAssist_RemoveAssist( data );
				BWRaid_Message( string.format( BWA_MULTI_ASSIST_CLEARED, data ), ChatTypeInfo["SYSTEM"] );
			end
			
		-- Clear all main assists
		elseif( command == "CLEARASSIST" and BWRaid_UserHasPermission( arg4 ) ) then
			BWAssist_RemoveAllAssists();
			BWRaid_Message( string.format( BWA_ASSISTCLEARED, arg4 ), ChatTypeInfo["SYSTEM"] );
		end	
	
	elseif( event == "PLAYER_ENTERING_WORLD" and BWRaid_Config.assist.enable and GetNumRaidMembers() > 0 ) then
		BWAssist_UpdateRaidRoster();
		BWAssist_UpdateAssists();
		
	elseif( event == "RAID_ROSTER_UPDATE" and BWRaid_Config.assist.enable ) then
		BWAssist_UpdateRaidRoster();
		BWAssist_UpdateAssists();
	end
end
