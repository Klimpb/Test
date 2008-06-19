--[[ 
	Bloomy Mayen (Horde) from Icecrown (US) PvE
]]

Bloomy = LibStub("AceAddon-3.0"):NewAddon("Bloomy", "AceEvent-3.0")

local L = BloomyLocals
local activeMacros, activeSpells, activeUnits = {}, {}, {}
local partyMap, raidMap = {}, {}
local unitBuffs = {}

local totalTracked = 0
local instanceType

function Bloomy:OnInitialize()
	-- Defaults
	self.defaults = {
		profile = {
			scale = 1.0,
			
			inside = {["raid"] = true}
		}
	}
	-- Init DB
	self.db = LibStub:GetLibrary("AceDB-3.0"):New("BloomyDB", self.defaults)
	self.revision = tonumber(string.match("$Revision: 628 $", "(%d+)")) or 1
	
	-- Macro stuffs
	if( not BloomyMacros ) then
		BloomyMacros = {}
	end
	
	self.data = BloomyMacros

	-- Store a mapping of unitids so we don't have to do a lot of concats
	for i=1, MAX_RAID_MEMBERS do
		raidMap[i] = string.format("raid%d", i)
	end
	
	for i=1, MAX_PARTY_MEMBERS do
		partyMap[i] = string.format("party%d", i)
	end

	unitBuffs["player"] = {}
	activeUnits["player"] = true
end

function Bloomy:OnEnable()
	-- Monitor for zone change
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA")

	-- Store the macro info initially
	self:RegisterEvent("ADDON_LOADED")
	self:UpdateMacros()
end

-- Lets us know to update the macro cache
function Bloomy:ADDON_LOADED(event, addon)
	if( IsAddOnLoaded("Blizzard_MacroUI") ) then
		MacroFrame:HookScript("OnHide", function()
			Bloomy:UpdateMacros()
		end)
				
		self:UnregisterEvent("ADDON_LOADED")
	end
end

-- See if we should enable it in this zone
function Bloomy:ZONE_CHANGED_NEW_AREA(event)
	local type = select(2, IsInInstance())

	if( type ~= instanceType ) then
		if( self.db.profile.inside[type] ) then
			self:CreateFrame()
			self:UpdateFrame()
			self:UpdateMacros()
			self.frame:Show()
		
		elseif( self.frame ) then
			self.frame:Hide()
		end
	end
		
	instanceType = type
end

-- BUFF TRACKING
function Bloomy:UNIT_AURA(event, unit)
	if( activeUnits[unit] ) then
		for k in pairs(unitBuffs[unit]) do unitBuffs[unit][k] = nil end
		local updated
		
		for i=1, 40 do
			local name, rank, _, stack, duration, timeLeft = UnitBuff(unit, i)
			if( not name ) then break end
			
			if( timeLeft and activeSpells[name] and activeSpells[name][unit] ) then
				unitBuffs[unit][name] = GetTime() + timeLeft
			end
		end
	end
end

-- MACRO SCANNING/STUFF
-- Checks the lines without needing a new table
function Bloomy:CheckMacro(...)
	if( select("#", ...) == 0 ) then
		return nil
	end
	
	for i=1, select("#", ...) do
		local key, id, spells = string.split(" ", select(i, ...), 3)
		if( key == "#bloomy" and id and spells ) then
			return id, spells
		end
	end
	
	return nil
end

function Bloomy:AddSpells(id, ...)
	if( select("#", ...) == 0 ) then
		return
	end
	
	activeMacros[id].spell = string.trim(select(1, ...))
	
	for i=1, select("#", ...) do
		activeMacros[id].spells[string.trim((select(i, ...)))] = true
	end
end


function Bloomy:ScanMacros()
	for _, data in pairs(activeMacros) do data.enabled = nil end
	
	local maxMacros = (MAX_MACROS or 18) * 2
	local globalNum, charNum = GetNumMacros()
	
	for i=1, maxMacros do
		local name, icon, text = GetMacroInfo(i)
		if( text and text ~= "" ) then
			local bloomyID, spells = self:CheckMacro(string.split("\n", text))
			if( bloomyID and spells ) then
				if( not activeMacros[i] ) then
					activeMacros[i] = {spells = {}}
				end
				
				activeMacros[i].enabled = true
				activeMacros[i].id = bloomyID
				activeMacros[i].perChar = i > 18	
				activeMacros[i].name = name
				activeMacros[i].icon = icon
				activeMacros[i].spellText = spells
				
				self:AddSpells(i, string.split(",", spells))
			end
		end
	end
end

function Bloomy:GetUnit(list)
	if( not list ) then
		return nil
	end
	
	for _, name in pairs(list) do
		if( UnitIsUnit(name, "player") ) then
			return "player"
		end
		
		for i=1, GetNumRaidMembers() do
			if( UnitName(raidMap[i]) == name ) then
				return raidMap[i]
			end
		end

		for i=1, GetNumPartyMembers() do
			if( UnitName(partyMap[i]) == name ) then
				return partyMap[i]
			end
		end
	end
	
	return nil
