HasteBlock = {}

local LB
local OH

local L = HasteBlockLocals
local display = ""

local mainHand
local offHand
local ranged

local mhLink
local ohLink
local rangedLink

local baseSpell = 0
local currentSpell = 0
local spellID
local usedFormats = 0

local isInCombat

function HasteBlock:OnLoad()
	self.tooltip = CreateFrame("GameTooltip", "HBTooltip", UIParent, "GameTooltipTemplate")
	self.tooltip:SetOwner(this, "ANCHOR_NONE")
	
	if( not HasteBlockDB ) then HasteBlockDB = { lego = { bgAlpha = 1.0, borderAlpha = 1.0 } } end
	self.db = HasteBlockDB

	LB = DongleStub("LegoBlock-Beta0"):New("HasteBlock", "---", nil, HasteBlockDB.lego )
	LB.Text:ClearAllPoints();
	LB.Text:SetPoint("LEFT", LB, "RIGHT", 0, 0)
		
	local r, g, b = LB:GetBackdropColor()
	LB:SetBackdropColor(r, g, b, self.db.lego.bgAlpha)
	
	r, g, b = LB:GetBackdropBorderColor()
	LB:SetBackdropBorderColor(r, g, b, self.db.lego.borderAlpha)

	OH = DongleStub("OptionHouse-1.0")

	local OHObj = OH:RegisterAddOn("HasteBlock", "Haste Block", "Amarand", "r" .. (tonumber(string.match("$Revision$", "(%d+)")) or 1))
	OHObj:RegisterCategory(L["General"], self, "CreateUI")	
	
	self:CheckUsed()
end

function HasteBlock:CheckUsed(skipSpeed)
	usedFormats = 0
	
	if( self.db.showModified ) then usedFormats = usedFormats + 1 end
	if( self.db.showOriginal ) then usedFormats = usedFormats + 1 end
	if( self.db.showHaste ) then usedFormats = usedFormats + 1 end	
	
	if( not skipSpeed ) then
		self:SpeedChanged()
	end
end

function HasteBlock:ToggleBlock(val)
	if( not val and display ~= "" ) then
		LB:Show()
	else
		LB:Hide()
	end
end

function HasteBlock:OpacityChanged(val, lego, key)
	if( key == "bgAlpha" ) then
		local r, g, b = LB:GetBackdropColor()
		LB:SetBackdropColor(r, g, b, self.db.lego.bgAlpha)

	elseif( key == "borderAlpha" ) then
		local r, g, b = LB:GetBackdropBorderColor()
		LB:SetBackdropBorderColor(r, g, b, self.db.lego.borderAlpha)
	end
end

function HasteBlock:Set(val, ...)
	if( select("#", ...) == 1 ) then
		self.db[select(1, ...)] = val
	else
		self.db[select(1, ...)][select(2, ...)] = val
	end

	self:SpeedChanged()
end

function HasteBlock:Get(...)
	if( select("#", ...) == 1 ) then
		return self.db[select(1, ...)]
	end
	
	return self.db[select(1, ...)][select(2, ...)]
end

