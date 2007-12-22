local Arena = SSPVP:NewModule("Arena", "AceEvent-3.0", "AceConsole-3.0")
Arena.activeIn = "arena"

local L = SSPVPLocals

-- Blizzard likes to change this monthly, so lets just store it here to make it easier
local pointPenalty = {[5] = 1.0, [3] = 0.88, [2] = 0.76}

local arenaTeams = {}

function Arena:OnInitialize()
	self.defaults = {
		profile = {
			score = true,
			personal = true,
		},
	}
	
	self.db = SSPVP.db:RegisterNamespace("arena", self.defaults)
	self:RegisterSlashCommands()
end

function Arena:OnEnable()
	-- Load the inspection stuff, or wait for it to load
	if( IsAddOnLoaded("Blizzard_InspectUI") ) then
		hooksecurefunc("InspectPVPTeam_Update", self.InspectPVPTeam_Update)
	else
		self:RegisterEvent("ADDON_LOADED")
	end
		
	-- Tracking our current arena things
	self:RegisterEvent("ARENA_TEAM_UPDATE")
	self:ARENA_TEAM_UPDATE()
end

function Arena:OnDisable()
	self:UnregisterAllEvents()
end

function Arena:EnableModule()
	if( self.db.profile.score ) then
		self:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
	end
end

function Arena:DisableModule()
	self:UnregisterEvent("UPDATE_BATTLEFIELD_STATUS")

	-- Grab new data for next game
	for i=MAX_ARENA_TEAMS, 1, -1 do
		ArenaTeamRoster(i)
	end
end

function Arena:Reload()
	if( self.isActive ) then
		self:UnregisterAllEvents()
		self:EnableModule()
	end

	if( self.db.profile.personal ) then
		self:RegisterEvent("ARENA_TEAM_ROSTER_UPDATE")
	else
		self:UnregisterEvent("ARENA_TEAM_ROSTER_UPDATE")
	end
end

-- Check if inspect UI loaded
function Arena:ADDON_LOADED(event, addon)
	if( addon == "Blizzard_InspectUI" ) then
		hooksecurefunc("InspectPVPTeam_Update", self.InspectPVPTeam_Update)
		self:UnregisterEvent("ADDON_LOADED")
	end
end

-- Conversions
-- Points gained/lost from beating teams
-- 1644 vs 1680, gained 17 / 1661 vs 1703, lost 14
local function getChange(aRate, bRate, aWon)	
	local aChance = 1 / ( 1 + 10 ^ ( ( bRate - aRate ) / 400 ) )
	local bChance = 1 / ( 1 + 10 ^ ( ( aRate - bRate ) / 400 ) )

	local aNew, bNew
	if( aWon ) then
		aNew = math.floor(aRate + 32 * (1 - aChance))
		bNew = math.ceil(bRate + 32 * (0 - bChance))
	else
		aNew = math.ceil(aRate + 32 * (0 - aChance))
		bNew = math.floor(bRate + 32 * (1 - bChance))
	end

	-- aNew, aDiff, bNew, bDiff
	return aNew, aNew - aRate, bNew, bNew - bRate
end


-- RATING -> POINTS
local function getPoints(rating, teamSize)
	local penalty = pointPenalty[teamSize or 5]
	
	local points = 0
	if( rating > 1500 ) then
		points = (1511.26 / (1 + 1639.28 * math.exp(1) ^ (-0.00412 * rating))) * penalty
	else
		points = ((0.22 * rating ) + 14) * penalty
	end
	
	if( points < 0 ) then
		points = 0
	end
	
	return points
end

-- POINTS -> RATING
local function getRating(points, teamSize)
	local penalty = pointPenalty[teamSize or 5]
	
	local rating = 0
	if( points > getPoints(1500, teamSize) ) then
		rating = (math.log(((1511.26 * penalty / points) - 1) / 1639.28) / -0.00412)
	else
		rating = ((points / penalty - 14) / 0.22 )
	end
	
	rating = math.floor(rating + 0.5)
	
	if( type(rating) ~= "number" or rating < 0 ) then
		rating = 0
	end
	
	return rating
end

-- Store latest arena team info
function Arena:ARENA_TEAM_UPDATE()
	for i=1, MAX_ARENA_TEAMS do
		local teamName, teamSize, _, _, _, _, _, _, _, _, playerRating = GetArenaTeam(i)
		if( teamName ) then
			local id = teamName .. teamSize

			if( not arenaTeams[id] ) then
				arenaTeams[id] = {}
			end

			arenaTeams[id].size = teamSize
			arenaTeams[id].index = i
			arenaTeams[id].personal = playerRating
		end

	end
