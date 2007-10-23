Bishop = DongleStub("Dongle-1.1"):New("Bishop")

local L = BishopLocals

local CREATED_ROWS = 0

local spellData
local talentData
local rangedData

local healData = {}

local playerTalents = {}
local equippedBonus = {}

local playerLevel = 0
local regrowthHealing = 0

local healYourself
local healOther
local healCritYourself
local healCritOther
local hotYourself
local hotOther

local OptionHouse
local HouseAuthority

function Bishop:Initialize()
	self.defaults = {
		profile = {
			scale = 1.0,
			locked = false,
			barTexture = "Interface\\TargetingFrame\\UI-StatusBar",
			barColor = { r = 0.20, g = 1.0, b = 0.20 },
			position = { x = 300, y = 600 },
		}
	}
	
	self.db = self:InitializeDB("BishopDB", self.defaults)

	self.cmd = self:InitializeSlashCommand(L["Bishop slash commands"], "BISHOP", "bishop")
	self.cmd:InjectDBCommands(self.db, "delete", "copy", "list", "set")
	self.cmd:RegisterSlashHandler(L["ui - Pulls up the configuration page"], "ui", function() OptionHouse:Open("Bishop") end)
	self.cmd:RegisterSlashHandler(L["toggle - Toggles the meter open/closed"], "toggle", "ToggleMeter")
	self.cmd:RegisterSlashHandler(L["reset - Resets all saved healing data"], "reset", "ResetMeter")

	OptionHouse = LibStub("OptionHouse-1.1")
	HouseAuthority = LibStub("HousingAuthority-1.2")
		
	local OHObj = OptionHouse:RegisterAddOn("Bishop", nil, "Amarand", "r" .. tonumber(string.match("$Revision$", "(%d+)") or 1))
	OHObj:RegisterCategory(L["General"], self, "CreateUI", nil, 1)
end

function Bishop:Enable()
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_BUFFS")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS")
	self:RegisterEvent("CHAT_MSG_SPELL_SELF_BUFF")

	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:RegisterEvent("UNIT_SPELLCAST_SENT")
	--self:RegisterEvent("UNIT_SPELLCAST_STOP")
	--self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")

	self:RegisterEvent("CONFIRM_TALENT_WIPE", "ScanPlayerTalents")
	self:RegisterEvent("CHARACTER_POINTS_CHANGED", "ScanPlayerTalents")
	self:RegisterEvent("UNIT_INVENTORY_CHANGED", "ScanPlayerRanged")
	
	spellData, talentData, rangedData = BishopData["Load" .. select(2, UnitClass("player"))]()
	rangedData = rangedData or {}
	
	-- Failed to load any data, exit quickly
	if( not spellData ) then
		self:Disable()
		return
	end
	
	self:ScanPlayerTalents()
	self:ScanPlayerRanged()
	
	playerLevel = UnitLevel("player")
	
--[[
	PERIODICAURAHEALSELFOTHER = "%s gains %d health from your %s.";
	PERIODICAURAHEALSELF = "You gain %d health from %s.";	
	HEALEDCRITSELFOTHER = "Your %s critically heals %s for %d.";
	HEALEDCRITSELFSELF = "Your %s critically heals you for %d.";
	HEALEDSELFOTHER = "Your %s heals %s for %d.";
	HEALEDSELFSELF = "Your %s heals you for %d.";
]]

	healYourself = self:FormatLog(HEALEDSELFSELF)
	healCritYourself = self:FormatLog(HEALEDCRITSELFSELF)
	healOther = self:FormatLog(HEALEDSELFOTHER)
	healCritOther = self:FormatLog(HEALEDCRITSELFOTHER)

	hotYourself = self:FormatLog(PERIODICAURAHEALSELF)
	hotOther = self:FormatLog(PERIODICAURAHEALSELFOTHER)
end

function Bishop:Disable()
	self:UnregisterAllEvents()
end

function Bishop:Debug()
	for spell, data in pairs(healData) do
		DEFAULT_CHAT_FRAME:AddMessage(string.format("[%s] %d (%d overheal, %d ticks/casts)", spell, data.totalHealed, data.overheal, data.totalCasts))
	end
end

