--[[ 
	Afflicted 3, Mayen/Selari/Dayliss from Illidan (US) PvP
]]

Afflicted = LibStub("AceAddon-3.0"):NewAddon("Afflicted", "AceEvent-3.0")

local L = AfflictedLocals
local instanceType
local summonedTotems = {}

function Afflicted:OnInitialize()
	self.defaults = {
		profile = {
			showAnchors = false,
			targetOnly = false,
			
			barWidth = 180,
			barNameOnly = false,
			barName = "BantoBar",

			fontSize = 12,
			fontName = "Friz Quadrata TT",
			
			announceColor = { r = 1.0, g = 1.0, b = 1.0 },
			announceDest = "1",
			inside = {["none"] = true},
			anchors = {},
			spells = {},

			revision = 0,
			spellRevision = 0,
		},
	}
	
	local anchor = {
		enabled = true,
		announce = false,
		growUp = false,
		scale = 1.0,
		maxRows = 20,
		fadeTime = 0.5,
		icon = "LEFT",
		redirect = "",
		display = "icons",
		startMessage = "USED *spell (*target)",
		endMessage = "FADED *spell (*target)",
	}
	
	-- Load default anchors
	self.defaults.profile.anchors.interrupts = CopyTable(anchor)
	self.defaults.profile.anchors.interrupts.text = "Interrupts"
	self.defaults.profile.anchors.cooldowns = CopyTable(anchor)
	self.defaults.profile.anchors.cooldowns.text = "Cooldowns"
	self.defaults.profile.anchors.spells = CopyTable(anchor)
	self.defaults.profile.anchors.spells.text = "Spells"
	self.defaults.profile.anchors.buffs = CopyTable(anchor)
	self.defaults.profile.anchors.buffs.text = "Buffs"
	self.defaults.profile.anchors.defenses = CopyTable(anchor)
	self.defaults.profile.anchors.defenses.text = "Defensive"
	self.defaults.profile.anchors.damage = CopyTable(anchor)
	self.defaults.profile.anchors.damage.text = "Damage"
	
	-- Initialize DB
	self.db = LibStub:GetLibrary("AceDB-3.0"):New("Afflicted3DB", self.defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "Reload")
	self.db.RegisterCallback(self, "OnProfileCopied", "Reload")
	self.db.RegisterCallback(self, "OnProfileReset", "Reload")
	self.db.RegisterCallback(self, "OnDatabaseShutdown", "OnDatabaseShutdown")

	self.revision = tonumber(string.match("$Revision$", "(%d+)") or 1)
	
	-- Load SML
	self.SML = LibStub:GetLibrary("LibSharedMedia-3.0")

	-- Load spell defaults in if the DB has changed
	if( self.db.profile.spellRevision <= AfflictedSpells.revision ) then
		self.db.profile.spellRevision = AfflictedSpells.revision
		
		local spells = AfflictedSpells:GetData()
		for spellID, data in pairs(spells) do
			-- Do not add a spell if it doesn't exist
			if( GetSpellInfo(spellID) ) then
				self.db.profile.spells[spellID] = data
			end
		end
	end

	-- So we know what spellIDs need to be updated when logging out
	self.writeQueue = {}
	
	-- Setup our spell cache
	self.spells = setmetatable({}, {
		__index = function(tbl, index)
			-- No data found, don't try and cache this value again
			if( not Afflicted.db.profile.spells[index] ) then
				tbl[index] = false
				return false
			elseif( type(Afflicted.db.profile.spells[index]) == "number" ) then
				tbl[index] = Afflicted.db.profile.spells[index]
				return tbl[index]
			end
			
			tbl[index] = {}

			-- Load the data into the DB
			for key, value in string.gmatch(Afflicted.db.profile.spells[index], "([a-zA-Z]+):([a-zA-Z0-9]+)") do
				-- Convert to number if needed
				if( key == "duration" or key == "cooldown" ) then
					value = tonumber(value)
				end

				tbl[index][key] = value
			end

			-- Load the reset spellID data
			if( tbl[index].resets ) then
				local text = tbl[index].resets

				tbl[index].resets = {}
				for spellID in string.gmatch(text, "([0-9]+),") do
					tbl[index].resets[tonumber(spellID)] = true
				end
			end
			
			return tbl[index]
		end
	})

	-- Load display libraries
	self.bars = self.modules.Bars:LoadVisual()
	self.icons = self.modules.Icons:LoadVisual()
	
	-- Annnd update revision
	self.db.profile.revision = self.revision

	self:RegisterEvent("PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
end

-- Quick function to get the linked spells easily and such
function Afflicted:GetSpell(spellID, spellName)
	if( self.spells[spellName] ) then
		return self.spells[spellName]
	elseif( not self.spells[spellID] ) then
		return nil
	elseif( tonumber(self.spells[spellID]) ) then
		return self.spells[self.spells[spellID]]
	end
	
	return self.spells[spellID]
end

local COMBATLOG_OBJECT_REACTION_HOSTILE	= COMBATLOG_OBJECT_REACTION_HOSTILE
local eventRegistered = {["SPELL_CAST_SUCCESS"] = true, ["SPELL_AURA_REMOVED"] = true, ["SPELL_SUMMON"] = true, ["SPELL_CREATE"] = true, ["PARTY_KILL"] = true, ["UNIT_DIED"] = true}

function Afflicted:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, eventType, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, ...)
	if( not eventRegistered[eventType] ) then
		return
	end
				
	-- Enemy buff faded
	if( eventType == "SPELL_AURA_REMOVED" and bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE ) then
		local spellID, spellName, spellSchool, auraType = ...
		if( auraType == "BUFF" ) then
			self:AbilityEarlyFade(sourceGUID, sourceName, self:GetSpell(spellID, spellName), spellID, spellName, spellSchool)
		end

	-- Spell casted succesfully
	elseif( eventType == "SPELL_CAST_SUCCESS" and bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE ) then
		local spellID, spellName, spellSchool, auraType = ...
		local spell = self:GetSpell(spellID, spellName)
		if( spell and spell.resets ) then
			self:ResetCooldowns(spell.resets)
		end
		
		self:AbilityTriggered(sourceGUID, sourceName, spell, spellID, spellName, spellSchool)
		
	-- Check for something being summoned (Pets, totems)
	elseif( eventType == "SPELL_SUMMON" and bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE ) then
		local spellID, spellName, spellSchool = ...
	
		-- Fixes an issue with totems not being removed when they get redropped
		local id = sourceGUID .. (AfflictedSpells:GetTotemClass(spellName) or spellName)
		local spell = self:GetSpell(spellID, spellName)
		if( spell and spell.type == "totem" ) then
			-- We already had a totem of this timer up, remove the previous one first
			if( summonedTotems[id] ) then
				self[self.db.profile.anchors[spell.anchor].display]:RemoveTimerByID(self.anchor, summonedTotems[id])
			end
			
			self:AbilityTriggered(sourceGUID, sourceName, spell, spellID, spellName, spellSchool)
		end

		-- Set this as the active totem of that type down
		summonedTotems[id] = sourceGUID .. spellID
		
	-- Check for something being created (Traps, ect)
	elseif( eventType == "SPELL_CREATE" and bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE ) then
		local spellID, spellName, spellSchool = ...
		
		local spell = self:GetSpell(spellID, spellName)
		if( spell and spell.type == "trap" ) then
			self:AbilityTriggered(sourceGUID, sourceName, spell, spellID, spellName, spellSchool)
		end
		
	-- Check if we should clear timers
	elseif( ( eventType == "PARTY_KILL" or ( instancetype ~= "arena" and eventType == "UNIT_DIED" ) ) and bit.band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE ) then
		self.display.bars:UnitDied(destGUID)
		self.display.icons:UnitDied(destGUID)
	end
