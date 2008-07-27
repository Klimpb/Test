-- Basically how the format works is
-- one = First tree, two = Second tree, three = Third tree, cooldown = Seconds it should be if it doesn't match
-- For example with Blind, if it has over 17 points spent in tree 3 then use the regular duration, if they don't then use
-- the new cooldown of 180 seconds
AfflictedTalentsSpells = {
	-- Blind
	[2094] = {
		one = 0, two = 0, three = 17,
		cooldown = 180,
	},

	-- Vanish
	[1856] = 26889,
	[1857] = 26889,
	[26889] = {
		one = 0, two = 0, three = 17,
		cooldown = 300,
	},
	
	-- Sprint
	[2983] = 11305,
	[8696] = 11305,
	[11305] = {
		one = 0, two = 10, three = 0,
		cooldown = 300,
	},
	
	-- Vanish
	[5277] = 26669,
	[26669] = {
		one = 0, two = 10, three = 0,
		cooldown = 300,
	},
	
	-- Frost Nova
	[122] = 27088,
	[865] = 27088,
	[6131] = 27088,
	[10230] = 27088,
	[27088] = {
		one = 0, two = 0, three = 7,
		cooldown = 25,
	},
	
	-- Hammer of Justice
	[853] = 10308,
	[5588] = 10308,
	[5589] = 10308,
	[10308] = {
		one = 0, two = 18, three = 0,
		cooldown = 60,
	},
	
	-- Blessing of Protection
	[1022] = 10278,
	[5599] = 10278,
	[10278] = {	
		one = 0, two = 7, three = 0,
		cooldown = 300,
	},
	
	-- Blessing of Freedom
	[1044] = {
		one = 0, two = 7, three = 0,
		seconds = 10,
	},
	
	-- Psychic Scream
	[8122] = 10890,
	[8124] = 10890,
	[10888] = 10890,
	[10890] = {
		one = 0, two = 0, three = 12,
		cooldown = 27,
	},
	
	-- Flame Shock
	[8050] = 25454,
	[8052] = 25454,
	[8053] = 25454,
	[10447] = 25454,
	[10448] = 25454,
	[10448] = 25454,
	[25457] = 25454,
	[29228] = 25454,
	
	-- Frost shock
	[8056] = 25454,
	[8058] = 25454,
	[10472] = 25454,
	[10473] = 25454,
	[25464] = 25454,
	
	-- Earth shock
	[8042] = 25454,
	[8044] = 25454,
	[8045] = 25454,
	[10412] = 25454,
	[10413] = 25454,
	[10414] = 25454,
	[25454] = {
		one = 15, two = 0, three = 0,
		cooldown = 6,
	},
	
	-- Intercept
	[20252] = 25275,
	[20616] = 25275,
	[20617] = 25275,
	[25272] = 25275,
	[25275] = {
		one = 27, two = 0, three = 0,
		cooldown = 25,
	},	
}