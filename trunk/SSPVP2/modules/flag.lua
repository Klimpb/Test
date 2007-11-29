local Flag = SSPVP:NewModule("Flag", "AceEvent-3.0", "AceTimer-3.0")
Flag.activeIn = "bg"

local L = SSPVPLocals
local carriers = {["alliance"] = {}, ["horde"] = {}}
local HEALTH_TIMEOUT = 10

function Flag:OnEnable()
	if( self.defaults ) then return end

	self.defaults = {
		profile = {
			wsg = {
				enabled = true,
				color = true,
				health = true,
				respawn = true,
				capture = true,
				macro = "/targetexact *name",
			},
			eots = {
				enabled = true,
				color = true,
				health = true,
				respawn = true,
				capture = true,
				macro = "/targetexact *name",
			},
		},
	}
	
	self.db = SSPVP.db:RegisterNamespace("score", self.defaults)	
	
	playerName = UnitName("player")
end

function Flag:EnableModule(abbrev)
	-- Flags are only used inside EoTS and WSG currently
	if( ( abbrev ~= "eots" and abbrev ~= "wsg" ) or not self.db.profile[abbrev].enabled ) then
		self.isActive = nil
		return
	end

	self:RegisterEvent("CHAT_MSG_BG_SYSTEM_HORDE", "ParseMessage")
	self:RegisterEvent("CHAT_MSG_BG_SYSTEM_ALLIANCE", "ParseMessage")
	self:RegisterEvent("UPDATE_BINDINGS")
	
	if( self.db.profile[abbrev].health ) then
		self:RegisterEvent("UNIT_HEALTH")
		self:RegisterEvent("PLAYER_TARGET_CHANGED")
		self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
	end
	
	self:ScheduleRepeatingTimer("ScanParty", 1)
	self.activeBF = abbrev
end

function Flag:DisableModule()
	self:CancelAllTimers()
	self:UnregisterAllEvents()
	
	SSOverlay:RemoveCategory("timer")
	
	for k, v in pairs(carriers["alliance"]) do
		v = nil
	end
	
	for k, v in pairs(carriers["horde"]) do
		v = nil
	end
	
	self:Hide("horde")
	self:Hide("alliance")
end

function Flag:Reload()
	if( self.activeBF and self.db.profile[self.activeBF].health and self.isActive ) then
		self:RegisterEvent("UNIT_HEALTH")
		self:RegisterEvent("PLAYER_TARGET_CHANGED")
		self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
	else
		self:UnregisterEvent("UNIT_HEALTH")
		self:UnregisterEvent("PLAYER_TARGET_CHANGED")
		self:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")
	end
	
	if( self.isActive ) then
		self:UpdateCarrier("alliance")
		self:UpdateCarrier("horde")
	end
end

-- Scan unit updates
function Flag:UNIT_HEALTH(event, unit)
	self:UpdateHealth(unit)
end

function Flag:UPDATE_MOUSEOVER_UNIT()
	self:UpdateHealth("mouseover")
end

function Flag:PLAYER_TARGET_CHANGED()
	self:UpdateHealth("target")
end

-- Scan raid targets
function Flag:ScanParty()
	for i=1, GetNumRaidMembers() do
		self:UpdateHealth("raid" .. i)
		self:UpdateHealth("raid" .. i .. "target")
	end
end

-- Update health
function Flag:UpdateHealth(unit)
	if( not UnitExists(unit) ) then
		return

	end
		

	local name = UnitName(unit)
	local faction = select(2, UnitFactionGroup(unit))
	if( not faction ) then
		return
	end
	
	faction = string.lower(faction)
	if( carriers[faction].name == name ) then
		carriers[faction].health = floor((UnitHealth(unit) / UnitHealthMax(unit) * 100) + 0.5)
		
		self:UpdateCarrier(faction)
		self:CancelTimer("Reset" .. faction .. "Health")
		self:ScheduleTimer("Reset" .. faction .. "Health", HEALTH_TIMEOUT)
	end
end

-- Check if we can still get health updates from them
function Flag:IsTargeted(name)
	-- Check if it's our target or mouseover
	if( UnitName("target") == name or UnitName("mouseover") == name ) then
		return true
	end
	
	-- Check if it's a raid member, or raid member target
	for i=1, GetNumRaidMembers() do
		local unit = "raid" .. i
		local target = unit .. "target"
		
		if( UnitExists(unit) and UnitName(unit) == name ) then
			return true
		elseif( UnitExists(target) and UnitName(target) == name ) then
			return true
		end
	end
	
	return nil