end

-- Reset spells
function Afflicted:ResetCooldowns(spells)
	for spellID in pairs(spells) do
		local anchor = self.db.profile.anchors[spellData.cdAnchor]
		if( anchor.enabled ) then
			self[anchor.display]:RemoveTimerByID(spellData.cdAnchor, sourceGUID .. spellID .. "CD")
		end
	end
end

function test()
	local self = Afflicted
	self:AbilityTriggered(UnitGUID("player"), UnitName("player"), self:GetSpell(47476, "Strangulate"), 47476, "Strangulate", 0)
	self:AbilityTriggered(UnitGUID("player"), UnitName("player"), self:GetSpell(18499, "Berserker Rage"), 18499, "Berserker Rage", 0)
end

-- Timer started
function Afflicted:AbilityTriggered(sourceGUID, sourceName, spellData, spellID, spellName, spellSchool)
	-- No data found, it's disabled, or it's not in our interest cause it's not focus/target
	if( not spellData or spellData.disabled or ( self.db.profile.targetOnly and UnitGUID("target") ~= sourceGUID and UnitGUID("focus") ~= sourceGUID ) ) then
		return
	end
	
	-- Set spell icon
	if( not spellData.icon or spellData.icon == "" or spellData.dontSave ) then
		spellData.icon = select(3, GetSpellInfo(spellID))
	end
	
	local anchor = self.db.profile.anchors[spellData.anchor or spellData.cdAnchor]
	
	-- Start timer
	self[anchor.display]:CreateTimer(sourceGUID, sourceName, spellData, spellID, spellName, spellSchool)
	
	-- Announce timer used
	self:Announce(spellData, anchor, "startMessage", spellName, sourceName)
