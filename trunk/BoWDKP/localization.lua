BWDKPVersion = "1.1.1";

------------
-- ENGLISH
------------

BWD_RAID_ENDED = "Finished raid '%s', data has been saved.";
BWD_RAID_STARTED = "Started new raid '%s', with a point factor of %d%%.";
BWD_RAID_ALREADYOPEN = "You currently have a raid named '%s' open, you need to close it before you can start another.";

BWD_RAID_SAVED = "Saved the data for raid '%s', you will need to end it still, you cannot upload the current data until the raid has been ended with /dkp end.";
BWD_CLEARED_DATA = "All saved raid data has been removed.";

BWD_ADDED_TO_SIT = "Added %s to sit for %s.";

BWD_RAID_NONEOPEN = "You must have a raid open to perform this action.";

BWD_DATA_SAVED = "Saved all raid/loot/sit data.";
BWD_DATA_CLEARED = "Cleared all saved data.";

--[[
BWR_DRAENEI = "Draenei";
BWR_BLOODELF = "Blood Elf";

-- Race to turn Dreanei into
BWR_HUMAN = "Human";

-- Race to turn BE's into
BWR_UNDEAD = "Undead";
]]

BWD_ANNOUNCE = "Announce";
BWD_LASTCALL = "Last Call";
BWD_ROT = "Rot";
BWD_DE = "DE";
BWD_AWARD = "Award";

BWD_TBA = "TBA";
BWD_LOOT_ANNOUNCE = "Tells %s (%s)";
BWD_LOOT_LASTCALL = "LAST CALL %s (%s)";
BWD_LOOT_ROT = "ROT %s (%s)";
BWD_LOOT_DE = "DE %s";
BWD_LOOT_WON = "%s %s (%s)";

BWD_YOU_REC_LOOT = "You receive loot";
BWD_OTHER_REC_LOOT = "(.+) receives loot";

BWD_ITEM_CONFIRMED = "%s has confirmed his item choice as %s.";

BWD_PRECORD_EXISTS = "%s already has a record, you cannot add another one.";
BWD_ADDED_RECORD = "Added %s (%s start minutes) to sit for raid %s.";
BWD_NORECORD_FOUND = "No record found for %s, nothing to delete.";
BWD_DELETED_RECORD = "Deleted sit and raid attendance for %s in the raid %s.";
BWD_ADDED_ITEM = "Added item %s looted by %s for raid %s.";
BWD_DELETED_ITEM = "Deleted item %s for %s.";
BWD_ITEM_NOLOOT = "No items have been recorded as looted for raid %s.";

BWD_NO = "No";
BWD_YES = "Yes";
BWD_ITEM_LIST = "%s: %s, waiting type response? %s";

BWD_SIT_LIST = "%s, time in sit %s, is offline? %s.";
BWD_NO_SIT = "No people are on sit for the raid %s.";

BWD_RAID_RUNNING = "WARNING: The raid %s is currently opened and hasn't been closed, you will need to type /dkp end to finish this raid.";
BWD_LOOT_NO_CLASS = "WARNING: Cannot find %s class, the item %s has NOT been recorded as looted.";
BWD_LOOT_NO_SET = "WARNING: Cannot find set piece %s that %s won, the item has NOT been recorded as looted.";
BWD_LOOT_NO_TYPE = "WARNING: Cannot find item type for %s that %s won, the item has NOT been recorded as looted.";
BWD_FRIENDS_FULL = "WARNING: Your friends list has hit the maximum of %d people, you will not be able to track anybody that isn't guilded on sit.";
BWD_FRIENDS_ALMOSTFULL = "WARNING: Your friends list is almost full, you currently are using %d of %d slots, when you hit the limit you will no longer be able to track unguilded players on sit.";

-- Whisper triggers
BWD_SIT = "sit";
BWD_RAIDSTATUS = "rs";

