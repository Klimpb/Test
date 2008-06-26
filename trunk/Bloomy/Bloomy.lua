--[[ 
	Bloomy Mayen (Horde) from Icecrown (US) PvE
]]

Bloomy = LibStub("AceAddon-3.0"):NewAddon("Bloomy", "AceEvent-3.0")

local L = BloomyLocals
local bloomyMacros, activeSpells, activeTracks, spellList = {}, {}, {}, {}, {}
local partyMap, raidMap = {}, {}
local unitBuffs = {}
local usedNames = {}

local totalTracked = 0
local instanceType, updateQueued

function Bloomy:OnInitialize()
	-- Defaults
	self.defaults = {
		profile = {
			scale = 1.0,
			showName = true,
			useUnits = false,
			
			inside = {["raid"] = true},
			macros = {},
		}
	}
	-- Init DB
	self.db = LibStub:GetLibrary("AceDB-3.0"):New("BloomyDB", self.defaults)
	self.revision = tonumber(string.match("$Revision: 628 $", "(%d+)")) or 1

	-- Store a mapping of unitids so we don't have to do a lot of concats
	for i=1, MAX_RAID_MEMBERS do
		raidMap[i] = string.format("raid%d", i)
	end
	
	for i=1, MAX_PARTY_MEMBERS do
		partyMap[i] = string.format("party%d", i)
	end
	
	-- Disable this mod, not a Druid
	if( select(2, UnitClass("player")) ~= "DRUID" ) then
		Bloomy.disabled = true
		self:UnregisterAllEvents()
	end
end

function Bloomy:OnEnable()
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("RAID_ROSTER_UPDATE")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	
	-- Store the macro info initially
	self:RegisterEvent("ADDON_LOADED")

	self:ScanMacros()
	self:UpdateMacros()
end

function Bloomy:RAID_ROSTER_UPDATE()
	-- No longer exists, so delete them
	for name in pairs(activeTracks) do
		if( not UnitExists(name) ) then
			activeTracks[name] = nil
			self:UpdateMacros()
		end
	end
end

-- Check if we need to update everything
function Bloomy:PLAYER_REGEN_ENABLED()
	if( updateQueued ) then
		updateQueued = nil
		self:UpdateMacros()
	end
end

