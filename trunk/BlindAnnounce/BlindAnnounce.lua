local ARENAS_ONLY = false
local CHANNEL = "PARTY"
local failMessage = "%s FAILED (%s)"
local spells = {
	["Sap"] = "SAPPED %s",
	["Blind"] = "BLINDED %s",
}
local targets = {}

local cast = CreateFrame("Frame")
cast:RegisterEvent("UNIT_SPELLCAST_SENT")
cast:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
cast:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
cast:SetScript("OnEvent", function(self, event, ...)
	-- Check for spell misses
	if( event == "COMBAT_LOG_EVENT_UNFILTERED" and select(2, ...) == "SPELL_MISSED" ) then
		local timestamp, eventType, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellID, spellName, spellSchool, missType = ...
		if( spells[spellName] ) then
			if( GetNumPartyMembers() > 0 and ( (ARENAS_ONLY and select(2, IsInInstance()) == "arena") or not ARENAS_ONLY )  ) then
				SendChatMessage(string.format(failMessage, spellName, string.upper(getglobal("ACTION_SPELL_MISSED_" .. missType))), CHANNEL)
			end
		end
	

	-- Sent to server
	elseif( event == "UNIT_SPELLCAST_SENT" ) then
		local unit, spellName, spellRank, targetName = ...
		if( unit == "player" and spells[spellName] ) then
			targets[spellName] = targetName
		end
	

	-- Spell caste

	elseif( event == "UNIT_SPELLCAST_SUCCEEDED" ) then
		local unit, spellName, spellRank = ...
		if( unit == "player" and spells[spellName] and targets[spellName] ) then
			if( GetNumPartyMembers() > 0 and ( (ARENAS_ONLY and select(2, IsInInstance()) == "arena") or not ARENAS_ONLY )  ) then
				SendChatMessage(string.format(spells[spellName], targets[spellName]), CHANNEL)
			end
		end
	end
end)