-- Whisper responses
BWD_PREFIX = "<BoWDKP> ";
BWD_REQUEST_TYPE = BWD_PREFIX .. "The item you won %s can be turned into %s different items, you will need to whisper back one of the following %s to log which one you want.";
BWD_REQUEST_NOTE = BWD_PREFIX .. "NOTE: If you do not respond with a type it will default to %s.";
BWD_ADDED_SIT = BWD_PREFIX .. "You have been added to the raid %s.";
BWD_ALREADY_SAT = BWD_PREFIX .. "You are currently sat, you cannot be added again.";
BWD_NO_RAID_OPEN = BWD_PREFIX .. "No raid is currently open.";
BWD_WHISPER_ITEMCONFIRMED = BWD_PREFIX .. "You have confirmed that you want %s (%s).";
BWD_WHISPER_NORECORD = BWD_PREFIX .. "No pending item choices found.";
BWD_WHISPER_RAIDSTATUS = BWD_PREFIX .. "Currently the raid has %d of %d players inside for raid %s.";
BWD_WHISPER_NOSIT = BWD_PREFIX .. "You are not currently on sit for the raid %s.";
BWD_WHISPER_REMOVEDSIT = BWD_PREFIX .. "You have been removed from sit for the %s, any attendance you have gained up to now is still saved.";

-- Help
BWD_HELP_COMMANDS = {};
table.insert( BWD_HELP_COMMANDS, "/dkp start <name> <factor> - Starts a new raid using the name and factor, if no factor is specified then it'll default to 100." );
table.insert( BWD_HELP_COMMANDS, "/dkp end - Ends a raid, will perform a ReloadUI to save the data." );
table.insert( BWD_HELP_COMMANDS, "/dkp clear - Clears all saved raid data" );
table.insert( BWD_HELP_COMMANDS, "/dkp padd <name> <minutes> - Adds a player to sit, minutes is how many minutes to start them with, if they are already on sit ( or in the raid ) it'll do nothing." );
table.insert( BWD_HELP_COMMANDS, "/dkp pdel <name> - Removes a player from sit or from the raid attendance" );
table.insert( BWD_HELP_COMMANDS, "/dkp iadd <name> <item> - Adds an item looted for the specified player, item name MUST be in text and cannot be an item link." );
table.insert( BWD_HELP_COMMANDS, "/dkp idel <name> <item> - Removes an item looted for the specified player, If no item is entered it deletes all items looted by a specific player, item name MUST be in text and cannot be an item link." );
table.insert( BWD_HELP_COMMANDS, "/dkp list <sit/loot> - Lists data from the open raid." );
table.insert( BWD_HELP_COMMANDS, "/dkp help - Displays a list of slash commands" );

--[[
 The format is a bit confusing for how this works, basically.
 BWD_ITEM_SETS is the set name, class and the tier, if the item has a special format
 like fucking priests, then you can use %item for the items name and %set for the set name
 by default %set %item is used. Tier is just used as a "key" to match an item to it's set.
 
 BWD_QUEST_ITEMS are items that can be turned into multiple sets, or used for multiple classes.
 Tier is used to match up with the set from BWD_ITEM_SETS
 
 If you specify ALL as a type then regardless of the class who loots it is the item, for example
 if a Druid loots Desecrated Headpiece then because the type for ALL is Headpiece it'll turn into
 Dreamwalker Headpiece.
 
 For items that have different names like AQ40 pieces you can use the class as a key, for example ROGUE = "Leggings" and WARRIOR = "Legguard"
 will turn into Deathdealer's Leggings for Rogues that loot it, and Conqueror's Legguards for Warriors
 
 However, for items like AQ40 Shoulder/Boots those are more complicated, first off IsMulti = true and Default = "<whatever>"
 need to be specified, Default is the item taht it should default to if the winner doesn't respond to the whisper asking for one.
 
 The format for using type changes if it's a multi item, the key is what item type it's for, so an example is
 shoulder = { ROGUE = "Spaulders", PRIEST = "Shoulderpads" }, boot = { ROGUE = "Boots", PRIEST = "Footwraps" }
 
 when a Rogue wins they'll be asked "Do you want the shoulder or boot? Please respond with "shoulder" or "boot" to choose,
 you'll be defaulted to "shoulder" if you don't respond"
 if the Rogue responds with boots when they go down as looting Deathdealer's Boots, if they choose shoulders then
 Deathdealer's Spaulders. You can still use the ALL type instead of listing all the classes
]]

-- Sets that are from items like Desecrated Headpiece off of bosses
BWD_ITEM_SETS = {};

