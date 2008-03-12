local ARENAS_ONLY = true

local blindTarget
local cast = CreateFrame("Frame")
cast:RegisterEvent("UNIT_SPELLCAST_SENT")
cast:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
cast:SetScript("OnEvent", function(self, event, ...)
	if( event == "UNIT_SPELLCAST_SENT" ) then
		local unit, spellName, spellRank, targetName = ...
		if( unit == "player" and spellName == "Blind" ) then
			blindTarget = targetName
		end
	elseif( event == "UNIT_SPELLCAST_SUCCEEDED" and blindTarget ) then
		local unit, spellName, spellRank = ...
		if( unit == "player" and spellName == "Blind" ) then
			if( GetNumPartyMembers() > 0 and ( (ARENAS_ONLY and select(2, IsInInstance()) == "arena") or not ARENAS_ONLY )  ) then
				SendChatMessage("BLINDED " .. blindTarget, "PARTY")
			end
		end
	end
end)