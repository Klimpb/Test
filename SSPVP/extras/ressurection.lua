local Ressurection = SSPVP:NewModule( "SSPVP-Res" );
Ressurection.activeIn = "bg";

local L = SSPVPLocals;

function Ressurection:EnableModule()
	SSOverlay:AddCategory( "res", L["Ressurections"], 1 );

	--self:RegisterEvent( "CHAT_MSG_BG_SYSTEM_NEUTRAL" );
	--self:RegisterEvent( "CHAT_MSG_MONSTER_YELL" );
	--self:RegisterEvent( "CHAT_MSG_BG_SYSTEM_HORDE" );
	--self:RegisterEvent( "CHAT_MSG_BG_SYSTEM_ALLIANCE" );	

	self:RegisterEvent( "PLAYER_DEAD" );
	self:RegisterEvent( "CORPSE_IN_RANGE" );
	self:RegisterEvent( "CORPSE_OUT_OF_RANGE" );
end

function Ressurection:DisableModule()
	self:UnregisterAllEvents();
	SSOverlay:RemoveCategory( "res" );
end

function Ressurection:CORPSE_OUT_OF_RANGE()
	SSPVP:UnregisterTimer( RetrieveCorpse );
end

function Ressurection:CORPSE_IN_RANGE()
	if( SSPVP.db.profile.bf.autoAccept and GetCorpseRecoveryDelay() ~= nil and GetCorpseRecoveryDelay() > 0 ) then
		SSPVP:RegisterTimer( RetrieveCorpse, GetCorpseRecoveryDelay() + 1 );
	end
end

function Ressurection:PLAYER_DEAD()
	if( SSPVP.db.profile.bf.release ) then
		if( not HasSoulstone() or SSPVP.db.profile.bf.releaseSS ) then
			StaticPopupDialogs["DEATH"].text = L["Releasing..."];
			RepopMe();	
			
		elseif( HasSoulstone() and not SSPVP.db.profile.bf.releaseSS ) then
			StaticPopupDialogs["DEATH"].text = string.format( L["Using %s..."], HasSoulstone() );
			UseSoulstone();		
		else
			StaticPopupDialogs["DEATH"].text = HasSoulstone();	
		end
	else
		StaticPopupDialogs["DEATH"].text = TEXT( DEATH_RELEASE_TIMER );
	end
end

function Ressurection:CHAT_MSG_BG_SYSTEM_HORDE( event, msg )
	self:ParseMessage( msg, "Horde" );
end

function Ressurection:CHAT_MSG_BG_SYSTEM_ALLIANCE( event, msg )
	self:ParseMessage( msg, "Alliance" );
end

function Ressurection:CHAT_MSG_BG_SYSTEM_NEUTRAL( event, msg )
	if( string.find( msg, L["The battle for"] ) or string.find( msg, L["battle has begun"] ) ) then
	end
end

-- Alterac Valley
function Ressurection:CHAT_MSG_MONSTER_YELL( event, msg, from )
	if( from ~= L["Herald"] ) then
		return;
	end

	if( string.find( msg, L["(.+) is under attack!"] ) ) then
		local _, _, name = string.find( msg, L["(.+) is under attack!"] );

	elseif( string.find( msg, L["(.+) was taken by the"] ) ) then
		local _, _, name = string.find( msg, L["(.+) was taken by the"] );
	end
end

function Ressurection:ParseMessage( msg, faction )
	-- Arathi Basin
	if( SSPVP:IsPlayerIn( "ab" ) ) then
		if( string.find( msg, L["has assaulted the ([^!]+)"] ) ) then
			local _, _, name = string.find( msg, L["has assaulted the ([^!]+)"] );

		elseif( string.find( msg, L["has taken the ([^!]+)"] ) ) then
			local _, _, name = string.find( msg, L["has taken the ([^!]+)"] );

		end
	
	-- Eye of the Storm
	elseif( SSPVP:IsPlayerIn( "eots" ) ) then
		if( string.find( msg, L["has lost control of the (.+)!"] ) ) then
			local _, _, name = string.find( msg, L["has lost control of the (.+)!"] );
			
		elseif( string.find( msg, L["has taken control of the (.+)!"] ) ) then
			local _, _, name = string.find( msg, L["has taken control of the (.+)!"] );
		end
	end
end