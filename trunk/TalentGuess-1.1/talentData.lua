local major = "TalentGuessData-1.1"
local minor = tonumber(string.match("$Revision: 55$", "(%d+)") or 1)

assert(LibStub, string.format("%s requires LibStub.", major))

local Data = LibStub:NewLibrary(major, minor)
if( not Data ) then return end

-- The format is pretty simple
-- [spellID] = "tree #:points required:checkBuffs:isCast"
Data.Spells = {
	-- DEATH KNIGHTS
	--[[ Blood ]]--
	-- Scent of Blood
	[50421] = "1:8",
	-- Rune Tap
	[48982] = "1:11:nil:true",
	-- Vendetta
	[50181] = "1:18",
	-- Mark of Blood
	[49005] = "1:21:nil:true",
	-- Bloody Vengeance
	[50447] = "1:26",
	[50448] = "1:27",
	[50449] = "1:28",
	-- Hysteria
	[49016] = "1:31:nil:true",
	-- Vampiric Blood
	[55233] = "1:36:nil:true",
	-- Heart Strike
	[55050] = "1:41:nil:true",
	[55258] = "1:41:nil:true",
	[55259] = "1:41:nil:true",
	[55260] = "1:41:nil:true",
	[55261] = "1:41:nil:true",
	[55262] = "1:41:nil:true",
	-- Dancing Rune Weapon
	[49028] = "1:51:nil:true",
	
	--[[ Frost ]]--
	-- Lichborne
	[49039] = "2:11:true",
	-- Killing Machine
	[51124] = "2:20",
	-- Howling Blast
	[49184] = "2:31:nil:true",
	[51408] = "2:31:nil:true",
	[51409] = "2:31:nil:true",
	[51410] = "2:31:nil:true",
	[51411] = "2:31:nil:true",
	-- Unbreakable Armor
	[51271] = "2:36:nil:true",
	-- Frost Strike
	[49143] = "2:41:nil:true",
	[51416] = "2:41:nil:true",
	[51417] = "2:41:nil:true",
	[51418] = "2:41:nil:true",
	[51419] = "2:41:nil:true",
	[55268] = "2:41:nil:true",
	-- Hungering Cold
	[49203] = "2:51:nil:true",
	
	--[[ Unholy ]]--
	-- Corpse Explosion
	[49158] = "3:11:nil:true",
	[51325] = "3:11:nil:true",
	[51326] = "3:11:nil:true",
	[51327] = "3:11:nil:true",
	[51328] = "3:11:nil:true",
	-- Blood-caked Strike
	[50463] = "3:18",
	-- Summon Gargoyle
	[49206] = "3:21:nil:true",
	-- Anti-Magic Zone
	[51052] = "3:31:nil:true",
	-- Bone Shield
	[49222] = "3:36:true",
	-- Night of the Dead
	[55744] = "3:36:true",
	[55621] = "3:37:true",
	-- Scourge Strike
	[55090] = "3:41:nil:true",
	[55265] = "3:41:nil:true",
	[55270] = "3:41:nil:true",
	[55271] = "3:41:nil:true",
	-- Unholy Blight
	[49194] = "3:51:nil:true",
	[51376] = "3:51:nil:true",
	[51378] = "3:51:nil:true",
	[51379] = "3:51:nil:true",

	-- ROGUES

	--[[ Assassination ]]--
	-- Remorseless Attacks
	[14143] = "1:1",
	[14149] = "1:2",
	-- Cold Blood
	[14177] = "1:21",
	-- Quick Recovery
	[31663] = "1:23",
	-- Focused Attacks
	[51637] = "1:38",
	-- Mutilate
	[1329] = "1:41",
	[34411] = "1:41",
	[34412] = "1:41",
	[34413] = "1:41",
	[48663] = "1:41",
	[48666] = "1:41",
	-- Hunger For Blood
	[51662] = "1:51",
	
	--[[ Combat ]]--
	-- Riposte
	[14251] = "2:11",
	-- Blade Flurry
	[13877] = "2:21",
	-- Adrenaline Rush
	[13750] = "2:31",
	-- Throwing Specialization
	[51680] = "2:37",
	-- Combat Potency
	[35542] = "2:36",
	[35545] = "2:37",
	[35546] = "2:38",
	[35547] = "2:39",
	[35548] = "2:40",
	-- Killing Spree
	[51690] = "2:51",

	--[[ Subtlety ]]--
	-- Relentless Strikes
	[14181] = "3:5",
	-- Ghostly Strike
	[14278] = "3:11",
	-- Hemorrhage
	[16511] = "3:21",
	[17347] = "3:21",
	[17348] = "3:21",
	[26864] = "3:21",
	[48660] = "3:21",
	-- Preparation
	[14185] = "3:21",
	-- Premedition
	[14183] = "3:31",
	-- Cheat Death
	[45182] = "3:33",
	-- Shadowstep
	[36554] = "3:41",
	-- Shadow Dance
	[51713] = "3:51",

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
	-- Feral Charge - Bear
	[16979] = "2:21",
	-- Feral Charge - Cat
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
	[33891] = "3:41:nil:true",
	-- Wild Growth
	[48438] = "3:51:nil:true",
	[53248] = "3:51:nil:true",
	[53249] = "3:51:nil:true",
	[53251] = "3:51:nil:true",
	
	-- HUNTERS
	
	--[[ Beast Mastery ]]--
	-- Improved Aspect of the Hawk
	[6150] = "1:5",
	-- Improved Mend Pet
	[24406] = "1:17",
	-- Intimidation
	[19577] = "1:21",
	-- Spirit Bond
	[19579] = "1:22:true",
	[24529] = "1:23:true",
	-- Beastial Wrath
	[19574] = "1:31",
	-- The Beast Within
	[34471] = "1:41",
	
	--[[ Marksmanship ]]--
	-- Aimed Shot
	[19434] = "2:11",
	[20900] = "2:11",
	[20901] = "2:11",
	[20902] = "2:11",
	[20903] = "2:11",
	[20904] = "2:11",
	[27065] = "2:11",
	[49049] = "2:11",
	[49050] = "2:11",
	-- Rapid Killing
	[35098] = "2:12",
	[35099] = "2:13",
	-- Readiness
	[23989] = "2:21",
	-- Silencing Shot
	[34490] = "2:41",
	-- Improved Steady Shot
	[53220] = "2:43",
	-- Chimera Shot
	[53209] = "2:51",
	
	--[[ Survival ]]--
	-- Scatter Shot
	[19503] = "3:11",
	-- Lock and Load
	[56453] = "3:18",
	-- Counterattack
	[19306] = "3:21",
	[20909] = "3:21",
	[20910] = "3:21",
	[27067] = "3:21",
	[48998] = "3:21",
	[48999] = "3:21",
	-- Wyvern Sting
	[19386] = "3:31",
	[24132] = "3:31",
	[24133] = "3:31",
	[27068] = "3:31",
	[49011] = "3:31",
	[49012] = "3:31",
	-- Explosive Shot
	[53301] = "3:51",
	
	-- MAGES
	
	--[[ Arcane ]]--
	-- Magic Absorption
	[29442] = "1:7",
	-- Clearcasting
	[12536] = "1:10",
	-- Focus Magic
	[54646] = "1:11:nil:true",
	-- Presence of Mind
	[12043] = "1:21",
	-- Improved Blink
	[46989] = "1:22",
	[47000] = "1:23",
	-- Arcane Power
	[12042] = "1:31",
	-- Incanter's Absorption
	[44413] = "1:33",
	-- Slow
	[31589] = "1:41",
	-- Missle Barrage
	[44401] = "1:45",
	-- Arcane Barrage
	[44425] = "1:51",
	[44780] = "1:51",
	[44781] = "1:51",
	
	--[[ Fire ]]--
	-- Burning Determination
	[54748] = "2:7",
	-- Master of Elements
	[29077] = "2:18",
	-- Blast Wave
	[11113] = "2:21",
	[13018] = "2:21",
	[13019] = "2:21",
	[13020] = "2:21",
	[13021] = "2:21",
	[27133] = "2:21",
	[33933] = "2:21",
	-- Blazing Speed
	[31643] = "2:27",
	-- Combustion
	[11129] = "2:31",
	-- Dragon's Breath
	[31661] = "2:41",
	[33041] = "2:41",
	[33042] = "2:41",
	[33043] = "2:41",
	[42949] = "2:41",
	[42950] = "2:41",
	-- Fire Starter
	[54741] = "2:43",
	-- Hot Streak
	[48108] = "2:43",
	-- Living Bomb
	[44457] = "2:51",
	[55359] = "2:51",
	[55360] = "2:51",

	--[[ Frost ]]--
	-- Icy Veins
	[12472] = "3:11",
	-- Cold Snap
	[11958] = "3:21",
	-- Ice Barrier
	[11426] = "3:31",
	[13031] = "3:31",
	[13032] = "3:31",
	[13033] = "3:31",
	[27134] = "3:31",
	[33405] = "3:31",
	[43038] = "3:31",
	[43039] = "3:31",
	-- Summon Water Element
	[31687] = "3:41",
	-- Deep Freeze
	[44572] = "3:51",
	
	-- PALADINS
	
	--[[ Holy ]]--
	-- Illumination
	[20272] = "1:15",
	-- Divine Favor
	[20216] = "1:21",
	-- Holy Shock
	[20473] = "1:31",
	[20929] = "1:31",
	[20930] = "1:31",
	[27174] = "1:31",
	[33072] = "1:31",
	[48824] = "1:31",
	[48825] = "1:31",
	-- Light's Grace
	[31834] = "1:33",
	-- Divine Illumination
	[31842] = "1:41",
	-- Judgement of the Pure
	[53655] = "1:46",
	[53656] = "1:47",
	[53657] = "1:48",
	[54152] = "1:49",
	[54153] = "1:50",
	-- Beacon of Light
	[53563] = "1:51",
	
	--[[ Protection ]]--
	-- Blessing of Kings
	[20217] = "2:1:nil:true",
	[25898] = "2:1:nil:true",
	-- Blessing of Sanctuary
	[20911] = "2:21:nil:true",
	[25899] = "2:21:nil:true",
	-- Reckoning
	[20178] = "2:25",
	-- Holy Shield
	[20925] = "2:31",
	[20927] = "2:31",
	[20928] = "2:31",
	[27179] = "2:31",
	[48951] = "2:31",
	[48952] = "2:31",
	-- Redoubt
	[20128] = "2:36",
	[20131] = "2:37",
	[20132] = "2:38",
	-- Avenger's Shield
	[31935] = "2:41",
	[32699] = "2:41",
	[32700] = "2:41",
	[48826] = "2:41",
	[48827] = "2:41",
	-- Hammer of the Righteous
	[53595] = "2:51",
	
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
	-- Matyrdom
	[14743] = "1:6",
	[27828] = "1:7",
	-- Inner Focus
	[14751] = "1:11",
	-- Divine Spirit
	[14752] = "1:21:nil:true",
	[14818] = "1:21:nil:true",
	[14819] = "1:21:nil:true",
	[27841] = "1:21:nil:true",
	[25312] = "1:21:nil:true",
	[48073] = "1:21:nil:true",
	-- Prayer of Spirit
	[27681] = "1:21:nil:true",
	[32999] = "1:21:nil:true",
	[48074] = "1:21:nil:true",
	-- Power Infusion
	[10060] = "1:31:nil:true",
	-- NTS: Find Rapture spellID
	-- Pain Suppression
	[33206] = "1:41:nil:true",
	-- Borrowed Time
	[59887] = "1:46",
	[59888] = "1:47",
	[59889] = "1:48",
	[59890] = "1:49",
	[59891] = "1:50",
	-- Penance
	[47540] = "1:51",
	[53005] = "1:51",
	[53006] = "1:51",
	[53007] = "1:51",
	
	--[[ Holy ]]--
	-- Blessed Recovery
	[27813] = "2:11",
	[27817] = "2:12",
	[27818] = "2:13",
	-- Desperate Prayer
	[19236] = "2:11",
	[19238] = "2:11",
	[19240] = "2:11",
	[19241] = "2:11",
	[19242] = "2:11",
	[19243] = "2:11",
	[25437] = "2:11",
	[48172] = "2:11",
	[48173] = "2:11",
	-- Spirit of Redemption
	[20711] = "2:21",
	-- Surge of Light
	[33151] = "2:27",
	-- Lightwell
	[724] = "2:31:nil:true",
	[27870] = "2:31:nil:true",
	[27871] = "2:31:nil:true",
	[28275] = "2:31:nil:true",
	[48086] = "2:31:nil:true",
	[48087] = "2:31:nil:true",
	-- Holy Concentration
	[34754] = "2:33",
	-- Circle of Healing
	[34861] = "2:41",
	[34863] = "2:41",
	[34864] = "2:41",
	[34865] = "2:41",
	[34866] = "2:41",
	[48088] = "2:41",
	[48089] = "2:41",	
	-- Improved Holy Concentration
	[47894] = "2:42",
	[47895] = "2:43",
	[47896] = "2:44",
	-- Guardian Spirit
	[47788] = "2:51:nil:true",
	
	--[[ Shadow ]]--
	-- Spirit Tap
	[15271] = "1:3",
	-- Improved Spirit Tap
	[49694] = "1:4",
	[59000] = "1:5",
	-- Mind Flay
	[15407] = "3:11",
	[17311] = "3:11",
	[17312] = "3:11",
	[17313] = "3:11",
	[17314] = "3:11",
	[18807] = "3:11",
	[25387] = "3:11",
	[48155] = "3:11",
	[48156]	= "3:11",
	-- Silence
	[15487] = "3:21",
	-- Vampiric Embrace
	[15286] = "3:21",
	-- Shadowform
	[15473] = "3:31:true",
	-- Vampiric Blood	
	[34914] = "3:41",
	[34916] = "3:41",
	[34917] = "3:41",
	[48159] = "3:41",
	[48160] = "3:41",
	-- Dispersion
	[47585] = "3:51",
	
	-- SHAMANS
	
	--[[ Elemental ]]--
	-- Elemental Devastation
	[30165] = "1:6",
	[29177] = "1:7",
	[29718] = "1:8",
	-- Clearcasting
	[16246] = "1:11",
	-- Elemental Mastery
	[16166] = "1:31",
	-- Totem of Wrath
	[30706] = "1:41",
	[57720] = "1:41",
	[57721] = "1:41",
	[57722] = "1:41",
	-- Astral Shift
	[52179] = "1:43",
	-- Thunderstorm
	[51490] = "1:51",
	[59156] = "1:51",
	[59158] = "1:51",
	[59159] = "1:51",
	
	--[[ Enhancement ]]--
	-- Flurry
	[16256] = "2:16",
	[16281] = "2:17",
	[16282] = "2:18",
	[16283] = "2:19",
	[16284] = "2:20",
	-- Stormstrike
	[32175] = "2:31",
	[32176] = "2:31",
	-- Shamanistic Rage
	[30823] = "2:41",
	-- Maelstrom Weapon
	[53817] = "2:50",
	-- Feral Spirit
	[51533] = "2:51",
	
	--[[ Resto ]]--
	-- Tidal Force
	[55198] = "3:11",
	-- Nature's Swiftness
	[16188] = "3:21",
	-- Mana Tide Totem
	[16190] = "3:31",
	-- Cleanse Spirit
	[51886] = "3:32",
	-- Nature's Guardian
	[31616] = "3:35",
	-- Earth Shield
	[974] = "3:41:nil:true",
	[32593] = "3:41:nil:true",
	[32594]	= "3:41:nil:true",
	[49283]	= "3:41:nil:true",
	[49284]	= "3:41:nil:true",
	-- Tidal Waves
	[53390] = "3:50",
	-- Riptide
	[61295] = "3:51:nil:true",
	[61299] = "3:51:nil:true",
	[61300] = "3:51:nil:true",
	[61301] = "3:51:nil:true",
	
	-- WARRIOR
	
	--[[ Arms ]]--
	-- Sweeping Strikes
	[12328] = "1:21",
	-- Mortal Strike
	[12294] = "1:31",
	[21551] = "1:31",
	[21552] = "1:31",
	[21553] = "1:31",
	[25248] = "1:31",
	[30330] = "1:31",
	[47485] = "1:31",
	[47486] = "1:31",
	-- Second Wind
	[29841] = "1:32",
	[29842] = "1:33",
	-- Wrecking Crew
	[57518] = "1:46",
	[57519] = "1:47",
	[57520] = "1:48",
	[57521] = "1:49",
	[57522] = "1:50",
	-- Bladestorm
	[46924] = "1:51",
	
	--[[ Fury ]]--
	-- Unbridled Wrath
	[12964] = "2:10",
	-- Piercing Howl
	[12323] = "2:11",
	-- Blood Craze
	[16488] = "2:11",
	[16490] = "2:12",
	[16491] = "2:13",
	-- Enrage
	[12317] = "2:16",
	[13045] = "2:17",
	[13046] = "2:18",
	[13047] = "2:19",
	[13048] = "2:20",
	-- Death Wish
	[12292] = "2:21",
	-- Improved Berserker Rage
	[23690] = "2:26",
	[23691] = "2:27",
	-- Flurry
	[12966] = "2:26",
	[12967] = "2:27",
	[12968] = "2:28",
	[12969] = "2:29",
	[12970] = "2:30",
	-- Bloodthirst
	[23881] = "2:31",
	-- Rampage
	[29801] = "2:41",
	-- Heroic Fury
	[60970] = "2:41",
	-- Bloodsurge
	[46916] = "2:43",

	--[[ Protection ]]--
	-- Shield Specialization
	[23602] = "3:5",
	-- Last Stand
	[12975] = "3:11",
	-- Concussion Blow
	[12809] = "3:21",
	-- Vigilance
	[50720] = "3:31:nil:true",
	-- Improved Defensive Stance
	[57514] = "3:32",
	[57516] = "3:33",
	-- Devastate
	[20243] = "3:41",
	[30016] = "3:41",
	[30022] = "3:41",
	[47497] = "3:41",
	[47498] = "3:41",
	-- Shockwave
	[46968] = "3:51",
	
	-- WARLOCKS
	
	--[[ Affliction ]]--
	-- Shadow Trance
	[17941] = "1:17",
	-- Siphon Life
	[18265] = "1:21",
	[18879] = "1:21",
	[18880] = "1:21",
	[18881] = "1:21",
	[27264] = "1:21",
	[30911] = "1:21",
	[47861] = "1:21",
	[47862] = "1:21",
	-- Curse of Exhuastion
	[18223] = "1:22",
	-- Dark Pact
	[18220] = "1:31",
	[18937] = "1:31",
	[18938] = "1:31",
	[27265] = "1:31",
	[59092] = "1:31",
	-- Eredication
	[47274] = "1:33",
	-- Unstable Affliction
	[30108] = "1:41",
	[30404] = "1:41",
	[30405] = "1:41",
	[47841] = "1:41",
	[47843] = "1:41",
	-- Haunt
	[48181] = "1:51",
	[59161] = "1:51",
	[59163] = "1:51",
	[59164] = "1:51",
	
	--[[ Demonology ]]--
	-- Soul Link
	[19028] = "2:11:true",
	-- Fel Domination
	[18708] = "2:11",
	-- Demonic Sacrifice
	[18788] = "2:21",
	-- Demonic Empowerment
	[47193] = "2:31",
	-- NTS: Figure out which Demonic Empathy spellID is for the Warlock
	-- Summon Felguard
	[30146] = "2:41",
	-- Metamorphosis
	[47241] = "2:51",
	
	--[[ Destruction ]]--
	-- Shadowburn
	[17877] = "3:11",
	[18867] = "3:11",
	[18868] = "3:11",
	[18869] = "3:11",
	[18870] = "3:11",
	[18871] = "3:11",
	[27263] = "3:11",
	[30546] = "3:11",
	[47826] = "3:11",
	[47827] = "3:11",
	-- Nether Protection
	[54370] = "3:27",
	[54371] = "3:27",
	[54372] = "3:27",
	[54373] = "3:27",
	[54374] = "3:27",
	[54375] = "3:27",
	-- Conflagrate
	[17962] = "3:31",
	[18930] = "3:31",
	[18931] = "3:31",
	[18932] = "3:31",
	[27266] = "3:31",
	[30912] = "3:31",
	[47828] = "3:31",
	[47829] = "3:31",
	-- Backlash
	[34935] = "3:33",
	[34938] = "3:33",
	[34939] = "3:33",
	-- Backdraft
	[54274] = "3:41",
	[54276] = "3:42",
	[54277] = "3:43",
	-- Shadowfury
	[30283] = "3:41",
	[30413] = "3:41",
	[30414] = "3:41",
	[47846] = "3:41",
	[47847] = "3:41",
	-- Chaos Bolt
	[50796] = "3:51",
	[59170] = "3:51",
	[59171] = "3:51",
	[59172] = "3:51",
}