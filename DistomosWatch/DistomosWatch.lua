--[[ 
	Distomos Watch, Mayen/Amarand (Horde) from Icecrown (US) PvE
]]

DistWatch = LibStub("AceAddon-3.0"):NewAddon("DistWatch", "AceEvent-3.0")

local L = DistWatchLocals
local GTBLib, GTBGroup, instanceType

local playerGUID
local unitMap = {}
local unitTable = {}

-- Spell info
local POM_SPELLID = {[41635] = true, [48110] = true, [48111] = true, [48112] = true, [33076] = true, [48113] = true, [33110] = true}
local SPELL_NAME = GetSpellInfo(41635)
local SPELL_DURATION = 30
local BOUNCE_TIMEOUT = 1.5

-- Tracking who "owns" the POM
local mendOwners = {}
local ownerTimeout = {}
local originalOwner = {}

function DistWatch:OnInitialize()
	self.defaults = {
		profile = {
			showAnchor = false,
			showOthers = true,
			gradient = true,
			growUp = false,
			
			scale = 1.0,
			width = 180,
			maxRows = 30,
			fontSize = 12,
			fadeTime = 1.5,
			
			color = { r = 0, g = 1, b = 0 },
			ourColor = { r = 0, g = 0, b = 1 },
			
			redirectTo = "",
			icon = "LEFT",
			fontName = "Friz Quadrata TT",
			texture = "BantoBar",

			inside = {["raid"] = true, ["party"] = true, ["arena"] = true, ["pvp"] = true},
		},
	}

	-- Initialize the DB
	self.db = LibStub:GetLibrary("AceDB-3.0"):New("DistWatchDB", self.defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "Reload")
	self.db.RegisterCallback(self, "OnProfileCopied", "Reload")
	self.db.RegisterCallback(self, "OnProfileReset", "Reload")

	self.revision = tonumber(string.match("$Revision: 811 $", "(%d+)") or 1)
	
	-- Annnd so we can grab texture things
	SML = LibStub:GetLibrary("LibSharedMedia-3.0")
	SML.RegisterCallback(self, "LibSharedMedia_Registered", "TextureRegistered")
	
	self:Reload()

	playerGUID = UnitGUID("player")

	-- Monitor for zone change
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")

	-- Setup our unit table so we don't have to do that many concats
	for i=1, MAX_RAID_MEMBERS do
		table.insert(unitTable, string.format("raid%d", i))
	end
	
	for i=1, MAX_PARTY_MEMBERS do
		table.insert(unitTable, string.format("party%d", i))
	end
end

function DistWatch:StartTimer(destGUID, destName, spellID)
	-- Check who owns the POM
	local type = "color"
	--[[
	if( mendOwners[destGUID] == playerGUID ) then
		type = "ourColor"
	end
	]]

	-- Show owner of the PoM if it isn't us
	local text
	if( self.db.profile.showOthers and mendOwners[destGUID] and mendOwners[destGUID] ~= playerGUID and unitMap[mendOwners[destGUID]] ) then
		local name = UnitName(unitMap[mendOwners[destGUID]])
		if( name ) then
			text = string.format("%s - %s (%s)", destName, name, self:GetStack(unitMap[destGUID]))
		else
			text = string.format("%s (%d)", destName, self:GetStack(unitMap[destGUID]))
		end
	else
		text = string.format("%s (%d)", destName, self:GetStack(unitMap[destGUID]))
	end

	GTBGroup:RegisterBar(string.format("dw%s", destGUID), text, SPELL_DURATION, nil, nil, self.db.profile[type].r, self.db.profile[type].g, self.db.profile[type].b)
end

