local WSG = SSPVP:NewModule("SSPVP-WSG")
WSG.activeIn = "wsg"

local L = SSPVPLocals

local carrierNames = {}
local carrierTimes = {}
local dataSent = {}
local friendlyUnit

local enemyFaction
local friendlyFaction

function WSG:Initialize()
	SSOverlay:AddCategory("wsg", L["Timers"])

	if( UnitFactionGroup("player") == "Alliance") then
		enemyFaction = "Horde"
		friendlyFaction = "Alliance"
	else
		enemyFaction = "Alliance"
		friendlyFaction = "Horde"
	end
end

function WSG:EnableModule()
	self:RegisterEvent("UPDATE_BATTLEFIELD_SCORE", "UpdateCarriers")
	self:RegisterEvent("CHAT_MSG_BG_SYSTEM_HORDE", "ParseMessage")
	self:RegisterEvent("CHAT_MSG_BG_SYSTEM_ALLIANCE", "ParseMessage")
	self:RegisterEvent("UNIT_HEALTH")
	self:RegisterEvent("UPDATE_BINDINGS", "UpdateCarrierBindings")
	
	self:RegisterMessage("SS_CARRIERS_REQ", "SendCarriers")
	self:RegisterMessage("SS_CARRIERS_DATA", "CarrierData")
	
	self:CreateCarrierButtons()
	self:UpdateCarrierBindings()
	
	PVPSync:SendMessage("CARRIERS")
end

function WSG:DisableModule()
	SSOverlay:RemoveCategory("wsg")

	carrierNames = {}
	carrierTimes = {}
	
	self:UnregisterAllMessages()
	self:UnregisterAllEvents()
	self:UpdateCarriersAttributes()
end

function WSG:Reload()
	WSG:SetCarrierBorders()
	if( self.allianceText and self.hordeText ) then
		WSG:UpdateCarriers()
	end
	
	if( SSPVP.db.profile.wsg.carriers and SSPVP:IsPlayerIn("wsg") ) then
		PVPSync:SendMessage("CARRIERS")
	end
	
	if( SSPVP.db.profile.wsg.flagElapsed ) then
		for faction, time in pairs(carrierTimes) do
			SSOverlay:UpdateElapsed("wsg", L["Time Elapsed: %s"], GetTime() - time, SSOverlay:GetFactionColor(faction))
		end
	else
		SSOverlay:RemoveRow("text", "wsg", L["Time Elapsed: %s"])
	end
	
	if( not SSPVP.db.profile.wsg.flagCapTime ) then
		SSOverlay:RemoveRow("text", "wsg", L["Capture Time: %s"])
	end
end

-- For turning $ffc/$ftc annd $efc/$etc into carrier name/carrier time
local Orig_SendChatMessage = SendChatMessage
function SendChatMessage(text, type, language, targetPlayer, ...)
	if( text and SSPVP:IsPlayerIn("wsg") ) then
		-- Friendly carrier info
		if( carrierNames[enemyFaction] ) then
			text = string.gsub(text, "$ffc", carrierNames[enemyFaction])
			text = string.gsub(text, "$ftc", SSOverlay:FormatTime(GetTime() - carrierTimes[enemyFaction], "minsec"))
		end
		
		-- Enemy carrier info
		if( carrierNames[friendlyFaction] ) then
			text = string.gsub(text, "$efc", carrierNames[friendlyFaction])
			text = string.gsub(text, "$etc", SSOverlay:FormatTime(GetTime() - carrierTimes[friendlyFaction], "minsec"))
		end
	end
	
	return Orig_SendChatMessage(text, type, language, targetPlayer, ...)
end

-- Sync data
function WSG:SendCarriers()
	if( not SSPVP.db.profile.wsg.carriers ) then
		return
	end

	PVPSync:SendMessage("CARRIERS:A:" .. ( carrierNames["Alliance"] or "" ) .. ",H:" .. ( carrierNames["Horde"] or "" ), "BATTLEGROUND")	
end

-- Receive the data
function WSG:CarrierData(event, ...)
	if( not SSPVP.db.profile.wsg.carriers ) then
		return
	end

	for i=1, select("#", ...) do
		local factionAbbrev, name = string.split(":", (select(i, ...)))
		
		if( name ~= "" ) then
			if( factionAbbrev == "A" ) then
				carrierNames["Alliance"] = name
			elseif( factionAbbrev == "H" ) then
				carrierNames["Horde"] = name
			end
		end
	end
