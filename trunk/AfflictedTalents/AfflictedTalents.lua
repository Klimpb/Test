--[[ 
	Afflicted Talents, Mayen (Horde) from Icecrown (US) PvE
]]

AfflictedTalents = LibStub("AceAddon-3.0"):NewAddon("AfflictTalents", "AceEvent-3.0", "AceHook-3.0")

local L = AfflictedTalentsLocals

function AfflictedTalents:OnInitialize()
	-- Defaults
	self.defaults = {
		profile = {
		}
	}
	-- Init DB
	self.db = LibStub:GetLibrary("AceDB-3.0"):New("AfflictedTalentsDB", self.defaults)
	self.revision = tonumber(string.match("$Revision: 791 $", "(%d+)")) or 1

	-- Register the talent guessing lib
	self.talents = LibStub:GetLibrary("TalentGuess-1.0"):Register()
	
	-- Save the original time in seconds first
	--self.afflictedSpells = CopyTable(Afflicted.db.defaults.profile.spells)
	self.afflictedSpells = {}

	self.spells = AfflictedTalentsSpells
	
	self:Hook(Afflicted, "ProcessAbility", "ProcessAbility")
	self:Hook(Afflicted, "OnDisable", "OnDisable")
	self:Hook(Afflicted, "OnEnable", "OnEnable")
end

function AfflictedTalents:OnEnable()
	local type = select(2, IsInInstance())
	if( not Afflicted.db.profile.inside[type] ) then
		return
	end

	self.talents:EnableCollection()
end

function AfflictedTalents:OnDisable()
	self.talents:DisableCollection()
end

local eventsRegistered = {["SPELL_AURA_APPLIEDBUFFENEMY"] = true, ["SPELL_AURA_APPLIEDDEBUFFENEMY"] = true, ["SPELL_CAST_SUCCESS"] = true}
function AfflictedTalents:ProcessAbility(self, eventType, spellID, spellName, spellSchool, sourceGUID, sourceName, destGUID, destName)
	if( not eventsRegistered[eventType] ) then
		return
	end
	
	local self = AfflictedTalents
	local talentedSpell = self.spells[spellID]

	-- Not tracking this
	if( not talentedSpell ) then
		return
	end

	if( type(talentedSpell) == "number" ) then
		talentedSpell = self.spells[talentedSpell]
	end
	
	-- Grab the spell that we're modifying
	local spell = Afflicted.db.profile.spells[spellID]
	local spellIndex = spellID
	if( not spell ) then
		return
	end

	if( type(spell) == "number" ) then
		spellIndex = spell
		spell = Afflicted.db.profile.spells[spell]
	end

	-- Check their talents
	local one, two, three
	if( eventType == "SPELL_CAST_SUCCESS" ) then
		one, two, three = self.talents:GetTalents(sourceName)
	else
		one, two, three = self.talents:GetTalents(destName)
	end
	
	one = one or 0
	two = two or 0
	three = three or 0
	
	-- Nothing to do
	if( one == 0 and two == 0 and three == 0 ) then
		return
	end
	
	-- Meet the talents required so reset it
	if( talentedSpell.one >= one and talentedSpell.two >= two and talentedSpell.three >= three ) then
		if( self.afflictedSpells[spellIndex] ) then
			spell.cooldown = self.afflictedSpells[spellIndex].cooldown
			spell.seconds = self.afflictedSpells[spellIndex].seconds

			ChatFrame1:AddMessage(string.format("[%s] [%s/%s/%s] restored [%s] [%s]", spellName, one, two, three, spell.cooldown or "", spell.seconds or ""))
		end
	else
		-- Save originals
		if( not self.afflictedSpells[spellIndex] ) then
			self.afflictedSpells[spellIndex] = { cooldown = spell.cooldown, seconds = spell.seconds }
		end
		
		if( spell.cooldown ) then
			spell.cooldown = talentedSpell.cooldown
		else
			spell.seconds = talentedSpell.cooldown
		end
		
		ChatFrame1:AddMessage(string.format("[%s] [%s/%s/%s] [cd is %s was %s] [seconds is %s was %s]", spellName, one, two, three, spell.cooldown or "", self.afflictedSpells[spellIndex].cooldown or "", spell.seconds or "", self.afflictedSpells[spellIndex].seconds or ""))
	end
end