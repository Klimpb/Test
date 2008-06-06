PartyCC = LibStub("AceAddon-3.0"):NewAddon("PartyCC", "AceEvent-3.0")

local L = PartyCCLocals

local SML, instanceType, playerName, playerGUID, GTBLib, GTBGroup
local timerList = {}

function PartyCC:OnInitialize()
	self.defaults = {
		profile = {
			scale = 1.0,
			width = 180,
			redirectTo = "",
			texture = "BantoBar",
			showAnchor = false,
			showName = false,
			silent = false,

			spellList = {},
			
			inside = {["pvp"] = true, ["arena"] = true}
		},
	}

	self.db = LibStub:GetLibrary("AceDB-3.0"):New("PartyCCDB", self.defaults)

	self.revision = tonumber(string.match("$Revision: 678 $", "(%d+)") or 1)
	self.spells = PartyCCSpells

	SML = LibStub:GetLibrary("LibSharedMedia-3.0")
	SML.RegisterCallback(self, "LibSharedMedia_Registered", "TextureRegistered")

	GTBLib = LibStub:GetLibrary("GTB-1.0")
	GTBGroup = GTBLib:RegisterGroup("Party CC Tracker", SML:Fetch(SML.MediaType.STATUSBAR, self.db.profile.texture))
	GTBGroup:RegisterOnMove(self, "OnBarMove")
	GTBGroup:SetScale(self.db.profile.scale)
	GTBGroup:SetWidth(self.db.profile.width)
	GTBGroup:SetDisplayGroup(self.db.profile.redirectTo ~= "" and self.db.profile.redirectTo or nil)
	GTBGroup:SetAnchorVisible(self.db.profile.showAnchor)

	if( self.db.profile.position ) then
		GTBGroup:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", self.db.profile.position.x, self.db.profile.position.y)
	end
	
	self.GTB = GTBLib
	self.GTBGroup = GTBGroup
	
	-- Set the enabled list
	for name in pairs(self.spells) do
		if( self.db.profile.spellList[name] == nil ) then
			self.db.profile.spellList[name] = true
		end
	end
	
	-- Monitor for zone change
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA")

	-- Quick check
	self:ZONE_CHANGED_NEW_AREA()

end

function PartyCC:OnEnable()
	local type = select(2, IsInInstance())
	if( not self.db.profile.inside[type] ) then
		return
	end
	
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
	self:RegisterEvent("PLAYER_FOCUS_CHANGED")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("UNIT_AURA")

	if( not self.db.profile.silent ) then
		self:RegisterEvent("CHAT_MSG_ADDON")
	end

	playerName = UnitName("player")
	playerGUID = UnitGUID("player")
end

-- Combat log data
local COMBATLOG_OBJECT_REACTION_HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE
local COMBATLOG_OBJECT_AFFILIATION_MINE = COMBATLOG_OBJECT_AFFILIATION_MINE
local eventRegistered = {["SPELL_AURA_REMOVED"] = true}
function PartyCC:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, eventType, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, ...)
	if( not eventRegistered[eventType] ) then
		return
	end
	
	-- Debuff faded from an enemy
	if( eventType == "SPELL_AURA_REMOVED" and bit.band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE ) then
		local spellID, spellName, spellSchool, auraType = ...
		if( auraType == "DEBUFF" and self.spells[spellName] ) then
			self:TimerFaded(spellID, spellName, destName, destGUID)
		end
	end
end

function PartyCC:TimerFound(spellName, spellRank, destName, destGUID, timeLeft)
	spellRank = spellRank or ""
	
	local id = string.format("%s:%s:%s:%s", destName, destGUID, spellName, spellRank)
	if( timerList[id] ) then
		return

	end
	

	timerList[id] = true
	self:SendMessage(string.format("GAIN:%s,%s,%s,%s,%s,%.2f", self.spells[spellName], destName, destGUID, spellName, spellRank, timeLeft))
end

function PartyCC:TimerFaded(spellID, spellName, destName, destGUID)
	local spellRank = select(2, GetSpellInfo(spellID))
	spellRank = spellRank or ""

	local id = string.format("%s:%s:%s:%s", destName, destGUID, spellName, spellRank)
	if( not timerList[id] ) then
		return
	end
	
	self:SendMessage(string.format("FADE:%s,%s,%s,%s", destName, destGUID, spellName, spellRank))
	timerList[id] = nil
end