end

-- More then 5 seconds without updates means they're too far away
function Flag:ResetallianceHealth()
	self:ResetHealth("alliance")
end

function Flag:ResethordeHealth()
	self:ResetHealth("horde")
end

function Flag:ResetHealth(type)
	-- If we still have them targeted, don't reset timeout
	if( self:IsTargeted(carriers[type].name) ) then
		self:ScheduleTimer("Reset" .. type .. "Health", HEALTH_TIMEOUT)
		return
	end

	if( carriers[type].health) then
		carriers[type].health = nil
		self:UpdateCarrier(type)
	end
end

-- We split these into two different functions, so we can do color/text/health updates
-- while in combat, but update targeting when out of it
function Flag:UpdateCarrierAttributes(faction)
	-- Carrier changed but we can't update it yet
	local carrier = carriers[faction].name
	if( self[faction].carrier ~= carrier ) then
		self[faction]:SetAlpha(0.75)
	else
		self[faction]:SetAlpha(1.0)
	end
	
	if( not carrier ) then
		return
	end

	-- In combat, can't change anything
	if( InCombatLockdown() ) then
		SSPVP:RegisterOOCUpdate(self, "UpdateCarrierAttributes", faction)
		return
	end
	
	local posFrame
	if( faction == "alliance" ) then
		posFrame = AlwaysUpFrame1Text
	else
		posFrame = AlwaysUpFrame2Text
	end
	
	self[faction].carrier = carrier
	self[faction]:ClearAllPoints()
	self[faction]:SetPoint("LEFT", UIParent, "BOTTOMLEFT", posFrame:GetRight() + 8, posFrame:GetTop() - 5)
	self[faction]:SetAttribute("type", "macro")
	self[faction]:SetAttribute("macrotext", string.gsub(self.db.profile[self.activeBF].macro, "*name", carrier))
end

function Flag:UpdateCarrier(faction)
	self:UpdateCarrierAttributes(faction)
	-- No carrier, hide it, this is bad
	local carrier = carriers[faction].name
	if( not carrier ) then
		self:Hide(faction)
		return
	end
	
	
	local health = ""
	if( carriers[faction].health and self.db.profile[self.activeBF].health and type(carriers[faction].health) == "number" ) then
		health = " |cffffffff[" .. carriers[faction].health .. "%]|r"
	end
	
	self[faction].text:SetText(carrier .. health)

	-- Carrier class color if enabled/not set
	if( not self[faction].colorSet and self.db.profile[self.activeBF].color ) then
		for i=1, GetNumBattlefieldScores() do
			local name, _, _, _, _, _, _, _, _, classToken = GetBattlefieldScore(i)
			
			if( string.match(name, "^" .. carrier) ) then
				self[faction].text:SetTextColor(RAID_CLASS_COLORS[classToken].r, RAID_CLASS_COLORS[classToken].g, RAID_CLASS_COLORS[classToken].b)
				self[faction].colorSet = true
				break
			end
		end
	end
	
	-- Update the color to the default because we couldn't find one
	if( not self[faction].colorSet ) then
		self[faction].text:SetTextColor(GameFontNormal:GetTextColor())
	end
end

-- Parse event for changes
function Flag:ParseMessage(event, msg)
	-- Issues if we don't do quick button check
	self:CreateButtons()
	
	-- More sane for us to do it here
	local faction
	if( self.activeBF == "wsg" ) then
		if( string.match(msg, L["Alliance"]) ) then
			faction = "alliance"
		elseif( string.match(msg, L["Horde"]) ) then
			faction = "horde"
		end
	elseif( event == "CHAT_MSG_BG_SYSTEM_HORDE" ) then
		faction = "horde"
	elseif( event == "CHAT_MSG_BG_SYSTEM_ALLIANCE" ) then
		faction = "alliance"
	end
	
	-- WSG, pick up
	if( string.match(msg, L["was picked up by (.+)!"]) ) then
		self:PickUp(faction, string.match(msg, L["was picked up by (.+)!"]))
	
	-- EoTS, pick up
	elseif( string.match(msg, L["(.+) has taken the flag!"]) ) then
		self:PickUp(faction, string.match(msg, L["(.+) has taken the flag!"]))

	-- WSG/EOTS, returned
	elseif( string.match(msg, L["was returned to its base"]) or string.match(msg, L["flag has been reset"]) ) then
		self:Returned(faction)
	
	-- WSG/EoTS, captured
	elseif( string.match(msg, L["captured the"]) ) then
		self:Captured(faction)
	
	-- EoTS/WSG, dropped
	elseif( string.match(msg, L["was dropped by (.+)!"]) or string.match(msg, L["The flag has been dropped"]) ) then
		self:Dropped(faction)
	end
