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

function HasteBlock:OnLoad()
	self.tooltip = CreateFrame("GameTooltip", "HBTooltip", UIParent, "GameTooltipTemplate")
	self.tooltip:SetOwner(this, "ANCHOR_NONE")
	
	if( not HasteBlockDB ) then HasteBlockDB = { lego = {} } end
	
	self.defaults = {
		showRanged = true,
		showMain = true,
		showOff = true,
		showSpell = true,
		showOriginal = true,
		showHaste = true,
		lego = {
			bgAlpha = 1.0,
			borderAlpha = 1.0,
			showText = true,
			hidden = false,
		}
	}
	
	local meta = {__index=function(t, k) return self.defaults[k] end}

	self.db = setmetatable(HasteBlockDB, meta)
	self.db.lego = setmetatable(HasteBlockDB.lego, meta)

	LB = DongleStub("LegoBlock-Beta0"):New("HasteBlock", "----", nil, HasteBlockDB.lego )
	
	local r, g, b = LB:GetBackdropColor()
	LB:SetBackdropColor(r, g, b, self.db.lego.bgAlpha)
	
	r, g, b = LB:GetBackdropBorderColor()
	LB:SetBackdropBorderColor(r, g, b, self.db.lego.borderAlpha)

	OH = DongleStub("OptionHouse-1.0")

	local OHObj = OH:RegisterAddOn("HasteBlock", "Haste Block", "Amarand", "r" .. (tonumber(string.match("$Revision$", "(%d+)")) or 1))
	OHObj:RegisterCategory(L["General"], self, "CreateUI")	
end

function HasteBlock:ToggleBlock(val)
	if( val ) then
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
		table.insert(config, {type = "check", text = L["Show spell haste percentage"], default = true, var = "showSpell"})
		table.insert(config, {type = "check", text = L["Show original attack speed"], default = true, var = "showOriginal"})
		table.insert(config, {type = "check", text = L["Show haste percentage"], default = true, var = "showHaste"})
		table.insert(config, {type = "check", text = L["Show mainhand attack speed"], default = true, var = "showMain"})
		
	-- Melee/Ranged (Other haste)
	else
		table.insert(config, {type = "check", text = L["Show original attack speed"], default = true, var = "showOriginal"})
		table.insert(config, {type = "check", text = L["Show haste percentage"], default = true, var = "showHaste"})
		table.insert(config, {type = "check", text = L["Show mainhand attack speed"], default = true, var = "showMain"})
		table.insert(config, {type = "check", text = L["Show offhand attack speed"], default = true, var = "showOff"})
		table.insert(config, {type = "check", text = L["Show ranged attack speed"], default = true, var = "showRanged"})
	end
	
	table.insert(config, {type = "label", color = { r = 1, g = 1, b = 1 }, text = L["LegoBlock Settings"]})
	table.insert(config, {type = "check", text = L["Show Haste LegoBlock"], default = true, onSet = "ToggleBlock", var = { "lego", "hidden" }})
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
	-- Spell Haste: 20.5%
	if( id == CR_HASTE_SPELL ) then
		local speed = (1 - speed / origSpeed) * 100)
		if( speed > 0.0 ) then
			display = display .. text .. string.format(" %.2f%%", speed) .. "\n"
		end
		
	-- Main Hand: 1.82 (2.6 -30%)
	elseif( self.db.showOriginal and self.db.showHaste and origSpeed ~= speed ) then
		display = display .. text .. string.format(" %.2f (%.2f -%.0f%%)", speed, origSpeed, (1 - speed / origSpeed) * 100) .. "\n"
	-- Main Hand: 1.82 (-30%)
	elseif( self.db.showHaste and origSpeed ~= speed ) then
		display = display .. text .. string.format(" %.2f (-%.0f%%)", speed, (1 - speed / origSpeed) * 100) .. "\n"
	
	-- Main Hand: 1.82 (2.6)
	elseif( self.db.showOriginal and origSpeed ~= speed ) then
		display = display .. text .. string.format(" %.2f (%.2f)", speed, origSpeed) .. "\n"
	else
		display = display .. text .. string.format(" %.2f", speed) .. "\n"
	end
end

function HasteBlock:SpeedChanged()
	display = ""
	
	-- Ranged weapon
	if( self.db.showRanged and ranged  ) then
		self:CalculateHaste(CR_HASTE_RANGED, L["Ranged:"], (UnitRangedDamage("player")), ranged)
	end
	
	-- Mainhand
	local main, off = UnitAttackSpeed("player")
	if( self.db.showMain and mainHand ) then
		self:CalculateHaste(CR_HASTE_MELEE, L["Mainhand:"], main, mainHand)
	end
	
	-- Offhand
	if( self.db.showOff and offHand ) then
		self:CalculateHaste(CR_HASTE_MELEE, L["Offhand:"], off, offHand)
	end

	-- Spells
	if( self.db.showSpell and baseSpell ) then
		self:CalculateHaste(CR_HASTE_SPELL, L["Spell:"], baseSpell, currentSpell)
	end

	if( display ~= "" ) then
		LB:SetText(string.trim(display))
		LB.Text:SetWidth(LB:GetWidth())
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
			
			-- Find the longest casting spell to make sure we
			-- can actually get the correct haste info
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

	elseif( event == "PLAYER_LOGOUT" ) then
		HasteBlockDB = HasteBlock.db

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
frame:RegisterEvent("PLAYER_LOGOUT")
frame:RegisterEvent("UNIT_ATTACK_SPEED")
frame:RegisterEvent("UNIT_INVENTORY_CHANGED")