function HasteBlock:CreateUI()
	local config = {}
	-- Mana class (Spell Haste)
	if( UnitPowerType("player") == 0 ) then
		table.insert(config, {type = "check", text = L["Show spell haste percentage"], default = true, onSet = "CheckUsed", var = "showSpell"})
		table.insert(config, {type = "check", text = L["Show original attack speed"], default = true, onSet = "CheckUsed", var = "showOriginal"})
		table.insert(config, {type = "check", text = L["Show haste percentage"], default = true, onSet = "CheckUsed", var = "showHaste"})
		table.insert(config, {type = "check", text = L["Show mainhand attack speed"], default = true, onSet = "CheckUsed", var = "showMain"})
		
	-- Melee/Ranged (Other haste)
	else
		table.insert(config, {type = "check", text = L["Show original attack speed"], default = true, onSet = "CheckUsed", var = "showOriginal"})
		table.insert(config, {type = "check", text = L["Show haste percentage"], default = true, onSet = "CheckUsed", var = "showHaste"})
		table.insert(config, {type = "check", text = L["Show mainhand attack speed"], default = true, onSet = "CheckUsed", var = "showMain"})
		table.insert(config, {type = "check", text = L["Show offhand attack speed"], default = true, onSet = "CheckUsed", var = "showOff"})
		table.insert(config, {type = "check", text = L["Show ranged attack speed"], default = true, onSet = "CheckUsed", var = "showRanged"})
	end
	
	table.insert(config, {type = "label", color = { r = 1, g = 1, b = 1 }, text = L["LegoBlock Settings"]})
	table.insert(config, {type = "check", text = L["Always show block when no haste is active"], onSet = "SpeedChanged", default = true, var = {"lego", "alwaysShow"}})
	table.insert(config, {type = "check", text = L["Hide Haste LegoBlock"], default = false, onSet = "ToggleBlock", var = { "lego", "hidden" }})
	--table.insert(config, {type = "check", text = L["Show header text"], default = true, var = { "lego", "showText" }})
	--table.insert(config, {type = "slider", format = L["Scale: %d%%"], var = { "lego", "scale" }, default = 1.0, min = 0.0, max = 2.0})
	table.insert(config, {type = "slider", format = L["Background Opacity: %d%%"], var = { "lego", "bgAlpha" }, onSet = "OpacityChanged", default = 1.0})
	table.insert(config, {type = "slider", format = L["Border Opacity: %d%%"], var = { "lego", "borderAlpha" }, onSet = "OpacityChanged", default = 1.0})

	return DongleStub("HousingAuthority-1.0"):CreateConfiguration(config, {handler = self, set = "Set", get = "Get"})
end

function HasteBlock:ScanSpell(id)
	HasteBlock.tooltip:ClearLines()
	HasteBlock.tooltip:SetSpell(id, BOOKTYPE_SPELL)

	for i=1, HasteBlock.tooltip:NumLines() do
		local line = getglobal("HBTooltipTextLeft" ..i):GetText();
		if( line ) then
			local speed = string.match(line, "(.+)" .. L["sec cast"])
			if( speed ) then
				return tonumber(string.trim(speed))
			end
		end
	end
end

function HasteBlock:ScanItem(slot)
	self.tooltip:ClearLines()
	self.tooltip:SetInventoryItem("player", slot)

	if( self.tooltip:NumLines() == 0 ) then
		return nil
	end

	for i=1, self.tooltip:NumLines() do
		local line = getglobal("HBTooltipTextRight" .. i):GetText();
		if( line ) then
			local speed = string.match(line, WEAPON_SPEED .. "(.+)")
			if( speed ) then
				return tonumber(string.trim(speed))
			end
		end
	end

	return nil
end

function HasteBlock:CalculateHaste(id, text, speed, origSpeed)	
	-- Catch unequipped weapons
	if( not speed or not origSpeed ) then
		if( isInCombat ) then
			display = display .. text .. " ----\n"
		end

		return
	end
	
	local line
	local showSpeed
	if( self.db.showModified ) then
		showSpeed = origSpeed
	elseif( self.db.showOriginal ) then
		showSpeed = speed	
	end
		
	-- Mainhand: 1.82 (-30.0%)
	if( usedFormats == 2 and self.db.showHaste ) then
		line = string.format("%s %.2f (-%.1f%%)", text, showSpeed, (1 - speed / origSpeed) * 100)
	
	-- Mainhand: 1.82 (-30%)
	elseif( usedFormats == 2 ) then
		line = string.format("%s %.2f (-%.1f%%)", text, showSpeed, (1 - speed / origSpeed) * 100)
	
	-- Mainhand: 1.82 (2.6 -30%)
	elseif( usedFormats == 3 ) then
		line = string.format("%s %.2f (%.2f -%.1f%%)", text, speed, origSpeed, (1 - speed / origSpeed) * 100)
	
	-- Mainhand: 1.82
	elseif( self.db.showModified or self.db.showOriginal ) then
		line = string.format("%s %.2f", text, showSpeed)
	
	-- Mainhand: -30%
	else
		line = string.format("%s -%.2f%%", text, speed)
	end
	
	if( ( isInCombat or self.db.lego.alwaysShow ) or ( not isInCombat and speed ~= origSpeed ) ) then
		display = display .. line .. "\n"
	end
end

