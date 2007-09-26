local Score = SSPVP:NewModule("SSPVP-Score")
Score.activeIn = "bf"

local L = SSPVPLocals
local enemies = {}
local friendlies = {}

function Score:Initialize()
	hooksecurefunc("WorldStateScoreFrame_Update", self.WorldStateScoreFrame_Update)

	WorldStateScoreFrame:HookScript("OnShow", self.CreateInfoButtons)
	WorldStateScoreFrame:HookScript("OnHide", function() SetBattlefieldScoreFaction(nil) end)
	
	SSOverlay:AddCategory("fact", L["Faction Balance"], 0)
end

function Score:EnableModule()
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
	self:RegisterEvent("RAID_ROSTER_UPDATE")
	self:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")
end

function Score:DisableModule()
	self:UnregisterAllEvents()
	SSOverlay:RemoveCategory("fact")
end

function Score:Reload()
	if( not SSPVP.db.profile.general.factBalance ) then
		SSOverlay:RemoveCategory("fact")
	end
	
	Score:RAID_ROSTER_UPDATE()
	Score:UPDATE_BATTLEFIELD_SCORE()
end

-- Maintain a list of friendly players
function Score:RAID_ROSTER_UPDATE()
	if( not SSPVP.db.profile.score.level ) then
		return
	end
	
	for i=1, GetNumRaidMembers() do
		local name, server = UnitName("raid" .. i)
		
		if( server ) then
			friendlies[name .. "-" .. server] = UnitLevel("raid" .. i)
		else
			friendlies[name] = UnitLevel("raid" .. i)
		end
	end
end

-- Maintain a list of enemy players
function Score:UPDATE_MOUSEOVER_UNIT()
	if( SSPVP.db.profile.score.level ) then
		self:CheckUnit("mouseover")
	end
end

function Score:PLAYER_TARGET_CHANGED()
	if( SSPVP.db.profile.score.level ) then
		self:CheckUnit("target")
	end
end

function Score:CheckUnit(unit)
	if( UnitIsEnemy(unit, "player") and UnitIsPVP(unit) and UnitIsPlayer(unit) ) then	
		local name, server = UnitName(unit)
		if( server ) then
			enemies[name .. "-" .. server] = UnitLevel(unit)
		else
			enemies[name] = UnitLevel(unit)
		end
	end	
end

-- Update faction balance
function Score:UPDATE_BATTLEFIELD_SCORE()
	if( not SSPVP.db.profile.general.factBalance ) then
		return
	end
	
	local alliance = 0
	local horde = 0
	
	for i=1, GetNumBattlefieldScores() do
		local _, _, _, _, _, faction, _, _, _, classToken = GetBattlefieldScore(i)
		
		if( faction == 0 ) then
			horde = horde + 1
		elseif( faction == 1 ) then
			alliance = alliance + 1
		end
	end
	
	-- If it's full for both sides, or empty for both hide it
	if( ( alliance == SSPVP:MaxBattlefieldPlayers() and horde == SSPVP:MaxBattlefieldPlayers() ) or ( alliance == 0 and horde == 0 ) ) then
		SSOverlay:RemoveCategory("fact")
		return
	end
	
	-- Display
	SSOverlay:UpdateText("fact", L["Alliance: %d"], SSOverlay:GetFactionColor("Alliance"), alliance)
	SSOverlay:UpdateText("fact", L["Horde: %d"], SSOverlay:GetFactionColor("Horde"), horde)
end

-- Create the text for faction information
local function sortTotals(a, b)
	if( not b ) then
		return false
	end
	
	return a.total > b.total
end

function Score:CreateFactionInfo( faction )
	local factionColor, factionID
	if( faction == "Alliance" ) then
		factionColor = "|cff0070dd"
		factionID = 1
	elseif( faction == "Horde" ) then
		factionColor = RED_FONT_COLOR_CODE
		factionID = 0
	end
	
	local serverCount = {}
	local classCount = {}
	local totalPlayers = 0
	
	for i=1, GetNumBattlefieldScores() do
		local name, _, _, _, _, playerFaction, _, _, class = GetBattlefieldScore(i)
		if( name and playerFaction == factionID ) then
			local server = GetRealmName()
			if( string.match(name, "%-") ) then
				_, server = string.match(name, "(.+)%-(.+)")
			end

			-- Update server total
			local found
			for id, row in pairs(serverCount) do
				if( row.server == server ) then
					row.total = row.total + 1
					found = true
					break
				end
			end
			
			if( not found ) then
				table.insert(serverCount, {total = 1, server = server})
			end
			
			-- Update class total
			found = nil
			
			for id, row in pairs(classCount) do
				if( row.class == class ) then
					row.total = row.total + 1
					found = true
					break
				end
			end
			
			if( not found ) then
				table.insert(classCount, {total = 1, class = class})
			end
			
			-- Total players
			totalPlayers = totalPlayers + 1
		end
	end
	
	table.sort(serverCount, sortTotals)
	table.sort(classCount, sortTotals)
	
	return serverCount, classCount, L[faction], factionColor, totalPlayers
end

-- Print faction info to chat
function Score:PrintFactionInfo( faction )
	local servers, classes, faction, _, players = self:CreateFactionInfo(faction)
	
	-- Require min 2 players from the same server to show it
	-- Or, 4 in AV
	local minCount = 2
	if( SSPVP:IsPlayerIn("av") ) then
		minCount = 4
	end
	
	-- Output total players
	SSPVP:ChannelMessage( string.format( L["%s (%d players)"], faction, players ) )
	
	-- Output server
	local parsedServers = {}
	for _, row in pairs(servers) do
		if( row.total >= minCount ) then
			table.insert(parsedServers, row.server .. ": " .. row.total)
		end
	end
	
	SSPVP:ChannelMessage(table.concat(parsedServers, ", "))
	
	-- Output classes
	local parsedClasses = {}
	for _, row in pairs(classes) do
		table.insert(parsedClasses, row.class .. ": " .. row.total)
	end
	
	SSPVP:ChannelMessage(table.concat(parsedClasses, ", "))
