--[ Bishop
--This mod provides a method for healers to track statistics with regards to their healing

local DEFAULT_OPTIONS = {}
local RED = "|cffff0000"
local GREEN = "|cff00ff00"
local BLUE = "|cff0000ff"
local YELLOW = "|cffffff00"
local HEADER = YELLOW.."[Bishop] |cffffffff"

--[[---------------------------------------------------------------------------------
  Class Setup
------------------------------------------------------------------------------------]]

Bishop = AceAddon:new({
	name		  = BISHOP.NAME,
	description   = BISHOP.DESCRIPTION,
	version		  = "1.0",
	releaseDate   = "10-19-2005",
	aceCompatible = "102",
	author		  = "Cladhaire",
	email		  = "cladhaire@gmail.com",
	website		  = "http://watchdog.brokendreams.net/Bishop",
	category	  = "other",
	db			  = AceDatabase:new("BishopDB"),
	defaults	  = DEFAULT_OPTIONS,
	cmd			  = AceChatCmd:new(BISHOP.COMMANDS, BISHOP.CMD_OPTIONS),
})

-- This method is for basic initialization stuff, like setting class variables,
-- performing data checks, and registering chat commands.
function Bishop:Initialize()
	
	-- Save the tooltip as a shortcut
	self.tooltip = BishopTooltip
	
	-- Create structure for saving spell information
	self.spellInfo = {	name 		= nil,		-- The name of the spell
						rank 		= nil,		-- The rank of the spell
						target		= nil,		-- The target of the spell
					}
	
	self.lastName = nil		-- The name of the last spell we scanned (tried to be cast)
	self.lastRank = nil		-- The rank of the last spell we scanned (tried to be cast)
	self.instant = nil		-- Only set to true if we've caught a spellcast
	
	-- Lets make some closures for our options
	self.GetOpt = function(var) local v=self.db:get(self.profilePath, var) return v end
	self.SetOpt = function(var, val) self.db:set(self.profilePath, var, val) end
	self.TogOpt = function (var) return self.db:toggle(self.profilePath, var) end
	self.TogMsg = function(text, val) self.cmd:status(text, val, ACEG_MAP_ONOFF) end
	self.incVal = function(path, key, val) self.db:set(path, key, (self.db:get(path, key) or 0) + val) end
	self.Get	= function(path, key) self.db:get(path, key) end
end

-- The Enable() method checks to see if hello messages are turned on. If so, then
-- it registers the appropriate events that allow Bishop respond to zone changes.
function Bishop:Enable()
	
	-- Register for events
	self:RegisterEvent("SPELLCAST_START")
	self:RegisterEvent("SPELLCAST_FAILED")
	self:RegisterEvent("SPELLCAST_INTERRUPTED")
	self:RegisterEvent("SPELLCAST_STOP")
	self:RegisterEvent("SPELLCAST_CHANNEL_START")
	
	self:RegisterEvent("UNIT_INVENTORY_CHANGED")
	self:RegisterEvent("LEARNED_SPELL_IN_TAB", "ParseSpellbook")

	self:ParseSpellbook()
	self:UNIT_INVENTORY_CHANGED(true)
	
	-- Healing spells on anyone in raid/party
	self:RegisterEvent("CHAT_MSG_SPELL_SELF_BUFF")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_BUFFS", "HOT_FRIENDLY")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_BUFFS", "HOT_FRIENDLY")
	
	self:Hook("CastSpell")
	self:Hook("CastSpellByName")
	self:Hook("UseAction")
	self:Hook("SpellTargetUnit")
	self:Hook("TargetUnit")
	self:Hook("SpellStopTargeting")
	self:Hook("CameraOrSelectOrMoveStart")
end

--[[---------------------------------------------------------------------------------
  Event Handling
------------------------------------------------------------------------------------]]

function Bishop:SPELLCAST_START()
	-- When this fires we want to grab the last CastSpell/ByName/UseAction information
	-- and save that information, so we can wait for the chat message (for processing)
	-- arg1 == the spell name
	
	self:debug(GREEN.."SPELLCAST_START()")
	
	if not arg1 == self.lastName then
		self:debug("Issue in SPELLCAST_START.  ("..tostring(arg1).." ~= "..tostring(self.lastName)..")")
		return
	end

	self:SetSpell(self.lastName, self.lastRank, self.lastTarget)
end

function Bishop:SPELLCAST_FAILED()
	-- This event will fire when we have a spell that can't be cast (invalid, more powerful)
	-- or when we're moving when we attempt to cast.  This needs to clear all saved
	-- variables whenever it fires.
	
	self:debug(RED.."SPELLCAST_FAILED()")
	
	self:ClearData()
end

function Bishop:SPELLCAST_INTERRUPTED()
	-- This event will fire as an error message, but doesn't truly signify anything:
	-- Fires when you move while casting (after SPELLCAST_STOP)  Shouldn't need to do anything
	-- with this event, but its probably a good idea to clear the saved data when it drops.
	
	self:debug(YELLOW.."SPELLCAST_INTERRUPTED()")
	
	self:ClearData()
