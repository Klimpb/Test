--[[ 
	Distomos Watch, Mayen/Amarand (Horde) from Icecrown (US) PvE
]]

DistWatch = LibStub("AceAddon-3.0"):NewAddon("DistWatch", "AceEvent-3.0")

local L = DistWatchLocals
local GTBLib, GTBGroup, instanceType

local SPELL_NAME = GetSpellInfo(41635)
local selfOwned = {}

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
	
	-- Setup bar group
	self:Reload()

	-- Monitor for zone change
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", function()
		DistWatch:UnregisterEvent("PLAYER_ENTERING_WORLD")
		DistWatch:ZONE_CHANGED_NEW_AREA()
	end)
end

function DistWatch:UNIT_AURA(event, unit)
	if( not UnitIsFriend("player", unit) or not UnitIsPlayer(unit) ) then
		return
	end
	
	local buffID = 1
	while( true ) do
		local name, rank, texture, count, debuffType, duration, endTime, isMine, isStealable = UnitBuff(unit, buffID)
		if( not name ) then break end
		if( name == SPELL_NAME ) then
			local guid = UnitGUID(unit)
			selfOwned[guid] = isMine
			
			self:StartTimer(guid, UnitName(unit), count, duration, endTime, isMine)
			break
		end
		
		buffID = buffID + 1
	end
end

function DistWatch:StartTimer(destGUID, destName, stack, duration, endTime, isMine)
	-- Only show our own PoMs
	if( not isMine and not self.db.profile.showOthers ) then
		return
	end

	local type = isMine and "ourColor" or "color"
	GTBGroup:RegisterBar(string.format("dw%s", destGUID), string.format("%s (%d)", destName, stack), endTime - GetTime(), duration, nil, self.db.profile[type].r, self.db.profile[type].g, self.db.profile[type].b)
end

-- Check for POM
local COMBATLOG_OBJECT_TYPE_PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER
local eventRegistered = {["SPELL_HEAL"] = true, ["SPELL_AURA_APPLIED"] = true, ["SPELL_AURA_REMOVED"] = true, ["UNIT_DIED"] = true}
function DistWatch:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, eventType, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellID, spellName, spellSchool, auraType)
	if( not eventRegistered[eventType] and bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) == COMBATLOG_OBJECT_TYPE_PLAYER ) then
		return
	end
	
	-- Bounced
	if( eventType == "SPELL_HEAL" and spellName == SPELL_NAME ) then
		local type = selfOwned[destGUID] and "ourColor" or "color"
		GTBGroup:RegisterBar(string.format("dw%s", destGUID), string.format("%s - %s", destName, auraType), 0, nil, nil, self.db.profile[type].r, self.db.profile[type].g, self.db.profile[type].b)
	
	-- POM Faded
	elseif( eventType == "SPELL_AURA_REMOVED" and auraType == "BUFF" and spellName == SPELL_NAME ) then
		GTBGroup:UnregisterBar(string.format("dw%s", destGUID))
		
	-- Unit died
	elseif( eventType == "UNIT_DIED" ) then
		GTBGroup:UnregisterBar(string.format("dw%s", destGUID))
	end
end

-- Check if we should enable it
function DistWatch:ZONE_CHANGED_NEW_AREA()
	local type = select(2, IsInInstance())
	
	if( type ~= instanceType ) then
		playerGUID = UnitGUID("player")

		if( self.db.profile.inside[type] ) then
			self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
			self:RegisterEvent("UNIT_AURA")
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
	GTBGroup:RegisterBar("dw1", string.format("%s - Distomos (4)", UnitName("player")), 15, nil, nil, self.db.profile.color.r, self.db.profile.color.g, self.db.profile.color.b)
	GTBGroup:RegisterBar("dw2", string.format("%s (5)", UnitName("player")), 15, nil, nil, self.db.profile.ourColor.r, self.db.profile.ourColor.g, self.db.profile.ourColor.b)
end

function DistWatch:Clear()
	GTBGroup:UnregisterAllBars()
end