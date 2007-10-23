Bishop = DongleStub("Dongle-1.1"):New("Bishop")

local L = BishopLocals

local spellData
local talentData
local rangedData

local healData = {}

local playerTalents = {}
local equippedBonus = {}

local playerLevel = 0
local regrowthHealing = 0

local healYourself
local healOther
local healCritYourself
local healCritOther
local hotYourself
local hotOther

function Bishop:Enable()
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_BUFFS")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS")
	self:RegisterEvent("CHAT_MSG_SPELL_SELF_BUFF")

	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:RegisterEvent("UNIT_SPELLCAST_SENT")
	--self:RegisterEvent("UNIT_SPELLCAST_STOP")
	--self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")

	self:RegisterEvent("CONFIRM_TALENT_WIPE", "ScanPlayerTalents")
	self:RegisterEvent("CHARACTER_POINTS_CHANGED", "ScanPlayerTalents")
	self:RegisterEvent("UNIT_INVENTORY_CHANGED", "ScanPlayerRanged")
	
	spellData, talentData, rangedData = BishopData["Load" .. select(2, UnitClass("player"))]()
	rangedData = rangedData or {}
	
	-- Failed to load any data, exit quickly
	if( not spellData ) then
		self:Disable()
		return
	end
	
	self:ScanPlayerTalents()
	self:ScanPlayerRanged()
	
	playerLevel = UnitLevel("player")
	
--[[
	PERIODICAURAHEALSELFOTHER = "%s gains %d health from your %s.";
	PERIODICAURAHEALSELF = "You gain %d health from %s.";	
	HEALEDCRITSELFOTHER = "Your %s critically heals %s for %d.";
	HEALEDCRITSELFSELF = "Your %s critically heals you for %d.";
	HEALEDSELFOTHER = "Your %s heals %s for %d.";
	HEALEDSELFSELF = "Your %s heals you for %d.";
]]

	healYourself = self:FormatLog(HEALEDSELFSELF)
	healCritYourself = self:FormatLog(HEALEDCRITSELFSELF)
	healOther = self:FormatLog(HEALEDSELFOTHER)
	healCritOther = self:FormatLog(HEALEDCRITSELFOTHER)

	hotYourself = self:FormatLog(PERIODICAURAHEALSELF)
	hotOther = self:FormatLog(PERIODICAURAHEALSELFOTHER)
end

function Bishop:Disable()
	self:UnregisterAllEvents()
end

function Bishop:HealedPlayer(spell, amount, crtHealth, maxHealth, type)
	if( not healData[spell] ) then
		healData[spell] = { totalHealed = 0, overheal = 0 }
	end	

	-- HoT, so subtract it from our current overheal
	if( type == "hot" ) then
		-- Check overheal
		local overheal = amount
		if( (crtHealth + amount) > maxHealth ) then
			overheal = maxHealth - crtHealth
		end

		healData[spell].overheal = healData[spell].overheal - overheal
	
	-- Direct heal, check overheal amount
	elseif( type == "heal" ) then
		-- Check overheal amount
		local overheal = crtHealth + amount
		if( overheal > maxHealth ) then
			overheal = overheal - maxHealth
		else
			overheal = 0
		end

		healData[spell].totalHealed = healData[spell].totalHealed + amount
		healData[spell].overheal = healData[spell].overheal + overheal
	end
	
	if( healData[spell].overheal < 0 ) then
		healData[spell].overheal = 0
	end
	
	--self:Echo(spell, healData[spell].totalHealed, healData[spell].overheal)
end

function Bishop:CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS(event, msg)
	if( string.match(msg, hotYourself) ) then
		local amount, spell = string.match(msg, hotYourself)
		
		self:HealedPlayer(spell, amount, UnitHealth("player"), UnitHealthMax("player"), "hot")
	end
end

function Bishop:CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_BUFFS(event, msg)
	if( string.match(msg, hotOther) ) then
		local target, amount, spell = string.match(msg, hotOther)

		self:HealedPlayer(spell, amount, UnitHealth(target), UnitHealthMax(target), "hot")
	end
end

function Bishop:CHAT_MSG_SPELL_SELF_BUFF(event, msg)
	if( string.match(msg, healCritYourself) ) then
		local spell, amount = string.match(msg, healCritYourself)
	
		self:HealedPlayer(spell, amount, UnitHealth("player"), UnitHealthMax("player"), "heal")
	elseif( string.match(msg, healYourself) ) then
		local spell, amount = string.match(msg, healYourself)
		
		self:HealedPlayer(spell, amount, UnitHealth("player"), UnitHealthMax("player"), "heal")
	elseif( string.match(msg, healCritOther) ) then
		local spell, target, amount = string.match(msg, healCritOther)

		self:HealedPlayer(spell, amount, UnitHealth(target), UnitHealthMax(target), "heal")
	elseif( string.match(msg, healOther) ) then
		local spell, target, amount = string.match(msg, healOther)
		
		self:HealedPlayer(spell, amount, UnitHealth(target), UnitHealthMax(target), "heal")
	end
