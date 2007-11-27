local BF = SSPVP:NewModule("Battlefield", "AceEvent-3.0")
BF.activeIn = "bf"

local L = SSPVPLocals

function BF:OnEnable()
	if( self.defaults ) then return end

	self.defaults = {
		profile = {
			release = true,
			whispers = true,
			soulstone = false,
		},
	}
	
	self.db = SSPVP.db:RegisterNamespace("battlefield", self.defaults)
end

function BF:EnableModule(abbrev)
	self:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
	
	-- May not want to auto release in arenas incase a team mates going to try
	-- and ressurect you
	if( abbrev ~= "arena" ) then
		self:RegisterEvent("PLAYER_DEAD")

		if( SHOW_BATTLEFIELD_MINIMAP == "1" ) then
			if( not BattlefieldMinimap ) then
				BattlefieldMinimap_LoadUI()
			end
			BattlefieldMinimap:Show()
		end
	end
end
function BF:DisableModule()
	SSOverlay:RemoveRow("start")
	self:UnregisterAllEvents()

	-- Hide minimap if it shouldn't be hidden in all zones
	if( SHOW_BATTLEFIELD_MINIMAP ~= "2" and BattlefieldMinimap and BattlefieldMinimap:IsShown() ) then
		BattlefieldMinimap:Hide()
	end
end

-- Start timers
function BF:CHAT_MSG_BG_SYSTEM_NEUTRAL(event, msg)
	if( string.match(msg, L["2 minute"]) ) then
		SSOverlay:RegisterTimer("start", "timer", L["Starting: %s"], 120)
	elseif( string.match(msg, L["1 minute"]) or string.match(msg, L["One minute"]) ) then
		SSOverlay:RegisterTimer("start", "timer", L["Starting: %s"], 60)
	elseif( string.match(msg, L["30 seconds"]) or string.match(msg, L["Thirty seconds"]) ) then
		SSOverlay:RegisterTimer("start", "timer", L["Starting: %s"], 30)
	elseif( string.match(msg, L["Fifteen seconds"]) ) then
		SSOverlay:RegisterTimer("start", "timer", L["Starting: %s"], 15)
	end
end

-- Auto release
function BF:PLAYER_DEAD()
	if( self.db.profile.release ) then
		-- No soul stone, release
		if( not HasSoulstone() ) then
			StaticPopupDialogs["DEATH"].text = L["Releasing..."]
			RepopMe()	
		
		-- Soul stone active, and we should auto use it
		elseif( HasSoulstone() and self.db.profile.soulstone ) then
			StaticPopupDialogs["DEATH"].text = string.format(L["Using %s..."], HasSoulstone())
			UseSoulstone()		
		
		-- Soul stone active, don't auto release
		else
			StaticPopupDialogs["DEATH"].text = HasSoulstone()	
		end
	else
		StaticPopupDialogs["DEATH"].text = TEXT(DEATH_RELEASE_TIMER)
	end
end

-- Block annoying raid join/leaves inside battlegrounds
local Orig_ChatFrame_SystemEventHandler = ChatFrame_SystemEventHandler
function ChatFrame_SystemEventHandler(event, ...)
	if( BF.isActive and arg1 and string.match(arg1, L["the raid group.$"]) ) then
		return true
	end
	
	return Orig_ChatFrame_SystemEventHandler(event, ...)
end

-- Block marks created message
local Orig_ChatFrame_MessageEventHandler = ChatFrame_MessageEventHandler
function ChatFrame_MessageEventHandler(event, ...)
	if( BF.isActive and event == "CHAT_MSG_LOOT" and string.match(arg1, L["(.+) Mark of Honor"]) ) then
		return false		
	end
	
	return Orig_ChatFrame_MessageEventHandler(event, ...)
end

-- Auto append server name
local Orig_SendChatMessage = SendChatMessage
function SendChatMessage(text, type, language, target, ...)
	-- See if we should try and find a match to the one we gave
	if( BF.isActive and type == "WHISPER" and target and BF.db.profile.whispers and not string.match(target, "-") ) then
		local results = 0
		local player

		-- Scan scores find match(es)
		for i=1, GetNumBattlefieldScores() do
			local name = GetBattlefieldScore(i)
			
			-- Make sure they're from another server
			if( string.match(string.lower(name), "^" .. string.lower(target)) ) then
				player = name
				results = results + 1
			end
		end
		
		-- If we only found one match, set the new name, otherwise discard it
		if( results == 1 ) then
			target = player
		end
	end
	
	return Orig_SendChatMessage(text, type, language, target, ...)
end

-- Blizzards code for hiding while inside of a PvP instance doesn't work very well, so override it with our own
local Orig_WorldStateFrame_CanShowBattlefieldMinimap = WorldStateFrame_CanShowBattlefieldMinimap
function WorldStateFrame_CanShowBattlefieldMinimap(...)
	-- Never show it in PvP, because we override it ourself
	if( select(2, IsInInstance()) == "pvp" ) then
		return false
	end
	
	return Orig_WorldStateFrame_CanShowBattlefieldMinimap(...)
end