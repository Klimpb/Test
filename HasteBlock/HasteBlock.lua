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
		showRanged = false,
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
end

function HasteBlock:Get(var)
	return self.db[var]
end

function HasteBlock:CreateUI()
	local config = {
		{	type = "check",
			text = L["Show original attack speed"],
			default = true,
			var = "showOringal",
		},
		{	type = "check",
			text = L["Show haste percentage"],
			default = true,
			var = "showHaste",
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
		local line = getglobal("HBTooltipTextRight" .. i);
		if( line ) then
			line = line:GetText()
			local speed = string.match(WEAPON_SPEED, WEAPON_SPEED .. "(.+)")
			if( speed ) then
				return string.trim(speed)
			end
		end
	end
	
	return nil
end

function HasteBlock:CalculateHaste(id, text, speed, origSpeed)
	-- Spell Haste: 20.5%
	if( not speed ) then
		display = display .. text .. string.format("%.2f", GetCombatRatingBonus(id)) .. "\n"
	
	-- Main Hand: 1.82 (2.6 -30%)
	elseif( self.db.showOriginal and self.db.showHaste ) then
		display = display .. text .. string.format("%.2f (%.2f -%.2f-)", speed, origSpeed, GetCombatRatingBonus(id)) .. "\n"
	
	-- Main Hand: 1.82 (-30%)
	elseif( self.db.showHaste ) then
		display = display .. text .. string.format("%.2f (-%.2f%)", speed, GetCombatRatingBonus(id)) .. "\n"
	
	-- Main Hand: 1.82 (2.6)
	elseif( self.db.showOriginal ) then
		display = display .. text .. string.format("%.2f (%.2f)", speed, origSpeed) .. "\n"
	end
end

function HasteBlock:SpeedChanged()
	display = ""
	if( self.db.showRanged ) then
		self:CalculateHaste(CR_HASTE_RANGED, L["Ranged Speed:"], (UnitRangedDamage("player")), ranged)
	end
	
	local main, off = UnitAttackSpeed("player")
	if( self.db.showMain and mainHand ) then
		self:CalculateHaste(CR_HASTE_MELEE, L["Main Speed:"], main, mainHand)
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

local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", function(self, event, addon)
	if( event == "ADDON_LOADED" and addon == "HasteBlock" ) then
		HasteBlock.OnLoad(HasteBlock)
		self:UnregisterEvent("ADDON_LOADED")
	elseif( event == "" ) then
		mainHand = HasteBlock.ScanItem(HasteBlock, CharacterMainHandSlot:GetID())
		offHand = HasteBlock.ScanItem(HasteBlock, CharacterSecondaryHandSlot:GetID())
		ranged = HasteBlock.ScanItem(HasteBlock, CharacterRangedSlot:GetID())		
	elseif( event ~= "ADDON_LOADED" ) then
		HasteBlock.SpeedChanged(HasteBlock)
	end
end)
frame:RegisterEvent("UNIT_ATTACK_SPEED")
frame:RegisterEvent("ADDON_LOADED")