local L = {
	["MAX_LIMIT"] = "Maximum number of messages stored set to [%d].",
	["HELP1"] = "/dcl max <number> - Sets the maximum number of messages to store.",
}

-- Update background so it resizes correctly
local function updateLogHeight()
	if( COMBATLOG ) then
		local background = _G[COMBATLOG:GetName() .. "Background"]
		background:ClearAllPoints()
		background:SetPoint("TOPLEFT", COMBATLOG, "TOPLEFT", -2, 3)
		background:SetPoint("BOTTOMRIGHT", COMBATLOG, "BOTTOMRIGHT", 2, -3)
	end
end

-- Check for combatlog loading
local function updateCombatLog()
	-- Set message limit
	if( DCL_Config.maxEntries ~= COMBATLOG_MESSAGE_LIMIT ) then
		COMBATLOG_MESSAGE_LIMIT = DCL_Config.maxEntries
		Blizzard_CombatLog_Refilter()
	end

	-- Update height
	updateLogHeight()
	hooksecurefunc("FCF_DockUpdate", updateLogHeight)

	-- Reposition quick filter bar
	CombatLogQuickButtonFrame_Custom:ClearAllPoints()
	CombatLogQuickButtonFrame_Custom:SetPoint("BOTTOMLEFT", COMBATLOG:GetName() .. "TabRight", "BOTTOMLEFT", 20, 0)
	CombatLogQuickButtonFrame_Custom:SetPoint("BOTTOMRIGHT", COMBATLOG, "TOPRIGHT")
	
	-- Make it so the quick buttons are actually visible
	Blizzard_CombatLog_Update_QuickButtons()
	Blizzard_CombatLog_RefreshGlobalLinks()
	Blizzard_CombatLog_ApplyFilters(Blizzard_CombatLog_CurrentSettings)
	Blizzard_CombatLog_Refilter()
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addon)
	if( addon == "DamnCombatLog" ) then
		if( not DCL_Config ) then
			DCL_Config = { maxEntries = 300 }
		end
		
		if( IsAddOnLoaded("Blizzard_CombatLog") ) then
			updateCombatLog()
			self:UnregisterEvent("ADDON_LOADED")
		end
		
	elseif( addon == "Blizzard_CombatLog" ) then
		updateCombatLog()
	end
end)

local function print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99DamnLog|r: " .. msg)
end

-- Slash command fun
SLASH_DAMNLOG1 = "/damnlog"
SLASH_DAMNLOG2 = "/dcl"
SlashCmdList["DAMNLOG"] = function(msg)
	local cmd, data = string.match(msg or "", "([a-zA-Z]+) ([0-9]+)")
	cmd = string.lower(cmd or "")
	data = tonumber(data)

	
	if( cmd == "max" ) then
		COMBATLOG_MESSAGE_LIMIT = data
		Blizzard_CombatLog_Refilter()

		DCL_Config.maxEntries = data
		print(string.format(L["MAX_LIMIT"], data))
	else
		DEFAULT_CHAT_FRAME:AddMessage(L["HELP1"])
	end
end