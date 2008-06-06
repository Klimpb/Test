PartyCCSpells = {}

local function addSpell(spellID)
	local name, rank, icon = GetSpellInfo(spellID)
	if( not name ) then
		return
	end
	
	PartyCCSpells[name] = icon
end

-- Sap
addSpell(11297)

-- Gouge
addSpell(38764)

-- Polymorph
addSpell(12826)

-- Fear (Warlock)
addSpell(6215)

-- Seduction (Pet)
addSpell(6358)

-- Howl of Terror
addSpell(17928)

-- Psychic scream
addSpell(10890)

-- Scare Beast
addSpell(14327)

-- Intimidating Shout
addSpell(5246)

-- Cheap Shot
addSpell(1833)

-- Blind
addSpell(2094)

-- Cyclone
addSpell(33786)

-- Scatter Shot
addSpell(19503)

-- Freezing Trap
addSpell(14309)

-- Death Coil
addSpell(27223)

-- Kidney Shot
addSpell(8643)

-- Hibernate
addSpell(18658)

-- Ent Roots
addSpell(26989)