-- Check for POM
local COMBATLOG_OBJECT_TYPE_PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER
--local test = {}
local eventRegistered = {["SPELL_CAST_SUCCESS"] = true, ["SPELL_HEAL"] = true, ["SPELL_AURA_APPLIED"] = true, ["SPELL_AURA_REMOVED"] = true, ["UNIT_DIED"] = true}
function DistWatch:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, eventType, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellID, spellName, spellSchool, auraType)
	if( not eventRegistered[eventType] and bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) == COMBATLOG_OBJECT_TYPE_PLAYER ) then
		return
	end
	
	-- New POM casted, associate that the one on destGUID is by sourceGUID
	if( eventType == "SPELL_CAST_SUCCESS" and POM_SPELLID[spellID] ) then
		table.insert(originalOwner, sourceGUID)
		table.insert(ownerTimeout, GetTime() + BOUNCE_TIMEOUT)

		--test[sourceGUID] = sourceName
		mendOwners[destGUID] = sourceGUID
		self:StartTimer(destGUID, destName, spellID)
		--ChatFrame1:AddMessage(string.format("[%s] casted on [%s]", sourceName, destName))
		
	-- POM Triggered, get ready for a bounce
	elseif( eventType == "SPELL_HEAL" and POM_SPELLID[spellID] ) then
		local type = "color"
		--[[
		if( mendOwners[destGUID] == playerGUID ) then
			type = "ourColor"
		end
		]]
		GTBGroup:RegisterBar(string.format("dw%s", destGUID), string.format("%s - %s", destName, auraType), 0, nil, nil, self.db.profile[type].r, self.db.profile[type].g, self.db.profile[type].b)
		
		-- Trying to use a table to solve multiple POMs bouncing at once.
		-- For example, Priest A and Priest B both cast a PoM on a different person, some sort of raid wide
		-- AE damage happens like Naj'entus, Priest A's heals first then Priest B's, but this is before the new one
		-- is applied, so in THEORY we know A's bounce will be applied before B's.
		if( mendOwners[destGUID] ) then
			table.insert(originalOwner, mendOwners[destGUID])
			table.insert(ownerTimeout, GetTime() + BOUNCE_TIMEOUT)
			--ChatFrame1:AddMessage(string.format("POM on [%s] bounced, owned by [%s]", destName, test[mendOwners[destGUID] or ""] or ""))
			mendOwners[destGUID] = nil
		end
	
	-- POM Gained 
	elseif( eventType == "SPELL_AURA_APPLIED" and auraType == "BUFF" and unitMap[destGUID] and POM_SPELLID[spellID] ) then
		--- Find the last known bounce, that hasn't timed out yet
		local timeout, original
		while( true ) do
			timeout = table.remove(ownerTimeout, 1)
			original = table.remove(originalOwner, 1)
			--ChatFrame1:AddMessage(string.format("[%s] [%s] [%s]", timeout or "", original or "", GetTime()))
			if( not timeout or not original or GetTime() <= timeout ) then break end
		end
		
		--if( timeout ) then
		--	ChatFrame1:AddMessage(string.format("[%s] [%s] [%s]", timeout, GetTime(), GetTime() - (timeout - BOUNCE_TIMEOUT)))
		--end
		
		--[[
		if( timeout ) then
			ChatFrame1:AddMessage(string.format("[%s] [%s] [%s] [%s]", timeout, GetTime(), timeout - GetTime(), original or "", test[original or ""] or ""))
		else
			ChatFrame1:AddMessage(string.format("[%s] gained unknown pom", destName))
		end
		]]
		
		if( timeout and original ) then
			mendOwners[destGUID] = original
		end

		self:StartTimer(destGUID, destName, spellID)
	
	-- POM Faded
	elseif( eventType == "SPELL_AURA_REMOVED" and auraType == "BUFF" and unitMap[destGUID] and POM_SPELLID[spellID] ) then
		GTBGroup:UnregisterBar(string.format("dw%s", destGUID))
		
	-- Unit died
	elseif( eventType == "UNIT_DIED" ) then
		mendOwners[destGUID] = nil
		
		for i=#(originalOwner), 1, -1 do
			if( originalOwner[i] == destGUID ) then
				table.remove(originalOwner, i)
				table.remove(ownerTimeout, i)
			end
		end
		
		GTBGroup:UnregisterBar(string.format("dw%s", destGUID))
	end
end

-- Get stack size
function DistWatch:GetStack(unit)
	if( not unit ) then return 5 end
	
	local i = 1
	while( true ) do
		local name, rank, _, stack, duration, timeLeft = UnitBuff(unit, i)
		if( not name ) then break end
		i = i + 1
		
		if( name == SPELL_NAME ) then
			return stack
		end
	end
	
	return 5
end

