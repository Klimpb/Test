local Flag = SSPVP:NewModule("Flag", "AceEvent-3.0", "AceTimer-3.0")
Flag.activeIn = "bg"

local L = SSPVPLocals
local carriers = {["alliance"] = {}, ["horde"] = {}}

function Flag:OnEnable()
	self.defaults = {
		profile = {
			color = true,
			health = true,
		},
	}
	
	self.db = SSPVP.db:RegisterNamespace("score", self.defaults)	
	
	playerName = UnitName("player")
end

function Flag:EnableModule(abbrev)
	-- Flags are only used inside EoTS and WSG currently
	if( abbrev ~= "eots" and abbrev ~= "wsg" ) then
		self.isActive = nil
		return
	end

	self:RegisterEvent("CHAT_MSG_BG_SYSTEM_HORDE", "ParseMessage")
	self:RegisterEvent("CHAT_MSG_BG_SYSTEM_ALLIANCE", "ParseMessage")
	self:RegisterEven2t("UPDATE_BINDINGS")
	
	if( self.db.profile.health ) then
		self:RegisterEvent("UNIT_HEALTH")
	end
	
	self:CreateButtons()
	self:ScheduleRepeatingTimer("ScanParty", 0.50)
	self:ScheduleRepeatingTimer("ResetHealth", 5)
	
	self.activeBF = abbrev
end

function Flag:DisableModule()
	self:CancelAllTimers()
	self:UnregisterAllEvents()
	
	for k, v in pairs(carriers["alliance"]) do
		v = nil
	end
	
	for k, v in pairs(carriers["horde"]) do
		v = nil
	end
end

function Flag:Reload()
	if( self.db.profile.health and self.isActive ) then
		self:RegisterEvent("UNIT_HEALTH")
	else
		self:UnregisterEvent("UNIT_HEALTH")
	end
	
	if( self.isActive ) then
		self:UpdateCarriers()
	end
end

-- Scan unit updates
function Flag:UNIT_HEALTH(event, unit)
	self:UpdateHealth(unit)
end

-- Scan raid targets
function Flag:ScanParty()
	for i=1, GetNumRaidMembers() do
		if( UnitExists("raid" .. i .. "target") ) then
			self:UpdateHealth("raid" .. i .. "target")
		end
	end
end

-- Update health
function Flag:UpdateHealth(unit)
	local name = UnitName(unit)
	if( carriers["alliance"].name == name ) then
		carriers["alliance"].health = floor((UnitHealth(unit) / UnitHealthMax(unit) * 100) + 0.5)
		carriers["alliance"].timeout = GetTime() + 5

	elseif( carriers["horde"].name == name ) then
		carriers["horde"].health = floor((UnitHealth(unit) / UnitHealthMax(unit) * 100) + 0.5)
		carriers["horde"].timeout = GetTime() + 5
	end
end

-- More then 5 seconds without updates means they're too far away
function Flag:ResetHealth(faction)
	if( carriers["alliance"].health and carriers["alliance"].timeout <= GetTime() ) then
		carriers["alliance"].health = nil
		carriers["alliance"].timeout = nil
		
		self:UpdateCarrier("alliance")
	end

	if( carriers["horde"].health and carriers["horde"].timeout <= GetTime() ) then
		carriers["horde"].health = nil
		carriers["horde"].timeout = nil
		
		self:UpdateCarrier("horde")
	end
end

-- Update the actual display
function Flag:UpdateCarriers()
	self:UpdateCarrier("alliance")
	self:UpdateCarrier("horde")
end

