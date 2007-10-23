Bishop = DongleStub("Dongle-1.1"):New("Bishop")

local L = BishopLocals

local healData = {}
local spellData
local talentData
local rangedData
local playerTalents = {}
local equippedBonus = {}

function Bishop:Enable()
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_BUFFS")
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:RegisterEvent("UNIT_SPELLCAST_SENT")
	--self:RegisterEvent("UNIT_SPELLCAST_STOP")
	--self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
	self:RegisterEvent("CHAT_MSG_SPELL_SELF_BUFF")
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
end

function Bishop:Disable()
	self:UnregisterAllEvents()
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

-- Figure out the total value of the HoT
function Bishop:CalculateHOTHeal(spellName, rank, spellStack)
	if( not spellName ) then
		return 0
	end
	
	rank = tonumber(string.match(rank, "(%d+)"))
	
	local healed = 0
	local spell = spellData[spellName]
	local addFactor = 1.0
	local multiFactor = spell[0].duration / 15
	
	if( spellStack > spell[0].maxStack ) then
		spellStack = spell[0].maxStack
	end
	
	-- Apply talent information
	for talent, data in pairs(talentData) do
		if( not data.spell or data.spell == spellName ) then
			if( data.multi ) then
				multiFactor = multiFactor * ( 1 + ( playerTalents[talent] * data.mod ) )
			else
				addFactor = addFactor + ( playerTalents[talent] * data.mod )
			end
		end
	end
	
	-- Check if we have any idols/relics/librams increasing our +healing for this
	local totalHealing = GetSpellBonusHealing()
	if( equippedBonus.spell == spellName ) then
		totalHealing = totalHealing + equippedBonus.healing		
	end
	
	-- Now calculate the total amount healed
	if( spell[0].type == "ddhot" ) then
		multiFactor = multiFactor * ( 1 - ( spell[0].hotFactor or 0 ) ) * ( spell[0].dotFactor or 1 )
		healed = addFactor * ( multiFactor * totalHealing + spell[rank].healed )

	elseif( spell[0].type == "hot" ) then
		healed = addFactor * ( 1 * spell[rank].healed + ( totalHealing * multiFactor ) )
	end
	
	return math.floor((healed * spellStack) + 0.5)
end


function Bishop:CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_BUFFS(event, msg)

end

function Bishop:CHAT_MSG_SPELL_SELF_BUFF(event, msg)
end

function Bishop:UNIT_SPELLCAST_SUCCEEDED(event, unit, spell, rank)
	if( unit ~= "player" ) then
		return
	end
	
	if( spell == L["Regrowth"] ) then
		healData[spell] = ( healData[spell] or 0 ) + self:CalculateHOTHeal(spell, rank, 1)
	end
end

function Bishop:UNIT_SPELLCAST_SENT(event, unit, spell, rank, target)
	if( unit ~= "player" ) then
		return
	end
	
	-- Got to figure it out now for simplicity
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
				return
			end
			
			i = i + 1
		end

		healData[spell] = ( healData[spell] or 0 ) + self:CalculateHOTHeal(spell, rank, spellStack)
	elseif( spell == L["Rejuvenation"] ) then
		healData[spell] = ( healData[spell] or 0 ) + self:CalculateHOTHeal(spell, rank, spellStack)
	end
end

--[[
"[CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_BUFFS] Kasath gains 108 health from your Lifebloom.", -- [334]
"[CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_BUFFS] Malfice gains 182 health from your Regrowth.", -- [190]
"[CHAT_MSG_SPELL_SELF_BUFF] Your Swiftmend heals you for 2210.", -- [347]
"[CHAT_MSG_SPELL_SELF_BUFF] Your Healing Touch heals Malfice for 2449.", -- [192]
"[CHAT_MSG_SPELL_SELF_BUFF] Your Frenzied Regeneration heals you for 250.", -- [206]
"[CHAT_MSG_SPELL_SELF_BUFF] Your Lifebloom critically heals you for 1461.", -- [215]
	
HEALEDCRITOTHER = "%s critically heals %s for %d.";
HEALEDCRITOTHEROTHER = "%s's %s critically heals %s for %d.";
HEALEDCRITOTHERSELF = "%s's %s critically heals you for %d.";
HEALEDCRITSELF = "%s critically heals you for %d.";
HEALEDCRITSELFOTHER = "Your %s critically heals %s for %d.";
HEALEDCRITSELFSELF = "Your %s critically heals you for %d.";
HEALEDOTHER = "%s heals %s for %d.";
HEALEDOTHEROTHER = "%s's %s heals %s for %d.";
HEALEDOTHERSELF = "%s's %s heals you for %d.";
HEALEDSELF = "%s's %s heals you for %d.";
HEALEDSELFOTHER = "Your %s heals %s for %d.";
HEALEDSELFSELF = "Your %s heals you for %d.";
]]