end

-- Spell faded early, so announce that
function Afflicted:AbilityEarlyFade(sourceGUID, sourceName, spellData, spellID, spellName, spellSchool)
	if( spellData and not spellData.disabled and spellData.type == "buff" ) then
		local removed = self[self.db.profile.anchors[spellData.anchor].display]:RemoveTimerByID(spellData.anchor, sourceGUID .. spellID)
		if( removed ) then
			self:Announce(spellData, self.db.profile.anchors[spellData.anchor], "endMessage", spellName, sourceName)
		end
	end
end

-- Timer faded naturally
function Afflicted:AbilityEnded(sourceGUID, sourceName, spellData, spellID, spellName, spellSchool, isCooldown)
	if( spellData ) then
		if( not isCooldown and not spellData.disabled ) then
			self:Announce(spellData, self.db.profile.anchors[spellData.anchor], "endMessage", spellName, sourceName)
		elseif( isCooldown and not spellData.cdDisabled ) then
			self:Announce(spellData, self.db.profile.anchors[spellData.cdAnchor], "endMessage", spellName, sourceName)
		end
	end
end

-- Announce something
function Afflicted:Announce(spellData, anchor, key, spellName, sourceName)
	local msg
	if( spellData.custom ) then
		msg = spellData[key]
	elseif( anchor.enabled and anchor.announce ) then
		msg = anchor[key]
	end
	
	if( not msg or msg == "" ) then
		return
	end
	
	msg = string.gsub(msg, "*spell", spellName)
	msg = string.gsub(msg, "*target", self:StripServer(sourceName))

	self:SendMessage(msg, anchor.announceDest, anchor.announceColor)
end

-- Database is getting ready to be written, we need to convert any changed data back into text
function Afflicted:OnDatabaseShutdown()
	for spellID in pairs(self.writeQueue) do
		-- We got data we can write
		if( type(self.spells[spellID]) == "table" ) then
			local data = ""
			for key, value in pairs(self.spells[spellID]) do
				data = data .. key .. ":" .. value .. ";"
			end

			self.db.profile.spells[spellID] = data
		-- No spell data found, reset saved
		elseif( not self.spells[spellID] ) then
			self.db.profile.spells[spellID] = nil
		end
		
		self.writeQueue[spellID] = nil
	end
