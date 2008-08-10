SSFlags = LibStub("AceAddon-3.0"):NewAddon("SSFlags", "AceEvent-3.0")

local L = SSFlagsLocals

local carriers = {["Alliance"] = {}, ["Horde"] = {}}
local buttons = {}

local raidUnits, raidTargetUnits, partyUnits, partyTargetUnits = {}, {}, {}, {}

local instanceType, queueReposition, queueUpdate, queueStatus, queueBindings

function SSFlags:OnInitialize()
	self.defaults = {
		profile = {
			wsg = {
				enabled = true,
				color = true,
				health = true,
				--respawn = true,
				--capture = true,
				macro = "/targetexact *name",
			},
			eots = {
				enabled = true,
				color = true,
				health = true,
				--respawn = true,
				--capture = true,
				macro = "/targetexact *name",
			},
		},
	}
	
	self.db = LibStub:GetLibrary("AceDB-3.0"):New("SSFlagsDB", self.defaults)
	
	-- SSPVP3 will be our "global" table if needed later on
	SSPVP3 = SSPVP3 or {}
	SSPVP3.Slash = SSPVP3.Slash or {}
	SSPVP3.Flags = SSFlags
	
	table.insert(SSPVP3.Slash, L["/ssflags - Flag configuration for battlegrounds like WSG and EoTS."])
	
	-- Store these so we don't have to keep concating 500 times
	for i=1, MAX_RAID_MEMBERS do
		raidUnits[i] = "raid" .. i
		raidTargetUnits[i] = "raid" .. i .. "target"
	end
	
	for i=1, MAX_PARTY_MEMBERS do
		partyUnits[i] = "party" .. i
		partyTargetUnits[i] = "party" .. i .. "target"
	end
end

function SSFlags:OnEnable()
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
end

-- Check if we're in WSG or EoTS
function SSFlags:ZONE_CHANGED_NEW_AREA()
	local type = select(2, IsInInstance())

	if( type == "pvp" and type ~= instanceType ) then
		local zone = GetRealZoneText() or ""
		
		local abbrev
		if( zone == L["Warsong Gulch"] ) then
			abbrev = "wsg"
		elseif( zone == L["Eye of the Storm"] ) then
			abbrev = "eots"
		end
		
		if( abbrev ) then
			instanceType = type
			self:Enable(abbrev)
		end
		return
	
	-- Left a pvp zone
	elseif( instanceType == "pvp" and type ~= instanceType and self.activeBF ) then
		self:Disable()
	end
	
	instanceType = type
end

-- Joined a battlefield that uses flags
function SSFlags:Enable(abbrev)
	if( not self.db.profile[abbrev].enabled ) then
		return
	end
	
	self:CreateButton(1)
	self:CreateButton(2)

	self.activeBF = abbrev
	
	-- Start health scans
	self.frame:Show()
	
	-- For now, it's consistant. Alliance is always up #1, Horde is always up #2
	-- If the WoTLK battlegrounds change this, then this will have to get updated
	buttons[1].type = "Alliance"
	self.Alliance = buttons[1]
	
	buttons[2].type = "Horde"
	self.Horde = buttons[2]
	
	
	self:RegisterEvent("CHAT_MSG_BG_SYSTEM_HORDE", "ParseMessage")
	self:RegisterEvent("CHAT_MSG_BG_SYSTEM_ALLIANCE", "ParseMessage")
	self:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL", "ParseMessage")
	self:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")
	--self:RegisterEvent("UPDATE_BINDINGS")
	
	if( self.db.profile[abbrev].health ) then
		self:RegisterEvent("UNIT_HEALTH")
		self:RegisterEvent("PLAYER_TARGET_CHANGED")
		self:RegisterEvent("PLAYER_FOCUS_CHANGED")
		self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
	end
end

-- Left a battlefield
function SSFlags:Disable()
	self.activeBF = nil
	
	-- Reset
	for faction, data in pairs(carriers) do
		for key in pairs(data) do
			data[key] = nil
		end
		
		self:Hide(faction)
	end
	
	-- Stop health updates
	self.frame:Hide()
	
	-- Clear overlay
	SSOverlay:RemoveCategory("timer")
	
	self:UnregisterAllEvents()
	self:OnEnable()
end

function SSFlags:Reload()
end

