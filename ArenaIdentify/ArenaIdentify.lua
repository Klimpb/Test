--[[ 
	Arena Identify, Mayen (Horde) from Icecrown (US) PvE
]]

ArenaIdentify = LibStub("AceAddon-3.0"):NewAddon("ArenaIdentify", "AceEvent-3.0")

local L = ArenaIdentLocals
local instanceType
local scanTable = {}
local alreadyLoaded = {}

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
	if( UnitIsPlayer(unit) and UnitIsVisible(unit) ) then
		ArenaIdentifyData[UnitGUID(unit)] = time()
	end
end

local function sortSeen(a, b)
	return a.time < b.time
end

-- Are we inside an arena?
function ArenaIdentify:ZONE_CHANGED_NEW_AREA()
	local type = select(2, IsInInstance())

	-- Inside an arena, but wasn't already
	if( type == "arena" and type ~= instanceType and select(2, IsActiveBattlefieldArena()) ) then
		self:RegisterEvent("PLAYER_FOCUS_CHANGED")
		self:RegisterEvent("PLAYER_TARGET_CHANGED")
		self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
		
		-- Load it into a table so we can sort it
		for k, v in pairs(ArenaIdentifyData) do
			if( not alreadyLoaded[k] ) then
				table.insert(scanTable, {guid = guid, time = time})
				alreadyLoaded[k] = true
			end
		end
		
		table.sort(scanTable, sortSeen)

	-- Was in an arena, but left it
	elseif( type ~= "arena" and instanceType == "arena" ) then
		self:UnregisterEvent("PLAYER_FOCUS_CHANGED")
		self:UnregisterEvent("PLAYER_TARGET_CHANGED")
		self:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")
	end
	
	instanceType = type
end