function Bishop:HealedPlayer(spell, amount, crtHealth, maxHealth, type)
	if( not healData[spell] ) then
		healData[spell] = { totalHealed = 0, overheal = 0, totalCasts = 0 }
	end	

	-- HoT, so subtract it from our current overheal
	if( type == "hot" ) then
		-- Check overheal
		local overheal = amount
		if( (crtHealth + amount) > maxHealth ) then
			overheal = maxHealth - crtHealth
		end
		
		healData[spell].totalTicks = ( healData[spell].totalTicks or 0 ) + 1
		healData[spell].overheal = healData[spell].overheal - overheal
	
	-- Direct heal, check overheal amount
	elseif( type == "heal" ) then
		-- Check overheal amount
		local overheal = crtHealth + amount
		if( overheal > maxHealth ) then
			overheal = overheal - maxHealth
		else
			overheal = 0
		end

		healData[spell].totalCasts = healData[spell].totalCasts + 1
		healData[spell].totalHealed = healData[spell].totalHealed + amount
		healData[spell].overheal = healData[spell].overheal + overheal
	end
	
	if( healData[spell].overheal < 0 ) then
		healData[spell].overheal = 0
	end
	
	-- Update the meter if shown, or if it's enabled
	if( ( not self.frame and self.db.profile.showFrame ) or ( self.frame and self.frame:IsVisible() ) ) then
		self:ShowMeterUI()
	end
	
	--self:Echo(spell, healData[spell].totalHealed, healData[spell].overheal)
end

function Bishop:CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS(event, msg)
	if( string.match(msg, hotYourself) ) then
		local amount, spell = string.match(msg, hotYourself)
		self:HealedPlayer(L["HOT"][spell] or spell, amount, UnitHealth("player"), UnitHealthMax("player"), "hot")
	end
end

function Bishop:CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_BUFFS(event, msg)
	if( string.match(msg, hotOther) ) then
		local target, amount, spell = string.match(msg, hotOther)
		self:HealedPlayer(L["HOT"][spell] or spell, amount, UnitHealth(target), UnitHealthMax(target), "hot")
	end
end

function Bishop:CHAT_MSG_SPELL_SELF_BUFF(event, msg)
	if( string.match(msg, healCritYourself) ) then
		local spell, amount = string.match(msg, healCritYourself)
	
		self:HealedPlayer(L["HEAL"][spell] or spell, amount, UnitHealth("player"), UnitHealthMax("player"), "heal")
	elseif( string.match(msg, healYourself) ) then
		local spell, amount = string.match(msg, healYourself)
		
		self:HealedPlayer(L["HEAL"][spell] or spell, amount, UnitHealth("player"), UnitHealthMax("player"), "heal")
	elseif( string.match(msg, healCritOther) ) then
		local spell, target, amount = string.match(msg, healCritOther)

		self:HealedPlayer(L["HEAL"][spell] or spell, amount, UnitHealth(target), UnitHealthMax(target), "heal")
	elseif( string.match(msg, healOther) ) then
		local spell, target, amount = string.match(msg, healOther)
		
		self:HealedPlayer(L["HEAL"][spell] or spell, amount, UnitHealth(target), UnitHealthMax(target), "heal")
	end
end

function Bishop:UNIT_SPELLCAST_SUCCEEDED(event, unit, spell, rank)
	if( unit ~= "player" ) then
		return
	end
	
	-- Regrowth has a cast time before the HoT lands so we have to check it once
	-- it goes off, instead of on sent
	if( spell == L["Regrowth"] ) then
		self:HealedPlayer(L["HOT"][spell], self:CalculateHOTHeal(spell, rank, regrowthHealing), 0, 0, "heal")
	end
end

function Bishop:UNIT_SPELLCAST_SENT(event, unit, spell, rank, target)
	if( unit ~= "player" ) then
		return
	end
	
	-- Figure out Lifebloom stack now for sanity
	if( spell == L["Lifebloom"] ) then
		local i = 1		
		local spellStack = 1
		
		while( true ) do
			local name, rank, _, stack, totalTime, duration = UnitBuff(target, i)
			if( not name ) then
				break
			end

			if( name == spell and duration ) then
				spellStack = stack + 1
				break
			end
			
			i = i + 1
		end
		
		self:HealedPlayer(L["HOT"][spell], self:CalculateHOTHeal(spell, rank, nil, spellStack), 0, 0, "heal")
	
	-- Also figure out rejuvenation heal now for sanity
	elseif( spell == L["Rejuvenation"] ) then
		self:HealedPlayer(spell, self:CalculateHOTHeal(spell, rank), 0, 0, "heal")
	
	-- As far as I know, Blizzard calculates the +healing by what it when
	-- the spell was sent to the server, so we have to store it here to calculate it
	elseif( spell == L["Regrowth"] ) then
		regrowthHealing = GetSpellBonusHealing()
	end
end


