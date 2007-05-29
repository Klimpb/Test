local Reformat = SSPVP:NewModule( "SSPVP-Reformat" );
Reformat.activeIn = "bf";

local L = SSPVPLocals;
local ChatHooks = {};
local JoinedRaid;
local LeftRaid;

function Reformat:Initialize()
	JoinedRaid = string.format( ERR_RAID_MEMBER_ADDED_S, "(.+)" );
	LeftRaid = string.format( ERR_RAID_MEMBER_REMOVED_S, "(.+)" );
end

function Reformat:EnableModule()
	self:RegisterEvent( "UPDATE_BATTLEFIELD_SCORE" );
end

function Reformat:DisableModule()
	self:UnregisterAllEvents();
end

local Orig_ChatFrame_SystemEventHandler = ChatFrame_SystemEventHandler;
function ChatFrame_SystemEventHandler( event, ... )
	if( Reformat.moduleEnabled and arg1 and ( string.match( arg1, JoinedRaid ) or string.match( arg1, LeftRaid ) ) ) then
		return true;
	end
	
	return Orig_ChatFrame_SystemEventHandler( event, ... );
end

local Orig_SendChatMessage = SendChatMessage;
function SendChatMessage( text, type, language, target, ... )
	if( Reformat.moduleEnabled and target and type == "WHISPER" and not string.match( target, "-" ) ) then
		local foundName;
		local foundPlayers = 0;
				
		target = string.lower( target );
		
		for i=1, GetNumBattlefieldScores() do
			local name = GetBattlefieldScore( i );
			
			if( string.match( string.lower( name ), "^" .. target ) ) then
				foundPlayers = foundPlayers + 1;
				foundName = name;
			end
		end
		
		-- Nothing found in battlefield scores, scan raid
		if( foundPlayers == 0 ) then
			for i=1, GetNumRaidMembers() do
				local name, server = UnitName( "raid" .. i );
				
				if( server and string.lower( name ) == target ) then
					foundName = target .. "-" .. select( 2, UnitName( "raid" .. i ) );
					foundPlayers = foundPlayers + 1;
				end
			end
		end
		
		-- If we only found one match, set the new name, otherwise discard it
		if( foundPlayers == 1 ) then
			target = foundName;
		end
	end
	
	return Orig_SendChatMessage( text, type, language, target, ... );
end

--|Hplayer:<name>:<id>|h<bracket><name><bracket>|h
--[[
function Reformat.ChatAddMessage( frame, text, ... )
	if( Reformat.moduleEnabled ) then
		if( event == "CHAT_MSG_SAY" or event == "CHAT_MSG_CHANNEL" or event == "CHAT_MSG_WHISPER" or event == "CHAT_MSG_WHISPER_INFORM" or event == "CHAT_MSG_YELL" or event == "CHAT_MSG_BATTLEGROUND" or event == "CHAT_MSG_BATTLEGROUND_LEADER" ) then
			if( string.match( text, "|Hplayer:(.-)%-(.-):([0-9]+)|h(.+)|h" ) ) then
				local playerName, playerServer, lineNum, displayedName = string.match( text, "|Hplayer:(.-)%-(.-):([0-9]+)|h(.+)|h" );
				displayedName = string.gsub( displayedName, "(.-)%-(.-)", "%1" );
				
				text = string.gsub( text, "|Hplayer:(.-):([0-9]+)|h(.+)|h", "|Hplayer:%1:%2|h" .. SSPVP.db.profile.reformat.prefix .. playerName .. SSPVP.db.profile.reformat.suffix .. " " .. SSPVP.db.profile.reformat.prefix .. playerServer .. SSPVP.db.profile.reformat.suffix .. "|h" );
			end
		end
	end
	
	ChatHooks[ frame ]( frame, text, ... );
end
]]