end

function Bishop:UNIT_SPELLCAST_SUCCEEDED(event, unit, spell, rank)
	if( unit ~= "player" ) then
		return
	end
	
	if( spell == L["Regrowth"] ) then
		self:HealedPlayer(spell, self:CalculateHOTHeal(spell, rank, regrowthHealing))
	end
end

function Bishop:UNIT_SPELLCAST_SENT(event, unit, spell, rank, target)
	if( unit ~= "player" ) then
		return
	end
	
	-- Figure out Lifebloom stack now for sanity
	if( spell == L["Lifebloom"] ) then
		local i = 1		
		local spellStack = 1
		
		while( true ) do
			local name, rank, _, stack, totalTime, duration = UnitBuff(target, i)
			if( not name ) then
				break
			end

			if( name == spell and duration ) then
				spellStack = stack + 1
				break
			end
			
			i = i + 1
		end
			
		self:HealedPlayer(spell, self:CalculateHOTHeal(spell, rank, nil, spellStack), 0, 0, "heal")
	
	-- Also figure out rejuvenation heal now for sanity
	elseif( spell == L["Rejuvenation"] ) then
		self:HealedPlayer(spell, self:CalculateHOTHeal(spell, rank), 0, 0, "heal")
	
	-- As far as I know, Blizzard calculates the +healing by what it when
	-- the spell was sent to the server, so we have to store it here to calculate it
	elseif( spell == L["Regrowth"] ) then
		regrowthHealing = GetSpellBonusHealing()
	end
end


-- Figure out the total value of the HoT
function Bishop:CalculateHOTHeal(spellName, rank, totalHealing, spellStack)
	if( not spellName ) then
		return 0
	end
	
	rank = tonumber(string.match(rank, "(%d+)"))
	spellStack = spellStack or 1
	totalHealing = totalHealing or GetSpellBonusHealing()
	
	local healed = 0
	local spell = spellData[spellName]
	local addFactor = 1.0
	local multiFactor = spell[0].duration / 15
	
	-- For lifebloom mainly
	if( spellStack > spell[0].maxStack ) then
		spellStack = spell[0].maxStack
	end
			
	-- Apply talent information
	for talent, data in pairs(talentData) do
		if( not data.spell or data.spell == spellName ) then
			if( data.multi ) then
				multiFactor = multiFactor * (1 + (playerTalents[talent] * data.mod))
			else
				addFactor = addFactor + (playerTalents[talent] * data.mod)
			end
		end
	end
	
	-- Check if we have any idols/relics/librams increasing our +healing for this
	if( equippedBonus.spell == spellName ) then
		totalHealing = totalHealing + equippedBonus.healing		
	end
	
	-- Low level penalty
	local lowLevelPenalty = 1
	if( spell[rank].level < 20 ) then
		lowLevelPenalty = 1 - ((20 - spell[rank].level) * 0.0375)
		if( lowLevelPenalty < 1 or lowLevelPenalty > 0 ) then
			multiFactor = multiFactor * lowLevelPenalty
		end
	end
	
	-- Downrank penalty
	local downRankPenalty = (spell[rank].level + 11) / playerLevel
	if( downRankPenalty < 1 ) then
		multiFactor = multiFactor * downRankPenalty
	end
	
	-- Now calculate the total amount healed
	if( spell[0].type == "ddhot" ) then
		multiFactor = multiFactor * (1 - (spell[0].hotFactor or 0)) * (spell[0].dotFactor or 1)
		healed = addFactor * (multiFactor * totalHealing + spell[rank].healed )

	elseif( spell[0].type == "hot" ) then
		healed = addFactor * (1 * spell[rank].healed + (totalHealing * multiFactor))
	end
	
	--self:Echo(spellName, rank, healed * spellStack, multiFactor, addFactor)
	
	return healed * spellStack
end

-- Check if we have any healing bonuses applied
function Bishop:ScanPlayerRanged()
	equippedBonus.spell = nil
	equippedBonus.healing = nil
	
	for spell, items in pairs(rangedData) do
		for itemid, healing in pairs(items) do
			if( IsEquippedItem(itemid) ) then
				equippedBonus.spell = spell
				equippedBonus.healing = healing
				break
			end
		end
		
		if( equippedBonus.spell ) then
			break
		end
	end
end

-- Scan/cache talents
function Bishop:ScanPlayerTalents()
	for tabIndex=1, GetNumTalentTabs() do
		for i=1, GetNumTalents(tabIndex) do
			local talentName, _, _, _, pointsSpent = GetTalentInfo(tabIndex, i)	
			if( not talentName ) then
				break
			end
			
			playerTalents[talentName] = pointsSpent
		end
	end
end

-- Turn GlobalStrings log into useful one
function Bishop:FormatLog(text)
	text = string.gsub(text, "%%s", "(.+)")
	text = string.gsub(text, "%%d", "([0-9]+)")
	
	return text
end
