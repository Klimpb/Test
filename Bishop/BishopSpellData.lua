BishopData = {}

local L = BishopLocals

function BishopData:LoadDRUID()
	local spells = {
		[L["Lifebloom"]] = {
			[0] = { type = "ddhot", duration = 7, totalTicks = 7, maxStack = 3, dotFactor = 1.115 },
			[1] = { healed = 273, level = 64 },
		},
		[L["Rejuvenation"]] = {
			[0] = { type = "hot", totalTicks = 4, duration = 12, maxStack = 1 },
			[1] = { healed = 32, level = 4 },
			[2] = { healed = 56, level = 10 },
			[3] = { healed = 116, level = 16 },
			[4] = { healed = 180, level = 22 },
			[5] = { healed = 244, level = 28 },
			[6] = { healed = 304, level = 34 },
			[7] = { healed = 388, level = 40 },
			[8] = { healed = 488, level = 46 },
			[9] = { healed = 608, level = 52 },
			[10] = { healed = 756, level = 58 },
			[11] = { healed = 888, level = 60 },
			[12] = { healed = 932, level = 63 },
			[13] = { healed = 1060, level = 69 },
		},
		[L["Regrowth"]] = {
			[0] = { type = "ddhot", totalTicks = 7, maxStack = 1, duration = 21, hotFactor = 0.499 },
			[1] = { healed = 98, level = 12 },
			[2] = { healed = 175, level = 18 },
			[3] = { healed = 259, level = 24 },
			[4] = { healed = 343, level = 30 },
			[5] = { healed = 427, level = 36 },
			[6] = { healed = 546, level = 42 },
			[7] = { healed = 686, level = 48 },
			[8] = { healed = 861, level = 54 },
			[9] = { healed = 1064, level = 60 },
			[10] = { healed = 1274, level = 65 },
		},
	}
	local talents = {
		[L["Gift of Nature"]] = { mod = 0.02 },
		[L["Improved Rejuvenation"]] = { mod = 0.05, spell = L["Rejuvenation"] },
		[L["Empowered Rejuvenation"]] = { mod = 0.04, multi = true },
	}
	
	local idol = {
		[L["Rejuvenation"]] = {[25643] = 86, [22398] = 50},
		[L["Lifebloom"]] = {[27886] = 88}
	}
	
	return spells, talents, idol
end

function BishopData:LoadPRIEST()
	local spells = {
		[L["Renew"]] = {
			[0] = { type = "hot", duration = 15, totalTicks = 5, maxStack = 1 },
			[1] = { healed = 45, level = 8 },
			[2] = { healed = 100, level = 14 },
			[3] = { healed = 175, level = 20 },
			[4] = { healed = 245, level = 26 },
			[5] = { healed = 315, level = 32 },
			[6] = { healed = 400, level = 38 },
			[7] = { healed = 510, level = 44 },
			[8] = { healed = 650, level = 50 },
			[9] = { healed = 810, level = 56 },
			[10] = { healed = 970, level = 60 },
			[11] = { healed = 1010, level = 65 },
			[12] = { healed = 1110, level = 70 },
		},
	}
	local talents = {
		[L["Improved Renew"]] = { mod = 0.05, spell = L["Renew"] },
		[L["Spiritual Healing"]] = { mod = 0.02 },
	}
	
	return spells, talents
end