-- T5, Lots of places
table.insert( BWD_ITEM_SETS, { class = "DRUID", tier = "4", set = "Malorne", Format = "%item of %set" } );
table.insert( BWD_ITEM_SETS, { class = "HUNTER", tier = "4", set = "Demon Stalker" } );
table.insert( BWD_ITEM_SETS, { class = "PALADIN", tier = "4", set = "Justicar" } );
table.insert( BWD_ITEM_SETS, { class = "SHAMAN", tier = "4", set = "Cyclone" } );
table.insert( BWD_ITEM_SETS, { class = "MAGE", tier = "4", set = "Aldor", Format = "%item of the %set" } );
table.insert( BWD_ITEM_SETS, { class = "WARLOCK", tier = "4", set = "Voidheart" } );
table.insert( BWD_ITEM_SETS, { class = "PRIEST", tier = "4", set = "Incarnate", Format = "%item of the %set" } );
table.insert( BWD_ITEM_SETS, { class = "WARRIOR", tier = "4", set = "Warbringer" } );	
table.insert( BWD_ITEM_SETS, { class = "ROGUE", tier = "4", set = "Netherblade" } );

-- T4, Karazhan
table.insert( BWD_ITEM_SETS, { class = "DRUID", tier = "4", set = "Nordrassil" } );
table.insert( BWD_ITEM_SETS, { class = "HUNTER", tier = "4", set = "Rift Stalker" } );
table.insert( BWD_ITEM_SETS, { class = "PALADIN", tier = "4", set = "Crystalforge" } );
table.insert( BWD_ITEM_SETS, { class = "SHAMAN", tier = "4", set = "Cataclysm", Format = "%item of %set" } );
table.insert( BWD_ITEM_SETS, { class = "MAGE", tier = "4", set = "Tirisfal" } );
table.insert( BWD_ITEM_SETS, { class = "WARLOCK", tier = "4", set = "Corruptor", Format = "%item of the %set" } );
table.insert( BWD_ITEM_SETS, { class = "PRIEST", tier = "4", set = "Avatar", Format = "%item of the %set" } );
table.insert( BWD_ITEM_SETS, { class = "WARRIOR", tier = "4", set = "Destroyer" } );	
table.insert( BWD_ITEM_SETS, { class = "ROGUE", tier = "4", set = "Deathmantle" } );

-- T3, Naxxramas
table.insert( BWD_ITEM_SETS, { class = "DRUID", tier = "3", set = "Dreamwalker" } );
table.insert( BWD_ITEM_SETS, { class = "HUNTER", tier = "3", set = "Cryptstalker" } );
table.insert( BWD_ITEM_SETS, { class = "PALADIN", tier = "3", set = "Redemption" } );
table.insert( BWD_ITEM_SETS, { class = "SHAMAN", tier = "3", set = "Earthshatter" } );
table.insert( BWD_ITEM_SETS, { class = "MAGE", tier = "3", set = "Frostfire" } );
table.insert( BWD_ITEM_SETS, { class = "WARLOCK", tier = "3", set = "Plagueheart" } );
table.insert( BWD_ITEM_SETS, { class = "PRIEST", tier = "3", set = "Faith", Format = "%item of %set" } );
table.insert( BWD_ITEM_SETS, { class = "WARRIOR", tier = "3", set = "Dreadnaught" } );	
table.insert( BWD_ITEM_SETS, { class = "ROGUE", tier = "3", set = "Bonescythe" } );

-- T2.5, Ahn'Qiraj 40
table.insert( BWD_ITEM_SETS, { class = "DRUID", tier = "2.5", set = "Genesis" } );
table.insert( BWD_ITEM_SETS, { class = "HUNTER", tier = "2.5", set = "Striker's" } );
table.insert( BWD_ITEM_SETS, { class = "PALADIN", tier = "2.5", set = "Avenger's" } );
table.insert( BWD_ITEM_SETS, { class = "SHAMAN", tier = "2.5", set = "Stormcaller's" } );
table.insert( BWD_ITEM_SETS, { class = "MAGE", tier = "2.5", set = "Engima" } );
table.insert( BWD_ITEM_SETS, { class = "WARLOCK", tier = "2.5", set = "Doomcaller's" } );
table.insert( BWD_ITEM_SETS, { class = "PRIEST", tier = "2.5", set = "Oracle", Format = "%item of the %set" } );
table.insert( BWD_ITEM_SETS, { class = "WARRIOR", tier = "2.5", set = "Conqueror's" } );
table.insert( BWD_ITEM_SETS, { class = "ROGUE", tier = "2.5", set = "Deathdealer's" } );

-- List of whisper triggers to check for if the item can be turned into multiple types (must be lower case)
BWD_WHISPER_TYPES = { "shoulder", "boot" };