-- Figure out the total value of the HoT
function Bishop:CalculateHOTHeal(spellName, rank, totalHealing, spellStack)
	if( not spellName ) then
		return 0
	end
	
	rank = tonumber(string.match(rank, "(%d+)"))
	spellStack = spellStack or 1
	totalHealing = totalHealing or GetSpellBonusHealing()
	
	local healed = 0
	local spell = spellData[spellName]
	local addFactor = 1.0
	local multiFactor = spell[0].duration / 15
	
	-- For lifebloom mainly
	if( spellStack > spell[0].maxStack ) then
		spellStack = spell[0].maxStack
	end
			
	-- Apply talent information
	for talent, data in pairs(talentData) do
		if( not data.spell or data.spell == spellName ) then
			if( data.multi ) then
				multiFactor = multiFactor * (1 + (playerTalents[talent] * data.mod))
			else
				addFactor = addFactor + (playerTalents[talent] * data.mod)
			end
		end
	end
	
	-- Check if we have any idols/relics/librams increasing our +healing for this
	if( equippedBonus.spell == spellName ) then
		totalHealing = totalHealing + equippedBonus.healing		
	end
	
	-- Low level penalty
	local lowLevelPenalty = 1
	if( spell[rank].level < 20 ) then
		lowLevelPenalty = 1 - ((20 - spell[rank].level) * 0.0375)
		if( lowLevelPenalty < 1 or lowLevelPenalty > 0 ) then
			multiFactor = multiFactor * lowLevelPenalty
		end
	end
	
	-- Downrank penalty
	local downRankPenalty = (spell[rank].level + 11) / playerLevel
	if( downRankPenalty < 1 ) then
		multiFactor = multiFactor * downRankPenalty
	end
	
	-- Now calculate the total amount healed
	if( spell[0].type == "ddhot" ) then
		multiFactor = multiFactor * (1 - (spell[0].hotFactor or 0)) * (spell[0].dotFactor or 1)
		healed = addFactor * (multiFactor * totalHealing + spell[rank].healed )

	elseif( spell[0].type == "hot" ) then
		healed = addFactor * (1 * spell[rank].healed + (totalHealing * multiFactor))
	end
	
	--self:Echo(spellName, rank, healed * spellStack, multiFactor, addFactor)
	
	return healed * spellStack
end

-- Check if we have any healing bonuses applied
function Bishop:ScanPlayerRanged()
	equippedBonus.spell = nil
	equippedBonus.healing = nil
	
	for spell, items in pairs(rangedData) do
		for itemid, healing in pairs(items) do
			if( IsEquippedItem(itemid) ) then
				equippedBonus.spell = spell
				equippedBonus.healing = healing
				break
			end
		end
		
		if( equippedBonus.spell ) then
			break
		end
	end
end

-- Scan/cache talents
function Bishop:ScanPlayerTalents()
	for tabIndex=1, GetNumTalentTabs() do
		for i=1, GetNumTalents(tabIndex) do
			local talentName, _, _, _, pointsSpent = GetTalentInfo(tabIndex, i)	
			if( not talentName ) then
				break
			end
			
			playerTalents[talentName] = pointsSpent
		end
	end
end

-- Turn GlobalStrings log into useful one
function Bishop:FormatLog(text)
	text = string.gsub(text, "%%s", "(.+)")
	text = string.gsub(text, "%%d", "([0-9]+)")
	
	return text
end

-- METER GUI
function Bishop:ResetMeter()
	healData = {}

	if( self.frame ) then
		self.frame:Hide()
		for i=1, CREATED_ROWS do
			self.rows[i]:Hide()
		end
	end
	
	self:Print(L["All healing information has been reset!"])
end

function Bishop:ToggleMeter()
	if( self.frame and self.frame:IsVisible() ) then
		self.frame:Hide()
	elseif( not self.frame or not self.frame:IsVisible() ) then
		self:ShowMeterUI()
	end
end

function Bishop:ShowMeterUI()
	self:CreateMeterUI()
	
	local totalHealed = 0
	local totalOverheal = 0
	local rowID = 0
	for spell, data in pairs(healData) do
		rowID = rowID + 1
		if( CREATED_ROWS < rowID ) then
			self:CreateRow()
		end
		
		local row = self.rows[rowID]
		row.text:SetText(spell)
		--row.percentText:SetText(string.format("(%.2f%%)", (data.overheal / data.totalHealed) * 100))
		row.percentText:SetText(string.format("%d (%.2f%%)", data.totalHealed, (data.overheal / data.totalHealed) * 100))
		
		row:SetMinMaxValues(0, data.totalHealed)
		row:SetValue(data.overheal)
		row:SetStatusBarColor(self.db.profile.barColor.r, self.db.profile.barColor.g, self.db.profile.barColor.b)
		row:Show()
		
		totalHealed = totalHealed + data.totalHealed
		totalOverheal = totalOverheal + data.overheal
	end
	
	-- Total
	rowID = rowID + 1
	if( CREATED_ROWS < rowID ) then
		self:CreateRow()
	end
	
	local row = self.rows[rowID]
	row.text:SetText(L["Total"])
	row.percentText:SetText(string.format("%d (%.2f%%)", totalHealed, (totalOverheal / totalHealed) * 100))

	row:SetMinMaxValues(0, totalHealed)
	row:SetValue(totalOverheal)
	row:SetStatusBarColor(self.db.profile.barColor.r, self.db.profile.barColor.g, self.db.profile.barColor.b)
	row:Show()
	
	
	self.frame:SetHeight(rowID * 14)
	self.frame:Show()
