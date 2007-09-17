
BWF_GROUP = "Group";

BWF_LEADER_ICON = "(L)";
BWF_ASSIST_ICON = "(A)";

BWF_CORRUPTION_FOUND = "Found corruption for %s in frame group %s, this has been fixed.";
BWF_CORRUPTION_FOUNDNOUNIT = "Found corruption for %s in frame group %s, however we cannot find a valid unitid to correct this. You likely need to do a /console reloadui";

BWF_NO_CORRUPTION = "No corruption found, if you're still having issues try a /console reloadui";

-- Classes
BWF_CLASSES = {};
BWF_CLASSES[1] = { unloc = "SHAMAN", class = "Shaman" };
BWF_CLASSES[2] = { unloc = "ROGUE", class = "Rogue" };
BWF_CLASSES[3] = { unloc = "DRUID", class = "Druid" };
BWF_CLASSES[4] = { unloc = "PRIEST", class = "Priest" };
BWF_CLASSES[5] = { unloc = "PALADIN", class = "Paladin" };
BWF_CLASSES[6] = { unloc = "WARRIOR", class = "Warrior" };
BWF_CLASSES[7] = { unloc = "MAGE", class = "Mage" };
BWF_CLASSES[8] = { unloc = "WARLOCK", class = "Warlock" };
BWF_CLASSES[9] = { unloc = "HUNTER", class = "Hunter" };

-- Range types, spell to do a range check for
BWF_RANGETYPE = {};
BWF_RANGETYPE["DRUID"] = { heal = "Healing Touch", decurse = "Remove Poison" };
BWF_RANGETYPE["PALADIN"] = { heal = "Flash of Light", decurse = "Cleanse" };
BWF_RANGETYPE["MAGE"] = { heal = nil, decurse = "Remove Lesser Curse" };
BWF_RANGETYPE["PRIEST"] = { heal = "Flash Heal", decurse = "Dispel Magic" };
BWF_RANGETYPE["SHAMAN"] = { heal = "Lesser Healing Wave", decurse = "Cure Poison" };

--Druid = Healing Touch, Paladin = Flash of Light, Shaman = Lesser Healing Wave. Those look right 

-- Heals over time
BWF_HOTS = {};
BWF_HOTS[1] = "Rejuvenation";
BWF_HOTS[2] = "Renew";
BWF_HOTS[3] = "Regrowth";
BWF_HOTS[4] = "Lifebloom";
BWF_HOTS[5] = "Gift of Naaru";