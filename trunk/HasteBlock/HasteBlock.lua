HasteBlock = {}

local LB
local OH

local L = HasteBlockLocals
local display = ""

local mainHand
local offHand
local ranged

function HasteBlock:OnLoad()
	self.tooltip = CreateFrame("GameTooltip", "HBTooltip", UIParent, "GameTooltipTemplate")
	self.tooltip:SetOwner(this, "ANCHOR_NONE")

	if( not HasteBlockDB ) then HasteBlockDB = {} end
	
	self.defaults = {
		showRanged = true,
		showMain = true,
		showOff = true,
		showSpell = true,
		showOriginal = true,
		showHaste = true,
	}
	self.db = setmetatable(HasteBlockDB, {__index=function(t,k) return self.defaults[k] end})
	
	LB = DongleStub("LegoBlock-Beta0"):New("HasteBlock", "----" )
	OH = DongleStub("OptionHouse-1.0")

	local OHObj = OH:RegisterAddOn("HasteBlock", "Haste Block", "Amarand", "r" .. (tonumber(string.match("$Revision$", "(%d+)")) or 1))
	OHObj:RegisterCategory(L["General"], self, "CreateUI")	
end

function HasteBlock:Set(var, val)
	self.db[var] = val
        self:SpeedChanged()
end

function HasteBlock:Get(var)
	return self.db[var]
end

function HasteBlock:CreateUI()
	local config = {
		{	type = "check",
			text = L["Show original attack speed"],
			default = true,
			var = "showOriginal",
		},
		{	type = "check",
			text = L["Show haste percentage"],
			default = true,
			var = "showHaste",
		},
		{	type = "check",
			text = L["Show mainhand attack speed"],
			default = true,
			var = "showMain",
		},
		{	type = "check",
			text = L["Show offhand attack speed"],
			default = true,
			var = "showOff",
		},
		{	type = "check",
			text = L["Show ranged attack speed"],
			default = true,
			var = "showRanged",
		},
		{	type = "check",
			text = L["Show spell haste percentage"],
			default = true,
			var = "showSpell",
		},
	}

	return DongleStub("HousingAuthority-1.0"):CreateConfiguration(config, {handler = self, set = "Set", get = "Get"})
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
	if( not speed ) then
		local bonus = GetCombatRatingBonus(id)
                if( bonus ~= 0 ) then
                        display = display .. text .. string.format("%.2f", bonus) .. "\n"
                end
	-- Main Hand: 1.82 (2.6 -30%)
	elseif( self.db.showOriginal and self.db.showHaste and origSpeed ~= speed ) then
		display = display .. text .. string.format("%.2f (%.2f -%.0f%%)", speed, origSpeed, (1-speed/origSpeed)*100) .. "\n"
	-- Main Hand: 1.82 (-30%)
	elseif( self.db.showHaste and origSpeed ~= speed ) then
		display = display .. text .. string.format("%.2f (-%.0f%%)", speed, (1-speed/origSpeed)*100) .. "\n"
	-- Main Hand: 1.82 (2.6)
	elseif( self.db.showOriginal and origSpeed ~= speed ) then
		display = display .. text .. string.format("%.2f (%.2f)", speed, origSpeed) .. "\n"
        else
		display = display .. text .. string.format("%.2f", speed) .. "\n"
	end
end

function HasteBlock:SpeedChanged()
	display = ""
	if( self.db.showRanged ) then
		self:CalculateHaste(CR_HASTE_RANGED, L["Ranged Speed:"], (UnitRangedDamage("player")), ranged)
	end

	local main, off = UnitAttackSpeed("player")
	if( self.db.showMain and mainHand ) then
		self:CalculateHaste(CR_HASTE_MELEE, L["Mainhand Speed:"], main, mainHand)
	end

	if( self.db.showOff and offHand ) then
		self:CalculateHaste(CR_HASTE_MELEE, L["Offhand Speed:"], off, offHand)
	end
	
	if( self.db.showSpell ) then
		self:CalculateHaste(CR_HASTE_SPELL, L["Spell Haste:"])
	end
	
	if( display ~= "" ) then
		LB:SetText(string.trim(display))
		LB.Text:SetWidth(LB:GetWidth())
		LB:Show()
	else
		LB:Hide()
	end
end

local mhID = CharacterMainHandSlot:GetID()
local ohID = CharacterSecondaryHandSlot:GetID()
local rangedID = CharacterRangedSlot:GetID()
local mhlink, ohlink, rangedlink

local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", function(self, event, arg1)
        if( event == "ADDON_LOADED" and arg1 == "HasteBlock" ) then
                HasteBlock.OnLoad(HasteBlock)
                self:UnregisterEvent("ADDON_LOADED")

        elseif( event == "UNIT_INVENTORY_CHANGED" and arg1 == "player" ) then
                local newmh, newoh, newranged = GetInventoryItemLink("player", mhID), GetInventoryItemLink("player", ohID), GetInventoryItemLink("player", rangedID)
                if newmh ~= mhlink then
                        mainHand = HasteBlock:ScanItem(mhID)
                        mhlink = newmh
                end
                if newoh ~= ohlink then
                        offHand = HasteBlock:ScanItem(ohID)
                        ohlink = newoh
                end
                if newranged ~= rangedlink then
                        ranged = HasteBlock:ScanItem(rangedID)
                        rangedlink = newranged
                end
                HasteBlock:SpeedChanged()

        elseif( event == "PLAYER_LOGIN" ) then
                mhlink, ohlink, rangedlink = GetInventoryItemLink("player", mhID), GetInventoryItemLink("player", ohID), GetInventoryItemLink("player", rangedID)
                mainHand = HasteBlock:ScanItem(mhID)
                offHand = HasteBlock:ScanItem(ohID)
                ranged = HasteBlock:ScanItem(rangedID)
                HasteBlock:SpeedChanged()

        elseif( event == "UNIT_ATTACK_SPEED" ) then
                HasteBlock:SpeedChanged()
        end
end)
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("UNIT_ATTACK_SPEED")
frame:RegisterEvent("UNIT_INVENTORY_CHANGED")