function SSFlags:Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99SSFlags|r: " .. msg)
end

-- Update carriers incase we have class
function SSFlags:UPDATE_BATTLEFIELD_SCORE()
	for faction, data in pairs(carriers) do
		if( data.name ) then
			self:UpdateCarrier(faction)
		end
	end
end

-- We split these into two different functions, so we can do color/text/health updates while in combat, but update targeting when out of it
function SSFlags:UpdateCarrierAttributes(faction)
	-- Carrier changed but we can't update it yet
	local carrier = carriers[faction].name
	local button = self[faction]
	if( button.carrier ~= carrier ) then
		button:SetAlpha(0.75)
	else
		button:SetAlpha(1.0)
	end
	
	-- In combat, can't change anything
	if( InCombatLockdown() ) then
		queueUpdate = true
		return
	end

	button.carrier = carrier
	button:SetAttribute("type", "macro")
	button:SetAttribute("macrotext", string.gsub(self.db.profile[self.activeBF].macro, "*name", carrier or ""))
end

function SSFlags:UpdateCarrier(faction)
	-- Check if we have a carrier
	local carrier = carriers[faction]
	if( not carrier.name ) then
		self:Hide(faction)
		return
	end
		
	local button = self[faction]
	if( carrier.health ) then
		button.text:SetFormattedText("%s |cffffffff[%d%%]|r", carrier.name, carrier.health)		
	else
		button.text:SetText(carrier.name)
	end

	-- Carrier class color if enabled/not set
	if( button.colorSet ~= carrier.name and self.db.profile[self.activeBF].color ) then
		for i=1, GetNumBattlefieldScores() do
			local name, _, _, _, _, _, _, _, _, classToken = GetBattlefieldScore(i)
			
			if( self:StripServer(name) == carrier.name ) then
				button.text:SetTextColor(RAID_CLASS_COLORS[classToken].r, RAID_CLASS_COLORS[classToken].g, RAID_CLASS_COLORS[classToken].b)
				button.colorSet = carrier.name
				break
			end
		end
	end
		
	-- Update the color to the default because we couldn't find one
	if( button.colorSet ~= carrier.name ) then
		button.text:SetTextColor(GameFontNormal:GetTextColor())
	end
end

function SSFlags:StripServer(text)
	local name, server = string.match(text, "(.-)%-(.*)$")
	if( not name and not server ) then
		return text
	end
	
	return name
end

-- Parse event for changes
function SSFlags:ParseMessage(event, msg)
	-- More sane for us to do it here
	local faction
	if( self.activeBF == "wsg" ) then
		-- Reverse the factions because Alliance found = Horde event
		-- Horde found = Alliance event
		if( string.match(msg, L["Alliance"]) ) then
			faction = "Horde"
		elseif( string.match(msg, L["Horde"]) ) then
			faction = "Alliance"
		end
	elseif( event == "CHAT_MSG_BG_SYSTEM_HORDE" ) then
		faction = "Horde"
	elseif( event == "CHAT_MSG_BG_SYSTEM_ALLIANCE" ) then
		faction = "Alliance"
	end
	
	-- WSG, pick up
	if( string.match(msg, L["was picked up by (.+)!"]) ) then
		self:PickUp(faction, string.match(msg, L["was picked up by (.+)!"]))
	
	-- EoTS, pick up
	elseif( string.match(msg, L["(.+) has taken the flag!"]) ) then
		self:PickUp(faction, string.match(msg, L["(.+) has taken the flag!"]))

	-- WSG, returned
	elseif( string.match(msg, L["was returned to its base"]) ) then
		self:Returned(faction)
	
	-- EOTS, returned
	elseif( string.match(msg, L["flag has been reset"]) ) then
		self:Returned("Horde")
		self:Returned("Alliance")
		
	-- WSG/EoTS, captured
	elseif( string.match(msg, L["captured the"]) ) then
		self:Captured(faction)
	
	-- EoTS/WSG, dropped
	elseif( string.match(msg, L["was dropped by (.+)!"]) or string.match(msg, L["The flag has been dropped"]) ) then
		self:Dropped(faction)
	end
end

-- Flag captured = time reset as well
function SSFlags:Captured(faction)
	-- Clear out
	carriers[faction].time = nil
	carriers[faction].name = nil
	carriers[faction].health = nil
	
	self:Hide(faction)