end

function Bloomy:UpdateMacros()
	self:ScanMacros()
	
	for k in pairs(activeUnits) do activeUnits[k] = nil end
	for _, guids in pairs(activeSpells) do for k in pairs(guids) do guids[k] = nil end end
	
	for id, macro in pairs(activeMacros) do
		if( macro.enabled ) then
			local text = string.format("#bloomy %s %s", macro.id, macro.spellText)
			
			local target = self:GetUnit(self.data[macro.id])
			if( target ) then
				text = string.format("%s\n#showtooltip %s\n/cast [target=%s] %s", text, macro.spell, target, macro.spell)
				macro.target = target
				
				activeUnits[target] = true
				unitBuffs[target] = unitBuffs[target] or {}
				
				for spellName in pairs(macro.spells) do
					if( not activeSpells[spellName] ) then totalTracked = totalTracked + 1 end
					
					activeSpells[spellName] = activeSpells[spellName] or {}
					activeSpells[spellName][target] = macro.id
				end
			else
				macro.target = nil
			end

			EditMacro(id, macro.name, macro.icon, text, true, macro.perChar)
		end
	end
end

function Bloomy:Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Bloomy|r: " .. msg)
end

SLASH_BLOOMY1 = "/bloomy"
SlashCmdList["BLOOMY"] = function(msg)
	local cmd, id, name = string.split(" ", msg or "")
	cmd = string.lower(cmd or "")
	
	local self = Bloomy
	if( cmd == "add" and id and name ) then
		if( not self.data[id] ) then
			self.data[id] = {}
		end
		
		table.insert(self.data[id], name)
		self:UpdateMacros()
		self:UpdateFrame()
		self:Print(string.format(L["Added \"%s\" to Bloomy ID \"%s\""], name, id))
	
	elseif( cmd == "remove" and id and name ) then
		if( not self.data[id] ) then
			Bloomy:Print(string.format(L["Cannot remove \"%s\" from id \"%s\", no Bloomy macro exists with that ID yet."], name, id))
			return
		end
		
		for i=#(self.data[id]), 1, -1 do
			table.remove(self.data[id], i)
		end
		
		self:UpdateMacros()
		self:UpdateFrame()
		self:Print(string.format(L["Removed \"%s\" from Bloomy ID \"%s\""], name, id))
	
	elseif( cmd == "reset" ) then
		for _, info in pairs(self.data) do
			for k in pairs(info) do
				info[k] = nil
			end
		end
		
		self:UpdateMacros()
		self:UpdateFrame()
		self:Print(L["Reset all Bloomy macros."])
	
	elseif( cmd == "toggle" ) then
		self:UpdateMacros()
		self:CreateFrame()
		self:UpdateFrame()
		
		if( self.frame:IsVisible() ) then
			self.frame:Hide()
		elseif( self.frame.rows[1].unit ) then
			self.frame:Show()
		end
	
	elseif( cmd == "help" ) then
		DEFAULT_CHAT_FRAME:AddMessage(L["In order for a macro to be recognized by Bloomy, it has to have an identifier in it."])
		DEFAULT_CHAT_FRAME:AddMessage(L["Add #bloomy <id> <spell name> to the macro and it'll automatically be edited with the person to cast the passed spell on."])
	else
		
		DEFAULT_CHAT_FRAME:AddMessage(L["Bloomy slash commands"])
		DEFAULT_CHAT_FRAME:AddMessage(L["/bloomy toggle - Toggles the Bloomy timer frame"])
		DEFAULT_CHAT_FRAME:AddMessage(L["/bloomy add <id> <name> - Adds a group member to the passed id which will have the duration of the HoT left shown in the action button."])
		DEFAULT_CHAT_FRAME:AddMessage(L["/bloomy remove <id> <name> - Removes the given group member from the passed id and hots will no longer be shown for them in the action button."])
		DEFAULT_CHAT_FRAME:AddMessage(L["/bloomy reset - Removed all assigned group members from Bloomy macros."])
		DEFAULT_CHAT_FRAME:AddMessage(L["/bloomy help - Shows information on how to create a Bloomy macro."])
	end
end

-- Timer updating
local colors = {
	[(GetSpellInfo(774))] = "|cffbc64aa", -- Regrowth
	[(GetSpellInfo(8936))] = "|cff00ff10", -- Rejuv
	[(GetSpellInfo(33763))] = "|cff50fe37", -- LB
}

