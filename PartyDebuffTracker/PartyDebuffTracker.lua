--[[ 
	Trackery, Mayen/Amarand (Horde) from Icecrown (US) PvE
	
	The awesome part about doing Afflicted, is I can basically rip the code off for any other PvP mod I want to do.
	This is an easy example, I've basically been able to rip out 95% of Afflicteds code and it'll work fine.
]]

Trackery = LibStub("AceAddon-3.0"):NewAddon("Trackery", "AceEvent-3.0")

local L = TrackeryLocals

local instanceType
local playerName
local spellInfo = {}
local currentDebuffs = {}
local lastDebuffs = {}

function Trackery:OnInitialize()
	self.defaults = {
		profile = {
			showAnchors = false,
			inside = {["arena"] = true},
			anchors = {
				--["player"] = {enabled = true, text = "Player", displayType = "right", scale = 1.0},
				["party1"] = {enabled = true, text = L["Party #1"], displayType = "down", scale = 1.0},
				["party2"] = {enabled = true, text = L["Party #2"], displayType = "down", scale = 1.0},
				["party3"] = {enabled = true, text = L["Party #3"], displayType = "down", scale = 1.0},
				["party4"] = {enabled = true, text = L["Party #4"], displayType = "down", scale = 1.0},
			},
		},
	}

	self.db = LibStub:GetLibrary("AceDB-3.0"):New("TrackeryDB", self.defaults)

	self.revision = tonumber(string.match("$Revision: 690 $", "(%d+)") or 1)
	self.visual = self.modules.Icons:LoadVisual()
	self.spells = TrackerySpells
	
	-- Debug, something went wrong
	if( not self.visual ) then
		self:UnregisterAllEvents()
		return
	end
	
	-- Monitor for zone change
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA")

	-- Quick check
	self:ZONE_CHANGED_NEW_AREA()
end

function Trackery:OnEnable()
	local type = select(2, IsInInstance())
	if( not self.db.profile.inside[type] ) then
		return
	end
	
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("PLAYER_AURAS_CHANGED")
	
	if( not self.db.profile.silent ) then
		self:RegisterEvent("CHAT_MSG_ADDON")
	end

	playerName = UnitName("player")
end

function Trackery:OnDisable()
	self:UnregisterAllEvents()
	
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA")
end

local COMBATLOG_OBJECT_AFFILIATION_MINE = COMBATLOG_OBJECT_AFFILIATION_MINE
local eventRegistered = {["SPELL_AURA_APPLIED"] = true, ["SPELL_AURA_REMOVED"] = true}
function Trackery:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, eventType, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, ...)
	if( not eventRegistered[eventType] or bit.band(destFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) ~= COMBATLOG_OBJECT_AFFILIATION_MINE ) then
		return
	end

	-- spellName/rank -> spellID map, not the cleanest method but it works without requiring localization
	if( eventType == "SPELL_AURA_APPLIED" ) then
		local spellID, spellName, spellSchool, auraType = ...
		if( auraType == "DEBUFF" and self.spells[spellID] ) then
			local rank = select(2, GetSpellInfo(spellID))
			spellInfo[spellName .. ":" .. rank] = spellID
		end
		
	-- Debuff faded from us
	--[[
	elseif( eventType == "SPELL_AURA_REMOVED" ) then
		local spellID, spellName, spellSchool, auraType = ...
		if( auraType == "DEBUFF" and self.spells[spellID] ) then
			local rank = select(2, GetSpellInfo(spellID))
			lastTrack[spellName .. rank] = nil
			
			self:SendMessage(string.format("FADE:%s,%d,%s", destName, spellID, spellName))
		end
	]]
	end
end