end

-- Parse flag messages
function WSG:ParseMessage( event, msg )
	if( not SSPVP.db.profile.wsg.carriers ) then
		return
	end
	
	-- The reason we don't just go by the event name like with EOTS and AB
	-- is due to the fact that the actual faction message
	-- changes for who captured it depending on the event
	-- this method is just simpler
	local faction
	if( string.match(msg, L["Alliance"]) ) then
		faction = "Alliance"
	elseif( string.match(msg, L["Horde"]) ) then
		faction = "Horde"
	end
	
	-- Flag picked up
	if( string.match(msg, L["was picked up by (.+)!"]) ) then
		local name = string.match(msg, L["was picked up by (.+)!"])
		
		carrierNames[faction] = name
		self:UpdateCarrier(faction)
		
		if( not carrierTimes[faction] ) then
			carrierTimes[faction] = GetTime()

			if( SSPVP.db.profile.wsg.flagElapsed ) then
				SSOverlay:UpdateElapsed("wsg", L["Time Elapsed: %s"], 1, SSOverlay:GetFactionColor(faction))
			end
		end
		
	-- Flag captured
	elseif( string.match(msg, L["(.+) captured the"]) ) then
		if( SSPVP.db.profile.wsg.flagCapTime and carrierTimes[faction] ) then
			SSOverlay:UpdateText("wsg", L["Capture Time: %s"], SSOverlay:GetFactionColor(faction), SSOverlay:FormatTime(GetTime() - carrierTimes[faction], "minsec"))
		end

		carrierNames[faction] = nil
		carrierTimes[faction] = nil
		
		self:UpdateCarrier(faction)
		
		SSOverlay:RemoveRow("elapsed", "wsg", L["Time Elapsed: %s"], SSOverlay:GetFactionColor(faction))
		
		-- Flag respawn time
		if( SSPVP.db.profile.wsg.respawn ) then
			SSOverlay:UpdateTimer("wsg", L["Flag Respawn: %s"], 23, SSOverlay:GetFactionColor(faction))
		end

	-- Flag dropped
	elseif( string.match(msg, L["was dropped by (.+)!"]) ) then
		carrierNames[faction] = nil
		self:UpdateCarrier(faction)

	-- Returned to it's base either by time out from dropped, or another player
	elseif( string.match(msg, L["was returned to its base"]) ) then
		SSOverlay:RemoveRow("elapsed", "wsg", L["Time Elapsed: %s"], SSOverlay:GetFactionColor(faction))

		if( SSPVP.db.profile.wsg.flagCapTime and carrierTimes[faction] ) then
			SSOverlay:UpdateText("wsg", L["Capture Time: %s"], SSOverlay:GetFactionColor(faction), SSOverlay:FormatTime(GetTime() - carrierTimes[faction], "minsec"))
		end
		
		carrierTimes[faction] = nil
	end
end

-- Update all attributes
function WSG:UpdateCarriersAttributes()
	WSG:UpdateCarrierAttributes("Alliance")
	WSG:UpdateCarrierAttributes("Horde")
end

local function checkButtonTarget(self)
	if( UnitExists("target") and UnitName("target") == self.carrierName ) then
		UIErrorsFrame:AddMessage(string.format(L["Targetting %s"], self.carrierName), 1.0, 0.1, 0.1, 1.0)
	else
		UIErrorsFrame:AddMessage(string.format(L["%s is out of range"], self.carrierName), 1.0, 0.1, 0.1, 1.0)
	end
end

