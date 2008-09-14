if( not IS_WRATH_BUILD ) then return end

local major = "TalentGuessData-1.0"
local minor = tonumber(string.match("$Revision: 703$", "(%d+)") or 1)

assert(LibStub, string.format("%s requires LibStub.", major))

local Data = LibStub:NewLibrary(major, minor)
if( not Data ) then return end

-- The format is pretty simple
-- [spellID] = "tree #:points required:checkBuffs:isCastOnly"
Data.Spells = {
	-- ROGUES

	--[[ Assassination ]]--
	
	--[[ Combat ]]--

	--[[ Subtlety ]]--

	--[[ DRUIDS ]]
	
	--[[ Balance ]]--
	-- Nature's Grace
	[16886] = "1:11:true",
	-- Insect Swarm
	[5570] = "1:21",
	[24974] = "1:21",
	[24975] = "1:21",
	[24976] = "1:21",
	[24977] = "1:21",
	[27013] = "1:21",
	[48468] = "1:21",
	-- Moonkin Form
	[24858] = "1:31:true",
	-- Owlkin Frenzy
	[48391] = "1:38",
	-- Typhoon
	[50516] = "1:41",
	[53223] = "1:41",
	[53225] = "1:41",
	[53226] = "1:41",
	[53227] = "1:41",
	-- Treants
	[33831] = "1:41",
	-- Eclipse
	[48517] = "1:43",
	[48518] = "1:43",
	-- Starfall
	[48505] = "1:51",
	[53199] = "1:51",
	[53200] = "1:51",
	[53201] = "1:51",
	
	--[[ Feral ]]--
	-- Faerie Fire
	[16857] = "2:11",
	[17390] = "2:11",
	[17391] = "2:11",
	[17392] = "2:11",
	[27011] = "2:11",
	[48475] = "2:11",
	-- Primal Fury
	[16959] = "2:17",	
	[16953] = "2:17",
	-- Feral Charge
	[16979] = "2:21",
	[49376] = "2:21",
	-- Mangle (Cat/Bear)
	[33878] = "2:41",
	[33986] = "2:41",
	[33987] = "2:41",
	[48563] = "2:41",
	[48564] = "2:41",
	[33876] = "2:41",
	[33982] = "2:41",
	[33983] = "2:41",
	[48565] = "2:41",
	[48566] = "2:41",
	-- Berserk
	[50334] = "2:51",
	
	--[[ Resto ]]--
	-- Omen of Clarity
	[16870] = "3:11",
	-- Master Shapeshifter
	[48418] = "3:13",
	[48420] = "3:13",
	[48421] = "3:13",
	[48422] = "3:13",
	-- Nature's Swiftness
	[17116] = "3:21",
	-- Swiftmend
	[18562] = "3:31",
	-- Natural Perfection
	[45281] = "3:32:true",
	[45282] = "3:33:true",
	[45283] = "3:34:true",
	-- Tree of Life
	[33891] = "3:41",
	-- Flourish
	[48438] = "3:51",
	[53248] = "3:51",
	[53249] = "3:51",
	[53251] = "3:51",
	
	-- HUNTERS
	
	--[[ Beast Mastery ]]--
		
	--[[ Marksmanship ]]--
	
	--[[ Survival ]]--
	
	-- MAGES
	
	--[[ Arcane ]]--
	
	--[[ Fire ]]--

	--[[ Frost ]]--
	
	-- PALADINS
	
	--[[ Holy ]]--
	
	--[[ Protection ]]--
	
	--[[ Retribution ]]--
	-- Seal of command
	[20375] = "3:11",
	[20050] = "3:26",
	[20052] = "3:27",
	[20053] = "3:28",
	-- Repentance
	[20066] = "3:31",
	-- The Art of War
	[53489] = "3:33",
	-- Crusader Strike
	[35395] = "3:41",
	-- Divine Storm
	[53385] = "3:51",
	
	
	-- PRIESTS
	
	--[[ Disc ]]--
	
	--[[ Holy ]]--
	
	--[[ Shadow ]]--
	
	-- SHAMANS
	
	--[[ Elemental ]]--
	
	--[[ Enhancement ]]--
	
	--[[ Resto ]]--
	
	-- WARRIOR
	
	--[[ Arms ]]--
	
	--[[ Fury ]]--
	
	--[[ Protection ]]--
	
	-- WARLOCKS
	
	--[[ Affliction ]]--

	--[[ Demon ]]--
	
	--[[ Destro ]]--
}