-- Track debuff gain/fades for the ones we care about
function Trackery:PLAYER_AURAS_CHANGED()
	local id = 0
	while( true ) do
		id = id + 1
		local buffID = GetPlayerBuff(id, "HARMFUL")
		if( buffID == 0 ) then break end
		
		local name, rank = GetPlayerBuffName(buffID)
		local id = name .. ":" .. rank
		
		if( spellInfo[id] ) then
			local timeLeft = GetPlayerBuffTimeLeft(buffID)
			if( not lastDebuffs[id] or ( lastDebuffs[id] and timeLeft > lastDebuffs[id] ) ) then
				self:SendMessage(string.format("GAIN:%s,%s,%s,%.2f", playerName, spellInfo[id], name, timeLeft))
			end

			currentDebuffs[id] = timeLeft
		end
	end
	
	for id in pairs(lastDebuffs) do
		if( not currentDebuffs[id] ) then
			self:SendMessage(string.format("FADE:%s,%d,%s", playerName, spellInfo[id], (string.split(":", id))))
			lastDebuffs[id] = nil
		end
	end
	
	-- Copy 
	for k, v in pairs(currentDebuffs) do lastDebuffs[k] = v; currentDebuffs[k] = nil; end
end

-- Figure out the unitid so we can 
function Trackery:GetUnitID(name)
	if( UnitIsUnit(name, "party1") ) then
		return "party1"
	elseif( UnitIsUnit(name, "party2") ) then
		return "party2"
	elseif( UnitIsUnit(name, "party3") ) then
		return "party3"
	elseif( UnitIsUnit(name, "party4") ) then
		return "party4"
	end
	
	return ""
end

-- Actual things happened!
function Trackery:AuraGained(name, spellID, spellName, timeLeft)
	spellID = tonumber(spellID)
	timeLeft = tonumber(timeLeft)
	
	-- Make sure it's a valid sync
	if( not spellID or not timeLeft or not UnitInParty(name) ) then
		return
	end
	
	local unitID = self:GetUnitID(name)
	local guid = UnitGUID(unitID)
	
	-- Invalid sync, no GUID found for this unitid
	if( not guid or not self.db.profile.anchors[unitID]  ) then
		return
	end
		
	local icon = select(3, GetSpellInfo(spellID))
	self.visual:CreateTimer(unitID, spellID, spellName, icon, timeLeft, guid)
end

function Trackery:AuraFaded(name, spellID, spellName)
	spellID = tonumber(spellID)
	

	-- Make sure it's a valid sync
	if( not spellID or not UnitInParty(name) ) then
		return
	end

	local unitID = self:GetUnitID(name)
	local guid = UnitGUID(unitID)
	
	-- Invalid sync, no GUID found for this unitid
	if( not guid ) then
		return
	end
	
	self.visual:RemoveTimer(unitID, spellID, guid)
end

-- Handle syncs
function Trackery:CHAT_MSG_ADDON(event, prefix, msg, type, author)
	if( type ~= "PARTY" or prefix ~= "TRCKY" --[[or author == playerName]] ) then
		return
	end
	
	local dataType, data = string.match(msg, "([^:]+)%:(.+)")
	if( dataType == "GAIN" ) then
		Trackery:AuraGained(string.split(",", data))
	elseif( dataType == "FADE" ) then
		Trackery:AuraFaded(string.split(",", data))
	end
end

-- See if we should enable Trackery in this zone
function Trackery:ZONE_CHANGED_NEW_AREA()
	local type = select(2, IsInInstance())

	if( type ~= instanceType ) then
		-- Clear timers because we changed zones
		for key in pairs(self.db.profile.anchors) do
			self.visual:ClearTimers(key)
		end
		
		-- Check if it's supposed to be enabled in this zone
		if( self.db.profile.inside[type] ) then
			self:OnEnable()
		else
			self:OnDisable()
		end
	end
		
	instanceType = type
end

function Trackery:Reload()
	self:OnDisable()

	-- Check to see if we should enable it
	local type = select(2, IsInInstance())
	if( self.db.profile.inside[type] ) then
		self:OnEnable()
	end
	
	self.visual:ReloadVisual()
end

function Trackery:SendMessage(msg)
	SendAddonMessage("TRCKY", msg, "PARTY")
end

function Trackery:Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99PDT|r: " .. msg)
end