-- Update a specific factions carrier
function WSG:UpdateCarrierAttributes(faction)
	if( InCombatLockdown() ) then
		-- If the carrier changes in combat change opacity
		-- so you know you can't target them
		if( faction == "Alliance" ) then
			if( self.allianceButton.carrierName ~= carrierNames[faction] ) then
				self.allianceText:SetAlpha(0.75)
				self.allianceText.colorSet = nil
		
				self.allianceButton.positionSet = nil
			end
		else
			if( self.hordeButton.carrierName ~= carrierNames[faction] ) then
				self.hordeText:SetAlpha(0.75)
				self.hordeText.colorSet = nil
		
				self.hordeButton.positionSet = nil
			end
		end

		SSPVP:RegisterOOCUpdate(WSG, "UpdateCarriersAttributes")
		return
	end
	
	if( faction == "Alliance" ) then
		if( carrierNames[faction] ) then
			self.allianceText:SetAlpha( 1.0 )
			self.allianceButton:SetAttribute("type", "macro")
			self.allianceButton:SetAttribute("macrotext", "/targetexact " .. carrierNames[faction])
			self.allianceButton:SetScript("PostClick", checkButtonTarget)
			self.allianceButton.carrierName = carrierNames[faction]
			self.allianceButton:Show()

			if( not self.allianceButton.positionSet ) then
				self.allianceButton.positionSet = true
				
				self.allianceButton:ClearAllPoints()
				self.allianceButton:SetPoint("LEFT", UIParent, "BOTTOMLEFT", AlwaysUpFrame2DynamicIconButton:GetRight() + 6, AlwaysUpFrame2DynamicIconButton:GetTop() - 14)

				self.allianceText:ClearAllPoints()
				self.allianceText:SetPoint("LEFT", UIParent, "BOTTOMLEFT", AlwaysUpFrame2DynamicIconButton:GetRight() + 6, AlwaysUpFrame2DynamicIconButton:GetTop() - 14)
			end
		else
			self.allianceText.colorSet = nil
			self.allianceButton.carrierName = nil
			self.allianceButton.positionSet = nil
			self.allianceButton:Hide()
		end
		
	else
		if( carrierNames[faction] ) then
			self.hordeText:SetAlpha(1.0)
			self.hordeButton:SetAttribute("type", "macro")
			self.hordeButton:SetAttribute("macrotext", "/targetexact " .. carrierNames[faction])
			self.hordeButton:SetScript("PostClick", checkButtonTarget)
			self.hordeButton.carrierName = carrierNames[faction]
			self.hordeButton:Show()

			if( not self.hordeButton.positionSet ) then
				self.hordeButton.positionSet = true
				
				self.hordeButton:ClearAllPoints()
				self.hordeButton:SetPoint( "LEFT", UIParent, "BOTTOMLEFT", AlwaysUpFrame1DynamicIconButton:GetRight() + 6, AlwaysUpFrame1DynamicIconButton:GetTop() - 14)

				self.hordeText:ClearAllPoints()
				self.hordeText:SetPoint("LEFT", UIParent, "BOTTOMLEFT", AlwaysUpFrame1DynamicIconButton:GetRight() + 6, AlwaysUpFrame1DynamicIconButton:GetTop() - 14)
			end
		else
			self.hordeText.colorSet = nil
			self.hordeButton.carrierName = nil
			self.hordeButton.positionSet = nil
			self.hordeButton:Hide()
		end
	end
end

-- Update carriers for both factions
function WSG:UpdateCarriers()
	self:UpdateCarrier("Alliance")
	self:UpdateCarrier("Horde")
end

-- Update specific faction
function WSG:UpdateCarrier(faction)
	if( not carrierNames[faction] or not SSPVP.db.profile.wsg.carriers ) then
		self:UpdateCarrierAttributes(faction)
		return
	end

	local button, text
	if( faction == "Alliance" ) then
		button = self.allianceButton
		text = self.allianceText
	elseif( faction == "Horde" ) then
		button = self.hordeButton
		text = self.hordeText
	end
	
	-- Add the friendly carriers health if available, and also the carriers text
	if( enemyFaction == faction and friendlyUnit and UnitName(friendlyUnit) == carrierNames[faction] ) then
		text:SetText(carrierNames[faction] .. " [" .. floor((UnitHealth(friendlyUnit) / UnitHealthMax(friendlyUnit) * 100) + 0.5) .. "%]")
	else
		text:SetText(carrierNames[faction])
	end
	
	-- Add color if we hasven't set it yet
	if( not text.colorSet and SSPVP.db.profile.wsg.color ) then
		for i=1, GetNumBattlefieldScores() do
			local name, _, _, _, _, _, _, _, _, classToken = GetBattlefieldScore(i)
			
			-- Different server
			if( string.match(name, "-") and carrierNames[faction] == (string.split("-", name)) ) then
				text:SetTextColor(RAID_CLASS_COLORS[classToken].r, RAID_CLASS_COLORS[classToken].g, RAID_CLASS_COLORS[classToken].b)
				text.colorSet = true
				break
			
			-- Same server
			elseif( name == carrierNames[faction] ) then
				text:SetTextColor( RAID_CLASS_COLORS[classToken].r, RAID_CLASS_COLORS[classToken].g, RAID_CLASS_COLORS[classToken].b)
				text.colorSet = true
				break
			end
		end
	end
	
	-- Didn't find them, default color
	if( not text.colorSet ) then
		text:SetTextColor(GameFontHighlightSmall:GetTextColor())
	end

	self:UpdateCarrierAttributes(faction)
