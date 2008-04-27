--[[ 
	Arena Identify, Mayen/Amarand (Horde) from Icecrown (US) PvE
]]

ArenaIdentify = LibStub("AceAddon-3.0"):NewAddon("ArenaIdentify", "AceEvent-3.0")

local L = ArenaIdentLocals
local instanceType, bracket
local scanTable = {}
local alreadyLoaded = {}
local alreadyFound = {}
local alreadySaved = {}

function ArenaIdentify:OnInitialize()
	-- Defaults
	self.defaults = {
		profile = {
			cutOff = 0,
		}
	}

	self.db = LibStub:GetLibrary("AceDB-3.0"):New("ArenaIdentifyDB", self.defaults)
	self.revision = tonumber(string.match("$Revision: 628 $", "(%d+)")) or 1
	
	-- Upgrade data
	if( ArenaIdentifyData and not ArenaIdentifyData[2] and not ArenaIdentifyData[3] and not ArenaIdentifyData[5] ) then
		ArenaIdentifyData = nil
	end

	if( not ArenaIdentifyData ) then
		ArenaIdentifyData = {[2] = {}, [3] = {}, [5] = {}}
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

function ArenaIdentify:Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99ArenaIdentify|r: " .. msg)
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
				
				-- Send the data to the AF mod directly since addon messages are ignored
				if( SSAF ) then
					SSAF:AddEnemy(data.name, data.server, data.race, data.classToken, nil, data.powerType, unitid, data.guid)
				elseif( Proximo ) then
					Proximo:AddToList(data.name, data.server, data.classToken, data.race, data.sex, 100, 100, "")						
				end
				
				-- SSAF is smart enough to catch Proximo syncs, so it's not a big deal to just send them using Proximo format
				-- and let SSAF sort it out for people
				local msg = string.format("ReceiveSync:%s,%s,%s,%s,%s,%s,%s,%s", data.name, data.server, data.classToken, data.race or "", data.sex or "", "100", "100", "")
				SendAddonMessage("Proximo", msg, "PARTY")
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
	local guid = UnitGUID(unit)
	if( not alreadySaved[guid] and UnitIsPlayer(unit) and UnitIsEnemy("player", unit) and not UnitIsCharmed(unit) and not UnitIsCharmed("player") and not GetPlayerBuffTexture(L["Arena Preparation"]) ) then
		local name, server = UnitName(unit)
		local _, classToken = UnitClass(unit)
		local powerType = UnitPowerType(unit) or 0
		local race = UnitRace(unit)
		local sex = UnitSex(unit)
		
		ArenaIdentifyData[bracket][guid] = string.format("%d:%s:%s:%s:%s:%s:%s", time(), name, server or "", race, classToken, powerType, sex)
		alreadySaved[guid] = true
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
	if( type == "arena" and type ~= instanceType and select(2, IsActiveBattlefieldArena()) ) then
		self:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
		self:RegisterEvent("PLAYER_FOCUS_CHANGED")
		self:RegisterEvent("PLAYER_TARGET_CHANGED")
		self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
		
		-- Set our prune threshold
		local pruneTime
		if( self.db.profile.cutOff > 0 ) then
			pruneTime = time() - ((60 * 60 * 24) * self.db.profile.cutOff)
		end
		
		-- Figure out the arena bracket
		bracket = 2
		for i=1, MAX_BATTLEFIELD_QUEUES do
			local status, _, _, _, _, teamSize = GetBattlefieldStatus(i)
			if( status == "active" and teamSize > 0 ) then
				bracket = teamSize
				break
			end
		end
		
		-- Load it into a table so we can sort it
		for guid, data in pairs(ArenaIdentifyData[bracket]) do
			if( not alreadyLoaded[guid] ) then
				alreadyLoaded[guid] = true

				local time, name, server, race, classToken, powerType, sex = string.split(":", data)
				time = tonumber(time) or 99999999999999
				
				if( not pruneTime or pruneTime <= time ) then
					table.insert(scanTable, {guid = guid, time = time, name = name, server = server, race = race, classToken = classToken, sex = tonumber(sex), powerType = tonumber(powerType) or 0})
				else
					ArenaIdentifyData[bracket][guid] = nil
				end
			end
		end
		
		table.sort(scanTable, sortSeen)
		

	-- Was in an arena, but left it
	elseif( type ~= "arena" and instanceType == "arena" ) then
		self:UnregisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
		self:UnregisterEvent("PLAYER_FOCUS_CHANGED")
		self:UnregisterEvent("PLAYER_TARGET_CHANGED")
		self:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")
		
		for k in pairs(alreadyFound) do alreadyFound[k] = nil end
		for k in pairs(alreadySaved) do alreadySaved[k] = nil end
		
		if( self.frame ) then
			self.frame:Hide()
		end
	end
	
	instanceType = type
end


SLASH_ARENAIDENTIFY1 = "/arenaidentify"
SLASH_ARENAIDENTIFY2 = "/ai"
SlashCmdList["ARENAIDENTIFY"] = function(msg)
	cmd, arg = string.split(" ", string.trim(msg or ""))
	if( not cmd and not arg ) then
		cmd = msg
	end
	
	cmd = string.lower(cmd)
	arg = arg or ""
	
	if( cmd == "prune" ) then
		arg = tonumber(arg)
		
		ArenaIdentify.db.profile.cutOff = arg
		ArenaIdentify:Print(string.format(L["Only saving people who you have seen within the last %d days now."], arg))
	else
		DEFAULT_CHAT_FRAME:AddMessage(L["/ai prune <days> - Set how many days players should be saved before being removed, use 0 to disable."])
	end
end