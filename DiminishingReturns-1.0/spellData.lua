local major = "DRData-1.0"
local minor = tonumber(string.match("$Revision: 703$", "(%d+)") or 1)

assert(LibStub, string.format("%s requires LibStub.", major))

local Data = LibStub:NewLibrary(major, minor)
if( not Data ) then return end

Data.Spells = {
	--[[ DISORIENTS ]]--
	-- Maim
	[22570] = "disorient",

	-- Sap
	[6770] = "disorient",
	[2070] = "disorient",
	[11297] = "disorient",
	
	-- Gouge
	[1776] = "disorient",
	[1777] = "disorient",
	[8629] = "disorient",
	[11285] = "disorient",
	[11286] = "disorient",
	[38764] = "disorient",
		
	-- Polymorph
	[118] = "disorient",
	[12824] = "disorient",
	[12825] = "disorient",
	[28272] = "disorient",
	[28271] = "disorient",
	[12826] = "disorient",

	--[[ FEARS ]]--
	-- Fear (Warlock)
	[5782] = "fear",
	[6213] = "fear",
	[6215] = "fear",
	
	-- Seduction (Pet)
	[6358] = "fear",
	
	-- Howl of Terror
	[5484] = "fear",
	[17928] = "fear",

	-- Psychic scream
	[8122] = "fear",
	[8124] = "fear",
	[10888] = "fear",
	[10890] = "fear",
	
	-- Scare Beast
	[1513] = "fear",
	[14326] = "fear",
	[14327] = "fear",
	
	-- Intimidating Shout
	[5246] = "fear",
			
	--[[ CONTROL STUNS ]]--
	-- Hammer of Justice
	[853] = "ctrlstun",
	[5588] = "ctrlstun",
	[5589] = "ctrlstun",
	[10308] = "ctrlstun",

	-- Bash
	[5211] = "ctrlstun",
	[6798] = "ctrlstun",
	[8983] = "ctrlstun",
	
	-- Pounce
	[9005] = "ctrlstun",
	[9823] = "ctrlstun",
	[9827] = "ctrlstun",
	[27006] = "ctrlstun",
	
	-- Intimidation
	[19577] = "ctrlstun",

	-- Charge
	[7922] = "ctrlstun",

	-- Cheap Shot
	[1833] = "ctrlstun",

	-- War Stomp
	[20549] = "ctrlstun",

	-- Intercept
	[20253] = "ctrlstun",
	[20614] = "ctrlstun",
	[20615] = "ctrlstun",
	[25273] = "ctrlstun",
	[25274] = "ctrlstun",
	
	-- Shadowfury
	[30283] = "ctrlstun", 
	[30413] = "ctrlstun",
	[30414] = "ctrlstun",
	
	--[[ RANDOM STUNS ]]--
	-- Starfire Stun
	[16922] = "rndstun",
	
	-- Mace Stun
	[5530] = "rndstun",
	
	-- Stormherald/Deep Thunder
	[34510] = "rndstun",
	
	-- Seal of Justice
	[20170] = "rndstun",
	
	-- Blackout
	[15269] = "rndstun",
	
	-- Impact
	[12355] = "rndstun",
	
	--[[ CYCLONE ]]--
	-- Blind
	[2094] = "cyclone",
	
	-- Cyclone
	[33786] = "cyclone",
	
	--[[ ROOTS ]]--
	-- Freeze (Water Elemental)
	[33395] = "root",
	
	-- Frost Nova
	[122] = "root",
	[865] = "root",
	[6131] = "root",
	[10230] = "root",
	[27088] = "root",
	
	-- Entangling Roots
	[339] = "root",
	[1062] = "root",
	[5195] = "root",
	[5196] = "root",
	[9852] = "root",
	[9853] = "root",
	[26989] = "root",

	--[[ MISC ]]--
	-- Chastise (Maybe this shares DR with Imp HS?)
	[44041] = "chastise",
	[44043] = "chastise",
	[44044] = "chastise",
	[44045] = "chastise",
	[44046] = "chastise",
	[44047] = "chastise",

	-- Scatter Shot
	[19503] = "scatters",
	
	-- Freezing Trap
	[3355] = "freezetrap",
	[14308] = "freezetrap",
	[14309] = "freezetrap",
	
	-- Improved Conc Shot
	[19410] = "impconc",
	[22915] = "impconc",
	[28445] = "impconc",
	
	-- Death Coil
	[6789] = "dc",
	[17925] = "dc",
	[17926] = "dc",
	[27223] = "dc",

	-- Kidney Shot
	[408] = "ks",
	[8643] = "ks",

	-- Improved Hamstring
	[23694] = "imphs",
		
	-- Hibernate
	[2637] = "hibernate",
	[18657] = "hibernate",
	[18658] = "hibernate",
}

-- DR Category names
Data.TypeNames = {
	["disorient"] = "Disorients",
	["fear"] = "Fears",
	["ctrlstun"] = "Control Stuns",
	["rndstun"] = "Random Stuns",
	["cyclone"] = "Cyclone/Blind",
	["ks"] = "Kidney Shot",
	["imphs"] = "Imp Hamstring",
	["chastise"] = "Chastise",
	["scatters"] = "Scatter Shot",
	["freezetrap"] = "Freeze Trap",
	["dc"] = "Death Coil",
	["hibernate"] = "Hibernate",
	["root"] = "Roots",
	["impconc"] = "Imp Concussive Shot",
}