end

-- Update the health of the friendly carrier
function WSG:UNIT_HEALTH(event, unitid)
	if( SSPVP.db.profile.wsg.health and UnitName(unitid) == carrierNames[enemyFaction] ) then
		friendlyUnit = unitid
		self[strlower(enemyFaction) .. "Text"]:SetText(carrierNames[enemyFaction] .. " [" .. floor((UnitHealth(unitid) / UnitHealthMax(unitid) * 100) + 0.5) .. "%]")
	end
end

-- Text borders
function WSG:SetCarrierBorders()
	if( self.allianceText and self.hordeText ) then
		if( SSPVP.db.profile.wsg.border ) then
			self.allianceText:SetFont(GameFontNormal:GetFont(), 12, "OUTLINE")
			self.hordeText:SetFont(GameFontNormal:GetFont(), 12, "OUTLINE")
		else
			self.allianceText:SetFont(GameFontNormal:GetFont(), 12, nil)
			self.hordeText:SetFont(GameFontNormal:GetFont(), 12, nil)
		end
	end
end

-- Update bindings for targetting
function WSG:UpdateCarrierBindings()
	-- Enemy carrier
	local bindKey = GetBindingKey("ETARFLAG")
	if( bindKey ) then
		SetOverrideBindingClick(getglobal("WSGFlag" .. friendlyFaction), false, bindKey, "WSGFlag" .. friendlyFaction)
	else
		ClearOverrideBindings(getglobal("WSGFlag" .. friendlyFaction))
	end
	
	-- Friendly carrier
	bindKey = GetBindingKey("FTARFLAG")
	if( bindKey ) then
		SetOverrideBindingClick(getglobal("WSGFlag" .. enemyFaction), false, bindKey, "WSGFlag" .. enemyFaction)
	else
		ClearOverrideBindings(getglobal("WSGFlag" .. enemyFaction))
	end
end

-- Create buttons carrier buttons
-- The buttons have to be named because the binding system
-- requires named frames
function WSG:CreateCarrierButtons()
	if( not self.allianceButton ) then
		self.allianceButton = CreateFrame("Button", "WSGFlagAlliance", UIParent, "SecureActionButtonTemplate")
		self.allianceButton:SetHeight(25)
		self.allianceButton:SetWidth(150)
		self.allianceButton:SetScript("PostClick", function()
			if( IsAltKeyDown() and carrierNames["Alliance" ] ) then
				SSPVP:ChannelMessage(string.format(L["Alliance flag carrier %s, flag held for %s."], carrierNames["Alliance"], SSOverlay:FormatTime(GetTime() - carrierTimes["Alliance"], "minsec")))
			end
		end)

		self.allianceText = self.allianceButton:CreateFontString(nil, "BACKGROUND")
		self.allianceText:SetJustifyH("LEFT")
		self.allianceText:SetHeight(25)
		self.allianceText:SetWidth(150)
	end
	
	if( not self.hordeButton ) then
		self.hordeButton = CreateFrame("Button", "WSGFlagHorde", UIParent, "SecureActionButtonTemplate")
		self.hordeButton:SetHeight(25)
		self.hordeButton:SetWidth(150)
		self.hordeButton:SetScript("PostClick", function()
			if( IsAltKeyDown() and carrierNames["Horde"] ) then
				SSPVP:ChannelMessage(string.format(L["Horde flag carrier %s, flag held for %s."], carrierNames["Horde"], SSOverlay:FormatTime(GetTime() - carrierTimes["Horde"], "minsec")))
			end
		end)

		self.hordeText = self.hordeButton:CreateFontString(nil, "BACKGROUND")
		self.hordeText:SetJustifyH("LEFT")
		self.hordeText:SetHeight(25)
		self.hordeText:SetWidth(150)
	end
	
	self:SetCarrierBorders()
end