end

-- Show faction info on the button tooltip
function Score:TooltipFactionInfo(faction)
	local servers, classes, faction, color, players = self:CreateFactionInfo(faction)
	if( players == 0 ) then
		return L["No data found"]
	end
	
	-- Show player totals
	local tooltip = string.format(L["%s (%d players)"], color .. faction .. FONT_COLOR_CODE_CLOSE, players) .. "\n\n"
	
	-- Show server info
	tooltip = tooltip .. color .. L["Server Balance"] .. FONT_COLOR_CODE_CLOSE .. "\n"
	for _, row in pairs(servers) do
		tooltip = tooltip .. row.server .. ": " .. row.total .. "\n"
	end
	
	-- Show class balance info
	tooltip = tooltip .. "\n" .. color .. L["Class Balance"] .. FONT_COLOR_CODE_CLOSE .. "\n"
	for _, row in pairs(classes) do
		tooltip = tooltip .. row.class .. ": " .. row.total .. "\n"
	end
	
	return tooltip
end

-- Create the Alliance/Horde buttons on the score
local function hideTooltip()
	GameTooltip:Hide()
end

local function showFactionTooltip(self)
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
	GameTooltip:SetText(Score:TooltipFactionInfo(self.faction))
	GameTooltip:Show()
end

local function outputServerInfo(self, mouseButton)
	if( mouseButton == "RightButton" ) then
		Score:PrintFactionInfo(self.faction)
	end
end

function Score:CreateInfoButtons()
	if( not self.allianceButton ) then
		local button = CreateFrame("Button", nil, WorldStateScoreFrame, "GameMenuButtonTemplate")
		button:SetFont(GameFontHighlightSmall:GetFont())
		button:SetText(L["Alliance"])
		button:SetHeight(19)
		button:SetWidth(button:GetFontString():GetStringWidth() + 10)
		button:SetPoint("TOPRIGHT", WorldStateScoreFrame, "TOPRIGHT", -190, -18)

		button:SetScript("OnLeave", hideTooltip)
		button:SetScript("OnEnter", showFactionTooltip)
		button:SetScript("OnMouseUp", outputServerInfo)
		button.faction = "Alliance"
		
		self.allianceButton = button
	end
	
	if( not self.hordeButton ) then
		local button = CreateFrame("Button", nil, WorldStateScoreFrame, "GameMenuButtonTemplate")
		button:SetFont(GameFontHighlightSmall:GetFont())
		button:SetText(L["Horde"])
		button:SetHeight(19)
		button:SetWidth(button:GetFontString():GetStringWidth() + 10)
		button:SetPoint("TOPRIGHT", WorldStateScoreFrame, "TOPRIGHT", -140, -18)

		button:SetScript("OnLeave", hideTooltip)
		button:SetScript("OnEnter", showFactionTooltip)
		button:SetScript("OnMouseUp", outputServerInfo)
		button.faction = "Horde"
		
		self.hordeButton = button
	end
end

-- Battlefield score changes
function Score:WorldStateScoreFrame_Update()
	local isArena = IsActiveBattlefieldArena()
	local dataFailure
	
	-- Sometimes will get a bad arena game, and we need to
	-- verify that we got good data before showing a rating change
	-- or else you'll see a large number like -39594134 rating lost
	if( isArena ) then
		for i=0, 1 do
			if( select(2, GetBattlefieldTeamInfo(i)) == 0 ) then
				dataFailure = true
			end
		end
	end

	for i=1, MAX_WORLDSTATE_SCORE_BUTTONS do
		local name, _, _, _, _, faction, _, _, _, classToken = GetBattlefieldScore(FauxScrollFrame_GetOffset(WorldStateScoreScrollFrame) + i)

		if( name ) then
			local nameText = getglobal("WorldStateScoreButton" .. i .. "Name")

			-- Hide class icons
			if( SSPVP.db.profile.score.icon ) then
				getglobal("WorldStateScoreButton" .. i .. "ClassButtonIcon"):Hide()
			end

			-- Color names by class
			if( SSPVP.db.profile.score.color and name ~= UnitName("player") ) then
				nameText:SetVertexColor(RAID_CLASS_COLORS[classToken].r, RAID_CLASS_COLORS[classToken].g, RAID_CLASS_COLORS[classToken].b )
			end

			-- Show level next to the name
			local level = ""
			if( SSPVP.db.profile.score.level ) then
				if( enemies[name] ) then
					level = "|cffffffff[" .. enemies[name] .. "]|r "
				elseif( friendlies[name] ) then
					level = "|cffffffff[" .. friendlies[name] .. "]|r "
				end
			end

			-- Show new rating next to the rating change
			if( isArena ) then
				local teamName, oldRating, newRating = GetBattlefieldTeamInfo(faction)
				if( not dataFailure ) then
					getglobal("WorldStateScoreButton" .. i .. "HonorGained"):SetText(newRating - oldRating .. " (" .. newRating .. ")")
				else
					getglobal("WorldStateScoreButton" .. i .. "HonorGained"):SetText("----")
				end
			end

			-- Append server name to everyone even if they're from the same server
			if( string.match(name, "-") ) then
				name, server = string.match(name, "(.+)%-(.+)")
			else
				server = GetRealmName()				
			end

			nameText:SetText(level .. name .. " |cffffffff- " .. server .. "|r")
		end
	end
end