function Bloomy:GetTimeText(unit)
	local text = ""
	local i = 0
	local time = GetTime()
	for name, endTime in pairs(unitBuffs[unit]) do
		local timeLeft = endTime - time
		
		if( timeLeft > 0 ) then
			if( i > 0 ) then
				text = text .. string.format(", %s%.1f|r", colors[name], timeLeft)
			else
				text = string.format("%s%.1f|r", colors[name], timeLeft)
			end

			i = i + 1
		end
	end
	
	return text ~= "" and text or "---"
end

local timeElapsed = 0
local function OnUpdate(self, elapsed)
	timeElapsed = timeElapsed + elapsed
	
	if( timeElapsed >= 0.20 ) then
		for _, row in pairs(Bloomy.frame.rows) do
			if( row.unit ) then
				row.timeLeft:SetText(Bloomy:GetTimeText(row.unit))
			end
		end
	end
end

local function OnShow(self)
	local position = Bloomy.db.profile.position
	if( position ) then
		local scale = self:GetEffectiveScale()
		self:ClearAllPoints()
		self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", position.x / scale, position.y / scale)
	else
		self:ClearAllPoints()
		self:SetPoint("CENTER", UIParent, "CENTER")
	end
	
	-- Register so we can start to get aura events
	Bloomy:RegisterEvent("UNIT_AURA")
end

local function OnHide(self)
	Bloomy:UnregisterEvent("UNIT_AURA")
end

local function OnDragStart(self)
	if( IsAltKeyDown() ) then
		self.isMoving = true
		self:StartMoving()
	end
end

local function OnDragStop(self)
	if( self.isMoving ) then
		self.isMoving = nil
		self:StopMovingOrSizing()

		if( not Bloomy.db.profile.position ) then
			Bloomy.db.profile.position = {}
		end

		local scale = self:GetEffectiveScale()
		Bloomy.db.profile.position.x = self:GetLeft() * scale
		Bloomy.db.profile.position.y = self:GetTop() * scale
	end
end

-- VISUALS
local backdrop = {bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeSize = 0.80,
		insets = {left = 1, right = 1, top = 1, bottom = 1}}

function Bloomy:CreateFrame()
	if( self.frame ) then
		return
	end
	
	local frame = CreateFrame("Frame", nil, UIParent)
	frame:SetWidth(150)
	frame:SetHeight(39)
	frame:SetScale(self.db.profile.scale)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:SetClampedToScreen(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetBackdrop(backdrop)
	frame:SetBackdropColor(0, 0, 0, 1.0)
	frame:SetBackdropBorderColor(0.75, 0.75, 0.75, 1.0)
	frame:SetFrameStrata("HIGH")
	frame:SetToplevel(true)
	frame:Hide()
	
	frame:SetScript("OnUpdate", OnUpdate)
	frame:SetScript("OnShow", OnShow)
	frame:SetScript("OnDragStart", OnDragStart)
	frame:SetScript("OnDragStop", OnDragStop)
	
	frame.rows = {}
	
	-- Create rows
	local path, size, outline = GameFontHighlightSmall:GetFont()
	size = 11
	
	for i=1, 10 do
		local name = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		name:SetWidth(70)
		name:SetHeight(10)
		name:SetJustifyH("LEFT")
		name:SetFont(path, size, outline)
		name:Hide()
		
		local timeLeft = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		timeLeft:SetHeight(10)
		timeLeft:SetFont(path, size, outline)
		timeLeft:Hide()
		
		if( i > 1 ) then
			name:SetPoint("TOPLEFT", frame.rows[i - 1].name, "BOTTOMLEFT", 0, -2)
			timeLeft:SetPoint("TOPLEFT", frame.rows[i - 1].timeLeft, "BOTTOMLEFT", 0, -2)
		else
			name:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
			timeLeft:SetPoint("TOPLEFT", frame, "TOPLEFT", 75, -2)
		end
		
		frame.rows[i] = {}
		frame.rows[i].name = name
		frame.rows[i].timeLeft = timeLeft
	end
	
	self.frame = frame
end

function Bloomy:UpdateFrame()
	if( not self.frame ) then
		return
	end
	
	for _, row in pairs(self.frame.rows) do
		row.unit = nil
		row.timeLeft:Hide()
		row.name:Hide()
	end
	
	
	local id = 0
	for unit in pairs(activeUnits) do
		id = id + 1
		
		local row = self.frame.rows[id]

		local colors = RAID_CLASS_COLORS[select(2, UnitClass(unit))]
		row.name:SetText(UnitName(unit))
		row.name:SetTextColor(colors.r, colors.g, colors.b)
		row.name:Show()
		
		row.timeLeft:SetText(self:GetTimeText(unit))
		row.timeLeft:Show()
		
		row.unit = unit
		
		if( id >= 10 ) then
			break
		end
	end
	
	if( id == 0 ) then
		self.frame:Hide()
		return
	end
	
	self.frame:SetWidth(100 + ((totalTracked - 1) * 28))
	self.frame:SetHeight((12 * id) + 3)
end