-- The actual piece that needs to be converted
BWD_QUEST_ITEMS = {};

-- T5, Lots of places
table.insert( BWD_QUEST_ITEMS, { item = "Leggings of the Fallen Defender", tier = "5", type = { DRUID = "Legguards", PRIEST = "Trousers", WARRIOR = "Legguards" } } );
table.insert( BWD_QUEST_ITEMS, { item = "Leggings of the Fallen Champion", tier = "5", type = { SHAMAN = "Kilt", PALADIN = "Leggings", ROGUE = "Breeches" } } );
table.insert( BWD_QUEST_ITEMS, { item = "Leggings of the Fallen Hero", tier = "5", type = { HUNTER = "Greaves", MAGE = "Legwraps", WARLOCK = "Leggings" } } );

table.insert( BWD_QUEST_ITEMS, { item = "Pauldrons of the Fallen Defender", tier = "5", type = { PRIEST = "Light-Mantle", DRUID = "Shoulderguards", WARRIOR = "Shoulderguards" } } );
table.insert( BWD_QUEST_ITEMS, { item = "Pauldrons of the Fallen Champion", tier = "5", type = { SHAMAN = "Shoulderpads", PALADIN = "Pauldrons", ROGUE = "Shoulderpads" } } );
table.insert( BWD_QUEST_ITEMS, { item = "Pauldrons of the Fallen Hero", tier = "5", type = { HUNTER = "Shoulderguards", MAGE = "Pauldrons", WARLOCK = "Mantle" } } );

table.insert( BWD_QUEST_ITEMS, { item = "Helm of the Fallen Defender", tier = "5", type = { DRUID = "Crown", PRIEST = "Light-Collar", WARRIOR = "Greathelm" } } );
table.insert( BWD_QUEST_ITEMS, { item = "Helm of the Fallen Champion", tier = "5", type = { SHAMAN = "Headdress", PALADIN = "Diadem", ROGUE = "Facemask" } } );
table.insert( BWD_QUEST_ITEMS, { item = "Helm of the Fallen Hero", tier = "5", type = { MAGE = "Collar", HUNTER = "Greathelm", WARLOCK = "Crown" } } );

table.insert( BWD_QUEST_ITEMS, { item = "Gloves of the Fallen Defender", tier = "5", type = { DRUID = "Handguards", PRIEST = "Handwraps", WARRIOR = "Handguards" } } );
table.insert( BWD_QUEST_ITEMS, { item = "Gloves of the Fallen Champion", tier = "5", type = { ALL = "Gloves" } } );
table.insert( BWD_QUEST_ITEMS, { item = "Gloves of the Fallen Hero", tier = "5", type = { HUNTER = "Gauntlets", MAGE = "Gloves", WARLOCK = "Gloves" } } );

table.insert( BWD_QUEST_ITEMS, { item = "Chestguard of the Fallen Defender", tier = "5", type = { DRUID = "Malorne", PRIEST = "Robes", WARRIOR = "Chestguard" } } );
table.insert( BWD_QUEST_ITEMS, { item = "Chestguard of the Fallen Champion", tier = "5", type = { SHAMAN = "Hauberk", PALADIN = "Chestpiece", ROGUE = "Chestpiece" } } );
table.insert( BWD_QUEST_ITEMS, { item = "Chestguard of the Fallen Hero", tier = "5", type = { HUNTER = "Harness", MAGE = "Vestments", WARLOCK = "Robe" } } );

-- T4, Karazhan
table.insert( BWD_QUEST_ITEMS, { item = "Leggings of the Vanquished Defender", tier = "4", type = { PRIEST = "Breeches", WARRIOR = "Legguards", DRUID = "Life-Kilt" } } );
table.insert( BWD_QUEST_ITEMS, { item = "Leggings of the Vanquished Champion", tier = "4", type = { SHAMAN = "Legguards", PALADIN = "Leggings", ROGUE = "Legguards" } } );
table.insert( BWD_QUEST_ITEMS, { item = "Leggings of the Vanquished Hero", tier = "4", type = { ALL = "Leggings"} } );