function Flag:UpdateCarrier(faction)
	if( InCombatLockdown() ) then
		SSPVP:RegisterOOCUpdate("UpdateCarriers")
		return
	end
	
	-- No carrier, hide it, this is bad
	if( not carriers[faction].name ) then
		self:Hide(faction)
		return
	end
	
	local health = ""
	if( carriers[faction].health and self.db.profile.health ) then
		health = " [" .. carriers[faction].health .. "%]"
	end
	
	self[faction].text:SetText(carriers[faction].name .. health)

	-- Carrier class color if enabled/not set
	if( not self[faction].colorSet and self.db.profile.color ) then
		for i=1, GetNumBattlefieldScores() do
			local name, _, _, _, _, _, _, _, _, classToken = GetBattlefieldScore(i)
			
			if( name == carrierName  or ( string.match(name, "-") and carrierName == (string.split("-", name)) ) ) then
				self[faction].text:SetTextColor(RAID_CLASS_COLORS[classToken].r, RAID_CLASS_COLORS[classToken].g, RAID_CLASS_COLORS[classToken].b)
				self[faction].colorSet = true
				break
			end
		end
	end
	
	-- Update the color to the default because we couldn't find one
	if( not self[faction].colorSet ) then
		text:SetTextColor(GameFontNormal:GetTextColor())
	end
end

-- Parse event for changes
function Flag:ParseMessage(event, msg)
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

	-- WSG/EoTS, captured
	elseif( string.match(msg, L["captured the"]) ) then
		self:Captured(faction)

	-- EoTS/WSG, dropped
	elseif( string.match(msg, L["was dropped by (.+)!"]) or string.match(msg, L["The flag has been dropped"]) ) then
		self:Dropped(faction)
	end
end

-- Respawn = 21s wsg, 10s eots
function Flag:Captured(faction)
	carriers[faction].time = nil
	carriers[faction].name = nil
	self:Hide(faction)
end

function Flag:Dropped(faction)
	carriers[faction].time = nil
	carriers[faction].name = nil
	self:Hide(faction)
end

function Flag:PickUp(faction, name)
	carriers[faction].time = GetTime()
	carriers[faction].name = name
	self:Show(faction)
end

-- Show flag
function Flag:Show(faction)
	if( InCombatLockdown() ) then
		self[faction]:SetAlpha(0.75)
		SSPVP:RegisterOOCUpdate("Show", faction)
	else
		self:UpdateCarrier(faction)
		self[faction]:SetAlpha(1.0)
		self[faction]:Show()
	end
end

-- Hide flag
function Flag:Hide(faction)
	if( InCombatLockdown() ) then
		self[faction]:SetAlpha(0.75)
		SSPVP:RegisterOOCUpdate("Hide", faction)
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
	if( not self.alliance ) then
		self.alliance = CreateFrame("Button", "SSFlagAlliance", UIParent, "SecureActionButtonTemplate")
		self.alliance:SetHeight(25)
		self.alliance:SetWidth(150)
		self.alliance:SetPoint("TOPRIGHT", AlwaysUpFrame1Text, "TOPRIGHT", 0, 0)
		self.alliance:SetScript("PostClick", function()
			if( IsAltKeyDown() and carrierNames["Alliance" ] ) then
				SSPVP:ChannelMessage(string.format(L["Alliance flag carrier %s, held for %s."], carriers["alliance"].name, SecondsToTime(carriers["alliance"].time)))
			end
		end)

		self.alliance.text = self.alliance:CreateFontString(nil, "BACKGROUND")
		self.alliance.text:SetJustifyH("LEFT")
		self.alliance.text:SetHeight(25)
		self.alliance.text:SetWidth(150)
	end
	
	if( not self.horde ) then
		self.horde = CreateFrame("Button", "SSFlagHorde", UIParent, "SecureActionButtonTemplate")
		self.horde:SetHeight(25)
		self.horde:SetWidth(150)
		self.horde:SetPoint("TOPRIGHT", AlwaysUpFrame2Text, "TOPRIGHT", 0, 0)
		self.horde:SetScript("PostClick", function()
			if( IsAltKeyDown() and carrierNames["Horde" ] ) then
				SSPVP:ChannelMessage(string.format(L["Horde flag carrier %s, held for %s."], carriers["horde"].name, SecondsToTime(carriers["horde"].time)))
			end
		end)

		self.horde.text = self.horde:CreateFontString(nil, "BACKGROUND")
		self.horde.text:SetJustifyH("LEFT")
		self.horde.text:SetHeight(25)
		self.horde.text:SetWidth(150)
	end
end