function HasteBlock:SpeedChanged()
	display = ""
	
	-- Ranged weapon
	if( self.db.showRanged ) then
		self:CalculateHaste(CR_HASTE_RANGED, L["Ranged:"], (UnitRangedDamage("player")), ranged)
	end
	
	-- Mainhand
	local main, off = UnitAttackSpeed("player")
	if( self.db.showMain ) then
		self:CalculateHaste(CR_HASTE_MELEE, L["Mainhand:"], main, mainHand)
	end
	
	-- Offhand
	if( self.db.showOff ) then
		self:CalculateHaste(CR_HASTE_MELEE, L["Offhand:"], off, offHand)
	end

	-- Spells
	if( self.db.showSpell ) then
		local spell = (1 - baseSpell / currentSpell) * 100
		
		if( ( isInCombat or self.db.lego.alwaysShow ) or ( not isInCombat and spell > 0 ) ) then
			spell = (1 - speed / origSpeed) * 100
			display = display .. string.format("%s -%.2f%%", L["Spell:"], speed) .. "\n"			
		end
	end

	if( display ~= "" and not self.db.lego.hidden ) then
		LB:SetText(string.trim(display))
		LB.Text:SetWidth(LB:GetWidth() + 5)
		LB:SetHeight(LB.Text:GetHeight() + 15)
		LB:Show()
	else
		LB:Hide()
	end
end

local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", function(self, event, arg1)
	if( event == "ADDON_LOADED" and arg1 == "HasteBlock" ) then
		HasteBlock.OnLoad(HasteBlock)
		self:UnregisterEvent("ADDON_LOADED")

	elseif( event == "UNIT_INVENTORY_CHANGED" and arg1 == "player" ) then
		local newMh = GetInventoryItemLink("player", CharacterMainHandSlot:GetID())
		local newOh = GetInventoryItemLink("player", CharacterSecondaryHandSlot:GetID())
		local newRanged = GetInventoryItemLink("player", CharacterRangedSlot:GetID())
		
		if( newMh ~= mhLink ) then
			mainHand = HasteBlock:ScanItem(CharacterMainHandSlot:GetID())
			mhLink = newMh
		end
		
		if( newOh ~= ohLink ) then
			offHand = HasteBlock:ScanItem(CharacterSecondaryHandSlot:GetID())
			ohLink = newOh
		end
		
		if( newRanged ~= rangedLink ) then
			ranged = HasteBlock:ScanItem(CharacterRangedSlot:GetID())
			rangedLink = newRanged
		end
				
		HasteBlock:SpeedChanged()

	elseif( event == "PLAYER_LOGIN" ) then
		mhLink = GetInventoryItemLink("player", CharacterMainHandSlot:GetID())
		ohLink = GetInventoryItemLink("player", CharacterSecondaryHandSlot:GetID())
		rangedLink = GetInventoryItemLink("player", CharacterRangedSlot:GetID())
		
		mainHand = HasteBlock:ScanItem(CharacterMainHandSlot:GetID())
		offHand = HasteBlock:ScanItem(CharacterSecondaryHandSlot:GetID())
		ranged = HasteBlock:ScanItem(CharacterRangedSlot:GetID())
		
		-- Scan a spell with a cast time if we're a mana user
		-- so we can figure out how much haste we gained for spells
		if( UnitPowerType("player") == 0 ) then
			local total = 0
			for i=1, GetNumSpellTabs() do
				total = total + select(4, GetSpellTabInfo(i))
			end
			
			-- Find the longest cast time
			for i=1, total do
				local speed = HasteBlock:ScanSpell(i)
				if( speed and speed > baseSpell ) then
					baseSpell = speed
					currentSpell = speed
					spellID = i
				end
			end
		end
		
		HasteBlock:SpeedChanged()

	elseif( event == "PLAYER_REGEN_DISABLED" ) then
		isInCombat = true
		HasteBlock:SpeedChanged()
		
	elseif( event == "PLAYER_REGEN_ENABLED" ) then
		isInCombat = nil
		HasteBlock:SpeedChanged()

	elseif( event == "UNIT_ATTACK_SPEED" ) then
		if( spellID ) then
			local speed = HasteBlock:ScanSpell(spellID)
			if( speed ) then
				currentSpell = speed
			end
		end

		HasteBlock:SpeedChanged()
	end
end)
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("UNIT_ATTACK_SPEED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("UNIT_INVENTORY_CHANGED")