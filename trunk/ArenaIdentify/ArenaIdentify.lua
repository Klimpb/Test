--[[ 
	Arena Identify, Mayen (Horde) from Icecrown (US) PvE
]]

ArenaIdentify = LibStub("AceAddon-3.0"):NewAddon("ArenaIdentify", "AceEvent-3.0")

local L = ArenaIdentLocals
local instanceType
local scanTable = {}
local alreadyLoaded = {}
local alreadyFound = {}

function ArenaIdentify:OnInitialize()
	-- Defaults
	self.defaults = {
		profile = {
		}
	}

	self.db = LibStub:GetLibrary("AceDB-3.0"):New("ArenaIdentifyDB", self.defaults)
	self.revision = tonumber(string.match("$Revision: 628 $", "(%d+)")) or 1
	
	if( not ArenaIdentifyData ) then
		ArenaIdentifyData = {}
	end
end

function ArenaIdentify:OnEnable()
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA")
	
	self:ZONE_CHANGED_NEW_AREA()
end

function ArenaIdentify:OnDisable()
	self:UnregisterAllEvents()
end

function ArenaIdentify:ScanUnits()
	if( not self.tooltip ) then
		self.tooltip = CreateFrame("GameTooltip", "ArenaIdentifyTooltip", UIParent, "GameTooltipTemplate")
		self.tooltip:SetOwner(UIParent, "ANCHOR_NONE")
	end
		
	for _, data in pairs(scanTable) do
		if( not alreadyFound[data.guid] and instanceType == "arena" ) then
			self.tooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
			self.tooltip:SetHyperlink(string.format("unit:%s", data.guid))
			
			local name, unitid = self.tooltip:GetUnit()
			self.tooltip:Hide()
			
			if( name and not UnitInParty(name) ) then
				alreadyFound[data.guid] = true
				
				-- Send the data to ourself since we auto-ignore syncs from ourselves now
				SSAF:AddEnemy(data.name, data.server, data.race, data.classToken, nil, data.powerType, unitid, data.guid)

				-- Sync it with other SSAF users
				local msg = string.format("ENEMY:%s,%s,%s,%s,%s,%s,%s,%s", data.name, data.server, data.race, data.classToken, "", data.powerType, "", data.guid)
				SendAddonMessage("SSAF", msg, "BATTLEGROUND")
			end
		end
	end
end

-- Get enemy/team mate races
function ArenaIdentify:PLAYER_TARGET_CHANGED()
	self:ScanUnit("target")
end

function ArenaIdentify:UPDATE_MOUSEOVER_UNIT()
	self:ScanUnit("mouseover")
end

function ArenaIdentify:PLAYER_FOCUS_CHANGED()
	self:ScanUnit("focus")
end

function ArenaIdentify:ScanUnit(unit)
	if( UnitIsPlayer(unit) and UnitIsEnemy("player", unit) and not UnitIsCharmed(unit) and not UnitIsCharmed("player") and not GetPlayerBuffTexture(L["Arena Preparation"]) ) then
		local name, server = UnitName(unit)
		local _, classToken = UnitClass(unit)
		local powerType = UnitPowerType(unit) or 0
		local race = UnitRace(unit)
		
		ArenaIdentifyData[UnitGUID(unit)] = string.format("%d:%s:%s:%s:%s:%s", time(), name, server or "", race, classToken, powerType)
	end
end

-- Check if match has started
local timeElapsed = 0
function ArenaIdentify:CHAT_MSG_BG_SYSTEM_NEUTRAL(event, msg)
	if( msg == L["The Arena battle has begun!"] ) then
		if( not self.frame ) then
			self.frame = CreateFrame("Frame")
			self.frame:Hide()
			self.frame:SetScript("OnUpdate", function(self, elapsed)
				timeElapsed = timeElapsed + elapsed
				
				if( timeElapsed >= 2 ) then
					if( InCombatLockdown() ) then
						self:Hide()
						return
					end
					
					ArenaIdentify:ScanUnits()
					timeElapsed = 0
				end
			end)
		end
		
		timeElapsed = 2
		self.frame:Show()
	end
end

local function sortSeen(a, b)
	return a.time > b.time
end

-- Are we inside an arena?
function ArenaIdentify:ZONE_CHANGED_NEW_AREA()
	local type = select(2, IsInInstance())

	-- Inside an arena, but wasn't already
	if( type == "arena" and type ~= instanceType --[[and select(2, IsActiveBattlefieldArena())]] ) then
		self:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
		self:RegisterEvent("PLAYER_FOCUS_CHANGED")
		self:RegisterEvent("PLAYER_TARGET_CHANGED")
		self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
		
		-- Load it into a table so we can sort it
		for guid, data in pairs(ArenaIdentifyData) do
			if( not alreadyLoaded[guid] ) then
				alreadyLoaded[guid] = true

				local time, name, server, race, classToken, powerType = string.split(":", data)
				table.insert(scanTable, {guid = guid, time = tonumber(time) or 9999999999999, name = name, server = server, race = race, classToken = classToken, powerType = tonumber(powerType) or 0})
			end
		end
		
		table.sort(scanTable, sortSeen)
		

	-- Was in an arena, but left it
	elseif( type ~= "arena" and instanceType == "arena" ) then
		self:UnregisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
		self:UnregisterEvent("PLAYER_FOCUS_CHANGED")
		self:UnregisterEvent("PLAYER_TARGET_CHANGED")
		self:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")
		
		for k, v in pairs(alreadyFound) do alreadyFound[k] = nil end
		
		if( self.frame ) then
			self.frame:Hide()
		end
	end
	
	instanceType = type
end