end

function SSFlags:Dropped(faction)
	carriers[faction].name = nil
	carriers[faction].health = nil
	
	self:Hide(faction)
end

-- Return = time reset
function SSFlags:Returned(faction)
	carriers[faction].time = nil
	carriers[faction].name = nil
end

function SSFlags:PickUp(faction, name)
	carriers[faction].name = name

	-- If the flags dropped then picked up, we don't want to reset time
	if( not carriers[faction].time ) then
		carriers[faction].time = GetTime()
	end
	
	self:Show(faction)
end

-- Update visibility based on what we have picked up
function SSFlags:UpdateStatus()
	for key, data in pairs(carriers) do
		if( data.name ) then
			self:Show(key)
		else
			self:Hide(key)
		end
	end
end

-- Show flag
function SSFlags:Show(faction)
	self:UpdateCarrier(faction)
	
	local button = self[faction]
	if( InCombatLockdown() ) then
		button:SetAlpha(0.75)
		queueStatus = true
	else
		self:UpdateCarrierAttributes(faction)
		button:SetAlpha(1.0)
		button:Show()
	end
end

-- Hide flag
function SSFlags:Hide(faction)
	local button = self[faction]
	if( InCombatLockdown() ) then
		button:SetAlpha(0.75)
		queueStatus = true
	else
		button.carrier = nil
		button:Hide()
	end
end

-- Carrier targeting
local function carrierPostClick(self)
	local faction = self.type
	if( not carriers[faction].name ) then
		return
	end

	if( self:GetAlpha() ~= 1.0 ) then
		UIErrorsFrame:AddMessage(string.format(L["Cannot target %s, in combat"], carriers[faction].name), 1.0, 0.1, 0.1, 1.0)
	elseif( UnitExists("target") and UnitName("target") == carriers[faction].name ) then
		UIErrorsFrame:AddMessage(string.format(L["Targetting %s"], carriers[faction].name), 1.0, 0.1, 0.1, 1.0)
	else
		UIErrorsFrame:AddMessage(string.format(L["%s is out of range"], carriers[faction].name), 1.0, 0.1, 0.1, 1.0)
	end
end

-- Create our target buttons
function SSFlags:CreateButton(id)
	local button = CreateFrame("Button", "SSFlag" .. id, UIParent, "SecureActionButtonTemplate")
	button:SetHeight(25)
	button:SetWidth(150)
	button:RegisterForClicks("AnyUp")
	button:SetScript("PostClick", carrierPostClick)

	button.text = button:CreateFontString(nil, "BACKGROUND")
	button.text:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
	button.text:SetFont((GameFontNormal:GetFont()), 11)
	button.text:SetShadowOffset(1, -1)
	button.text:SetShadowColor(0, 0, 0, 1)
	button.text:SetJustifyH("LEFT")
	button.text:SetHeight(25)
	button.text:SetWidth(150)
	
	buttons[id] = button
end

function SSFlags:PositionButtons()
	if( InCombatLockdown() ) then
		queueReposition = true
		return
	end

	for i=1, NUM_ALWAYS_UP_UI_FRAMES do
		local dynamicIcon = getglobal(string.format("AlwaysUpFrame%dDynamicIconButton", i))
		if( dynamicIcon and buttons[i] ) then
			if( dynamicIcon:IsVisible() ) then
				buttons[i]:SetPoint("LEFT", UIParent, "BOTTOMLEFT", dynamicIcon:GetRight() + 6, dynamicIcon:GetTop() - 13)
			else
				local text = getglobal(string.format("AlwaysUpFrame%dText", i))
				buttons[i]:SetPoint("LEFT", UIParent, "BOTTOMLEFT", text:GetRight() + 8, text:GetTop() - 5)
			end
		end
	end
end

-- Ensure that the buttons will always be positioned on the always up frame
local Orig_WorldStateAlwaysUpFrame_Update = WorldStateAlwaysUpFrame_Update
function WorldStateAlwaysUpFrame_Update(...)
	Orig_WorldStateAlwaysUpFrame_Update(...)
	
	if( SSFlags.activeBF ) then
		SSFlags:PositionButtons()
	end
end