end

function Bishop:CreateMeterUI()
	if( self.frame ) then
		return
	end
	self.rows = {}
	
	self.frame = CreateFrame("Frame", nil, UIParent)
	self.frame:SetScale(self.db.profile.scale)
	self.frame:SetWidth(210)
	self.frame:SetHeight(50)
	self.frame:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeSize = 0.6,
		insets = {left = 1, right = 1, top = 1, bottom = 1}})

	self.frame:SetBackdropColor(0, 0, 0, 1.0)
	self.frame:SetBackdropBorderColor(0.60, 0.60, 0.60, 1.0)
	self.frame:SetMovable(true)
	self.frame:EnableMouse(true)
	self.frame:SetClampedToScreen(true)

	self.frame:SetScript("OnMouseDown", function(self)
		if( not Bishop.db.profile.locked ) then
			self.isMoving = true
			self:StartMoving()
		end
	end)
	self.frame:SetScript("OnMouseUp", function(self)
		if( self.isMoving ) then
			self.isMoving = nil
			self:StopMovingOrSizing()

			Bishop.db.profile.position.x = self:GetLeft()
			Bishop.db.profile.position.y = self:GetTop()
		end
	end)	
	
	self.frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", self.db.profile.position.x, self.db.profile.position.y)
end

function Bishop:CreateRow()
	CREATED_ROWS = CREATED_ROWS + 1
	local id = CREATED_ROWS
	
	-- Health bar
	local row = CreateFrame("StatusBar", nil, self.frame)
	row:SetHeight(12)
	row:SetWidth(208)
	row:SetStatusBarTexture(self.db.profile.barTexture)
	row:Hide()
	
	-- Total health healed
	local text = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	text:SetPoint("LEFT", row, "LEFT", 1, 0)
	text:SetTextColor(1, 1, 1, 1.0)
	
	-- Overheal percent
	local percentText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	percentText:SetPoint("RIGHT", row, "RIGHT", -1, 0)
	percentText:SetTextColor(1, 1, 1, 1.0)
	
	-- Position
	if( id > 1 ) then
		row:SetPoint("TOPLEFT", self.rows[id - 1], "BOTTOMLEFT", 0, -2)
	else
		row:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 1, -1)
	end
	
	self.rows[id] = row
	self.rows[id].text = text
	self.rows[id].percentText = percentText
end

-- GUI CONFIG
function Bishop:Set(var, value)
	self.db.profile[var] = value
end

function Bishop:Get(var)
	return self.db.profile[var]
end

function Bishop:Reload()
	if( self.db.profile.showFrame ) then
		self:ShowMeterUI()
	elseif( self.frame ) then
		self.frame:Hide()
	end
	
	if( self.frame ) then
		self.frame:SetScale(self.db.profile.scale)

		for i=1, CREATED_ROWS do
			self.rows[i]:SetStatusBarColor(self.db.profile.barColor.r, self.db.profile.barColor.g, self.db.profile.barColor.b)
			self.rows[i]:SetStatusBarTexture(self.db.profile.barTexture)
		end
	end
end

local SML
function Bishop:CreateUI()
	local config = {
		{ group = L["Display"], text = L["Bar texture"], type = "dropdown", list = {{"Interface\\TargetingFrame\\UI-StatusBar", "Blizzard"}}, var = "barTexture"},
		{ group = L["Color"], text = L["Bar color"], type = "color", var = "barColor"},
				
		{ group = L["Frame"], text = L["Show frame"], type = "check", var = "showFrame"},
		{ group = L["Frame"], text = L["Lock frame"], type = "check", var = "locked"},
		{ group = L["Frame"], format = L["Frame scale: %d%%"], manualInput = true, min = 0.0, max = 2.0, type = "slider", var = "scale"}
	}

	-- Update the dropdown incase any new textures were added
	local frame = HouseAuthority:CreateConfiguration(config, {set = "Set", get = "Get", onSet = "Reload", handler = Bishop})
	frame:Hide()
	frame:SetScript("OnShow", function(self)
		if( not SML ) then
			SML = LibStub:GetLibrary("LibSharedMedia-2.0")
			SML:Register(SML.MediaType.STATUSBAR, "XRaid", "Interface\\Bishop\\Images\\xraid_statusbar.tga")
		end

		local textures = {}
		for _, name in pairs(SML:List(SML.MediaType.STATUSBAR)) do
			table.insert(textures, {SML:Fetch(SML.MediaType.STATUSBAR, name), name})
		end

		HouseAuthority:GetObject(self):UpdateDropdown({var = "barTexture", list = textures})
	end)
	
	return frame
end
