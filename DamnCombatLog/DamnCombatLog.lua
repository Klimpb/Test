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
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addon)
	if( IsAddOnLoaded("Blizzard_CombatLog") ) then
		-- Update height
		updateLogHeight()
		hooksecurefunc("FCF_DockUpdate", updateLogHeight)
	
		-- Reposition quick filter bar
		CombatLogQuickButtonFrame_Custom:ClearAllPoints()
		CombatLogQuickButtonFrame_Custom:SetPoint("BOTTOMLEFT", COMBATLOG:GetName() .. "TabRight", "BOTTOMLEFT", 20, 0)
		CombatLogQuickButtonFrame_Custom:SetPoint("BOTTOMRIGHT", COMBATLOG, "TOPRIGHT")

		self:UnregisterEvent("ADDON_LOADED")
	end
end)