table.insert( BWD_QUEST_ITEMS, { item = "Pauldrons of the Vanquished Defender", tier = "4", type = { WARRIOR = "Shoulderguards", PRIEST = "Mantle", DRUID = "Life-Mantle" } } );
table.insert( BWD_QUEST_ITEMS, { item = "Pauldrons of the Vanquished Champion", tier = "4", type = { SHAMAN = "Shoulderguards", PALADIN = "Pauldrons", ROGUE = "Shoulderpads" } } );
table.insert( BWD_QUEST_ITEMS, { item = "Pauldrons of the Vanquished Hero", tier = "4", type = { ALL = "Mantle" } } );

table.insert( BWD_QUEST_ITEMS, { item = "Helm of the Vanquished Defender", tier = "4", type = { WARRIOR = "Shoulderguards", PRIEST = "Mantle", DRUID = "Life-Mantle" } } );
table.insert( BWD_QUEST_ITEMS, { item = "Helm of the Vanquished Champion", tier = "4", type = { SHAMAN = "Headguard", PALADIN = "Greathelm", ROGUE = "Helm" } } );
table.insert( BWD_QUEST_ITEMS, { item = "Helm of the Vanquished Hero", tier = "4", type = { PRIEST = "Cowl", WARRIOR = "Greathelm", DRUID = "Headguard" } } );

table.insert( BWD_QUEST_ITEMS, { item = "Gloves of the Vanquished Defender", tier = "4", type = { WARRIOR = "Handguards", PRIEST = "Gloves", DRUID = "Gloves" } } );
table.insert( BWD_QUEST_ITEMS, { item = "Gloves of the Vanquished Champion", tier = "4", type = { SHAMAN = "Gloves", PALADIN = "Gloves", ROGUE = "Handguards" } } );
table.insert( BWD_QUEST_ITEMS, { item = "Gloves of the Vanquished Hero", tier = "4", type = { HUNTER = "Gauntlets", MAGE = "Gloves", WARLOCK = "Gloves" } } );

table.insert( BWD_QUEST_ITEMS, { item = "Chestguard of the Vanquished Defender", tier = "4", type = { WARRIOR = "Chestguard", DRUID = "Chestguard", PRIEST = "Vestments" } } );
table.insert( BWD_QUEST_ITEMS, { item = "Chestguard of the Vanquished Champion", tier = "4", type = { SHAMAN = "Shoulderguards", PALADIN = "Pauldrons", ROGUE = "Shoulderpads" } } );
table.insert( BWD_QUEST_ITEMS, { item = "Chestguard of the Vanquished Hero", tier = "4", type = { SHAMAN = "Chestguard", PALADIN = "Chestpiece", ROGUE = "Chestguard" } } );


-- T3, Naxxramas
-- Hybrids
table.insert( BWD_QUEST_ITEMS, { item = "Desecrated Headpiece", tier = "3", type = { ALL = "Headpiece" } } );
table.insert( BWD_QUEST_ITEMS, { item = "Desecrated Spaulders", tier = "3", type = { ALL = "Spaulders" } } );
table.insert( BWD_QUEST_ITEMS, { item = "Desecrated Tunic", tier = "3", type = { ALL = "Tunic" } } );
table.insert( BWD_QUEST_ITEMS, { item = "Desecrated Legguards", tier = "3", type = { ALL = "Legguards" } } );
table.insert( BWD_QUEST_ITEMS, { item = "Desecrated Handguards", tier = "3", type = { ALL = "Handguards" } } );
table.insert( BWD_QUEST_ITEMS, { item = "Desecrated Wristguards", tier = "3", type = { ALL = "Wristguards" } } );
table.insert( BWD_QUEST_ITEMS, { item = "Desecrated Girdle", tier = "3", type = { ALL = "Girdle" } } );
table.insert( BWD_QUEST_ITEMS, { item = "Desecrated Boots", tier = "3", type = { ALL = "Boots" } } );

-- Casters
table.insert( BWD_QUEST_ITEMS, { item = "Desecrated Circlet", tier = "3", type = { ALL = "Circlet" } } );
table.insert( BWD_QUEST_ITEMS, { item = "Desecrated Shoulderpads", tier = "3", type = { ALL = "Shoulderpads" } } );
table.insert( BWD_QUEST_ITEMS, { item = "Desecrated Robe", tier = "3", type = { ALL = "Robe" } } );
table.insert( BWD_QUEST_ITEMS, { item = "Desecrated Leggings", tier = "3", type = { ALL = "Leggings" } } );
table.insert( BWD_QUEST_ITEMS, { item = "Desecrated Gloves", tier = "3", type = { ALL = "Gloves" } } );
table.insert( BWD_QUEST_ITEMS, { item = "Desecrated Bindings", tier = "3", type = { ALL = "Bindings" } } );
table.insert( BWD_QUEST_ITEMS, { item = "Desecrated Belt", tier = "3", type = { ALL = "Belt" } } );
table.insert( BWD_QUEST_ITEMS, { item = "Desecrated Sandals", tier = "3", type = { ALL = "Sandals" } } );