end

-- Rating/personal rating change
-- How many points gained/lost
function Arena:UPDATE_BATTLEFIELD_STATUS()
	if( GetBattlefieldWinner() and select(2, IsActiveBattlefieldArena()) ) then
		-- Figure out what bracket we're in
		local bracket
		for i=1, MAX_BATTLEFIELD_QUEUES do
			local status, _, _, _, _, teamSize = GetBattlefieldStatus(i)
			if( status == "active" ) then
				bracket = teamSize
				break
			end
		end
		
		-- Failed (bad)
		if( not bracket ) then
			return
		end
		
		local firstInfo, secondInfo, playerWon, playerPersonal, enemyRating

		-- Ensure that the players team is shown first
		for i=0, 1 do
			local teamName, oldRating, newRating = GetBattlefieldTeamInfo(i)
			if( arenaTeams[teamName .. bracket] ) then
				firstInfo = string.format(L["%s %d points (%d rating)"], teamName, newRating - oldRating, newRating)
				
				-- Only show our personal rating change if it's different from our teams rating
				if( playerPersonal ~= oldRating ) then
					playerPersonal = arenaTeams[teamName .. bracket].personal
				end
				
				if( newRating > oldRating ) then
					playerWon = true
				end
			else
				secondInfo = string.format(L["%s %d points (%d rating)"], teamName, newRating - oldRating, newRating)
				enemyRating = oldRating
			end
		end
		
		
		local personal = ""
		if( self.db.profile.personal and playerPersonal ) then
			-- Figure out our personal rating change
			local newPersonal, personalDiff = getChange(playerPersonal, enemyRating, playerWon)
			personal = string.format(L["/ %d personal (%d rating)"], personalDiff, newPersonal)
		end		
		
		SSPVP:Print(string.format("%s / %s %s", firstInfo, secondInfo, personal))
	end
end


-- Slash commands
function Arena:RegisterSlashCommands()
	-- Slash commands for conversions
	self:RegisterChatCommand("arena", function(input)
		-- Points -> rating
		if( string.match(input, "points ([0-9]+)") ) then
			local points = tonumber(string.match(input, "points ([0-9]+)"))

			SSPVP:Print(string.format(L["[%d vs %d] %d points = %d rating"], 5, 5, points, getRating(points)))
			SSPVP:Print(string.format(L["[%d vs %d] %d points = %d rating"], 3, 3, points, getRating(points, 3)))
			SSPVP:Print(string.format(L["[%d vs %d] %d points = %d rating"], 2, 2, points, getRating(points, 2)))
		
		-- Rating -> points
		elseif( string.match(input, "rating ([0-9]+)") ) then
			local rating = tonumber(string.match(input, "rating ([0-9]+)"))

			SSPVP:Print(string.format(L["[%d vs %d] %d rating = %d points"], 5, 5, rating, getPoints(rating)))
			SSPVP:Print(string.format(L["[%d vs %d] %d rating = %d points - %d%% = %d points"], 3, 3, rating, getPoints(rating), pointPenalty[3] * 100, getPoints(rating, 3)))
			SSPVP:Print(string.format(L["[%d vs %d] %d rating = %d points - %d%% = %d points"], 2, 2, rating, getPoints(rating), pointPenalty[2] * 100, getPoints(rating, 2)))

		-- Rating changes if you win/lose against a certain rating
		elseif( string.match(input, "change ([0-9]+) ([0-9]+)") ) then
			local aRating, bRating = string.match(input, "change ([0-9]+) ([0-9]+)")
			local aNew, aDiff, bNew, bDiff = getChange(tonumber(aRating), tonumber(bRating), true)
			
			SSPVP:Print(string.format(L["+%d points (%d rating) / %d points (%d rating)"], aDiff, aNew, bDiff, bNew))
			
		-- Games required for 30%
		elseif( string.match(input, "attend ([0-9]+) ([0-9]+)") ) then
			local played, teamPlayed = string.match(input, "attend ([0-9]+) ([0-9]+)")
			local percent = played / teamPlayed
			
			if( percent >= 0.30 ) then
				-- Make sure we don't show it as being above 100%
				if( percent > 1.0 ) then
					percent = 1.0
				end

				SSPVP:Print(string.format(L["%d games out of %d total is already above 30%% (%.2f%%)."], played, teamPlayed, percent * 100))
			else
				local gamesNeeded = math.ceil(((0.3 - percent) / 0.70) * teamPlayed)
				SSPVP:Print(string.format(L["%d more games have to be played (%d total) to reach 30%%."], gamesNeeded, teamPlayed + gamesNeeded))
			end
		else
			DEFAULT_CHAT_FRAME:AddMessage(L["SSPVP Arena slash commands"])
			DEFAULT_CHAT_FRAME:AddMessage(L[" - rating <rating> - Calculates points given from the passed rating."])
			DEFAULT_CHAT_FRAME:AddMessage(L[" - points <points> - Calculates rating required to reach the passed points."])
			DEFAULT_CHAT_FRAME:AddMessage(L[" - attend <played> <team> - Calculates games required to reach 30% using the passed games <played> out of the <team> games played."])
			DEFAULT_CHAT_FRAME:AddMessage(L[" - change <winner rating> <loser rating> - Calculates points gained/lost assuming the <winner rating> beats <loser rating>."])
		end
	end)