end

-- Enabling Afflicted based on zone type
function Afflicted:ZONE_CHANGED_NEW_AREA()
	local type = select(2, IsInInstance())

	if( type ~= instanceType ) then
		if( self.db.profile.inside[type] ) then
			self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		else
			self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		end
	end
	
	instanceType = type
end

function Afflicted:Reload()

end

-- Strips server name
function Afflicted:StripServer(text)
	local name, server = string.match(text, "(.-)%-(.*)$")
	if( not name and not server ) then
		return text
	end
	
	return name
end

local chatFrames = {}
function Afflicted:SendMessage(msg, dest, color)
	-- We're not showing anything
	if( dest == "none" ) then
		return
	-- We're undergrouped, so redirect it to our fake alert frame
	elseif( dest == "rw" and GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 ) then
		dest = "rwframe"
	-- We're grouped, in a raid and not leader or assist
	elseif( dest == "rw" and not IsRaidLeader() and not IsRaidOfficer() and GetNumRaidMembers() > 0 ) then
		dest = "party"
	end
	
	-- Strip out any () leftover from no name being given
	msg = string.trim(string.gsub(msg, "%(%)", ""))
		
	-- Chat frame
	if( tonumber(dest) ) then
		if( not chatFrames[dest] ) then
			chatFrames[dest] = getglobal("ChatFrame" .. dest)
		end
		
		local frame = chatFrames[dest] or DEFAULT_CHAT_FRAME
		frame:AddMessage("|cff33ff99Afflicted|r|cffffffff:|r " .. msg, color.r, color.g, color.b)
	-- Raid warning announcement to raid/party
	elseif( dest == "rw" ) then
		SendChatMessage(msg, "RAID_WARNING")
	-- Raid warning frame, will not send it out to the party
	elseif( dest == "rwframe" ) then
		if( not self.alertFrame ) then
			self.alertFrame = CreateFrame("MessageFrame", nil, UIParent)
			self.alertFrame:SetInsertMode("TOP")
			self.alertFrame:SetFrameStrata("HIGH")
			self.alertFrame:SetWidth(UIParent:GetWidth())
			self.alertFrame:SetHeight(60)
			self.alertFrame:SetFadeDuration(0.5)
			self.alertFrame:SetTimeVisible(2)
			self.alertFrame:SetFont((GameFontNormal:GetFont()), 20, "OUTLINE")
			self.alertFrame:SetPoint("CENTER", 0, 60)
		end
		
		self.alertFrame:AddMessage(msg, color.r, color.g, color.b)
	-- Party chat
	elseif( dest == "party" ) then
		SendChatMessage(msg, "PARTY")
	-- Combat text
	elseif( dest == "ct" ) then
		self:CombatText(msg, color)
	end
end

function Afflicted:CombatText(text, color, spellID)	
	-- SCT
	if( IsAddOnLoaded("sct") ) then
		SCT:DisplayText(text, color, nil, "event", 1)
	-- MSBT
	elseif( IsAddOnLoaded("MikScrollingBattleText") ) then
		MikSBT.DisplayMessage(text, MikSBT.DISPLAYTYPE_NOTIFICATION, false, color.r * 255, color.g * 255, color.b * 255)		
	-- Blizzard Combat Text
	elseif( IsAddOnLoaded("Blizzard_CombatText") ) then
		-- Haven't cached the movement function yet
		if( not COMBAT_TEXT_SCROLL_FUNCTION ) then
			CombatText_UpdateDisplayedMessages()
		end
		
		CombatText_AddMessage(text, COMBAT_TEXT_SCROLL_FUNCTION, color.r, color.g, color.b)
	end
end

function Afflicted:Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Afflicted3|r: " .. msg)
end
