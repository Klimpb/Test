-- Change this to "true" (without qoutes) to only announce spells in arenas globally
local ARENAS_ONLY = true
-- Change this to "RAID", "PARTY", "BATTLEGROUND", "SAY", "YELL" depending on the channel you want, include the quotes
local CHANNEL = "PARTY"
local failMessage = "%s FAILED (%s)"

--[[
Format is

["<spell name>"] = { msg = "<announce message>" },

<spell name> has to be the exact name you see in the combat log in the "You cast x".
<announce message> is whatever you want, use %s for the person it was used on.


For example, if you want to announce when you Sap somebody, but only in arenas you would add the below.

["Sap"] = { msg = "SAPPED %s", arenas = true },
]]

local spells = {
	--["Sap"] = { msg = "SAPPED %s" },
	--["Blind"] = { msg = "BLINDED %s"},
	--["Innervate"] = { msg = "Innervate used %s"},
	--["Seaspray Alabtross"] = { msg = "Seaspray Alabtross used" },
}

local cast = CreateFrame("Frame")
cast:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
cast:SetScript("OnEvent", function(self, event, ...)
	-- Check for spell misses
	if( event == "COMBAT_LOG_EVENT_UNFILTERED" and select(2, ...) == "SPELL_MISSED" ) then
		local timestamp, eventType, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellID, spellName, spellSchool, missType = ...
		if( bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) == COMBATLOG_OBJECT_AFFILIATION_MINE and spells[spellName] ) then
			
			if( GetNumPartyMembers() > 0 ) then
				local spell = spells[spellName]
				if( spell.fail and ( not spell.arenas or ( spell.arenas and select(2, IsInInstance()) == "arena" ) ) ) then
					SendChatMessage(string.format(spell.fail, spellName, string.upper(getglobal("ACTION_SPELL_MISSED_" .. missType))), spell.channel)
					--ChatFrame1:AddMessage(string.format("[%s] [%s]", spell.channel, string.format(spell.fail, spellName, string.upper(getglobal("ACTION_SPELL_MISSED_" .. missType)))))
				end
			end
		end
	
	-- Check if the spel lwas cast
	elseif( event == "COMBAT_LOG_EVENT_UNFILTERED" and select(2, ...) == "SPELL_CAST_SUCCESS" ) then
		local timestamp, eventType, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellID, spellName, spellSchool, missType = ...
		if( bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) == COMBATLOG_OBJECT_AFFILIATION_MINE and spells[spellName] ) then
			if( GetNumPartyMembers() > 0 ) then
				local spell = spells[spellName]
				if( not spell.arenas or ( spell.arenas and select(2, IsInInstance()) == "arena" ) ) then
					SendChatMessage(string.format(spell.msg, destName), spell.channel)
					--ChatFrame1:AddMessage(string.format("[%s] [%s]", spell.channel, string.format(spell.msg, destName or "")))
				end
			end
		end
	end
end)

-- Setup "defaults" quickly
for name, data in pairs(spells) do
	if( data.arenas == nil ) then
		data.arenas = ARENAS_ONLY
	end
	
	if( data.channel == nil ) then
		data.channel = CHANNEL
	end
	
	if( data.fail == nil ) then
		data.fail = failMessage
	end
end