end

-- Flag captured = time reset as well
function Flag:Captured(faction)
	if( self.db.profile[self.activeBF].respawn ) then
		if( self.activeBF == "eots" ) then
			SSOverlay:RegisterTimer("respawn", "timer", L["Flag Respawn: %s"], 10, SSPVP:GetFactionColor("Neutral"))
		else
			SSOverlay:RegisterTimer("respawn", "timer", L["Flag Respawn: %s"], 21, SSPVP:GetFactionColor("Neutral"))
		end
	end
	
	-- Remove held time, show time taken to capture
	SSOverlay:RemoveRow(faction .. "time")
	
	if( carriers[faction].time ) then
		SSOverlay:RegisterText(faction .. "capture", "timer", string.format(L["Capture Time: %s"], SecondsToTime(GetTime() - carriers[faction].time)), SSPVP:GetFactionColor(faction))
	end
	
	-- Clear out
	carriers[faction].time = nil
	carriers[faction].name = nil
	carriers[faction].health = nil
	self:Hide(faction)
end

function Flag:Dropped(faction)
	carriers[faction].name = nil
	carriers[faction].health = nil
	SSOverlay:RemoveRow(faction .. "time")
	
	self:Hide(faction)
end

-- Return = time reset
function Flag:Returned(faction)
	carriers[faction].time = nil
	carriers[faction].name = nil
	SSOverlay:RemoveRow(faction .. "time")
end

function Flag:PickUp(faction, name)
	carriers[faction].name = name

	-- If the flags dropped then picked up, we don't want to reset time
	if( not carriers[faction].time ) then
		carriers[faction].time = GetTime()
	end
	
	SSOverlay:RegisterElapsed(faction .. "time", "timer", L["Held Time: %s"], GetTime() - carriers[faction].time, SSPVP:GetFactionColor(faction))
		
	self:Show(faction)
end

-- Update everything, we do this here instead of specifics
-- so if we drop the flag, then pick it up in combat it won't show it, then hide
function Flag:UpdateStatus()
	if( carriers["alliance"].name ) then
		self:Show("alliance")
	else
		self:Hide("alliance")
	end
	
	if( carriers["horde"].name ) then
		self:Show("horde")
	else
		self:Hide("horde")
	end
end

-- Show flag
function Flag:Show(faction)
	-- Just because flag changes in combat, doesn't mean 
	-- we can't change name and such information
	self:UpdateCarrier(faction)
		
	if( InCombatLockdown() ) then
		self[faction]:SetAlpha(0.75)
		SSPVP:RegisterOOCUpdate(self, "UpdateStatus")
	else
		self[faction]:SetAlpha(1.0)
		self[faction]:Show()
	end
end

-- Hide flag
function Flag:Hide(faction)
	if( InCombatLockdown() ) then
		self[faction]:SetAlpha(0.75)
		SSPVP:RegisterOOCUpdate(self, "UpdateStatus")
	else
		self[faction].colorSet = nil
		self[faction]:Hide()
	end
end

-- Update bindings
function Flag:UPDATE_BINDINGS()
	local friendlyFaction, enemyFaction
	if( select(2, UnitFactionGroup("player")) == "Alliance" ) then
		enemyFaction = "Horde"
		friendlyFaction = "Alliance"
	else
		enemyFaction = "Alliance"
		friendlyFaction = "Horde"
	end
	
	-- Enemy carrier
	local bindKey = GetBindingKey("ETARFLAG")
	if( bindKey ) then
		SetOverrideBindingClick(getglobal("SSFlag" .. friendlyFaction), false, bindKey, "SSFlag" .. friendlyFaction)
	else
		ClearOverrideBindings(getglobal("SSFlag" .. friendlyFaction))
	end
	
	-- Friendly carrier
	bindKey = GetBindingKey("FTARFLAG")
	if( bindKey ) then
		SetOverrideBindingClick(getglobal("SSFlag" .. enemyFaction), false, bindKey, "SSFlag" .. enemyFaction)
	else
		ClearOverrideBindings(getglobal("SSFlag" .. enemyFaction))
	end