-- Lets us know to update the macro cache
function Bloomy:ADDON_LOADED(event, addon)
	if( IsAddOnLoaded("Blizzard_MacroUI") ) then
		MacroFrame:HookScript("OnHide", function()
			Bloomy:ScanMacros()
			Bloomy:UpdateMacros()
			
			if( self.frame ) then
				self:UpdateFrame()
			end
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
			
			if( self.frame.rows[1].target ) then
				self.frame:Show()
			end
		
		elseif( self.frame ) then
			self.frame:Hide()
		end
	end
		
	instanceType = type
end

-- BUFF TRACKING
function Bloomy:UNIT_AURA(event, unit)
	-- Don't let this be used on pets for sanity reasons basically
	if( not UnitIsPlayer(unit) ) then
		return
	end
	
	local playerName = UnitName(unit)
	if( activeTracks[playerName] ) then
		-- Reset them, really we could do something fancy and see what faded specifically
		-- but we really don't need that, and it's more complicated then just doing this
		for k in pairs(unitBuffs[playerName]) do unitBuffs[playerName][k] = nil end
		
		for i=1, 40 do
			local name, rank, _, stack, duration, timeLeft = UnitBuff(unit, i)
			if( not name ) then break end
			
			-- It's one of ours, and we're actively tracking it
			if( timeLeft and activeSpells[name] and activeSpells[name][playerName] ) then
				unitBuffs[playerName][name] = GetTime() + timeLeft
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
		local key, id, spells = string.split(" ", (select(i, ...)), 3)
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
	
	bloomyMacros[id].spell = string.trim(select(1, ...))
	for i=1, select("#", ...) do
		bloomyMacros[id].spells[string.trim((select(i, ...)))] = true
	end
end

-- Find new macros
function Bloomy:ScanMacros()
	for _, data in pairs(bloomyMacros) do data.enabled = nil; for k in pairs(data.spells) do data.spells[k] = nil end; end

	for i=1, 36 do
		local name, icon, text = GetMacroInfo(i)
		if( text and text ~= "" ) then
			local id, spells = self:CheckMacro(string.split("\n", text))
			if( id and spells ) then
				if( not bloomyMacros[id] ) then
					bloomyMacros[id] = {spells = {}}
				end
				
				bloomyMacros[id].enabled = true
				bloomyMacros[id].macroID = i
				bloomyMacros[id].id = id
				bloomyMacros[id].name = name
				bloomyMacros[id].icon = icon
				bloomyMacros[id].spellText = spells
				
				self:AddSpells(id, string.split(",", spells))
			end
		end
	end
end

-- Find a valid person to use
function Bloomy:GetUnit(list)
	if( not list ) then
		return nil
	end
	
	for _, name in pairs(list) do
		if( name == "player" ) then
			return UnitName(name)
		elseif( UnitExists(name) ) then
			return name
		end
	end
	
	return nil
end

-- Update all the table stuff
function Bloomy:UpdateMacros()
	if( InCombatLockdown() ) then
		updateQueued = true
		return
	end

	-- Reset fun stuff
	for _, guids in pairs(activeSpells) do for k in pairs(guids) do guids[k] = nil end end
	for k in pairs(activeTracks) do activeTracks[k] = nil end
	for k in pairs(spellList) do spellList[k] = nil end
	
	totalTracked = 0
	
	-- Find the macro ids
	local scanned = {}
	for _, macro in pairs(bloomyMacros) do
		if( macro.enabled ) then
			macro.target = self:GetUnit(self.db.profile.macros[macro.id])
			
			if( macro.target ) then
				-- Setup tables
				activeTracks[macro.target] = UnitName(macro.target)
				unitBuffs[macro.target] = unitBuffs[macro.target] or {}
				
				-- Set spells as actively being used
				for spellName in pairs(macro.spells) do
					if( not spellList[spellName] ) then totalTracked = totalTracked + 1 end
					
					activeSpells[spellName] = activeSpells[spellName] or {}
					activeSpells[spellName][macro.target] = macro.id
					
					spellList[spellName] = true
				end
			end
		end
	end

	-- Actually update all the macros
	self:WriteMacros()
	self:UpdateFrame()
end

-- Write all the macros
-- This isn't the cleanest solution sadly, but the previous method was causing odd issues with the wrong Bloomy macro
-- being written so moving to this until I can actually fix it
function Bloomy:WriteMacros()
	for i=1, 36 do
		local name, icon, text = GetMacroInfo(i)
		if( text and text ~= "" ) then
			local id, spells = self:CheckMacro(string.split("\n", text))
			if( id and spells and bloomyMacros[id] ) then
				local text = string.format("#bloomy %s %s", id, spells)
				local macro = bloomyMacros[id]
				
				if( macro.target ) then
					text = string.format("%s\n#showtooltip %s\n/cast [target=%s] %s", text, macro.spell, macro.target, macro.spell)
				end
				
				-- Set macro name
				local name = " "
				if( self.db.profile.showName and macro.target ) then
					name = UnitName(macro.target)
				elseif( not self.db.profile.showName ) then
					name = macro.name
				end

				EditMacro(i, name == "" and " " or name, macro.icon, text)
			end
		end
	end
end

function Bloomy:Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Bloomy|r: " .. msg)
end

-- Timer updating
local colors = {
	[(GetSpellInfo(8936))] = "|cffaaaaff", -- Regrowth
	[(GetSpellInfo(774))] = "|cffbc64aa", -- Rejuv
	[(GetSpellInfo(33763))] = "|cff50fe37", -- LB
}

function Bloomy:GetTimeText(target)
	local text = ""
	local i = 0
	local time = GetTime()
	for name, endTime in pairs(unitBuffs[target]) do
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
	
	if( timeElapsed >= 0.10 ) then
		for _, row in pairs(Bloomy.frame.rows) do
			if( row.target ) then
				row.timeLeft:SetText(Bloomy:GetTimeText(row.target))
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


local function sortMacros(a, b)
	return a < b
end

local temp = {}
function Bloomy:UpdateFrame()
	if( not self.frame ) then
		return
	end
	
	-- Hide everything
	for _, row in pairs(self.frame.rows) do
		row.unit = nil
		row.timeLeft:Hide()
		row.name:Hide()
	end
	
	-- Sort table thing
	for i=#(temp), 1, -1 do table.remove(temp, i) end
	
	for _, macro in pairs(bloomyMacros) do
		if( macro.enabled and macro.target ) then
			table.insert(temp, macro.id)
		end
	end
	
	-- Nothing to show, so hide
	if( #(temp) == 0 ) then
		self.frame:Hide()
		return
	end
	
	table.sort(temp, sortMacros)
	
	-- Update the display now
	local total = 0
	for i, id in pairs(temp) do
		total = total + 1
		
		local macroData = bloomyMacros[id]
		local row = self.frame.rows[total]

		local colors = RAID_CLASS_COLORS[select(2, UnitClass(macroData.target))]
		row.name:SetText(UnitName(macroData.target))
		row.name:SetTextColor(colors.r, colors.g, colors.b)
		row.name:Show()

		row.timeLeft:SetText(self:GetTimeText(macroData.target))
		row.timeLeft:Show()

		row.target = macroData.target

		if( i >= 10 ) then
			break
		end
	end
	
	self.frame:SetWidth(110 + ((totalTracked - 1) * 28))
	self.frame:SetHeight((12 * #(temp)) + 3)
end

-- Configuration changed
function Bloomy:Reload()
	if( self.frame ) then
		self.frame:SetScale(self.db.profile.scale)
		OnShow(self.frame)
	end
	
	-- Show frame if needed
	instanceType = nil
	self:ZONE_CHANGED_NEW_AREA()
end