end

function Bishop:SPELLCAST_STOP()
	-- This is an important event, it fires on occasion when spells fail, but also when spells
	-- finish casting.  It is the only event that fires for instant cast spells.
	-- Fires when moving while casting a spell (obviously won't fire for instant casts)
	-- Fires immediately after SPELLCAST_CHANNEL_START when casting a channeled spell
	-- Fires when finished casting a spell
	
	-- At this point, we expect SetSpell to have been called.  If this is an instant
	-- cast spell, self.instant will be true, otherwise it won't.  This event is only
	-- truly used for instant cast spells. 
	
	-- At this point, this should be a successfully cast instant cast spell
	
	self:debug(RED.."SPELLCAST_STOP")
	
	if self.instant then 
		self:PredictHeal()
	end
end

function Bishop:SPELLCAST_CHANNEL_START()
	-- This event will fire when we start casting a channeled spell (Tranquility). 
	-- At this point, we can predict the full amount of the heal.
	
	self:debug(GREEN.."SPELLCAST_CHANNEL_START")
	
	self:PredictHeal()
end

function Bishop:CHAT_MSG_SPELL_SELF_BUFF()
	-- This event will fire when a heal comes across on anyone in the raid or party
	-- Messages we are interested in: "Your Flash Heal critically heals Cladhaire for 1337."
	-- SetSpell should have already been called, so we just need to process the prediction
	
	local _,_,spell,target,amount = string.find(arg1, BISHOP.MSG_HEAL_PATTERN)

	if not spell or not target or not amount then return end
	
	-- Parse the critically out, if it exists
	local _,_,critName = string.find(spell, BISHOP.MSG_CRIT_PATTERN)
	
	if critName then spell = critName end
	if target == "you" then target = "player" end
	
	if not BISHOP.HEALS[spell] then return end
	
	local rank = BISHOP.HEALS[spell].lastRank

	-- We need the spell, rank, target and amount in order to pass the heal off
	
	self:debug("CHAT_MSG_SPELL_SELF_BUFF: Spell: " .. tostring(spell).. " Amount: " .. tostring(amount) .. " Target: " .. tostring(target))
	
	local missing = UnitHealthMax(target) - UnitHealth(target)
	local actual
	
	if (missing - amount) < 0 then
		actual = missing
	else
		actual = amount
	end
			
	self:PredictHeal()
	
	self:AddHeal(spell, rank, target, actual)
	self:ClearData()
end

function Bishop:CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS()
	-- This event will fire when a HoT tick goes off on the player.
	-- Messages will typically look like: "You gain 12 health from Renew."
	-- Prediction has already been done, we just need to record the heal

	local _,_,actual,spell = string.find(arg1, BISHOP.MSG_HOT_PATTERN_SELF)

	if not actual or not spell then return end
	if not BISHOP.HEALS[spell] then return end

	self:debug(arg1)
	
	local rank = BISHOP.HEALS[spell].lastRank
	
	self:AddHeal(spell, rank, "player", actual)
end

function Bishop:HOT_FRIENDLY()
	-- This event will fire when a HoT tick goes off on a party member
	-- Messages will typically look like: "Sagart gains 12 health from your Renew."
	-- Prediction has already been done, we just need to record the heal

	local _,_,targetName,actual,spell = string.find(arg1, BISHOP.MSG_HOT_PATTERN_OTHER)

	if not targetName or not actual or not spell then return end
	if not BISHOP.HEALS[spell] then return end

	self:debug(arg1)
		
	local rank = BISHOP.HEALS[spell].lastRank
	local target = self:GetTargetFromName(targetName)
	
	if not target then return end
	
	self:AddHeal(spell, rank, target, actual)
end


--[[---------------------------------------------------------------------------------
  Function Hooks
------------------------------------------------------------------------------------]]

function Bishop:CastSpell(spellId, spellbookTabNum)
	-- Call the original function
	self:CallHook("CastSpell", spellId, spellbookTabNum)
	local name, rank = GetSpellName(spellId, spellbookTabNum)

	if not BISHOP.HEALS[name] then return end
	_,_,rank = string.find(rank, BISHOP.RANK_PATTERN)
	
	self.spellInfo.spell = name
	self.spellInfo.rank = rank
	self.spellInfo.instant = BISHOP.HEALS[name].instant
	
	if SpellIsTargeting() then
		self.spellInfo.targeting = true
	else
		self.spellInfo.target = UnitName("target")
		self.predict = true

		if BISHOP.HEALS[name].instant then self:PredictHeal() end
	end
end

function Bishop:CastSpellByName(spellName)
	self:CallHook("CastSpellByName", spellName)
	local _,_,name,rank = string.find(spellName, BISHOP.NAME_RANK_PATTERN)
	if not name then return end
	if not BISHOP.HEALS[name] then return end

	self.spellInfo.spell = name
	self.spellInfo.rank = rank
	self.spellInfo.instant = BISHOP.HEALS[name].instant

	if SpellIsTargeting() then
		self.spellInfo.targeting = true
	else
		self.spellInfo.target = UnitName("target")
		self.predict = true

		if BISHOP.HEALS[name].instant then self:PredictHeal() end
	end
end

function Bishop:UseAction(a1, a2, a3)
	self:CallHook("UseAction", a1, a2, a3)
	if GetActionText(a1) then return end
	self.tooltip:SetAction(a1) 
	local name, rank

	if BishopTooltipTextLeft1:GetText() then 
		name = BishopTooltipTextLeft1:GetText()
		if BishopTooltipTextRight1:GetText() then 
			_,_,rank = string.find(BishopTooltipTextRight1:GetText(), BISHOP.RANK_PATTERN)
		end
	else
		return
	end

	if not name or not rank then return end
	if not BISHOP.HEALS[name] then return end
	
	self.spellInfo.spell = name
	self.spellInfo.rank = rank
	self.spellInfo.instant = BISHOP.HEALS[name].instant
 
	if SpellIsTargeting() then
		self.spellInfo.targeting = true
	else
		self.spellInfo.target = UnitName("target")
		self.predict = true

		if BISHOP.HEALS[name].instant then self:PredictHeal() end
	end
end

function Bishop:SpellTargetUnit(unit)
	self:CallHook("SpellTargetUnit", unit)
	
	if self.spellInfo.targeting and not SpellIsTargeting() then
		self.spellInfo.target = UnitName(unit)
		self.predict = true

		if BISHOP.HEALS[self.spellInfo.spell].instant then self:PredictHeal() end
	end
end

function Bishop:TargetUnit(unit)
	self:CallHook("TargetUnit", unit)

	if self.spellInfo.targeting and not SpellIsTargeting() then
		self.spellInfo.target = UnitName(unit)
		self.predict = true

		if BISHOP.HEALS[self.spellInfo.spell].instant then self:PredictHeal() end
	end
end

function Bishop:SpellStopTargeting()
	self:CallHook("SpellStopTargeting")
end

function Bishop:CameraOrSelectOrMoveStart()
	local target= nil
	
	if self.spellInfo.spell and UnitName("mouseover") then
		target = UnitName("mouseover")
	end

	self:CallHook("CameraOrSelectOrMoveStart")

	if self.spellInfo.targeting and not SpellIsTargeting() then
		self.spellInfo.target = target
		self.predict = true

		if BISHOP.HEALS[self.spellInfo.spell].instant then self:PredictHeal() end
	end
end

--[[---------------------------------------------------------------------------------
  Processing Functions
------------------------------------------------------------------------------------]]

function Bishop:PredictHeal()
	if not self.predict then return end
	
	local data = BISHOP.HEALS[self.spellInfo.spell][self.spellInfo.rank]
	local rootPath = {"healData"}
	local targetSpellPath = {"healData", self.spellInfo.target}
	local paths = {rootPath, targetSpellPath}
	
	for k,v in paths do
--		self.db:incVal(v, "casts", 1)
	end
	
	if data.hotAmt then
		-- We have a HoT amount, so lets predict that first
		for k,v in paths do 
--			self.db.incVal(v, "amount", data.hotAmt)
		end
	end
	
	if data.min then
		-- We have a min/max amount, so predict the average between then
		for k,v in paths do
--			self.db:incVal(v, "amount", (data.min + data.max) / 2)
		end
	end
	
	ace:print(HEADER.." Predicted " .. self.spellInfo.spell .. " Rank " .. self.spellInfo.rank .. " on " .. tostring(self.spellInfo.target)) 
	
	-- Change predict so we don't try this again (Chain Heal, PoF, etc)
	self.predict = nil
	self.instant = nil
	self.targeting = nil

	self:ClearData()	
end

function Bishop:SetSpell(spell, rank, target)
end

function Bishop:AddHeal(spell, rank, target, actual)
	ace:print(HEADER.." AddHeal(" ..tostring(spell)..", "..tostring(rank)..", "..tostring(target)..", "..tostring(actual))
end

function Bishop:ClearData()
	local s = self.spellInfo
	self.lastSpell = s.spell
	self.lastRank = s.rank

	s.spell = nil
	s.targeting = nil
	s.instant = nil
	s.rank = 9
end

function Bishop:GetTargetFromName(name)
end

function Bishop:OnEnter()
end

--[[ Data is saved in the following format:

healData = {
	["Sagart"] = {
		class 	= "Priest",	
		["Flash Heal"] = {
			["Rank 6"] = {
				actual 	= 0,
				amount 	= 0,
				casts 	= 0,
				crits	= 0,
			}
		},
		["Greater Heal"] = {		
			["Rank 4"] = {
				actual 	= 0,
				amount 	= 0,
				casts 	= 0,
				crits	= 0,
			},
		},
	},
}

--]]

Bishop:RegisterForLoad()