-- Scan for timers we started
function PartyCC:UNIT_AURA(event, unit)
	self:ScanUnit(unit)
end

function PartyCC:PLAYER_TARGET_CHANGED()
	self:ScanUnit("target")
end

function PartyCC:PLAYER_FOCUS_CHANGED()
	self:ScanUnit("focus")
end

function PartyCC:UPDATE_MOUSEOVER_UNIT()
	self:ScanUnit("mouseover")
end

function PartyCC:ScanUnit(unit)
	local destName = UnitName(unit)
	local destGUID = UnitGUID(unit)
	
	local id = 0
	while( true ) do
		id = id + 1
		local name, rank, texture, _, _, startSeconds, timeLeft = UnitDebuff(unit, id)
		if( not name ) then break end
		
		if( startSeconds and timeLeft and self.spells[name] ) then
			self:TimerFound(name, rank, destName, destGUID, timeLeft)
		end
	end
end

-- Handle syncs + timers
function PartyCC:CHAT_MSG_ADDON(event, prefix, msg, type, author)
	if( type ~= "PARTY" or prefix ~= "PCCT" or author == playerName ) then
		return
	end
		
	local dataType, data = string.match(msg, "([^:]+)%:(.+)")
	if( dataType == "GAIN" ) then
		self:AuraGained(string.split(",", data))
	elseif( dataType == "FADE" ) then
		self:AuraFaded(string.split(",", data))
	end
end

function PartyCC:AuraGained(icon, name, guid, spellName, spellRank, timeLeft)
	timeLeft = tonumber(timeLeft)

	-- Make sure it's a valid sync
	if( not name or not spellName or not timeLeft or self.db.profile.spellList[spellName] == false ) then
		return
	end
	
	local text = name
	if( not self.db.profile.showName ) then
		text = string.format("%s - %s", name, spellName)
	end
	
	GTBGroup:RegisterBar(string.format("%s:%s:%s", guid, spellName, spellRank), text, timeLeft, nil, icon)

	
	-- Add it to the spell list so it can be disabled/enabled if it's a spell we don't have yet
	if( self.db.profile.spellList[spellName] == nil ) then
		self.db.profile.spellList[spellName] = true
	end
end

function PartyCC:AuraFaded(name, guid, spellName, spellRank)
	if( not guid or not spellName or not spellRank ) then
		return
	end
	
	GTBGroup:UnregisterBar(string.format("%s:%s:%s", guid, spellName, spellRank))
end

-- See if we should enable Afflicted in this zone
function PartyCC:ZONE_CHANGED_NEW_AREA()
	local type = select(2, IsInInstance())

	if( type ~= instanceType ) then
		-- Check if it's supposed to be enabled in this zone
		if( self.db.profile.inside[type] ) then
			self:OnEnable()
		else
			self:OnDisable()
		end
	end
		
	instanceType = type
end

function PartyCC:StripServer(text)
	local name, server = string.match(text, "(.-)%-(.*)$")
	if( not name and not server ) then
		return text
	end
	
	return name
end

function PartyCC:SendMessage(msg)
	SendAddonMessage("PCCT", msg, "PARTY")
end

function PartyCC:Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99PartyCC|r: " .. msg)
end

function PartyCC:OnDisable()
	self:UnregisterAllEvents()
	
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA")
end

function PartyCC:Reload()
	self:OnDisable()

	-- Check to see if we should enable it
	local type = select(2, IsInInstance())
	if( self.db.profile.inside[type] ) then
		self:OnEnable()
	end

	GTBGroup:SetScale(self.db.profile.scale)
	GTBGroup:SetWidth(self.db.profile.width)
	GTBGroup:SetDisplayGroup(self.db.profile.redirectTo ~= "" and self.db.profile.redirectTo or nil)
	GTBGroup:SetAnchorVisible(self.db.profile.showAnchor)
end

function PartyCC:OnBarMove(parent, x, y)
	if( not PartyCC.db.profile.position ) then
		PartyCC.db.profile.position = {}
	end
	
	PartyCC.db.profile.position.x = x
	PartyCC.db.profile.position.y = y
end

function PartyCC:TextureRegistered(event, mediaType, key)
	if( mediaType == SML.MediaType.STATUSBAR and PartyCC.db.profile.texture == key ) then
		GTBGroup:SetTexture(SML:Fetch(SML.MediaType.STATUSBAR, self.db.profile.texture))
	end
end