end


-- Inspection and players arena info uses the same base names
function Arena:UpdateDisplay(parent, isInspect, ...)
	local teamName, teamSize, teamRating, weekPlayed, weekWins, seasonPlayed, seasonWins, playerPlayed, seasonPlayerPlayed, teamRank, playerRating = select(1, ...)
	if( teamRating == 0 ) then
		return
	end

	-- Add points gained next to the rating
	local name = parent .. "Data"
	
	-- Shift the actual rating text down to the left to make room for our changes
	local label = getglobal(name .. "RatingLabel")
	label:SetText(L["Rating"])
	label:SetPoint("LEFT", name .. "Name", "RIGHT", -32, 0)

	-- Shift the rating to match the rating label + Set it
	local ratingText = getglobal(name .. "Rating")
	ratingText:SetText(string.format("%d |cffffffff(%d)|r", teamRating, getPoints(teamRating, teamSize)))
	ratingText:SetWidth(70)
	ratingText:ClearAllPoints()
	ratingText:SetPoint("LEFT", label, "RIGHT", 2, 0)

	-- Resize team name so it doesn't overflow into our rating
	getglobal(name .. "Name"):SetWidth(150)

	-- Can't get week info
	if( isInspect ) then
		return
	end

	-- Reposition the week/season stats
	local parentFrame = getglobal(parent)
	if( not parentFrame.SSUpdated ) then
		parentFrame.SSUpdated = true
		
		-- Shift played percentage/games up
		local label = getglobal(name .. "TypeLabel")
		label:ClearAllPoints()
		label:SetPoint("BOTTOMLEFT", name .. "Name", "BOTTOMLEFT", 0, -24)
		
		-- Hide games/played/-/wins/loses label, and shift them down a bit
		local label = getglobal(name .. "GamesLabel")
		--label:ClearAllPoints()
		--label:SetPoint("BOTTOMLEFT", name .. "TypeLabel", "BOTTOMRIGHT", -22, 16)
		label:Hide()
		
		local label = getglobal(name .. "WinLossLabel")
		--label:ClearAllPoints()
		--label:SetPoint("LEFT", name .. "GamesLabel", "RIGHT", -5, 0)
		label:Hide()
		
		local label = getglobal(name .. "PlayedLabel")
		--label:ClearAllPoints()
		--label:SetPoint("LEFT", name .. "WinLossLabel", "RIGHT", 19, 0)
		label:Hide()
		
		-- Create our custom widgets
		local season = parentFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
		season:SetPoint("BOTTOMLEFT", name .. "Name", "BOTTOMLEFT", 0, -41)
		season:SetJustifyH("LEFT")
		season:SetJustifyV("BOTTOM")
		season:SetText(L["Season"])
		
		local game = parentFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
		game:SetPoint("TOP", name .. "Games", "BOTTOM", 0, -7)

		local dash = parentFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
		dash:SetPoint("TOP", name .. "-", "BOTTOM", 0, -7)
		dash:SetText(" - ")
		
		local win = parentFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
		win:SetPoint("RIGHT", dash, "LEFT", 0, 0)

		local loss = parentFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
		loss:SetPoint("LEFT", dash, "RIGHT", 0, 0)
		
		--local winPercent = parentFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
		--winPercent:SetPoint("LEFT", dash, "RIGHT", 25, 0)
		--winPercent:SetText("34.4%")

		local played = parentFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
		played:SetPoint("TOP", name .. "Played", "BOTTOM", 0, -7)
		
		parentFrame.seasonWin = win
		parentFrame.seasonLoss = loss
		parentFrame.seasonGames = game
		parentFrame.seasonPlayed = played
	end
	
	-- DISPLAY!
	-- WEEK

	getglobal(name .. "TypeLabel"):SetText(L["Week"])
	 
	getglobal(name .. "Games"):SetText(weekPlayed)
	getglobal(name .. "Wins"):SetText(weekWins)
	getglobal(name .. "Loss"):SetText(weekPlayed - weekWins)		
	
	local played = getglobal(name .. "Played")
	local percent = playerPlayed / weekPlayed
	if( weekPlayed == 0 or playerPlayed == 0 ) then
		percent = 0
	end
	
	local color = "|cff20ff20"
	if( percent < 0.30 ) then
		color = "|cffff2020"
	end
	
	played:SetText(string.format("%d %s(%.f%%)|r", playerPlayed, color, percent * 100))
	played:SetVertexColor(1.0, 1.0, 1.0)
	
	-- SEASON
	parentFrame.seasonWin:SetText(seasonWins)

	parentFrame.seasonLoss:SetText(seasonPlayed - seasonWins)
	parentFrame.seasonGames:SetText(seasonPlayed)
	

	-- Do we want to show percent, or personal?
	local percent = seasonPlayerPlayed / seasonPlayed
	local color = "|cff20ff20"
	if( percent < 0.30 ) then
		color = "|cffff2020"

	end

	parentFrame.seasonPlayed:SetText(string.format("%d %s(%.f%%)|r", playerRating, color, percent * 100))