-- Queuing updates for OOC
function SSFlags:PLAYER_REGEN_ENABLED()
	if( queueReposition ) then
		queueReposition = nil
		SSFlags:PositionButtons()
	end
	
	if( queueUpdate ) then
		queueUpdate = nil
		SSFlags:UpdateAttributes("Alliance")
		SSFlags:UpdateAttributes("Horde")
	end
	
	if( queueStatus ) then
		queueStatus = nil
		for i=1, #(buttons) do
			SSFlags:UpdateStatus(i)
		end
	end
	
	if( queueBindings ) then
		queueBindings = nil
		--SSFlags:UPDATE_BINDINGS()
	end
end


-- HEALTH UPDATES
local HEALTH_TIMEOUT = 10
local partyScan = 0
local allianceTimeout, hordeTimeout

function SSFlags:UNIT_HEALTH(event, unit)
	self:UpdateHealth(unit)
end

function SSFlags:UPDATE_MOUSEOVER_UNIT()
	self:UpdateHealth("mouseover")
end

function SSFlags:PLAYER_FOCUS_CHANGED()
	self:UpdateHealth("focus")
end

function SSFlags:PLAYER_TARGET_CHANGED()
	self:UpdateHealth("target")
end

-- Scan raid targets
function SSFlags:ScanParty()
	for i=1, GetNumRaidMembers() do
		self:UpdateHealth(raidUnits[i])
		self:UpdateHealth(raidTargetUnits[i])
	end
end

-- Update health
function SSFlags:UpdateHealth(unit)
	if( not UnitExists(unit) or not UnitFactionGroup(unit) ) then
		return
	end

	local name = UnitName(unit)
	local faction = UnitFactionGroup(unit)
	if( carriers[faction].name == name ) then
		carriers[faction].health = floor((UnitHealth(unit) / UnitHealthMax(unit) * 100) + 0.5)
		
		self:UpdateCarrier(faction)
		
		if( faction == "Alliance" ) then
			allianceTimeout = HEALTH_TIMEOUT
		else
			hordeTimeout = HEALTH_TIMEOUT
		end
	end
end

-- Check if we can still get health updates from them
function SSFlags:IsTargeted(name)
	-- Check if it's our target or mouseover
	if( UnitName("target") == name or UnitName("mouseover") == name or UnitName("focus") == name ) then
		return true
	end
	
	-- Scan raid member targets, and raid member targets of target
	for i=1, GetNumRaidMembers() do
		if( ( UnitExists(raidUnits[i]) and UnitName(raidUnits[i]) == name ) or ( UnitExists(raidTargetUnits[i]) and UnitName(raidTargetUnits[i]) == name ) ) then
			return true
		end
	end
	
	-- Scan party member targets, and party member targets of target
	for i=1, GetNumPartyMembers() do
		if( ( UnitExists(partyUnits[i]) and UnitName(partyUnits[i]) == name ) or ( UnitExists(partyTargetUnits[i]) and UnitName(partyTargetUnits[i]) == name ) ) then
			return true
		end
	end
	
	return nil
end

-- More then HEALTH_TIMEOUT seconds without updates means they're too far away
function SSFlags:ResetHealth(type)
	-- If we still have them targeted, don't reset health
	if( self:IsTargeted(carriers[type].name) ) then
		if( type == "Alliance" ) then
			allianceTimeout = HEALTH_TIMEOUT
		else
			hordeTimeout = HEALTH_TIMEOUT
		end
		return
	end

	if( carriers[type] and carriers[type].health ) then
		carriers[type].health = nil
		self:UpdateCarrier(type)
	end
end

-- Health OnUpdate
SSFlags.frame = CreateFrame("Frame")
SSFlags.frame:Hide()

SSFlags.frame:SetScript("OnUpdate", function(self, elapsed)
	if( allianceTimeout ) then
		allianceTimeout = allianceTimeout - elapsed
		
		if( allianceTimeout <= 0 ) then
			allianceTimeout = nil
			SSFlags:ResetHealth("Alliance")
		end
	end
	
	if( hordeTimeout ) then
		hordeTimeout = hordeTimeout - elapsed
		
		if( hordeTimeout <= 0 ) then
			hordeTimeout = nil
			SSFlags:ResetHealth("Horde")
		end
	end
	
	partyScan = partyScan + elapsed
	if( partyScan >= 5 ) then
		SSFlags:ScanParty()
	end
end)