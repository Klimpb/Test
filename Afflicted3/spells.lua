local AfflictedSpells = {}

function AfflictedSpells:GetCacheVersion()
	--return tonumber(string.match("$Revision: 1131 $", "(%d+)") or 1)
	return GetTime()
end

function AfflictedSpells:GetData()
	if( self.spells ) then
		return self.spells
	end
	
	self.spells = {
		-- Death Knight
		-- Strangulate
		[47476] = "cooldown:120;cdAnchor:interrupts",
		-- Empower Rune Weapon
		[47568] = "cooldown:300;cdAnchor:spells",
		-- Icebound Fortitude
		[48792] = "duration:12;cooldown:60;anchor:defenses;cdAnchor:cooldowns",
		-- Mind Freeze
		[47528] = "cooldown:10;cdAnchor:interrupts",
		-- Anti-Magic Shell
		[48707] = "type:buff;duration:5;cooldown:45;anchor:defenses;cdAnchor:cooldowns",
		-- Death Grip
		[49576] = "cooldown:35;cdAnchor:spells",
		-- Anti-Magic Zone
		[51052] = "duration:10;anchor:defenses;cooldown:120;cdAnchor:cooldowns",
		-- Dancing Rune Weapon
		[49028] = "duration:14;anchor:damage;cooldown:90;cdAnchor:cooldowns",
		-- Deathchill
		[49796] = "type:buff;duration:30;anchor:damage;cooldown:120;cdAnchor:cooldowns",
		-- Hysteria
		[49016] = "type:buff;duration:30;anchor:damage;cooldown:180;cdAnchor:cooldowns",
		-- Lichborne
		[49039] = "duration:15;anchor:defenses;cooldown:180;cdAnchor:cooldowns",
		-- Rune Tap
		[48982] = "cooldown:30;cdAnchor:spells",
		-- Vampiric Blood
		[55233] = "duration:20;anchor:defenses;cooldown:120;cdAnchor:cooldowns",
		
		
		-- Paladin
		-- Exorcism
		[27138] = 48801,
		[48800] = 48801,
		[48801] = "cooldown:15;cdAnchor:interrupts",
		-- Divine Plea
		[54428] = "type:buff;duration:15;anchor:buffs;cooldown:60;cdAnchor:cooldowns",
		-- Avenging Wrath
		[31884] = "duration:20;anchor:damage;cooldown:120;cdAnchor:cooldowns",
		-- Hammer of Justice
		[10308] = "cooldown:40;cdAnchor:cooldowns",
		-- Hand of Protection
		[10278] = "type:buff;duration:10;anchor:defenses;cooldown:180;cdanchor:cooldowns",
		-- Divine Shield
		[642] = "type:buff;duration:12;anchor:defenses;cooldown:300;cdAnchor:cooldowns",
		-- Hand of Freedom
		[1044] = "type:buff;duration:14;anchor:spells;cooldown:25;cdAnchor:cooldowns"
		-- Divine Protection
		[498] = "type:buff;duration:12;anchor:defenses;cooldown:180;cdAnchor:cooldowns",
		-- Hand of Sacrifice
		[6940] = "type:buff;duration:12;anchor:defenses;cooldown:120;cdAnchor:cooldowns",
		-- Aura Mastery
		[31821] = "duration:10;anchor:defenses;cooldown:120;cdAnchor:cooldowns",
		-- Divine Sacrifice
		[64205] = "duration:10;anchor:defenses;cooldown:120;cdAnchor:cooldowns",
		
		-- Warrior
		-- Shattering Throw
		[64382] = "cooldown:300;cdAnchor:damage",
		-- Intervene
		[3411] = "cooldown:30;cdAnchor:defenses",
		-- Recklessness
		[1719] = "duration:12;anchor:damage;cooldown:300;cdAnchor:cooldowns",
		-- Charge
		[11578] = "cooldown:15;cdAnchor:spells",
		-- Berserker Rage
		[18499] = "duration:10;anchor:spells;cooldown:30;cdAnchor:cooldowns",
		-- Intercept
		[20252] = "cooldown:15;cdAnchor:spells",
		-- Shield Wall
		[871] = "duration:12;anchor:defenses;cooldown:300;cdAnchor:cooldowns",
		-- Intimidating Shout
		[5246] = "cooldown:120;cdAnchor:spells",
		-- Retaliation (dumbasses)
		[20230] = "type:buff;duration:12;cooldown:300",
		-- Disarm
		[676] = "cooldown:60;cdAnchor:spells",
		
		-- Druid
		-- Survival Instincts
		[61336] = "duration:20;anchor:defenses;cooldown:300;cdAnchor:cooldowns",
		-- Force of Nature (Treants)
		[33831] = "duration:30;anchor:damage;cooldown:180;cdAnchor:cooldowns",
		-- Berserk
		[50334] = "duration:15;anchor:damage;cooldown:180;cdAnchor:cooldowns",
		-- Tiger's fury
		[9846] = 50212,
		[50212] = "cooldown:30;cdAnchor:damage",
		-- Nature's Grasp
		[17329] = 53312,
		[27009] = 27009,
		[53312] = "duration:45;anchor:buffs;cooldown:60;cdAnchor:cooldowns",
		-- Innervate
		[29166] = "duration:20;anchor:buffs;cooldown:360;cdAnchor:cooldowns",
		-- Frenzied Regeneration
		[22842] = "duration:10;anchor:defenses;cooldown:180;cdAnchor:cooldowns",
		-- Feral Charge - Bear
		[16979] = "cooldown:15;cdAnchor:interrupts",
		-- Feral Charge - Cat
		[49376] = "cooldown:30;cdAnchor:spells",
		-- Bash
		[8983] = "cooldown:30;cdAnchor:interrupts",
		
		-- Priest
		
		-- Warlock
		
		-- Shaman
		
		-- Hunter
		
		-- Mage
		
		-- Rogue
	}
	
	return self.spells
end