-- Update party/raid list
function DistWatch:UPDATE_ROSTER()
	if( not playerGUID ) then
		return
	end
	
	for k in pairs(unitMap) do unitMap[k] = nil end
	
	unitMap[playerGUID] = "player"
	for _, unit in pairs(unitTable) do
		local guid = UnitGUID(unit)
		if( guid ) then
			unitMap[UnitGUID(unit)] = unit
		end
	end
end


function DistWatch:PLAYER_ENTERING_WORLD()
	playerGUID = UnitGUID("player")

	self:UPDATE_ROSTER()
	self:ZONE_CHANGED_NEW_AREA()
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end

-- Check if we should enable it
function DistWatch:ZONE_CHANGED_NEW_AREA()
	local type = select(2, IsInInstance())
	
	if( type ~= instanceType ) then
		playerGUID = UnitGUID("player")

		if( self.db.profile.inside[type] ) then
			self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
			self:RegisterEvent("PARTY_MEMBERS_CHANGED", "UPDATE_ROSTER")
			self:RegisterEvent("RAID_ROSTER_UPDATE", "UPDATE_ROSTER")
			self:UPDATE_ROSTER()
		else
			self:UnregisterAllEvents()
			self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
			self:RegisterEvent("PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA")
		end
	end
		
	instanceType = type
end

-- If we want a texture that was registered later after we loaded, reload the bars so it uses the correct one
function DistWatch:TextureRegistered(event, mediaType, key)
	if( mediaType == SML.MediaType.STATUSBAR or mediaType == SML.MediaType.FONT ) then
		if( key == self.db.profile.fontName or key == self.db.profile.texture ) then
			self:Reload()
		end
	end
end

function DistWatch:OnBarMove(parent, x, y)
	if( not DistWatch.db.profile.position ) then
		DistWatch.db.profile.position = {}
	end

	DistWatch.db.profile.position.x = x
	DistWatch.db.profile.position.y = y
end

function DistWatch:Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Distomos Watch|r: " .. msg)
end

function DistWatch:Reload()
	instanceType = nil
	self:ZONE_CHANGED_NEW_AREA()
	
	-- Load GTB
	if( not GTBLib and not GTBGroup ) then
		GTBLib = LibStub:GetLibrary("GTB-1.0")
		GTBGroup = GTBLib:RegisterGroup("Distomos Watch", SML:Fetch(SML.MediaType.STATUSBAR, self.db.profile.texture))
		GTBGroup:RegisterOnMove(self, "OnBarMove")
	end
	
	GTBGroup:SetScale(self.db.profile.scale)
	GTBGroup:SetWidth(self.db.profile.width)
	GTBGroup:SetDisplayGroup(self.db.profile.redirectTo ~= "" and self.db.profile.redirectTo or nil)
	GTBGroup:SetAnchorVisible(self.db.profile.showAnchor)
	GTBGroup:EnableGradient(self.db.profile.gradient)
	GTBGroup:SetBarGrowth(self.db.profile.growUp and "UP" or "DOWN")
	GTBGroup:SetMaxBars(self.db.profile.maxRows)
	GTBGroup:SetFont(SML:Fetch(SML.MediaType.FONT, self.db.profile.fontName), self.db.profile.fontSize)
	GTBGroup:SetTexture(SML:Fetch(SML.MediaType.STATUSBAR, self.db.profile.texture))
	GTBGroup:SetFadeTime(self.db.profile.fadeTime)
	
	if( self.db.profile.background ) then
		GTBGroup:SetBackgroundColor(self.db.profile.background.r, self.db.profile.background.g, self.db.profile.background.b)
	end
	
	if( self.db.profile.position ) then
		GTBGroup:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", self.db.profile.position.x, self.db.profile.position.y)
	end
end

function DistWatch:Test()
	GTBGroup:RegisterBar("dw1", string.format("%s - Distomos (4)", UnitName("player")), SPELL_DURATION, nil, nil, self.db.profile.color.r, self.db.profile.color.g, self.db.profile.color.b)
	GTBGroup:RegisterBar("dw2", string.format("%s (5)", UnitName("player")), SPELL_DURATION, nil, nil, self.db.profile.color.r, self.db.profile.color.g, self.db.profile.color.b)
end

function DistWatch:Clear()
	GTBGroup:UnregisterAllBars()
end