end

-- Modifies the team details page to show percentage of games played
hooksecurefunc("PVPTeamDetails_Update", function()
	local _, _, _, teamPlayed, _,  seasonTeamPlayed = GetArenaTeam(PVPTeamDetails.team)
	for i=1, GetNumArenaTeamMembers(PVPTeamDetails.team, 1) do
		local playedText = getglobal("PVPTeamDetailsButton" .. i .. "Played")
		local name, rank, _, _, online, played, _, seasonPlayed = GetArenaTeamRosterInfo(PVPTeamDetails.team, i)
		
		-- So we can show whos leader
		if( rank == 0 and not online ) then
			getglobal("PVPTeamDetailsButton" .. i .. "NameText"):SetText(string.format(L["(L) %s"], name))
		end
		
		-- Show decimal of games played instead of rounding
		if( PVPTeamDetails.season and seasonPlayed > 0 and seasonTeamPlayed > 0 ) then
			percent = seasonPlayed / seasonTeamPlayed
		elseif( played > 0 and teamPlayed > 0 ) then
			percent = played / teamPlayed
		else
			percent = 0
		end
		
		playedText.tooltip = string.format("%.2f%%", percent * 100)
	end
end)

-- Player frame
hooksecurefunc("PVPTeam_Update", function()
	local teams = {{size = 2}, {size = 3}, {size = 5}}
	
	-- Figure out which teams they have
	for _, value in pairs(teams) do
		for i=1, MAX_ARENA_TEAMS do
			local teamName, teamSize = GetArenaTeam(i)
			if( value.size == teamSize ) then
				value.index = i
			end
		end
	end

	-- Annd now display
	local buttonIndex = 0
	for _, value in pairs(teams) do
		if( value.index ) then
			buttonIndex = buttonIndex + 1 
			Arena:UpdateDisplay("PVPTeam" .. buttonIndex, nil, GetArenaTeam(value.index))
		end
	end
	
	-- Hide the season toggle
	PVPFrameToggleButton:Hide()
end)

-- Inspection frame
function Arena:InspectPVPTeam_Update()
	local teams = {{size = 2}, {size = 3}, {size = 5}}

	-- Figure out which teams they have
	for _, value in pairs(teams) do
		for i=1, MAX_ARENA_TEAMS do
			local teamName, teamSize = GetInspectArenaTeamData(i)
			if( value.size == teamSize ) then
				value.index = i
			end
		end
	end
	
	-- Annd now display
	local buttonIndex = 0
	for _, value in pairs(teams) do
		if( value.index ) then
			buttonIndex = buttonIndex + 1
			
			local teamName, teamSize, teamRating = GetInspectArenaTeamData(value.index)
			if( teamName ) then
				getglobal("InspectPVPTeam" .. buttonIndex .. "DataName"):SetText(string.format(L["%s |cffffffff(%dvs%d)|r"], teamName, teamSize, teamSize))
				Arena:UpdateDisplay("InspectPVPTeam" .. buttonIndex, true, GetInspectArenaTeamData(value.index))
			end
		end
	end
end

