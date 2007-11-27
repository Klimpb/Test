-- It looks weird without a comment up here
-- so hi heres a comment

local L = {	
	["%s (|cffffffff%d|rvs|cffffffff%d|r), %d #%d"] = "%s (|cffffffff%d|rvs|cffffffff%d|r), %d #%d",
	["Week: |cff20ff20%d|r:|cffff2020%d|r (%s)"] = "Week: |cff20ff20%d|r:|cffff2020%d|r (%s)",
	["Season: |cff20ff20%d|r:|cffff2020%d|r (%s)"] = "Season: |cff20ff20%d|r:|cffff2020%d|r (%s)",
	["PERSONAL"] = "PERSONAL",
	["Personal Rating"] = "Personal Rating",
	["POINTS"] = "POINTS",
}

local personalFrame
local Orig_PVPHonor_Update = PVPHonor_Update
function PVPHonor_Update(...)
	Orig_PVPHonor_Update(...)

	local highestPersonal = 0
	local highestID
	
	-- Find our highest personal rating
	for teamID=1, 3 do
		for i=1, GetNumArenaTeamMembers(teamID, true) do
			local rating = select(11, GetArenaTeam(i))
			if( rating > highestPersonal ) then
				highestPersonal = rating
				highestID = i
			end
		end
	end
	
	if( not personalFrame ) then
		-- Create the personal arena display to the right of the row with arena points
		personalFrame = CreateFrame("Frame", nil, PVPFrame)
		personalFrame:SetPoint("TOPRIGHT", PVPFrameBackground, -5, -95)
		personalFrame:SetHitRectInsets(0, 120, 0, 0)
		personalFrame:SetWidth(300)
		personalFrame:SetHeight(20)
		personalFrame:EnableMouse(true)
		personalFrame:SetScript("OnEnter", function(self)
			GameTooltip_SetDefaultAnchor(GameTooltip, self)
			GameTooltip:SetText(L["Personal Rating"], HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
			GameTooltip:AddLine(self.tooltip, nil, nil, nil, 1)
			GameTooltip:Show()
		end)
		personalFrame:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)

		personalFrame.label = personalFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
		personalFrame.label:SetPoint("LEFT", personalFrame, 0, 0)
		personalFrame.label:SetText(L["PERSONAL"])
		
		personalFrame.points = personalFrame:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
		personalFrame.points:SetPoint("LEFT", personalFrame.label, "RIGHT", 8, 0)
		personalFrame.points:SetJustifyH("RIGHT")
		
		personalFrame.icon = personalFrame:CreateTexture(nil, "BACKGROUND")
		personalFrame.icon:SetHeight(17)
		personalFrame.icon:SetWidth(17)
		personalFrame.icon:SetTexture("Interface\\PVPFrame\\PVP-ArenaPoints-Icon")
		personalFrame.icon:SetPoint("LEFT", personalFrame.points, "RIGHT", 5, 0)
		
		-- Move the arena points text to the left side instead of center, and rename it to "POINTS"
		PVPFrameArena:ClearAllPoints()
		PVPFrameArena:SetPoint("TOPLEFT", PVPFrameBackground, "TOPLEFT", 10, -95)
		PVPFrameArenaLabel:SetText(L["POINTS"])
	end
	
	-- Set personal rating
	if( highestID ) then
		local name, bracket, rating, _, _, _, _, _, _, rank = GetArenaTeam(highestID)
		local tooltip = string.format(L["%s (|cffffffff%d|rvs|cffffffff%d|r), %d #%d"], name, bracket, bracket, rating, rank)
		
		-- Add specific stats
		for i=1, GetNumArenaTeamMembers(highestID) do
			local name, _, _, _, _, played, win, seasonPlayed, seasonWin, personalRating = GetArenaTeamRosterInfo(highestID, i)
			if( name == UnitName("player") ) then
				-- THIS WEEK
				local winPercent = win / played * 100
				if( winPercent > 70 ) then
					winPercent = GREEN_FONT_COLOR_CODE .. string.format("%.2f%%", winPercent) .. FONT_COLOR_CODE_CLOSE
				elseif( winPercent < 30 ) then
					winPercent = RED_FONT_COLOR_CODE .. string.format("%.2f%%", winPercent) .. FONT_COLOR_CODE_CLOSE
				else
					winPercent = "|cffffffff" .. string.format("%.2f%%", winPercent) .. "|r"
				end
				
				tooltip = tooltip .. "\n\n" .. string.format(L["Week: |cff20ff20%d|r:|cffff2020%d|r (%s)"], win, played - win, winPercent)

				-- THIS SEASON
				local winPercent = seasonWin / seasonPlayed * 100
				if( winPercent > 70 ) then
					winPercent = GREEN_FONT_COLOR_CODE .. string.format("%.2f", winPercent) .. FONT_COLOR_CODE_CLOSE
				elseif( winPercent < 30 ) then
					winPercent = RED_FONT_COLOR_CODE .. string.format("%.2f%%", winPercent) .. FONT_COLOR_CODE_CLOSE
				else
					winPercent = "|cffffffff" .. string.format("%.2f%%", winPercent) .. "|r"
				end
				
				tooltip = tooltip .. "\n" .. string.format(L["Season: |cff20ff20%d|r:|cffff2020%d|r (%s)"], seasonWin, seasonPlayed - seasonWin, winPercent)
				break
			end
		end

		personalFrame.points:SetText(highestPersonal)
		personalFrame.tooltip = tooltip

	-- None found, not that this should really ever happen
	else
		personalFrame.points:SetText("0")
		personalFrame.tooltip = nil
	end
end