end

-- Create our target buttons
function Flag:CreateButtons()
	if( not self.alliance and AlwaysUpFrame1Text ) then
		self.alliance = CreateFrame("Button", "SSFlagAlliance", UIParent, "SecureActionButtonTemplate")
		self.alliance:SetHeight(25)
		self.alliance:SetWidth(150)
		self.alliance:SetPoint("LEFT", UIParent, "BOTTOMLEFT", AlwaysUpFrame1Text:GetRight() + 8, AlwaysUpFrame1Text:GetTop() - 5)
		self.alliance:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp", "Button4Up", "Button5Up")
		self.alliance:SetScript("PostClick", function(self)
			if( IsAltKeyDown() and carriers["alliance"].name ) then
				SSPVP:ChannelMessage(string.format(L["Alliance flag carrier %s, held for %s."], carriers["alliance"].name, SecondsToTime(GetTime() - carriers["alliance"].time)))
			end
			
			if( UnitExists("target") and UnitName("target") == carriers["alliance"].name ) then
				UIErrorsFrame:AddMessage(string.format(L["Targetting %s"], carriers["alliance"].name), 1.0, 0.1, 0.1, 1.0)
			elseif( carriers["alliance"].name ) then
				UIErrorsFrame:AddMessage(string.format(L["%s is out of range"], carriers["alliance"].name), 1.0, 0.1, 0.1, 1.0)
			end
		end)

		self.alliance.text = self.alliance:CreateFontString(nil, "BACKGROUND")
		self.alliance.text:SetPoint("TOPLEFT", self.alliance, "TOPLEFT", 0, 0)
		self.alliance.text:SetFont((GameFontNormal:GetFont()), 11)
		self.alliance.text:SetShadowOffset(1, -1)
		self.alliance.text:SetShadowColor(0, 0, 0, 1)
		self.alliance.text:SetJustifyH("LEFT")
		self.alliance.text:SetHeight(25)
		self.alliance.text:SetWidth(150)
	end
	
	if( not self.horde and AlwaysUpFrame2Text ) then
		self.horde = CreateFrame("Button", "SSFlagHorde", UIParent, "SecureActionButtonTemplate")
		self.horde:SetHeight(25)
		self.horde:SetWidth(150)
		self.horde:ClearAllPoints()
		self.horde:SetPoint("LEFT", UIParent, "BOTTOMLEFT", AlwaysUpFrame2Text:GetRight() + 8, AlwaysUpFrame2Text:GetTop() - 5)
		self.horde:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp", "Button4Up", "Button5Up")
		self.horde:SetScript("PostClick", function()
			if( IsAltKeyDown() and carriers["horde"].name ) then
				SSPVP:ChannelMessage(string.format(L["Horde flag carrier %s, held for %s."], carriers["horde"].name, SecondsToTime(GetTime() - carriers["horde"].time)))
			end

			if( UnitExists("target") and UnitName("target") == carriers["horde"].name ) then
				UIErrorsFrame:AddMessage(string.format(L["Targetting %s"], carriers["horde"].name), 1.0, 0.1, 0.1, 1.0)
			elseif( carriers["horde"].name ) then
				UIErrorsFrame:AddMessage(string.format(L["%s is out of range"], carriers["horde"].name), 1.0, 0.1, 0.1, 1.0)
			end
		end)

		self.horde.text = self.horde:CreateFontString(nil, "BACKGROUND")
		self.horde.text:SetPoint("TOPLEFT", self.horde, "TOPLEFT", 0, 0)
		self.horde.text:SetFont((GameFontNormal:GetFont()), 11)
		self.horde.text:SetShadowOffset(1, -1)
		self.horde.text:SetShadowColor(0, 0, 0, 1)
		self.horde.text:SetJustifyH("LEFT")
		self.horde.text:SetHeight(25)
		self.horde.text:SetWidth(150)
	end
end