-- Melee
table.insert( BWD_QUEST_ITEMS, { item = "Desecrated Helmet", tier = "3", type = { ALL = "Helmet" } } );
table.insert( BWD_QUEST_ITEMS, { item = "Desecrated Pauldrons", tier = "3", type = { ALL = "Pauldrons" } } );
table.insert( BWD_QUEST_ITEMS, { item = "Desecrated Breastplate", tier = "3", type = { ALL = "Breastplate" } } );
table.insert( BWD_QUEST_ITEMS, { item = "Desecrated Legplates", tier = "3", type = { ALL = "Legplates" } } );
table.insert( BWD_QUEST_ITEMS, { item = "Desecrated Gauntlets", tier = "3", type = { ALL = "Gauntlets" } } );
table.insert( BWD_QUEST_ITEMS, { item = "Desecrated Bracers", tier = "3", type = { ALL = "Bracers" } } );
table.insert( BWD_QUEST_ITEMS, { item = "Desecrated Waistguard", tier = "3", type = { ALL = "Waistguard" } } );
table.insert( BWD_QUEST_ITEMS, { item = "Desecrated Sabatons", tier = "3", type = { ALL = "Sabatons" } } );

-- T2.5, Ahn'Qiraj 40
-- Leggings
table.insert( BWD_QUEST_ITEMS, { item = "Ouro's Intact Hide", tier = "2.5", type = { ROGUE = "Leggings", WARRIOR = "Legguard", PRIEST = "Trousers", MAGE = "Leggings" } } );
table.insert( BWD_QUEST_ITEMS, { item = "Skin of the Great Sandworm", tier = "2.5", type = { WARLOCK = "Trousers", HUNTER = "Leggings", PALADIN = "Legguards", DRUID = "Trousters", SHAMAN = "Leggings" } } );

-- Breastplate
table.insert( BWD_QUEST_ITEMS, { item = "Carapace of the Old God", tier = "2.5", type = { SHAMAN = "Hauberk", HUNTER = "Hauberk", WARRIOR = "Breastplate", ROGUE = "Vest", PALADIN = "Breastplate" } } );
table.insert( BWD_QUEST_ITEMS, { item = "Husk of the Old God", tier = "2.5", type = { MAGE = "Robes", WARLOCK = "Robes", PRIEST = "Vestments", DRUID = "Vest" } } );

-- Helm
table.insert( BWD_QUEST_ITEMS, { item = "Vek'lor's Diadem", tier = "2.5", type = { ROGUE = "Helm", HUNTER = "Diadem", PALADIN = "Crown", SHAMAN = "Diadem", DRUID = "Helm" } } );
table.insert( BWD_QUEST_ITEMS, { item = "Vek'nilash's Circlet", tier = "2.5", type = { MAGE = "Circlet", WARLOCK = "Circlet", WARRIOR = "Crown", PRIEST = "Tiara" } } );

-- Shoulders/Boots
table.insert( BWD_QUEST_ITEMS, { item = "Qiraji Bindings of Command", IsMulti = true, defaultType = "shoulder", tier = "2.5", type = { shoulder = { ROGUE = "Spaulders", PRIEST = "Mantle", HUNTER = "Pauldrons", WARRIOR = "Spaulders" }, boot = { ROGUE = "Boots", WARRIOR = "Greaves", HUNTER = "Footguards", PRIEST = "Footwraps" } } } );
table.insert( BWD_QUEST_ITEMS, { item = "Qiraji Bindings of Dominance", IsMulti = true, defaultType = "shoulder", tier = "2.5", type = { shoulder = { MAGE = "Shoulderpads", WARLOCK = "Mantle", DRUID = "Shoulderpads", SHAMAN = "Pauldrons", PALADIN = "Pauldrons" }, boot = { MAGE = "Boots", WARLOCK = "Footwraps", PALADIN = "Greaves", DRUID = "Boots", SHAMAN = "Footguards" } } } );
